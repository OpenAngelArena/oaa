modifier_spark_midas = class(ModifierBaseClass)

function modifier_spark_midas:IsHidden()
	return false
end

function modifier_spark_midas:IsDebuff()
	return false
end

function modifier_spark_midas:IsPurgable()
	return false
end

function modifier_spark_midas:RemoveOnDeath()
  return false
end

function modifier_spark_midas:GetTexture()
  return "custom/travel_origin"
end

function modifier_spark_midas:OnCreated( event )

end

function modifier_spark_midas:OnRefresh( event )

end

if IsServer() then
	function modifier_spark_midas:OnIntervalThink()
		local parent = self:GetParent()
		local spell = self:GetAbility()

		-- disable everything here for illusions or during duels / pre 0:00
		if parent:IsIllusion() or not Gold:IsGoldGenActive() then
			return
		end

		local currentCharges = spell:GetCurrentCharges()

		if currentCharges < self.maxCharges then
			-- get the current point of the parent
			local originParent = parent:GetAbsOrigin()

			-- get the distance between that point and their old point
			local dist = ( originParent - self.originOld ):Length2D()

			-- cap the amount of distances so tps don't instafill it
			dist = math.min( dist, self.distMax )

			-- add the distance to the fraction charge
			self.fracCharge = self.fracCharge + dist

			-- determine the amount of charges to give
			local addedCharges = math.floor( self.fracCharge / self.distPer )

			-- give those charges, then subtract their fractional charge from the item
			spell:SetCurrentCharges( math.min( currentCharges + addedCharges, self.maxCharges ) )
			self.fracCharge = self.fracCharge - ( self.distPer * addedCharges )

			-- set the old point of the parent
			self.originOld = originParent
		end
	end
end

--------------------------------------------------------------------------------

function modifier_spark_midas:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}

	return funcs
end

--------------------------------------------------------------------------------

if IsServer() then
  function modifier_spark_midas:OnAttackLanded( event )
    local parent = self:GetParent()
    local attacker = event.attacker
    local attacked_unit = event.target

    if attacker == parent or attacked_unit == parent then
      local spell = self:GetAbility()

      -- Break Tranquils only in the following cases:
      -- 1. If the parent attacked a hero
      -- 2. If the parent was attacked by a hero, boss, hero creep or a player-controlled creep.
	  -- 3. Either of the above, and we don't have an origin.
      if spell:IsBreakable() and ((attacker == parent and attacked_unit:IsHero()) or (attacked_unit == parent and (attacker:IsConsideredHero() or attacker:IsControllableByAnyPlayer()))) then
        spell:UseResources(false, false, true)

        local cdRemaining = spell:GetCooldownTimeRemaining()
        if cdRemaining > 0 then
          self:SetDuration( cdRemaining, true )
        end
      end

      -- Tranquils instant kill should work only on neutrals (not bosses)
	  -- and never in duels
      if attacker == parent and attacked_unit:IsNeutralCreep( true ) and Gold:IsGoldGenActive() then
        local currentCharges = spell:GetCurrentCharges()

        -- If number of charges is equal or above 100 and the parent is not muted or an illusion trigger naturalize eating
				if currentCharges >= 100 and not spell:IsMuted() and not parent:IsIllusion() then
					local player = parent:GetPlayerOwner()

					-- remove 100 charges
					spell:SetCurrentCharges( currentCharges - 100 )

					-- bonus gold
					PlayerResource:ModifyGold( player:GetPlayerID(), self.bonusGold, false, DOTA_ModifyGold_CreepKill )
					SendOverheadEventMessage( player, OVERHEAD_ALERT_GOLD, parent, self.bonusGold, player )

					-- bonus exp
					if self.bonusXP > 0 then
						parent:AddExperience( self.bonusXP, DOTA_ModifyXP_CreepKill, false, true )
					end

					-- particle
					local part = ParticleManager:CreateParticle( "particles/units/heroes/hero_treant/treant_leech_seed_damage_glow.vpcf", PATTACH_POINT_FOLLOW, event.target )
					ParticleManager:ReleaseParticleIndex( part )

					-- sound
					parent:EmitSound( "Hero_Treant.LeechSeed.Cast" )

					-- kill the target
					attacked_unit:Kill( spell, parent )
				end
      end
		end
	end
end


