modifier_boss_magma_mage_volcano_thinker = class (ModifierBaseClass)

 
--------------------------------------------------------------------------------
function modifier_boss_magma_mage_volcano_thinker:IsHidden()
  return true
end

function modifier_boss_magma_mage_volcano_thinker:IsAura()
  return false
end

function modifier_boss_magma_mage_volcano_thinker:RemoveOnDeath()
  return true
end

function modifier_boss_magma_mage_volcano_thinker:DeclareFunctions()
  local funcs = {
  MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
  MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_boss_magma_mage_volcano_thinker:OnCreated(kv)
  if IsServer() then

    local hAbility = self:GetAbility()

    self.creationtime = kv.creationtime
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
    
    self.nFXIndex = ParticleManager:CreateParticle( "particles/boss_magma_mage_volcano_indicator1.vpcf", PATTACH_WORLDORIGIN, nil )
    ParticleManager:SetParticleControl( self.nFXIndex, 0, self:GetParent():GetAbsOrigin())
    ParticleManager:SetParticleControl( self.nFXIndex, 1, Vector(self.radius,self.delay,0))
    local nFXIndex = ParticleManager:CreateParticle( "particles/boss_magma_mage_volcano_embers.vpcf", PATTACH_WORLDORIGIN, nil )
    ParticleManager:SetParticleControl( nFXIndex, 2, self:GetParent():GetAbsOrigin())

    self.bErupted = false
    self:StartIntervalThink(1/30)
  end
end

function modifier_boss_magma_mage_volcano_thinker:OnDestroy()
  if IsServer() then
    ParticleManager:DestroyParticle(self.nFXIndex, false)
    UTIL_Remove( self:GetParent() )
  end
  return
end

function modifier_boss_magma_mage_volcano_thinker:OnIntervalThink()

  if self.bErupted == true then
    local aoe_per_interval = self.aoe_per_second*self.interval
    local heal_per_interval = self.heal_per_second*self.interval
    local damage_per_interval = self.damage_per_second*self.interval

    local hParent = self:GetParent()
    local damage = {
        victim = nil,
        attacker = self:GetCaster(),
        damage = damage_per_interval ,
        damage_type = self.damage_type,
        ability = self:GetAbility(),
    }
    local units = FindUnitsInRadius( hParent:GetTeamNumber(), hParent:GetAbsOrigin(), hParent, self.magma_radius, DOTA_UNIT_TARGET_TEAM_ENEMY + DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false )
      if #units > 0 then
        for _,unit in pairs(units) do
          if unit ~= nil then
            unit:AddNewModifier(hCaster,hAbility,"modifier_boss_magma_mage_volcano_burning_effect", {duration = self.interval+0.1} )
            if unit:GetTeamNumber() == hParent:GetTeamNumber() then
              unit:Heal(heal_per_interval, self:GetAbility())
            elseif not unit:HasModifier("modifier_boss_magma_mage_volcano") then 
              --damage enemy in pool unless they have yet to hit the ground
              damage.victim = unit
              ApplyDamage(damage)
            end
          end
        end
    end

  self.magma_radius = math.min( math.sqrt(self.magma_radius^2 + aoe_per_interval/math.pi), self.max_radius)

  ParticleManager:SetParticleControl( self.nFXIndex, 1, Vector(self.magma_radius,0,0)) 

  elseif GameRules:GetGameTime() >= (self.creationtime + self.delay) then
      self:MagmaErupt()
      self.bErupted = true
      self:StartIntervalThink(self.interval)
  end
  return
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


--------------------------------------------------------------------------------
 
 function modifier_boss_magma_mage_volcano_thinker:MagmaErupt()

    local hParent = self:GetParent()
    local hCaster = self:GetCaster()

    ParticleManager:DestroyParticle(self.nFXIndex, false)
    local nFXIndex = ParticleManager:CreateParticle( "particles/boss_magma_mage_volcano1.vpcf", PATTACH_WORLDORIGIN, nil )
    ParticleManager:SetParticleControl( nFXIndex, 0, hParent:GetOrigin())
    ParticleManager:SetParticleControl( nFXIndex, 1, Vector(self.radius,0,0))

    hParent:AddNewModifier(hCaster,self:GetAbility(),"modifier_boss_magma_mage_volcano_thinker_child", {duration = self.knockup_duration})

    local enemies = FindUnitsInRadius( hParent:GetTeamNumber(), hParent:GetAbsOrigin(), hParent, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY , DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false )

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
        if (unit ~= nil)  then
          damage.victim = unit
          ApplyDamage(damage)
          unit:AddNewModifier(hCaster,hAbility,"modifier_boss_magma_mage_volcano", {duration = self.knockup_duration} )
          unit:AddNewModifier(hCaster,hAbility,"modifier_stun_generic", {duration = self.stun_duration} )
          --self:MagmaTorrent(unit:GetOrigin())
        end
      end

    end 

    --Particle for the actual magma pool
    self.nFXIndex = ParticleManager:CreateParticle( "particles/boss_magma_mage_volcano_indicator1.vpcf", PATTACH_WORLDORIGIN, nil )
    ParticleManager:SetParticleControl( self.nFXIndex, 0, self:GetParent():GetAbsOrigin())
    ParticleManager:SetParticleControl( self.nFXIndex, 1, Vector(self.magma_radius,0,0))   

  return

 end

function modifier_boss_magma_mage_volcano_thinker:OnAttackLanded( params )
  if IsServer() then
    local hParent = self:GetParent()
    for k,v in pairs(params) do
      print(k,v)
    end
    if params.target == hParent then
      local hAttacker = params.attacker
      if hAttacker ~= nil then
        local damage_dealt = nil
        if hAttacker:IsHero() then
          damage_dealt = 8
        else 
          damage_dealt = 1
        end
        hParent:SetHealth(hParent:GetHealth()-damage_dealt)
      end
    end
  end
end

function modifier_boss_magma_mage_volcano_thinker:GetModifierIncomingDamage_Percentage()
  return -100
end

function modifier_boss_magma_mage_volcano_thinker:GetMagmaRadius()
  return self.magma_radius
end

