LinkLuaModifier("modifier_item_enrage_crystal", "items/reflex/postactive_hard_dispell.lua", LUA_MODIFIER_MOTION_NONE)

item_enrage_crystal_1 = class(ItemBaseClass)
item_enrage_crystal_2 = item_enrage_crystal_1
item_enrage_crystal_3 = item_enrage_crystal_1

function item_enrage_crystal_1:GetIntrinsicModifierName()
  return "modifier_item_enrage_crystal"
end

function item_enrage_crystal_1:OnSpellStart()
  local caster = self:GetCaster()

  caster:Purge(false, true, false, true, true)
  caster:EmitSound("Hero_Abaddon.AphoticShield.Destroy")

  local nIndex = ParticleManager:CreateParticle("particles/items/enrage_crystal/enrage_crystal_explosion.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
  ParticleManager:ReleaseParticleIndex( nIndex )
end

function item_enrage_crystal_1:ProcsMagicStick()
  return false
end

---------------------------------------------------------------------------------------------------

modifier_item_enrage_crystal = class(ModifierBaseClass)

function modifier_item_enrage_crystal:IsHidden()
  return true
end

function modifier_item_enrage_crystal:IsDebuff()
  return false
end

function modifier_item_enrage_crystal:IsPurgable()
  return false
end

function modifier_item_enrage_crystal:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_enrage_crystal:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_str = ability:GetSpecialValueFor("bonus_strength")
    self.bonus_damage = ability:GetSpecialValueFor("bonus_damage")
    self.bonus_status_resist = ability:GetSpecialValueFor("bonus_status_resist")
  end
end

modifier_item_enrage_crystal.OnRefresh = modifier_item_enrage_crystal.OnCreated

function modifier_item_enrage_crystal:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
  }
  return funcs
end

function modifier_item_enrage_crystal:GetModifierBonusStats_Strength()
  return self.bonus_str or self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_enrage_crystal:GetModifierPreAttack_BonusDamage()
  return self.bonus_damage or self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_enrage_crystal:GetModifierStatusResistanceStacking()
  return self.bonus_status_resist or self:GetAbility():GetSpecialValueFor("bonus_status_resist")
end
