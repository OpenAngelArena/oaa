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
  local vanilla_ability = caster:FindAbilityByName("dragon_knight_elder_dragon_form")

  if vanilla_ability then
    if not caster:HasScepter() then
      if level >= 4 then
        vanilla_ability:SetLevel(4)
      else
        vanilla_ability:SetLevel(level)
      end
    else
      if level >= 3 then
        vanilla_ability:SetLevel(4)
        if level >= 5 then
          duration = -1
        end
      else
        vanilla_ability:SetLevel(level+1)
      end
    end
  else
    return
  end

  -- Cast the vanilla ability
  vanilla_ability:OnSpellStart()

  -- apply the standard dragon form modifier ( for movespeed and the model change )
  --caster:AddNewModifier( caster, ability, "modifier_dragon_knight_dragon_form", { duration = duration, } )

  -- apply the corrosive breath modifier, don't need to check its level really
  --caster:AddNewModifier( caster, ability, "modifier_dragon_knight_corrosive_breath", { duration = duration, } )

  -- apply the leveled modifiers
  --if level >= 2 then
    --caster:AddNewModifier( caster, ability, "modifier_dragon_knight_splash_attack", { duration = duration, } )
  --end

  --if level >= 3 then
    --caster:AddNewModifier( caster, ability, "modifier_dragon_knight_frost_breath", { duration = duration, } )
  --end

  if level >= 5 or ( level >= 4 and caster:HasScepter() ) then
    caster:AddNewModifier( caster, self, "modifier_dragon_knight_max_level_oaa", { duration = duration, } )
  end

  -- Manage Attack Projectile if there is none (if it's not handled with vanilla modifiers)
  --local projectile_name = caster:GetRangedProjectileName()
  --if not projectile_name or projectile_name == "" then
    --if self:IsStolen() then
      -- For Rubick if he doesn't have a projectile in Dragon Form at least add his base projectile
      --caster:SetRangedProjectileName(caster:GetBaseRangedProjectileName())
    --else
      --caster:ChangeAttackProjectile()
    --end
  --end
end

function dragon_knight_elder_dragon_form_oaa:GetIntrinsicModifierName()
  if self:GetLevel() >= 5 then
    return "modifier_dragon_knight_elder_dragon_form_oaa"
  end
end

--[[
function dragon_knight_elder_dragon_form_oaa:OnUpgrade()
  local caster = self:GetCaster()
  local ability_level = self:GetLevel()

  local vanilla_ability = caster:FindAbilityByName("dragon_knight_elder_dragon_form")
  if not vanilla_ability then
    return
  end

  if not caster:HasScepter() then
    if ability_level >= 4 then
      vanilla_ability:SetLevel(4)
    else
      vanilla_ability:SetLevel(ability_level)
    end
  else
    if ability_level >= 3 then
      vanilla_ability:SetLevel(4)
    else
      vanilla_ability:SetLevel(ability_level+1)
    end
  end
end
]]

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

-- function dragon_knight_elder_dragon_form_oaa:OnUnStolen()
  -- local caster = self:GetCaster()
  -- if caster:HasModifier("modifier_dragon_knight_elder_dragon_form_oaa") then
    -- caster:RemoveModifierByName("modifier_dragon_knight_elder_dragon_form_oaa")
  -- end
-- end

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
    -- Dragon Form modifiers
    local modifier = parent:FindModifierByName("modifier_dragon_knight_dragon_form")
    local modifier2 = parent:FindModifierByName("modifier_dragon_knight_black_dragon_tooltip")
    local modifier3 = parent:FindModifierByName("modifier_dragon_knight_max_level_oaa")
    if parent:HasScepter() then
      if not modifier or not modifier2 or not modifier3 then
        ability:OnSpellStart()
        return
      else
        if modifier then
          if modifier:GetDuration() ~= -1 then
            --ability:OnSpellStart()
            modifier:SetDuration(-1, true)
          end
        end
        if modifier2 then
          if modifier2:GetDuration() ~= -1 then
            --ability:OnSpellStart()
            modifier2:SetDuration(-1, true)
          end
        end
        if modifier3 then
          if modifier3:GetDuration() ~= -1 then
            --ability:OnSpellStart()
            modifier3:SetDuration(-1, true)
          end
        end
      end
    else
      -- Parent doesn't have scepter -> indirectly check if parent dropped/sold his scepter
      -- by checking if it has dragon form modifiers and by checking modifier durations
      if not modifier then
        -- Modifier doesn't exist and parent doesn't have scepter -> don't do anything
      else
        if modifier:GetDuration() == -1 then
          -- Duration of the modifier is -1 (infinite) but parent doesn't have scepter
          -- Recast the ability
          ability:OnSpellStart()
          return
        end
      end
      if not modifier2 then
        -- Modifier doesn't exist and parent doesn't have scepter -> don't do anything
      else
        if modifier2:GetDuration() == -1 then
          -- Duration of the modifier is -1 (infinite) but parent doesn't have scepter
          -- Recast the ability
          ability:OnSpellStart()
          return
        end
      end
      if not modifier3 then
        -- Modifier doesn't exist and parent doesn't have scepter -> don't do anything
      else
        if modifier3:GetDuration() == -1 then
          -- Duration of the modifier is -1 (infinite) but parent doesn't have scepter
          -- Recast the ability
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

--function modifier_dragon_knight_max_level_oaa:OnCreated()
  --local ability = self:GetAbility()
  --local mr_at_4 = ability:GetLevelSpecialValueFor("magic_resistance", 3)
  --local mr_at_5 = ability:GetLevelSpecialValueFor("magic_resistance", 4)

  --if mr_at_5 > mr_at_4 and mr_at_4 ~= 100 then
    --self.bonus_mr = 100 * (mr_at_5 - mr_at_4) / (100 - mr_at_4)
  --else
    --self.bonus_mr = 0
  --end
--end

--modifier_dragon_knight_max_level_oaa.OnRefresh = modifier_dragon_knight_max_level_oaa.OnCreated

function modifier_dragon_knight_max_level_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
    --MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
  }
end

--function modifier_dragon_knight_max_level_oaa:GetModifierMagicalResistanceBonus()
  --return self.bonus_mr
--end

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

    local duration = ability:GetSpecialValueFor("heal_reduction_duration")

    -- Apply the debuff
    target:AddNewModifier(parent, ability, "modifier_dragon_knight_frostbite_debuff_oaa", {duration = duration})
    target:ApplyNonStackableBuff(parent, ability, "modifier_item_enhancement_crude", duration)
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
  self.heal_suppression_pct = self:GetAbility():GetSpecialValueFor("health_restoration")
  -- No effect if caster is an illusion
  local caster = self:GetCaster()
  if caster:IsIllusion() then
    self:Destroy()
  end
end

modifier_dragon_knight_frostbite_debuff_oaa.OnRefresh = modifier_dragon_knight_frostbite_debuff_oaa.OnCreated

function modifier_dragon_knight_frostbite_debuff_oaa:OnDestroy()
  if not IsServer() then
    return
  end
  local parent = self:GetParent()
  local ability = self:GetAbility()
  local caster = self:GetCaster()
  if not parent or parent:IsNull() then
    return
  end
  local mods = parent:FindAllModifiersByName("modifier_item_enhancement_crude")
  for _, mod in pairs(mods) do
    if mod and not mod:IsNull() then
      local mod_ability = mod:GetAbility()
      local mod_caster = mod:GetCaster()
      if mod_ability and mod_caster then
        if mod_ability == ability and mod_caster == caster then
          mod:Destroy()
          break
        end
      end
    end
  end
end

function modifier_dragon_knight_frostbite_debuff_oaa:DeclareFunctions()
  return {
    --MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
    --MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
    --MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
    --MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_TOOLTIP,
  }
end

function modifier_dragon_knight_frostbite_debuff_oaa:OnTooltip()
  return self.heal_suppression_pct
end

-- function modifier_dragon_knight_frostbite_debuff_oaa:GetModifierHealAmplify_PercentageTarget()
  -- return -self.heal_suppression_pct
-- end

-- function modifier_dragon_knight_frostbite_debuff_oaa:GetModifierHPRegenAmplify_Percentage()
  -- return -self.heal_suppression_pct
-- end

-- Doesn't work, Thanks Valve!
-- function modifier_dragon_knight_frostbite_debuff_oaa:GetModifierLifestealRegenAmplify_Percentage()
  -- return -self.heal_suppression_pct
-- end

-- Doesn't work, Thanks Valve!
-- function modifier_dragon_knight_frostbite_debuff_oaa:GetModifierSpellLifestealRegenAmplify_Percentage()
  -- return -self.heal_suppression_pct
-- end
