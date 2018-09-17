LinkLuaModifier("modifier_defense_tower", "items/azazel_tower_defense.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_defense_tower_true_sight", "items/azazel_tower_defense.lua", LUA_MODIFIER_MOTION_NONE)

item_azazel_tower_defense_1 = class(ItemBaseClass)

function item_azazel_tower_defense_1:CastFilterResultLocation(location)
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

function item_azazel_tower_defense_1:GetCustomCastErrorLocation(location)
  return "#dota_hud_error_no_buildings_here"
end

function item_azazel_tower_defense_1:OnSpellStart()
  local caster = self:GetCaster()
  local location = self:GetCursorPosition()
  local building = CreateUnitByName("npc_azazel_tower_defense", location, true, caster, caster:GetOwner(), caster:GetTeam())
  --building:RemoveModifierByName("modifier_invulnerable") -- Only real buildings have invulnerability on spawn
  building:SetOwner(caster)
  GridNav:DestroyTreesAroundPoint(location, building:GetHullRadius(), true)
  building:AddNewModifier(building, self, "modifier_building_construction", {})
  building:AddNewModifier(building, self, "modifier_defense_tower", {})
  building:AddNewModifier(building, self, "modifier_defense_tower_true_sight", {})

  self:SpendCharge()
end

-- upgrades
item_azazel_tower_defense_2 = item_azazel_tower_defense_1
item_azazel_tower_defense_3 = item_azazel_tower_defense_1
item_azazel_tower_defense_4 = item_azazel_tower_defense_1

--------------------------------------------------------------------------
-- base modifier

modifier_defense_tower = class(ModifierBaseClass)

function modifier_defense_tower:IsHidden()
  return true
end

function modifier_defense_tower:IsDebuff()
  return false
end

function modifier_defense_tower:IsPurgable()
  return false
end

function modifier_defense_tower:OnCreated()
  local ability = self:GetAbility()
  self.bonusDamage = ability:GetSpecialValueFor("bonus_damage")
end

function modifier_defense_tower:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH,
    MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
  }
end

function modifier_defense_tower:OnDeath(data)
  if data.unit == self:GetParent() then
    --self:GetParent():SetModel("models/props_structures/radiant_tower002_destruction.vmdl") -- doesn't seem to work.
    data.unit:SetOriginalModel("models/props_structures/radiant_tower002_destruction.vmdl")
    data.unit:ManageModelChanges()
  end
end

function modifier_defense_tower:GetModifierBaseAttack_BonusDamage()
  return self.bonusDamage
end

modifier_defense_tower_true_sight = class(ModifierBaseClass)

function modifier_defense_tower_true_sight:OnCreated()
  if IsServer() then
    self:GetParent():Attribute_SetIntValue("true_sight_radius", self:GetAbility():GetSpecialValueFor("true_sight_radius"))
  end
end

function modifier_defense_tower_true_sight:IsHidden()
  return false
end

function modifier_defense_tower_true_sight:GetTexture()
  return "item_ward_sentry"
end

function modifier_defense_tower_true_sight:IsPurgable()
  return false
end

function modifier_defense_tower_true_sight:IsAura()
  return true
end

function modifier_defense_tower_true_sight:GetModifierAura()
  return "modifier_truesight"
end

function modifier_defense_tower_true_sight:GetAuraRadius()
  return self:GetParent():Attribute_GetIntValue("true_sight_radius", 800)
end

function modifier_defense_tower_true_sight:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_defense_tower_true_sight:GetAuraSearchType()
  return DOTA_UNIT_TARGET_ALL
end
