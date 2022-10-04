LinkLuaModifier( "modifier_intrinsic_multiplexer", "modifiers/modifier_intrinsic_multiplexer.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_greater_travel_boots", "items/farming/greater_travel_boots.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_greater_travel_boots_unique_passive", "items/farming/greater_travel_boots.lua", LUA_MODIFIER_MOTION_NONE )

item_greater_travel_boots = class(ItemBaseClass)

function item_greater_travel_boots:GetIntrinsicModifierName()
  return "modifier_intrinsic_multiplexer"
end

function item_greater_travel_boots:GetIntrinsicModifierNames()
  return {
    "modifier_item_greater_travel_boots",
    "modifier_item_greater_travel_boots_unique_passive",
  }
end

function item_greater_travel_boots:CastFilterResultLocation(targetPoint)
  if IsServer() then
    local hCaster = self:GetCaster()
    -- FindUnitsInRadius(int teamNumber, Vector position, handle cacheUnit, float radius, int teamFilter, int typeFilter, int flagFilter, int order, bool canGrowCache)
    local units = FindUnitsInRadius(hCaster:GetTeamNumber(), targetPoint, nil, FIND_UNITS_EVERYWHERE, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags(), FIND_CLOSEST, false)

    local function IsNotCaster(entity)
      return entity ~= hCaster
    end
    local hTarget = nth(1, filter(IsNotCaster, iter(units)))

    if not hTarget then
      return UF_FAIL_CUSTOM
    end

    -- Teleport target is too close and player clicked far away
    if (hTarget:GetAbsOrigin() - hCaster:GetAbsOrigin()):Length2D() <= 800 and (targetPoint - hCaster:GetAbsOrigin()):Length2D() > 1800 then
      return UF_FAIL_CUSTOM
    end

    self.targetEntity = hTarget
    return UF_SUCCESS
  end
end

function item_greater_travel_boots:GetCustomCastErrorLocation()
  -- "Cannot find nearby valid target" error
  return "#dota_hud_error_target_no_dark_rift"
end

function item_greater_travel_boots:OnSpellStart()
  local hCaster = self:GetCaster()
  local hTarget = self:GetCursorTarget()
  local casterTeam = hCaster:GetTeamNumber()

  -- Disable working on Meepo Clones
  if hCaster:IsClone() then
    self:RefundManaCost()
    self:EndCooldown()
    return
  end

  local function IsAlly(entity)
    return entity:GetTeamNumber() == casterTeam
  end

  if hTarget then
    if hTarget == hCaster then
      local fountains = Entities:FindAllByClassname("ent_dota_fountain")
      hTarget = head(filter(IsAlly, iter(fountains)))
    end
    self.targetEntity = hTarget
  else
    hTarget = self.targetEntity
  end

  local targetOrigin = hTarget:GetOrigin()

  -- Minimap teleport display
  MinimapEvent(casterTeam, hCaster, targetOrigin.x, targetOrigin.y, DOTA_MINIMAP_EVENT_TEAMMATE_TELEPORTING, self:GetChannelTime() + 0.5)

  -- Vision
  self:CreateVisibilityNode(targetOrigin, 400, self:GetChannelTime() + 1)

  -- Teleport animation
  hCaster:StartGesture(ACT_DOTA_TELEPORT)

  -- Teleport sounds
  hCaster:EmitSound("Portal.Loop_Disappear")
  hTarget:EmitSound("Portal.Loop_Appear")

  -- Particle effects
  local teleportFromEffectName = "particles/items2_fx/teleport_start.vpcf"
  local teleportToEffectName = "particles/items2_fx/teleport_end.vpcf"
  self.teleportFromEffect = ParticleManager:CreateParticle(teleportFromEffectName, PATTACH_ABSORIGIN, hCaster)
  self.teleportToEffect = ParticleManager:CreateParticle(teleportToEffectName, PATTACH_ABSORIGIN_FOLLOW, hTarget)

  --ParticleManager:SetParticleControl(self.teleportFromEffect, 0, hCaster:GetOrigin())
  -- Teleport effect color
  ParticleManager:SetParticleControl(self.teleportFromEffect, 2, Vector(255, 255, 255))

  --ParticleManager:SetParticleControlEnt(self.teleportToEffect, 0, hTarget, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", hTarget:GetAbsOrigin(), true)
  ParticleManager:SetParticleControlEnt(self.teleportToEffect, 1, hTarget, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", targetOrigin, true)
  ParticleManager:SetParticleControlEnt(self.teleportToEffect, 3, hCaster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", targetOrigin, true)
  ParticleManager:SetParticleControl(self.teleportToEffect, 4, Vector(0.9, 0, 0))
  ParticleManager:SetParticleControlEnt(self.teleportToEffect, 5, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", targetOrigin, true)
end

function item_greater_travel_boots:OnChannelThink (delta)
  if not self.targetEntity:IsAlive() or self:GetCaster():IsRooted() then
    self:EndChannel(true)
  end
end

function item_greater_travel_boots:OnChannelFinish(wasInterupted)
  local hCaster = self:GetCaster()

  MinimapEvent(hCaster:GetTeamNumber(), hCaster, 0, 0, DOTA_MINIMAP_EVENT_CANCEL_TELEPORTING, 0)

  -- End animation
  hCaster:RemoveGesture(ACT_DOTA_TELEPORT)
  -- End particle effects
  ParticleManager:DestroyParticle(self.teleportFromEffect, false)
  ParticleManager:DestroyParticle(self.teleportToEffect, false)
  ParticleManager:ReleaseParticleIndex(self.teleportFromEffect)
  ParticleManager:ReleaseParticleIndex(self.teleportToEffect)
  -- End sounds
  hCaster:StopSound("Portal.Loop_Disappear")
  hCaster:StopSound("Hero_Tinker.MechaBoots.Loop")
  self.targetEntity:StopSound("Portal.Loop_Appear")

  if wasInterupted then
    return -- do nothing
  end

  hCaster:StartGesture(ACT_DOTA_TELEPORT_END)

  EmitSoundOnLocationWithCaster(hCaster:GetOrigin(), "Portal.Hero_Disappear", hCaster)
  self.targetEntity:EmitSound("Portal.Hero_Appear")

  FindClearSpaceForUnit(self:GetCaster(), self.targetEntity:GetAbsOrigin(), true)
end

item_greater_travel_boots_2 = class(item_greater_travel_boots)
item_greater_travel_boots_3 = class(item_greater_travel_boots)
item_greater_travel_boots_4 = class(item_greater_travel_boots)
item_travel_boots_oaa = item_greater_travel_boots

---------------------------------------------------------------------------------------------------

modifier_item_greater_travel_boots = class(ModifierBaseClass)

function modifier_item_greater_travel_boots:IsHidden()
  return true
end

function modifier_item_greater_travel_boots:IsDebuff()
  return false
end

function modifier_item_greater_travel_boots:IsPurgable()
  return false
end

function modifier_item_greater_travel_boots:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_UNIQUE
  }
end

function modifier_item_greater_travel_boots:GetModifierMoveSpeedBonus_Special_Boots()
  if self:GetAbility() then
    return self:GetAbility():GetSpecialValueFor('bonus_movement_speed')
  end
end

---------------------------------------------------------------------------------------------------

modifier_item_greater_travel_boots_unique_passive = class(ModifierBaseClass)

function modifier_item_greater_travel_boots_unique_passive:IsHidden()
  return true
end

function modifier_item_greater_travel_boots_unique_passive:IsDebuff()
  return false
end

function modifier_item_greater_travel_boots_unique_passive:IsPurgable()
  return false
end

function modifier_item_greater_travel_boots_unique_passive:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.dmg = ability:GetSpecialValueFor("bonus_damage_during_duels")
    self.spell_amp = ability:GetSpecialValueFor("bonus_spell_amp_during_duels")
  end
  if IsServer() then
    self:StartIntervalThink(0)
  end
end

function modifier_item_greater_travel_boots_unique_passive:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.dmg = ability:GetSpecialValueFor("bonus_damage_during_duels")
    self.spell_amp = ability:GetSpecialValueFor("bonus_spell_amp_during_duels")
  end
end

function modifier_item_greater_travel_boots_unique_passive:OnIntervalThink()
  if Duels:IsActive() then
    self:SetStackCount(1)
  else
    self:SetStackCount(2)
  end
end

function modifier_item_greater_travel_boots_unique_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
    MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
  }
end

function modifier_item_greater_travel_boots_unique_passive:GetModifierBaseDamageOutgoing_Percentage()
  if self:GetStackCount() == 1 then
    return self.dmg or self:GetAbility():GetSpecialValueFor("bonus_damage_during_duels")
  end

  return 0
end

function modifier_item_greater_travel_boots_unique_passive:GetModifierSpellAmplify_Percentage()
  if self:GetStackCount() == 1 then
    return self.spell_amp or self:GetAbility():GetSpecialValueFor("bonus_spell_amp_during_duels")
  end

  return 0
end
