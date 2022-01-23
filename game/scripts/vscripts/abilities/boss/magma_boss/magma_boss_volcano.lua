LinkLuaModifier("modifier_boss_magma_mage_volcano", "abilities/magma_mage/modifier_boss_magma_mage_volcano.lua", LUA_MODIFIER_MOTION_VERTICAL) --knockup from torrent
LinkLuaModifier("modifier_boss_magma_mage_volcano_thinker", "abilities/magma_mage/modifier_boss_magma_mage_volcano_thinker.lua", LUA_MODIFIER_MOTION_NONE) --applied to volcano units to create magma pools
LinkLuaModifier("modifier_boss_magma_mage_volcano_thinker_child", "abilities/magma_mage/modifier_boss_magma_mage_volcano_thinker_child.lua", LUA_MODIFIER_MOTION_NONE) --applied to volcano units to make them invulnerable and pop in
LinkLuaModifier("modifier_boss_magma_mage_volcano_burning_effect", "abilities/magma_mage/modifier_boss_magma_mage_volcano_burning_effect.lua", LUA_MODIFIER_MOTION_NONE) --particles-only modifier for standing in magma

boss_magma_mage_volcano = class(AbilityBaseClass)

function boss_magma_mage_volcano:OnOwnerDied()
  self:KillAllVolcanos()
end

function boss_magma_mage_volcano:OnSpellStart()
  if IsServer() then
    --EmitSoundOn("",self:GetOwner())
    local hCaster = self:GetCaster()
    local nCastRange = self:GetSpecialValueFor("torrent_range")
    local nTorrents = self:GetSpecialValueFor("torrents_casted")

    local kv = {
      duration = self:GetSpecialValueFor("totem_duration_max"),
    }
    for i = 1, nTorrents do

      --get random location within cast range
      local fRadians = RandomFloat(0, 2*math.pi)
      local fDist = RandomFloat(0, nCastRange)
      local vLoc = hCaster:GetAbsOrigin()
      vLoc.x = vLoc.x + fDist*math.cos(fRadians)
      vLoc.y = vLoc.y + fDist*math.sin(fRadians)
      vLoc.z = GetGroundHeight(vLoc, nil)

      local hUnit = CreateUnitByName("npc_dota_magma_mage_volcano", vLoc, false, hCaster, hCaster, hCaster:GetTeamNumber())
      hUnit:AddNewModifier(hCaster, self, "modifier_boss_magma_mage_volcano_thinker", kv)
      hUnit:SetModelScale(0.01)
      local nMaxHealth = self:GetSpecialValueFor("totem_health")
      hUnit:SetBaseMaxHealth(nMaxHealth)
      hUnit:SetMaxHealth(nMaxHealth)
      hUnit:SetHealth(nMaxHealth)
      if self.zVolcanoName == nil then
        self.zVolcanoName = hUnit:GetName()
      end
    end
  end
end

--------------------------------------------------------------------------------

function boss_magma_mage_volcano:KillAllVolcanos() --kill all volcanos created by this ability's caster
  if IsServer() then
    local volcanos = Entities:FindAllByName(self.zVolcanoName)
    local zModName = "modifier_boss_magma_mage_volcano_thinker"
    for _,volcano in pairs(volcanos) do
      if volcano:HasModifier(zModName) and (volcano:FindModifierByName(zModName):GetCaster() == self:GetCaster()) then
        volcano:ForceKill(false)
      end
    end
  end
end

function boss_magma_mage_volcano:FindClosestMagmaPool() --returns the location (Vector) of the closest magma (edge of a magma pool)
  if IsServer() then
    local volcanos = Entities:FindAllByName(self.zVolcanoName)
    local zModName = "modifier_boss_magma_mage_volcano_thinker"
    local hClosestVolcano = nil
    local nClosestEdgeDistance = math.huge
    for _,volcano in pairs(volcanos) do
      if volcano:HasModifier(zModName) and (volcano:FindModifierByName(zModName):GetCaster():GetTeamNumber() == self:GetCaster():GetTeamNumber()) then
        local EdgeDistance = (self:GetOwner():GetOrigin() - volcano:GetOrigin()):Length2D() - volcano:FindModifierByName(zModName):GetMagmaRadius()
        if EdgeDistance < nClosestEdgeDistance then
          nClosestEdgeDistance = EdgeDistance
          hClosestVolcano = volcano
        end
      end
    end
    local vEdgeLoc
    if hClosestVolcano then
      vEdgeLoc = self:GetOwner():GetAbsOrigin() + (hClosestVolcano:GetAbsOrigin()-self:GetOwner():GetAbsOrigin()):Normalized()*nClosestEdgeDistance
      DebugDrawLine(self:GetOwner():GetOrigin(),vEdgeLoc,0,255,255,true,10)
    end
    return vEdgeLoc
  end
end

function boss_magma_mage_volcano:GetNumVolcanos()
  if IsServer() then
    local volcanos = Entities:FindAllByName(self.zVolcanoName)
    local NumVolcanos = 0
    if #volcanos > 0 then
      local zModName = "modifier_boss_magma_mage_volcano_thinker"
      for _,volcano in pairs(volcanos) do
        if volcano and volcano:HasModifier(zModName) and (volcano:FindModifierByName(zModName):GetCaster():GetTeamNumber() == self:GetCaster():GetTeamNumber()) then
          NumVolcanos = NumVolcanos + 1
        end
      end
    end
    --print("MAGMA_MAGE NumVolcanos", NumVolcanos)
    return NumVolcanos
  end
end

---------------------------------------------------------------------------------------------------

modifier_boss_magma_mage_volcano = class(ModifierBaseClass)

GRAVITY_DECEL = 800

function modifier_boss_magma_mage_volcano:IsHidden()
  return true
end

function modifier_boss_magma_mage_volcano:IsStunDebuff()
  return true
end

function modifier_boss_magma_mage_volcano:IsAura()
  return false
end

function modifier_boss_magma_mage_volcano:IsDebuff()
  return true
end

function modifier_boss_magma_mage_volcano:IsPurgable()
  return false
end

function modifier_boss_magma_mage_volcano:IsPurgeException()
  return true
end

function modifier_boss_magma_mage_volcano:RemoveOnDeath()
  return true
end

function modifier_boss_magma_mage_volcano:GetEffectName()
  return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_boss_magma_mage_volcano:GetEffectAttachType()
  return PATTACH_OVERHEAD_FOLLOW
end

function modifier_boss_magma_mage_volcano:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
  }
  return funcs
end

function modifier_boss_magma_mage_volcano:GetOverrideAnimation()
  return ACT_DOTA_FLAIL
end

function modifier_boss_magma_mage_volcano:OnCreated( kv )
  if IsServer() then
    --set speed so that the rise/fall will match the knockup duration
    self.speed = kv.duration*GRAVITY_DECEL/2
    if self:ApplyVerticalMotionController() == false then
      self:Destroy()
    end
  end
end

function modifier_boss_magma_mage_volcano:OnRefresh( kv )
  if IsServer() then
    local hParent = self:GetParent()
    hParent:RemoveVerticalMotionController(self)
    self.speed = kv.duration*GRAVITY_DECEL/2
    if self:ApplyVerticalMotionController() == false then
      self:Destroy()
    end
  end
end

function modifier_boss_magma_mage_volcano:OnDestroy()
  if IsServer() then
    local hParent = self:GetParent()
    hParent:RemoveVerticalMotionController(self)
  end
end

function modifier_boss_magma_mage_volcano:UpdateVerticalMotion( me, dt )
  if IsServer() then
    local parent = self:GetParent()
    local iVectLength = self.speed*dt
    self.speed = self.speed - GRAVITY_DECEL*dt
    local vVect = iVectLength*Vector(0,0,1)
    parent:SetOrigin(parent:GetOrigin()+vVect)
  end
end

function modifier_boss_magma_mage_volcano:CheckState()
  local state = {
    [MODIFIER_STATE_STUNNED] = true
  }
  return state
end

---------------------------------------------------------------------------------------------------

modifier_boss_magma_mage_volcano_burning_effect = class(ModifierBaseClass)

function modifier_boss_magma_mage_volcano_burning_effect:IsHidden()
  return true
end

function modifier_boss_magma_mage_volcano_burning_effect:IsAura()
  return false
end

function modifier_boss_magma_mage_volcano_burning_effect:IsDebuff()
  return true
end

function modifier_boss_magma_mage_volcano_burning_effect:IsPurgable()
  return false
end

function modifier_boss_magma_mage_volcano_burning_effect:RemoveOnDeath()
  return true
end

function modifier_boss_magma_mage_volcano_burning_effect:OnCreated()
  if IsServer() then
    local parent = self:GetParent()
    local nFXIndex = ParticleManager:CreateParticle("particles/boss_magma_mage_volcano_burning.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControlEnt(nFXIndex, 0, parent, PATTACH_ABSORIGIN_FOLLOW, nil, parent:GetOrigin(), true)
    ParticleManager:SetParticleControl(nFXIndex, 2, Vector(2,0,0))
    self.nFXIndex = nFXIndex
  end
end

function modifier_boss_magma_mage_volcano_burning_effect:OnDestroy()
  if IsServer() then
    if self.nFXIndex then
      ParticleManager:DestroyParticle(self.nFXIndex, false)
      ParticleManager:ReleaseParticleIndex(self.nFXIndex)
    end
  end
end

---------------------------------------------------------------------------------------------------

modifier_boss_magma_mage_volcano_thinker = class (ModifierBaseClass)

function modifier_boss_magma_mage_volcano_thinker:IsHidden()
  return true
end

function modifier_boss_magma_mage_volcano_thinker:IsDebuff()
  return false
end

function modifier_boss_magma_mage_volcano_thinker:IsPurgable()
  return false
end

function modifier_boss_magma_mage_volcano_thinker:IsAura()
  return false
end

function modifier_boss_magma_mage_volcano_thinker:RemoveOnDeath()
  return true
end

function modifier_boss_magma_mage_volcano_thinker:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_DISABLE_HEALING,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_boss_magma_mage_volcano_thinker:OnCreated()
  if IsServer() then
    local parent = self:GetParent()
    local hAbility = self:GetAbility()

    self.delay = hAbility:GetSpecialValueFor("torrent_delay")
    self.interval = hAbility:GetSpecialValueFor("magma_damage_interval")
    self.radius = hAbility:GetSpecialValueFor("torrent_aoe")
    self.torrent_damage = hAbility:GetSpecialValueFor("torrent_damage")
    self.damage_type = hAbility:GetAbilityDamageType() or 0
    self.stun_duration = hAbility:GetSpecialValueFor("torrent_stun_duration")
    self.knockup_duration = hAbility:GetSpecialValueFor("torrent_knockup_duration")
    self.damage_per_second = hAbility:GetSpecialValueFor("magma_damage_per_second")
    self.heal_per_second = hAbility:GetSpecialValueFor("magma_heal_per_second")
    self.aoe_per_second = hAbility:GetSpecialValueFor("magma_spread_speed")
    self.magma_radius =  hAbility:GetSpecialValueFor("magma_initial_aoe")
    self.max_radius = hAbility:GetSpecialValueFor("magma_radius_max")

    self.nFXIndex = ParticleManager:CreateParticle("particles/boss_magma_mage_volcano_indicator1.vpcf", PATTACH_WORLDORIGIN, parent)
    ParticleManager:SetParticleControl(self.nFXIndex, 0, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.nFXIndex, 1, Vector(self.radius, self.delay, 0))
    self.nFXIndex2 = ParticleManager:CreateParticle("particles/boss_magma_mage_volcano_embers.vpcf", PATTACH_WORLDORIGIN, parent)
    ParticleManager:SetParticleControl(self.nFXIndex2, 2, parent:GetAbsOrigin())

    self.bErupted = false
    self:StartIntervalThink(self.delay)
  end
end

function modifier_boss_magma_mage_volcano_thinker:OnDestroy()
  if IsServer() then
    if self.nFXIndex then
      ParticleManager:DestroyParticle(self.nFXIndex, false)
      ParticleManager:ReleaseParticleIndex(self.nFXIndex)
    end
    if self.nFXIndex2 then
      ParticleManager:DestroyParticle(self.nFXIndex2, false)
      ParticleManager:ReleaseParticleIndex(self.nFXIndex2)
    end
    -- Instead ofUTIL_Remove(self:GetParent())
    local parent = self:GetParent()
    if parent then
      parent:AddNoDraw()
    end
  end
end

function modifier_boss_magma_mage_volcano_thinker:OnIntervalThink()
  if self.bErupted == true then
    local aoe_per_interval = self.aoe_per_second*self.interval
    local heal_per_interval = self.heal_per_second*self.interval
    local damage_per_interval = self.damage_per_second*self.interval

    local hParent = self:GetParent()
    local ability = self:GetAbility()
    local damage = {
        victim = nil,
        attacker = self:GetCaster(),
        damage = damage_per_interval,
        damage_type = self.damage_type,
        ability = ability,
    }
    local units = FindUnitsInRadius(hParent:GetTeamNumber(), hParent:GetAbsOrigin(), hParent, self.magma_radius, DOTA_UNIT_TARGET_TEAM_BOTH, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
      if #units > 0 then
        for _,unit in pairs(units) do
          if unit and not unit:IsNull() then
            unit:AddNewModifier(damage.attacker, ability, "modifier_boss_magma_mage_volcano_burning_effect", {duration = self.interval+0.1})
            if unit:GetTeamNumber() == hParent:GetTeamNumber() then
              unit:Heal(heal_per_interval, ability)
            elseif not unit:HasModifier("modifier_boss_magma_mage_volcano") then
              --damage enemy in pool unless they have yet to hit the ground
              damage.victim = unit
              ApplyDamage(damage)
            end
          end
        end
    end

    self.magma_radius = math.min(math.sqrt(self.magma_radius^2 + aoe_per_interval/math.pi), self.max_radius)
    ParticleManager:SetParticleControl(self.nFXIndex, 1, Vector(self.magma_radius, 0, 0))

  else
    self:MagmaErupt()
    self.bErupted = true
    self:StartIntervalThink(self.interval)
  end
end


function modifier_boss_magma_mage_volcano_thinker:CheckState()
  local state = {
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
  }
  if self.bErupted == false then
    state[MODIFIER_STATE_NO_HEALTH_BAR] = true
    state[MODIFIER_STATE_UNSELECTABLE] = true
    state[MODIFIER_STATE_INVISIBLE] = true
    state[MODIFIER_STATE_TRUESIGHT_IMMUNE] = true
  end
  return state
end

function modifier_boss_magma_mage_volcano_thinker:MagmaErupt()
  local hParent = self:GetParent()
  local hCaster = self:GetCaster()

  ParticleManager:DestroyParticle(self.nFXIndex, false)
  ParticleManager:ReleaseParticleIndex(self.nFXIndex)

  local nFXIndex = ParticleManager:CreateParticle("particles/boss_magma_mage_volcano1.vpcf", PATTACH_WORLDORIGIN, hParent)
  ParticleManager:SetParticleControl(nFXIndex, 0, hParent:GetOrigin())
  ParticleManager:SetParticleControl(nFXIndex, 1, Vector(self.radius, 0, 0))

  hParent:AddNewModifier(hCaster, self:GetAbility(), "modifier_boss_magma_mage_volcano_thinker_child", {duration = self.knockup_duration})

  local enemies = FindUnitsInRadius(hParent:GetTeamNumber(), hParent:GetAbsOrigin(), hParent, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

  if #enemies > 0 then
    local hAbility = self:GetAbility()
    local damage = {
      victim = nil, --applied later
      attacker = hCaster,
      damage = self.torrent_damage,
      damage_type = hAbility:GetAbilityDamageType(),
      ability = hAbility,
    }

    for _,unit in pairs(enemies) do
      if unit and not unit:IsNull() then
        damage.victim = unit
        ApplyDamage(damage)
        unit:AddNewModifier(hCaster, hAbility, "modifier_boss_magma_mage_volcano", {duration = self.knockup_duration})
        unit:AddNewModifier(hCaster, hAbility, "modifier_stunned", {duration = self.stun_duration})
      end
    end
  end

  --Particle for the actual magma pool
  self.nFXIndex = ParticleManager:CreateParticle("particles/boss_magma_mage_volcano_indicator1.vpcf", PATTACH_WORLDORIGIN, hParent)
  ParticleManager:SetParticleControl(self.nFXIndex, 0, hParent:GetAbsOrigin())
  ParticleManager:SetParticleControl(self.nFXIndex, 1, Vector(self.magma_radius, 0, 0))
end

function modifier_boss_magma_mage_volcano_thinker:OnAttackLanded(params)
  if IsServer() then
    local hParent = self:GetParent()
    if params.target == hParent then
      local hAttacker = params.attacker
      if hAttacker then
        local damage_dealt = 1
        if hAttacker:IsRealHero() then
          -- This is correct if HP is 32
          damage_dealt = 8
        end
        -- To prevent dead staying in memory (preventing SetHealth(0) or SetHealth(-value) )
        if hParent:GetHealth() - damage_dealt <= 0 then
          hParent:Kill(self:GetAbility(), hAttacker)
        else
          hParent:SetHealth(hParent:GetHealth() - damage_dealt)
        end
      end
    end
  end
end

function modifier_boss_magma_mage_volcano_thinker:GetAbsoluteNoDamagePhysical()
  return 1
end

function modifier_boss_magma_mage_volcano_thinker:GetAbsoluteNoDamageMagical()
  return 1
end

function modifier_boss_magma_mage_volcano_thinker:GetAbsoluteNoDamagePure()
  return 1
end

function modifier_boss_magma_mage_volcano_thinker:GetDisableHealing()
	return 1
end

function modifier_boss_magma_mage_volcano_thinker:GetMagmaRadius()
  return self.magma_radius
end

---------------------------------------------------------------------------------------------------

modifier_boss_magma_mage_volcano_thinker_child = class (ModifierBaseClass)

function modifier_boss_magma_mage_volcano_thinker_child:IsHidden()
  return true
end

function modifier_boss_magma_mage_volcano_thinker_child:IsDebuff()
  return false
end

function modifier_boss_magma_mage_volcano_thinker_child:IsPurgable()
  return false
end

function modifier_boss_magma_mage_volcano_thinker_child:IsAura()
  return false
end

function modifier_boss_magma_mage_volcano_thinker_child:RemoveOnDeath()
  return true
end

function modifier_boss_magma_mage_volcano_thinker_child:OnCreated(kv)
  if IsServer() then
    self.duration = kv.duration
    self.end_model_scale = self:GetAbility():GetSpecialValueFor("volcano_model_scale")
    self:StartIntervalThink(1/15)
  end
end

function modifier_boss_magma_mage_volcano_thinker_child:OnIntervalThink()
  local scale = self.end_model_scale*(1-self:GetRemainingTime()/self.duration)
  self:GetParent():SetModelScale(scale)
end

function modifier_boss_magma_mage_volcano_thinker_child:CheckState()
  local state = {
    [MODIFIER_STATE_UNSELECTABLE] = true,
    [MODIFIER_STATE_INVULNERABLE] = true,
  }
  return state
end
