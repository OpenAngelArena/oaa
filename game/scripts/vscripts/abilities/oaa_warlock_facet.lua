LinkLuaModifier("modifier_warlock_facet_oaa", "abilities/oaa_warlock_facet.lua", LUA_MODIFIER_MOTION_NONE)

-- Multitasking

warlock_facet_oaa = class(AbilityBaseClass)

--[[
function warlock_facet_oaa:Spawn()
  if IsServer() then
    local caster = self:GetCaster()
    if not caster:HasModifier("modifier_warlock_facet_oaa") then
      caster:AddNewModifier(caster, self, "modifier_warlock_facet_oaa", {})
    end
  end
end
]]

function warlock_facet_oaa:GetIntrinsicModifierName()
  return "modifier_warlock_facet_oaa" --"modifier_pugna_oblivion_savant"
end

---------------------------------------------------------------------------------------------------

modifier_warlock_facet_oaa = class(ModifierBaseClass)

function modifier_warlock_facet_oaa:IsHidden()
  return true
end

function modifier_warlock_facet_oaa:IsDebuff()
  return false
end

function modifier_warlock_facet_oaa:IsPurgable()
  return false
end

function modifier_warlock_facet_oaa:RemoveOnDeath()
  return false
end

function modifier_warlock_facet_oaa:OnCreated()
  self.dmg_reduction = 10
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.dmg_reduction = ability:GetSpecialValueFor("dmg_reduction")
  end
end

function modifier_warlock_facet_oaa:DeclareFunctions()
  return {
    --MODIFIER_PROPERTY_IGNORE_CAST_ANGLE,
    MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
  }
end

if IsServer() then
  function modifier_warlock_facet_oaa:GetModifierIgnoreCastAngle()
    local parent = self:GetParent()
    local current_ability = parent:GetCurrentActiveAbility()
    if (current_ability and current_ability:IsChanneling()) or parent:IsChanneling() then
      return 1
    end
  end

  function modifier_warlock_facet_oaa:GetModifierTotal_ConstantBlock(event)
    local attacker = event.attacker
    local parent = self:GetParent()

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
    if (current_ability and current_ability:IsChanneling()) or parent:IsChanneling() then
      return event.damage * self.dmg_reduction / 100
    end

    return 0
  end
end

function modifier_warlock_facet_oaa:CheckState()
  return {
    [MODIFIER_STATE_CASTS_IGNORE_CHANNELING] = true,
  }
end
