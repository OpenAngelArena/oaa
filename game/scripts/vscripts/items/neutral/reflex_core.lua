LinkLuaModifier("modifier_item_reflex_core_passive", "items/neutral/reflex_core.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_reflex_core_cooldown", "items/neutral/reflex_core.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_reflex_core_invulnerability", "items/neutral/reflex_core.lua", LUA_MODIFIER_MOTION_NONE)

item_reflex_core = class(ItemBaseClass)

function item_reflex_core:GetIntrinsicModifierName()
  return "modifier_item_reflex_core_passive"
end

function item_reflex_core:OnSpellStart()
  local duration = self:GetSpecialValueFor("active_duration")
  local caster = self:GetCaster()

  -- Disjoint projectiles on cast
  ProjectileManager:ProjectileDodge(caster)

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

function modifier_item_reflex_core_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ABSORB_SPELL,
  }
end

if IsServer() then
  function modifier_item_reflex_core_passive:GetAbsorbSpell(event)
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local casted_ability = event.ability

    -- Don't block if we don't have required variables
    if not ability or ability:IsNull() or not casted_ability or casted_ability:IsNull() then
      return 0
    end

    local caster = casted_ability:GetCaster()

    -- Don't block allied spells
    if caster:GetTeamNumber() == parent:GetTeamNumber() then
      return 0
    end

    -- Don't block if parent is an illusion
    -- Some stuff pierce invulnerability (like Nullifier) so we need to block them too
    if parent:IsIllusion() then
      return 0
    end

    -- Don't dodge if passive is on cooldown
    if parent:HasModifier("modifier_item_reflex_core_cooldown") then
      return 0
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

    return 0
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
  return "custom/reflex_core"
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
  return {
    [MODIFIER_STATE_UNSELECTABLE] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_INVULNERABLE] = true,
  }
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

function modifier_item_reflex_core_cooldown:GetTexture()
  return "custom/reflex_core"
end
