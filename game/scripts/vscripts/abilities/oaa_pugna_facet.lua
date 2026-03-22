--LinkLuaModifier("modifier_pugna_facet_oaa", "abilities/oaa_pugna_facet.lua", LUA_MODIFIER_MOTION_NONE)

-- Undead Nature

pugna_facet_oaa = class(AbilityBaseClass)

function pugna_facet_oaa:GetIntrinsicModifierName()
  return "modifier_muerta_supernatural"
end

---------------------------------------------------------------------------------------------------

modifier_pugna_facet_oaa = class(ModifierBaseClass)

function modifier_pugna_facet_oaa:IsHidden()
  return true
end

function modifier_pugna_facet_oaa:IsDebuff()
  return false
end

function modifier_pugna_facet_oaa:IsPurgable()
  return false
end

function modifier_pugna_facet_oaa:RemoveOnDeath()
  return false
end

function modifier_pugna_facet_oaa:DeclareFunctions()
  return {
    --MODIFIER_PROPERTY_ALWAYS_ETHEREAL_ATTACK, -- does not work
  }
end

--[[ -- does not work
if IsServer() then
  function modifier_pugna_facet_oaa:GetAllowEtherealAttack()
    local parent = self:GetParent()
    if not parent:PassivesDisabled() then
      return 1
    end
  end
end
]]


