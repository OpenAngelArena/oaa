
modifier_boss_charger_trampling = class(ModifierBaseClass)

function modifier_boss_charger_trampling:IsHidden()
  return true
end

function modifier_boss_charger_trampling:IsDebuff()
  return true
end

function modifier_boss_charger_trampling:IsStunDebuff()
  return true
end

function modifier_boss_charger_trampling:IsPurgable()
  return true
end

function modifier_boss_charger_trampling:OnCreated (keys)
  self:StartIntervalThink(0.01)
end

function modifier_boss_charger_trampling:OnIntervalThink() -- this modifier just moves (drags) the hero (parent) together with the Charger
  local charger = self:GetCaster()
  local hero = self:GetParent()

  if not hero or hero:IsNull() or hero.SetAbsOrigin == nil or not charger or charger:IsNull() then
    self:StartIntervalThink(-1)
    self:Destroy()
    return
  end

  if not charger:HasModifier('modifier_boss_charger_charge') then
    self:StartIntervalThink(-1)
    self:Destroy()
    FindClearSpaceForUnit(hero, hero:GetAbsOrigin(), false)
    return
  end

  hero:SetAbsOrigin(charger:GetAbsOrigin())
end
