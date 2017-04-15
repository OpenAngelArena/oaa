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

function item_greater_travel_boots:OnSpellStart()
  local hCaster = self:GetCaster()
  local hTarget = self:GetCursorTarget()
  local targetOrigin = hTarget:GetOrigin()

  if not hTarget then
    -- FindUnitsInRadius(int teamNumber, Vector position, handle cacheUnit, float radius, int teamFilter, int typeFilter, int flagFilter, int order, bool canGrowCache)
    local units = FindUnitsInRadius(hCaster:GetTeamNumber(), self:GetCursorPosition(), nil, 2000, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags(), FIND_CLOSEST, false)
    hTarget = units[1]
  end
  if not hTarget or hTarget == hCaster then
    return false
  end

  self.targetEntity = hTarget

  -- Minimap teleport display
  MinimapEvent(hCaster:GetTeamNumber(), hCaster, targetOrigin.x, targetOrigin.y, DOTA_MINIMAP_EVENT_TEAMMATE_TELEPORTING, self:GetChannelTime() + 1)

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
