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

--------------------------------------------------------------------------------

if IsServer() then
	function modifier_sven_great_cleave_oaa_passive:OnAttackLanded( event )
		if event.attacker ~= self:GetParent() then
      return
    end

		local parent = self:GetParent()
		local target = event.target
		local ability = self:GetAbility()

    -- Do not proc when passives are disabled
    if parent:PassivesDisabled() then
      return
    end

    -- Does not cleave upon attacking wards, buildings or allied units.
    if target:GetTeamNumber() == parent:GetTeamNumber() or
        target == nil or target:IsTower() or
        target:IsBarracks() or
        target:IsBuilding() or
        target:IsOther()
      then
      return
    end

		-- Play the impact sound
    target:EmitSound( "Sven.GreatCleave" )

    local particleName = "particles/units/heroes/hero_sven/sven_spell_great_cleave.vpcf"

    local startEntity = parent
    if (self.fromTarget ~= nil and self.fromTarget == true) or parent:IsRangedAttacker() then
      startEntity = target
    end
    local startPos = startEntity:GetAbsOrigin()

	-- Play the impact particle
	local cleave_pfx = ParticleManager:CreateParticle( particleName, PATTACH_ABSORIGIN_FOLLOW, startEntity )
	ParticleManager:SetParticleControl( cleave_pfx, 0, target:GetAbsOrigin() )
	ParticleManager:ReleaseParticleIndex( cleave_pfx )

    -- Not work on illusions (only visuals works)
    if parent:IsIllusion() then
      return
    end

    PerformCleave(
      parent, ability, target,
      parent:GetTeamNumber(),
      startPos,
      (target:GetAbsOrigin() - parent:GetAbsOrigin()):Normalized(), --parent:GetForwardVector(),
      ability:GetSpecialValueFor("cleave_starting_width"),
      ability:GetSpecialValueFor("cleave_ending_width"),
      ability:GetSpecialValueFor("cleave_distance"),
      event.damage * (ability:GetSpecialValueFor("great_cleave_damage") / 100.0))
	end
end
