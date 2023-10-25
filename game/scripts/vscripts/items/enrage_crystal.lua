LinkLuaModifier("modifier_item_enrage_crystal_passive", "items/enrage_crystal.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_enrage_crystal_active", "items/enrage_crystal.lua", LUA_MODIFIER_MOTION_NONE)

item_enrage_crystal_1 = class(ItemBaseClass)

function item_enrage_crystal_1:GetIntrinsicModifierName()
  return "modifier_item_enrage_crystal_passive"
end

function item_enrage_crystal_1:OnSpellStart()
  local caster = self:GetCaster()

  -- Strong Dispel
  caster:Purge(false, true, false, true, false)

  -- Sound
  caster:EmitSound("Hero_Abaddon.AphoticShield.Destroy")

  -- Particle
  local particle = ParticleManager:CreateParticle("particles/items/enrage_crystal/enrage_crystal_explosion.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
  ParticleManager:ReleaseParticleIndex(particle)

  -- Apply brief debuff immunity
  caster:AddNewModifier(caster, self, "modifier_item_enrage_crystal_active", {duration = self:GetSpecialValueFor("active_duration")})
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
    self.bonus_slow_resist = = ability:GetSpecialValueFor("bonus_slow_resist")
    self.dmg_reduction = ability:GetSpecialValueFor("dmg_reduction_while_stunned")
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
    MODIFIER_PROPERTY_SLOW_RESISTANCE,
    MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
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

function modifier_item_enrage_crystal_passive:GetModifierSlowResistance()
  if self:GetStackCount() == 2 then
    return self.bonus_slow_resist or self:GetAbility():GetSpecialValueFor("bonus_slow_resist")
  else
    return 0
  end
end

if IsServer() then
  function modifier_item_enrage_crystal_passive:GetModifierTotal_ConstantBlock(event)
    if self:GetStackCount() ~= 2 then
      return 0
    end

    local parent = self:GetParent()
    local damage = event.damage

    local block_amount = damage * self.dmg_reduction / 100

    if block_amount > 0 and (parent:IsStunned() or parent:IsHexed() or parent:IsOutOfGame()) then
      -- Visual effect
      local alert_type = OVERHEAD_ALERT_MAGICAL_BLOCK
      if event.damage_type == DAMAGE_TYPE_PHYSICAL then
        alert_type = OVERHEAD_ALERT_BLOCK
      end

      SendOverheadEventMessage(nil, alert_type, parent, block_amount, nil)

      return block_amount
    end

    return 0
  end
end

---------------------------------------------------------------------------------------------------

modifier_item_enrage_crystal_active = class(ModifierBaseClass)

function modifier_item_enrage_crystal_active:IsHidden()
  return false
end

function modifier_item_enrage_crystal_active:IsDebuff()
  return false
end

function modifier_item_enrage_crystal_active:IsPurgable()
  return false
end

function modifier_item_enrage_crystal_active:CheckState()
  return {
    [MODIFIER_STATE_DEBUFF_IMMUNE] = true,
  }
end

function modifier_item_enrage_crystal_active:GetEffectName()
  return "particles/items_fx/black_king_bar_avatar.vpcf"
end

function modifier_item_enrage_crystal_active:GetTexture()
  return "custom/enrage_crystal_1"
end
