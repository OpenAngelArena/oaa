LinkLuaModifier("modifier_boss_spooky_ghost_ethereal_buff", "abilities/boss/spooky_ghost/boss_spooky_ghost_ethereal.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_spooky_ghost_silence_debuff", "abilities/boss/spooky_ghost/boss_spooky_ghost_ethereal.lua", LUA_MODIFIER_MOTION_NONE)

boss_spooky_ghost_ethereal = class(AbilityBaseClass)

function boss_spooky_ghost_ethereal:OnSpellStart()
  local caster = self:GetCaster()

  -- Apply Basic Dispel
  caster:Purge(false, true, false, false, false)

  -- Apply buff
  caster:AddNewModifier(caster, self, "modifier_boss_spooky_ghost_ethereal_buff", {duration = self:GetSpecialValueFor("ethereal_duration")})

  -- Sound
  caster:EmitSound("DOTA_Item.GhostScepter.Activate")
end

---------------------------------------------------------------------------------------------------

modifier_boss_spooky_ghost_ethereal_buff = class(ModifierBaseClass)

function modifier_boss_spooky_ghost_ethereal_buff:IsHidden()
  return false
end

function modifier_boss_spooky_ghost_ethereal_buff:IsDebuff()
  return false
end

function modifier_boss_spooky_ghost_ethereal_buff:IsPurgable()
  return true
end

function modifier_boss_spooky_ghost_ethereal_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    MODIFIER_EVENT_ON_TAKEDAMAGE,
  }
end

function modifier_boss_spooky_ghost_ethereal_buff:GetAbsoluteNoDamagePhysical()
  return 1
end

if IsServer() then
  function modifier_boss_spooky_ghost_ethereal_buff:OnTakeDamage(event)
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local attacker = event.attacker
    local damaged_unit = event.unit

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if damaged entity exists
    if not damaged_unit or damaged_unit:IsNull() then
      return
    end

    -- Check if damaged unit has this buff
    if damaged_unit ~= parent then
      return
    end

    -- Ignore physical damage and attacks
    if event.damage_type == DAMAGE_TYPE_PHYSICAL or event.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK then
      return
    end

    -- Ignore items
    local inflictor = event.inflictor
    if inflictor and not inflictor:IsNull() then
      if inflictor:IsItem() then
        return
      end
    end

    -- If unit is dead, spell immune, invulnerable, banished, a ward, tower or in a duel don't do anything
    if not attacker:IsAlive() or attacker:IsMagicImmune() or attacker:IsTower() or attacker:IsOther() or attacker:IsInvulnerable() or attacker:IsOutOfGame() or Duels:IsActive() then
      return
    end

    -- Apply debuff
    local actual_duration = attacker:GetValueChangedByStatusResistance(ability:GetSpecialValueFor("silence_duration"))
    attacker:AddNewModifier(parent, ability, "modifier_boss_spooky_ghost_silence_debuff", {duration = actual_duration})
  end
end

function modifier_boss_spooky_ghost_ethereal_buff:CheckState()
  return {
    [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_DISARMED] = true
  }
end

function modifier_boss_spooky_ghost_ethereal_buff:GetStatusEffectName()
  return "particles/status_fx/status_effect_ghost.vpcf"
end

function modifier_boss_spooky_ghost_ethereal_buff:StatusEffectPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA
end

---------------------------------------------------------------------------------------------------

modifier_boss_spooky_ghost_silence_debuff = class(ModifierBaseClass)

function modifier_boss_spooky_ghost_silence_debuff:IsHidden()
  return false
end

function modifier_boss_spooky_ghost_silence_debuff:IsDebuff()
  return true
end

function modifier_boss_spooky_ghost_silence_debuff:IsPurgable()
  return true
end

function modifier_boss_spooky_ghost_silence_debuff:CheckState()
  return {
    [MODIFIER_STATE_SILENCED] = true,
  }
end

function modifier_boss_spooky_ghost_silence_debuff:GetEffectName()
  return "particles/generic_gameplay/generic_silenced.vpcf"
end

function modifier_boss_spooky_ghost_silence_debuff:GetEffectAttachType()
  return PATTACH_OVERHEAD_FOLLOW
end
