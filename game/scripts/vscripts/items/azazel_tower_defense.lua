LinkLuaModifier("modifier_defense_tower_construction", "items/azazel_tower_defense.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_defense_tower_true_sight", "items/azazel_tower_defense.lua", LUA_MODIFIER_MOTION_NONE)

item_azazel_tower_defense_1 = class(ItemBaseClass)

function item_azazel_tower_defense_1:CastFilterResultLocation(location)
  if IsClient() then
    return UF_SUCCESS
  end
  if (not GridNav:IsTraversable(location)) or #FindUnitsInRadius(DOTA_TEAM_NEUTRALS, location, nil, 144, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_BUILDING, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false) > 0 then
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
  local radius = building:GetHullRadius()
  building:SetOwner(caster)
  GridNav:DestroyTreesAroundPoint(location, radius, true)
  building:SetOrigin(location)
  Timers:CreateTimer(0.1,function()
    ResolveNPCPositions(location, radius)
  end)
  building:RemoveModifierByName('modifier_invulnerable')
  building:AddNewModifier(building, self, "modifier_defense_tower_construction", {duration = -1})
  building:AddNewModifier(building, self, "modifier_defense_tower_true_sight", {duration = -1})
end

-- upgrades
item_azazel_tower_defense_2 = item_azazel_tower_defense_1
item_azazel_tower_defense_3 = item_azazel_tower_defense_1
item_azazel_tower_defense_4 = item_azazel_tower_defense_1

--------------------------------------------------------------------------
-- base modifier

modifier_defense_tower_construction = class(ModifierBaseClass)

local SINK_HEIGHT = 300
local THINK_INTERVAL = 0.1

function modifier_defense_tower_construction:OnCreated()
  if IsServer() then
    local target = self:GetParent()
    local ab = self:GetAbility()
    local maxhealth = target:GetMaxHealth() + ab:GetSpecialValueFor("bonus_health")
    local location = target:GetOrigin()
    local time = ab:GetSpecialValueFor("construction_time")
    target:Attribute_SetIntValue("construction_time", time)
    target:Attribute_SetIntValue("bonus_damage", ab:GetSpecialValueFor("bonus_damage"))
    target:SetOrigin(GetGroundPosition(location, target) - Vector(0, 0, SINK_HEIGHT))
    target:SetMaxHealth(maxhealth)
    target:SetHealth(maxhealth * 0.01)
    self:StartIntervalThink(THINK_INTERVAL)
    self:SetStackCount(math.floor(time / THINK_INTERVAL)) -- `construction_time` should be divisible by `THINK_INTERVAL`!
  end
end

function modifier_defense_tower_construction:OnIntervalThink()
  if IsServer() then
    local target = self:GetParent()
    local time = target:Attribute_GetIntValue("construction_time", 10)
    local count = self:GetStackCount()
    local location = target:GetOrigin()
    target:SetOrigin(target:GetOrigin() + Vector(0, 0, SINK_HEIGHT / (time / THINK_INTERVAL)))
    self:SetStackCount(count - 1)
    if count < 1 then
      self:StartIntervalThink(-1)
    end
  end
end

function modifier_defense_tower_construction:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_defense_tower_construction:IsHidden()
  return true
end
function modifier_defense_tower_construction:IsDebuff()
  return false
end
function modifier_defense_tower_construction:IsPurgable()
  return false
end

function modifier_defense_tower_construction:CheckState()
  return {
    [MODIFIER_STATE_DISARMED] = self:GetStackCount() > 0
  }
end
function modifier_defense_tower_construction:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH,
    MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
  }
end

function modifier_defense_tower_construction:OnDeath(data)
  if data.unit == self:GetParent() then
    --self:GetParent():SetModel("models/props_structures/radiant_tower002_destruction.vmdl") -- doesn't seem to work.
    self:GetParent():SetOriginalModel("models/props_structures/radiant_tower002_destruction.vmdl")
    self:GetParent():ManageModelChanges()
  end
end

function modifier_defense_tower_construction:GetModifierConstantHealthRegen()
  if self:GetStackCount() > 0 then
    return self:GetParent():GetMaxHealth() / self:GetParent():Attribute_GetIntValue("construction_time", 10)
  else
    return 0
  end
end

function modifier_defense_tower_construction:GetModifierBaseAttack_BonusDamage()
  return self:GetParent():Attribute_GetIntValue("bonus_damage", 0)
end

modifier_defense_tower_true_sight = class(ModifierBaseClass)

function modifier_defense_tower_true_sight:OnCreated()
  self:GetParent():Attribute_SetIntValue("true_sight_radius", self:GetAbility():GetSpecialValueFor("true_sight_radius"))
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
