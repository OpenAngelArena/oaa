item_greater_tranquil_boots = class(ItemBaseClass)

LinkLuaModifier( "modifier_item_greater_tranquil_boots", "items/farming/greater_tranquil_boots.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_greater_tranquil_boots_sap", "items/farming/greater_tranquil_boots.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

function item_greater_tranquil_boots:GetAbilityTextureName()
	local baseName = self.BaseClass.GetAbilityTextureName( self )

	local brokeName = ""

	if self.tranqMod and not self.tranqMod:IsNull() and self.tranqMod:GetRemainingTime() > 0 then
		brokeName = "_active"
	end

	return baseName .. brokeName
end

--------------------------------------------------------------------------------

function item_greater_tranquil_boots:GetIntrinsicModifierName()
	return "modifier_item_greater_tranquil_boots"
end

--------------------------------------------------------------------------------

modifier_item_greater_tranquil_boots = class(ModifierBaseClass)

--------------------------------------------------------------------------------

function modifier_item_greater_tranquil_boots:IsHidden()
	return true
end

function modifier_item_greater_tranquil_boots:IsDebuff()
	return false
end

function modifier_item_greater_tranquil_boots:IsPurgable()
	return false
end

function modifier_item_greater_tranquil_boots:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_greater_tranquil_boots:DestroyOnExpire()
	return false
end

--------------------------------------------------------------------------------

function modifier_item_greater_tranquil_boots:OnCreated( event )
	local spell = self:GetAbility()

	spell.tranqMod = self

	self.interval = spell:GetSpecialValueFor( "check_interval" )

	if IsServer() then
		self:SetDuration( spell:GetCooldownTime(), true )

		self:StartIntervalThink( self.interval )
	end

	self.moveSpd = spell:GetSpecialValueFor( "bonus_movement_speed" )
	self.moveSpdBroken = spell:GetSpecialValueFor( "broken_movement_speed" )
	self.armor = spell:GetSpecialValueFor( "bonus_armor" )
	self.healthRegen = spell:GetSpecialValueFor( "bonus_health_regen" )

	self.distPer = spell:GetSpecialValueFor( "distance_per_charge" )
	self.distMax = spell:GetSpecialValueFor( "max_dist" )
	self.bonusGold = spell:GetSpecialValueFor( "bonus_gold" )
	self.bonusXP = spell:GetSpecialValueFor( "bonus_xp" )
	self.maxCharges = spell:GetSpecialValueFor( "max_charges" )

	-- this stuff prob shouldn't get refreshed
	self.originOld = self:GetParent():GetAbsOrigin()
	self.fracCharge = 0
end

--------------------------------------------------------------------------------

function modifier_item_greater_tranquil_boots:OnRefresh( event )
	local spell = self:GetAbility()

	spell.tranqMod = self

	self.interval = spell:GetSpecialValueFor( "check_interval" )

	if IsServer() then
		self:SetDuration( spell:GetCooldownTime(), true )

		self:StartIntervalThink( self.interval )
	end

	self.moveSpd = spell:GetSpecialValueFor( "bonus_movement_speed" )
	self.moveSpdBroken = spell:GetSpecialValueFor( "broken_movement_speed" )
	self.armor = spell:GetSpecialValueFor( "bonus_armor" )
	self.healthRegen = spell:GetSpecialValueFor( "bonus_health_regen" )

	self.distPer = spell:GetSpecialValueFor( "distance_per_charge" )
	self.distMax = spell:GetSpecialValueFor( "max_dist" )
	self.bonusGold = spell:GetSpecialValueFor( "bonus_gold" )
	self.bonusXP = spell:GetSpecialValueFor( "bonus_xp" )
	self.maxCharges = spell:GetSpecialValueFor( "max_charges" )
end

--------------------------------------------------------------------------------

if IsServer() then
	function modifier_item_greater_tranquil_boots:OnIntervalThink()
		local parent = self:GetParent()
		local spell = self:GetAbility()

		-- disable everything here for illusions
		if parent:IsIllusion() then
			return
		end

		--[[
		if self.storedDamage and self.storedDamage > 0 then
			local parent = self:GetParent()
			local maxHeal = math.min( spell:GetSpecialValueFor( "regen_from_creeps" ) * self.interval, self.storedDamage )

			parent:Heal( maxHeal, parent )

			self.storedDamage = self.storedDamage - maxHeal
		end
		--]]

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

--------------------------------------------------------------------------------

	function modifier_item_greater_tranquil_boots:IsNeutralCreep( unit )
		local parent = self:GetParent()

		return ( UnitFilter( unit, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC, bit.bor( DOTA_UNIT_TARGET_FLAG_DEAD, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO ), parent:GetTeamNumber() ) == UF_SUCCESS and not unit:IsControllableByAnyPlayer() )
	end
end

--------------------------------------------------------------------------------

function modifier_item_greater_tranquil_boots:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_UNIQUE,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		--MODIFIER_EVENT_ON_TAKEDAMAGE,
	}

	return funcs
end

--------------------------------------------------------------------------------

if IsServer() then
	function modifier_item_greater_tranquil_boots:OnAttackLanded( event )
		local parent = self:GetParent()

		-- thankfully, tranqs don't have complicated trigger requirements
		if event.attacker == parent or event.target == parent then
			local spell = self:GetAbility()

			-- determine the other unit that isn't the parent
			local checkUnit = event.attacker
			if event.attacker == parent then
				checkUnit = event.target
			end

			-- if the checked unit is a neutral creep, don't break
			if self:IsNeutralCreep( checkUnit ) then
				-- nah
				--[[
				-- if both creep sap specials are greater than 0, and the attacker is the creep
				-- apply the creep sap modifier
				if checkUnit == event.attacker then
					if spell:GetSpecialValueFor( "creep_sap_duration" ) > 0 and spell:GetSpecialValueFor( "creep_sap_damage" ) > 0 then
						event.attacker:AddNewModifier( parent, spell, "modifier_item_greater_tranquil_boots_sap", {
							duration = spell:GetSpecialValueFor( "creep_sap_duration" ),
						} )
					end
				end
				--]]

				-- then check for naturalize eating
				local currentCharges = spell:GetCurrentCharges()

				if currentCharges >= 100 and event.attacker == parent and not spell:IsMuted() and not parent:IsIllusion() then
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
					event.target:Kill( spell, parent )
				end

				return
			end

			spell:UseResources( false, false, true )

			-- seriously, this is easy

			-- less so is actually making this do anything
			-- because valve
			self:SetDuration( spell:GetCooldownTime(), true )
		end
	end

--------------------------------------------------------------------------------

	function modifier_item_greater_tranquil_boots:OnTakeDamage( event )
		local parent = self:GetParent()

		if event.unit == parent then
			local attacker = event.attacker

			-- return if the damage isn't from a creep
			-- creep heroes count as not a creep, in this case
			if UnitFilter( attacker, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC, bit.bor( DOTA_UNIT_TARGET_FLAG_DEAD, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO ), parent:GetTeamNumber() ) ~= UF_SUCCESS then
				return
			end

			-- uncomment this if player units shouldn't proc this, either
			if attacker:IsControllableByAnyPlayer() then
				return
			end

			if not self.storedDamage then
				self.storedDamage = event.damage
			else
				self.storedDamage = self.storedDamage + event.damage
			end
		end
	end
end

--------------------------------------------------------------------------------

function modifier_item_greater_tranquil_boots:GetModifierMoveSpeedBonus_Special_Boots( event )
	local spell = self:GetAbility()

	if self:GetRemainingTime() <= 0 then
		return self.moveSpd or spell:GetSpecialValueFor( "bonus_movement_speed" )
	end

	return self.moveSpdBroken or spell:GetSpecialValueFor( "broken_movement_speed" )
end

--------------------------------------------------------------------------------

function modifier_item_greater_tranquil_boots:GetModifierPhysicalArmorBonus( event )
	local spell = self:GetAbility()

	return self.armor or spell:GetSpecialValueFor( "bonus_armor" )
end

--------------------------------------------------------------------------------

function modifier_item_greater_tranquil_boots:GetModifierConstantHealthRegen( event )
	local spell = self:GetAbility()

	if self:GetRemainingTime() <= 0 then
		return self.healthRegen or spell:GetSpecialValueFor( "bonus_health_regen" )
	end

	return 0
end

--------------------------------------------------------------------------------

modifier_item_greater_tranquil_boots_sap = class(ModifierBaseClass)

--------------------------------------------------------------------------------

function modifier_item_greater_tranquil_boots_sap:IsHidden()
	return true
end

function modifier_item_greater_tranquil_boots_sap:IsDebuff()
	return true
end

function modifier_item_greater_tranquil_boots_sap:IsPurgable()
	return false
end

--------------------------------------------------------------------------------

if IsServer() then
	function modifier_item_greater_tranquil_boots_sap:OnCreated( event )
		local spell = self:GetAbility()

		self.sapDamage = spell:GetSpecialValueFor( "creep_sap_damage" )

		self:StartIntervalThink( 1.0 )
	end

--------------------------------------------------------------------------------

	function modifier_item_greater_tranquil_boots_sap:OnRefresh( event )
		local spell = self:GetAbility()

		self.sapDamage = spell:GetSpecialValueFor( "creep_sap_damage" )
	end

--------------------------------------------------------------------------------

	function modifier_item_greater_tranquil_boots_sap:OnIntervalThink()
		if self.sapDamage then
			local parent = self:GetParent()
			local caster = self:GetCaster()
			local spell = self:GetAbility()

			local damage = parent:GetMaxHealth() * ( self.sapDamage * 0.01 )

			ApplyDamage( {
				victim = parent,
				attacker = caster,
				damage = damage,
				damage_type = DAMAGE_TYPE_MAGICAL,
				damage_flags = DOTA_DAMAGE_FLAG_HPLOSS,
				ability = spell,
			} )
		end
	end
end

--------------------------------------------------------------------------------

item_greater_tranquil_boots_2 = item_greater_tranquil_boots
item_greater_tranquil_boots_3 = item_greater_tranquil_boots
item_greater_tranquil_boots_4 = item_greater_tranquil_boots
item_greater_tranquil_boots_5 = item_greater_tranquil_boots
