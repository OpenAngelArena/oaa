item_greater_travel_boots = class({})
modifier_item_greater_travel_boots = class({})

LinkLuaModifier( "modifier_item_greater_travel_boots", "items/farming/item_greater_travel_boots.lua", LUA_MODIFIER_MOTION_NONE )

function item_greater_travel_boots:GetIntrinsicModifierName()
  return "modifier_item_greater_travel_boots"
end

function item_greater_travel_boots:IsHidden()
  return false
end

function item_greater_travel_boots:IsDebuff()
  return false
end

function item_greater_travel_boots:IsPurgable()
  return false
end

function item_greater_travel_boots:CastFilterResultLocation(targetPoint)
  if IsServer() then
    local hCaster = self:GetCaster()
    -- FindUnitsInRadius(int teamNumber, Vector position, handle cacheUnit, float radius, int teamFilter, int typeFilter, int flagFilter, int order, bool canGrowCache)
    local units = FindUnitsInRadius(hCaster:GetTeamNumber(), targetPoint, nil, 2000, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags(), FIND_CLOSEST, false)

    local function IsNotCaster(entity)
      return not (entity == hCaster)
    end
    local hTarget = nth(1, filter(IsNotCaster, iter(units)))

    if not hTarget then
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

  -- Teleport animation
  hCaster:StartGesture(ACT_DOTA_TELEPORT)

  -- Teleport sounds
  EmitSoundOn("Portal.Loop_Disappear", hCaster)
  EmitSoundOn("Portal.Loop_Appear", hTarget)

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
  if not self.targetEntity:IsAlive() then
    self:EndChannel(true)
  end
end
-- IsAlive
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
  self.targetEntity:StopSound("Portal.Loop_Appear")

  if wasInterupted then
    return -- do nothing
  end

  hCaster:StartGesture(ACT_DOTA_TELEPORT_END)

  EmitSoundOnLocationWithCaster(hCaster:GetOrigin(), "Portal.Hero_Disappear", hCaster)
  EmitSoundOn("Portal.Hero_Appear", self.targetEntity)

  FindClearSpaceForUnit(self:GetCaster(), self.targetEntity:GetAbsOrigin(), true)
end

function modifier_item_greater_travel_boots:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_UNIQUE
  }
end

function modifier_item_greater_travel_boots:GetModifierMoveSpeedBonus_Special_Boots()
  return self:GetAbility():GetSpecialValueFor('bonus_movement_speed')
end

function modifier_item_greater_travel_boots:OnCreated()
  self:StartIntervalThink(1)
end

function modifier_item_greater_travel_boots:OnIntervalThink ()
  if not PlayerResource then
    -- sometimes for no reason the player resource isn't there, usually only at the start of games in tools mode
    return
  end
  local caster = self:GetCaster()
  local gpm = self:GetAbility():GetSpecialValueFor('bonus_gold_per_minute')
  PlayerResource:ModifyGold(caster:GetPlayerID(), gpm / 60, true, DOTA_ModifyGold_GameTick)
end

--------------------------------------------------------------------------------
-- All the upgrades are exactly the same
--------------------------------------------------------------------------------
item_greater_travel_boots_2 = item_greater_travel_boots
item_greater_travel_boots_3 = item_greater_travel_boots
item_greater_travel_boots_4 = item_greater_travel_boots
item_greater_travel_boots_5 = item_greater_travel_boots
