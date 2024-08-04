dragon_knight_elder_dragon_form_oaa = class(AbilityBaseClass)

LinkLuaModifier( "modifier_dragon_knight_elder_dragon_form_oaa", "abilities/oaa_elder_dragon_form.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_dragon_knight_max_level_oaa", "abilities/oaa_elder_dragon_form.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_dragon_knight_frostbite_debuff_oaa", "abilities/oaa_elder_dragon_form.lua", LUA_MODIFIER_MOTION_NONE )

-- this makes the ability passive when it hits level 5 and caster has scepter
function dragon_knight_elder_dragon_form_oaa:GetBehavior()
  if self:GetLevel() >= 5 and self:GetCaster():HasScepter() then
    return DOTA_ABILITY_BEHAVIOR_PASSIVE
  end

  return self.BaseClass.GetBehavior(self)
end

-- this is meant to accompany the above, removing the mana cost and cooldown
-- from the tooltip when it becomes passive
function dragon_knight_elder_dragon_form_oaa:GetCooldown(level)
  local caster = self:GetCaster() or self:GetOwner()
  if (self:GetLevel() >= 5 or level >= 5) and caster:HasScepter() then
    return 0
  end

  return self.BaseClass.GetCooldown(self, level)
end

function dragon_knight_elder_dragon_form_oaa:GetManaCost(level)
  local caster = self:GetCaster() or self:GetOwner()
  if (self:GetLevel() >= 5 or level >= 5) and caster:HasScepter() then
    return 0
  end

  return self.BaseClass.GetManaCost(self, level)
end

function dragon_knight_elder_dragon_form_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local level = self:GetLevel()
  local duration = self:GetSpecialValueFor("duration")
  local ability = caster:FindAbilityByName("dragon_knight_elder_dragon_form")

  if ability then
    if level >= 4 then
      if caster:HasScepter() then
        ability:SetLevel(3)
      else
        ability:SetLevel(4)
      end
    end
  else
    ability = self
  end

  if level >= 5 and caster:HasScepter() then
    duration = -1
  end

  -- apply the standard dragon form modifier ( for movespeed and the model change )
  caster:AddNewModifier( caster, ability, "modifier_dragon_knight_dragon_form", { duration = duration, } )

  -- apply the corrosive breath modifier, don't need to check its level really
  caster:AddNewModifier( caster, ability, "modifier_dragon_knight_corrosive_breath", { duration = duration, } )

  -- apply the leveled modifiers
  if level >= 2 then
    caster:AddNewModifier( caster, ability, "modifier_dragon_knight_splash_attack", { duration = duration, } )
  end

  if level >= 3 then
    caster:AddNewModifier( caster, ability, "modifier_dragon_knight_frost_breath", { duration = duration, } )
  end

  if level >= 5 or ( level >= 4 and caster:HasScepter() ) then
    caster:AddNewModifier( caster, self, "modifier_dragon_knight_max_level_oaa", { duration = duration, } )
  end

  -- Manage Attack Projectile if there is none (if it's not handled with vanilla modifiers)
  local projectile_name = caster:GetRangedProjectileName()
  if not projectile_name or projectile_name == "" then
    if self:IsStolen() then
      -- For Rubick if he doesn't have a projectile in Dragon Form at least add his base projectile
      caster:SetRangedProjectileName(caster:GetBaseRangedProjectileName())
    else
      caster:ChangeAttackProjectile()
    end
  end
end

function dragon_knight_elder_dragon_form_oaa:GetIntrinsicModifierName()
  if self:GetLevel() >= 5 then
    return "modifier_dragon_knight_elder_dragon_form_oaa"
  end
end

function dragon_knight_elder_dragon_form_oaa:OnUpgrade()
  local caster = self:GetCaster()
  local ability_level = self:GetLevel()

  local vanilla_ability = caster:FindAbilityByName("dragon_knight_elder_dragon_form")
  if not vanilla_ability then
    return
  end

  if ability_level >= 4 then
    if caster:HasScepter() then
      vanilla_ability:SetLevel(3)
    else
      vanilla_ability:SetLevel(4)
    end
    return
  end

  vanilla_ability:SetLevel(ability_level)
end

-- function dragon_knight_elder_dragon_form_oaa:GetAssociatedSecondaryAbilities()
  -- return "dragon_knight_elder_dragon_form"
-- end

-- function dragon_knight_elder_dragon_form_oaa:OnStolen(hSourceAbility)
  -- local caster = self:GetCaster()
  -- local vanilla_ability = caster:FindAbilityByName("dragon_knight_elder_dragon_form")
  -- if not vanilla_ability then
    -- return
  -- end
  -- vanilla_ability:SetHidden(true)
-- end

function dragon_knight_elder_dragon_form_oaa:OnUnStolen()
  local caster = self:GetCaster()
  if caster:HasModifier("modifier_dragon_knight_elder_dragon_form_oaa") then
    caster:RemoveModifierByName("modifier_dragon_knight_elder_dragon_form_oaa")
  end
end

function dragon_knight_elder_dragon_form_oaa:ProcsMagicStick()
  if self:GetLevel() >= 5 and self:GetCaster():HasScepter() then
    return false
  end

  return true
end

---------------------------------------------------------------------------------------------------
-- This modifier handles lvl 5 and scepter equip/unequip edge cases
modifier_dragon_knight_elder_dragon_form_oaa = class(ModifierBaseClass)

function modifier_dragon_knight_elder_dragon_form_oaa:IsHidden()
  return true
end

function modifier_dragon_knight_elder_dragon_form_oaa:IsDebuff()
  return false
end

function modifier_dragon_knight_elder_dragon_form_oaa:IsPurgable()
  return false
end

function modifier_dragon_knight_elder_dragon_form_oaa:RemoveOnDeath()
  return false
end

function modifier_dragon_knight_elder_dragon_form_oaa:OnCreated()
  if not IsServer() then
    return
  end

  self:StartIntervalThink(1)
end

function modifier_dragon_knight_elder_dragon_form_oaa:OnRefresh()
  if not IsServer() then
    return
  end

  self:OnIntervalThink()
end

-- Check periodically if parent has scepter or not if the ability is level 5 or above
function modifier_dragon_knight_elder_dragon_form_oaa:OnIntervalThink()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()

  if not parent or parent:IsNull() then
    return
  end

  if parent:IsIllusion() then
    return
  end

  local ability = self:GetAbility() or parent:FindAbilityByName("dragon_knight_elder_dragon_form_oaa")

  if not ability or ability:IsNull() then
    return
  end

  if ability:GetLevel() >= 5 then
    -- Vanilla Dragon Form modifier
    local modifier = parent:FindModifierByName("modifier_dragon_knight_dragon_form")
    if parent:HasScepter() then
      if not modifier then
        ability:OnSpellStart()
      else
        if modifier:GetDuration() ~= -1 then
          ability:OnSpellStart()
        end
      end
    else
      -- Parent doesn't have scepter -> indirectly check if parent dropped/sold his scepter
      -- by checking if it has dragon form modifiers and by checking modifier durations
      if not modifier then
        -- Modifier doesn't exist and parent doesn't have scepter -> don't do anything
        return
      else
        if modifier:GetDuration() == -1 then
          -- Duration of the modifier is -1 (infinite) but parent doesn't have scepter
          -- Reapply Dragon Form modifiers to give them normal duration
          ability:OnSpellStart()
        end
      end
    end
  end
end

--[[
function modifier_dragon_knight_elder_dragon_form_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

-- Rage chance - chance to transform into Dragon Form when attack lands, doesn't matter what is the attacked target
if IsServer() then
  function modifier_dragon_knight_elder_dragon_form_oaa:OnAttackLanded(event)
    local parent = self:GetParent()
    local spell = self:GetAbility()
    local attacker = event.attacker
    local target = event.target

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if attacker ~= parent then
      return
    end

    -- no rage while broken
    if parent:PassivesDisabled() then
      return
    end

    if not spell or spell:GetLevel() ~= 4 then
      return
    end

    local chance = spell:GetSpecialValueFor( "rage_chance" ) / 100

    -- we're using the modifier's stack to store the amount of prng failures
    -- this could be something else but since this modifier is hidden anyway ...
    local prngMult = self:GetStackCount() + 1

    -- compared prng to slightly less prng
    if RandomFloat( 0.0, 1.0 ) <= ( PrdCFinder:GetCForP(chance) * prngMult ) then
      -- reset failure count
      self:SetStackCount( 0 )

      local duration = spell:GetSpecialValueFor( "rage_duration" )

      -- check if the ability is already active, and if so, grab the current
      -- duration
      local mod = parent:FindModifierByName( "modifier_dragon_knight_dragon_form" )

      if mod then
        duration = duration + mod:GetRemainingTime()
      end

      local edfMods = {
        "modifier_dragon_knight_dragon_form",
        "modifier_dragon_knight_corrosive_breath",
        "modifier_dragon_knight_splash_attack",
        "modifier_dragon_knight_frost_breath",
      }

      -- apply the edf modifiers with the new duration
      for _, modName in pairs( edfMods ) do
        parent:AddNewModifier( parent, spell, modName, { duration = duration } )
      end
    else
      -- increment failure count
      self:SetStackCount( prngMult )
    end
  end
end
]]

---------------------------------------------------------------------------------------------------

modifier_dragon_knight_max_level_oaa = class(ModifierBaseClass)

function modifier_dragon_knight_max_level_oaa:IsHidden()
  return false
end

function modifier_dragon_knight_max_level_oaa:IsDebuff()
  return false
end

function modifier_dragon_knight_max_level_oaa:IsPurgable()
  return false
end

function modifier_dragon_knight_max_level_oaa:RemoveOnDeath()
  return true
end

function modifier_dragon_knight_max_level_oaa:OnCreated()
  local ability = self:GetAbility()
  local mr_at_4 = ability:GetLevelSpecialValueFor("magic_resistance", 3)
  local mr_at_5 = ability:GetLevelSpecialValueFor("magic_resistance", 4)

  if mr_at_5 > mr_at_4 and mr_at_4 ~= 100 then
    self.bonus_mr = 100 * (mr_at_5 - mr_at_4) / (100 - mr_at_4)
  else
    self.bonus_mr = 0
  end
end

function modifier_dragon_knight_max_level_oaa:OnRefresh()
  self:OnCreated()
end

function modifier_dragon_knight_max_level_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
  }
end

function modifier_dragon_knight_max_level_oaa:GetModifierMagicalResistanceBonus()
  return self.bonus_mr
end

if IsServer() then
  function modifier_dragon_knight_max_level_oaa:OnAttackLanded(event)
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local attacker = event.attacker
    local target = event.target

    if parent:IsIllusion() then
      return
    end

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if attacker ~= parent then
      return
    end

    -- Check if attacked unit exists
    if not target or target:IsNull() then
      return
    end

    -- Check for existence of GetUnitName method to determine if target is a unit or an item (or rune)
    -- items don't have that method -> nil; if the target is an item, don't continue
    if target.GetUnitName == nil then
      return
    end

    -- Don't affect buildings, wards, spell-immune units and invulnerable units.
    if target:IsTower() or target:IsBarracks() or target:IsBuilding() or target:IsOther() or target:IsMagicImmune() or target:IsInvulnerable() then
      return
    end

    local duration = ability:GetSpecialValueFor("frost_duration")

    -- Apply the debuff
    target:AddNewModifier(parent, ability, "modifier_dragon_knight_frostbite_debuff_oaa", {duration = duration})
  end
end
---------------------------------------------------------------------------------------------------

modifier_dragon_knight_frostbite_debuff_oaa = class(ModifierBaseClass)

function modifier_dragon_knight_frostbite_debuff_oaa:IsHidden()
  return false
end

function modifier_dragon_knight_frostbite_debuff_oaa:IsDebuff()
  return true
end

function modifier_dragon_knight_frostbite_debuff_oaa:IsPurgable()
  return true
end

function modifier_dragon_knight_frostbite_debuff_oaa:GetEffectName()
  return "particles/items4_fx/spirit_vessel_damage.vpcf"
end

function modifier_dragon_knight_frostbite_debuff_oaa:OnCreated()
  self.heal_suppression_pct = self:GetAbility():GetSpecialValueFor("heal_suppression_pct")
  -- No effect if caster is an illusion
  local caster = self:GetCaster()
  if caster:IsIllusion() then
    self:Destroy()
  end
end

function modifier_dragon_knight_frostbite_debuff_oaa:OnRefresh()
  self.heal_suppression_pct = self:GetAbility():GetSpecialValueFor("heal_suppression_pct")
  -- No effect if caster is an illusion
  local caster = self:GetCaster()
  if caster:IsIllusion() then
    self:Destroy()
  end
end

function modifier_dragon_knight_frostbite_debuff_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
    MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
  }
end

function modifier_dragon_knight_frostbite_debuff_oaa:GetModifierHealAmplify_PercentageTarget()
  return -self.heal_suppression_pct
end

function modifier_dragon_knight_frostbite_debuff_oaa:GetModifierHPRegenAmplify_Percentage()
  return -self.heal_suppression_pct
end

function modifier_dragon_knight_frostbite_debuff_oaa:GetModifierLifestealRegenAmplify_Percentage()
  return -self.heal_suppression_pct
end

function modifier_dragon_knight_frostbite_debuff_oaa:GetModifierSpellLifestealRegenAmplify_Percentage()
  return -self.heal_suppression_pct
end
