LinkLuaModifier("modifier_boss_resistance", "abilities/boss_resistance.lua", LUA_MODIFIER_MOTION_NONE) --- PERTH VIPPITY PARTIENCE
LinkLuaModifier("modifier_boss_truesight", "abilities/boss_resistance.lua", LUA_MODIFIER_MOTION_NONE)

boss_resistance = class(AbilityBaseClass)

function boss_resistance:GetIntrinsicModifierName()
  return "modifier_boss_resistance"
end

function boss_resistance:GetBehavior ()
  return DOTA_ABILITY_BEHAVIOR_PASSIVE
end

-----------------------------------------------------------------------------------------

modifier_boss_resistance = class(ModifierBaseClass)

function modifier_boss_resistance:IsHidden()
  return true
end

function modifier_boss_resistance:IsPurgable()
  return false
end

function modifier_boss_resistance:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
    MODIFIER_EVENT_ON_TAKEDAMAGE
  }
end

function modifier_boss_resistance:GetModifierTotal_ConstantBlock(keys)
  local damageReduction = self:GetAbility():GetSpecialValueFor("percent_damage_reduce")
  if keys.attacker == self:GetParent() then -- boss degen nonsense
    return 0
  end
  return keys.damage * damageReduction / 100
end

function modifier_boss_resistance:OnTakeDamage(keys)
  local parent = self:GetParent()
  if not keys.attacker or not keys.unit or keys.unit ~= parent then
    return
  end
  local ability = self:GetAbility()
  local revealDuration = ability:GetSpecialValueFor("reveal_duration")
  keys.attacker:AddNewModifier(parent, self:GetAbility(), "modifier_boss_truesight", {duration = revealDuration})
end

-- function modifier_boss_resistance:GetModifierIncomingDamage_Percentage(keys)
--   --[[
-- [   VScript              ]: process_procs: true
-- [   VScript              ]: order_type: 0
-- [   VScript              ]: issuer_player_index: 1982289334
-- [   VScript              ]: fail_type: 0
-- [   VScript              ]: damage_category: 0
-- [   VScript              ]: reincarnate: false
-- [   VScript              ]: distance: 0
-- [   VScript              ]: gain: 98.332176208496
-- [   VScript              ]: attacker: table: 0x00636d38
-- [   VScript              ]: ranged_attack: false
-- [   VScript              ]: record: 5
-- [   VScript              ]: activity: -1
-- [   VScript              ]: do_not_consume: false
-- [   VScript              ]: damage_type: 4
-- [   VScript              ]: heart_regen_applied: false
-- [   VScript              ]: diffusal_applied: false
-- [   VScript              ]: no_attack_cooldown: false
-- [   VScript              ]: cost: 0
-- [   VScript              ]: inflictor: table: 0x004bfe30
-- [   VScript              ]: damage_flags: 0
-- [   VScript              ]: original_damage: 650
-- [   VScript              ]: ignore_invis: false
-- [   VScript              ]: damage: 650
-- [   VScript              ]: basher_tested: false
-- [   VScript              ]: target: table: 0x00524320

--   local percentBaseSpells = {
--     death_prophet_spirit_siphon = true,
--     life_stealer_feast = true
--   }

--   print('--')
--   for k,v in pairs(keys) do
--     print(k .. ': ' .. tostring(v))
--   end
--   print('--')

--   local hero = keys.attacker

--   if hero and hero:IsRealHero and hero:IsRealHero() then
--     hero:
--   end
--   if not keys.inflictor then
--     return 0
--   end

--   local name = keys.inflictor:GetAbilityName()
--   if percentBaseSpells[name] then
--     print('Reducing incoming damage')
--     return 0 - self:GetAbility():GetSpecialValueFor("percent_damage_reduce")
--   end
-- ]]
--   local damageReduction = self:GetAbility():GetSpecialValueFor("percent_damage_reduce")
--   local parent = self:GetParent()
--   -- List of modifiers with all damage amplification that need to stack multiplicatively with Boss Resistance
--   local damageAmpModifiers = {
--     "modifier_bloodseeker_bloodrage",
--     "modifier_chen_penitence",
--     "modifier_shadow_demon_soul_catcher"
--   }
--   -- A list matched with the previous one for the AbilitySpecial keys that contain the damage amp values of the modifiers
--   local ampAbilitySpecialKeys = {
--     "damage_increase_pct",
--     "bonus_damage_taken",
--     "bonus_damage_taken"
--   }

--   -- Calculates a value that will counteract damage amplification from the named modifier such that
--   -- it's as if the damage amplification stacks multiplicatively with Boss Resistance
--   local function CalculateMultiplicativeAmpStack(modifierName, ampValueKey)
--     local modifiers = parent:FindAllModifiersByName(modifierName)

--     local function CalculateAmp(modifier)
--       if modifier:IsNull() then
--         return 0
--       else
--         local modifierDamageAmp = modifier:GetAbility():GetSpecialValueFor(ampValueKey)
--         return (100 - damageReduction) / 100 * modifierDamageAmp - modifierDamageAmp
--       end
--     end

--     return sum(map(CalculateAmp, modifiers))
--   end

--   local damageAmpReduction = sum(map(CalculateMultiplicativeAmpStack, zip(damageAmpModifiers, ampAbilitySpecialKeys)))
--   return 0 - damageReduction + damageAmpReduction
-- end

-----------------------------------------------------------------------------------------

modifier_boss_truesight = class(ModifierBaseClass)

function modifier_boss_truesight:OnCreated()
  self.maxRevealDist = self:GetAbility():GetSpecialValueFor("reveal_max_distance")
end

if IsServer() then
  function modifier_boss_truesight:CheckState()
    local parent = self:GetParent()
    local caster = self:GetCaster()

    -- Only reveal when within reveal_max_distance of boss
    if (parent:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D() <= self.maxRevealDist then
      return {
        [MODIFIER_STATE_INVISIBLE] = false
      }
    else
      return {}
    end
  end
end

function modifier_boss_truesight:IsPurgable()
  return false
end

function modifier_boss_truesight:IsDebuff()
  return true
end

function modifier_boss_truesight:GetTexture()
  return "item_gem"
end

function modifier_boss_truesight:IsHidden()
  local parent = self:GetParent()
  local caster = self:GetCaster()
  return (parent:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D() > self.maxRevealDist
end

function modifier_boss_truesight:GetPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA
end
