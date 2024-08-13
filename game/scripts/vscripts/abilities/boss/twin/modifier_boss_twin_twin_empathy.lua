
modifier_boss_twin_twin_empathy_buff = class(AbilityBaseClass)

function modifier_boss_twin_twin_empathy_buff:IsHidden()
  return false
end

function modifier_boss_twin_twin_empathy_buff:IsDebuff()
  return false
end

function modifier_boss_twin_twin_empathy_buff:IsPurgable()
  return false
end

function modifier_boss_twin_twin_empathy_buff:OnCreated()
  if not IsServer() then
    return
  end
  local ability = self:GetAbility()
  local interval = 2
  if ability and not ability:IsNull() then
    interval = ability:GetSpecialValueFor("heal_timer")
  end
  self:StartIntervalThink(interval)
  self.interval = interval
end

function modifier_boss_twin_twin_empathy_buff:OnIntervalThink()
  if not IsServer() then
    return
  end

  local master = self:GetCaster()
  local twin = self:GetParent()

  if twin and master and not twin:IsNull() and not master:IsNull() then
    if twin:IsAlive() and master:IsAlive() then
      if twin:GetHealth() < master:GetHealth() then
        twin:SetHealth(master:GetHealth())
      elseif twin:GetHealth() > master:GetHealth() then
        master:SetHealth(twin:GetHealth())
      end
    end
  end

  local ability = self:GetAbility()
  if not ability or ability:IsNull() then
    return
  end

  if self.interval ~= ability:GetSpecialValueFor("heal_timer") then
    self:StartIntervalThink(ability:GetSpecialValueFor("heal_timer"))
  end
end
