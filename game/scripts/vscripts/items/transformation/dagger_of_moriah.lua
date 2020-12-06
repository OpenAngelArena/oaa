---
--- Created by Zarnotox.
--- DateTime: 03-Dec-17 21:32
---
item_dagger_of_moriah = class(TransformationBaseClass)

LinkLuaModifier("modifier_intrinsic_multiplexer", "modifiers/modifier_intrinsic_multiplexer.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_dagger_of_moriah_sangromancy", "items/transformation/dagger_of_moriah.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_dagger_of_moriah_stacking_stats", "items/transformation/dagger_of_moriah.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_dagger_of_moriah_non_stacking_stats", "items/transformation/dagger_of_moriah.lua", LUA_MODIFIER_MOTION_NONE)

---------------------------------------------------------------------------------------------------

function item_dagger_of_moriah:GetIntrinsicModifierName()
  return "modifier_intrinsic_multiplexer"
end

function item_dagger_of_moriah:GetIntrinsicModifierNames()
  return {
    "modifier_item_dagger_of_moriah_stacking_stats",
    "modifier_item_dagger_of_moriah_non_stacking_stats"
  }
end

function item_dagger_of_moriah:GetTransformationModifierName()
  return "modifier_item_dagger_of_moriah_sangromancy"
end

item_dagger_of_moriah_2 = item_dagger_of_moriah

---------------------------------------------------------------------------------------------------

modifier_item_dagger_of_moriah_stacking_stats = class(ModifierBaseClass)

function modifier_item_dagger_of_moriah_stacking_stats:IsHidden()
  return true
end
function modifier_item_dagger_of_moriah_stacking_stats:IsDebuff()
  return false
end
function modifier_item_dagger_of_moriah_stacking_stats:IsPurgable()
  return false
end

function modifier_item_dagger_of_moriah_stacking_stats:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_dagger_of_moriah_stacking_stats:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.stats = ability:GetSpecialValueFor("bonus_all_stats")
    self.hp_regen = ability:GetSpecialValueFor("bonus_health_regen")
    self.mp_regen = ability:GetSpecialValueFor("bonus_mana_regen")
  end
end

function modifier_item_dagger_of_moriah_stacking_stats:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.stats = ability:GetSpecialValueFor("bonus_all_stats")
    self.hp_regen = ability:GetSpecialValueFor("bonus_health_regen")
    self.mp_regen = ability:GetSpecialValueFor("bonus_mana_regen")
  end
end

function modifier_item_dagger_of_moriah_stacking_stats:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
  }
end

function modifier_item_dagger_of_moriah_stacking_stats:GetModifierBonusStats_Strength()
  return self.stats or self:GetAbility():GetSpecialValueFor("bonus_all_stats")
end

function modifier_item_dagger_of_moriah_stacking_stats:GetModifierBonusStats_Agility()
  return self.stats or self:GetAbility():GetSpecialValueFor("bonus_all_stats")
end

function modifier_item_dagger_of_moriah_stacking_stats:GetModifierBonusStats_Intellect()
  return self.stats or self:GetAbility():GetSpecialValueFor("bonus_all_stats")
end

function modifier_item_dagger_of_moriah_stacking_stats:GetModifierConstantHealthRegen()
  return self.hp_regen or self:GetAbility():GetSpecialValueFor("bonus_health_regen")
end

function modifier_item_dagger_of_moriah_stacking_stats:GetModifierConstantManaRegen()
  return self.mp_regen or self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
end

---------------------------------------------------------------------------------------------------
-- Parts of Dagger of Moriah that should NOT stack with other Daggers of Moriah

modifier_item_dagger_of_moriah_non_stacking_stats = class(ModifierBaseClass)

function modifier_item_dagger_of_moriah_non_stacking_stats:IsHidden()
  return true
end

function modifier_item_dagger_of_moriah_non_stacking_stats:IsDebuff()
  return false
end

function modifier_item_dagger_of_moriah_non_stacking_stats:IsPurgable()
  return false
end

function modifier_item_dagger_of_moriah_non_stacking_stats:OnCreated()
  local parent = self:GetParent()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.spell_amp = ability:GetSpecialValueFor("spell_amp_per_intellect")
  end

  if parent:IsRealHero() then
    self.int = parent:GetIntellect()
  end

  if IsServer() and parent:IsRealHero() then
    parent:CalculateStatBonus()
  end

  self:StartIntervalThink(0.5)
end

function modifier_item_dagger_of_moriah_non_stacking_stats:OnRefresh()
  local parent = self:GetParent()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.spell_amp = ability:GetSpecialValueFor("spell_amp_per_intellect")
  end

  if parent:IsRealHero() then
    self.int = parent:GetIntellect()
  end

  if IsServer() and parent:IsRealHero() then
    parent:CalculateStatBonus()
  end
end

function modifier_item_dagger_of_moriah_non_stacking_stats:OnIntervalThink()
  local parent = self:GetParent()

  if parent:IsRealHero() then
    self.int = parent:GetIntellect()
  end

  if IsServer() and parent:IsRealHero() then
    parent:CalculateStatBonus()
  end
end

function modifier_item_dagger_of_moriah_non_stacking_stats:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
  }
end

function modifier_item_dagger_of_moriah_non_stacking_stats:GetModifierSpellAmplify_Percentage()
  local spell_amp_per_int = self.spell_amp or self:GetAbility():GetSpecialValueFor("spell_amp_per_intellect")
  if self.int and spell_amp_per_int then
    return spell_amp_per_int * self.int
  end

  return 0
end

---------------------------------------------------------------------------------------------------

modifier_item_dagger_of_moriah_sangromancy = class(ModifierBaseClass)

function modifier_item_dagger_of_moriah_sangromancy:IsHidden()
  return false
end

function modifier_item_dagger_of_moriah_sangromancy:IsDebuff()
  return false
end

function modifier_item_dagger_of_moriah_sangromancy:IsPurgable()
  return true
end

function modifier_item_dagger_of_moriah_sangromancy:OnCreated( event )
  local spell = self:GetAbility()

  spell.mod = self

  self.spellamp = spell:GetSpecialValueFor( "sangromancy_spell_amp" )
  self.selfDamage = spell:GetSpecialValueFor( "sangromancy_self_damage" )
  self.bonusDamagefromOthers = spell:GetSpecialValueFor( "sangromancy_bonus_damage_from_others" )

  if IsServer() and self.nPreviewFX == nil then
    self.nPreviewFX = ParticleManager:CreateParticle( "particles/items/dagger_of_moriah/dagger_of_moriah_ambient_smoke.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
    ParticleManager:SetParticleControlEnt( self.nPreviewFX, 0, self:GetParent(), PATTACH_ABSORIGIN_FOLLOW, nil, self:GetParent():GetOrigin(), true )
  end
end

function modifier_item_dagger_of_moriah_sangromancy:OnDestroy(  )
  if IsServer() and self.nPreviewFX ~= nil then
    ParticleManager:DestroyParticle( self.nPreviewFX, false )
    ParticleManager:ReleaseParticleIndex(self.nPreviewFX)
    self.nPreviewFX = nil
  end
end

function modifier_item_dagger_of_moriah_sangromancy:OnRefresh( event )
  local spell = self:GetAbility()

  spell.mod = self

  self.spellamp = spell:GetSpecialValueFor( "sangromancy_spell_amp" )
  self.selfDamage = spell:GetSpecialValueFor( "sangromancy_self_damage" )
  self.bonusDamagefromOthers = spell:GetSpecialValueFor( "sangromancy_bonus_damage_from_others" )
end

function modifier_item_dagger_of_moriah_sangromancy:OnRemoved()
  local spell = self:GetAbility()

  if spell and not spell:IsNull() then
    spell.mod = nil
  end
end

function modifier_item_dagger_of_moriah_sangromancy:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    MODIFIER_EVENT_ON_TAKEDAMAGE,
  }

  return funcs
end

function modifier_item_dagger_of_moriah_sangromancy:GetModifierSpellAmplify_Percentage( event )
  local spell = self:GetAbility()

  return self.spellamp or spell:GetSpecialValueFor( "sangromancy_spell_amp" )
end

function modifier_item_dagger_of_moriah_sangromancy:GetModifierIncomingDamage_Percentage( event )
  local spell = self:GetAbility()
  if event.attacker == self:GetParent() then
    return 0
  else
    return self.bonusDamagefromOthers or spell:GetSpecialValueFor( "sangromancy_bonus_damage_from_others" )
  end
end

function modifier_item_dagger_of_moriah_sangromancy:OnTakeDamage(event)
  if event.damage_category == 0 and event.attacker == self:GetParent() and not (event.unit == self:GetParent()) and bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION) == 0 then

    local damage = {
      victim = event.attacker,
      attacker = event.attacker,
      damage = event.original_damage * (self.selfDamage / 100),
      damage_type = event.damage_type,
      damage_flags = bit.bor(event.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_NON_LETHAL),
      ability = self:GetAbility(),
    }

    ApplyDamage( damage )

    if IsServer() then
      local unit = self:GetParent()
      if unit.flashFX == nil and unit:HasModifier( "modifier_item_dagger_of_moriah_sangromancy" ) then
        unit.flashFX = ParticleManager:CreateParticle( "particles/items/dagger_of_moriah/dagger_of_moriah_ambient_smoke_flash.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit )
        ParticleManager:SetParticleControlEnt( unit.flashFX, 0, unit, PATTACH_ABSORIGIN_FOLLOW, nil, unit:GetOrigin(), true )
        Timers:CreateTimer(0.3, function()
          ParticleManager:DestroyParticle(unit.flashFX, false)
          ParticleManager:ReleaseParticleIndex(unit.flashFX)
          unit.flashFX = nil
        end)
      end
    end
  end
end

function modifier_item_dagger_of_moriah_sangromancy:GetTexture()
  return "custom/dagger_of_moriah_2_active"
end
