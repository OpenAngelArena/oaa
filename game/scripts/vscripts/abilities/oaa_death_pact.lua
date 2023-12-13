clinkz_death_pact_oaa = class( AbilityBaseClass )

LinkLuaModifier( "modifier_clinkz_death_pact_oaa", "abilities/oaa_death_pact.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_clinkz_death_pact_effect_oaa", "abilities/oaa_death_pact.lua", LUA_MODIFIER_MOTION_NONE )

---------------------------------------------------------------------------------------------------

function clinkz_death_pact_oaa:CastFilterResultTarget(hTarget)
  if (hTarget:IsCreep() and not hTarget:IsAncient() and not hTarget:IsConsideredHero() and not hTarget:IsCourier()) or hTarget:GetClassname() == "npc_dota_clinkz_skeleton_archer" then
    return UF_SUCCESS
  end

  return UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_CREEP, bit.bor(DOTA_UNIT_TARGET_FLAG_NOT_ANCIENTS, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO), self:GetCaster():GetTeamNumber())
end

function clinkz_death_pact_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()
  local duration = self:GetSpecialValueFor("duration")

  -- get the target's max health
  local targetHealth = target:GetMaxHealth()

  -- kill the target
  target:Kill(self, caster)

  -- Apply the modifier that just displays duration and visual effects
  caster:AddNewModifier(caster, self, "modifier_clinkz_death_pact_effect_oaa", {duration = duration})

  -- get KV variables
  local healthPct = self:GetSpecialValueFor("health_gain_pct")
  local healthMax = self:GetSpecialValueFor("health_gain_max")
  local damagePct = self:GetSpecialValueFor("damage_gain_pct")
  local damageMax = self:GetSpecialValueFor("damage_gain_max")

  -- Talent that increases hp and dmg gain
  local talent2 = caster:FindAbilityByName("special_bonus_clinkz_death_pact_oaa")
  if talent2 and talent2:GetLevel() > 0 then
    healthPct = healthPct + talent2:GetSpecialValueFor("value")
    damagePct = damagePct + talent2:GetSpecialValueFor("value2")
    healthMax = healthMax + talent2:GetSpecialValueFor("value3")
    damageMax = damageMax + talent2:GetSpecialValueFor("value4")
  end

  -- Calculate bonuses
  local health = targetHealth * healthPct * 0.01
  local damage = targetHealth * damagePct * 0.01

  -- Cap the health bonus
  if healthMax > 0 then
    health = math.min(healthMax, health)
  end

  -- Cap the damage bonus
  if damageMax > 0 then
    damage = math.min(damageMax, damage)
  end

  -- apply the new modifier which actually provides the stats
  -- then set its stack count to the amount of health the target had
  local modifier = caster:AddNewModifier(caster, self, "modifier_clinkz_death_pact_oaa", {duration = duration, health = health})
  modifier:SetStackCount(damage)

  -- play the sounds
  caster:EmitSound("Hero_Clinkz.DeathPact.Cast")
  target:EmitSound("Hero_Clinkz.DeathPact")

  -- show the particle
  local part = ParticleManager:CreateParticle("particles/units/heroes/hero_clinkz/clinkz_death_pact.vpcf", PATTACH_ABSORIGIN, target)
  ParticleManager:SetParticleControlEnt(part, 1, caster, PATTACH_ABSORIGIN, "", caster:GetAbsOrigin(), true)
  ParticleManager:ReleaseParticleIndex(part)
end

---------------------------------------------------------------------------------------------------

modifier_clinkz_death_pact_oaa = class( ModifierBaseClass )

function modifier_clinkz_death_pact_oaa:IsHidden()
  return true
end

function modifier_clinkz_death_pact_oaa:IsDebuff()
  return false
end

function modifier_clinkz_death_pact_oaa:IsPurgable()
  return false
end

function modifier_clinkz_death_pact_oaa:RemoveOnDeath()
  return false
end

function modifier_clinkz_death_pact_oaa:OnCreated(event)
  local parent = self:GetParent()
  local spell = self:GetAbility()

  if IsServer() then
    self.health = event.health

    -- apply the new health and such
    parent:CalculateStatBonus(true)

    -- add the added health
    parent:Heal(self.health, spell)
  end
end

function modifier_clinkz_death_pact_oaa:OnRefresh(event)
  local parent = self:GetParent()
  local spell = self:GetAbility()

  if IsServer() then
    self.health = event.health

    -- apply the new health and such
    parent:CalculateStatBonus(true)

    -- add the added health
    parent:Heal(self.health, spell)
  end
end

function modifier_clinkz_death_pact_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,       -- this is bonus raw damage (green)
    --MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,     -- this is bonus base damage (white)
    MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
  }
end

--function modifier_clinkz_death_pact_oaa:GetModifierBaseAttack_BonusDamage()
  --return self:GetStackCount()
--end

function modifier_clinkz_death_pact_oaa:GetModifierPreAttack_BonusDamage()
  return self:GetStackCount()
end

function modifier_clinkz_death_pact_oaa:GetModifierExtraHealthBonus()
  return self.health
end

---------------------------------------------------------------------------------------------------

modifier_clinkz_death_pact_effect_oaa = class( ModifierBaseClass )

function modifier_clinkz_death_pact_effect_oaa:IsHidden()
  return false
end

function modifier_clinkz_death_pact_effect_oaa:IsDebuff()
  return false
end

function modifier_clinkz_death_pact_effect_oaa:IsPurgable()
  return false
end

function modifier_clinkz_death_pact_effect_oaa:RemoveOnDeath()
  return false
end

function modifier_clinkz_death_pact_effect_oaa:GetEffectName()
  return "particles/units/heroes/hero_clinkz/clinkz_death_pact_buff.vpcf"
end

function modifier_clinkz_death_pact_effect_oaa:GetEffectAttachType()
  return PATTACH_POINT_FOLLOW
end
