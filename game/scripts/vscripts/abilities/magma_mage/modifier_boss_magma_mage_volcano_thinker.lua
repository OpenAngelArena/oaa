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

