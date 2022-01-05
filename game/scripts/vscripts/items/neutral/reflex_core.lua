LinkLuaModifier("modifier_item_reflex_core_passive", "items/neutral/reflex_core.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_reflex_core_cooldown", "items/neutral/reflex_core.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_reflex_core_invulnerability", "items/neutral/reflex_core.lua", LUA_MODIFIER_MOTION_NONE)
--LinkLuaModifier("modifier_generic_bonus", "modifiers/modifier_generic_bonus.lua", LUA_MODIFIER_MOTION_NONE)

item_reflex_core = class(ItemBaseClass)

function item_reflex_core:GetIntrinsicModifierName()
  return "modifier_item_reflex_core_passive"
end

function item_reflex_core:OnSpellStart()
  local duration = self:GetSpecialValueFor("active_duration")
  local caster = self:GetCaster()

  caster:AddNewModifier(caster, self, "modifier_item_reflex_core_invulnerability", {duration = duration})
end

---------------------------------------------------------------------------------------------------

modifier_item_reflex_core_passive = class(ModifierBaseClass)

function modifier_item_reflex_core_passive:IsHidden()
  return true
end

function modifier_item_reflex_core_passive:IsDebuff()
  return false
end

function modifier_item_reflex_core_passive:IsPurgable()
  return false
end

function modifier_item_reflex_core_passive:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.evasion = ability:GetSpecialValueFor("bonus_evasion")
  end
end

function modifier_item_reflex_core_passive:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.evasion = ability:GetSpecialValueFor("bonus_evasion")
  end
end

function modifier_item_reflex_core_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ABSORB_SPELL,
    MODIFIER_PROPERTY_EVASION_CONSTANT,
  }
end

function modifier_item_reflex_core_passive:GetModifierEvasion_Constant()
  return self.evasion or self:GetAbility():GetSpecialValueFor("bonus_evasion")
end

function modifier_item_reflex_core_passive:GetAbsorbSpell(event)
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  local ability = self:GetAbility()

  if not ability or ability:IsNull() then
    return
  end

  -- No need to dodge if parent is invulnerable
  if parent:HasModifier("modifier_item_reflex_core_invulnerability") or parent:IsInvulnerable() then
    return
  end

  -- Don't dodge if passive is on cooldown
  if parent:HasModifier("modifier_item_reflex_core_cooldown") then
    return
  end

  local chance = ability:GetSpecialValueFor("spell_dodge_chance")/100

  -- Get number of failures
  local prngMult = self:GetStackCount() + 1

  if RandomFloat(0.0, 1.0) <= (PrdCFinder:GetCForP(chance) * prngMult) then
    -- Reset failure count
    self:SetStackCount(0)

    -- Start cooldown by adding a modifier
    parent:AddNewModifier(parent, ability, "modifier_item_reflex_core_cooldown", {duration = ability:GetSpecialValueFor("spell_dodge_cooldown")})

    return 1
  else
    -- Increment number of failures
    self:SetStackCount(prngMult)
  end
end

---------------------------------------------------------------------------------------------------

modifier_item_reflex_core_invulnerability = class(ModifierBaseClass)

function modifier_item_reflex_core_invulnerability:IsHidden()
  return false
end

function modifier_item_reflex_core_invulnerability:IsDebuff()
  return false
end

function modifier_item_reflex_core_invulnerability:IsPurgable()
  return false
end

function modifier_item_reflex_core_invulnerability:GetEffectName()
  return "particles/items_fx/black_king_bar_avatar.vpcf"
end

function modifier_item_reflex_core_invulnerability:GetTexture()
  return self:GetAbility():GetAbilityTextureName()
end

function modifier_item_reflex_core_invulnerability:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
  }
end

function modifier_item_reflex_core_invulnerability:GetAbsoluteNoDamagePhysical()
  return 1
end

function modifier_item_reflex_core_invulnerability:GetAbsoluteNoDamageMagical()
  return 1
end

function modifier_item_reflex_core_invulnerability:GetAbsoluteNoDamagePure()
  return 1
end

function modifier_item_reflex_core_invulnerability:CheckState()
  local state = {
    [MODIFIER_STATE_UNSELECTABLE] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_INVULNERABLE] = true,
  }
  return state
end

---------------------------------------------------------------------------------------------------

modifier_item_reflex_core_cooldown = class(ModifierBaseClass)

function modifier_item_reflex_core_cooldown:IsHidden()
  return false
end

function modifier_item_reflex_core_cooldown:IsDebuff()
  return true
end

function modifier_item_reflex_core_cooldown:IsPurgable()
  return false
end
