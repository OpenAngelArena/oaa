modifier_is_in_offside = class(ModifierBaseClass)

local TICKS_PER_SECOND = 5

function modifier_is_in_offside:OnCreated()
  if not IsServer() then
    return
  end

  self:OnIntervalThink()
  self:StartIntervalThink(1)
end

function modifier_is_in_offside:OnIntervalThink()
  if not IsServer() then
    return
  end

  if Duels:IsActive() then
    return
  end

  local parent = self:GetParent()
  local origin = parent:GetAbsOrigin()
  local team = parent:GetTeamNumber()

  -- Don't continue (don't do location checks etc.) if parent is dead
  if not parent:IsAlive() then
    return
  end

  -- Remove this offside thinker if parent is not in any offside zone
  if not IsLocationInOffside(origin) then
    -- Don't remove this thinker if parent is still in the buffer zone
    if not ProtectionAura or not ProtectionAura:IsInBufferZone(parent) then
      self:Destroy()
    end
    return
  end

  -- Add offside debuff if enemy is in offside and offside is active/enabled
  if not parent:HasModifier("modifier_offside") then
    if (team == DOTA_TEAM_GOODGUYS and IsLocationInDireOffside(origin) and not Wanderer.dire_offside_disabled) or (team == DOTA_TEAM_BADGUYS and IsLocationInRadiantOffside(origin) and not Wanderer.radiant_offside_disabled) then
      parent:AddNewModifier(parent, nil, "modifier_offside", {})
    end
  end
end

function modifier_is_in_offside:IsHidden()
  return true
end

function modifier_is_in_offside:IsPurgable()
  return false
end

function modifier_is_in_offside:RemoveOnDeath()
  return false
end

---------------------------------------------------------------------------------------------------

modifier_offside = class(ModifierBaseClass)

function modifier_offside:OnCreated()
  if IsServer() then
    self:SetStackCount(0)
    self:StartIntervalThink(1 / TICKS_PER_SECOND)
  end
end

function modifier_offside:OnDestroy()
  self:ReleaseParticles()
end

function modifier_offside:IsPurgable()
  return false -- IsAura set to true makes the modifier unpurgable
end

function modifier_offside:RemoveOnDeath()
  return false
end

function modifier_offside:IsAura()
  return true
end

function modifier_offside:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO
end

function modifier_offside:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_offside:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, DOTA_UNIT_TARGET_FLAG_PLAYER_CONTROLLED)
end

function modifier_offside:GetAuraEntityReject(entity)
  -- Dont provide the offside buff to bosses
  if entity:IsOAABoss() then
    return true
  end
  return false
end

function modifier_offside:GetAuraRadius()
  return 2500
end

function modifier_offside:GetModifierAura()
  return "modifier_onside_buff"
end

function modifier_offside:GetTexture()
  return "custom/modifier_offside"
end

function modifier_offside:IsDebuff()
  return true
end

function modifier_offside:ReleaseParticles()
  if self.stackParticle then
    ParticleManager:DestroyParticle(self.stackParticle, false)
    ParticleManager:ReleaseParticleIndex( self.stackParticle )
  end

  if self.BloodOverlay then
    ParticleManager:SetParticleControl( self.BloodOverlay, 1, Vector( 0, 0, 0 ) )
    ParticleManager:DestroyParticle(self.BloodOverlay, false)
    ParticleManager:ReleaseParticleIndex( self.BloodOverlay )
  end
end

function modifier_offside:DrawParticles()
  -- avoid firing new particle every tick
  if self.stackOffset == 0 then
    local stackCount = self:GetStackCount()
    local parent = self:GetParent()
    local origin = parent:GetAbsOrigin()
    local team = parent:GetTeamNumber()

    local isEnemyOffside = true -- we assume that the offside is an enemy zone
    local radiantOffside = IsLocationInRadiantOffside(origin)
    local direOffside = IsLocationInDireOffside(origin)

    -- Check if it's enemy offside
    if (team == DOTA_TEAM_GOODGUYS and radiantOffside) or (team == DOTA_TEAM_BADGUYS and direOffside) then
      isEnemyOffside = false -- this is possible when teleporting directly from enemy base to ally base
    end

    local isDamageable = parent:IsAlive() and not parent:IsInvulnerable() and not parent:IsOutOfGame()
    local isInOffside = (radiantOffside or direOffside) and isEnemyOffside == true
    local alpha = (stackCount - 7) * 255/15

    if alpha >= 0 and isInOffside and isDamageable then
      if self.BloodOverlay == nil then
        -- Creates a new particle effect
        self.BloodOverlay = ParticleManager:CreateParticleForPlayer( "particles/misc/screen_blood_overlay.vpcf", PATTACH_WORLDORIGIN, parent, parent:GetPlayerOwner() )
        ParticleManager:SetParticleControl( self.BloodOverlay, 1, Vector( alpha, 0, 0 ) )
      end
      ParticleManager:SetParticleControl( self.BloodOverlay, 1, Vector( alpha, 0, 0 ) )
    elseif self.BloodOverlay then
      ParticleManager:SetParticleControl( self.BloodOverlay, 1, Vector( 0, 0, 0 ) )
    end

    if self.stackParticle then
      ParticleManager:DestroyParticle(self.stackParticle, false)
      ParticleManager:ReleaseParticleIndex(self.stackParticle)
    end
    self.stackParticle = ParticleManager:CreateParticleForPlayer( "particles/dungeon_overhead_timer_colored.vpcf", PATTACH_OVERHEAD_FOLLOW, parent, parent:GetPlayerOwner() )
    ParticleManager:SetParticleControl( self.stackParticle, 1, Vector( 0, stackCount, 0 ) )
    ParticleManager:SetParticleControl( self.stackParticle, 2, Vector( 2, 0, 0 ) )
    ParticleManager:SetParticleControl( self.stackParticle, 3, Vector( 255, 50, 0 ) )
  end
end

function modifier_offside:OnIntervalThink()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  local origin = parent:GetAbsOrigin()
  local team = parent:GetTeamNumber()

  -- Don't continue (don't do location checks, don't increment or decrement the stacks, don't do damage etc.) if the parent is dead
  -- It also prevents parent's corpse from gaining more stacks if the parent died in offside
  if not parent:IsAlive() then
    if self.BloodOverlay then
      ParticleManager:SetParticleControl(self.BloodOverlay, 1, Vector( 0, 0, 0 ))
    end
    return
  end

  local isEnemyOffside = true -- we assume that the offside is an enemy zone
  local radiantOffside = IsLocationInRadiantOffside(origin)
  local direOffside = IsLocationInDireOffside(origin)

  -- Check if parent is in its base (on its highground)
  if (team == DOTA_TEAM_GOODGUYS and radiantOffside) or (team == DOTA_TEAM_BADGUYS and direOffside) then
    isEnemyOffside = false -- this is possible when teleporting directly from enemy base to ally base
  end

  -- Check if parent is in the enemy offside zone while that offside zone is disabled by the Wanderer
  if (team == DOTA_TEAM_GOODGUYS and direOffside and Wanderer.dire_offside_disabled == true) or (team == DOTA_TEAM_BADGUYS and radiantOffside and Wanderer.radiant_offside_disabled == true) then
    return -- Don't continue (don't increment or decrement the stacks and don't do damage)
  end

  if not self.stackOffset then
    self.stackOffset = 1
  else
    self.stackOffset = self.stackOffset + 1
  end

  local isInOffside = (radiantOffside or direOffside) and isEnemyOffside == true

  if self.stackOffset >= TICKS_PER_SECOND then
    if isInOffside then
      self:IncrementStackCount()
    else
      self:DecrementStackCount()
    end
    self.stackOffset = 0
  end

  local h = parent:GetMaxHealth()
  local stackCount = self:GetStackCount()

  self:DrawParticles()

  if not isInOffside then
    if stackCount <= 0 then
      self:Destroy()
    end
    return -- Don't continue (don't do damage)
  end

  -- Find enemy heroes and other player-controlled units
  local defenders = FindUnitsInRadius(
    team,
    origin,
    nil,
    3600,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_OTHER),
    bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD),
    FIND_CLOSEST,
    false
  )

  -- Find the damage source of offside damage - nearest non-neutral hero or player-controlled unit
  if #defenders ~= 0 then
    for k = 1, #defenders do
      local defender = defenders[k]
      if defender and not defender:IsNull() and IsValidEntity(defender) then
        if defender:GetTeamNumber() ~= DOTA_TEAM_NEUTRALS then
          if defender.HasModifier then
            if not defender:HasModifier("modifier_minimap") and not defender:HasModifier("modifier_oaa_thinker") then
              self.damage_source = defender
              break
            end
          end
        end
      end
    end
  end

  -- Last resort (if highground is empty, there were no heroes and player-controlled units at modifier creation)
  if not self.damage_source and not IsValidEntity(self.damage_source) then
    self.damage_source = Entities:FindByClassnameNearest("ent_dota_fountain", origin, 6000)
  end

  local damageTable = {
    victim = parent,
    attacker = self.damage_source,
    damage = (h * ((0.15 * ((stackCount - 7)^2 + 10 * (stackCount - 7)))/100)) / TICKS_PER_SECOND,
    damage_type = DAMAGE_TYPE_PURE,
    damage_flags = bit.bor(DOTA_DAMAGE_FLAG_HPLOSS, DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS, DOTA_DAMAGE_FLAG_REFLECTION),
  }

  if stackCount >= 8 then
    return ApplyDamage(damageTable)
  end
end
