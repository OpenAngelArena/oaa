LinkLuaModifier("modifier_intrinsic_multiplexer", "modifiers/modifier_intrinsic_multiplexer.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_oaa_dagon_stacking_stats", "items/dagon.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_oaa_dagon_non_stacking_stats", "items/dagon.lua", LUA_MODIFIER_MOTION_NONE)

item_dagon_oaa = class(ItemBaseClass)
item_dagon_oaa_2 = item_dagon_oaa
item_dagon_oaa_3 = item_dagon_oaa
item_dagon_oaa_4 = item_dagon_oaa
item_dagon_oaa_5 = item_dagon_oaa
item_dagon_oaa_6 = item_dagon_oaa
item_dagon_oaa_7 = item_dagon_oaa
item_dagon_oaa_8 = item_dagon_oaa
item_dagon_oaa_9 = item_dagon_oaa

function item_dagon_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()
  local level = self:GetLevel()

  local soundCaster = "DOTA_Item.Dagon.Activate"
  local soundTarget = "DOTA_Item.Dagon5.Target"

  local particleName = "particles/items/dagon_oaa.vpcf"
  local particleThickness = 300 + (100 * level) --Control Point 2 in Dagon's particle effect takes a number between 400 and 2000, depending on its level.

  local damage = self:GetSpecialValueFor("damage") -- Damage should never be a big value because of the spells like Fatal Bonds that share dmg
  local damage_type = DAMAGE_TYPE_MAGICAL

  local particle = ParticleManager:CreateParticle(particleName,  PATTACH_POINT_FOLLOW, caster)
  ParticleManager:SetParticleControlEnt(particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetOrigin(), true)
  ParticleManager:SetParticleControlEnt(particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetOrigin(), true)
  ParticleManager:SetParticleControl(particle, 2, Vector(particleThickness))
  ParticleManager:ReleaseParticleIndex(particle)

  -- Sound on caster
  caster:EmitSound(soundCaster)

  -- Sound on target
  target:EmitSound(soundTarget)

  -- Don't do anything if target has Linken's effect or it's spell-immune
  if target:TriggerSpellAbsorb(self) or target:IsMagicImmune() then
    return
  end

  -- If the target is an illusion, just kill it and don't do damage
  if target:IsIllusion() and not target:IsNull() and not target:IsStrongIllusionOAA() then
    target:Kill(self, caster)
    return
  end

  ApplyDamage({
    victim = target,
    attacker = caster,
    damage = damage,
    damage_type = damage_type,
    ability = self
  })
end

function item_dagon_oaa:GetIntrinsicModifierName()
  return "modifier_intrinsic_multiplexer"
end

function item_dagon_oaa:GetIntrinsicModifierNames()
  return {
    "modifier_item_oaa_dagon_stacking_stats",
    "modifier_item_oaa_dagon_non_stacking_stats"
  }
end

---------------------------------------------------------------------------------------------------
-- Parts of Dagon that should stack with other Dagons (stats)

modifier_item_oaa_dagon_stacking_stats = class(ModifierBaseClass)

function modifier_item_oaa_dagon_stacking_stats:IsHidden()
  return true
end
function modifier_item_oaa_dagon_stacking_stats:IsDebuff()
  return false
end
function modifier_item_oaa_dagon_stacking_stats:IsPurgable()
  return false
end

function modifier_item_oaa_dagon_stacking_stats:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_oaa_dagon_stacking_stats:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.int = ability:GetSpecialValueFor("bonus_int")
    self.str = ability:GetSpecialValueFor("bonus_str")
    self.agi = ability:GetSpecialValueFor("bonus_agi")
  end
end

function modifier_item_oaa_dagon_stacking_stats:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.int = ability:GetSpecialValueFor("bonus_int")
    self.str = ability:GetSpecialValueFor("bonus_str")
    self.agi = ability:GetSpecialValueFor("bonus_agi")
  end
end

function modifier_item_oaa_dagon_stacking_stats:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
  }
end

function modifier_item_oaa_dagon_stacking_stats:GetModifierBonusStats_Strength()
  return self.str or self:GetAbility():GetSpecialValueFor("bonus_str")
end

function modifier_item_oaa_dagon_stacking_stats:GetModifierBonusStats_Agility()
  return self.agi or self:GetAbility():GetSpecialValueFor("bonus_agi")
end

function modifier_item_oaa_dagon_stacking_stats:GetModifierBonusStats_Intellect()
  return self.int or self:GetAbility():GetSpecialValueFor("bonus_int")
end

---------------------------------------------------------------------------------------------------
-- Parts of Dagon that should NOT stack with other Dagons

modifier_item_oaa_dagon_non_stacking_stats = class(ModifierBaseClass)

function modifier_item_oaa_dagon_non_stacking_stats:IsHidden()
  return true
end

function modifier_item_oaa_dagon_non_stacking_stats:IsDebuff()
  return false
end

function modifier_item_oaa_dagon_non_stacking_stats:IsPurgable()
  return false
end

function modifier_item_oaa_dagon_non_stacking_stats:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.spell_amp = ability:GetSpecialValueFor("spell_amp")
  end
end

function modifier_item_oaa_dagon_non_stacking_stats:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.spell_amp = ability:GetSpecialValueFor("spell_amp")
  end
end

function modifier_item_oaa_dagon_non_stacking_stats:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
  }
end

function modifier_item_oaa_dagon_non_stacking_stats:GetModifierSpellAmplify_Percentage()
  return self.spell_amp or self:GetAbility():GetSpecialValueFor("spell_amp")
end
