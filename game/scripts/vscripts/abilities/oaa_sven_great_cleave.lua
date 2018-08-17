sven_great_cleave_oaa = class( AbilityBaseClass )

LinkLuaModifier("modifier_sven_great_cleave_oaa_passive", "abilities/oaa_sven_great_cleave.lua", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

function sven_great_cleave_oaa:GetIntrinsicModifierName()
  return "modifier_sven_great_cleave_oaa_passive"
end

--------------------------------------------------------------------------------

function sven_great_cleave_oaa:IsHiddenWhenStolen( arg )
  return true
end

--------------------------------------------------------------------------------

modifier_sven_great_cleave_oaa_passive = class( ModifierBaseClass )

--------------------------------------------------------------------------------

function modifier_sven_great_cleave_oaa_passive:IsHidden()
  return true
end

function modifier_sven_great_cleave_oaa_passive:IsPurgable()
  return false
end

function modifier_sven_great_cleave_oaa_passive:IsDebuff()
  return false
end

function modifier_sven_great_cleave_oaa_passive:GetAttributes()
  return MODIFIER_ATTRIBUTE_PERMANENT
end

--------------------------------------------------------------------------------

function modifier_sven_great_cleave_oaa_passive:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

if IsServer() then
  function modifier_sven_great_cleave_oaa_passive:OnAttackLanded( event )
    if self:GetParent() ~= event.attacker then
      return
    end
    local ability = self:GetAbility()
    local cleaveInfo = {
      startRadius = ability:GetSpecialValueFor("cleave_starting_width"),
      endRadius = ability:GetSpecialValueFor("cleave_ending_width"),
      length = ability:GetSpecialValueFor("cleave_distance")
    }
    ability:PerformCleaveOnAttack(
      event,
      cleaveInfo,
      ability:GetSpecialValueFor("great_cleave_damage") / 100.0,
      "Hero_Sven.GreatCleave",
      nil,
      "particles/units/heroes/hero_sven/sven_spell_great_cleave.vpcf"
    )
  end
end
