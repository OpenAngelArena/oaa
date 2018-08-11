--TODO "particles/units/heroes/hero_kunkka/kunkka_spell_tidebringer_active.vpcf" -- point glow
--TODO "particles/units/heroes/hero_kunkka/kunkka_weapon_tidebringer.vpcf" -- weapon glow
--TODO Weapon glow when ability off cooldown

--TODO On ability learn, turn the autocast on
--TODO Effect on hit enemies?
--TODO Plays an audio effect (only heard by Kunkka) when going off cooldown.

kunkka_tidebringer_oaa = class( AbilityBaseClass )

LinkLuaModifier("modifier_kunkka_tidebringer_oaa_passive", "abilities/oaa_kunkka_tidebringer.lua", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

function kunkka_tidebringer_oaa:GetCooldown( level )
  local caster = self:GetCaster()

  local talent_cooldown_reduction = caster:FindTalentValue("special_bonus_unique_kunkka_5")
  return self.BaseClass.GetCooldown( self, level ) - talent_cooldown_reduction
end

--------------------------------------------------------------------------------

function kunkka_tidebringer_oaa:GetIntrinsicModifierName()
  return "modifier_kunkka_tidebringer_oaa_passive"
end

--------------------------------------------------------------------------------

modifier_kunkka_tidebringer_oaa_passive = class( ModifierBaseClass )

--------------------------------------------------------------------------------

function modifier_kunkka_tidebringer_oaa_passive:IsHidden()
  return false --true
end

function modifier_kunkka_tidebringer_oaa_passive:IsPurgable()
  return false
end

function modifier_kunkka_tidebringer_oaa_passive:IsDebuff()
  return false
end

function modifier_kunkka_tidebringer_oaa_passive:GetAttributes()
  return MODIFIER_ATTRIBUTE_PERMANENT
end

--------------------------------------------------------------------------------

function modifier_kunkka_tidebringer_oaa_passive:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE
  }
end

if IsServer() then
  function modifier_kunkka_tidebringer_oaa_passive:GetModifierPreAttack_BonusDamage( event )
  	if self:GetParent() ~= event.attacker then
		return
	end
    if self:GetAbility():IsCooldownReady() then --TODO an is toggled on
      return self:GetAbility():GetSpecialValueFor("damage_bonus")
    end
    return 0
  end

  function modifier_kunkka_tidebringer_oaa_passive:OnAttackLanded( event )
  	if self:GetParent() ~= event.attacker then
		return
	end
    if not self:GetAbility():IsCooldownReady() then --TODO an is toggled on
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
      ability:GetSpecialValueFor("cleave_damage") / 100.0,
      cleaveInfo,
      "Kunkka.Tidebringer",
	  "particles/econ/items/kunkka/kunkka_tidebringer_base/kunkka_spell_tidebringer.vpcf",
      "particles/units/heroes/hero_kunkka/kunkka_spell_tidebringer.vpcf"
    )

    -- Force cooldown
    -- Including cooldown reduction which is why we do not use StartCooldown()
    self:GetAbility():UseResources(true, true, true)
  end
end
