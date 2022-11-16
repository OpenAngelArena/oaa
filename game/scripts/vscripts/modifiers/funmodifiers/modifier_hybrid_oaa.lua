LinkLuaModifier("modifier_hybrid_dmg_stack_oaa", "modifiers/funmodifiers/modifier_hybrid_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hybrid_spell_amp_stack_oaa", "modifiers/funmodifiers/modifier_hybrid_oaa.lua", LUA_MODIFIER_MOTION_NONE)

modifier_hybrid_oaa = class(ModifierBaseClass)

function modifier_hybrid_oaa:IsHidden()
  return false
end

function modifier_hybrid_oaa:IsDebuff()
  return false
end

function modifier_hybrid_oaa:IsPurgable()
  return false
end

function modifier_hybrid_oaa:RemoveOnDeath()
  return false
end

function modifier_hybrid_oaa:OnCreated()
  self.duration = 5
end

function modifier_hybrid_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
    MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
  }
end

if IsServer() then
  function modifier_hybrid_oaa:OnAttackLanded(event)
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

    -- Check if attacked unit exists
    if not target or target:IsNull() then
      return
    end

    -- Check for existence of GetUnitName method to determine if target is a unit or an item (or rune)
    -- items don't have that method -> nil; if the target is an item, don't continue
    if target.GetUnitName == nil then
      return
    end

    -- No need to proc if target is invulnerable or dead
    if target:IsInvulnerable() or target:IsOutOfGame() or not target:IsAlive() then
      return
    end

    parent:AddNewModifier(parent, nil, "modifier_hybrid_spell_amp_stack_oaa", {duration = self.duration})
  end

  function modifier_hybrid_oaa:OnAbilityFullyCast(event)
    local parent = self:GetParent()
    local unit = event.unit
    local ability = event.ability

    -- Check if caster unit exists
    if not unit or unit:IsNull() then
      return
    end

    -- Check if caster unit has this modifier
    if unit ~= parent then
      return
    end

    -- Check if caster is alive
    if not parent:IsAlive() then
      return
    end

    -- Check if used ability exists
    if not ability or ability:IsNull() then
      return
    end

    -- Check if ability is an item
    if ability:IsItem() then
      return
    end

    parent:AddNewModifier(parent, nil, "modifier_hybrid_dmg_stack_oaa", {duration = self.duration})
  end
end

function modifier_hybrid_oaa:GetTexture()
  return "custom/elixier_hybrid_2"
end

---------------------------------------------------------------------------------------------------

modifier_hybrid_dmg_stack_oaa = class(ModifierBaseClass)

function modifier_hybrid_dmg_stack_oaa:IsHidden()
  return true
end

function modifier_hybrid_dmg_stack_oaa:IsDebuff()
  return false
end

function modifier_hybrid_dmg_stack_oaa:IsPurgable()
  return false
end

function modifier_hybrid_dmg_stack_oaa:RemoveOnDeath()
  return true
end

function modifier_hybrid_dmg_stack_oaa:OnCreated()
  self.dmg_per_stack = 40

  if IsServer() then
    self:SetStackCount(1)
  end
end

function modifier_hybrid_dmg_stack_oaa:OnRefresh()
  self.dmg_per_stack = 40

  if IsServer() then
    self:IncrementStackCount()
  end
end

function modifier_hybrid_dmg_stack_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
  }
end

function modifier_hybrid_dmg_stack_oaa:GetModifierPreAttack_BonusDamage()
  return self:GetStackCount() * self.dmg_per_stack
end

---------------------------------------------------------------------------------------------------

modifier_hybrid_spell_amp_stack_oaa = class(ModifierBaseClass)

function modifier_hybrid_spell_amp_stack_oaa:IsHidden()
  return true
end

function modifier_hybrid_spell_amp_stack_oaa:IsDebuff()
  return false
end

function modifier_hybrid_spell_amp_stack_oaa:IsPurgable()
  return false
end

function modifier_hybrid_spell_amp_stack_oaa:RemoveOnDeath()
  return true
end

function modifier_hybrid_spell_amp_stack_oaa:OnCreated()
  self.spell_amp_per_stack = 2

  if IsServer() then
    self:SetStackCount(1)
  end
end

function modifier_hybrid_spell_amp_stack_oaa:OnRefresh()
  self.spell_amp_per_stack = 2

  if IsServer() then
    self:IncrementStackCount()
  end
end

function modifier_hybrid_spell_amp_stack_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
  }
end

function modifier_hybrid_spell_amp_stack_oaa:GetModifierSpellAmplify_Percentage()
  return self:GetStackCount() * self.spell_amp_per_stack
end
