LinkLuaModifier( "modifier_boss_acid_spray_thinker", "abilities/boss/alchemist/boss_alchemist_acid_spray.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_boss_acid_spray_debuff", "abilities/boss/alchemist/boss_alchemist_acid_spray.lua", LUA_MODIFIER_MOTION_NONE )

boss_alchemist_acid_spray = class(AbilityBaseClass)

function boss_alchemist_acid_spray:Precache(context)
  PrecacheResource("particle", "particles/units/heroes/hero_alchemist/alchemist_acid_spray.vpcf", context)
  PrecacheResource("particle", "particles/units/heroes/hero_ogre_magi/ogre_magi_ignite.vpcf", context)
  PrecacheResource("particle", "particles/units/heroes/hero_ogre_magi/ogre_magi_ignite_debuff.vpcf", context)
  --PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_alchemist.vsndevts", context)
  PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_ogre_magi.vsndevts", context)
end

function boss_alchemist_acid_spray:OnSpellStart()
  local caster = self:GetCaster()
  local mainTarget = self:GetCursorPosition()
  local vTargetPositions = {}
  if not mainTarget then
    return
  end
  table.insert(vTargetPositions, mainTarget + RandomVector( RandomFloat( 250, 300 ) ))
  table.insert(vTargetPositions, mainTarget + RandomVector( RandomFloat( 250, 300 ) ))
  if self.target_points then
    for _, target in pairs(self.target_points) do
      if target then
        table.insert(vTargetPositions, target)
      end
    end
  else
    table.insert(vTargetPositions, mainTarget)
  end

  self.hThinkers = {}

  for i, vTargetPos in ipairs( vTargetPositions ) do
    self.hThinkers[ i ] = CreateModifierThinker( caster, self, "modifier_boss_acid_spray_thinker", { duration = -1 }, vTargetPos, caster:GetTeamNumber(), false )
    if self.hThinkers[ i ] then
      local projectile =
      {
        Target = self.hThinkers[ i ],
        Source = caster,
        Ability = self,
        EffectName = "particles/units/heroes/hero_ogre_magi/ogre_magi_ignite.vpcf",
        iMoveSpeed = self:GetSpecialValueFor( "projectile_speed" ),
        vSourceLoc = caster:GetOrigin(),
        bDodgeable = false,
        bProvidesVision = false,
      }

      ProjectileManager:CreateTrackingProjectile( projectile )
      caster:EmitSound("OgreMagi.Ignite.Cast")
    end
  end
end

function boss_alchemist_acid_spray:OnProjectileHit( hTarget, vLocation )
  for _, hThinker in pairs( self.hThinkers ) do
    if hThinker and not hThinker:IsNull() then
      local hBuff = hThinker:FindModifierByName( "modifier_boss_acid_spray_thinker" )
      if hBuff ~= nil then
        hBuff:OnIntervalThink()
      end
    end
  end

  return true
end

---------------------------------------------------------------------------------------------------

modifier_boss_acid_spray_thinker = class( ModifierBaseClass )

function modifier_boss_acid_spray_thinker:OnCreated( kv )
	if IsServer() then
		self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
		self.area_duration = self:GetAbility():GetSpecialValueFor( "area_duration" )
		self.duration = self:GetAbility():GetSpecialValueFor( "duration" )
		self.bImpact = false
	end
end

function modifier_boss_acid_spray_thinker:OnImpact()
  if IsServer() then
    local parent = self:GetParent()
    local nFXIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_alchemist/alchemist_acid_spray.vpcf", PATTACH_WORLDORIGIN, nil ) --PATTACH_POINT_FOLLOW
    ParticleManager:SetParticleControl(nFXIndex, 0, parent:GetOrigin())
    --ParticleManager:SetParticleControl(nFXIndex, 0, Vector(0, 0, 0))
    ParticleManager:SetParticleControl(nFXIndex, 1, Vector(self.radius, 1, 1))
    ParticleManager:SetParticleControl(nFXIndex, 15, Vector(25, 150, 25))
    ParticleManager:SetParticleControl(nFXIndex, 16, Vector(0, 0, 0))
    --ParticleManager:ReleaseParticleIndex( nFXIndex )

    self.particle = nFXIndex

    parent:EmitSound("OgreMagi.Ignite.Target")

    self:SetDuration( self.area_duration, true )
    self.bImpact = true

    self:StartIntervalThink( 0.5 )
  end
end

function modifier_boss_acid_spray_thinker:OnIntervalThink()
  if IsServer() then
    if self.bImpact == false then
      self:OnImpact()
      return
    end

    local parent = self:GetParent()
    local enemies = FindUnitsInRadius(
      parent:GetTeamNumber(),
      parent:GetOrigin(),
      nil,
      self.radius,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
      DOTA_UNIT_TARGET_FLAG_NONE,
      FIND_ANY_ORDER,
      false
    )
    for _, enemy in pairs( enemies ) do
      if enemy and not enemy:IsNull() and not enemy:IsMagicImmune() and not enemy:IsDebuffImmune() then
        enemy:AddNewModifier( parent, self:GetAbility(), "modifier_boss_acid_spray_debuff", { duration = self.duration } )
      end
    end
  end
end

function modifier_boss_acid_spray_thinker:OnDestroy()
  if not IsServer() then
    return
  end
  local parent = self:GetParent()
  if self.particle then
    ParticleManager:DestroyParticle(self.particle, true)
    ParticleManager:ReleaseParticleIndex(self.particle)
  end
  if parent and not parent:IsNull() then
    parent:ForceKillOAA(false)
  end
end

----------------------------------------------------------------------------------------

modifier_boss_acid_spray_debuff = class(ModifierBaseClass)

function modifier_boss_acid_spray_debuff:IsHidden()
  return false
end

function modifier_boss_acid_spray_debuff:IsPurgable()
  return true
end

function modifier_boss_acid_spray_debuff:IsDebuff()
  return true
end

function modifier_boss_acid_spray_debuff:DestroyOnExpire()
  return true
end

function modifier_boss_acid_spray_debuff:OnCreated()
  local damage_per_second = 275
  local interval = 0.2
  local damage_type = DAMAGE_TYPE_PURE
  local slow = -30
  local armor = -15
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    damage_per_second = ability:GetSpecialValueFor("damage_per_second")
    interval = ability:GetSpecialValueFor("damage_interval")
    slow = ability:GetSpecialValueFor("slow_movement_speed_pct")
    armor = ability:GetSpecialValueFor("armor_reduction")
    if IsServer() then
      damage_type = ability:GetAbilityDamageType()
    end
  end
  self.damage_per_interval = damage_per_second*interval
  self.slow = slow
  self.armor = armor
  self.damage_type = damage_type
  if IsServer() then
    self:OnIntervalThink()
    self:StartIntervalThink(interval)
  end
end

function modifier_boss_acid_spray_debuff:OnIntervalThink()
  local parent = self:GetParent()
  local caster = self:GetCaster()
  local ability = self:GetAbility()
  if caster and not caster:IsNull() then
    -- Creating the damage table
    local damage_table = {
      attacker = caster,
      victim = parent,
      damage = self.damage_per_interval,
      damage_type = self.damage_type,
      ability = ability,
    }
    -- Apply damage on interval
    ApplyDamage(damage_table)
  end
end

function modifier_boss_acid_spray_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
  }
end

function modifier_boss_acid_spray_debuff:GetModifierMoveSpeedBonus_Percentage()
  return 0 - math.abs(self.slow)
end

function modifier_boss_acid_spray_debuff:GetModifierPhysicalArmorBonus()
  return 0 - math.abs(self.armor)
end

function modifier_boss_acid_spray_debuff:GetTexture()
  return "alchemist_acid_spray"
end

function modifier_boss_acid_spray_debuff:GetEffectName()
  return "particles/units/heroes/hero_ogre_magi/ogre_magi_ignite_debuff.vpcf"
end
