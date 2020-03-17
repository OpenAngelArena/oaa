LinkLuaModifier("modifier_item_ward_stack", "items/ward_stack.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ward_stack_observers", "items/ward_stack.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ward_stack_sentries", "items/ward_stack.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ward_stack_aura", "items/ward_stack.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sentry_ward_recharger", "items/ward_stack.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_observer_ward_recharger", "items/ward_stack.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier('modifier_ward_invisibility', 'modifiers/modifier_ward_invisibility.lua', LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_intrinsic_multiplexer", "modifiers/modifier_intrinsic_multiplexer.lua", LUA_MODIFIER_MOTION_NONE)

item_ward_stack = class(ItemBaseClass)

Debug:EnableDebugging()

local WARD_TYPE_SENTRY = 1
local WARD_TYPE_OBSERVER = 2
local WARD_TYPE_OBSERVER_ONLY = 3
local WARD_TYPE_SENTRY_ONLY = 4
local WARD_TYPE_NONE = 5

local function wardTypeToString (ward)
  if ward == WARD_TYPE_SENTRY then
    return "sentry"
  elseif ward == WARD_TYPE_OBSERVER then
    return "observer"
  end
  return "unknown"
end

if IsServer() then
  -- active effect!
  function item_ward_stack:Setup ()
    local caster = self:GetCaster()

    if not caster.sentryCount then
      caster.sentryCount = 2
    end
    if not caster.observerCount then
      caster.observerCount = 2
    end
    if not self.wardType then
      self:SetType(WARD_TYPE_OBSERVER)
    end
  end
  function item_ward_stack:OnSpellStart ()
    self:Setup()
    local caster = self:GetCaster()
    local unit = false
    if not self:GetCursorTargetingNothing() then
      unit = self:GetCursorTarget()
    end
    local target = self:GetCursorPosition()
    local wardType = wardTypeToString(self.wardType)

    if unit == caster then
      return self:ToggleType()
    end

    if caster[wardType .. 'Count'] == 0 then
      self:ToggleType()
      wardType = wardTypeToString(self.wardType)
      if caster[wardType .. 'Count'] == 0 then
        return
      end
    end

    local ward = CreateUnitByName("npc_dota_" .. wardType .. "_wards", target, true, nil, caster, caster:GetTeam())
    if wardType == "sentry" then
      ward:AddNewModifier(ward, nil, "modifier_item_ward_true_sight", {
        true_sight_range = self:GetSpecialValueFor("sentry_reveal_radius"),
        duration = self:GetSpecialValueFor(wardType .. '_duration')
      })
    end
    ward:AddNewModifier(ward, nil, "modifier_item_buff_ward", {
      duration = self:GetSpecialValueFor(wardType .. '_duration')
    })

    caster[wardType .. 'Count'] = caster[wardType .. 'Count'] - 1
    if caster[wardType .. 'Count'] == 0 then
      self:ToggleType()
    end
    self.mod:OnWardTypeUpdate()
    EmitSoundOnLocationForAllies(target, "DOTA_Item.ObserverWard.Activate", caster)

    -- ward
  end

  function item_ward_stack:ToggleType ()
    self:Setup()
    local caster = self:GetCaster()
    local newVal = self.wardType % 2 + 1
    DebugPrint('Toggling! ' .. self.wardType .. '->' .. newVal)
    if caster[wardTypeToString(newVal) .. 'Count'] == 0 then
      return
    end
    self:SetType(newVal)
  end

  function item_ward_stack:SetType (type)
    self.wardType = type
    if self.mod then
      self.mod:OnWardTypeUpdate()
    end
  end

  function item_ward_stack:GetIntrinsicModifierName ()
    return "modifier_intrinsic_multiplexer"
  end

  function item_ward_stack:GetIntrinsicModifierNames ()
    return {
      "modifier_item_ward_stack",
      "modifier_item_ward_stack_observers",
      "modifier_item_ward_stack_sentries",
    }
  end
end

if not IsServer() then
  function item_ward_stack:GetAbilityTextureName()
    local wardType = self.lastType or WARD_TYPE_OBSERVER
    if self.mod and not self.mod:IsNull() then
      wardType = self.mod:GetStackCount()
    end
    self.lastType = wardType
    if wardType == WARD_TYPE_OBSERVER then
      return "item_ward_dispenser"
    elseif wardType == WARD_TYPE_SENTRY then
      return "item_ward_dispenser_sentry"
    elseif wardType == WARD_TYPE_SENTRY_ONLY then
      return "item_ward_sentry"
    elseif wardType == WARD_TYPE_OBSERVER_ONLY then
      return "item_ward_observer"
    else
      return "item_branches"
    end
  end
end

function item_ward_stack:CastFilterResultTarget (unit)
  if unit == self:GetCaster() then
    return UF_SUCCESS
  end
  return UF_FAIL_INVALID_LOCATION
end

item_ward_stack_2 = item_ward_stack
item_ward_stack_3 = item_ward_stack
item_ward_stack_4 = item_ward_stack
item_ward_stack_5 = item_ward_stack

--------------------------------------------------------------------------
-- observer/sentry count in status bar
--------------------------------------------------------------------------
local WARD_INTERVAL = 0.2
modifier_item_ward_stack_sentries = class(ModifierBaseClass)

function modifier_item_ward_stack_sentries:OnCreated (keys)
  local wardStack = self:GetAbility()
  self.wardStack = wardStack
  self.wasMaxed = false

  if not IsServer() then
    return
  end

  self:StartIntervalThink(WARD_INTERVAL)
  self.wardStack[self:WardName() .. "IntervalCount"] = self.wardStack[self:WardName() .. "IntervalCount"] or 0

  DebugPrint('Init ' .. self:WardName() .. ' with ' .. self:GetStackCount() .. '/' .. self.wardStack[self:WardName() .. "IntervalCount"])
end

function modifier_item_ward_stack_sentries:OnDestroy ()
  if IsServer() then
    local caster = self:GetCaster()
    local modifierCharger = 'modifier_' .. self:WardName() .. '_ward_recharger'

    caster:RemoveModifierByName(modifierCharger)
  end
end

function modifier_item_ward_stack_sentries:IsHidden ()
  return true
end

function modifier_item_ward_stack_sentries:GetIntervalCount ()
  local count =  self:GetAbility():GetSpecialValueFor(self:WardName() .. '_recharge')
  return count
end
function modifier_item_ward_stack_sentries:GetMaxStack ()
  local count = self:GetAbility():GetSpecialValueFor(self:WardName() .. '_max')
  return count
end

function modifier_item_ward_stack_sentries:OnIntervalThink ()
  if not IsServer() then
    return
  end
  local caster = self:GetCaster()
  local maxStack = self:GetMaxStack()
  local currentStack = caster[self:WardName() .. "Count"] or 0
  local localStack = self:GetStackCount()
  local ability = self:GetAbility()

  if localStack ~= currentStack then
    self:SetStackCount(currentStack)
    localStack = currentStack
  end

  if self.charger and not self.charger:IsNull() then
    if self.charger:GetStackCount() ~= currentStack then
      self.charger:SetStackCount(currentStack)
    end
  end

  local intervalCount = self:WardName() .. "IntervalCount"
  local modifierCharger = 'modifier_' .. self:WardName() .. '_ward_recharger'
  local maxCount = self:GetIntervalCount()

  -- DebugPrint('Intervalling! ' .. localStack .. '/' .. currentStack .. '/' .. maxStack .. ' at ' .. self.wardStack[intervalCount] .. '/' .. maxCount)

  if currentStack >= maxStack then
    local isCharging = caster:HasModifier(modifierCharger)
    if isCharging then
      return
    end

    self.charger = caster:AddNewModifier(caster, ability, modifierCharger, {})
    self.wasMaxed = true
    return
  end

  -- DebugPrint('Increasing interval from ' .. self.wardStack[intervalCount] .. ' to ' .. (self.wardStack[intervalCount] + WARD_INTERVAL))
  self.wardStack[intervalCount] = self.wardStack[intervalCount] + WARD_INTERVAL

  if self.wardStack[intervalCount] > maxCount then
    self.wardStack[intervalCount] = 0
    currentStack = currentStack + 1
    caster[self:WardName() .. "Count"] = currentStack
    self:SetStackCount(currentStack)
    caster:RemoveModifierByName(modifierCharger)
    if ability.mod then
      ability.mod:OnWardTypeUpdate()
    end
    self.wasMaxed = false
  end

  local isCharging = caster:HasModifier(modifierCharger)

  if isCharging then
    if self.wasMaxed then
      caster:RemoveModifierByName(modifierCharger)
      self.wasMaxed = false
    end
    return
  end
  if currentStack >= maxStack then
    return
  end

  DebugPrint('Adding new charger!')
  self.charger = caster:AddNewModifier(caster, ability, modifierCharger, { duration = self:GetIntervalCount() - self.wardStack[intervalCount] } )
end

modifier_item_ward_stack_sentries.OnRefresh = modifier_item_ward_stack_sentries.OnCreated
modifier_item_ward_stack_observers = class(modifier_item_ward_stack_sentries)

function modifier_item_ward_stack_sentries:IsPurgable ()
  return false
end

function modifier_item_ward_stack_observers:IsPurgable ()
  return false
end

function modifier_item_ward_stack_sentries:IsHidden ()
  return true
end
function modifier_item_ward_stack_observers:IsHidden ()
  return true
end

function modifier_item_ward_stack_observers:WardName ()
  return "observer"
end
function modifier_item_ward_stack_sentries:WardName ()
  return "sentry"
end

modifier_sentry_ward_recharger = class(ModifierBaseClass)

function modifier_sentry_ward_recharger:OnCreated (keys)
  local caster = self:GetCaster()
  local wardStack = self:GetAbility()
  self.wardStack = wardStack

  if IsServer() then
    self:SetStackCount(caster[self:WardName() .. "Count"] or 0)
  end
end

function modifier_sentry_ward_recharger:IsHidden ()
  return false
end

function modifier_sentry_ward_recharger:GetTexture ()
  return "item_ward_" .. self:WardName()
end

modifier_sentry_ward_recharger.OnRefresh = modifier_sentry_ward_recharger.OnCreated
modifier_observer_ward_recharger = class(modifier_sentry_ward_recharger)

function modifier_observer_ward_recharger:WardName ()
  return "observer"
end
function modifier_sentry_ward_recharger:WardName ()
  return "sentry"
end

function modifier_sentry_ward_recharger:IsPurgable ()
  return false
end

function modifier_observer_ward_recharger:IsPurgable ()
  return false
end

--------------------------------------------------------------------------
-- modifier_item_ward_stack
--------------------------------------------------------------------------

modifier_item_ward_stack = class(ModifierBaseClass) -- AuraProviderBaseClass

function modifier_item_ward_stack:OnCreated(keys)
  self.BaseClass.OnCreated(self, keys)

  self:OnWardTypeUpdate()
end

function modifier_item_ward_stack:OnWardTypeUpdate ()
  local item = self:GetAbility()
  item.mod = self
  if IsServer() then
    item:Setup()
    local caster = self:GetCaster()
    local count = item.wardType or WARD_TYPE_OBSERVER
    if caster.observerCount == 0 and caster.sentryCount > 0 then
      count = WARD_TYPE_SENTRY_ONLY
    end
    if caster.sentryCount == 0 and caster.observerCount > 0 then
      count = WARD_TYPE_OBSERVER_ONLY
    end
    if caster.sentryCount == 0 and caster.observerCount == 0 then
      count = WARD_TYPE_NONE
    end

    self:SetStackCount(count)
  end
end

function modifier_item_ward_stack:IsHidden()
  return true
end

function modifier_item_ward_stack:IsDebuff()
  return false
end

function modifier_item_ward_stack:IsPurgable()
  return false
end

function modifier_item_ward_stack:IsAura()
  return true
end

-- aura stuff
--function modifier_item_ward_stack:GetAuraStackingType()
  --return AURA_TYPE_NON_STACKING
--end

--function modifier_item_ward_stack:IsAuraActiveOnDeath()
  --return true
--end

function modifier_item_ward_stack:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor('aura_radius')
end

function modifier_item_ward_stack:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

--function modifier_item_ward_stack:GetAuraDuration()
  --return 1
--end

function modifier_item_ward_stack:GetModifierAura()
  return "modifier_item_ward_stack_aura"
end

function modifier_item_ward_stack:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_item_ward_stack:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
end

function modifier_item_ward_stack:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_INVULNERABLE, DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD)
end

-- passive stats
function modifier_item_ward_stack:DeclareFunctions ()
  return {
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    --MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_HEALTH_BONUS
    --MODIFIER_PROPERTY_MANA_BONUS
  }
end

function modifier_item_ward_stack:GetModifierConstantHealthRegen()
  return self:GetAbility():GetSpecialValueFor('bonus_health_regen')
end

--function modifier_item_ward_stack:GetModifierPhysicalArmorBonus()
  --return self:GetAbility():GetSpecialValueFor('bonus_armor')
--end

function modifier_item_ward_stack:GetModifierHealthBonus()
  return self:GetAbility():GetSpecialValueFor('bonus_health')
end

--function modifier_item_ward_stack:GetModifierManaBonus()
  --return self:GetAbility():GetSpecialValueFor('bonus_mana')
--end

function modifier_item_ward_stack:GetModifierBonusStats_Strength()
  return self:GetAbility():GetSpecialValueFor('bonus_all_stats')
end

function modifier_item_ward_stack:GetModifierBonusStats_Agility()
  return self:GetAbility():GetSpecialValueFor('bonus_all_stats')
end

function modifier_item_ward_stack:GetModifierBonusStats_Intellect()
  return self:GetAbility():GetSpecialValueFor('bonus_all_stats')
end

--------------------------------------------------------------------------
-- modifier_item_ward_stack_aura
--------------------------------------------------------------------------

modifier_item_ward_stack_aura = class(ModifierBaseClass) -- AuraEffectBaseClass

function modifier_item_ward_stack_aura:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MANA_REGEN_CONSTANT
  }
end

function modifier_item_ward_stack_aura:GetModifierConstantManaRegen()
  return self:GetAbility():GetSpecialValueFor('aura_mana_regen')
end

function modifier_item_ward_stack_aura:IsHidden()
  return true
end

function modifier_item_ward_stack_aura:IsDebuff()
  return false
end

function modifier_item_ward_stack_aura:IsPurgable()
  return false
end
