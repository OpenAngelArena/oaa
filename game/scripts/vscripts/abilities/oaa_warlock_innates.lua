LinkLuaModifier("modifier_warlock_innates_oaa", "abilities/oaa_warlock_innates.lua", LUA_MODIFIER_MOTION_NONE)

-- Multitasking

warlock_innates_oaa = class(AbilityBaseClass)

function warlock_innates_oaa:Spawn()
  if IsServer() then
    local caster = self:GetCaster()
    if not caster:HasModifier("modifier_warlock_innates_oaa") then
      caster:AddNewModifier(caster, self, "modifier_warlock_innates_oaa", {})
    end
  end
end

--function warlock_innates_oaa:GetIntrinsicModifierName()
  --return "modifier_warlock_innates_oaa" --"modifier_pugna_oblivion_savant"
--end

---------------------------------------------------------------------------------------------------

modifier_warlock_innates_oaa = class(ModifierBaseClass)

function modifier_warlock_innates_oaa:IsHidden()
  return true
end

function modifier_warlock_innates_oaa:IsDebuff()
  return false
end

function modifier_warlock_innates_oaa:IsPurgable()
  return false
end

function modifier_warlock_innates_oaa:RemoveOnDeath()
  return false
end

--[[
function modifier_warlock_innates_oaa:OnCreated()
  self.dmg_reduction = 10
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.dmg_reduction = ability:GetSpecialValueFor("dmg_reduction")
  end
end

function modifier_warlock_innates_oaa:DeclareFunctions()
  return {
    --MODIFIER_PROPERTY_IGNORE_CAST_ANGLE,
    MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
  }
end

if IsServer() then
  function modifier_warlock_innates_oaa:GetModifierIgnoreCastAngle()
    local parent = self:GetParent()
    --if parent:PassivesDisabled() then
      --return 0
    --end
    local current_ability = parent:GetCurrentActiveAbility()
    if ((current_ability and current_ability:IsChanneling() and current_ability:GetAbilityName() == "warlock_upheaval") or parent:IsChanneling()) and not parent:PassivesDisabled() then
      return 1
    end
  end

  function modifier_warlock_innates_oaa:GetModifierTotal_ConstantBlock(event)
    local attacker = event.attacker
    local parent = self:GetParent()

    --if parent:PassivesDisabled() then
      --return 0
    --end

    if not attacker or attacker:IsNull() then
      return 0
    end

    if attacker.IsBaseNPC == nil then
      return 0
    end

    if not attacker:IsBaseNPC() then
      return 0
    end

    local current_ability = parent:GetCurrentActiveAbility()
    if (current_ability and current_ability:IsChanneling() and current_ability:GetAbilityName() == "warlock_upheaval") or parent:IsChanneling() then
      return event.damage * self.dmg_reduction / 100
    end

    return 0
  end
end
]]

function modifier_warlock_innates_oaa:CheckState()
  local parent = self:GetParent()
  --if parent:PassivesDisabled() then
    --return {}
  --end
  local current_ability = parent:GetCurrentActiveAbility()
  if current_ability and current_ability:IsChanneling() and current_ability:GetAbilityName() == "warlock_upheaval" and parent:IsChanneling() then
    return {
      [MODIFIER_STATE_CASTS_IGNORE_CHANNELING] = true,
    }
  end
  return {}
end
