LinkLuaModifier("modifier_roshan_bash_oaa", "modifiers/funmodifiers/modifier_roshan_power_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_spell_block_cooldown_oaa", "modifiers/funmodifiers/modifier_spell_block_oaa.lua", LUA_MODIFIER_MOTION_NONE)

-- Roshan's Body

modifier_roshan_power_oaa = class(ModifierBaseClass)

function modifier_roshan_power_oaa:IsHidden()
  return false
end

function modifier_roshan_power_oaa:IsDebuff()
  return false
end

function modifier_roshan_power_oaa:IsPurgable()
  return false
end

function modifier_roshan_power_oaa:RemoveOnDeath()
  return false
end

function modifier_roshan_power_oaa:OnCreated()
  self.move_speed_override = 270
  self.spell_block_cd = 15
  self.bash_chance = 15
  self.bash_duration = 1.65
  self.bash_damage = 50
  self.status_resist = 25
  --self.magic_resist = 55
  self.dmg_per_minute = 6
end

function modifier_roshan_power_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BASE_OVERRIDE,
    MODIFIER_PROPERTY_MODEL_CHANGE,
    MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_MAGICAL,
    MODIFIER_PROPERTY_ABSORB_SPELL,
    MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
    --MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
  }
end

function modifier_roshan_power_oaa:GetModifierMoveSpeedOverride()
  return self.move_speed_override
end

function modifier_roshan_power_oaa:GetModifierModelChange()
  return "models/creeps/roshan/roshan.vmdl"
end

function modifier_roshan_power_oaa:GetModifierStatusResistanceStacking()
  return self.status_resist
end

--function modifier_roshan_power_oaa:GetModifierMagicalResistanceBonus()
  --return self.magic_resist
--end

function modifier_roshan_power_oaa:GetModifierPreAttack_BonusDamage()
  return math.max(self.dmg_per_minute, self.dmg_per_minute * math.floor(GameRules:GetGameTime() / 60))
end

if IsServer() then
  function modifier_roshan_power_oaa:GetModifierProcAttack_BonusDamage_Magical(event)
    local parent = self:GetParent()

    if parent:IsIllusion() then
      return 0
    end

    local target = event.target

    -- can't bash towers or wards, but can bash allies
    if UnitFilter(target, DOTA_UNIT_TARGET_TEAM_BOTH, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, parent:GetTeamNumber()) ~= UF_SUCCESS then
      return 0
    end

    local chance = self.bash_chance

    if RandomInt(1, 100) <= chance then
      local duration = self.bash_duration
      local damage = self.bash_damage

      duration = target:GetValueChangedByStatusResistance(duration)

      target:AddNewModifier(parent, nil, "modifier_roshan_bash_oaa", {duration = duration})

      target:EmitSound("Roshan.Bash")

      return damage
    end
    return 0
  end

  function modifier_roshan_power_oaa:GetAbsorbSpell(event)
    local parent = self:GetParent()
    local casted_ability = event.ability

    if not casted_ability or casted_ability:IsNull() then
      return 0
    end

    local caster = casted_ability:GetCaster()

    -- Don't block allied spells
    if caster:GetTeamNumber() == parent:GetTeamNumber() then
      return 0
    end

    -- No need to block if parent is invulnerable
    if parent:IsInvulnerable() or parent:IsOutOfGame() then
      return 0
    end

    -- Don't block if on cooldown
    if parent:HasModifier("modifier_spell_block_cooldown_oaa") then
      return 0
    end

    local cooldown = self.spell_block_cd

    -- Sound
    parent:EmitSound("DOTA_Item.LinkensSphere.Activate")

    -- Particle
    local pfx = ParticleManager:CreateParticle("particles/items_fx/immunity_sphere.vpcf", PATTACH_POINT_FOLLOW, parent)
    ParticleManager:SetParticleControlEnt(pfx, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
    ParticleManager:ReleaseParticleIndex(pfx)

    -- Start cooldown by adding a modifier
    parent:AddNewModifier(parent, nil, "modifier_spell_block_cooldown_oaa", {duration = cooldown})

    return 1
  end
end

function modifier_roshan_power_oaa:GetTexture()
  return "roshan_bash"
end

---------------------------------------------------------------------------------------------------

modifier_roshan_bash_oaa = class(ModifierBaseClass)

function modifier_roshan_bash_oaa:IsHidden()
  return false
end

function modifier_roshan_bash_oaa:IsDebuff()
  return true
end

function modifier_roshan_bash_oaa:IsStunDebuff()
  return true
end

function modifier_roshan_bash_oaa:IsPurgable()
  return true
end

function modifier_roshan_bash_oaa:GetEffectName()
  return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_roshan_bash_oaa:GetEffectAttachType()
  return PATTACH_OVERHEAD_FOLLOW
end

function modifier_roshan_bash_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
  }
end

function modifier_roshan_bash_oaa:GetOverrideAnimation()
  return ACT_DOTA_DISABLED
end

function modifier_roshan_bash_oaa:CheckState()
  return {
    [MODIFIER_STATE_STUNNED] = true,
  }
end

function modifier_roshan_bash_oaa:GetTexture()
  return "roshan_bash"
end
