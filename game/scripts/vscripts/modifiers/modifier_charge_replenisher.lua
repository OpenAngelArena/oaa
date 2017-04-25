LinkLuaModifier( "modifier_charge_replenishing", "modifiers/modifier_charge_replenisher.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_generic_bonus", "modifiers/modifier_generic_bonus.lua", LUA_MODIFIER_MOTION_NONE)

modifier_charge_replenisher = class({})

function modifier_charge_replenisher:IsHidden()
  return true
end

function modifier_charge_replenisher:IsDebuff()
  return false
end
function modifier_charge_replenisher:IsPurgable()
  return false
end
function modifier_charge_replenisher:OnCreated()
  if IsServer() then
    self.statBonusModifier = self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_generic_bonus", {})
  end
  self:StartIntervalThink(0.1)
end
function modifier_charge_replenisher:OnRefresh()
  self:StartIntervalThink(0.1)
end
function modifier_charge_replenisher:OnDestroy()
  if IsServer() then
    self.statBonusModifier:Destroy()
  end
end
function modifier_charge_replenisher:OnIntervalThink()
  local caster = self:GetCaster()
  local isReplenishing = caster:HasModifier("modifier_charge_replenishing")
  if isReplenishing then
    return
  end

  local ability = self:GetAbility()
  local maxCharges = ability:GetSpecialValueFor( "max_charges" )
  local duration = ability:GetSpecialValueFor( "charge_restore_time" )
  if not ability.GetCurrentCharges then
    -- this happens when it first starts up and i have no clue why
    return
  end
  local charges = ability:GetCurrentCharges()

  local ability = self:GetAbility()
  if charges < maxCharges then
    -- purely visual
    caster:AddNewModifier( caster, ability, "modifier_charge_replenishing", { duration = duration } )
  end
end

modifier_charge_replenishing = class({})

function modifier_charge_replenishing:IsHidden()
  return false
end
function modifier_charge_replenishing:IsDebuff()
  return false
end
function modifier_charge_replenishing:IsPurgable()
  return false
end
function modifier_charge_replenishing:OnCreated(keys)
  self:StartIntervalThink(keys.duration)
end
function modifier_charge_replenishing:OnRefresh(keys)
  self:StartIntervalThink(keys.duration)
end
function modifier_charge_replenishing:OnIntervalThink()
  local ability = self:GetAbility()
  local maxCharges = ability:GetSpecialValueFor( "max_charges" )
  local charges = ability:GetCurrentCharges()
  if charges < maxCharges then
    ability:SetCurrentCharges( ability:GetCurrentCharges() + 1 )
  end
  self:StartIntervalThink(-1)
end
