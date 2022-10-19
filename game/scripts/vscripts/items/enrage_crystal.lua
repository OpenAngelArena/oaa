LinkLuaModifier("modifier_item_enrage_crystal_passive", "items/enrage_crystal.lua", LUA_MODIFIER_MOTION_NONE)

item_enrage_crystal_1 = class(ItemBaseClass)

function item_enrage_crystal_1:GetIntrinsicModifierName()
  return "modifier_item_enrage_crystal_passive"
end

function item_enrage_crystal_1:OnSpellStart()
  local caster = self:GetCaster()

  -- Strong Dispel
  caster:Purge(false, true, false, true, true)

  -- Sound
  caster:EmitSound("Hero_Abaddon.AphoticShield.Destroy")

  -- Particle
  local nIndex = ParticleManager:CreateParticle("particles/items/enrage_crystal/enrage_crystal_explosion.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
  ParticleManager:ReleaseParticleIndex(nIndex)
end

item_enrage_crystal_2 = item_enrage_crystal_1
item_enrage_crystal_3 = item_enrage_crystal_1

---------------------------------------------------------------------------------------------------

modifier_item_enrage_crystal_passive = class(ModifierBaseClass)

function modifier_item_enrage_crystal_passive:IsHidden()
  return true
end

function modifier_item_enrage_crystal_passive:IsDebuff()
  return false
end

function modifier_item_enrage_crystal_passive:IsPurgable()
  return false
end

function modifier_item_enrage_crystal_passive:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_enrage_crystal_passive:OnCreated()
  self:OnRefresh()
  if IsServer() then
    self:StartIntervalThink(0.1)
  end
end

function modifier_item_enrage_crystal_passive:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_str = ability:GetSpecialValueFor("bonus_strength")
    self.bonus_damage = ability:GetSpecialValueFor("bonus_damage")
    self.bonus_status_resist = ability:GetSpecialValueFor("bonus_status_resist")
  end

  if IsServer() then
    self:OnIntervalThink()
  end
end

function modifier_item_enrage_crystal_passive:OnIntervalThink()
  if self:IsFirstItemInInventory() then
    self:SetStackCount(2)
  else
    self:SetStackCount(1)
  end
end

function modifier_item_enrage_crystal_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
  }
end

function modifier_item_enrage_crystal_passive:GetModifierBonusStats_Strength()
  return self.bonus_str or self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_enrage_crystal_passive:GetModifierPreAttack_BonusDamage()
  return self.bonus_damage or self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_enrage_crystal_passive:GetModifierStatusResistanceStacking()
  if self:GetStackCount() == 2 then
    return self.bonus_status_resist or self:GetAbility():GetSpecialValueFor("bonus_status_resist")
  else
    return 0
  end
end
