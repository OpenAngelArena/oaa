LinkLuaModifier("modifier_generic_bonus", "modifiers/modifier_generic_bonus.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_devastator_slow_movespeed", "modifiers/modifier_item_devastator_slow_movespeed.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_devastator_reduce_armor", "modifiers/modifier_item_devastator_reduce_armor.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_devastator_desolator", "modifiers/modifier_item_devastator_desolator.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_devastator_corruption_armor", "modifiers/modifier_item_devastator_corruption_armor.lua", LUA_MODIFIER_MOTION_NONE)

item_devastator = class(ItemBaseClass)
item_devastator_3 = item_devastator
item_devastator_4 = item_devastator
item_devastator_5 = item_devastator


function item_devastator:OnSpellStart()
  self.devastator_speed = self:GetSpecialValueFor( "devastator_speed" )
	self.devastator_width_initial = self:GetSpecialValueFor( "devastator_width_initial" )
	self.devastator_width_end = self:GetSpecialValueFor( "devastator_width_end" )
	self.devastator_distance = self:GetSpecialValueFor( "devastator_distance" )
	self.devastator_damage = self:GetSpecialValueFor( "devastator_damage" )
	self.devastator_movespeed_reduction_duration = self:GetSpecialValueFor( "devastator_movespeed_reduction_duration" )
	self.devastator_armor_reduction_duration = self:GetSpecialValueFor( "devastator_armor_reduction_duration" )
	self.devastator_corruption_duration = self:GetSpecialValueFor( "corruption_duration" )

	-- Re enable if the item should have any sound
	-- EmitSoundOn( "Hero_Lina.DragonSlave.Cast", self:GetCaster() )

	local vPos = nil
	if self:GetCursorTarget() then
		vPos = self:GetCursorTarget():GetOrigin()
	else
		vPos = self:GetCursorPosition()
	end

	local vDirection = vPos - self:GetCaster():GetOrigin()
	vDirection.z = 0.0
	vDirection = vDirection:Normalized()

	self.devastator_speed = self.devastator_speed * ( self.devastator_distance / ( self.devastator_distance - self.devastator_width_initial ) )

	local info = {
		-- replace with the correct particles
		
		EffectName = "particles/units/heroes/hero_lina/lina_spell_dragon_slave.vpcf",
		Ability = self,
		vSpawnOrigin = self:GetCaster():GetOrigin(),
		fStartRadius = self.devastator_width_initial,
		fEndRadius = self.devastator_width_end,
		vVelocity = vDirection * self.devastator_speed,
		fDistance = self.devastator_distance,
		Source = self:GetCaster(),
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
	}

	ProjectileManager:CreateLinearProjectile( info )
	-- Re enable if the item should have sound
	-- EmitSoundOn( "Hero_Lina.DragonSlave", self:GetCaster() )
end

-- Impact of the projectile
function item_devastator:OnProjectileHit( hTarget, vLocation )
	if hTarget ~= nil and ( not hTarget:IsMagicImmune() ) and ( not hTarget:IsInvulnerable() ) then
		local damage = {
			victim = hTarget,
			attacker = self:GetCaster(),
			damage = self.devastator_damage,
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = self
		}

		ApplyDamage( damage )

		local vDirection = vLocation - self:GetCaster():GetOrigin()
		vDirection.z = 0.0
		vDirection = vDirection:Normalized()
		-- Replace with the particles for the item
		local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_lina/lina_spell_dragon_slave_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, hTarget )
		ParticleManager:SetParticleControlForward( nFXIndex, 1, vDirection )
    ParticleManager:ReleaseParticleIndex( nFXIndex )

		hTarget:AddNewModifier( hTarget, self, "modifier_item_devastator_slow_movespeed", { duration = self.devastator_movespeed_reduction_duration } )

		-- check the current devastator_armor_reduction and the corruption_armor check the higher
		local armor_reduction = self:GetSpecialValueFor( "devastator_armor_reduction" )
		local corruption_armor = self:GetSpecialValueFor( "corruption_armor" )


		-- if already has applied corruption
		if hTarget:HasModifier("modifier_item_devastator_corruption_armor") then
			-- if corruption is higher than armor reduction just exit
			if   corruption_armor < armor_reduction then
				return false
			end
			-- so in this case should remove corruption and applied
			hTarget:RemoveModifierByName("modifier_item_devastator_corruption_armor");

		end
		-- if there is no other just applied it
		hTarget:AddNewModifier( hTarget, self, "modifier_item_devastator_reduce_armor", { duration = self.devastator_armor_reduction_duration } )

	end

	return false
end

-- base modifiers for the passive effects
function item_devastator:GetIntrinsicModifierName()
  return "modifier_item_devastator_desolator"
end
