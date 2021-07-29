LinkLuaModifier('modifier_is_in_offside', 'modifiers/modifier_offside.lua', LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier('modifier_offside', 'modifiers/modifier_offside.lua', LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier('modifier_onside_buff', 'modifiers/modifier_onside_buff.lua', LUA_MODIFIER_MOTION_NONE)

modifier_is_in_offside = class(ModifierBaseClass)
modifier_offside = class(ModifierBaseClass)

local TICKS_PER_SECOND = 5

function modifier_is_in_offside:OnCreated()
  if not IsServer() then
    return
  end

  self:StartIntervalThink(1)
end

modifier_is_in_offside.OnRefresh = modifier_is_in_offside.OnCreated

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

  -- Remove this offside thinker if parent is not in any offside zone
  if not IsLocationInOffside(origin) then
    self:Destroy()
    return
  end

  -- Add offside debuff if enemy is in offside and offside is active/enabled
  if (team == DOTA_TEAM_GOODGUYS and IsLocationInDireOffside(origin) and not Wanderer.dire_offside_disabled) or (team == DOTA_TEAM_BADGUYS and IsLocationInRadiantOffside(origin) and not Wanderer.radiant_offside_disabled) then
    if not parent:HasModifier("modifier_offside") then
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

--------------------------------------------------------------------

function modifier_offside:OnCreated()
  if IsServer() then
    self:SetStackCount(0)
    self:StartIntervalThink(1 / TICKS_PER_SECOND)
  end
end
modifier_offside.OnRefresh = modifier_offside.OnCreated

function modifier_offside:OnDestroy()
  self:ReleaseParticles()
end

function modifier_offside:IsPurgable()
  return false
end

--------------------------------------------------------------------
--aura
function modifier_offside:IsAura()
  return true
end

function modifier_offside:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO
end

function modifier_offside:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_offside:GetAuraRadius()
  return 2500
end

function modifier_offside:GetModifierAura()
  return "modifier_onside_buff"
end
--------------------------------------------------------------------
--% health damage
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
    local isInOffside = self:GetParent():HasModifier("modifier_is_in_offside")

    local alpha = (stackCount - 8) * 255/15

    if alpha >= 0 and isInOffside then
      if self.BloodOverlay == nil then
        -- Creates a new particle effect
        self.BloodOverlay = ParticleManager:CreateParticleForPlayer( "particles/misc/screen_blood_overlay.vpcf", PATTACH_WORLDORIGIN, self:GetParent(), self:GetParent():GetPlayerOwner() )
        ParticleManager:SetParticleControl( self.BloodOverlay, 1, Vector( alpha, 0, 0 ) )
        DebugPrint("Create Blood Overlay Alpha =" ..alpha)
      end
      ParticleManager:SetParticleControl( self.BloodOverlay, 1, Vector( alpha, 0, 0 ) )
    elseif self.BloodOverlay and not isInOffside then
      ParticleManager:SetParticleControl( self.BloodOverlay, 1, Vector( 0, 0, 0 ) )
    end

    if self.stackParticle then
      ParticleManager:DestroyParticle(self.stackParticle, false)
      ParticleManager:ReleaseParticleIndex(self.stackParticle)
    end
    self.stackParticle = ParticleManager:CreateParticleForPlayer( "particles/dungeon_overhead_timer_colored.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent(), self:GetParent():GetPlayerOwner() )
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
  local isEnemyOffside = true -- we assume that the offside is an enemy zone
  local radiantOffside = IsLocationInRadiantOffside(origin)
  local direOffside = IsLocationInDireOffside(origin)

  -- Check if parent is in its base (on its highground)
  if (team == DOTA_TEAM_GOODGUYS and radiantOffside) or (team == DOTA_TEAM_BADGUYS and direOffside) then
    isEnemyOffside = false -- this is possible when teleporting from enemy base to ally base and modifier_is_in_offside is not removed
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

  local isInOffside = parent:HasModifier("modifier_is_in_offside") and isEnemyOffside == true

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

  local defenders = FindUnitsInRadius(
    team,
    origin,
    nil,
    2500,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_HERO,
    bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD),
    FIND_ANY_ORDER,
    false
  )

  if #defenders == 0 then
    defenders = nil
  end

  if defenders then
    defenders = defenders[1]
  else
    defenders = Entities:FindByClassnameNearest("ent_dota_fountain", origin, 10000)
  end

  local damageTable = {
    victim = parent,
    attacker = defenders,
    damage = (h * ((0.15 * ((stackCount - 8)^2 + 10 * (stackCount - 8)))/100)) / TICKS_PER_SECOND,
    damage_type = DAMAGE_TYPE_PURE,
    damage_flags = bit.bor(DOTA_DAMAGE_FLAG_HPLOSS, DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS, DOTA_DAMAGE_FLAG_REFLECTION),
    ability = nil
  }

  if stackCount >= 8 then
    return ApplyDamage(damageTable)
  end
end
