
modifier_legion_duel_buff_oaa = modifier_legion_duel_buff_oaa or class({})

function modifier_legion_duel_buff_oaa:IsHidden()
  return true
end

function modifier_legion_duel_buff_oaa:IsDebuff()
  return false
end

function modifier_legion_duel_buff_oaa:IsPurgable()
  return false
end

function modifier_legion_duel_buff_oaa:OnCreated()
  if IsServer() then
    self:StartIntervalThink(0.1)
  end
end

function modifier_legion_duel_buff_oaa:OnIntervalThink()
  local parent = self:GetParent()
  -- Remove this debuff if parent is not affected by Duel anymore
  if not parent:HasModifier("modifier_legion_commander_duel") then
    self:StartIntervalThink(-1)
    self:Destroy()
    return
  end
end

function modifier_legion_duel_buff_oaa:CheckState()
  return {
    [MODIFIER_STATE_DEBUFF_IMMUNE] = true,
  }
end

function modifier_legion_duel_buff_oaa:GetEffectName()
  return "particles/items_fx/black_king_bar_avatar.vpcf"
end

---------------------------------------------------------------------------------------------------

modifier_legion_duel_debuff_oaa = modifier_legion_duel_debuff_oaa or class({})

function modifier_legion_duel_debuff_oaa:IsHidden()
  return true
end

function modifier_legion_duel_debuff_oaa:IsDebuff()
  return false
end

function modifier_legion_duel_debuff_oaa:IsPurgable()
  return false
end

function modifier_legion_duel_debuff_oaa:OnCreated()
  if IsServer() then
    self:StartIntervalThink(0.1)
  end
end

function modifier_legion_duel_debuff_oaa:OnIntervalThink()
  local parent = self:GetParent()
  -- Remove this debuff if parent is not affected by Duel anymore
  if not parent:HasModifier("modifier_legion_commander_duel") then
    self:StartIntervalThink(-1)
    self:Destroy()
    return
  end

  parent:Purge(true, false, false, false, false)
end

function modifier_legion_duel_debuff_oaa:GetEffectName()
  return "particles/items_fx/black_king_bar_overhead.vpcf"
end

function modifier_legion_duel_debuff_oaa:GetEffectAttachType()
  return PATTACH_OVERHEAD_FOLLOW
end
