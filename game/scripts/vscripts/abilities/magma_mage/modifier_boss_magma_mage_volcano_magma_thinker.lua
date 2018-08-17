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
  }
  return funcs
end

function modifier_boss_magma_mage_volcano_thinker:OnCreated(kv)
  if IsServer() then

    -- for k,v in pairs(kv) do
    --   print(k,v)
    -- end
    self.creationtime = kv.creationtime
    self.delay = kv.delay or 0
    self.interval = kv.interval or 0.1
    self.radius = kv.radius or 250
    self.torrent_damage = kv.torrent_damage or 1
    self.damage_type = self:GetAbility():GetAbilityDamageType() or 0
    self.stun_duration = kv.stun_duration or 0
    
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
    local hParent = self:GetParent()
    local damage = {
        victim = nil,
        attacker = hParent,
        damage = 1,
        damage_type = self.damage_type,
        ability = self:GetAbility(),
    }
    local units = FindUnitsInRadius( hParent:GetTeamNumber(), hParent:GetAbsOrigin(), hParent, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false )
      if #units > 0 then
        for _,unit in pairs(units) do
          if unit ~= nil then
            damage.victim = unit
            ApplyDamage(damage)
          end
        end
    end
  elseif GameRules:GetGameTime() >= (self.creationtime + self.delay) then
      self.bErupted = true
      self:MagmaErupt()
      self:StartIntervalThink(self.interval)
  end
  return
end


--------------------------------------------------------------------------------
 
 function modifier_boss_magma_mage_volcano_thinker:MagmaErupt()

    local hParent = self:GetParent()

    ParticleManager:DestroyParticle(self.nFXIndex, false)
    local nFXIndex = ParticleManager:CreateParticle( "particles/boss_magma_mage_volcano1.vpcf", PATTACH_WORLDORIGIN, nil )
    ParticleManager:SetParticleControl( nFXIndex, 0, hParent:GetOrigin())
    ParticleManager:SetParticleControl( nFXIndex, 1, Vector(self.radius,0,0))

    local enemies = FindUnitsInRadius( hParent:GetTeamNumber(), hParent:GetAbsOrigin(), hParent, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false )
    print(#enemies)

    if #enemies > 0 then
      print(hello)
      local hAbility = self:GetAbility()
      local damage = {
        victim = nil, --applied later
        attacker = hParent,
        damage = self.torrent_damage,
        damage_type = hAbility:GetAbilityDamageType(),
        ability = hAbility,
      }

      for _,unit in pairs(enemies) do
        if (unit ~= nil)  then
          damage.victim = unit
          ApplyDamage(damage)
          --unit:AddNewModifier(hCaster,self,"modifier_boss_magma_mage_volcano", {duration = self:GetSpecialValueFor("torrent_knockup_duration")} )
          unit:AddNewModifier(hParent,hAbility,"modifier_stun_generic", {duration = self.stun_duration} )
          --self:MagmaTorrent(unit:GetOrigin())
        end
      end

    end

  return

 end
