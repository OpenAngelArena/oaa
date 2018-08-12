--TODO "particles/units/heroes/hero_kunkka/kunkka_spell_tidebringer_active.vpcf" -- point glow
--TODO Effect on hit enemies?

kunkka_tidebringer_oaa = class( AbilityBaseClass )

LinkLuaModifier("modifier_kunkka_tidebringer_oaa_active", "abilities/oaa_kunkka_tidebringer.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_kunkka_tidebringer_oaa_cooldown", "abilities/oaa_kunkka_tidebringer.lua", LUA_MODIFIER_MOTION_NONE)


--------------------------------------------------------------------------------

function kunkka_tidebringer_oaa:GetCooldown( level )
  local caster = self:GetCaster()

  local talent_cooldown_reduction = caster:FindTalentValue("special_bonus_unique_kunkka_5")
  return self.BaseClass.GetCooldown( self, level ) - talent_cooldown_reduction
end

-- Do not allow Rubick to steal this ability
function kunkka_tidebringer_oaa:IsStealable()
  return false
end

--------------------------------------------------------------------------------

function kunkka_tidebringer_oaa:OnUpgrade()
  -- First point to the ability
  if self:GetLevel() == 1 then
    -- Turn on on first level-up
    if not self:GetToggleState() then
      self:ToggleAutoCast()
    end
    -- Apply _active or _cooldown modifiers
    if self:IsCooldownReady() then
      self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_kunkka_tidebringer_oaa_active", nil)
    else
      self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_kunkka_tidebringer_oaa_cooldown", {
        duration = self:GetCooldownTimeRemaining()
      })
    end
  end
end

--------------------------------------------------------------------------------

modifier_kunkka_tidebringer_oaa_active = class( ModifierBaseClass )

--------------------------------------------------------------------------------

function modifier_kunkka_tidebringer_oaa_active:IsHidden()
  return false
end

function modifier_kunkka_tidebringer_oaa_active:IsPurgable()
  return false
end

function modifier_kunkka_tidebringer_oaa_active:IsDebuff()
  return false
end

function modifier_kunkka_tidebringer_oaa_active:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_kunkka_tidebringer_oaa_active:GetStatusEffectName()
  return "particles/units/heroes/hero_kunkka/kunkka_weapon_tidebringer.vpcf"
end

--------------------------------------------------------------------------------

function modifier_kunkka_tidebringer_oaa_active:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE
  }
end

if IsServer() then
  function modifier_kunkka_tidebringer_oaa_active:GetModifierPreAttack_BonusDamage( event )
    if self:GetParent() ~= event.attacker then
      return
    end

    -- Toggled on
    local ability = self:GetAbility()
    if ability:GetToggleState() then
      return ability:GetTalentSpecialValueFor("damage_bonus")
    end
    return 0
  end

  function modifier_kunkka_tidebringer_oaa_active:OnAttackLanded( event )
    -- Only attacks FROM parent
    if self:GetParent() ~= event.attacker then
      return
    end

    -- Toggled off
    if not ability:GetToggleState() then
      return
    end

    local ability = self:GetAbility()

    local cleaveInfo = {
      startRadius = ability:GetTalentSpecialValueFor("cleave_starting_width"),
      endRadius = ability:GetTalentSpecialValueFor("cleave_ending_width"),
      length = ability:GetTalentSpecialValueFor("cleave_distance")
    }
    ability:PerformCleaveOnAttack(
      event,
      cleaveInfo,
      ability:GetTalentSpecialValueFor("cleave_damage") / 100.0,
      "Kunkka.Tidebringer",
      "particles/econ/items/kunkka/kunkka_tidebringer_base/kunkka_spell_tidebringer.vpcf",
      "particles/units/heroes/hero_kunkka/kunkka_spell_tidebringer.vpcf"
    )

    -- Force cooldown
    -- Including cooldown reduction which is why we do not use StartCooldown()
    self:GetAbility():UseResources(true, true, true)
    -- Remove active effect
    self:GetParent():RemoveModifierByNameAndCaster("modifier_kunkka_tidebringer_oaa_active", self:GetParent())
    -- Add cooldown timer
    self:GetParent():AddNewModifier(self:GetParent(), self, "modifier_kunkka_tidebringer_oaa_cooldown", {
      duration = self:GetCooldownTimeRemaining()
    })
  end
end

--------------------------------------------------------------------------------

modifier_kunkka_tidebringer_oaa_cooldown = class( ModifierBaseClass )

--------------------------------------------------------------------------------

function modifier_kunkka_tidebringer_oaa_cooldown:IsHidden()
  return false
end

function modifier_kunkka_tidebringer_oaa_cooldown:IsPurgable()
  return false
end

function modifier_kunkka_tidebringer_oaa_cooldown:IsDebuff()
  return false
end

function modifier_kunkka_tidebringer_oaa_cooldown:GetAttributes()
  return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_kunkka_tidebringer_oaa_cooldown:OnCreated( keys )
end

function modifier_kunkka_tidebringer_oaa_cooldown:OnRefresh( keys )
  if self:GetAbility():IsCooldownReady() then

  else
    self:SetTime(self:GetAbility():GetCooldownTimeRemaining())
  end
end

function modifier_kunkka_tidebringer_oaa_cooldown:OnRemoved()
  -- Plays an audio effect (only heard by Kunkka) when going off cooldown.
  EmitSoundOnClient("Kunkka.Tidebringer.OffCooldown")
end

function modifier_kunkka_tidebringer_oaa_cooldown:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end
