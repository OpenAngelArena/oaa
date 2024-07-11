LinkLuaModifier("modifier_boss_charger_charge", "abilities/boss/charger/boss_charger_charge.lua", LUA_MODIFIER_MOTION_NONE) --- BATHS HEAVY IMPORTED
LinkLuaModifier("modifier_boss_charger_pillar_debuff", "abilities/boss/charger/modifier_boss_charger_pillar_debuff.lua", LUA_MODIFIER_MOTION_NONE) --- PARTH WEVY IMPARTAYT
LinkLuaModifier("modifier_boss_charger_hero_pillar_debuff", "abilities/boss/charger/modifier_boss_charger_hero_pillar_debuff.lua", LUA_MODIFIER_MOTION_NONE) --- PITH YEVY IMPARTIAL
LinkLuaModifier("modifier_boss_charger_trampling", "abilities/boss/charger/modifier_boss_charger_trampling.lua", LUA_MODIFIER_MOTION_NONE) --- MARTH FAIRY IPARTY
LinkLuaModifier("modifier_boss_charger_glanced", "abilities/boss/charger/boss_charger_charge.lua", LUA_MODIFIER_MOTION_NONE)

boss_charger_charge = class(AbilityBaseClass)

function boss_charger_charge:OnSpellStart()
  self:GetCaster():EmitSound("Boss_Charger.Charge.Begin")
end

function boss_charger_charge:OnChannelFinish(interrupted)
  local caster = self:GetCaster()
  local cooldown = self:GetSpecialValueFor("cooldown")

  if interrupted then
    self:StartCooldown(cooldown / 2)
    caster:StopSound("Boss_Charger.Charge.Begin")
    return
  end
  self:StartCooldown(cooldown)

  caster:AddNewModifier(caster, self, "modifier_boss_charger_charge", {duration = self:GetSpecialValueFor("charge_duration")})

  caster:EmitSound("Boss_Charger.Charge.Movement")
end

function boss_charger_charge:OnOwnerDied()
  self:GetCaster():StopSound("Boss_Charger.Charge.Movement")
end

---------------------------------------------------------------------------------------------------

boss_charger_charge_tier5 = boss_charger_charge

---------------------------------------------------------------------------------------------------

modifier_boss_charger_charge = class(ModifierBaseClass)

function modifier_boss_charger_charge:IsHidden()
  return false
end

function modifier_boss_charger_charge:OnCreated()
  if not IsServer() then
    return
  end

  self.draggedHeroes = {}
  self.glanced = {}

  local ability = self:GetAbility()
  local cursorPosition = ability:GetCursorPosition()
  local caster = self:GetCaster()
  local origin = caster:GetAbsOrigin()
  local direction = (cursorPosition - origin):Normalized()

  direction.z = 0

  self.direction = direction
  self.distance_traveled = 0
  self.speed = ability:GetSpecialValueFor("speed")
  self.max_distance = ability:GetSpecialValueFor("distance")
  self.debuff_duration = ability:GetSpecialValueFor("debuff_duration")
  self.hero_stun_duration = ability:GetSpecialValueFor("hero_stun_duration")
  self.hero_pillar_damage = ability:GetSpecialValueFor("hero_pillar_damage")
  self.glancing_damage = ability:GetSpecialValueFor("glancing_damage")
  self.glancing_duration = ability:GetSpecialValueFor("glancing_duration")
  self.glancing_width = ability:GetSpecialValueFor("glancing_width")

  self:StartIntervalThink(0.01)
end

function modifier_boss_charger_charge:OnIntervalThink()
  if not IsServer() then
    return
  end

  local caster = self:GetCaster()
  local ability = self:GetAbility()

  if not caster or caster:IsNull() then
    self:StartIntervalThink(-1)
    self:Destroy()
    return
  end

  if self.distance_traveled >= self.max_distance then
    return self:EndCharge()
  end

  local origin = caster:GetAbsOrigin()
  caster:SetAbsOrigin(origin + (self.direction * self.speed))
  self.distance_traveled = self.distance_traveled + (self.direction * self.speed):Length2D()

  local glance_candidates = FindUnitsInRadius(
    caster:GetTeamNumber(),
    caster:GetAbsOrigin(),
    nil,
    self.glancing_width,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO),
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  for _, v in pairs(glance_candidates) do
    if v and not v:IsNull() then
      if not self.glanced[v:entindex()] then
        self.glanced[v:entindex()] = true

        if not v:IsMagicImmune() and not v:IsDebuffImmune() then
          -- Slow debuff
          v:AddNewModifier(caster, ability, "modifier_boss_charger_glanced", {duration = self.glancing_duration})

          -- Damage
          ApplyDamage({
            victim = v,
            attacker = caster,
            damage = self.glancing_damage,
            damage_type = DAMAGE_TYPE_PHYSICAL,
            damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_BLOCK,
            ability = ability
          })
        end
      end
    end
  end

  local units = FindUnitsInRadius(
    caster:GetTeamNumber(),
    caster:GetAbsOrigin(),
    nil,
    50,
    DOTA_UNIT_TARGET_TEAM_BOTH,
    bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO),
    bit.bor(DOTA_UNIT_TARGET_FLAG_INVULNERABLE, DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD),
    FIND_CLOSEST,
    false
  )

  local function isTower (tower)
    return tower:GetUnitName() == "npc_dota_boss_pillar_charger_oaa"
  end

  local function isValidTarget (unit)
    if unit:GetTeam() == caster:GetTeam() then
      return false
    end
    if unit.IsRealHero == nil then
      return false
    end
    if (unit:IsInvulnerable() or unit:IsOutOfGame()) and not isTower(unit) then
      return false
    end
    return true
  end

  local towers = filter(isTower, iter(units))
  local targets = filter(isValidTarget, iter(units))

  if targets:length() > 0 then
    targets:each(function (target)
      if not target:IsRealHero() then
        --target:Kill(ability, caster) -- crashes
        target:ForceKillOAA(false)
        return
      end
      if not target:HasModifier('modifier_boss_charger_trampling') then
        target:AddNewModifier(caster, ability, "modifier_boss_charger_trampling", {})
        table.insert(self.draggedHeroes, target)
        caster:EmitSound("Boss_Charger.Charge.HeroImpact")
      end
    end)
  end
  if towers:length() > 0 then
    -- we hit a tower!
    local tower = towers:head()
    --tower:Kill(ability, caster) -- crashes
    tower:ForceKillOAA(false)

    if #self.draggedHeroes > 0 then
      iter(self.draggedHeroes):each(function (hero)
        if not hero:IsMagicImmune() and not hero:IsDebuffImmune() then
          local actual_duration = hero:GetValueChangedByStatusResistance(self.hero_stun_duration)
          hero:AddNewModifier(caster, ability, "modifier_boss_charger_hero_pillar_debuff", {duration = actual_duration})

          ApplyDamage({
            victim = hero,
            attacker = caster,
            damage = self.hero_pillar_damage,
            damage_type = DAMAGE_TYPE_PHYSICAL,
            damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_BLOCK,
            ability = ability
          })
        end
      end)
    else
      caster:AddNewModifier(caster, caster:FindAbilityByName("boss_charger_super_armor"), "modifier_boss_charger_pillar_debuff", {duration = self.debuff_duration})
    end

    caster:EmitSound("Boss_Charger.Charge.TowerImpact")
    return self:EndCharge()
  end
end

function modifier_boss_charger_charge:EndCharge()
  local caster = self:GetCaster()

  --caster:InterruptMotionControllers(true) -- Charger boss is immune to motion controllers so this is not needed
  FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
  self:StartIntervalThink(-1)
  self:Destroy()
end

---------------------------------------------------------------------------------------------------

modifier_boss_charger_glanced = class(ModifierBaseClass)

function modifier_boss_charger_glanced:IsDebuff()
  return true
end

function modifier_boss_charger_glanced:IsPurgable()
  return true
end

function modifier_boss_charger_glanced:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
  }
end

function modifier_boss_charger_glanced:GetModifierMoveSpeedBonus_Percentage()
  if not self:GetAbility() then return end
  return self:GetAbility():GetSpecialValueFor("glancing_slow")
end
