item_greater_tranquil_boots = class(ItemBaseClass)

LinkLuaModifier( "modifier_item_greater_tranquil_boots_passive", "items/farming/greater_tranquil_boots.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_greater_tranquils_trees_buff", "items/farming/greater_tranquil_boots.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_greater_tranquils_tranquilize_debuff", "items/farming/greater_tranquil_boots.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_greater_tranquils_bearing_buff", "items/farming/greater_tranquil_boots.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_greater_tranquils_bearing_unslowable", "items/farming/greater_tranquil_boots.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_greater_tranquils_endurance_aura_effect", "items/farming/greater_tranquil_boots.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_greater_tranquils_trees_dummy_stuff", "items/farming/greater_tranquil_boots.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

function item_greater_tranquil_boots:GetIntrinsicModifierName()
	return "modifier_intrinsic_multiplexer"
end

function item_greater_tranquil_boots:GetIntrinsicModifierNames()
  return {
    "modifier_item_greater_tranquil_boots_passive",
    "modifier_greater_tranquils_trees_buff"
  }
end

--function item_greater_tranquil_boots:ShouldUseResources()
  --return true
--end

function item_greater_tranquil_boots:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()

  -- Disable working on Meepo Clones
  if caster:IsClone() then
    self:RefundManaCost()
    self:EndCooldown()
    return
  end

  local bearing_duration = self:GetSpecialValueFor("bearing_duration")
  local tree_buff_duration = self:GetSpecialValueFor("tree_protection_duration")
  local unslowable_duration = self:GetSpecialValueFor("bearing_unslowable_duration")

  -- Sound
  caster:EmitSound("DOTA_Item.DoE.Activate")

  -- Apply Boots of Bearing / Drums of Endurance buff (with Tree-walking) to all allies in the area
  local allies = FindUnitsInRadius(
    caster:GetTeamNumber(),
    caster:GetAbsOrigin(),
    nil,
    self:GetSpecialValueFor("bearing_radius"),
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  for _, ally in pairs(allies) do
    if ally and not ally:IsNull() then
      -- Apply Boots of Bearing / Drums of Endurance buff (with Tree-walking) to the ally
      ally:AddNewModifier(caster, self, "modifier_greater_tranquils_bearing_buff", {duration = bearing_duration})

      -- Apply Boots of Bearing unslowable buff to the ally
      ally:AddNewModifier(caster, self, "modifier_greater_tranquils_bearing_unslowable", {duration = unslowable_duration})
    end
  end

  if target:GetTeamNumber() == caster:GetTeamNumber() then
    if target ~= caster then
      -- Apply Tree Protection buff to the ally (don't apply when self-cast because the caster already has it)
      target:AddNewModifier(caster, self, "modifier_greater_tranquils_trees_buff", {duration = tree_buff_duration})
    end

    -- Create trees around the target
    self:Sprout(target)
  else

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
end

function item_greater_tranquil_boots:Sprout(target)
  local caster = self:GetCaster()
  local duration = self:GetSpecialValueFor("sprout_duration")
  local target_loc = target:GetAbsOrigin()
  local team = caster:GetTeamNumber()

  -- Vision
  local vision_radius
  if target:GetTeamNumber() == team then
    -- same vision as the target
    vision_radius = math.min(target:GetCurrentVisionRange(), 900)
  else
    vision_radius = self:GetSpecialValueFor("sprout_vision_range")
  end

  -- Create an invisible dummy/thinker
  local dummy = CreateUnitByName("npc_dota_custom_dummy_unit", target_loc, false, caster, caster, team)
  dummy:AddNewModifier(caster, self, "modifier_oaa_thinker", {})
  dummy:AddNewModifier(caster, self, "modifier_greater_tranquils_trees_dummy_stuff", {radius = vision_radius})
  dummy:AddNewModifier(caster, self, "modifier_kill", {duration = duration})
  dummy:AddNewModifier(caster, self, "modifier_generic_dead_tracker_oaa", {duration = duration + MANUAL_GARBAGE_CLEANING_TIME})

  --self:CreateVisibilityNode(target_loc, vision_radius, duration)

  local r = 150
  local c = math.sqrt(2) * 0.5 * r
  local x_offset = { -r, -c, 0.0, c, r, c, 0.0, -c }
  local y_offset = { 0.0, c, r, c, 0.0, -c, -r, -c }

  local nFXIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_furion/furion_sprout.vpcf", PATTACH_CUSTOMORIGIN, caster)
  ParticleManager:SetParticleControl(nFXIndex, 0, target_loc)
  ParticleManager:SetParticleControl(nFXIndex, 1, Vector(0.0, r, 0.0))
  ParticleManager:ReleaseParticleIndex(nFXIndex)

  -- Create trees
  for i = 1, 8 do
    CreateTempTree(target_loc + Vector(x_offset[i], y_offset[i], 0.0), duration)
  end

  -- Unstuck entities
  for i = 1, 8 do
    ResolveNPCPositions(target_loc + Vector(x_offset[i], y_offset[i], 0.0), 64.0)
  end

  -- Sound
  EmitSoundOnLocationWithCaster(target_loc, "Hero_Furion.Sprout", caster)
end

function item_greater_tranquil_boots:OnProjectileHit(target, location)
  local caster = self:GetCaster()

  if not target or target:IsNull() then
    return
  end

  -- Don't do anything if target has Linken's effect or it's spell-immune
  if target:TriggerSpellAbsorb(self) or target:IsMagicImmune() then
    return
  end

  local debuff_duration = self:GetSpecialValueFor("tranquilize_slow_duration")
  -- Ignore status resistance
  target:AddNewModifier(caster, self, "modifier_greater_tranquils_tranquilize_debuff", {duration = debuff_duration})

  self:Sprout(target)
end

function item_greater_tranquil_boots:IsBreakable()
  local break_time = self:GetSpecialValueFor("break_time")
  return break_time and break_time > 0
end

item_greater_tranquil_boots_2 = item_greater_tranquil_boots
item_greater_tranquil_boots_3 = item_greater_tranquil_boots
item_greater_tranquil_boots_4 = item_greater_tranquil_boots

---------------------------------------------------------------------------------------------------

modifier_item_greater_tranquil_boots_passive = class(ModifierBaseClass)

function modifier_item_greater_tranquil_boots_passive:IsHidden()
  return true
end

function modifier_item_greater_tranquil_boots_passive:IsDebuff()
  return false
end

function modifier_item_greater_tranquil_boots_passive:IsPurgable()
  return false
end

-- We don't have this on purpose because we don't want people to buy multiple of these
--function modifier_item_greater_tranquil_boots_passive:GetAttributes()
  --return MODIFIER_ATTRIBUTE_MULTIPLE
--end

function modifier_item_greater_tranquil_boots_passive:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.moveSpd = ability:GetSpecialValueFor("bonus_movement_speed")
    self.hp_regen = ability:GetSpecialValueFor("bonus_health_regen")
    self.str = ability:GetSpecialValueFor("bonus_str")
    self.int = ability:GetSpecialValueFor("bonus_int")
    self.aura_radius = ability:GetSpecialValueFor("aura_radius")
  end
end

modifier_item_greater_tranquil_boots_passive.OnRefresh = modifier_item_greater_tranquil_boots_passive.OnCreated

function modifier_item_greater_tranquil_boots_passive:IsAura()
  return true
end

function modifier_item_greater_tranquil_boots_passive:GetAuraRadius()
  return self.aura_radius or self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_item_greater_tranquil_boots_passive:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_item_greater_tranquil_boots_passive:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
end

function modifier_item_greater_tranquil_boots_passive:GetModifierAura()
  return "modifier_greater_tranquils_endurance_aura_effect"
end

function modifier_item_greater_tranquil_boots_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_UNIQUE,
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    --MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

function modifier_item_greater_tranquil_boots_passive:GetModifierMoveSpeedBonus_Special_Boots()
  return self.moveSpd or self:GetAbility():GetSpecialValueFor("bonus_movement_speed")
end

function modifier_item_greater_tranquil_boots_passive:GetModifierConstantHealthRegen()
  return self.hp_regen or self:GetAbility():GetSpecialValueFor("bonus_health_regen")
end

function modifier_item_greater_tranquil_boots_passive:GetModifierBonusStats_Strength()
  if self:GetParent():IsClone() then
    return 0
  end
  return self.str or self:GetAbility():GetSpecialValueFor("bonus_str")
end

function modifier_item_greater_tranquil_boots_passive:GetModifierBonusStats_Intellect()
  if self:GetParent():IsClone() then
    return 0
  end
  return self.int or self:GetAbility():GetSpecialValueFor("bonus_int")
end

-- if IsServer() then
  -- function modifier_item_greater_tranquil_boots_passive:OnAttackLanded( event )
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
        -- spell:UseResources(true, false, false, true)
        -- local cdRemaining = spell:GetCooldownTimeRemaining()
        -- if cdRemaining > 0 then
          -- parent:AddNewModifier(parent, spell, "modifier_greater_tranquils_broken_debuff", {duration = cdRemaining})
        -- end
      -- end
    -- end
	-- end
-- end

function modifier_item_greater_tranquil_boots_passive:CheckState()
  return {
    [MODIFIER_STATE_ALLOW_PATHING_THROUGH_TREES] = true,
  }
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
  self:OnRefresh()
  if IsServer() then
    self:SetStackCount(2)
    self:StartIntervalThink(0)
  end
end

function modifier_greater_tranquils_trees_buff:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.hp_regen_amp = ability:GetSpecialValueFor("tree_hp_regen_amp")
    self.dmg_reduction = ability:GetSpecialValueFor("tree_damage_reduction")
    self.status_resist = ability:GetSpecialValueFor("tree_status_resistance")
  end
end

if IsServer() then
  function modifier_greater_tranquils_trees_buff:OnIntervalThink()
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
    local tree_radius = ability:GetSpecialValueFor("tree_radius")

    if GridNav:IsNearbyTree(parent_origin, tree_radius, true) then
      self:SetStackCount(0)
    else
      self:SetStackCount(2)
    end
  end
end

function modifier_greater_tranquils_trees_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
  }
end

function modifier_greater_tranquils_trees_buff:GetModifierHPRegenAmplify_Percentage()
  if self:GetStackCount() == 0 then
    return self.hp_regen_amp or self:GetAbility():GetSpecialValueFor("tree_hp_regen_amp")
  end

  return 0
end

if IsServer() then
  function modifier_greater_tranquils_trees_buff:GetModifierIncomingDamage_Percentage(event)
    --if event.damage_type ~= DAMAGE_TYPE_PHYSICAL then
      --return 0
    --end
    local ability = self:GetAbility()
    if self:GetStackCount() == 0 then
      local dmg_reduction = 0
      if self.dmg_reduction then
        dmg_reduction = 0 - self.dmg_reduction
      elseif ability and not ability:IsNull() then
        dmg_reduction = 0 - ability:GetSpecialValueFor("tree_damage_reduction")
      end
      if self:GetParent():IsClone() then
        return dmg_reduction / 2
      else
        return dmg_reduction
      end
    end

    return 0
  end
end

function modifier_greater_tranquils_trees_buff:GetModifierStatusResistanceStacking()
  if self:GetStackCount() == 0 then
    return self.status_resist or self:GetAbility():GetSpecialValueFor("tree_status_resistance")
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
    attack_slow = ability:GetSpecialValueFor("tranquilize_attack_speed_slow")
  end
  if parent:IsOAABoss() then
    attack_slow = 0
  end

  self.attack_slow = attack_slow
end

modifier_greater_tranquils_tranquilize_debuff.OnRefresh = modifier_greater_tranquils_tranquilize_debuff.OnCreated

function modifier_greater_tranquils_tranquilize_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    --MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
  }
end

function modifier_greater_tranquils_tranquilize_debuff:GetModifierAttackSpeedBonus_Constant()
  return self.attack_slow
end

--function modifier_greater_tranquils_tranquilize_debuff:GetModifierProvidesFOWVision()
  --return 1
--end

function modifier_greater_tranquils_tranquilize_debuff:GetEffectName()
  return "particles/units/heroes/hero_enchantress/enchantress_untouchable.vpcf"
end

function modifier_greater_tranquils_tranquilize_debuff:GetEffectAttachType()
  return PATTACH_OVERHEAD_FOLLOW
end

function modifier_greater_tranquils_tranquilize_debuff:GetTexture()
  return "custom/greater_tranquils_4"
end

---------------------------------------------------------------------------------------------------

modifier_greater_tranquils_bearing_buff = class(ModifierBaseClass)

function modifier_greater_tranquils_bearing_buff:IsHidden()
  return false
end

function modifier_greater_tranquils_bearing_buff:IsDebuff()
  return false
end

function modifier_greater_tranquils_bearing_buff:IsPurgable()
  return true
end

function modifier_greater_tranquils_bearing_buff:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.move_speed = ability:GetSpecialValueFor("bearing_movement_speed_pct")
    self.attack_speed = ability:GetSpecialValueFor("bearing_attack_speed")
  end

  if IsServer() then
    if self.particle == nil then
      local parent = self:GetParent()
      -- Particle
      local particle_name = "particles/items_fx/drum_of_endurance_buff.vpcf"
      self.particle = ParticleManager:CreateParticle(particle_name, PATTACH_ABSORIGIN_FOLLOW, parent)
      ParticleManager:SetParticleControl(self.particle, 0, parent:GetAbsOrigin())
      ParticleManager:SetParticleControl(self.particle, 1, Vector(0,0,0))
    end

    self:StartIntervalThink(0.1)
  end
end

function modifier_greater_tranquils_bearing_buff:OnRefresh()
  if IsServer() and self.particle then
    ParticleManager:DestroyParticle(self.particle, true)
    ParticleManager:ReleaseParticleIndex(self.particle)
    self.particle = nil
  end

  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.move_speed = ability:GetSpecialValueFor("bearing_movement_speed_pct")
    self.attack_speed = ability:GetSpecialValueFor("bearing_attack_speed")
  end

  if IsServer() and self.particle == nil then
    local parent = self:GetParent()
    -- Particle
    local particle_name = "particles/items_fx/drum_of_endurance_buff.vpcf"
    self.particle = ParticleManager:CreateParticle(particle_name, PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControl(self.particle, 0, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.particle, 1, Vector(0,0,0))
  end
end

function modifier_greater_tranquils_bearing_buff:OnIntervalThink()
  local parent = self:GetParent()
  if parent and not parent:IsNull() then
    parent:RemoveModifierByName("modifier_item_boots_of_bearing_active")
    parent:RemoveModifierByName("modifier_item_ancient_janggo_active")
  end
end

function modifier_greater_tranquils_bearing_buff:OnDestroy()
  if IsServer() and self.particle then
    ParticleManager:DestroyParticle(self.particle, false)
    ParticleManager:ReleaseParticleIndex(self.particle)
    self.particle = nil
  end
end

function modifier_greater_tranquils_bearing_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
  }
end

function modifier_greater_tranquils_bearing_buff:GetModifierMoveSpeedBonus_Percentage()
  return self.move_speed or self:GetAbility():GetSpecialValueFor("bearing_movement_speed_pct")
end

function modifier_greater_tranquils_bearing_buff:GetModifierAttackSpeedBonus_Constant()
  return self.attack_speed or self:GetAbility():GetSpecialValueFor("bearing_attack_speed")
end

function modifier_greater_tranquils_bearing_buff:CheckState()
  return {
    [MODIFIER_STATE_ALLOW_PATHING_THROUGH_TREES] = true,
  }
end

function modifier_greater_tranquils_bearing_buff:GetTexture()
  return "custom/greater_tranquils_4" -- "item_boots_of_bearing"
end

---------------------------------------------------------------------------------------------------

modifier_greater_tranquils_endurance_aura_effect = class(ModifierBaseClass)

function modifier_greater_tranquils_endurance_aura_effect:IsHidden()
  local parent = self:GetParent()
  return parent:HasModifier("modifier_item_boots_of_bearing_aura") or parent:HasModifier("modifier_item_ancient_janggo_aura")
end

function modifier_greater_tranquils_endurance_aura_effect:IsDebuff()
  return false
end

function modifier_greater_tranquils_endurance_aura_effect:IsPurgable()
  return false
end

function modifier_greater_tranquils_endurance_aura_effect:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.move_speed = ability:GetSpecialValueFor("aura_movement_speed")
  end
end

modifier_greater_tranquils_endurance_aura_effect.OnRefresh = modifier_greater_tranquils_endurance_aura_effect.OnCreated

function modifier_greater_tranquils_endurance_aura_effect:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
  }
end

function modifier_greater_tranquils_endurance_aura_effect:GetModifierMoveSpeedBonus_Constant()
  local parent = self:GetParent()
  if parent:HasModifier("modifier_item_boots_of_bearing_aura") or parent:HasModifier("modifier_item_ancient_janggo_aura") then
    return 0
  end
  return self.move_speed or self:GetAbility():GetSpecialValueFor("aura_movement_speed")
end

function modifier_greater_tranquils_endurance_aura_effect:GetTexture()
  return "item_boots_of_bearing"
end

---------------------------------------------------------------------------------------------------

modifier_greater_tranquils_trees_dummy_stuff = class(ModifierBaseClass)

function modifier_greater_tranquils_trees_dummy_stuff:IsHidden()
  return true
end

function modifier_greater_tranquils_trees_dummy_stuff:IsDebuff()
  return false
end

function modifier_greater_tranquils_trees_dummy_stuff:IsPurgable()
  return false
end

function modifier_greater_tranquils_trees_dummy_stuff:OnCreated(kv)
  if IsServer() then
    local radius = kv.radius
    if radius then
      self:SetStackCount(radius)
    end
  end
end

function modifier_greater_tranquils_trees_dummy_stuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_BONUS_DAY_VISION,
    MODIFIER_PROPERTY_BONUS_NIGHT_VISION,
  }
end

function modifier_greater_tranquils_trees_dummy_stuff:GetBonusDayVision()
  return self:GetStackCount()
end

function modifier_greater_tranquils_trees_dummy_stuff:GetBonusNightVision()
  return self:GetStackCount()
end

function modifier_greater_tranquils_trees_dummy_stuff:CheckState()
  return {
    [MODIFIER_STATE_FLYING] = true,
  }
end

---------------------------------------------------------------------------------------------------

modifier_greater_tranquils_bearing_unslowable = class(ModifierBaseClass)

function modifier_greater_tranquils_bearing_unslowable:IsHidden()
  return false
end

function modifier_greater_tranquils_bearing_unslowable:IsDebuff()
  return false
end

function modifier_greater_tranquils_bearing_unslowable:IsPurgable()
  return true
end

function modifier_greater_tranquils_bearing_unslowable:GetPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA + 10000
end

function modifier_greater_tranquils_bearing_unslowable:CheckState()
  return {
    [MODIFIER_STATE_UNSLOWABLE] = true,
  }
end

function modifier_greater_tranquils_bearing_unslowable:GetTexture()
  return "item_boots_of_bearing"
end
