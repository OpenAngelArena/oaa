alpha_wolf_critical_strike_aura_oaa = class(AbilityBaseClass)

LinkLuaModifier("modifier_alpha_critical_strike_aura_oaa_applier", "abilities/neutrals/oaa_alpha_wolf_critical_strike_aura.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_alpha_critical_strike_aura_oaa_effect", "abilities/neutrals/oaa_alpha_wolf_critical_strike_aura.lua", LUA_MODIFIER_MOTION_NONE )

function alpha_wolf_critical_strike_aura_oaa:GetIntrinsicModifierName()
  return "modifier_alpha_critical_strike_aura_oaa_applier"
end

--------------------------------------------------------------------------------

modifier_alpha_critical_strike_aura_oaa_applier = class(ModifierBaseClass)

function modifier_alpha_critical_strike_aura_oaa_applier:IsHidden()
  return true
end

function modifier_alpha_critical_strike_aura_oaa_applier:IsDebuff()
  return false
end

function modifier_alpha_critical_strike_aura_oaa_applier:IsPurgable()
  return false
end

function modifier_alpha_critical_strike_aura_oaa_applier:IsAura()
  local parent = self:GetParent()
  if parent:PassivesDisabled() then
    return false
  end
  return true
end

function modifier_alpha_critical_strike_aura_oaa_applier:GetModifierAura()
  return "modifier_alpha_critical_strike_aura_oaa_effect"
end

function modifier_alpha_critical_strike_aura_oaa_applier:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_alpha_critical_strike_aura_oaa_applier:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_alpha_critical_strike_aura_oaa_applier:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
end

function modifier_alpha_critical_strike_aura_oaa_applier:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_INVULNERABLE, DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD)
end

function modifier_alpha_critical_strike_aura_oaa_applier:GetAuraEntityReject(hEntity)
  local caster = self:GetCaster()
  -- Dont provide the aura effect to hero creeps when caster (owner of this aura) cannot be controlled
  if hEntity ~= caster and hEntity:IsConsideredHero() and not caster:IsControllableByAnyPlayer() then
    return true
  end
  return false
end

--------------------------------------------------------------------------------

modifier_alpha_critical_strike_aura_oaa_effect = class(ModifierBaseClass)

function modifier_alpha_critical_strike_aura_oaa_effect:IsHidden()
  return false
end

function modifier_alpha_critical_strike_aura_oaa_effect:IsDebuff()
  return false
end

function modifier_alpha_critical_strike_aura_oaa_effect:IsPurgable()
  return false
end

function modifier_alpha_critical_strike_aura_oaa_effect:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
  }
  return funcs
end

function modifier_alpha_critical_strike_aura_oaa_effect:GetModifierPreAttack_CriticalStrike(params)
  if IsServer() then
    local ability = self:GetAbility()
    local parent = self:GetParent()
    local target = params.target

     -- Don't crit on allies, towers, or wards
    if UnitFilter(target, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, parent:GetTeamNumber() ) ~= UF_SUCCESS then
      return 0
    end

    if not ability then
      return 0
    end

    local chance = ability:GetSpecialValueFor("crit_chance")/100

    -- Using the modifier's stack to store the amount of prng failures
    local prngMult = self:GetStackCount() + 1

    if RandomFloat( 0.0, 1.0 ) <= ( PrdCFinder:GetCForP(chance) * prngMult )  then
      -- Reset failure count
      self:SetStackCount( 0 )

      return ability:GetSpecialValueFor("crit_multiplier")
    else
      -- Increment failure count
      self:SetStackCount( prngMult )

      return 0
    end
  end
end
