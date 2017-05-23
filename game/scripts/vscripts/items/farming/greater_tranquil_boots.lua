item_greater_tranquil_boots = class({})

LinkLuaModifier( "modifier_item_greater_tranquil_boots", "items/item_greater_tranquil_boots.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_greater_tranquil_boots_sap", "items/item_greater_tranquil_boots.lua", LUA_MODIFIER_MOTION_NONE )

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

modifier_item_greater_tranquil_boots = class({})

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

	if IsServer() then
		self:SetDuration( spell:GetCooldownTime(), true )

		self:StartIntervalThink( 0.1 )
	end
end

--------------------------------------------------------------------------------

if IsServer() then
	function modifier_item_greater_tranquil_boots:OnIntervalThink()
		if self.storedDamage and self.storedDamage > 0 then
			local parent = self:GetParent()
			local spell = self:GetAbility()
			local maxHeal = math.min( spell:GetSpecialValueFor( "regen_from_creeps" ) * 0.1, self.storedDamage )

			parent:Heal( maxHeal, parent )

			self.storedDamage = self.storedDamage - maxHeal
		end
	end
end

--------------------------------------------------------------------------------

function modifier_item_greater_tranquil_boots:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_UNIQUE,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
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
			if UnitFilter( checkUnit, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC, bit.bor( DOTA_UNIT_TARGET_FLAG_DEAD, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO ), parent:GetTeamNumber() ) == UF_SUCCESS and not checkUnit:IsControllableByAnyPlayer() then
				-- if both creep sap specials are greater than 0, and the attacker is the creep
				-- apply the creep sap modifier
				if checkUnit == event.attacker then
					if spell:GetSpecialValueFor( "creep_sap_duration" ) > 0 and spell:GetSpecialValueFor( "creep_sap_damage" ) > 0 then
						event.attacker:AddNewModifier( parent, spell, "modifier_item_greater_tranquil_boots_sap", {
							duration = spell:GetSpecialValueFor( "creep_sap_duration" ),
						} )
					end
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
		return spell:GetSpecialValueFor( "bonus_movement_speed" )
	end

	return spell:GetSpecialValueFor( "broken_movement_speed" )
end

--------------------------------------------------------------------------------

function modifier_item_greater_tranquil_boots:GetModifierPhysicalArmorBonus( event )
	local spell = self:GetAbility()

	return spell:GetSpecialValueFor( "bonus_armor" )
end

--------------------------------------------------------------------------------

function modifier_item_greater_tranquil_boots:GetModifierConstantHealthRegen( event )
	local spell = self:GetAbility()

	if self:GetRemainingTime() <= 0 then
		return spell:GetSpecialValueFor( "bonus_health_regen" )
	end

	return 0
end

--------------------------------------------------------------------------------

modifier_item_greater_tranquil_boots_sap = class({})

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
