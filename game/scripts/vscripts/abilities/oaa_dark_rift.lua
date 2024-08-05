abyssal_underlord_dark_rift_oaa = class(AbilityBaseClass)

LinkLuaModifier("modifier_underlord_dark_rift_oaa_stun", "abilities/oaa_dark_rift.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_underlord_dark_rift_oaa_scepter_buff", "abilities/oaa_dark_rift.lua", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

function abyssal_underlord_dark_rift_oaa:GetAOERadius()
  return self:GetSpecialValueFor("radius")
end

function abyssal_underlord_dark_rift_oaa:GetCastAnimation()
  return ACT_DOTA_CAST_ABILITY_4
end

function abyssal_underlord_dark_rift_oaa:GetAssociatedSecondaryAbilities()
  return "abyssal_underlord_cancel_dark_rift_oaa"
end

function abyssal_underlord_dark_rift_oaa:OnUpgrade()
  local abilityLevel = self:GetLevel()
  local sub_ability = self:GetCaster():FindAbilityByName("abyssal_underlord_cancel_dark_rift_oaa")

	-- Check to not enter a level up loop
  if sub_ability and sub_ability:GetLevel() ~= abilityLevel then
    sub_ability:SetLevel(abilityLevel)
  end
end

function abyssal_underlord_dark_rift_oaa:GetCooldown(level)
  local cooldown = self.BaseClass.GetCooldown(self, level)
  local caster = self:GetCaster()

  if caster:HasScepter() then
    cooldown = self:GetSpecialValueFor("cooldown_scepter")
  end

  return cooldown
end

function abyssal_underlord_dark_rift_oaa:OnAbilityPhaseStart()
  local caster = self:GetCaster()
  local originCaster = caster:GetAbsOrigin()
  local pos = self:GetCursorPosition() -- Server only?
  local minRange = self:GetSpecialValueFor("minimum_range")
  local vectorTarget = pos - originCaster

  -- if the target point is too close, push it out to minimum range
  if vectorTarget:Length2D() < minRange then
    pos = originCaster + ( vectorTarget:Normalized() * minRange )
  end

  local radius = self:GetSpecialValueFor( "radius" )
  local target_loc = GetGroundPosition( Vector(pos.x, pos.y, 0), caster) -- Server only?

  if IsServer() then
    -- Remove particles of the previous spell instance in case of refresher
    if caster.partPortal1 then
      ParticleManager:DestroyParticle( caster.partPortal1, false )
      ParticleManager:ReleaseParticleIndex( caster.partPortal1 )
      caster.partPortal1 = nil
    end
    if caster.partPortal2 then
      ParticleManager:DestroyParticle( caster.partPortal2, false )
      ParticleManager:ReleaseParticleIndex( caster.partPortal2 )
      caster.partPortal2 = nil
    end

    -- Remove stored locations of the previous spell instance in case of refresher
    caster.dark_rift_origin = nil
    caster.dark_rift_target = nil

    -- create portal particle on caster location
    local partPortal1 = ParticleManager:CreateParticle( "particles/units/heroes/heroes_underlord/abyssal_underlord_dark_rift_portal.vpcf", PATTACH_WORLDORIGIN, caster )
    ParticleManager:SetParticleControl( partPortal1, 0, originCaster )
    ParticleManager:SetParticleControl( partPortal1, 2, originCaster )
    ParticleManager:SetParticleControl( partPortal1, 1, Vector( radius, 1, 1 ) )

    -- create portal particle on destination
    local partPortal2 = ParticleManager:CreateParticle( "particles/units/heroes/heroes_underlord/abyssal_underlord_dark_rift_portal.vpcf", PATTACH_WORLDORIGIN, caster )
    ParticleManager:SetParticleControl( partPortal2, 0, target_loc )
    ParticleManager:SetParticleControl( partPortal2, 2, target_loc )
    ParticleManager:SetParticleControl( partPortal2, 1, Vector( radius, 1, 1 ) )

    -- play cast sounds
    caster:EmitSound("Hero_AbyssalUnderlord.DarkRift.Cast")
    --EmitSoundOnLocationWithCaster( target_loc, "Hero_AbyssalUnderlord.DarkRift.Cast", caster )
    -- EmitSoundOnLocationWithCaster needs to be replaced with EmitSound on invisible thinker/dummy entity
    -- and StopSound when portals close, otherwise its annoying

    -- Store the location of the caster on the caster itself for the sub ability
    caster.dark_rift_origin = originCaster

    -- Store the target location on the caster itself for the sub ability
    caster.dark_rift_target = target_loc

    -- Store particles indexes on caster itself (because of Dark Abduction sub ability)
    caster.partPortal1 = partPortal1
    caster.partPortal2 = partPortal2
  end

  return true
end

function abyssal_underlord_dark_rift_oaa:OnAbilityPhaseInterrupted()
  if IsServer() then
    local caster = self:GetCaster()

    -- Stop sound if interrupted
    caster:StopSound("Hero_AbyssalUnderlord.DarkRift.Cast")

    -- Remove particles if interrupted
    if caster.partPortal1 then
      ParticleManager:DestroyParticle( caster.partPortal1, true )
      ParticleManager:ReleaseParticleIndex( caster.partPortal1 )
      caster.partPortal1 = nil
    end
    if caster.partPortal2 then
      ParticleManager:DestroyParticle( caster.partPortal2, true )
      ParticleManager:ReleaseParticleIndex( caster.partPortal2 )
      caster.partPortal2 = nil
    end

    -- Remove stored locations if interrupted
    caster.dark_rift_origin = nil
    caster.dark_rift_target = nil
  end
end

-- function abyssal_underlord_dark_rift_oaa:GetChannelTime()
  -- if self:GetCaster():HasScepter() then
    -- return self:GetSpecialValueFor("teleport_delay_scepter")
  -- end
  -- return self.BaseClass.GetChannelTime(self)
-- end

function abyssal_underlord_dark_rift_oaa:OnSpellStart()
  local caster = self:GetCaster()

  -- Stop sound when the spell goes off
  caster:StopSound("Hero_AbyssalUnderlord.DarkRift.Cast")

  -- local function for removing portal particles
  local function RemoveParticles()
    if caster.partPortal1 then
      ParticleManager:DestroyParticle( caster.partPortal1, false )
      ParticleManager:ReleaseParticleIndex( caster.partPortal1 )
      caster.partPortal1 = nil
    end
    if caster.partPortal2 then
      ParticleManager:DestroyParticle( caster.partPortal2, false )
      ParticleManager:ReleaseParticleIndex( caster.partPortal2 )
      caster.partPortal2 = nil
    end
  end

  local originParent = caster:GetAbsOrigin()
  local radius = self:GetSpecialValueFor("radius")
  local target_loc = caster.dark_rift_target

  -- destroy all trees in portals
  GridNav:DestroyTreesAroundPoint( originParent, radius, true )
  GridNav:DestroyTreesAroundPoint( target_loc, radius, true )

  -- play teleportation sounds
  caster:EmitSound("Hero_AbyssalUnderlord.DarkRift.Aftershock")
  EmitSoundOnLocationWithCaster( target_loc, "Hero_AbyssalUnderlord.DarkRift.Aftershock", caster )

  -- emit warp particles
  local part = ParticleManager:CreateParticle( "particles/units/heroes/heroes_underlord/abbysal_underlord_darkrift_warp.vpcf", PATTACH_WORLDORIGIN, caster )
  ParticleManager:SetParticleControl( part, 1, Vector( radius, 1, 1 ) )
  ParticleManager:SetParticleControl( part, 2, originParent )

  local part2 = ParticleManager:CreateParticle( "particles/units/heroes/heroes_underlord/abbysal_underlord_darkrift_warp.vpcf", PATTACH_WORLDORIGIN, caster )
  ParticleManager:SetParticleControl( part2, 1, Vector( radius, 1, 1 ) )
  ParticleManager:SetParticleControl( part2, 2, target_loc )

  local targetTeam = self:GetAbilityTargetTeam()
  local targetType = self:GetAbilityTargetType()
  local targetFlags = DOTA_UNIT_TARGET_FLAG_NONE --self:GetAbilityTargetFlags()

  local units_in_portal = FindUnitsInRadius(caster:GetTeamNumber(), target_loc, nil, radius, targetTeam, targetType, targetFlags, FIND_ANY_ORDER, false)

  -- Original stun duration
  local stun_duration = self:GetSpecialValueFor("stun_duration")

  -- Teleport the caster
  caster:SetAbsOrigin(target_loc)
  FindClearSpaceForUnit(caster, target_loc, true)

  -- Disjoint disjointable/dodgeable projectiles
  ProjectileManager:ProjectileDodge(caster)

  -- Teleportation particle
  local part3 = ParticleManager:CreateParticle( "particles/units/heroes/heroes_underlord/abbysal_underlord_darkrift_ambient_end.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
  ParticleManager:SetParticleControl( part3, 2, originParent )
  ParticleManager:SetParticleControl( part3, 5, originParent )

  -- Scepter buff
  if caster:HasScepter() then
    caster:AddNewModifier(caster, self, "modifier_underlord_dark_rift_oaa_scepter_buff", {duration = self:GetSpecialValueFor("buff_duration")})
  end

  local damageTable = {
    attacker = caster,
    damage = self:GetSpecialValueFor("damage"),
    damage_type = self:GetAbilityDamageType(),
    ability = self,
  }

  -- Find all enemies and apply effects of the spell: stun them and damage them
  for _, unit in pairs(units_in_portal) do
    -- Status Resistance Fix
    local actual_duration = unit:GetValueChangedByStatusResistance(stun_duration)
    unit:AddNewModifier(caster, self, "modifier_underlord_dark_rift_oaa_stun", {duration = actual_duration} )
    -- Apply damage
    damageTable.victim = unit
    ApplyDamage(damageTable)
  end

  -- Particles releasing indexes
  ParticleManager:ReleaseParticleIndex(part)
  ParticleManager:ReleaseParticleIndex(part2)
  ParticleManager:ReleaseParticleIndex(part3)

  -- If somebody was affected by this spell, delay the portal particle removal, otherwise remove immediately
  if #units_in_portal > 0 then
    Timers:CreateTimer(stun_duration+0.5, function()
      RemoveParticles()
    end)
  else
    RemoveParticles()
    caster.dark_rift_origin = nil
  end
end

-- function abyssal_underlord_dark_rift_oaa:OnHeroCalculateStatBonus()
	-- local caster = self:GetCaster()
  -- local fiends_gate_ability = caster:FindAbilityByName("abyssal_underlord_dark_portal")
  -- local fiends_gate_warp_ability = caster:FindAbilityByName("abyssal_underlord_portal_warp")

	-- if not fiends_gate_ability then
    -- return
  -- end

  -- if caster:HasScepter() then
		-- fiends_gate_ability:SetHidden(false)
		-- if fiends_gate_ability:GetLevel() <= 0 then
			-- fiends_gate_ability:SetLevel(1)
		-- end
    -- --if not fiends_gate_warp_ability then
      -- --caster:AddAbility("abyssal_underlord_portal_warp")
    -- --end
	-- else
		-- fiends_gate_ability:SetHidden(true)
	-- end
-- end

function abyssal_underlord_dark_rift_oaa:ProcsMagicStick()
  return true
end

function abyssal_underlord_dark_rift_oaa:IsStealable()
  return true
end

---------------------------------------------------------------------------------------------------

modifier_underlord_dark_rift_oaa_stun = class(ModifierBaseClass)

function modifier_underlord_dark_rift_oaa_stun:IsHidden()
  return false
end

function modifier_underlord_dark_rift_oaa_stun:IsDebuff()
  return true
end

function modifier_underlord_dark_rift_oaa_stun:IsPurgable()
  return true
end

function modifier_underlord_dark_rift_oaa_stun:IsStunDebuff()
  return true
end

function modifier_underlord_dark_rift_oaa_stun:GetEffectName()
  return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_underlord_dark_rift_oaa_stun:GetEffectAttachType()
  return PATTACH_OVERHEAD_FOLLOW
end

function modifier_underlord_dark_rift_oaa_stun:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
  }
end

function modifier_underlord_dark_rift_oaa_stun:GetOverrideAnimation()
  return ACT_DOTA_DISABLED
end

function modifier_underlord_dark_rift_oaa_stun:CheckState()
  return {
    [MODIFIER_STATE_STUNNED] = true,
  }
end

---------------------------------------------------------------------------------------------------

modifier_underlord_dark_rift_oaa_scepter_buff = class(ModifierBaseClass)

function modifier_underlord_dark_rift_oaa_scepter_buff:IsHidden()
  return false
end

function modifier_underlord_dark_rift_oaa_scepter_buff:IsDebuff()
  return false
end

function modifier_underlord_dark_rift_oaa_scepter_buff:IsPurgable()
  return true
end

function modifier_underlord_dark_rift_oaa_scepter_buff:OnCreated()
  local ability = self:GetAbility()
  if ability then
    self.dmg_reduction = ability:GetSpecialValueFor("damage_reduction")
    self.move_speed = ability:GetSpecialValueFor("bonus_ms")
  else
    self.dmg_reduction = 10
    self.move_speed = 10
  end
end

function modifier_underlord_dark_rift_oaa_scepter_buff:OnRefresh()
  self:OnCreated()
end

function modifier_underlord_dark_rift_oaa_scepter_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
  }
end

if IsServer() then
  function modifier_underlord_dark_rift_oaa_scepter_buff:GetModifierIncomingDamage_Percentage()
    return 0 - math.abs(self.dmg_reduction)
  end
end

function modifier_underlord_dark_rift_oaa_scepter_buff:GetModifierMoveSpeedBonus_Percentage()
  return self.move_speed
end
