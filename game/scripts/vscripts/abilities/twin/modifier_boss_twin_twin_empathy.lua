--LinkLuaModifier("modifier_boss_twin_twin_empathy_buff", "abilities/twin/boss_twin_twin_empathy.lua", LUA_MODIFIER_MOTION_NONE)

modifier_boss_twin_twin_empathy_buff = class(AbilityBaseClass)

--This may need to be in the abil not the mod
function modifier_boss_twin_twin_empathy_buff:OnCreated()
  local interval = 2
  self:StartIntervalThink(interval)
  return true
end

function modifier_boss_twin_twin_empathy_buff:IsHidden()
  return false
end

function modifier_boss_twin_twin_empathy_buff:IsPurgable()
  return false
end

function modifier_boss_twin_twin_empathy_buff:OnIntervalThink()
  if not IsServer() then
    return
  end

  local master = self:GetCaster()
  local twin = self:GetParent()

	if twin:IsAlive() and master:IsAlive() then
	  if twin:GetHealth() < master:GetHealth() then
      twin:SetHealth(master:GetHealth())
    elseif twin:GetHealth() > master:GetHealth() then
      master:SetHealth(twin:GetHealth())
    end
  end

  self:StartIntervalThink(self:GetAbility():GetSpecialValueFor( "heal_timer" ))
end
