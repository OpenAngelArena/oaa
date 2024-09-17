LinkLuaModifier("modifier_item_rune_breaker_oaa_passive", "items/neutral/rune_breaker.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_rune_breaker_oaa_debuff", "items/neutral/rune_breaker.lua", LUA_MODIFIER_MOTION_NONE)

item_rune_breaker_oaa = class(ItemBaseClass)

function item_rune_breaker_oaa:GetIntrinsicModifierName()
  return "modifier_item_rune_breaker_oaa_passive"
end

function item_rune_breaker_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()

  -- Don't do anything if target is spell-immune
  if target:IsMagicImmune() then
    return
  end

  -- Basic Dispel (for enemies)
  local RemovePositiveBuffs = true
  local RemoveDebuffs = false
  local BuffsCreatedThisFrameOnly = false
  local RemoveStuns = false
  local RemoveExceptions = false

  target:Purge(RemovePositiveBuffs, RemoveDebuffs, BuffsCreatedThisFrameOnly, RemoveStuns, RemoveExceptions)

  -- Apply break debuff (duration is not affected by status resistance)
  local debuff_duration = self:GetSpecialValueFor("duration")
  target:AddNewModifier(caster, self, "modifier_item_rune_breaker_oaa_debuff", {duration = debuff_duration})

  -- Particle
  --local particle_name = ""
  --local particle = ParticleManager:CreateParticle(particle_name, PATTACH_ABSORIGIN, target)
  --ParticleManager:SetParticleControl(particle, 1, target:GetAbsOrigin())
  --ParticleManager:ReleaseParticleIndex(particle)

  -- Sound
  --caster:EmitSound("")
end

---------------------------------------------------------------------------------------------------

modifier_item_rune_breaker_oaa_passive = class(ModifierBaseClass)

function modifier_item_rune_breaker_oaa_passive:IsHidden()
  return true
end

function modifier_item_rune_breaker_oaa_passive:IsDebuff()
  return false
end

function modifier_item_rune_breaker_oaa_passive:IsPurgable()
  return false
end

function modifier_item_rune_breaker_oaa_passive:OnCreated()
  self:OnRefresh()
  if IsServer() then
    self:StartIntervalThink(0)
  end
end

function modifier_item_rune_breaker_oaa_passive:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.attack_speed = ability:GetSpecialValueFor("bonus_attack_speed")
    self.armor = ability:GetSpecialValueFor("bonus_armor")
    self.dmg = ability:GetSpecialValueFor("bonus_damage_during_duels")
  end
end

function modifier_item_rune_breaker_oaa_passive:OnIntervalThink()
  if Duels:IsActive() then
    self:SetStackCount(1)
  else
    self:SetStackCount(2)
  end
end

function modifier_item_rune_breaker_oaa_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
  }
end

function modifier_item_rune_breaker_oaa_passive:GetModifierPhysicalArmorBonus()
  return self.armor or self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_item_rune_breaker_oaa_passive:GetModifierAttackSpeedBonus_Constant()
  return self.attack_speed or self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_item_rune_breaker_oaa_passive:GetModifierBaseDamageOutgoing_Percentage()
  if self:GetStackCount() == 1 then
    return self.dmg or self:GetAbility():GetSpecialValueFor("bonus_damage_during_duels")
  end

  return 0
end

---------------------------------------------------------------------------------------------------

modifier_item_rune_breaker_oaa_debuff = class(ModifierBaseClass)

function modifier_item_rune_breaker_oaa_debuff:IsHidden()
  return false
end

function modifier_item_rune_breaker_oaa_debuff:IsDebuff()
  return true
end

function modifier_item_rune_breaker_oaa_debuff:IsPurgable()
  return false
end

function modifier_item_rune_breaker_oaa_debuff:CheckState()
  return {
    [MODIFIER_STATE_PASSIVES_DISABLED] = true,
  }
end

function modifier_item_rune_breaker_oaa_debuff:GetEffectName()
  return "particles/items3_fx/silver_edge.vpcf"
end

function modifier_item_rune_breaker_oaa_debuff:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_item_rune_breaker_oaa_debuff:GetTexture()
  return "item_the_leveller"
end
