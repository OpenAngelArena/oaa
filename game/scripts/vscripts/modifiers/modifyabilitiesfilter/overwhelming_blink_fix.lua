---------------------------------------------------------------------------------------------------

modifier_item_overwhelming_blink_debuff_oaa = modifier_item_overwhelming_blink_debuff_oaa or class({})

function modifier_item_overwhelming_blink_debuff_oaa:IsHidden()
  return true
end

function modifier_item_overwhelming_blink_debuff_oaa:IsDebuff()
  return true
end

function modifier_item_overwhelming_blink_debuff_oaa:IsPurgable()
  return true
end

function modifier_item_overwhelming_blink_debuff_oaa:OnCreated()
  if not IsServer() then
    return
  end
  local dmg_per_strength = 1
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    dmg_per_strength = ability:GetSpecialValueFor("damage_pct_over_time") / 100
  end
  local caster = self:GetCaster()
  if not caster or caster:IsNull() then
    return
  end
  if caster.GetStrength == nil then
    return
  end
  local str = caster:GetStrength()
  local total_dmg = str * dmg_per_strength
  if self:GetRemainingTime() > 0 then
    self.dps = total_dmg / self:GetRemainingTime()
  end
  self:StartIntervalThink(1)
end

function modifier_item_overwhelming_blink_debuff_oaa:OnIntervalThink()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  local caster = self:GetCaster()
  local ability = self:GetAbility()

  -- ApplyDamage crashes the game if attacker or victim do not exist
  if not parent or parent:IsNull() or not caster or caster:IsNull() or not self.dps then
    self:StartIntervalThink(-1)
    self:Destroy()
    return
  end

  local damageTable = {
    victim = parent,
    attacker = caster,
    damage = self.dps,
    damage_type = DAMAGE_TYPE_MAGICAL,
    ability = ability
  }

  ApplyDamage(damageTable)
end
