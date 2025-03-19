item_greater_boots_of_bearing_1 = class(ItemBaseClass)

LinkLuaModifier( "modifier_item_greater_boots_of_bearing_passive", "items/greater_boots_of_bearing.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_greater_boots_of_bearing_buff", "items/greater_boots_of_bearing.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_greater_boots_of_bearing_unslowable", "items/greater_boots_of_bearing.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_greater_boots_of_bearing_endurance_aura_effect", "items/greater_boots_of_bearing.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

function item_greater_boots_of_bearing_1:GetIntrinsicModifierName()
  return "modifier_item_greater_boots_of_bearing_passive"
end

function item_greater_boots_of_bearing_1:OnSpellStart()
  local caster = self:GetCaster()

  -- Disable working on Meepo Clones
  if caster:IsClone() then
    self:RefundManaCost()
    self:EndCooldown()
    return
  end

  local bearing_duration = self:GetSpecialValueFor("bearing_duration")
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
      ally:AddNewModifier(caster, self, "modifier_item_greater_boots_of_bearing_buff", {duration = bearing_duration})

      -- Apply Boots of Bearing unslowable buff to the ally
      ally:AddNewModifier(caster, self, "modifier_item_greater_boots_of_bearing_unslowable", {duration = unslowable_duration})
    end
  end
end

item_greater_boots_of_bearing_2 = item_greater_boots_of_bearing_1
item_greater_boots_of_bearing_3 = item_greater_boots_of_bearing_1
item_greater_boots_of_bearing_4 = item_greater_boots_of_bearing_1

---------------------------------------------------------------------------------------------------

modifier_item_greater_boots_of_bearing_passive = class(ModifierBaseClass)

function modifier_item_greater_boots_of_bearing_passive:IsHidden()
  return true
end

function modifier_item_greater_boots_of_bearing_passive:IsDebuff()
  return false
end

function modifier_item_greater_boots_of_bearing_passive:IsPurgable()
  return false
end

-- We don't have this on purpose because we don't want people to buy multiple of these
--function modifier_item_greater_boots_of_bearing_passive:GetAttributes()
  --return MODIFIER_ATTRIBUTE_MULTIPLE
--end

function modifier_item_greater_boots_of_bearing_passive:OnCreated()
  self:OnRefresh()
  if IsServer() then
    self:StartIntervalThink(0.1)

    local parent = self:GetParent()

    -- Remove aura effect modifier from units in radius to force refresh
    local units = FindUnitsInRadius(
      parent:GetTeamNumber(),
      parent:GetAbsOrigin(),
      nil,
      self:GetAuraRadius(),
      self:GetAuraSearchTeam(),
      self:GetAuraSearchType(),
      DOTA_UNIT_TARGET_FLAG_NONE,
      FIND_ANY_ORDER,
      false
    )

    local function RemoveAuraEffect(unit)
      unit:RemoveModifierByName(self:GetModifierAura())
    end

    foreach(RemoveAuraEffect, units)
  end
end

function modifier_item_greater_boots_of_bearing_passive:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_ms = ability:GetSpecialValueFor("bonus_movement_speed")
    self.bonus_hp_regen = ability:GetSpecialValueFor("bonus_health_regen")
    self.bonus_str = ability:GetSpecialValueFor("bonus_str")
    self.bonus_int = ability:GetSpecialValueFor("bonus_int")
    self.aura_radius = ability:GetSpecialValueFor("aura_radius")
  end
end

if IsServer() then
  function modifier_item_greater_boots_of_bearing_passive:OnIntervalThink()
    local parent = self:GetParent()

    if not parent or parent:IsNull() then
      self:StartIntervalThink(-1)
      return
    end

    -- Ignore Meepo clones
    if parent:IsClone() then
      self:StartIntervalThink(-1) -- dynamic clones still don't exist, so we can stop thinking
      self:SetStackCount(3) -- don't grant strength and intelligence
      return
    end
  end
end

function modifier_item_greater_boots_of_bearing_passive:IsAura()
  return true
end

function modifier_item_greater_boots_of_bearing_passive:GetAuraRadius()
  return self.aura_radius or self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_item_greater_boots_of_bearing_passive:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_item_greater_boots_of_bearing_passive:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
end

function modifier_item_greater_boots_of_bearing_passive:GetModifierAura()
  return "modifier_item_greater_boots_of_bearing_endurance_aura_effect"
end

function modifier_item_greater_boots_of_bearing_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_UNIQUE,
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
  }
end

function modifier_item_greater_boots_of_bearing_passive:GetModifierMoveSpeedBonus_Special_Boots()
  return self.bonus_ms or self:GetAbility():GetSpecialValueFor("bonus_movement_speed")
end

function modifier_item_greater_boots_of_bearing_passive:GetModifierConstantHealthRegen()
  return self.bonus_hp_regen or self:GetAbility():GetSpecialValueFor("bonus_health_regen")
end

function modifier_item_greater_boots_of_bearing_passive:GetModifierBonusStats_Strength()
  if self:GetStackCount() == 3 then
    return 0
  end
  return self.bonus_str or self:GetAbility():GetSpecialValueFor("bonus_str")
end

function modifier_item_greater_boots_of_bearing_passive:GetModifierBonusStats_Intellect()
  if self:GetStackCount() == 3 then
    return 0
  end
  return self.bonus_int or self:GetAbility():GetSpecialValueFor("bonus_int")
end

-- if IsServer() then
  -- function modifier_item_greater_boots_of_bearing_passive:OnAttackLanded( event )
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

---------------------------------------------------------------------------------------------------
--[[ Old Tranquils effect
LinkLuaModifier( "modifier_item_greater_boots_of_bearing_sap", "items/greater_boots_of_bearing.lua", LUA_MODIFIER_MOTION_NONE )

modifier_item_greater_boots_of_bearing_sap = class(ModifierBaseClass)

function modifier_item_greater_boots_of_bearing_sap:IsHidden()
	return true
end

function modifier_item_greater_boots_of_bearing_sap:IsDebuff()
	return true
end

function modifier_item_greater_boots_of_bearing_sap:IsPurgable()
	return false
end

if IsServer() then
	function modifier_item_greater_boots_of_bearing_sap:OnCreated( event )
		local spell = self:GetAbility()

		self.sapDamage = spell:GetSpecialValueFor( "creep_sap_damage" )

		self:StartIntervalThink( 1.0 )
	end

--------------------------------------------------------------------------------

	function modifier_item_greater_boots_of_bearing_sap:OnRefresh( event )
		local spell = self:GetAbility()

		self.sapDamage = spell:GetSpecialValueFor( "creep_sap_damage" )
	end

--------------------------------------------------------------------------------

	function modifier_item_greater_boots_of_bearing_sap:OnIntervalThink()
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

modifier_item_greater_boots_of_bearing_buff = class(ModifierBaseClass)

function modifier_item_greater_boots_of_bearing_buff:IsHidden()
  return false
end

function modifier_item_greater_boots_of_bearing_buff:IsDebuff()
  return false
end

function modifier_item_greater_boots_of_bearing_buff:IsPurgable()
  return true
end

function modifier_item_greater_boots_of_bearing_buff:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.move_speed = ability:GetSpecialValueFor("bearing_movement_speed_pct")
    self.attack_speed = ability:GetSpecialValueFor("bearing_attack_speed")
  end

  if IsServer() then
    --if self.particle == nil then
      --local parent = self:GetParent()
      -- Particle
      --local particle_name = "particles/items_fx/drum_of_endurance_buff.vpcf"
      --self.particle = ParticleManager:CreateParticle(particle_name, PATTACH_ABSORIGIN_FOLLOW, parent)
      --ParticleManager:SetParticleControl(self.particle, 0, parent:GetAbsOrigin())
      --ParticleManager:SetParticleControl(self.particle, 1, Vector(0,0,0))
    --end

    self:StartIntervalThink(0.1)
  end
end

function modifier_item_greater_boots_of_bearing_buff:OnRefresh()
  --if IsServer() and self.particle then
    --ParticleManager:DestroyParticle(self.particle, true)
    --ParticleManager:ReleaseParticleIndex(self.particle)
    --self.particle = nil
  --end

  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.move_speed = ability:GetSpecialValueFor("bearing_movement_speed_pct")
    self.attack_speed = ability:GetSpecialValueFor("bearing_attack_speed")
  end

  --if IsServer() and self.particle == nil then
    --local parent = self:GetParent()
    -- Particle
    --local particle_name = "particles/items_fx/drum_of_endurance_buff.vpcf"
    --self.particle = ParticleManager:CreateParticle(particle_name, PATTACH_ABSORIGIN_FOLLOW, parent)
    --ParticleManager:SetParticleControl(self.particle, 0, parent:GetAbsOrigin())
    --ParticleManager:SetParticleControl(self.particle, 1, Vector(0,0,0))
  --end
end

function modifier_item_greater_boots_of_bearing_buff:OnIntervalThink()
  local parent = self:GetParent()
  if parent and not parent:IsNull() then
    parent:RemoveModifierByName("modifier_item_boots_of_bearing_active")
    parent:RemoveModifierByName("modifier_item_ancient_janggo_active")
  end
end

--function modifier_item_greater_boots_of_bearing_buff:OnDestroy()
  --if IsServer() and self.particle then
    --ParticleManager:DestroyParticle(self.particle, false)
    --ParticleManager:ReleaseParticleIndex(self.particle)
    --self.particle = nil
  --end
--end

function modifier_item_greater_boots_of_bearing_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
  }
end

function modifier_item_greater_boots_of_bearing_buff:GetModifierMoveSpeedBonus_Percentage()
  return self.move_speed or self:GetAbility():GetSpecialValueFor("bearing_movement_speed_pct")
end

function modifier_item_greater_boots_of_bearing_buff:GetModifierAttackSpeedBonus_Constant()
  return self.attack_speed or self:GetAbility():GetSpecialValueFor("bearing_attack_speed")
end

---------------------------------------------------------------------------------------------------

modifier_item_greater_boots_of_bearing_endurance_aura_effect = class({})

function modifier_item_greater_boots_of_bearing_endurance_aura_effect:IsHidden()
  local parent = self:GetParent()
  return parent:HasModifier("modifier_item_boots_of_bearing_aura") or parent:HasModifier("modifier_item_ancient_janggo_aura")
end

function modifier_item_greater_boots_of_bearing_endurance_aura_effect:IsDebuff()
  return false
end

function modifier_item_greater_boots_of_bearing_endurance_aura_effect:IsPurgable()
  return false
end

function modifier_item_greater_boots_of_bearing_endurance_aura_effect:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.move_speed = ability:GetSpecialValueFor("aura_movement_speed")
  end
end

modifier_item_greater_boots_of_bearing_endurance_aura_effect.OnRefresh = modifier_item_greater_boots_of_bearing_endurance_aura_effect.OnCreated

function modifier_item_greater_boots_of_bearing_endurance_aura_effect:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
  }
end

function modifier_item_greater_boots_of_bearing_endurance_aura_effect:GetModifierMoveSpeedBonus_Constant()
  local parent = self:GetParent()
  if parent:HasModifier("modifier_item_boots_of_bearing_aura") or parent:HasModifier("modifier_item_ancient_janggo_aura") then
    return 0
  end
  return self.move_speed or self:GetAbility():GetSpecialValueFor("aura_movement_speed")
end

function modifier_item_greater_boots_of_bearing_endurance_aura_effect:GetTexture()
  return "item_boots_of_bearing"
end

---------------------------------------------------------------------------------------------------

modifier_item_greater_boots_of_bearing_unslowable = class(ModifierBaseClass)

function modifier_item_greater_boots_of_bearing_unslowable:IsHidden()
  return false
end

function modifier_item_greater_boots_of_bearing_unslowable:IsDebuff()
  return false
end

function modifier_item_greater_boots_of_bearing_unslowable:IsPurgable()
  return true
end

function modifier_item_greater_boots_of_bearing_unslowable:GetPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA + 10000
end

function modifier_item_greater_boots_of_bearing_unslowable:CheckState()
  return {
    [MODIFIER_STATE_UNSLOWABLE] = true,
  }
end

function modifier_item_greater_boots_of_bearing_unslowable:GetTexture()
  return "item_boots_of_bearing"
end
