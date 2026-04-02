LinkLuaModifier("modifier_gyrocopter_innate_oaa", "abilities/oaa_gyrocopter_innate.lua", LUA_MODIFIER_MOTION_NONE)

-- Gyro Scope

gyrocopter_innate_oaa = class(AbilityBaseClass)

function gyrocopter_innate_oaa:Spawn()
  if IsServer() then
    local caster = self:GetCaster()
    if not caster:HasModifier("modifier_gyrocopter_innate_oaa") then
      caster:AddNewModifier(caster, self, "modifier_gyrocopter_innate_oaa", {})
    end
    --self:SetLevel(1)
  end
end

function gyrocopter_innate_oaa:GetIntrinsicModifierName()
  return "modifier_magnataur_solid_core"
end

---------------------------------------------------------------------------------------------------

modifier_gyrocopter_innate_oaa = class(ModifierBaseClass)

function modifier_gyrocopter_innate_oaa:IsHidden()
  return true
end

function modifier_gyrocopter_innate_oaa:IsDebuff()
  return false
end

function modifier_gyrocopter_innate_oaa:IsPurgable()
  return false
end

function modifier_gyrocopter_innate_oaa:RemoveOnDeath()
  return false
end

function modifier_gyrocopter_innate_oaa:OnCreated()
  self.chance = 25
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.chance = ability:GetSpecialValueFor("bonus_accuracy")
  end
  self.truestrike = RandomInt(0, 100) <= self.chance
end

function modifier_gyrocopter_innate_oaa:CheckState()
  if self.truestrike then
    return {
      [MODIFIER_STATE_CANNOT_MISS] = true,
    }
  end
  return {}
end

function modifier_gyrocopter_innate_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_RECORD_DESTROY,
  }
end

if IsServer() then
  function modifier_gyrocopter_innate_oaa:OnAttackRecordDestroy(event)
    local parent = self:GetParent()
    local attacker = event.attacker

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if attacker ~= parent then
      return
    end

    -- Roll chance for true strike (accuracy) again
    self.truestrike = RandomInt(0, 100) <= self.chance
  end
end
