LinkLuaModifier("modifier_item_ward_stack", "items/ward_stack.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ward_stack_observers", "items/ward_stack.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ward_stack_sentries", "items/ward_stack.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ward_stack_aura", "items/ward_stack.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier('modifier_ward_invisibility', 'modifiers/modifier_ward_invisibility.lua', LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_intrinsic_multiplexer", "modifiers/modifier_intrinsic_multiplexer.lua", LUA_MODIFIER_MOTION_NONE)

item_ward_stack = class(ItemBaseClass)

Debug:EnableDebugging()

local WARD_TYPE_SENTRY = 1
local WARD_TYPE_OBSERVER = 2

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

    if not self.wardType then
      self.wardType = WARD_TYPE_SENTRY
    end
    if not caster.sentryCount then
      caster.sentryCount = 2
    end
    if not caster.observerCount then
      caster.observerCount = 2
    end
  end
  function item_ward_stack:OnSpellStart ()
    self:Setup()
    local caster = self:GetCaster()
    local unit = false
    if not self:GetCursorTargetingNothing() then
      unit = self:GetCursorTarget()
    end
    local caster = self:GetCaster()
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
    ward:AddNewModifier(ward, nil, "modifier_kill", { duration = self:GetSpecialValueFor(wardType .. '_duration') })
    ward:AddNewModifier(ward, nil, "modifier_ward_invisibility", { invisible = true })

    caster[wardType .. 'Count'] = caster[wardType .. 'Count'] - 1
    if caster[wardType .. 'Count'] == 0 then
      self:ToggleType()
    end
    -- ward
  end

  function item_ward_stack:ToggleType ()
    self:Setup()
    local newVal = self.wardType % 2 + 1
    if self[wardTypeToString(newVal) .. 'Count'] == nil then
      self[wardTypeToString(newVal) .. 'Count'] = 0
      return
    end
    if self[wardTypeToString(newVal) .. 'Count'] == 0 then
      return
    end
    self.wardType = newVal
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

function item_ward_stack:CastFilterResultTarget (unit)
  if unit == self:GetCaster() then
    return UF_SUCCESS
  end
  return UF_FAIL_INVALID_LOCATION
end

item_ward_stack_2 = item_ward_stack
item_ward_stack_3 = item_ward_stack
item_ward_stack_4 = item_ward_stack

--------------------------------------------------------------------------
-- observer/sentry count in status bar
--------------------------------------------------------------------------
local WARD_INTERVAL = 0.2
modifier_item_ward_stack_sentries = class(ModifierBaseClass)

function modifier_item_ward_stack_sentries:OnCreated ()
  local wardStack = self:GetAbility()
  self.wardStack = wardStack
  self:SetStackCount(self.wardStack[self:WardName() .. "Count"])

  self:StartIntervalThink(WARD_INTERVAL)
  self.wardStack[self:WardName() .. "IntervalCount"] = self.wardStack[self:WardName() .. "IntervalCount"] or 0
end

function modifier_item_ward_stack_sentries:OnDestroy ()
  local caster = self:GetCaster()
  local modifierCharger = 'modifier_' .. self:WardName() .. '_ward_recharger'

  caster:RemoveModifierByName(modifierCharger)
end

function modifier_item_ward_stack_sentries:IsHidden ()
  return true
end

function modifier_item_ward_stack_sentries:GetIntervalCount ()
  return self:GetAbility():GetSpecialValueFor(self:GetName() .. '_recharge')
end
function modifier_item_ward_stack_sentries:GetMaxStack ()
  return self:GetAbility():GetSpecialValueFor(self:GetName() .. '_max')
end

function modifier_item_ward_stack_sentries:OnIntervalThink ()
  local caster = self:GetCaster()
  local maxStack = self:GetMaxStack()
  local currentStack = self:GetStackCount()

  local intervalCount = self:WardName() .. "IntervalCount"
  local modifierCharger = 'modifier_' .. self:WardName() .. '_ward_recharger'

  if currentStack >= maxStack then
    local isCharging = caster:HasModifier(modifierCharger)
    if isCharging then
      return
    end

    local ability = self:GetAbility()
    caster:AddNewModifier(caster, ability, modifierCharger, {})
    return
  end

  self.wardStack[intervalCount] = self.wardStack[intervalCount] + WARD_INTERVAL
  local maxCount = self:GetIntervalCount()

  if self.wardStack[intervalCount] > maxCount then
    self.wardStack[intervalCount] = 0
    currentStack = currentStack + 1
    self:SetStackCount(currentStack)
    caster:RemoveModifierByName(modifierCharger)
  end

  local isCharging = caster:HasModifier(modifierCharger)

  if isCharging then
    return
  end
  if currentStack >= maxStack then
    return
  end

  local ability = self:GetAbility()
  caster:AddNewModifier(caster, ability, modifierCharger, { duration = self:GetIntervalCount() - self.wardStack[intervalCount] } )
end

modifier_item_ward_stack_sentries.OnRefresh = modifier_item_ward_stack_sentries.OnCreated
modifier_item_ward_stack_observers = class(modifier_item_ward_stack_sentries)

function modifier_item_ward_stack_observers:WardName ()
  return "observer"
end
function modifier_item_ward_stack_sentries:WardName ()
  return "sentry"
end

modifier_sentry_ward_recharger = class(ModifierBaseClass)

function modifier_sentry_ward_recharger:OnCreated ()
  local wardStack = self:GetAbility()
  self.wardStack = wardStack

  self:SetStackCount(self.wardStack[self:WardName() .. "Count"])
end

function modifier_sentry_ward_recharger:IsHidden ()
  return false
end

function modifier_item_ward_stack_sentries:GetTexture ()
  return "item_" .. self:GetName() .. "_ward"
end

modifier_sentry_ward_recharger.OnRefresh = modifier_sentry_ward_recharger.OnCreated
modifier_observer_ward_recharger = class(modifier_sentry_ward_recharger)

function modifier_observer_ward_recharger:WardName ()
  return "observer"
end
function modifier_sentry_ward_recharger:WardName ()
  return "sentry"
end

--------------------------------------------------------------------------
-- modifier_item_ward_stack
--------------------------------------------------------------------------

modifier_item_ward_stack = class(AuraProviderBaseClass)

function modifier_item_ward_stack:IsHidden()
  return true
end

-- aura stuff
function modifier_item_ward_stack:GetAuraStackingType()
  return AURA_TYPE_NON_STACKING
end

function modifier_item_ward_stack:IsAuraActiveOnDeath()
  return true
end

function modifier_item_ward_stack:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor('aura_radius')
end

function modifier_item_ward_stack:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_ward_stack:GetAuraDuration()
  return 1
end

function modifier_item_ward_stack:GetModifierAura()
  return "modifier_item_ward_stack_aura"
end

-- passive stats
function modifier_item_ward_stack:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_MANA_BONUS
  }
end

function modifier_item_ward_stack:GetModifierConstantHealthRegen()
  return self:GetAbility():GetSpecialValueFor('bonus_health_regen')
end
function modifier_item_ward_stack:GetModifierPhysicalArmorBonus()
  return self:GetAbility():GetSpecialValueFor('bonus_armor')
end
function modifier_item_ward_stack:GetModifierHealthBonus()
  return self:GetAbility():GetSpecialValueFor('bonus_health')
end
function modifier_item_ward_stack:GetModifierManaBonus()
  return self:GetAbility():GetSpecialValueFor('bonus_mana')
end

--------------------------------------------------------------------------
-- modifier_item_ward_stack_aura
--------------------------------------------------------------------------

modifier_item_ward_stack_aura = class(AuraEffectBaseClass)

function modifier_item_ward_stack_aura:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MANA_REGEN_CONSTANT
  }
end

function modifier_item_ward_stack_aura:GetModifierConstantManaRegen()
  return self:GetAbility():GetSpecialValueFor('aura_mana_regen')
end
