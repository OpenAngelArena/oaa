electrician_electric_shield = class( AbilityBaseClass )

LinkLuaModifier( "modifier_electrician_electric_shield", "abilities/electrician/electrician_electric_shield.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

function electrician_electric_shield:GetBehavior()
  local caster = self:GetCaster()
  -- Shard that makes Electric Shield toggle
  if caster:HasShardOAA() then
    return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IMMEDIATE + DOTA_ABILITY_BEHAVIOR_IGNORE_CHANNEL + DOTA_ABILITY_BEHAVIOR_TOGGLE
  end
  return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IMMEDIATE + DOTA_ABILITY_BEHAVIOR_IGNORE_CHANNEL
end

function electrician_electric_shield:GetManaCost(level)
  local caster = self:GetCaster()
  local baseCost = self.BaseClass.GetManaCost(self, level)
  local currentMana = caster:GetMana()
  local cost = baseCost

  if baseCost < currentMana then
    local fullCost = caster:GetMaxMana() * ( self:GetSpecialValueFor( "mana_cost" ) * 0.01 )

    if currentMana < fullCost then
      cost = currentMana
    else
      cost = fullCost
    end
  end

  -- GetManaCost gets called after paying the cost but before OnSpellStart occurs
  -- so we need to only track the cost the moment the spell is cast and never
  -- any other time
  if self.recordCost then
    self.usedCost = cost
    self.recordCost = false
  end

  if caster:HasShardOAA() then
    return 0
  end

  return cost
end

--------------------------------------------------------------------------------

-- this is seemingly the only thing that gets called before OnSpellStart for this kind
-- of spell, at least as far as non-hacks go
function electrician_electric_shield:CastFilterResult()
	self.recordCost = true
	return UF_SUCCESS
end

--------------------------------------------------------------------------------

function electrician_electric_shield:OnSpellStart()
  local caster = self:GetCaster()
  if caster:HasShardOAA() then
    return
  end
  local shieldHP = self.usedCost * self:GetSpecialValueFor("shield_per_mana")

  -- create the shield modifier
  caster:AddNewModifier( caster, self, "modifier_electrician_electric_shield", {
    duration = self:GetSpecialValueFor( "shield_duration" ),
    shieldHP = shieldHP,
  } )
end

function electrician_electric_shield:OnToggle()
  local caster = self:GetCaster()
  if not caster:HasShardOAA() then
    return
  end
  if self:GetToggleState() then
    caster:AddNewModifier(caster, self, "modifier_electrician_electric_shield", {
    duration = -1,
    shieldHP = -1,
  } )
  else
    caster:RemoveModifierByNameAndCaster("modifier_electrician_electric_shield", caster)
  end
end

function electrician_electric_shield:ProcMagicStick()
  local caster = self:GetCaster()
  if caster:HasShardOAA() then
    return false
  end

  return true
end

--------------------------------------------------------------------------------

modifier_electrician_electric_shield = class( ModifierBaseClass )

--------------------------------------------------------------------------------

function modifier_electrician_electric_shield:IsDebuff()
	return false
end

function modifier_electrician_electric_shield:IsHidden()
	return false
end

function modifier_electrician_electric_shield:IsPurgable()
  local parent = self:GetParent()
  if parent:HasShardOAA() then
    return false
  end

  return true
end

--------------------------------------------------------------------------------

function modifier_electrician_electric_shield:DeclareFunctions()
  local func = {
    --MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK_UNAVOIDABLE_PRE_ARMOR,
    MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
  }

  return func
end

--------------------------------------------------------------------------------

if IsServer() then
	--[[
  function modifier_electrician_electric_shield:GetModifierPhysical_ConstantBlockUnavoidablePreArmor( event )
		-- start with the maximum block amount
		local blockAmount = event.damage * self.shieldRate
		-- grab the remaining shield hp
		local hp = self:GetStackCount()

		-- don't block more than remaining hp
		blockAmount = math.min( blockAmount, hp )

		-- remove shield hp
		self:SetStackCount( hp - blockAmount )

		-- do the little block visual effect
		SendOverheadEventMessage( nil, 8, self:GetParent(), blockAmount, nil )

		-- destroy the modifier if hp is reduced to nothing
		if self:GetStackCount() <= 0 then
			self:Destroy()
		end

		return blockAmount
	end
  ]]

  function modifier_electrician_electric_shield:GetModifierTotal_ConstantBlock( event )
    -- Do nothing if damage has HP removal flag
    if bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then
      return 0
    end

    -- start with the maximum block amount
    local blockAmount = event.damage * self.shieldRate
    local parent = self:GetParent()
    if parent:HasShardOAA() then
      local ability = self:GetAbility()
      local damage_per_mana = math.max(ability:GetSpecialValueFor("shard_shield_per_mana"), ability:GetSpecialValueFor("shield_per_mana"))
      local shield_dmg_block = math.max(ability:GetSpecialValueFor("shard_shield_damage_block"), ability:GetSpecialValueFor("shield_damage_block"))
      local current_mana = parent:GetMana()
      local current_shield_hp = current_mana * damage_per_mana

      -- Calculate block amount
      blockAmount = math.min(event.damage * shield_dmg_block * 0.01, current_shield_hp)

      -- Calculate what shield hp should be after blocking
      local shield_hp_after = current_shield_hp - blockAmount

      -- Calculate what mana should be after blocking
      local mana_after = shield_hp_after / damage_per_mana

      -- Calculate how much mana should be removed
      local mana_to_remove = math.max(0, current_mana - mana_after)

      -- Remove mana
      parent:ReduceMana(mana_to_remove)
    else
      -- grab the remaining shield hp
      local hp = self:GetStackCount()

      -- don't block more than remaining hp
      blockAmount = math.min( blockAmount, hp )

      -- remove shield hp
      self:SetStackCount( hp - blockAmount )

      -- destroy the modifier if hp is reduced to nothing
      if self:GetStackCount() <= 0 then
        self:Destroy()
      end
    end

    if blockAmount > 0 then
      -- do the little block visual effect (TODO: add unique visual effect)
      SendOverheadEventMessage(nil, OVERHEAD_ALERT_BLOCK, parent, blockAmount, nil)
    end

    return blockAmount
  end

--------------------------------------------------------------------------------

  function modifier_electrician_electric_shield:OnCreated(event)
    local parent = self:GetParent()
    local spell = self:GetAbility()
    local caster = self:GetCaster()

    if not caster:HasShardOAA() and event.shieldHP ~= -1 then
      self:SetStackCount(event.shieldHP)
    end

    -- grab ability specials
    local damageInterval = spell:GetSpecialValueFor("aura_interval")
    local damage_per_second = spell:GetSpecialValueFor("aura_damage")
    -- Bonus damage talent
    local talent = caster:FindAbilityByName("special_bonus_electrician_electric_shield_damage")
    if talent and talent:GetLevel() > 0 then
      damage_per_second = damage_per_second + talent:GetSpecialValueFor("value")
    end
    self.shieldRate = spell:GetSpecialValueFor("shield_damage_block") * 0.01
    self.damageRadius =  spell:GetSpecialValueFor("aura_radius")
    self.damagePerInterval = damage_per_second * damageInterval
    self.damageType = spell:GetAbilityDamageType()

    -- create the shield particles
    self.partShield = ParticleManager:CreateParticle( "particles/hero/electrician/electrician_electric_shield.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControlEnt(self.partShield, 1, parent, PATTACH_ABSORIGIN_FOLLOW, nil, parent:GetAbsOrigin(), true)

    -- play sound
    parent:EmitSound( "Ability.static.start" )

    -- cast animation (needs FadeGesture some time after)
    --caster:StartGesture(ACT_DOTA_CAST_ABILITY_2)

    -- start thinking
    self:StartIntervalThink(damageInterval)
  end

--------------------------------------------------------------------------------

  function modifier_electrician_electric_shield:OnRefresh(event)
    -- destroy the shield particles
    if self.partShield then
      ParticleManager:DestroyParticle(self.partShield, false)
      ParticleManager:ReleaseParticleIndex(self.partShield)
    end

    self:OnCreated(event)
  end

--------------------------------------------------------------------------------

  function modifier_electrician_electric_shield:OnDestroy()
    -- destroy the shield particles
    if self.partShield then
      ParticleManager:DestroyParticle(self.partShield, false)
      ParticleManager:ReleaseParticleIndex(self.partShield)
    end
    -- play end sound
    self:GetParent():EmitSound("Hero_Razor.StormEnd")
  end

--------------------------------------------------------------------------------

	function modifier_electrician_electric_shield:OnIntervalThink()
		local parent = self:GetParent()
		local caster = self:GetCaster()
		local spell = self:GetAbility()
		local parentOrigin = parent:GetAbsOrigin()

		local units = FindUnitsInRadius(
			parent:GetTeamNumber(),
			parentOrigin,
			nil,
			self.damageRadius,
			spell:GetAbilityTargetTeam(),
			spell:GetAbilityTargetType(),
			DOTA_UNIT_TARGET_FLAG_NONE,
			FIND_ANY_ORDER,
			false
		)

		for _, target in pairs( units ) do
			ApplyDamage( {
				victim = target,
				attacker = caster,
				damage = self.damagePerInterval,
				damage_type = self.damageType,
				damage_flags = DOTA_DAMAGE_FLAG_NONE,
				ability = spell,
			} )

      -- old particle
      --local part = ParticleManager:CreateParticle( "particles/units/heroes/hero_zuus/zuus_arc_lightning.vpcf", PATTACH_POINT_FOLLOW, parent)
      -- new particle
      local part = ParticleManager:CreateParticle("particles/items_fx/chain_lightning.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
      ParticleManager:SetParticleControlEnt(part, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
      ParticleManager:SetParticleControlEnt(part, 1, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parentOrigin, true)
      ParticleManager:ReleaseParticleIndex(part)

			target:EmitSound( "Hero_razor.lightning" )
		end
	end
end
