dragon_knight_elder_dragon_form_oaa = class( AbilityBaseClass )

LinkLuaModifier( "modifier_dragon_knight_elder_dragon_form_oaa", "abilities/oaa_elder_dragon_form.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_dragon_knight_max_level_oaa", "abilities/oaa_elder_dragon_form.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_dragon_knight_frostbite_debuff_oaa", "abilities/oaa_elder_dragon_form.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

-- this makes the ability passive when it hits level 5
--[[
function dragon_knight_elder_dragon_form_oaa:GetBehavior()
	if self:GetLevel() >= 5 then
		return DOTA_ABILITY_BEHAVIOR_PASSIVE
	end

	return self.BaseClass.GetBehavior( self )
end
]]

--------------------------------------------------------------------------------

-- this is meant to accompany the above, removing the mana cost and cooldown
-- from the tooltip when it becomes passive
function dragon_knight_elder_dragon_form_oaa:GetCooldown( level )
	if self:GetLevel() >= 5 or level >= 5 then
		return 0
	end

	return self.BaseClass.GetCooldown( self, level )
end

--------------------------------------------------------------------------------

function dragon_knight_elder_dragon_form_oaa:GetManaCost( level )
	if self:GetLevel() >= 5 or level >= 5 then
		return 0
	end

	return self.BaseClass.GetManaCost( self, level )
end

--------------------------------------------------------------------------------

function dragon_knight_elder_dragon_form_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local level = self:GetLevel()
  local duration = self:GetSpecialValueFor( "duration" )
  local ability = caster:FindAbilityByName("dragon_knight_elder_dragon_form") or self

  -- apply the standard dragon form modifier ( for movespeed and the model change )
  caster:AddNewModifier( caster, ability, "modifier_dragon_knight_dragon_form", { duration = duration, } )

  -- apply the corrosive breath modifier, don't need to check its level really
  caster:AddNewModifier( caster, ability, "modifier_dragon_knight_corrosive_breath", { duration = duration, } )

  -- apply the leveled modifiers
  if level >= 2 then
    caster:AddNewModifier( caster, ability, "modifier_dragon_knight_splash_attack", { duration = duration, } )
  end

  if level >= 3 then
    caster:AddNewModifier( caster, ability, "modifier_dragon_knight_frost_breath", { duration = duration, } )
  end

  if level >= 5 or ( level >= 4 and caster:HasScepter() ) then
    caster:AddNewModifier( caster, self, "modifier_dragon_knight_max_level_oaa", { duration = duration, } )
  end
end

--------------------------------------------------------------------------------
--[[
function dragon_knight_elder_dragon_form_oaa:GetIntrinsicModifierName()
	-- adds the modifier in change of automatically transforming dk
	-- when edf hits level 5 actually no level 4
	-- since now this is also in charge of rage
	if self:GetLevel() >= 4 then
		return "modifier_dragon_knight_elder_dragon_form_oaa"
	end
end
]]

--------------------------------------------------------------------------------

function dragon_knight_elder_dragon_form_oaa:OnUpgrade()
  local caster = self:GetCaster()
  local ability_level = self:GetLevel()
  --[[
  -- we need to refresh the passive modifier to cause it to instantly
  -- transform dk on upgrade
  if ability_level >= 5 then
    -- adding it again works in the off chance the modifier is somehow removed
    caster:AddNewModifier( caster, self, "modifier_dragon_knight_elder_dragon_form_oaa", {} )
  end
  ]]
  local vanilla_ability = caster:FindAbilityByName("dragon_knight_elder_dragon_form")
  
  if not vanilla_ability then
    return
  end
  
  if ability_level >= 4 then
    if caster:HasScepter() then
      vanilla_ability:SetLevel(3)
    else
      vanilla_ability:SetLevel(4)
    end
    return
  end

  vanilla_ability:SetLevel(ability_level)
end

--------------------------------------------------------------------------------

modifier_dragon_knight_elder_dragon_form_oaa = class( ModifierBaseClass )

-- table of edf modifiers
modifier_dragon_knight_elder_dragon_form_oaa.edfMods = {
	"modifier_dragon_knight_dragon_form",
	"modifier_dragon_knight_corrosive_breath",
	"modifier_dragon_knight_splash_attack",
	"modifier_dragon_knight_frost_breath",
}

--------------------------------------------------------------------------------

function modifier_dragon_knight_elder_dragon_form_oaa:IsHidden()
	return true
end

function modifier_dragon_knight_elder_dragon_form_oaa:IsDebuff()
	return false
end

function modifier_dragon_knight_elder_dragon_form_oaa:IsPurgable()
	return false
end

function modifier_dragon_knight_elder_dragon_form_oaa:RemoveOnDeath()
	return false
end

--------------------------------------------------------------------------------

if IsServer() then
	function modifier_dragon_knight_elder_dragon_form_oaa:OnCreated( event )
		local parent = self:GetParent()
		local spell = self:GetAbility()

		-- apply all the edf modifiers on creation if level 5
		if spell:GetLevel() >= 5 then
			for _, modName in ipairs( self.edfMods ) do
				local mod = parent:FindModifierByName( modName )

				if not mod then
					parent:AddNewModifier( parent, spell, modName, {} )
				else
					-- if dk already has 'em, just set their duration to "permanent"
					-- so no special effect happens on level up if he's already transformed
					mod:SetDuration( -1, true )
				end
			end
		end
	end

--------------------------------------------------------------------------------

	function modifier_dragon_knight_elder_dragon_form_oaa:OnRefresh( event )
		local parent = self:GetParent()
		local spell = self:GetAbility()

		-- apply all the edf modifiers on creation if level 5
		if spell:GetLevel() >= 5 then
			for _, modName in pairs( self.edfMods ) do
				local mod = parent:FindModifierByName( modName )

				if not mod then
					parent:AddNewModifier( parent, spell, modName, {} )
				else
					-- if dk already has 'em, just set their duration to "permanent"
					-- so no special effect happens on level up if he's already transformed
					mod:SetDuration( -1, true )
				end
			end
		end
	end

--------------------------------------------------------------------------------

	function modifier_dragon_knight_elder_dragon_form_oaa:DeclareFunctions()
		local funcs = {
			MODIFIER_EVENT_ON_ATTACK_LANDED,
			MODIFIER_EVENT_ON_RESPAWN,
		}

		return funcs
	end

--------------------------------------------------------------------------------

	function modifier_dragon_knight_elder_dragon_form_oaa:OnAttackLanded( event )
		local parent = self:GetParent()

		if event.attacker == parent and event.process_procs then
			local spell = self:GetAbility()

			if spell:GetLevel() == 4 then
				-- no rage while broken
				if parent:PassivesDisabled() then
					return
				end

				local chance = spell:GetSpecialValueFor( "rage_chance" ) / 100

				-- we're using the modifier's stack to store the amount of prng failures
				-- this could be something else but since this modifier is hidden anyway ...
				local prngMult = self:GetStackCount() + 1

				-- compared prng to slightly less prng
				if RandomFloat( 0.0, 1.0 ) <= ( PrdCFinder:GetCForP(chance) * prngMult ) then
					-- reset failure count
					self:SetStackCount( 0 )

					local duration = spell:GetSpecialValueFor( "rage_duration" )

					-- check if the ability is already active, and if so, grab the current
					-- duration
					local mod = parent:FindModifierByName( "modifier_dragon_knight_dragon_form" )

					if mod then
						duration = duration + mod:GetRemainingTime()
					end

					-- apply the edf modifiers with the new duration
					for _, modName in pairs( self.edfMods ) do
						parent:AddNewModifier( parent, spell, modName, { duration = duration } )
					end
				else
					-- increment failure count
					self:SetStackCount( prngMult )
				end
			end
		end
	end

--------------------------------------------------------------------------------

	function modifier_dragon_knight_elder_dragon_form_oaa:OnRespawn( event )
		local parent = self:GetParent()
		local spell = self:GetAbility()

		if event.unit == parent and spell:GetLevel() >= 5 then
			-- apply the edf modifiers on respawn
			for _, modName in pairs( self.edfMods ) do
				parent:AddNewModifier( parent, spell, modName, {} )
			end
		end
	end
end

---------------------------------------------------------------------------------------------------

modifier_dragon_knight_max_level_oaa = class(ModifierBaseClass)

function modifier_dragon_knight_max_level_oaa:IsHidden()
  return false
end

function modifier_dragon_knight_max_level_oaa:IsDebuff()
  return false
end

function modifier_dragon_knight_max_level_oaa:IsPurgable()
  return false
end

function modifier_dragon_knight_max_level_oaa:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
  }

  return funcs
end

function modifier_dragon_knight_max_level_oaa:OnAttackLanded(event)
  local parent = self:GetParent()
  local ability = self:GetAbility()
  local target = event.target

  if parent ~= event.attacker then
    return
  end

  -- No effect while broken or illusion
  if parent:PassivesDisabled() or parent:IsIllusion() then
    return
  end

  -- To prevent crashes:
  if not target then
    return
  end

  if target:IsNull() then
    return
  end

  -- Check for existence of GetUnitName method to determine if target is a unit or an item (or rune)
  -- items don't have that method -> nil; if the target is an item, don't continue
  if target.GetUnitName == nil then
    return
  end

  -- Don't affect buildings, wards and invulnerable units.
  if target:IsTower() or target:IsBarracks() or target:IsBuilding() or target:IsOther() or target:IsMagicImmune() or target:IsInvulnerable() then
    return
  end

  local duration = ability:GetSpecialValueFor("frost_duration")

  -- Apply the debuff
  target:AddNewModifier(parent, ability, "modifier_dragon_knight_frostbite_debuff_oaa", {duration = duration})
end

function modifier_dragon_knight_max_level_oaa:GetModifierMagicalResistanceBonus()
  --local ability = self:GetAbility()
  --return ability:GetLevelSpecialValueFor("magic_resistance", ability:GetLevel()-1)
  return 20
end

---------------------------------------------------------------------------------------------------

modifier_dragon_knight_frostbite_debuff_oaa = class(ModifierBaseClass)

function modifier_dragon_knight_frostbite_debuff_oaa:IsHidden()
  return false
end

function modifier_dragon_knight_frostbite_debuff_oaa:IsDebuff()
  return true
end

function modifier_dragon_knight_frostbite_debuff_oaa:IsPurgable()
  return true
end

function modifier_dragon_knight_frostbite_debuff_oaa:GetEffectName()
  return "particles/items4_fx/spirit_vessel_damage.vpcf"
end

function modifier_dragon_knight_frostbite_debuff_oaa:OnCreated( kv )
  self.heal_suppression_pct = self:GetAbility():GetSpecialValueFor( "heal_suppression_pct" )
end

function modifier_dragon_knight_frostbite_debuff_oaa:OnRefresh( kv )
  self.heal_suppression_pct = self:GetAbility():GetSpecialValueFor( "heal_suppression_pct" )
end

function modifier_dragon_knight_frostbite_debuff_oaa:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
    MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
  }
  return funcs
end

function modifier_dragon_knight_frostbite_debuff_oaa:GetModifierHealAmplify_PercentageTarget()
  return -self.heal_suppression_pct
end

function modifier_dragon_knight_frostbite_debuff_oaa:GetModifierHPRegenAmplify_Percentage()
  return -self.heal_suppression_pct
end

function modifier_dragon_knight_frostbite_debuff_oaa:GetModifierLifestealRegenAmplify_Percentage()
  return -self.heal_suppression_pct
end

function modifier_dragon_knight_frostbite_debuff_oaa:GetModifierSpellLifestealRegenAmplify_Percentage()
  return -self.heal_suppression_pct
end
