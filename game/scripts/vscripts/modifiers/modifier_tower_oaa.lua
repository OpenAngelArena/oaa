modifier_tower_oaa = class({})

function modifier_tower_oaa:IsHidden()
  return true
end

function modifier_tower_oaa:IsPurgable()
  return false
end

function modifier_tower_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
    MODIFIER_PROPERTY_FIXED_DAY_VISION,
    MODIFIER_PROPERTY_FIXED_NIGHT_VISION,
    --MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
    --MODIFIER_EVENT_ON_ATTACK_START,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

function modifier_tower_oaa:GetAbsoluteNoDamagePhysical()
  return 1
end

function modifier_tower_oaa:GetAbsoluteNoDamageMagical()
  return 1
end

function modifier_tower_oaa:GetAbsoluteNoDamagePure()
  return 1
end

function modifier_tower_oaa:GetFixedDayVision()
  return 900
end

function modifier_tower_oaa:GetFixedNightVision()
  return 900
end

--function modifier_tower_oaa:GetOverrideAnimation()
  --return ACT_DOTA_CUSTOM_TOWER_IDLE -- does not work
--end

function modifier_tower_oaa:CheckState()
  return {
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    --[MODIFIER_STATE_OUT_OF_GAME] = true,
    --[MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_FORCED_FLYING_VISION] = true,
  }
end

if IsServer() then
  function modifier_tower_oaa:OnAttackStart(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    if not attacker or attacker:IsNull() then
      return
    end
    if attacker ~= parent then
      return
    end
    if parent:GetUnitName() ~= "npc_dota_badguys_tower3_mid" then
      return
    end

    --parent:StartGestureWithPlaybackRate(ACT_DOTA_CUSTOM_TOWER_ATTACK, parent:GetAttacksPerSecond(false)) -- does not work
  end

  function modifier_tower_oaa:OnAttackLanded(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local target = event.target

    if not attacker or attacker:IsNull() then
      return
    end
    if not target or target:IsNull() then
      return
    end
    if attacker ~= parent then
      return
    end
    if not HudTimer then
      return
    end
    local game_time = HudTimer:GetGameTime()
    if game_time < 600 then -- 10 minutes
      return
    end
    if target.GetMaxHealth == nil then
      return
    end
    if not target:IsAlive() then
      return
    end
    local max_hp = target:GetMaxHealth()
    local max_hp_dmg = 2.5 * max_hp * 0.01 -- 2.5% of max hp

    local dmg_type = DAMAGE_TYPE_PURE
    local dmg_flags = bit.bor(DOTA_DAMAGE_FLAG_HPLOSS, DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS, DOTA_DAMAGE_FLAG_REFLECTION, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION)

    if target:IsDebuffImmune() then
      dmg_type = DAMAGE_TYPE_MAGICAL
      dmg_flags = bit.bor(DOTA_DAMAGE_FLAG_HPLOSS, DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_IGNORES_MAGIC_ARMOR)
    end

    local damage_table = {
      victim = target,
      attacker = parent,
      damage = max_hp_dmg,
      damage_type = dmg_type,
      damage_flags = dmg_flags,
    }

    ApplyDamage(damage_table)
  end
end
