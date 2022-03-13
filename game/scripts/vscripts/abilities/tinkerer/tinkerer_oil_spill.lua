LinkLuaModifier("modifier_tinkerer_oil_spill_thinker", "abilities/tinkerer/tinkerer_oil_spill.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tinkerer_oil_spill_debuff", "abilities/tinkerer/tinkerer_oil_spill.lua", LUA_MODIFIER_MOTION_NONE)

tinkerer_oil_spill = class({})

function tinkerer_oil_spill:GetAOERadius()
  return self:GetSpecialValueFor("ability_aoe")
end

function tinkerer_oil_spill:OnSpellStart()
  local caster = self:GetCaster()
  local cursor = self:GetCursorPosition()
  local team = caster:GetTeamNumber()
  local projectile_speed = self:GetSpecialValueFor("projectile_speed")

  local thinker = CreateModifierThinker(caster, self, "modifier_tinkerer_oil_spill_thinker", {duration = 5.0}, cursor, team, false)

  local projectile_table = {
    vSourceLoc = caster:GetAbsOrigin(),
    Target = thinker,
    iMoveSpeed = projectile_speed,
    --flExpireTime = GameRules:GetGameTime()+5.0,
    bDodgeable = false,
    bIsAttack = false,
    bReplaceExisting = false,
    bIgnoreObstructions = true,
    bDrawsOnMinimap = false,
    --bVisibleToEnemies = false,
    EffectName = ".vpcf",
    Ability = self,
    Source = caster,
    bProvidesVision = true,
    iVisionRadius = 100,
    iVisionTeamNumber = team,
  }

  ProjectileManager:CreateTrackingProjectile(projectile_table)

  caster:EmitSound("Hero_Shredder.TimberChain.Impact")
end

function tinkerer_oil_spill:OnProjectileHit(target,location)
  local caster = self:GetCaster()
  local team = caster:GetTeamNumber()

  local ability_aoe = self:GetSpecialValueFor("ability_aoe")
  local slow_duration = self:GetSpecialValueFor("slow_duration")

  local splat = ParticleManager:CreateParticle(".vpcf", PATTACH_ABSORIGIN, caster)

  local aboveground = GetGroundPosition(location,nil)
  ParticleManager:SetParticleControl(splat,0,aboveground)
  ParticleManager:ReleaseParticleIndex(splat)

  AddFOWViewer(team,location,ability_aoe,1.0,false)
  --DebugDrawCircle(location,Vector(255,0,0),1,ability_aoe,true,1.0)

  --oil near enemies
  local oiled_enemies = FindUnitsInRadius(
      team,
      location,
      nil,
      ability_aoe,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
      DOTA_UNIT_TARGET_FLAG_NONE,
      FIND_ANY_ORDER,
      false
  )

  -- Check for talent
  local talent_slow_duration = caster:FindAbilityByName("special_bonus_tinkerer_oil_spill_slow_duration")
  if talent_slow_duration and talent_slow_duration:GetLevel() > 0 then
    slow_duration = slow_duration + talent_slow_duration:GetSpecialValueFor("value")
  end

  --loop enemies
  for _, enemy in pairs(oiled_enemies) do
    if enemy and not enemy:IsNull() then
      enemy:AddNewModifier(caster, self, "modifier_tinkerer_oil_spill_debuff", {duration = slow_duration})
    end
  end

  target:EmitSound("Hero_Alchemist.AcidSpray.Damage")

  target:ForceKill(false)

  return true
end

---------------------------------------------------------------------------------------------------

modifier_tinkerer_oil_spill_thinker = class({})

function modifier_tinkerer_oil_spill_thinker:IsHidden()return true end

function modifier_tinkerer_oil_spill_thinker:IsPurgable() return false end

--function modifier_tinkerer_oil_spill_thinker:OnCreated( kv )

--end

function modifier_tinkerer_oil_spill_thinker:OnDestroy()
  if not IsServer() then
    return
  end
  local parent = self:GetParent()
  if self.particle then
    ParticleManager:DestroyParticle(self.particle, true)
    ParticleManager:ReleaseParticleIndex(self.particle)
  end
  if parent and not parent:IsNull() then
    parent:ForceKill(false)
  end
end

---------------------------------------------------------------------------------------------------

modifier_tinkerer_oil_spill_debuff = class({})

function modifier_tinkerer_oil_spill_debuff:IsHidden() return false end

function modifier_tinkerer_oil_spill_debuff:IsDebuff() return true end

function modifier_tinkerer_oil_spill_debuff:IsPurgable() return true end

--function modifier_tinkerer_oil_spill_debuff:GetStatusEffectName()
	--return "particles/status_fx/status_effect_stickynapalm.vpcf"
--end

function modifier_tinkerer_oil_spill_debuff:OnCreated( kv )
  self.talent_ms_as_bonus = 0
  local talent_slow_amount = self:GetCaster():FindAbilityByName("special_bonus_tinkerer_oil_spill_slow_amount")
  if not talent_slow_amount == false then
     self.talent_ms_as_bonus = talent_slow_amount:GetSpecialValueFor("value")
  end

  self.move_speed_percent = self:GetAbility():GetSpecialValueFor("move_speed_percent")+self.talent_ms_as_bonus
  self.attack_speed_percent = self:GetAbility():GetSpecialValueFor("attack_speed_percent")+self.talent_ms_as_bonus
  self.burn_dot = self:GetAbility():GetSpecialValueFor("burn_dot")
  self.oil_drip = ParticleManager:CreateParticle("particles/units/heroes/hero_batrider/batrider_stickynapalm_debuff.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
  self.is_burning = false
end

function modifier_tinkerer_oil_spill_debuff:DeclareFunctions()
    local dfuncs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE,
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_PROPERTY_TOOLTIP
    }
	return dfuncs
end

function modifier_tinkerer_oil_spill_debuff:GetModifierMoveSpeedBonus_Percentage()
    return -self.move_speed_percent
end

function modifier_tinkerer_oil_spill_debuff:GetModifierAttackSpeedPercentage()
    return -self.attack_speed_percent
end

function modifier_tinkerer_oil_spill_debuff:OnTakeDamage(event)
  if event.attacker ~= self:GetCaster() then return end

  if event.unit ~= self:GetParent() then return end

  if not event.inflictor then return end

  if event.inflictor:GetName() ~= "tinkerer_smart_missiles" then return end

  if self.is_burning == true then return end

  self.is_burning = true

  self.burning_particle = ParticleManager:CreateParticle(
      "particles/econ/items/huskar/huskar_2021_immortal/huskar_2021_immortal_burning_spear_debuff_flame_circulate.vpcf",
      PATTACH_ABSORIGIN_FOLLOW,
      self:GetParent()
  )

  self:OnIntervalThink()
  self:StartIntervalThink(1.0)
end

function modifier_tinkerer_oil_spill_debuff:OnIntervalThink()
    local burn_table = {
        victim = self:GetParent(),
        attacker = self:GetCaster(),
        damage = self.burn_dot,
        damage_type = DAMAGE_TYPE_MAGICAL,
        damage_flags = DOTA_DAMAGE_FLAG_NONE,
        ability = self:GetAbility()
    }
    ApplyDamage(burn_table)
end

function modifier_tinkerer_oil_spill_debuff:OnTooltip()
    return self.burn_dot
end

function modifier_tinkerer_oil_spill_debuff:OnDestroy()
  if self.oil_drip then
    ParticleManager:DestroyParticle(self.oil_drip,false)
    ParticleManager:ReleaseParticleIndex(self.oil_drip)
  end

  if self.burning_particle then
    ParticleManager:DestroyParticle(self.burning_particle,false)
    ParticleManager:ReleaseParticleIndex(self.burning_particle)
  end
end
