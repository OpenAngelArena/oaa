LinkLuaModifier("modifier_watch_tower", "items/azazel_tower_watch.lua", LUA_MODIFIER_MOTION_NONE)

item_azazel_tower_watch_1 = class(ItemBaseClass)

function item_azazel_tower_watch_1:CastFilterResultLocation(location)
  if IsClient() then
    return UF_SUCCESS -- the client can't use the GridNav, but the server will correct it anyway, you can't cheat that.
  end
  --if ... or #FindAllBuildingsInRadius(location, 144) > 0 or ...
  if (not GridNav:IsTraversable(location)) or #FindCustomBuildingsInRadius(location, 144) > 0 or
	self:GetCaster():IsPositionInRange(location, 144 + self:GetCaster():GetHullRadius())
  then
    return UF_FAIL_CUSTOM
  else
    return UF_SUCCESS
  end
end
function item_azazel_tower_watch_1:GetCustomCastErrorLocation(location)
  return "#dota_hud_error_no_buildings_here"
end

function item_azazel_tower_watch_1:OnSpellStart()
  local caster = self:GetCaster()
  local location = self:GetCursorPosition()
  local building = CreateUnitByName("npc_azazel_tower_watch", location, true, caster, caster:GetOwner(), caster:GetTeam())
  --building:RemoveModifierByName("modifier_invulnerable") -- Only real buildings have invulnerability on spawn
  building:SetMaterialGroup('radiant_level' .. self:GetLevel())
  building:SetHullRadius(60)
  building:SetOwner(caster)
  GridNav:DestroyTreesAroundPoint(location, building:GetHullRadius(), true)
  building:AddNewModifier(building, self, "modifier_watch_tower", {})
  building:AddNewModifier(building, self, "modifier_building_construction", {})
  building:AddNewModifier(building, self, "modifier_building_hide_on_minimap", {})

  self:SpendCharge()
end

-- upgrades
item_azazel_tower_watch_2 = item_azazel_tower_watch_1
item_azazel_tower_watch_3 = item_azazel_tower_watch_1
item_azazel_tower_watch_4 = item_azazel_tower_watch_1

--------------------------------------------------------------------------
-- base modifier

modifier_watch_tower = class(ModifierBaseClass)

local THINK_INTERVAL = 0.1

function modifier_watch_tower:OnCreated()
  local ab = self:GetAbility()
  self.level = ab:GetLevel()
  self.bonus_vision_range = ab:GetSpecialValueFor("bonus_vision_range")
  self:StartIntervalThink(THINK_INTERVAL)
end

function modifier_watch_tower:OnIntervalThink()
  if IsServer() then
    local target = self:GetParent()
    -- No other way to have unobstructed vision, sorry.
    AddFOWViewer(target:GetTeam(), target:GetOrigin(), target:GetCurrentVisionRange(), THINK_INTERVAL, false)
  end
end

function modifier_watch_tower:IsHidden()
  return true
end

function modifier_watch_tower:IsDebuff()
  return false
end

function modifier_watch_tower:IsPurgable()
  return false
end

function modifier_watch_tower:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH,
    MODIFIER_PROPERTY_BONUS_DAY_VISION,
    MODIFIER_PROPERTY_BONUS_NIGHT_VISION,
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
    MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS
  }
end

function modifier_watch_tower:OnDeath(data)
  if data.unit == self:GetParent() then
    data.unit:SetOriginalModel("models/props_structures/tower_upgrade/tower_upgrade_dest.vmdl")
    data.unit:ManageModelChanges()
    local destruction_particle = ParticleManager:CreateParticle("particles/world_tower/tower_upgrade/ti7_radiant_tower_lvl1_dest.vpcf", PATTACH_ABSORIGIN, data.unit)
    ParticleManager:ReleaseParticleIndex(destruction_particle)
  end
end

function modifier_watch_tower:GetBonusDayVision()
  if IsServer() then
    return self.bonus_vision_range
  end
end
modifier_watch_tower.GetBonusNightVision = modifier_watch_tower.GetBonusDayVision

function modifier_watch_tower:GetOverrideAnimation()
  return ACT_DOTA_CAPTURE
end

function modifier_watch_tower:GetActivityTranslationModifiers()
  return "level"..self.level
end
