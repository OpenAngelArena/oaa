-- Astral Worldsmith

LinkLuaModifier("modifier_elder_titan_innate_oaa", "abilities/oaa_elder_titan_innate.lua", LUA_MODIFIER_MOTION_NONE)

elder_titan_innate_oaa = class(AbilityBaseClass)

function elder_titan_innate_oaa:GetIntrinsicModifierName()
  return "modifier_elder_titan_innate_oaa"
end

---------------------------------------------------------------------------------------------------

modifier_elder_titan_innate_oaa = class(ModifierBaseClass)

function modifier_elder_titan_innate_oaa:IsHidden()
  return true
end

function modifier_elder_titan_innate_oaa:IsDebuff()
  return false
end

function modifier_elder_titan_innate_oaa:IsPurgable()
  return false
end

function modifier_elder_titan_innate_oaa:RemoveOnDeath()
  return false
end

function modifier_elder_titan_innate_oaa:OnCreated()
  local ability = self:GetAbility()
  self.dmg_per_strength = ability:GetSpecialValueFor("dmg_per_strength")
  self.base_dmg_penalty_per_strength = ability:GetSpecialValueFor("base_dmg_penalty_per_strength") / 100
end

function modifier_elder_titan_innate_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

function modifier_elder_titan_innate_oaa:GetModifierBaseAttack_BonusDamage()
  local parent = self:GetParent()
  local dmg_penalty = self.base_dmg_penalty_per_strength * parent:GetStrength()
  return 0 - math.abs(dmg_penalty)
end

if IsServer() then
  function modifier_elder_titan_innate_oaa:OnAttackLanded(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local target = event.target

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if attacker ~= parent then
      return
    end

    -- Check if attacker is dead or silenced
    if not parent:IsAlive() then
      return
    end

    -- Don't do anything if broken or if an illusion
    if parent:PassivesDisabled() or parent:IsIllusion() then
      return
    end

    -- Check if attacked unit exists
    if not target or target:IsNull() then
      return
    end

    -- Check for existence of GetUnitName method to determine if target is a unit or an item (or rune)
    -- items don't have that method -> nil; if the target is an item, don't continue
    if target.GetUnitName == nil then
      return
    end

    -- No need to proc if target is invulnerable, spell immune or dead
    if target:IsInvulnerable() or target:IsOutOfGame() or not target:IsAlive() or target:IsMagicImmune() then
      return
    end

    local dmg_per_strength = self.dmg_per_strength
    local strength = parent:GetStrength()
    local bonus_dmg_on_attack = strength * dmg_per_strength

    local damage_table = {
      attacker = parent,
      victim = target,
      damage = bonus_dmg_on_attack,
      damage_type = DAMAGE_TYPE_MAGICAL,
      damage_flags = DOTA_DAMAGE_FLAG_NONE,
      ability = self:GetAbility(),
    }

    ApplyDamage(damage_table)
  end
end

-- function modifier_elder_titan_innate_oaa:CheckState()
  -- return {
    -- [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
  -- }
-- end
