item_greater_tranquil_boots = class(ItemBaseClass)

LinkLuaModifier( "modifier_intrinsic_multiplexer", "modifiers/modifier_intrinsic_multiplexer.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_greater_tranquil_boots", "items/farming/greater_tranquil_boots.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_greater_tranquils_trees_buff", "items/farming/greater_tranquil_boots.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_greater_tranquils_tranquilize_debuff", "items/farming/greater_tranquil_boots.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_greater_tranquils_tranquilize_buff", "items/farming/greater_tranquil_boots.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

--[[
function item_greater_tranquil_boots:GetAbilityTextureName()
	local baseName = self.BaseClass.GetAbilityTextureName( self )

	if not self:IsBreakable() then
		return baseName
	end

	local brokeName = ""

	if self:GetCaster():HasModifier("modifier_greater_tranquils_broken_debuff") then
		brokeName = "_active"
	end

	return baseName .. brokeName
end
]]

function item_greater_tranquil_boots:GetIntrinsicModifierName()
	return "modifier_intrinsic_multiplexer"
end

function item_greater_tranquil_boots:GetIntrinsicModifierNames()
  return {
    "modifier_item_greater_tranquil_boots",
    "modifier_greater_tranquils_trees_buff"
  }
end

function item_greater_tranquil_boots:ShouldUseResources()
  return true
end

function item_greater_tranquil_boots:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()

  -- Disable working on Meepo Clones
  if caster:IsClone() then
    self:RefundManaCost()
    self:EndCooldown()
    return
  end

  -- Create the projectile
  local info = {
    Target = target,
    Source = caster,
    Ability = self,
    EffectName = "particles/units/heroes/hero_abaddon/abaddon_death_coil.vpcf",
    bDodgeable = true,
    bProvidesVision = true,
    bVisibleToEnemies = true,
    bReplaceExisting = false,
    iMoveSpeed = self:GetSpecialValueFor("projectile_speed"),
    iVisionRadius = 250,
    iVisionTeamNumber = caster:GetTeamNumber(),
  }
  ProjectileManager:CreateTrackingProjectile(info)

end

function item_greater_tranquil_boots:OnProjectileHit(target, location)
  local caster = self:GetCaster()

  if not target or target:IsNull() then
    return
  end

  local debuff_duration = self:GetSpecialValueFor("slow_duration")
  local buff_duration = self:GetSpecialValueFor("sprout_duration")

  if target:GetTeamNumber() ~= caster:GetTeamNumber() then
    -- Don't do anything if target has Linken's effect or it's spell-immune
    if target:TriggerSpellAbsorb(self) or target:IsMagicImmune() then
      return
    end

    target:AddNewModifier(caster, self, "modifier_greater_tranquils_tranquilize_debuff", {duration = debuff_duration})
  else
    target:AddNewModifier(caster, self, "modifier_greater_tranquils_tranquilize_buff", {duration = buff_duration})
  end

  local target_loc = target:GetAbsOrigin()
  local r = 150
  local c = math.sqrt(2) * 0.5 * r
  local x_offset = { -r, -c, 0.0, c, r, c, 0.0, -c }
  local y_offset = { 0.0, c, r, c, 0.0, -c, -r, -c }

  local nFXIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_furion/furion_sprout.vpcf", PATTACH_CUSTOMORIGIN, nil)
  ParticleManager:SetParticleControl(nFXIndex, 0, target_loc)
  ParticleManager:SetParticleControl(nFXIndex, 1, Vector(0.0, r, 0.0))
  ParticleManager:ReleaseParticleIndex(nFXIndex)

  -- Create trees
  for i = 1,8 do
    CreateTempTree(target_loc + Vector(x_offset[i], y_offset[i], 0.0), buff_duration)
  end

  -- Unstuck entities
  for i = 1,8 do
    ResolveNPCPositions(target_loc + Vector(x_offset[i], y_offset[i], 0.0), 64.0)
  end

  -- Vision
  self:CreateVisibilityNode(target_loc, self:GetSpecialValueFor("sprout_vision_range"), buff_duration)

  -- Sound
  EmitSoundOnLocationWithCaster(target_loc, "Hero_Furion.Sprout", caster)
end

function item_greater_tranquil_boots:IsBreakable()
	return self:GetSpecialValueFor("break_time") > 0
end

item_greater_tranquil_boots_2 = class(item_greater_tranquil_boots)
item_greater_tranquil_boots_3 = class(item_greater_tranquil_boots)
item_greater_tranquil_boots_4 = class(item_greater_tranquil_boots)

---------------------------------------------------------------------------------------------------

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

--function modifier_item_greater_tranquil_boots:GetAttributes()
	--return MODIFIER_ATTRIBUTE_MULTIPLE
--end

function modifier_item_greater_tranquil_boots:OnCreated()
	local spell = self:GetAbility()
  if spell and not spell:IsNull() then
	  self.moveSpd = spell:GetSpecialValueFor("bonus_movement_speed")
	  --self.moveSpdBroken = spell:GetSpecialValueFor("broken_movement_speed")
	  self.armor = spell:GetSpecialValueFor("bonus_armor")
	  self.healthRegen = spell:GetSpecialValueFor("bonus_health_regen")
  end
end

modifier_item_greater_tranquil_boots.OnRefresh = modifier_item_greater_tranquil_boots.OnCreated

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
		MODIFIER_PROPERTY_MOVESPEED_BONUS_UNIQUE,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		--MODIFIER_EVENT_ON_ATTACK_LANDED,
	}

	return funcs
end

-- if IsServer() then
  -- function modifier_item_greater_tranquil_boots:OnAttackLanded( event )
    -- local parent = self:GetParent()
    -- local attacker = event.attacker
    -- local attacked_unit = event.target

    -- if attacked_unit == parent then
      -- local spell = self:GetAbility()

      -- --Break Tranquils only in the following cases:
      -- --old 1. If the parent attacked a hero
      -- --old 2. If the parent was attacked by a hero, boss, hero creep or a player-controlled creep.
      -- --((attacker == parent and attacked_unit:IsHero()) or (attacked_unit == parent and (attacker:IsConsideredHero() or attacker:IsControllableByAnyPlayer())))
      -- --new 1: if the parent was attacked by a real hero (not an illusion and not a hero creep or boss)

      -- if spell:IsBreakable() and attacker:IsRealHero() then
        -- spell:UseResources(false, false, true)
        -- local cdRemaining = spell:GetCooldownTimeRemaining()
        -- if cdRemaining > 0 then
          -- parent:AddNewModifier(parent, spell, "modifier_greater_tranquils_broken_debuff", {duration = cdRemaining})
        -- end
      -- end
    -- end
	-- end
-- end

function modifier_item_greater_tranquil_boots:GetModifierMoveSpeedBonus_Special_Boots()
	-- local spell = self:GetAbility()
	-- if self:GetRemainingTime() <= 0 or not spell:IsBreakable() then
		-- return self.moveSpd
	-- end
	-- return self.moveSpdBroken
  return self.moveSpd
end

function modifier_item_greater_tranquil_boots:GetModifierPhysicalArmorBonus()
	return self.armor
end

function modifier_item_greater_tranquil_boots:GetModifierConstantHealthRegen()
	-- local spell = self:GetAbility()
	-- if self:GetRemainingTime() <= 0 or not spell:IsBreakable() then
		-- return self.healthRegen
	-- end
	-- return 0
  return self.healthRegen
end

function modifier_item_greater_tranquil_boots:CheckState()
  local state = {
    [MODIFIER_STATE_ALLOW_PATHING_THROUGH_TREES] = true,
  }
  return state
end

---------------------------------------------------------------------------------------------------
--[[ Old Tranquils effect
LinkLuaModifier( "modifier_item_greater_tranquil_boots_sap", "items/farming/greater_tranquil_boots.lua", LUA_MODIFIER_MOTION_NONE )

modifier_item_greater_tranquil_boots_sap = class(ModifierBaseClass)

function modifier_item_greater_tranquil_boots_sap:IsHidden()
	return true
end

function modifier_item_greater_tranquil_boots_sap:IsDebuff()
	return true
end

function modifier_item_greater_tranquil_boots_sap:IsPurgable()
	return false
end

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

modifier_greater_tranquils_trees_buff = class(ModifierBaseClass)

function modifier_greater_tranquils_trees_buff:IsHidden()
  return self:GetStackCount() ~= 0
end

function modifier_greater_tranquils_trees_buff:IsDebuff()
  return false
end

function modifier_greater_tranquils_trees_buff:IsPurgable()
  return false
end

function modifier_greater_tranquils_trees_buff:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.hp_regen_amp = ability:GetSpecialValueFor("passive_hp_regen_amp")
    self.heal_amp = ability:GetSpecialValueFor("passive_heal_amp")
    self.dmg_reduction = ability:GetSpecialValueFor("passive_damage_reduction")
    self.status_resist = ability:GetSpecialValueFor("passive_status_resistance")
  end

  if IsServer() then
    self:SetStackCount(2)
    self:StartIntervalThink(0)
  end
end

function modifier_greater_tranquils_trees_buff:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.hp_regen_amp = ability:GetSpecialValueFor("passive_hp_regen_amp")
    self.heal_amp = ability:GetSpecialValueFor("passive_heal_amp")
    self.dmg_reduction = ability:GetSpecialValueFor("passive_damage_reduction")
    self.status_resist = ability:GetSpecialValueFor("passive_status_resistance")
  end
end

function modifier_greater_tranquils_trees_buff:OnIntervalThink()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  local ability = self:GetAbility()

  if not parent or parent:IsNull() then
    return
  end

  -- Ignore illusions
  if parent:IsIllusion() then
    return
  end

  -- Ignore banished units
  if parent:IsOutOfGame() then
    self:SetStackCount(2)
    return
  end

  if not ability or ability:IsNull() then
    return
  end

  local parent_origin = parent:GetAbsOrigin()
  local tree_radius = ability:GetSpecialValueFor("passive_tree_radius")

  if GridNav:IsNearbyTree(parent_origin, tree_radius, true) then
    self:SetStackCount(0)
  else
    self:SetStackCount(2)
  end
end

function modifier_greater_tranquils_trees_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE,
    MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
  }
end

function modifier_greater_tranquils_trees_buff:GetModifierHPRegenAmplify_Percentage()
  if self:GetStackCount() == 0 then
    return self.hp_regen_amp or self:GetAbility():GetSpecialValueFor("passive_hp_regen_amp")
  end

  return 0
end

function modifier_greater_tranquils_trees_buff:GetModifierHealAmplify_PercentageSource()
  if self:GetStackCount() == 0 then
    return self.heal_amp or self:GetAbility():GetSpecialValueFor("passive_heal_amp")
  end

  return 0
end

function modifier_greater_tranquils_trees_buff:GetModifierHealAmplify_PercentageTarget()
  if self:GetStackCount() == 0 then
    return self.heal_amp or self:GetAbility():GetSpecialValueFor("passive_heal_amp")
  end

  return 0
end

function modifier_greater_tranquils_trees_buff:GetModifierIncomingDamage_Percentage(event)
  --if event.damage_type ~= DAMAGE_TYPE_PHYSICAL then
    --return 0
  --end

  if self:GetStackCount() == 0 then
    local dmg_reduction = 0-self.dmg_reduction or 0-self:GetAbility():GetSpecialValueFor("passive_damage_reduction")
    if self:GetParent():IsClone() then
      return dmg_reduction / 2
    else
      return dmg_reduction
    end
  end

  return 0
end

function modifier_greater_tranquils_trees_buff:GetModifierStatusResistanceStacking()
  if self:GetStackCount() == 0 then
    return self.status_resist or self:GetAbility():GetSpecialValueFor("passive_status_resistance")
  end

  return 0
end

---------------------------------------------------------------------------------------------------

modifier_greater_tranquils_tranquilize_debuff = class(ModifierBaseClass)

function modifier_greater_tranquils_tranquilize_debuff:IsHidden()
  return false
end

function modifier_greater_tranquils_tranquilize_debuff:IsDebuff()
  return true
end

function modifier_greater_tranquils_tranquilize_debuff:IsPurgable()
  return false
end

function modifier_greater_tranquils_tranquilize_debuff:OnCreated()
  local parent = self:GetParent()
  local ability = self:GetAbility()
  local attack_slow = -700

  if ability and not ability:IsNull() then
    attack_slow = ability:GetSpecialValueFor("attack_speed_slow")
  end
  if parent:IsOAABoss() then
    attack_slow = 0
  end

  self.attack_slow = attack_slow
end

modifier_greater_tranquils_tranquilize_debuff.OnRefresh = modifier_greater_tranquils_tranquilize_debuff.OnCreated

function modifier_greater_tranquils_tranquilize_debuff:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
  }
  return funcs
end

function modifier_greater_tranquils_tranquilize_debuff:GetModifierAttackSpeedBonus_Constant()
  return self.attack_slow
end

function modifier_greater_tranquils_tranquilize_debuff:GetModifierProvidesFOWVision()
  return 1
end

function modifier_greater_tranquils_tranquilize_debuff:GetEffectName()
  return "particles/units/heroes/hero_enchantress/enchantress_untouchable.vpcf"
end

function modifier_greater_tranquils_tranquilize_debuff:GetEffectAttachType()
  return PATTACH_OVERHEAD_FOLLOW
end

---------------------------------------------------------------------------------------------------

modifier_greater_tranquils_tranquilize_buff = class(ModifierBaseClass)

function modifier_greater_tranquils_tranquilize_buff:IsHidden()
  return false
end

function modifier_greater_tranquils_tranquilize_buff:IsDebuff()
  return false
end

function modifier_greater_tranquils_tranquilize_buff:IsPurgable()
  return false
end

function modifier_greater_tranquils_tranquilize_buff:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.hp_regen_amp = ability:GetSpecialValueFor("active_hp_regen_amp")
    self.heal_amp = ability:GetSpecialValueFor("active_heal_amp")
  end
end

modifier_greater_tranquils_tranquilize_buff.OnRefresh = modifier_greater_tranquils_tranquilize_buff.OnCreated

function modifier_greater_tranquils_tranquilize_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE,
    MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
  }
end

function modifier_greater_tranquils_tranquilize_buff:GetModifierHPRegenAmplify_Percentage()
  return self.hp_regen_amp or self:GetAbility():GetSpecialValueFor("active_hp_regen_amp")
end

function modifier_greater_tranquils_tranquilize_buff:GetModifierHealAmplify_PercentageSource()
  return self.heal_amp or self:GetAbility():GetSpecialValueFor("active_heal_amp")
end

function modifier_greater_tranquils_tranquilize_buff:GetModifierHealAmplify_PercentageTarget()
  return self.heal_amp or self:GetAbility():GetSpecialValueFor("active_heal_amp")
end

function modifier_greater_tranquils_tranquilize_buff:CheckState()
  local state = {
    [MODIFIER_STATE_ALLOW_PATHING_THROUGH_TREES] = true,
  }
  return state
end
