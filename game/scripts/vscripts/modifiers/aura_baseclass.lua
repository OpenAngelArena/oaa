require('libraries/functional')

-- Only one instance of the effect modifier is allowed
AURA_TYPE_NON_STACKING = 0
-- This is like vanilla Dota behaviour where multiple instances
-- of the same aura from the same unit do not stack, but can stack with
-- other units having the same aura
AURA_TYPE_STACK_DIFF_CASTER = 1
-- Auras stack, even from the same unit
AURA_TYPE_FULLY_STACKING = 2

AuraProviderBaseClass = class(ModifierBaseClass)

function AuraProviderBaseClass:IsPurgable()
  return false
end

function AuraProviderBaseClass:IsHidden()
  return true
end

function AuraProviderBaseClass:RemoveOnDeath()
  return false
end

if IsServer() then
  function AuraProviderBaseClass:OnCreated(keys)
    self:StartIntervalThink(0.03)
  end

  function AuraProviderBaseClass:OnIntervalThink()
    local parent = self:GetParent()
    if not self:IsAuraActiveOnDeath() and not parent:IsAlive() then
      return
    end
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local trackerModName = "modifier_aura_origin_tracker"
    local effectModName = self:GetModifierAura()
    self.unitCache = self.unitCache or {}
    local units = FindUnitsInRadius(
      caster:GetTeamNumber(),
      caster:GetAbsOrigin(),
      self.unitCache,
      self:GetAuraRadius(),
      self:GetAuraSearchTeam(),
      self:GetAuraSearchType(),
      self:GetAuraSearchFlags(),
      FIND_ANY_ORDER,
      true
    )
    iter(units)
      :filter(compose(op.lnot, partial(self.GetAuraEntityReject, self)))
      :each(function(unit)
        local modifierName
        local auraStackType = self:GetAuraStackingType()
        -- We don't need the origin tracker if every source of the aura applies its own
        -- instance of the effect, so we can just apply the effect modifier directly
        if auraStackType == AURA_TYPE_FULLY_STACKING then
          modifierName = effectModName
        else
          modifierName = trackerModName
        end

        -- Search the unit for tracker/effect modifiers that are tied to the same item/ability as self
        local modifiers = unit:FindAllModifiersByName(modifierName)
        local existingIndex = iter(modifiers)
                                :map(CallMethod("GetAbility"))
                                :index(ability)
        -- If the above search found a modifier, we just reset its duration
        if existingIndex then
          modifiers[existingIndex]:SetDuration(self:GetAuraDuration(), false)
        -- Else create the modifier
        else
          unit:AddNewModifier(
            caster,
            ability,
            modifierName,
            {
              duration = self:GetAuraDuration(),
              effectModName = effectModName,
              auraStackType = auraStackType,
              removeOnDeath = bit.band(self:GetAuraSearchFlags(), DOTA_UNIT_TARGET_FLAG_DEAD) ~= 0,
              isProvidedByAura = 1 -- This makes the UI not display modifier duration
            }
          )
        end
      end)
  end
end

--------------------------------------------------------------------------------

modifier_aura_origin_tracker = class(ModifierBaseClass)

function modifier_aura_origin_tracker:IsHidden()
  return true
end

function modifier_aura_origin_tracker:IsPurgable()
  return false
end

function modifier_aura_origin_tracker:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_aura_origin_tracker:RemoveOnDeath()
  return self.removeOnDeath
end

if IsServer() then
  function modifier_aura_origin_tracker:OnCreated(keys)
    local parent = self:GetParent()
    local caster = self:GetCaster()
    -- Must save reference so that we can still call RemoveParentAbility properly if item/ability gets deleted
    self.ability = self:GetAbility()
    local auraStackType = keys.auraStackType
    local effectModName = keys.effectModName
    self.removeOnDeath = keys.removeOnDeath

    if auraStackType == AURA_TYPE_NON_STACKING then
      self.modifier = parent:FindModifierByName(effectModName)
    elseif auraStackType == AURA_TYPE_STACK_DIFF_CASTER then
      self.modifier = parent:FindModifierByNameAndCaster(effectModName, caster)
    end

    if not self.modifier then
      self.modifier = parent:AddNewModifier(caster, self.ability, effectModName, {removeOnDeath = self.removeOnDeath})
    end
    self.modifier:AddParentAbility(self.ability)
  end

  function modifier_aura_origin_tracker:OnDestroy()
    if not self.modifier:IsNull() then
      self.modifier:RemoveParentAbility(self.ability)
    end
  end
end

--------------------------------------------------------------------------------

AuraEffectBaseClass = class(ModifierBaseClass)

-- If self:GetAbility() returns a valid ability reference, calls func with ability as an argument,
-- saves the result under the given storagePropName on self, and returns it
-- Otherwise, returns the last saved value under storagePropName
function AuraEffectBaseClass:SafeCallWithAbility(storagePropName, func)
  local ability = self:GetAbility()
  if IsValidEntity(ability) then
    self[storagePropName] = func(ability)
  end
  return self[storagePropName]
end

function AuraEffectBaseClass:RemoveOnDeath()
  return self.removeOnDeath
end

function AuraEffectBaseClass:IsPurgable()
  return false
end

function AuraEffectBaseClass:OnCreated(keys)
  self.removeOnDeath = keys.removeOnDeath
  self.parentAbilities = {}
end

function AuraEffectBaseClass:GetAbility()
  return self.ability or self.BaseClass.GetAbility(self)
end

if IsServer() then
  function AuraEffectBaseClass:UpdateActiveParentAbility()
    local function higherLevelAbility(abil1, abil2)
      if not abil1 or abil2:GetLevel() > abil1:GetLevel() then
        return abil2
      else
        return abil1
      end
    end

    self.ability = iter(self.parentAbilities)
                    :filter(IsValidEntity) -- TEST IsValidEntity
                    :reduce(higherLevelAbility, nil)
    -- Do some stack count hackery to synchronise the client modifier's ability reference
    if self.ability then
      self:SetStackCount(self.ability:entindex())
    end
  end

  function AuraEffectBaseClass:AddParentAbility(ability)
    table.insert(self.parentAbilities, ability)
    self:UpdateActiveParentAbility()
  end

  function AuraEffectBaseClass:RemoveParentAbility(ability)
    local abilityIndex = index(ability, self.parentAbilities)

    if abilityIndex then
      table.remove(self.parentAbilities, abilityIndex)

      -- If the removed ability was the last one in self.parentAbilities destroy the modifier
      if not self.parentAbilities[1] then
        self:Destroy()
      else
        self:UpdateActiveParentAbility()
      end
    end
  end
end

if IsClient() then
  function AuraEffectBaseClass:GetTexture()
    -- Do some stack count hackery to synchronise the client modifier's ability reference
    local stackCount = self:GetStackCount()
    if stackCount ~= 0 then
      self.ability = EntIndexToHScript(stackCount)
      self:SetStackCount(0)
    end
    return self:SafeCallWithAbility("savedTextureName", CallMethod("GetAbilityTextureName"))
  end
end
