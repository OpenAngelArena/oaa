-- Hidden Health Bar

modifier_no_health_bar_oaa = class(ModifierBaseClass)

function modifier_no_health_bar_oaa:IsHidden()
  return false
end

function modifier_no_health_bar_oaa:IsDebuff()
  return false
end

function modifier_no_health_bar_oaa:IsPurgable()
  return false
end

function modifier_no_health_bar_oaa:RemoveOnDeath()
  local parent = self:GetParent()
  if parent:IsRealHero() and not parent:IsOAABoss() then
    return false
  end
  return true
end

function modifier_no_health_bar_oaa:CheckState()
  return {
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
  }
end

--function modifier_no_health_bar_oaa:GetTexture()
  --return "generic_hidden"
--end
