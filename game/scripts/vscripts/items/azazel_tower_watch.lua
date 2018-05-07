LinkLuaModifier("modifier_watch_tower_construction", "items/azazel_tower_watch.lua", LUA_MODIFIER_MOTION_NONE)

item_azazel_tower_watch_1 = class(ItemBaseClass)

function item_azazel_tower_watch_1:CastFilterResultLocation(location)
  if IsClient() then
    return UF_SUCCESS -- the client can't use the GridNav, but the server will correct it anyway, you can't cheat that.
  end
  if (not GridNav:IsTraversable(location)) or #FindUnitsInRadius(DOTA_TEAM_NEUTRALS, location, nil, 144, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_BUILDING, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false) > 0 or
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
  building:SetOwner(caster)
  GridNav:DestroyTreesAroundPoint(location, building:GetHullRadius(), true)
  building:SetOrigin(location)
  building:RemoveModifierByName('modifier_invulnerable')
  building:AddNewModifier(building, self, "modifier_watch_tower_construction", {duration = -1})
  local charges = self:GetCurrentCharges() - 1
  if charges < 1 then
    caster:RemoveItem(self)
  else
    self:SetCurrentCharges(charges)
  end
end

-- upgrades
item_azazel_tower_watch_2 = item_azazel_tower_watch_1
item_azazel_tower_watch_3 = item_azazel_tower_watch_1
item_azazel_tower_watch_4 = item_azazel_tower_watch_1

--------------------------------------------------------------------------
-- base modifier

modifier_watch_tower_construction = class(ModifierBaseClass)

local SINK_HEIGHT = 200
local THINK_INTERVAL = 0.1

function modifier_watch_tower_construction:OnCreated()
  local ab = self:GetAbility()
  local level = ab:GetLevel()
  self.level = level
  if IsServer() then
    local target = self:GetParent()
    local maxhealth = target:GetMaxHealth() + ab:GetSpecialValueFor("bonus_health")
    local location = target:GetOrigin()
    local time = ab:GetSpecialValueFor("construction_time")
    target:Attribute_SetIntValue("construction_time", time)
    target:Attribute_SetIntValue("bonus_vision_range", ab:GetSpecialValueFor("bonus_vision_range"))
    target:SetOrigin(GetGroundPosition(location, target) - Vector(0, 0, SINK_HEIGHT))
    Timers:CreateTimer(0.1, function()
      ResolveNPCPositions(location, target:GetHullRadius())
      target:SetMaxHealth(maxhealth)
      target:SetHealth(maxhealth * 0.01)
      target:SetMaterialGroup('radiant_level'..level)
      self:StartIntervalThink(THINK_INTERVAL)
      self:SetStackCount(math.floor(time / THINK_INTERVAL)) -- `construction_time` should be divisible by `THINK_INTERVAL`!
    end)
  end
end

function modifier_watch_tower_construction:OnIntervalThink()
  if IsServer() then
    local target = self:GetParent()
    local count = self:GetStackCount()
    if count > 0 then
      local time = target:Attribute_GetIntValue("construction_time", 10)
      local location = target:GetOrigin()
      target:SetOrigin(target:GetOrigin() + Vector(0, 0, SINK_HEIGHT / (time / THINK_INTERVAL)))
      self:SetStackCount(count - 1)
    else
      AddFOWViewer(target:GetTeam(), target:GetOrigin(), target:GetCurrentVisionRange(), THINK_INTERVAL, false)
    end
  end
end

function modifier_watch_tower_construction:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end
function modifier_watch_tower_construction:IsHidden()
  return true
end
function modifier_watch_tower_construction:IsDebuff()
  return false
end
function modifier_watch_tower_construction:IsPurgable()
  return false
end
function modifier_watch_tower_construction:CheckState()
  return {
    [MODIFIER_STATE_BLIND] = self:GetStackCount() > 0,
    [MODIFIER_STATE_FROZEN] = self:GetStackCount() > 0 -- animation seem to restart on each `SetOrigin()` call, causing jittery look.
  }
end
function modifier_watch_tower_construction:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH,
    MODIFIER_PROPERTY_BONUS_DAY_VISION,
    MODIFIER_PROPERTY_BONUS_NIGHT_VISION,
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
    MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
  }
end
function modifier_watch_tower_construction:OnDeath(data)
  if data.unit == self:GetParent() then
    self:GetParent():SetOriginalModel("models/props_structures/tower_upgrade/tower_upgrade_dest.vmdl")
    self:GetParent():ManageModelChanges()
    ParticleManager:CreateParticle("particles/world_tower/tower_upgrade/ti7_radiant_tower_lvl1_dest.vpcf", PATTACH_ABSORIGIN, data.unit)
  end
end
function modifier_watch_tower_construction:GetModifierConstantHealthRegen()
  if IsServer() and self:GetStackCount() > 0 then
    return self:GetParent():GetMaxHealth() / self:GetParent():Attribute_GetIntValue("construction_time", 10)
  else
    return 0
  end
end
function modifier_watch_tower_construction:GetBonusDayVision()
  if IsServer() then
    return self:GetParent():Attribute_GetIntValue("bonus_vision_range", 0)
  end
end
modifier_watch_tower_construction.GetBonusNightVision = modifier_watch_tower_construction.GetBonusDayVision
function modifier_watch_tower_construction:GetOverrideAnimation()
  return ACT_DOTA_CAPTURE
end
function modifier_watch_tower_construction:GetActivityTranslationModifiers()
  return "level"..self.level
end
