-- Azazel's Sustainability Elixiers
-- by Firetoad, April 1st, 2018
-- changed and modified by Darkonius many times

--------------------------------------------------------------------------------

LinkLuaModifier("modifier_elixier_sustain_active", "items/elixier_sustain.lua", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

item_elixier_sustain = class(ItemBaseClass)

function item_elixier_sustain:OnSpellStart()
  local caster = self:GetCaster()

  -- Activation sound
  caster:EmitSound("DOTA_Item.FaerieSpark.Activate")

  -- Apply a buff
  local buff = caster:AddNewModifier(caster, self, "modifier_elixier_sustain_active", {duration = self:GetSpecialValueFor("duration")})
  buff.regen = self:GetSpecialValueFor("bonus_hp_regen")
  buff.hero_lifesteal = self:GetSpecialValueFor("bonus_lifesteal")
  buff.hero_spell_lifesteal = self:GetSpecialValueFor("bonus_spell_lifesteal")

  -- Consume the item
  self:SpendCharge()
end

--------------------------------------------------------------------------------

modifier_elixier_sustain_active = class(ModifierBaseClass)

function modifier_elixier_sustain_active:IsHidden()
  return false
end

function modifier_elixier_sustain_active:IsPurgable()
  return false
end

function modifier_elixier_sustain_active:IsDebuff()
  return false
end

function modifier_elixier_sustain_active:RemoveOnDeath()
  return false
end

function modifier_elixier_sustain_active:GetEffectName()
  return "particles/generic_gameplay/rune_regeneration_sparks.vpcf"
end

function modifier_elixier_sustain_active:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_elixier_sustain_active:GetTexture()
  return "custom/elixier_sustain"
end

function modifier_elixier_sustain_active:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.regen = ability:GetSpecialValueFor("bonus_hp_regen")
    self.hero_lifesteal = ability:GetSpecialValueFor("bonus_lifesteal")
    self.hero_spell_lifesteal = ability:GetSpecialValueFor("bonus_spell_lifesteal")
  else
    self.regen = self.regen or 50
    self.hero_lifesteal = self.hero_lifesteal or 55
    self.hero_spell_lifesteal = self.hero_spell_lifesteal or 40
  end

  self.creep_lifesteal = self.hero_lifesteal * 0.6
  self.creep_spell_lifesteal = self.hero_spell_lifesteal / 5
end

function modifier_elixier_sustain_active:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_EVENT_ON_TAKEDAMAGE,
  }
end

function modifier_elixier_sustain_active:GetModifierConstantHealthRegen()
  return self.regen
end

if IsServer() then
  function modifier_elixier_sustain_active:OnTakeDamage(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local damaged_unit = event.unit
    local dmg_flags = event.damage_flags
    local damage = event.damage
    local inflictor = event.inflictor

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if attacker ~= parent then
      return
    end

    -- Check if damaged entity exists
    if not damaged_unit or damaged_unit:IsNull() then
      return
    end

    -- Ignore self damage
    if damaged_unit == attacker then
      return
    end

    -- Check if entity is an item, rune or something weird
    if damaged_unit.GetUnitName == nil then
      return
    end

    -- Buildings, wards and invulnerable units can't lifesteal
    if attacker:IsTower() or attacker:IsBarracks() or attacker:IsBuilding() or attacker:IsOther() or attacker:IsInvulnerable() then
      return
    end

    -- Don't affect buildings, wards and invulnerable units.
    if damaged_unit:IsTower() or damaged_unit:IsBarracks() or damaged_unit:IsBuilding() or damaged_unit:IsOther() or damaged_unit:IsInvulnerable() then
      return
    end

    -- Ignore damage with no-reflect flag
    if bit.band(dmg_flags, DOTA_DAMAGE_FLAG_REFLECTION) > 0 then
      return
    end

    -- Ignore damage with HP removal flag
    if bit.band(dmg_flags, DOTA_DAMAGE_FLAG_HPLOSS) > 0 then
      return
    end

    -- Ignore damage with no-spell-lifesteal flag
    if inflictor and bit.band(dmg_flags, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL) > 0 then
      return
    end

    -- Ignore damage with no-spell-amplification flag
    if bit.band(dmg_flags, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION) > 0 then
      return
    end

    local lifesteal_pct = 0
    if inflictor then
      lifesteal_pct = self.hero_spell_lifesteal
    else
      lifesteal_pct = self.hero_lifesteal
    end

    -- Illusions are treated as creeps too
    if not damaged_unit:IsRealHero() and not damaged_unit:IsStrongIllusionOAA() then
      if inflictor then
        lifesteal_pct = self.creep_spell_lifesteal
      else
        lifesteal_pct = self.creep_lifesteal
      end
    end

    -- Calculate the lifesteal (heal) amount
    local lifesteal_amount = damage * lifesteal_pct / 100

    if lifesteal_amount > 0 then
      --attacker:Heal(lifesteal_amount, nil)
      -- Particle
      if inflictor then
        -- Spell Lifesteal
        attacker:HealWithParams(lifesteal_amount, nil, false, true, attacker, true)

        local particle1 = ParticleManager:CreateParticle("particles/items3_fx/octarine_core_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, attacker)
        ParticleManager:SetParticleControl(particle1, 0, attacker:GetAbsOrigin())
        ParticleManager:ReleaseParticleIndex(particle1)
      else
        -- Normal Lifesteal
        attacker:HealWithParams(lifesteal_amount, nil, true, true, attacker, false)

        local particle2 = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, attacker)
        ParticleManager:ReleaseParticleIndex(particle2)
      end
    end
  end
end
