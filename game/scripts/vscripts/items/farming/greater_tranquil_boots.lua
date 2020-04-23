item_greater_tranquil_boots = class(ItemBaseClass)

LinkLuaModifier( "modifier_item_greater_tranquil_boots", "items/farming/greater_tranquil_boots.lua", LUA_MODIFIER_MOTION_NONE )
--LinkLuaModifier( "modifier_intrinsic_multiplexer", "modifiers/modifier_intrinsic_multiplexer.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_greater_tranquils_tranquilize_debuff", "items/farming/greater_tranquil_boots.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

function item_greater_tranquil_boots:GetAbilityTextureName()
	local baseName = self.BaseClass.GetAbilityTextureName( self )

	if not self:IsBreakable() then
		return baseName
	end

	local brokeName = ""

	if self.tranqMod and not self.tranqMod:IsNull() and self.tranqMod:GetRemainingTime() > 0 then
		brokeName = "_active"
	end

	return baseName .. brokeName
end

--------------------------------------------------------------------------------

function item_greater_tranquil_boots:GetIntrinsicModifierName()
	return "modifier_item_greater_tranquil_boots" -- "modifier_intrinsic_multiplexer"
end
-- uncomment this if we plan to add more effects to Greater Tranquil Boots
--[[
function item_greater_tranquil_boots:GetIntrinsicModifierNames()
  return {
    "modifier_item_greater_tranquil_boots",
  }
end
]]

function item_greater_tranquil_boots:ShouldUseResources()
  return true
end

function item_greater_tranquil_boots:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()

  -- Don't do anything if target has Linken's effect
  if target:TriggerSpellAbsorb(self) then
    return
  end

  local duration = self:GetSpecialValueFor("tranquilize_duration")
  -- Apply status resistance only if its a ranged hero
  if target:IsRangedAttacker() then
    duration = target:GetValueChangedByStatusResistance(duration)
  end
  target:AddNewModifier(caster, self, "modifier_greater_tranquils_tranquilize_debuff", {duration = duration})
end

--------------------------------------------------------------------------------

-- used for various checks to accomodate for origin
-- ( or any future changes that make them unbreakable or something )
function item_greater_tranquil_boots:IsBreakable()
	return self:GetSpecialValueFor("break_time") > 0
end

--------------------------------------------------------------------------------

modifier_item_greater_tranquil_boots = class(ModifierBaseClass)

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

function modifier_item_greater_tranquil_boots:OnCreated( event )
	local spell = self:GetAbility()

	spell.tranqMod = self

	if IsServer() then
		if spell:IsBreakable() then
			local cdRemaining = spell:GetCooldownTimeRemaining()
			-- Break for any remaining duration (e.g. if item was dropped and picked up)
			-- Have to check for 0 because setting duration to 0 apparently destroys the modifier even with DestroyOnExpire false
			if cdRemaining > 0 then
				self:SetDuration( cdRemaining, true )
			end
		end
	end

	self.moveSpd = spell:GetSpecialValueFor( "bonus_movement_speed" )
	self.moveSpdBroken = spell:GetSpecialValueFor( "broken_movement_speed" )
	self.armor = spell:GetSpecialValueFor( "bonus_armor" )
	self.healthRegen = spell:GetSpecialValueFor( "bonus_health_regen" )
end

--------------------------------------------------------------------------------

function modifier_item_greater_tranquil_boots:OnRefresh( event )
	local spell = self:GetAbility()

	spell.tranqMod = self

	if IsServer() then
		if spell:IsBreakable() then
			local cdRemaining = spell:GetCooldownTimeRemaining()
			-- Break for any remaining duration (e.g. if item was dropped and picked up)
			-- Have to check for 0 because setting duration to 0 apparently destroys the modifier even with DestroyOnExpire false
			if cdRemaining > 0 then
				self:SetDuration( cdRemaining, true )
			end
		end
	end

	self.moveSpd = spell:GetSpecialValueFor( "bonus_movement_speed" )
	self.moveSpdBroken = spell:GetSpecialValueFor( "broken_movement_speed" )
	self.armor = spell:GetSpecialValueFor( "bonus_armor" )
	self.healthRegen = spell:GetSpecialValueFor( "bonus_health_regen" )
end

--------------------------------------------------------------------------------
--[[ Old checking distance traveled and modifying charges accordingly (part of Naturalize)
if IsServer() then
	function modifier_item_greater_tranquil_boots:OnIntervalThink()
		local parent = self:GetParent()
		local spell = self:GetAbility()

		-- disable everything here for illusions or during duels / pre 0:00
		if parent:IsIllusion() or not Gold:IsGoldGenActive() then
			return
		end

		if self.storedDamage and self.storedDamage > 0 then
			local parent = self:GetParent()
			local maxHeal = math.min( spell:GetSpecialValueFor( "regen_from_creeps" ) * self.interval, self.storedDamage )

			parent:Heal( maxHeal, parent )

			self.storedDamage = self.storedDamage - maxHeal
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
]]

function modifier_item_greater_tranquil_boots:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT_UNIQUE,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}

	return funcs
end

--------------------------------------------------------------------------------

if IsServer() then
  function modifier_item_greater_tranquil_boots:OnAttackLanded( event )
    local parent = self:GetParent()
    local attacker = event.attacker
    local attacked_unit = event.target

    if attacked_unit == parent then
      local spell = self:GetAbility()

      -- Break Tranquils only in the following cases:
      -- old 1. If the parent attacked a hero
      -- old 2. If the parent was attacked by a hero, boss, hero creep or a player-controlled creep.
      -- ((attacker == parent and attacked_unit:IsHero()) or (attacked_unit == parent and (attacker:IsConsideredHero() or attacker:IsControllableByAnyPlayer())))
      --
      -- new 1: if the parent was attacked by a real hero (not an illusion and not a hero creep or boss)
      if spell:IsBreakable() and attacker:IsRealHero() then
        spell:UseResources(false, false, true)

        local cdRemaining = spell:GetCooldownTimeRemaining()
        if cdRemaining > 0 then
          self:SetDuration( cdRemaining, true )
        end
      end
    end
	end
end

--------------------------------------------------------------------------------

function modifier_item_greater_tranquil_boots:GetModifierMoveSpeedBonus_Constant_Unique()
	local spell = self:GetAbility()

	if self:GetRemainingTime() <= 0 or not spell:IsBreakable() then
		return self.moveSpd
	end

	return self.moveSpdBroken
end

--------------------------------------------------------------------------------

function modifier_item_greater_tranquil_boots:GetModifierPhysicalArmorBonus()
	return self.armor
end

--------------------------------------------------------------------------------

function modifier_item_greater_tranquil_boots:GetModifierConstantHealthRegen()
	local spell = self:GetAbility()

	if self:GetRemainingTime() <= 0 or not spell:IsBreakable() then
		return self.healthRegen
	end

	return 0
end

--------------------------------------------------------------------------------
--[[ Old Tranquils effect
LinkLuaModifier( "modifier_item_greater_tranquil_boots_sap", "items/farming/greater_tranquil_boots.lua", LUA_MODIFIER_MOTION_NONE )

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
]]

---------------------------------------------------------------------------------------------------

modifier_greater_tranquils_tranquilize_debuff = class(ModifierBaseClass)

function modifier_greater_tranquils_tranquilize_debuff:IsHidden()
  return false
end

function modifier_greater_tranquils_tranquilize_debuff:IsDebuff()
  return true
end

function modifier_greater_tranquils_tranquilize_debuff:IsPurgable()
  return true
end

function modifier_greater_tranquils_tranquilize_debuff:OnCreated()
  local parent = self:GetParent()
  local attack_slow = self:GetAbility():GetSpecialValueFor("melee_attack_speed_slow")
  if parent:IsRangedAttacker() or parent:IsOAABoss() then
    attack_slow = 0
  end
  if IsServer() then
    -- Attack Speed Slow is reduced with Status Resistance
    self.attack_slow = parent:GetValueChangedByStatusResistance(attack_slow)
  else
    self.attack_slow = attack_slow
  end
end

function modifier_greater_tranquils_tranquilize_debuff:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
  }
  return funcs
end

function modifier_greater_tranquils_tranquilize_debuff:GetModifierAttackSpeedBonus_Constant()
  return self.attack_slow
end

function modifier_greater_tranquils_tranquilize_debuff:GetModifierAttackRangeBonus()
  local ability = self:GetAbility()
  if ability and self:GetParent():IsRangedAttacker() then
    return ability:GetSpecialValueFor("ranged_bonus_attack_range")
  end
  return 0
end

item_greater_tranquil_boots_2 = class(item_greater_tranquil_boots)
item_greater_tranquil_boots_3 = class(item_greater_tranquil_boots)
item_greater_tranquil_boots_4 = class(item_greater_tranquil_boots)
item_greater_tranquil_boots_5 = class(item_greater_tranquil_boots)
--item_tranquil_origin = class(item_greater_tranquil_boots)
