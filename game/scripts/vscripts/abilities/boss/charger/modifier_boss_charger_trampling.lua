
modifier_boss_charger_trampling = class(ModifierBaseClass)

function modifier_boss_charger_trampling:OnCreated (keys)
  self:StartIntervalThink(0.01)
end

function modifier_boss_charger_trampling:OnIntervalThink()
  local charger = self:GetCaster()
  local hero = self:GetParent()

  if not hero or not hero.SetAbsOrigin then
    return
  end

  if not charger:HasModifier('modifier_boss_charger_charge') and not charger:HasModifier('modifier_boss_charger_charge_tier5') then
    self:StartIntervalThink(-1)
    self:Destroy()
    FindClearSpaceForUnit(hero, hero:GetAbsOrigin(), false)
    return
  end

  hero:SetAbsOrigin(charger:GetAbsOrigin())
end
