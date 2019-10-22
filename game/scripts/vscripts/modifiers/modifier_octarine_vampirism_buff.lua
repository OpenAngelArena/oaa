modifier_octarine_vampirism_buff = class(ModifierBaseClass)

--------------------------------------------------------------------------------
function modifier_octarine_vampirism_buff:DeclareFunctions(params)
	local funcs = {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_PROPERTY_TOOLTIP
	}

	return funcs
end

function modifier_octarine_vampirism_buff:IsHidden()
	return true
end

function modifier_octarine_vampirism_buff:IsPurgable()
	return false
end

function modifier_octarine_vampirism_buff:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

--------------------------------------------------------------------------------

function modifier_octarine_vampirism_buff:OnCreated( kv )
	self.hero_lifesteal = self:GetAbility():GetSpecialValueFor( "hero_lifesteal" )
	self.creep_lifesteal = self:GetAbility():GetSpecialValueFor( "creep_lifesteal" )

	self.hero_spellsteal_unholy = self:GetAbility():GetSpecialValueFor( "unholy_hero_spell_lifesteal" )
	self.creep_spellsteal_unholy = self:GetAbility():GetSpecialValueFor( "unholy_creep_spell_lifesteal" )
end

--------------------------------------------------------------------------------

function modifier_octarine_vampirism_buff:OnRefresh( kv )
	self.hero_lifesteal = self:GetAbility():GetSpecialValueFor( "hero_lifesteal" )
	self.creep_lifesteal = self:GetAbility():GetSpecialValueFor( "creep_lifesteal" )

	self.hero_spellsteal_unholy = self:GetAbility():GetSpecialValueFor( "unholy_hero_spell_lifesteal" )
	self.creep_spellsteal_unholy = self:GetAbility():GetSpecialValueFor( "unholy_creep_spell_lifesteal" )
end

--------------------------------------------------------------------------------

function modifier_octarine_vampirism_buff:OnTooltip( params )
	return self.hero_lifesteal
end

--------------------------------------------------------------------------------
function modifier_octarine_vampirism_buff:OnTakeDamage(params)
	local hero = self:GetParent()
	local isFirstVampModifier = hero:FindModifierByName(self:GetName()) == self

	local function IsItemOctarine(item)
		-- Compare the full name because we don't want to include Octarine Core 2
		return item and item:GetAbilityName() == "item_octarine_core"
	end
	local items = map(partial(hero.GetItemInSlot, hero), range(0, 5))
	local heroHasOctarine = any(IsItemOctarine, items)

	-- Don't do anything if hero is Broken, self isn't the first spell vamp modifier, or hero has a level 1 Octarine Core
	-- in their inventory
	if not isFirstVampModifier or heroHasOctarine then
		return
	end

	-- Ignore damage that has the no-reflect or no spell lifesteal flags
	-- Thanks, Siltbreaker!
	if bit.band( params.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION ) > 0 then
		return 0
	end

	-- for ... some reason this still allow lifestealing off of cleave despite
	-- this being taken from siltbreaker
	-- but i'll leave it in since there's no harm
	if bit.band( params.damage_flags, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL ) > 0 then
		return 0
	end

	-- no idea why this one isn't used in siltbreaker
	if bit.band( params.damage_flags, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION  ) > 0 then
		return 0
	end

	local dmg = params.damage
	local nHeroHeal = self.hero_lifesteal / 100
	local nCreepHeal = self.creep_lifesteal / 100

	if self.hero_spellsteal_unholy and hero:HasModifier("modifier_satanic_core_unholy") and hero:HasModifier("modifier_item_satanic_core") then
		nHeroHeal = self.hero_spellsteal_unholy / 100
		nCreepHeal = self.creep_spellsteal_unholy / 100
	end

	if params.inflictor then
		if params.attacker == hero then
      local heal_amount = 0
      local damaged_unit = params.unit

      if damaged_unit:IsRealHero() then
        -- Don't heal on self damage
        if damaged_unit ~= hero then
          heal_amount = dmg * nHeroHeal
        end
      else
        -- Illusions are treated as creeps too
        heal_amount = dmg * nCreepHeal
      end

			if heal_amount > 0 then
				local healthCalculated = hero:GetHealth() + heal_amount
				hero:Heal(heal_amount, self:GetAbility())
				local particle = ParticleManager:CreateParticle("particles/items3_fx/octarine_core_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
				ParticleManager:ReleaseParticleIndex(particle)
			end
		end
	end
end
