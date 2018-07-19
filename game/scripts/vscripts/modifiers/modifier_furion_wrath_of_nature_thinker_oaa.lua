LinkLuaModifier( "modifier_treant_bonus_oaa", "modifiers/modifier_treant_bonus_oaa", LUA_MODIFIER_MOTION_NONE )

modifier_furion_wrath_of_nature_thinker_oaa = class(ModifierBaseClass)

--------------------------------------------------------------------------------

function modifier_furion_wrath_of_nature_thinker_oaa:IsHidden()
  return true
end

--------------------------------------------------------------------------------

function modifier_furion_wrath_of_nature_thinker_oaa:OnCreated( kv )
  self.damage = self:GetAbility():GetSpecialValueFor( "damage" )
  self.max_targets = self:GetAbility():GetSpecialValueFor( "max_targets" )
  self.damage_percent_add = self:GetAbility():GetSpecialValueFor( "damage_percent_add" )
  self.jump_delay = self:GetAbility():GetSpecialValueFor( "jump_delay" )
  self.damage_scepter = self:GetAbility():GetSpecialValueFor( "damage_scepter" )

  if IsServer() then
    self.hTarget = self:GetAbility().hTarget
    if self.hTarget ~= nil and self.hTarget:TriggerSpellAbsorb( self ) then
      self:Destroy()
      return
    end

    if self.hTarget == nil then
      local vPos = self:GetParent():GetOrigin()

      local nFXIndexStart = ParticleManager:CreateParticle( "particles/units/heroes/hero_furion/furion_wrath_of_nature_start.vpcf", PATTACH_CUSTOMORIGIN, nil )
      ParticleManager:SetParticleControl( nFXIndexStart, 0, self:GetParent():GetOrigin() )
      ParticleManager:ReleaseParticleIndex( nFXIndexStart )

      self.hTarget = self:GetNextTarget()
      if self.hTarget == nil then
        Msg( "Couldn't find target" )
        self:Destroy()
        return
      end
    end

    self.flLastTickTime = GameRules:GetGameTime()
    self.flTimeAccumlator = 0.0
    self.hTargetsHit = {}
    self:StartIntervalThink( 0.0 )

    self:CreateBounceFX( self.hTarget )
    self:GetParent():SetOrigin( self.hTarget:GetOrigin() )
    self:HitTarget( self.hTarget )

  end
end

--------------------------------------------------------------------------------

function modifier_furion_wrath_of_nature_thinker_oaa:OnDestroy()
  if IsServer() then
    UTIL_Remove( self:GetParent() )
  end
end

--------------------------------------------------------------------------------

function modifier_furion_wrath_of_nature_thinker_oaa:OnIntervalThink()
  if IsServer() then
    local flCurTime = GameRules:GetGameTime()
    local dt = flCurTime - self.flLastTickTime
    self.flLastTickTime = flCurTime
    self.flTimeAccumlator = self.flTimeAccumlator + dt

    if self.flTimeAccumlator < self.jump_delay then
      return
    end

    self.flTimeAccumlator = self.flTimeAccumlator - self.jump_delay

    local hNewTarget = self:GetNextTarget()
    if hNewTarget == nil then
      self:Destroy()
      return
    end

    self:CreateBounceFX( hNewTarget )
    self:GetParent():SetOrigin( hNewTarget:GetOrigin() )
    self:HitTarget( hNewTarget )

    local nMaxTargets = self.max_targets

    if #self.hTargetsHit >= nMaxTargets then
      self:Destroy()
    end
  end
end

--------------------------------------------------------------------------------

function modifier_furion_wrath_of_nature_thinker_oaa:GetNextTarget()
  local enemies = FindUnitsInRadius( self:GetCaster():GetTeamNumber(), self:GetParent():GetOrigin(), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false )

  local hClosestTarget = nil
  local flClosestDist = 0.0
  if #enemies > 0 then
    for _,enemy in pairs(enemies) do
      if enemy ~= nil and self:GetCaster():CanEntityBeSeenByMyTeam( enemy ) then
        local bHitByWrath = false

        if self.hTargetsHit ~= nil then
          for _,hHitEnemy in ipairs(self.hTargetsHit) do
            if enemy == hHitEnemy then
              bHitByWrath = true
            end
          end
        end

        if bHitByWrath == false then
          local vToTarget = enemy:GetOrigin() - self:GetParent():GetOrigin()
          local flDistToTarget = vToTarget:Length()

          if hClosestTarget == nil or flDistToTarget < flClosestDist then
            hClosestTarget = enemy
            flClosestDist = flDistToTarget
          end
        end
      end
    end
  end

  return hClosestTarget
end

--------------------------------------------------------------------------------

function modifier_furion_wrath_of_nature_thinker_oaa:HitTarget( hTarget )
  if hTarget == nil then
    return
  end

  local caster = self:GetCaster()
  local bHasScepter = caster:HasScepter()
  local nTargetsHit = 0
  if self.hTargetsHit ~= nil then
    nTargetsHit = #self.hTargetsHit
  end
  local flDamagePct = math.pow( 1.0 + ( self.damage_percent_add / 100.0 ), nTargetsHit )
  local flDamage = self.damage
  if bHasScepter then
    flDamage = self.damage_scepter
  end

  flDamage = flDamage * flDamagePct

  local damage = {
    victim = hTarget,
    attacker = caster,
    damage = flDamage,
    damage_type = DAMAGE_TYPE_MAGICAL,
    ability = self:GetAbility()
  }

  ApplyDamage( damage )

  if hTarget:IsHero() then
    EmitSoundOn( "Hero_Furion.WrathOfNature_Damage", hTarget )
  else
    EmitSoundOn( "Hero_Furion.WrathOfNature_Damage.Creep", hTarget )
  end

  if bHasScepter then
    local hForceOfNature = caster:FindAbilityByName( "furion_force_of_nature" )
    if ( not hTarget:IsAlive() ) and hForceOfNature ~= nil and hForceOfNature:IsTrained() then
      local level = hForceOfNature:GetLevel()
      local treantName = "npc_dota_furion_treant_" .. level
      if hTarget:IsHero() then
        treantName = "npc_dota_furion_treant_large_" .. level
      end

      -- Check whether the caster has learnt the 2x Treant health/damage talent
      local caster_has_treant_bonus = caster:HasLearnedAbility( "special_bonus_unique_furion" )

      local hTreant = CreateUnitByName( treantName, hTarget:GetOrigin(), true, caster, caster:GetOwner(), caster:GetTeamNumber() )
      if hTreant ~= nil then
        hTreant:SetControllableByPlayer( caster:GetPlayerID(), false )
        hTreant:SetOwner( caster )
        if caster_has_treant_bonus then
          hTreant:AddNewModifier( caster, self, "modifier_treant_bonus_oaa", {} )
        end

        local kv = {
          duration = hForceOfNature:GetSpecialValueFor( "duration" )
        }

        hTreant:AddNewModifier( caster, self, "modifier_kill", kv )
        EmitSoundOnLocationWithCaster( hTarget:GetOrigin(), "Hero_Furion.ForceOfNature", caster )
      end
    end
  end

  table.insert( self.hTargetsHit, hTarget )
end

--------------------------------------------------------------------------------

function modifier_furion_wrath_of_nature_thinker_oaa:CreateBounceFX( hTarget )
  --FX
  local vTarget1 = self:GetParent():GetOrigin()

  local vTarget2 = hTarget:GetOrigin() - vTarget1
  local flDistance = math.min( vTarget2:Length() / 2, 256.0 )
  vTarget2 = vTarget2:Normalized() * flDistance

  local vTarget3 = vTarget1 - hTarget:GetOrigin()
  vTarget3 = vTarget3:Normalized() * flDistance

  vTarget2 = vTarget2 + vTarget1
  vTarget3 = vTarget3 + hTarget:GetOrigin()

  local vTarget4 = hTarget:GetOrigin()

  vTarget2.z = vTarget2.z + math.max( flDistance, 128 )
  vTarget3.z = vTarget3.z + math.max( flDistance, 128 )
  vTarget4.z = vTarget4.z + 100

  local nFXIndexHit = ParticleManager:CreateParticle( "particles/units/heroes/hero_furion/furion_wrath_of_nature.vpcf", PATTACH_CUSTOMORIGIN, nil );
  ParticleManager:SetParticleControl( nFXIndexHit, 0, vTarget1 );
  ParticleManager:SetParticleControl( nFXIndexHit, 1, vTarget2 );
  ParticleManager:SetParticleControl( nFXIndexHit, 2, vTarget3 );
  ParticleManager:SetParticleControl( nFXIndexHit, 3, vTarget4 );
  ParticleManager:SetParticleControlOrientation( nFXIndexHit, 0, Vector( 0, 0, 1), Vector( 0, 1, 0), Vector( 1, 0, 0 ) );
  ParticleManager:SetParticleControlOrientation( nFXIndexHit, 1, Vector( 0, 0, 1), Vector( 0, 1, 0), Vector( 1, 0, 0 ) );
  ParticleManager:SetParticleControlOrientation( nFXIndexHit, 2, Vector( 0, 0, 1), Vector( 0, 1, 0), Vector( 1, 0, 0 ) );
  ParticleManager:SetParticleControlEnt( nFXIndexHit, 4, self.hTarget, PATTACH_ABSORIGIN_FOLLOW, nil, self:GetCaster():GetOrigin(), false );
  ParticleManager:ReleaseParticleIndex( nFXIndexHit );
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
