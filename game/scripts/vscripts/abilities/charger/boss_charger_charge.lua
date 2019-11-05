require('libraries/timers')

LinkLuaModifier("modifier_boss_charger_charge", "abilities/charger/boss_charger_charge.lua", LUA_MODIFIER_MOTION_BOTH) --- BATHS HEAVY IMPORTED
LinkLuaModifier("modifier_boss_charger_pillar_debuff", "abilities/charger/modifier_boss_charger_pillar_debuff.lua", LUA_MODIFIER_MOTION_NONE) --- PARTH WEVY IMPARTAYT
LinkLuaModifier("modifier_boss_charger_hero_pillar_debuff", "abilities/charger/modifier_boss_charger_hero_pillar_debuff.lua", LUA_MODIFIER_MOTION_NONE) --- PITH YEVY IMPARTIAL
LinkLuaModifier("modifier_boss_charger_trampling", "abilities/charger/modifier_boss_charger_trampling.lua", LUA_MODIFIER_MOTION_BOTH) --- MARTH FAIRY IPARTY

boss_charger_charge = class(AbilityBaseClass)

function boss_charger_charge:OnSpellStart()
  self:GetCaster():EmitSound("Boss_Charger.Charge.Begin")
end

function boss_charger_charge:OnChannelFinish(interrupted) --You misspelled "Interrupted"
  local caster = self:GetCaster()
  if interrupted then
    self:StartCooldown(self:GetSpecialValueFor("cooldown") / 2)
    caster:StopSound("Boss_Charger.Charge.Begin")
    return
  end
  self:StartCooldown(self:GetSpecialValueFor("cooldown"))

  caster:AddNewModifier(caster, self, "modifier_boss_charger_charge", {
    duration = self:GetSpecialValueFor( "charge_duration" )
  })

  caster:EmitSound("Boss_Charger.Charge.Movement")

  return true
end

function boss_charger_charge:OnOwnerDied()
  self:GetCaster():StopSound("Boss_Charger.Charge.Movement")
end

--------------------------------------------------------------------------------

modifier_boss_charger_charge = class(ModifierBaseClass)

function modifier_boss_charger_charge:IsHidden()
  return false
end

function modifier_boss_charger_charge:OnIntervalThink()
  if not IsServer() then
    return
  end

  local caster = self:GetCaster()

  if self.distance_traveled >= self.max_distance then
    return self:EndCharge()
  end

  local origin = caster:GetAbsOrigin()
  caster:SetAbsOrigin(origin + (self.direction * self.speed))
  self.distance_traveled = self.distance_traveled + (self.direction * self.speed):Length2D()

  -- FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, creepSearchRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, FIND_ANY_ORDER, false)
  local units = FindUnitsInRadius(
    caster:GetTeamNumber(),
    caster:GetAbsOrigin(),
    nil,
    50,
    DOTA_UNIT_TARGET_TEAM_BOTH,
    bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO),
    DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
    FIND_CLOSEST,
    false
  )

  local function isTower (tower)
    return tower:GetUnitName() == "npc_dota_boss_charger_pillar"
  end

  local function isHero (hero)
    -- intentionally don't call it, i just want to make sure it has the method
    -- we're gonna blow up the non-heroes with charge because fuck your shit PA
    if hero:GetTeam() == caster:GetTeam() then
      return false
    end
    if hero.IsRealHero == nil then
      return false
    end
    return true
  end

  local towers = filter(isTower, iter(units))
  local heroes = filter(isHero, iter(units))

  if heroes:length() > 0 then
    heroes:each(function (hero)
      if not hero:IsRealHero() then
        hero:Kill(self:GetAbility(), caster)
        return
      end
      if not hero:HasModifier('modifier_boss_charger_trampling') then
        hero:AddNewModifier(caster, self:GetAbility(), "modifier_boss_charger_trampling", {})
        table.insert(self.draggedHeroes, hero)
        caster:EmitSound("Boss_Charger.Charge.HeroImpact")
      end
    end)
  end
  if towers:length() > 0 then
    -- we hit a tower!
    local tower = towers:head()
    tower:Kill(self:GetAbility(), caster)

    if #self.draggedHeroes > 0 then
      iter(self.draggedHeroes):each(function (hero)
        hero:AddNewModifier(caster, self:GetAbility(), "modifier_boss_charger_hero_pillar_debuff", {
          duration = self.hero_stun_duration
        })

        ApplyDamage({
          victim = hero,
          attacker = caster,
          damage = self.hero_pillar_damage,
          damage_type = DAMAGE_TYPE_PHYSICAL,
          damage_flags = DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS,
          ability = self:GetAbility()
        })
      end)
    else
      caster:AddNewModifier(caster, caster:FindAbilityByName("boss_charger_super_armor"), "modifier_boss_charger_pillar_debuff", {
        duration = self.debuff_duration
      })
    end

    caster:EmitSound("Boss_Charger.Charge.TowerImpact")
    return self:EndCharge()
  end
end

function modifier_boss_charger_charge:EndCharge()
  local caster = self:GetCaster()

  caster:InterruptMotionControllers(true)
  FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
  self:StartIntervalThink(-1)
  self:Destroy()
  return 0
end

function modifier_boss_charger_charge:OnCreated(keys)
  if not IsServer() then
    return
  end

  self.draggedHeroes = {}

  local ability = self:GetAbility()
  local cursorPosition = ability:GetCursorPosition()
  local caster = self:GetCaster()
  local origin = caster:GetAbsOrigin()
  local direction = (cursorPosition - origin):Normalized()

  direction.z = 0

  self.direction = direction
  self.speed = ability:GetSpecialValueFor( "speed" )
  self.distance_traveled = 0
  self.max_distance = ability:GetSpecialValueFor( "distance" )
  self.debuff_duration = ability:GetSpecialValueFor( "debuff_duration" )
  self.debuff_duration = ability:GetSpecialValueFor( "debuff_duration" )
  self.hero_stun_duration = ability:GetSpecialValueFor( "hero_stun_duration" )
  self.hero_pillar_damage = ability:GetSpecialValueFor( "hero_pillar_damage" )
  self.glancing_damage = ability:GetSpecialValueFor( "glancing_damage" )
  self.glancing_slow = ability:GetSpecialValueFor( "glancing_slow" )
  self.glancing_duration = ability:GetSpecialValueFor( "glancing_duration" )
  self.glancing_knockback = ability:GetSpecialValueFor( "glancing_knockback" )

  self:StartIntervalThink(0.01)
end
