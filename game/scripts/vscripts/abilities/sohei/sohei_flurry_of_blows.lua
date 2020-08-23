sohei_flurry_of_blows = class( AbilityBaseClass )

LinkLuaModifier( "modifier_sohei_flurry_self", "abilities/sohei/sohei_flurry_of_blows.lua", LUA_MODIFIER_MOTION_NONE )

---------------------------------------------------------------------------------------------------

-- old Flurry of Blows, channeling, uses Momentum
--[[
function sohei_flurry_of_blows:OnAbilityPhaseStart()
  if IsServer() then
    self:GetCaster():EmitSound( "Hero_EmberSpirit.FireRemnant.Stop" )
    return true
  end
end

function sohei_flurry_of_blows:OnAbilityPhaseInterrupted()
  if IsServer() then
    self:GetCaster():StopSound( "Hero_EmberSpirit.FireRemnant.Stop" )
  end
end

function sohei_flurry_of_blows:GetAssociatedSecondaryAbilities()
  return "sohei_momentum"
end

function sohei_flurry_of_blows:GetChannelTime()

  if self:GetCaster():HasScepter() then
    return 300
  end

  return self:GetSpecialValueFor( "max_duration" )
end

function sohei_flurry_of_blows:OnChannelFinish(bInterrupted)
  local caster = self:GetCaster()
  caster:RemoveModifierByName( "modifier_sohei_flurry_self" )
end
]]

if IsServer() then
  function sohei_flurry_of_blows:OnSpellStart()
    local caster = self:GetCaster()
    local target_loc = self:GetCursorPosition()
    local flurry_radius = self:GetAOERadius()
    --local max_attacks = self:GetSpecialValueFor("max_attacks")
    --local max_duration = self:GetSpecialValueFor( "max_duration" )
    --local attack_interval = self:GetSpecialValueFor("attack_interval")
    local delay = self:GetSpecialValueFor("delay")
    local bonus_damage = self:GetSpecialValueFor("bonus_damage")

    -- Emit sound
    caster:EmitSound( "Hero_EmberSpirit.FireRemnant.Cast" )

    -- Draw the particle
    if caster.flurry_ground_pfx then
      ParticleManager:DestroyParticle( caster.flurry_ground_pfx, false )
      ParticleManager:ReleaseParticleIndex( caster.flurry_ground_pfx )
    end
    caster.flurry_ground_pfx = ParticleManager:CreateParticle( "particles/hero/sohei/flurry_of_blows_ground.vpcf", PATTACH_CUSTOMORIGIN, nil )
    ParticleManager:SetParticleControl( caster.flurry_ground_pfx, 0, target_loc )
    ParticleManager:SetParticleControl( caster.flurry_ground_pfx, 10, Vector(flurry_radius,0,0))

    -- Disjoint projectiles
    ProjectileManager:ProjectileDodge(caster)

    -- Put caster in the middle of the circle little above ground
    caster:SetAbsOrigin( target_loc + Vector(0, 0, 200) )

    -- Add a modifier that does actual spell effect
    caster:AddNewModifier( caster, self, "modifier_sohei_flurry_self", {
      duration = delay + 0.1,
      damage = bonus_damage,
      flurry_radius = flurry_radius,
      --attack_interval = attack_interval,
    } )

    -- Give vision over the area
    AddFOWViewer(caster:GetTeamNumber(), target_loc, flurry_radius, delay + 0.1, false)
  end
end

function sohei_flurry_of_blows:GetAOERadius()
  local caster = self:GetCaster()

  return self:GetSpecialValueFor( "flurry_radius" ) + caster:FindTalentValue( "special_bonus_sohei_fob_radius" )
end

---------------------------------------------------------------------------------------------------

-- Flurry of Blows' self buff
modifier_sohei_flurry_self = class( ModifierBaseClass )

function modifier_sohei_flurry_self:IsDebuff()
  return false
end

function modifier_sohei_flurry_self:IsHidden()
  return true
end

function modifier_sohei_flurry_self:IsPurgable()
  return false
end

function modifier_sohei_flurry_self:IsStunDebuff()
  return false
end

function modifier_sohei_flurry_self:StatusEffectPriority()
  return 20
end

function modifier_sohei_flurry_self:GetStatusEffectName()
  return "particles/status_fx/status_effect_omnislash.vpcf"
end

function modifier_sohei_flurry_self:CheckState()
  local state = {
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    [MODIFIER_STATE_ROOTED] = true
  }

  return state
end

function modifier_sohei_flurry_self:OnIntervalThink()
  local caster = self:GetCaster()
  local ability = self:GetAbility()
  if IsServer() then
    -- Flurry of Blows actual spell effect - Hit everyone in a radius once at the same time
    local units = FindUnitsInRadius(
      caster:GetTeamNumber(),
      caster:GetAbsOrigin(),
      nil,
      self.radius,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
      bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, DOTA_UNIT_TARGET_FLAG_NO_INVIS, DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE),
      FIND_ANY_ORDER,
      false
    )

    local bUseProjectile = false
    if ability and ability:IsStolen() then
      bUseProjectile = true
    end

    for _,unit in pairs(units) do
      if unit and not unit:IsNull() and not caster:IsDisarmed() then
        caster:PerformAttack(unit, true, true, true, false, bUseProjectile, false, false)
      end
    end

    --caster:Interrupt()
    --caster:RemoveNoDraw()
    self:Destroy()
  end
end

function modifier_sohei_flurry_self:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
  }

  return funcs
end

function modifier_sohei_flurry_self:GetModifierBaseAttack_BonusDamage()
  return self.bonus_damage
end


function modifier_sohei_flurry_self:OnCreated( event )
  local parent = self:GetParent()
  self.bonus_damage = event.damage
	-- self.remaining_attacks = event.max_attacks
  self.radius = event.flurry_radius
  -- self.attack_interval = event.attack_interval
  -- self.position = self:GetCaster():GetAbsOrigin()
  -- self.positionGround = self.position - Vector( 0, 0, 200 )

  if IsServer() then
    local delay = event.duration - 0.1
    self:StartIntervalThink(delay)
  end

  -- if self:PerformFlurryBlow() then
    -- self.remaining_attacks = self.remaining_attacks - 1
  -- end
end

function modifier_sohei_flurry_self:OnDestroy()
  if IsServer() then
    local caster = self:GetCaster()
    ParticleManager:DestroyParticle( caster.flurry_ground_pfx, false )
    ParticleManager:ReleaseParticleIndex( caster.flurry_ground_pfx )
    caster.flurry_ground_pfx = nil
  end
end

--[[
  function modifier_sohei_flurry_self:OnIntervalThink()
    -- Give vision
    local parent = self:GetParent()
    AddFOWViewer(parent:GetTeam(), parent:GetOrigin(), self.radius, self.attack_interval, false)

    -- Attempt a strike
    if self:PerformFlurryBlow() then
      self.remaining_attacks = self.remaining_attacks - 1


      if self:GetParent():HasScepter() then
        self:SetDuration( self:GetRemainingTime() + self.attack_interval, true )
      end

    end

    -- If there are no strikes left, end
    if self.remaining_attacks <= 0 then
      self:Destroy()
    end
  end

  function modifier_sohei_flurry_self:PerformFlurryBlow()
    local parent = self:GetParent()

    -- If there is at least one target to attack, hit it
    local targets = FindUnitsInRadius(
      parent:GetTeamNumber(),
      self.positionGround,
      nil,
      self.radius,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      DOTA_UNIT_TARGET_HERO,
      bit.bor( DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, DOTA_UNIT_TARGET_FLAG_NO_INVIS, DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE ),
      FIND_ANY_ORDER,
      false
    )

    if targets[1] then
      local target = targets[1]
      local targetOrigin = target:GetAbsOrigin()
      local abilityDash = parent:FindAbilityByName( "sohei_dash" )
      local abilityMomentum = parent:FindAbilityByName( "sohei_momentum" )
      local distance = 50

      parent:RemoveNoDraw(  )

      if abilityDash then
        distance = abilityDash:GetSpecialValueFor( "dash_distance" ) + 50
      end

      local targetOffset = ( targetOrigin - self.positionGround ):Normalized() * distance
      local tickOrigin = targetOrigin + targetOffset

      parent:SetAbsOrigin( tickOrigin )
      parent:SetForwardVector( ( ( self.positionGround ) - tickOrigin ):Normalized() )
      parent:FaceTowards( targetOrigin )

      -- this stuff should probably be removed if we get actual animations
      -- just let the animations handle the movement
      if abilityDash and abilityDash:GetLevel() > 0 then
        abilityDash:PerformDash()
      end

      if abilityMomentum and abilityMomentum:GetLevel() > 0 then
        if not abilityMomentum:GetToggleState() then
          abilityMomentum:ToggleAbility()
        end
      end
      parent:PerformAttack( target, true, true, true, false, false, false, false)

      return true

    -- Else, return false and keep meditating
    else
      parent:AddNoDraw(  )
      parent:SetAbsOrigin( self.position )

      return false
    end
  end
]]
