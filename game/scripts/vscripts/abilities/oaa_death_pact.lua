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
  local duration = self:GetSpecialValueFor( "duration" )

  -- get the target's current health
  local targetHealth = target:GetHealth()

  -- kill the target
  target:Kill( self, caster )

  -- Apply the modifier that just displays duration and visual effects
  caster:AddNewModifier( caster, self, "modifier_clinkz_death_pact_effect_oaa", {duration = duration} )

  -- apply the new modifier which actually provides the stats
  -- then set its stack count to the amount of health the target had
  caster:AddNewModifier( caster, self, "modifier_clinkz_death_pact_oaa", {duration = duration, stacks = targetHealth} )

  -- play the sounds
  caster:EmitSound( "Hero_Clinkz.DeathPact.Cast" )
  target:EmitSound( "Hero_Clinkz.DeathPact" )

  -- show the particle
  local part = ParticleManager:CreateParticle( "particles/units/heroes/hero_clinkz/clinkz_death_pact.vpcf", PATTACH_ABSORIGIN, target )
  ParticleManager:SetParticleControlEnt( part, 1, caster, PATTACH_ABSORIGIN, "", caster:GetAbsOrigin(), true )
  ParticleManager:ReleaseParticleIndex( part )
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

function modifier_clinkz_death_pact_oaa:OnCreated( event )
  local parent = self:GetParent()
  local spell = self:GetAbility()

  -- this has to be done server-side because valve
  if IsServer() then
    -- get the parent's (Clinkz) current health before applying anything
    self.parentHealth = parent:GetHealth()

    -- set the modifier's stack count to the target's health, so that we
    -- have access to it on the client
    self:SetStackCount( event.stacks )
  end

  -- get KV variables
  local healthPct = spell:GetSpecialValueFor( "health_gain_pct" )
  local healthMax = spell:GetSpecialValueFor( "health_gain_max" )
  local damagePct = spell:GetSpecialValueFor( "damage_gain_pct" )
  local damageMax = spell:GetSpecialValueFor( "damage_gain_max" )

  if IsServer() then
    -- Talent that increases hp and dmg gain
    local talent = parent:FindAbilityByName("special_bonus_clinkz_death_pact_oaa")
    if talent then
      if talent:GetLevel() > 0 then
        healthPct = healthPct + talent:GetSpecialValueFor("value")
        damagePct = damagePct + talent:GetSpecialValueFor("value2")
        healthMax = healthMax + talent:GetSpecialValueFor("value3")
        damageMax = damageMax + talent:GetSpecialValueFor("value4")
      end
    end
  end

  -- retrieve the stack count
  local targetHealth = self:GetStackCount()

  -- make sure the resulting buffs don't exceed the caps
  self.health = targetHealth * healthPct * 0.01

  if healthMax > 0 then
    self.health = math.min( healthMax, self.health )
  end

  self.damage = targetHealth * damagePct * 0.01

  if damageMax > 0 then
    self.damage = math.min( damageMax, self.damage )
  end

  if IsServer() then
    -- apply the new health and such
    parent:CalculateStatBonus(true)

    -- add the added health
    parent:SetHealth( self.parentHealth + self.health )
  end
end

function modifier_clinkz_death_pact_oaa:OnRefresh( event )
  local parent = self:GetParent()
  local spell = self:GetAbility()

  -- this has to be done server-side because valve
  if IsServer() then
    -- get the parent's current health before applying anything
    self.parentHealth = parent:GetHealth()

    -- set the modifier's stack count to the target's health, so that we
    -- have access to it on the client
    self:SetStackCount( event.stacks )
  end

  -- get KV variables
  local healthPct = spell:GetSpecialValueFor( "health_gain_pct" )
  local healthMax = spell:GetSpecialValueFor( "health_gain_max" )
  local damagePct = spell:GetSpecialValueFor( "damage_gain_pct" )
  local damageMax = spell:GetSpecialValueFor( "damage_gain_max" )

  if IsServer() then
    -- Talent that increases hp and dmg gain
    local talent = parent:FindAbilityByName("special_bonus_clinkz_death_pact_oaa")
    if talent then
      if talent:GetLevel() > 0 then
        healthPct = healthPct + talent:GetSpecialValueFor("value")
        damagePct = damagePct + talent:GetSpecialValueFor("value2")
        healthMax = healthMax + talent:GetSpecialValueFor("value3")
        damageMax = damageMax + talent:GetSpecialValueFor("value4")
      end
    end
  end

  -- retrieve the stack count
  local targetHealth = self:GetStackCount()

  -- make sure the resulting buffs don't exceed the caps
  self.health = targetHealth * healthPct * 0.01

  if healthMax > 0 then
    self.health = math.min( healthMax, self.health )
  end

  self.damage = targetHealth * damagePct * 0.01

  if damageMax > 0 then
    self.damage = math.min( damageMax, self.damage )
  end

  if IsServer() then
    -- apply the new health and such
    parent:CalculateStatBonus(true)

    -- add the added health
    parent:SetHealth( self.parentHealth + self.health )
  end
end

function modifier_clinkz_death_pact_oaa:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE, -- Vanilla is not base damage!
    MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
  }

  return funcs
end

function modifier_clinkz_death_pact_oaa:GetModifierBaseAttack_BonusDamage( event )
  return self.damage
end

function modifier_clinkz_death_pact_oaa:GetModifierExtraHealthBonus( event )
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

function modifier_clinkz_death_pact_effect_oaa:GetEffectName()
  return "particles/units/heroes/hero_clinkz/clinkz_death_pact_buff.vpcf"
end

function modifier_clinkz_death_pact_effect_oaa:GetEffectAttachType()
  return PATTACH_POINT_FOLLOW
end
