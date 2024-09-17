broodmother_incapacitating_bite_oaa = class(AbilityBaseClass)

LinkLuaModifier("modifier_broodmother_incapacitating_bite_debuff_oaa", "abilities/oaa_broodmother_incapacitating_bite.lua", LUA_MODIFIER_MOTION_NONE)

---------------------------------------------------------------------------------------------------

function broodmother_incapacitating_bite_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()

  -- Create the projectile
  local info = {
    Target = target,
    Source = caster,
    Ability = self,
    EffectName = "particles/units/heroes/hero_broodmother/broodmother_web_cast.vpcf",
    bDodgeable = true,
    bProvidesVision = true,
    bVisibleToEnemies = true,
    bReplaceExisting = false,
    iMoveSpeed = self:GetSpecialValueFor("projectile_speed"),
    iVisionRadius = 250,
    iVisionTeamNumber = caster:GetTeamNumber(),
  }

  ProjectileManager:CreateTrackingProjectile(info)

  -- Cast Sound
  caster:EmitSound("Hero_Broodmother.SpawnSpiderlingsCast")
end

function broodmother_incapacitating_bite_oaa:OnProjectileHit(target, location)
  local caster = self:GetCaster()

  if not target or target:IsNull() then
    return
  end

  -- Impact Sound
  caster:EmitSound("Hero_Broodmother.SpawnSpiderlingsImpact")

  -- Don't do anything if target has Linken's effect or it's spell-immune
  if target:TriggerSpellAbsorb(self) or target:IsMagicImmune() then
    return
  end

  -- KV variables
  local duration = self:GetSpecialValueFor("duration")
  local base_damage = self:GetSpecialValueFor("base_damage")
  local max_hp_damage_percent = self:GetSpecialValueFor("max_hp_percent_dmg")

  -- Calculate duration (duration is affected by status resistance)
  local debuff_duration = target:GetValueChangedByStatusResistance(duration)

  -- Apply debuff
  target:AddNewModifier(caster, self, "modifier_broodmother_incapacitating_bite_debuff_oaa", {duration = debuff_duration})

  -- Get max health
  local target_max_health = target:GetMaxHealth()

  -- Do reduced damage to bosses
  if target:IsOAABoss() then
    max_hp_damage_percent = max_hp_damage_percent * (1 - BOSS_DMG_RED_FOR_PCT_SPELLS/100)
  end

  -- Calculate damage
  local actual_damage = base_damage + max_hp_damage_percent * target_max_health * 0.01

  local damage_table = {
    victim = target,
    attacker = caster,
    damage = actual_damage,
    damage_type = DAMAGE_TYPE_MAGICAL,
    damage_flags = DOTA_DAMAGE_FLAG_NONE,
    ability = self,
  }

  ApplyDamage(damage_table)
end

function broodmother_incapacitating_bite_oaa:IsStealable()
  return true
end

function broodmother_incapacitating_bite_oaa:ProcMagicStick()
  return true
end

---------------------------------------------------------------------------------------------------

modifier_broodmother_incapacitating_bite_debuff_oaa = class(ModifierBaseClass)

function modifier_broodmother_incapacitating_bite_debuff_oaa:IsHidden()
  return false
end

function modifier_broodmother_incapacitating_bite_debuff_oaa:IsDebuff()
  return true
end

function modifier_broodmother_incapacitating_bite_debuff_oaa:IsPurgable()
  return true
end

-- function modifier_broodmother_incapacitating_bite_debuff_oaa:DeclareFunctions()
  -- return {
    -- MODIFIER_PROPERTY_DISABLE_TURNING,
  -- }
-- end

-- function modifier_broodmother_incapacitating_bite_debuff_oaa:GetModifierDisableTurning()
  -- return 1
-- end

function modifier_broodmother_incapacitating_bite_debuff_oaa:CheckState()
  return {
    [MODIFIER_STATE_ROOTED] = true,
    [MODIFIER_STATE_DISARMED] = true,
    [MODIFIER_STATE_BLOCK_DISABLED] = true,
    [MODIFIER_STATE_EVADE_DISABLED] = true,
    [MODIFIER_STATE_FROZEN] = true,
  }
end

function modifier_broodmother_incapacitating_bite_debuff_oaa:GetEffectName()
  return "particles/units/heroes/hero_broodmother/broodmother_incapacitatingbite_debuff.vpcf"
end

function modifier_broodmother_incapacitating_bite_debuff_oaa:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end
