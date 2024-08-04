electrician_electric_shield = class( AbilityBaseClass )

LinkLuaModifier( "modifier_electrician_electric_shield", "abilities/electrician/electrician_electric_shield.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_electrician_electric_shield_auto_caster", "abilities/electrician/electrician_electric_shield.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

function electrician_electric_shield:GetIntrinsicModifierName()
  local isToggleable = self:GetSpecialValueFor("is_toggleable") > 0
  if isToggleable then
    return "modifier_electrician_electric_shield_auto_caster"
  end
end

function electrician_electric_shield:GetBehavior()
  local isToggleable = self:GetSpecialValueFor("is_toggleable") > 0

  -- Shard that makes Electric Shield toggle
  if isToggleable then
    return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IMMEDIATE + DOTA_ABILITY_BEHAVIOR_IGNORE_CHANNEL + DOTA_ABILITY_BEHAVIOR_AUTOCAST
  end
  return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IMMEDIATE + DOTA_ABILITY_BEHAVIOR_IGNORE_CHANNEL
end

function electrician_electric_shield:GetManaCost(level)
  local caster = self:GetCaster()
  local baseCost = self.BaseClass.GetManaCost(self, level)
  local currentMana = caster:GetMana()
  local cost = baseCost

  if currentMana > baseCost then
    local fullCost = caster:GetMaxMana() * ( self:GetSpecialValueFor( "mana_cost" ) * 0.01 )

    cost = math.min(currentMana, fullCost)
  end

  -- GetManaCost gets called after paying the cost but before OnSpellStart occurs
  -- so we need to only track the cost the moment the spell is cast and never
  -- any other time
  if self.recordCost then
    self.usedCost = cost
    self.recordCost = false
  end

  return cost
end

-- function electrician_electric_shield:GetCooldown(level)
--   return self:GetSpecialValueFor("AbilityCooldown")
-- end

--------------------------------------------------------------------------------

-- this is seemingly the only thing that gets called before OnSpellStart for this kind
-- of spell, at least as far as non-hacks go
function electrician_electric_shield:CastFilterResult()
  local caster = self:GetCaster()

  -- currently being nullified / demonically purged
  if caster:HasModifier("modifier_item_nullifier_mute") or caster:HasModifier("modifier_shadow_demon_purge_slow") then
    return UF_FAIL_CUSTOM
  end

	self.recordCost = true
	return UF_SUCCESS
end

function electrician_electric_shield:GetCustomCastError()
  return "#electrician_cannot_activate_shield_while_nullified"
end


--------------------------------------------------------------------------------

function electrician_electric_shield:OnSpellStart()
  local caster = self:GetCaster()
  local shieldHP = self.usedCost * self:GetSpecialValueFor("shield_per_mana")

  local shield = caster:FindModifierByName("modifier_electrician_electric_shield")
  if shield and not shield:IsNull() then
    -- remove old shield first
    shield:Destroy()
  end

  -- create the shield modifier
  caster:AddNewModifier( caster, self, "modifier_electrician_electric_shield", {
    duration = self:GetSpecialValueFor( "shield_duration" ),
    shieldHP = shieldHP,
  } )
end

function electrician_electric_shield:ProcMagicStick()
  return true
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

modifier_electrician_electric_shield_auto_caster = class( ModifierBaseClass )

--------------------------------------------------------------------------------

function modifier_electrician_electric_shield_auto_caster:IsDebuff()
  return false
end

function modifier_electrician_electric_shield_auto_caster:IsHidden()
  return true
end

function modifier_electrician_electric_shield_auto_caster:IsPurgable()
  return false
end

function modifier_electrician_electric_shield_auto_caster:OnCreated(event)
  self:CheckTimer()
end
function modifier_electrician_electric_shield_auto_caster:OnRefresh(event)
  self:CheckTimer()
end

function modifier_electrician_electric_shield_auto_caster:CheckTimer()
  -- only run on the server
  if not IsServer() then
    return
  end

  self:StartIntervalThink(0.2)
end

function modifier_electrician_electric_shield_auto_caster:OnIntervalThink()
  -- only run on the server
  if not IsServer() then
    return
  end

  local newTime = self:CheckCastShield()
  self:StartIntervalThink(newTime)
end

function modifier_electrician_electric_shield_auto_caster:CheckCastShield()
  -- only run on the server
  if not IsServer() then
    return
  end

  local ability = self:GetAbility()
  if not ability or ability:IsNull() then
    return -1
  end

  if not ability:GetAutoCastState() or not ability:IsOwnersManaEnough() or not ability:IsCooldownReady() then
    return 1
  end

  local parent = self:GetParent()
  if not parent or parent:IsNull() or not parent:IsRealHero() then
    return -1
  end

  if not parent:IsAlive() then
    return 2
  end

  local shield = parent:FindModifierByName("modifier_electrician_electric_shield")

  if shield and not shield:IsNull() then
    shield.auto_cast_modifier = self
    return 2
  end

  if parent:IsSilenced() or parent:IsStunned() then
    return 0.1
  end

  -- logic for not casting at dumb times is in CastFilterResult
  local filterResult = ability:CastFilterResult()
  ability:GetManaCost(-1)

  if filterResult == UF_SUCCESS then
    ability:CastAbility()
  end

  return 0.1
end


--------------------------------------------------------------------------------
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
  return true
end

--------------------------------------------------------------------------------

function modifier_electrician_electric_shield:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT,
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
  }
end

--------------------------------------------------------------------------------

if IsServer() then
	--[[
  function modifier_electrician_electric_shield:GetModifierPhysical_ConstantBlockUnavoidablePreArmor( event )
		-- start with the maximum block amount
		local blockAmount = event.damage * self.shieldRate
		-- grab the remaining shield hp
		local hp = math.abs(self:GetStackCount())

		-- don't block more than remaining hp
		blockAmount = math.min( blockAmount, hp )

		-- remove shield hp (using negative stacks to not show them on the buff)
		self:SetStackCount( blockAmount - hp )

		-- do the little block visual effect
		SendOverheadEventMessage( nil, 8, self:GetParent(), blockAmount, nil )

		-- destroy the modifier if hp is reduced to nothing
		if self:GetStackCount() >= 0 then
			self:Destroy()
		end

		return blockAmount
	end
  ]]

--------------------------------------------------------------------------------

  function modifier_electrician_electric_shield:OnCreated(event)
    local parent = self:GetParent()
    local spell = self:GetAbility()

    if event.shieldHP ~= -1 then
      self:SetStackCount(0 - event.shieldHP)
    end

    -- grab ability specials
    local damageInterval = spell:GetSpecialValueFor("aura_interval")
    local damage_per_second = spell:GetSpecialValueFor("aura_damage")
    -- Bonus damage talent

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
      self.partShield = nil
    end

    self:OnCreated(event)
  end

--------------------------------------------------------------------------------

-- damage_pct_to_attacks
-- mana_pct_refund
  function modifier_electrician_electric_shield:OnDestroy()
    if IsServer() then
      local parent = self:GetParent()
      local ability = self:GetAbility();

      if not parent or parent:IsNull() or not ability or ability:IsNull() then
        return 0
      end

      local manaRefundPercent = ability:GetSpecialValueFor("mana_pct_refund") / 100

      if manaRefundPercent > 0 then
        local remainingShieldHP = 0 - self:GetStackCount()
        if remainingShieldHP > 0 then
          local shieldPerMana = ability:GetSpecialValueFor("shield_per_mana")
          local manaCost = remainingShieldHP / shieldPerMana
          parent:GiveMana(manaCost * manaRefundPercent)
        end
      end

      -- asyncronously recast shield
      Timers:CreateTimer(FrameTime(), function()
        if self.auto_cast_modifier and self.auto_cast_modifier.CheckCastShield and not self.auto_cast_modifier:IsNull() then
          self.auto_cast_modifier:CheckCastShield()
        end
      end)
    end

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

    if not parent or parent:IsNull() or not spell or spell:IsNull() or not caster or caster:IsNull() then
      return 0
    end

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

    local damage_table = {
      attacker = caster,
      damage = self.damagePerInterval,
      damage_type = self.damageType,
      damage_flags = DOTA_DAMAGE_FLAG_NONE,
      ability = spell,
    }

    for _, target in pairs( units ) do
      -- Particle
      local part = ParticleManager:CreateParticle("particles/items_fx/chain_lightning.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
      ParticleManager:SetParticleControlEnt(part, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
      ParticleManager:SetParticleControlEnt(part, 1, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parentOrigin, true)
      ParticleManager:ReleaseParticleIndex(part)

      -- Sound
      target:EmitSound( "Hero_razor.lightning" )

      -- Apply damage
      damage_table.victim = target
      ApplyDamage(damage_table)
    end
  end
end

function modifier_electrician_electric_shield:GetModifierIncomingDamageConstant(event)
  local parent = self:GetParent()
  local ability = self:GetAbility()

  if not parent or parent:IsNull() or not ability or ability:IsNull() then
    return 0
  end

  if IsClient() then
    -- Shield numbers (visual only)
    local max_mana = parent:GetMaxMana()

    local max_mana_cost = max_mana * ability:GetSpecialValueFor("mana_cost") * 0.01
    local damage_per_mana = ability:GetSpecialValueFor("shield_per_mana")
    local max_shield_hp = max_mana_cost * damage_per_mana
    local current_shield_hp = math.abs(self:GetStackCount())

    if event.report_max then
      return max_shield_hp
    else
      return current_shield_hp
    end
  else

    -- Don't react to damage with HP removal flag
    if bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then
      return 0
    end

    -- Don't react on self damage
    if event.attacker == parent then
      return 0
    end

    local damage = event.damage
    local shield_hp = math.abs(self:GetStackCount())

    -- Don't block more than remaining hp
    local block_amount = math.min(damage*self.shieldRate, shield_hp)

    -- Reduce shield hp (using negative stacks to not show them on the buff)
    self:SetStackCount(block_amount - shield_hp)

    if block_amount > 0 then
      -- Visual effect (TODO: add unique visual effect)
      local alert_type = OVERHEAD_ALERT_MAGICAL_BLOCK
      if event.damage_type == DAMAGE_TYPE_PHYSICAL then
        alert_type = OVERHEAD_ALERT_BLOCK
      end

      SendOverheadEventMessage(nil, alert_type, parent, block_amount, nil)
    end

    -- destroy the modifier if hp is reduced to nothing
    if self:GetStackCount() >= 0 then
      self:Destroy()
    end

    return -block_amount
  end
end

function modifier_electrician_electric_shield:GetModifierPreAttack_BonusDamage(event)
  local ability = self:GetAbility()
  local auraDamage = ability:GetSpecialValueFor("aura_damage")
  local damageToAttacks = ability:GetSpecialValueFor("damage_pct_to_attacks") / 100
  if damageToAttacks > 0 then
    return auraDamage * damageToAttacks
  end
  return 0
end
