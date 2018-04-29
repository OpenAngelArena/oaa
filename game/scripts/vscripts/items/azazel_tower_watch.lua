LinkLuaModifier("modifier_watch_tower_construction", "items/azazel_tower_watch.lua", LUA_MODIFIER_MOTION_NONE)

item_azazel_tower_watch_1 = class(ItemBaseClass)

function item_azazel_tower_watch_1:OnSpellStart()
  local caster = self:GetCaster()
  local tester = CreateUnitByName("npc_space_finder", self:GetCursorPosition(), true, nil, nil, DOTA_TEAM_NEUTRALS)
  FindClearSpaceForUnit(tester,self:GetCursorPosition(),true)
  local location = tester:GetOrigin()
  UTIL_Remove(tester)
  local building = CreateUnitByName("npc_azazel_tower_watch", location, true, caster, caster:GetOwner(), caster:GetTeam())
  building:SetOrigin(location)
  building:RemoveModifierByName('modifier_invulnerable')
  building:AddNewModifier(building, self, "modifier_watch_tower_construction", {duration = -1})
  building:SetOwner(caster)
  --building:SetForwardVector((location - caster:GetOrigin()):Normalized()) -- buildings can't be rotated.
end

-- upgrades
item_azazel_tower_watch_2 = item_azazel_tower_watch_1
item_azazel_tower_watch_3 = item_azazel_tower_watch_1
item_azazel_tower_watch_4 = item_azazel_tower_watch_1

--------------------------------------------------------------------------
-- base modifier

modifier_watch_tower_construction = class(ModifierBaseClass)

local SINK_HEIGHT = 300
local THINK_INTERVAL = 0.1

function modifier_watch_tower_construction:OnCreated()
  if IsServer() then
    local target = self:GetParent()
    local ab = self:GetAbility()
    local maxhealth = target:GetMaxHealth() + ab:GetSpecialValueFor("bonus_health")
    local location = target:GetOrigin()
    target:SetOrigin(GetGroundPosition(location, target) - Vector(0, 0, SINK_HEIGHT))
    target:SetMaxHealth(maxhealth)
    target:SetHealth(maxhealth * 0.01)
    self:StartIntervalThink(THINK_INTERVAL)
    self:SetStackCount(math.floor(ab:GetSpecialValueFor("construction_time") / THINK_INTERVAL) - 1) -- `construction_time` should be divisible by `THINK_INTERVAL`!
  end
end

function modifier_watch_tower_construction:OnIntervalThink()
  if IsServer() then
    local target = self:GetParent()
    local count = self:GetStackCount()
    if count > 0 then
      local time = self:GetAbility():GetSpecialValueFor("construction_time")
      local location = target:GetOrigin()
      target:SetOrigin(target:GetOrigin() + Vector(0, 0, SINK_HEIGHT / (time / THINK_INTERVAL)))
      self:SetStackCount(count - 1)
    end
    AddFOWViewer(target:GetTeam(), target:GetOrigin(), target:GetCurrentVisionRange(), THINK_INTERVAL, false)
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

function modifier_watch_tower_construction:DeclareFunctions()
  return {
    --MODIFIER_EVENT_ON_DEATH,
    MODIFIER_PROPERTY_BONUS_DAY_VISION,
    MODIFIER_PROPERTY_BONUS_NIGHT_VISION,
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
  }
end

function modifier_watch_tower_construction:OnDeath(data)
  if data.unit == self:GetParent() then
    --self:GetParent():SetModel("models/props_structures/radiant_tower002_destruction.vmdl") -- doesn't seem to work.
    self:GetParent():SetOriginalModel("models/props_structures/radiant_tower002_destruction.vmdl")
    self:GetParent():ManageModelChanges()
  end
end

function modifier_watch_tower_construction:GetModifierConstantHealthRegen()
  if self:GetStackCount() > 0 then
    return self:GetParent():GetMaxHealth() / self:GetAbility():GetSpecialValueFor("construction_time")
  else
    return 0
  end
end

function modifier_watch_tower_construction:GetBonusDayVision()
  return self:GetAbility():GetSpecialValueFor("bonus_vision_range")
end
modifier_watch_tower_construction.GetBonusNightVision = modifier_watch_tower_construction.GetBonusDayVision
