---------------------------------------------------------------------------------------------------

modifier_wisp_relocate_shield_oaa = modifier_wisp_relocate_shield_oaa or class({})

function modifier_wisp_relocate_shield_oaa:IsHidden()
  return false
end

function modifier_wisp_relocate_shield_oaa:IsDebuff()
  return false
end

function modifier_wisp_relocate_shield_oaa:IsPurgable()
  return true
end

function modifier_wisp_relocate_shield_oaa:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.max_shield_hp = ability:GetSpecialValueFor("shield_hp")
    self.duration = ability:GetSpecialValueFor("return_time")
  end

  if IsServer() then
    self:SetStackCount(0 - self.max_shield_hp)
    self:SetDuration(self.duration, true)
  end
end

modifier_wisp_relocate_shield_oaa.OnRefresh = modifier_wisp_relocate_shield_oaa.OnCreated

function modifier_wisp_relocate_shield_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT,
  }
end

function modifier_wisp_relocate_shield_oaa:GetModifierIncomingDamageConstant(event)
  if IsClient() then
    if event.report_max then
      return self.max_shield_hp
    else
      return math.abs(self:GetStackCount()) -- current shield hp
    end
  else
    local parent = self:GetParent()
    local damage = event.damage
    local barrier_hp = math.abs(self:GetStackCount())

    -- Don't react to damage with HP removal flag
    if bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then
      return 0
    end

    -- Don't react on self damage
    if event.attacker == parent then
      return 0
    end

    -- Don't block more than remaining hp
    local block_amount = math.min(damage, barrier_hp)

    -- Reduce barrier hp (using negative stacks to not show them on the buff)
    self:SetStackCount(block_amount - barrier_hp)

    if block_amount > 0 then
      -- Visual effect
      SendOverheadEventMessage(nil, OVERHEAD_ALERT_BLOCK, parent, block_amount, nil)
    end

    -- Remove the barrier if hp is reduced to nothing
    if self:GetStackCount() >= 0 then
      self:Destroy()
    end

    return -block_amount
  end
end

