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
    if not self.wardType then
      self.wardType = WARD_TYPE_SENTRY
    end
    if not self.sentryCount then
      self.sentryCount = 0
    end
    if not self.observerCount then
      self.sentryCount = 0
    end
  end
  function item_ward_stack:OnSpellStart ()
    self:Setup()
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

    if self[wardType .. 'Count'] == 0 then
      self:ToggleType()
      wardType = wardTypeToString(self.wardType)
      if self[wardType .. 'Count'] == 0 then
        return
      end
    end

    local ward = CreateUnitByName("npc_dota_" .. wardType .. "_wards", target, true, nil, caster, caster:GetTeam())
    ward:AddNewModifier(ward, nil, "modifier_kill", { duration = self:GetSpecialValueFor(wardType .. '_duration') })
    ward:AddNewModifier(ward, nil, "modifier_ward_invisibility", { invisible = true })

    self[wardType .. 'Count'] = self[wardType .. 'Count'] - 1
    if self[wardType .. 'Count'] == 0 then
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
modifier_item_ward_stack_observers = class(ModifierBaseClass)
modifier_item_ward_stack_sentries = class(ModifierBaseClass)

function modifier_item_ward_stack_observers:GetTexture()
  return "item_observer_ward"
end
function modifier_item_ward_stack_sentries:GetTexture()
  return "item_sentry_ward"
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
