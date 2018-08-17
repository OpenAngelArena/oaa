kunkka_tidebringer_oaa = class( AbilityBaseClass )

LinkLuaModifier("modifier_kunkka_tidebringer_oaa_passive", "abilities/oaa_kunkka_tidebringer.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_kunkka_tidebringer_oaa_cooldown", "abilities/oaa_kunkka_tidebringer.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_kunkka_tidebringer_oaa_weapon_effect", "abilities/oaa_kunkka_tidebringer.lua", LUA_MODIFIER_MOTION_NONE)


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

function kunkka_tidebringer_oaa:GetIntrinsicModifierName()
  return "modifier_kunkka_tidebringer_oaa_passive"
end

function kunkka_tidebringer_oaa:ShouldUseResources()
  return true
end

--------------------------------------------------------------------------------

function kunkka_tidebringer_oaa:OnUpgrade()
  -- First point to the ability
  if self:GetLevel() == 1 then
    -- Turn on on first level-up
    if not self:GetAutoCastState() then
      self:ToggleAutoCast()
    end
  end
end

--------------------------------------------------------------------------------

modifier_kunkka_tidebringer_oaa_passive = class( ModifierBaseClass )

--------------------------------------------------------------------------------

function modifier_kunkka_tidebringer_oaa_passive:IsHidden()
  return true
end

function modifier_kunkka_tidebringer_oaa_passive:IsPurgable()
  return false
end

function modifier_kunkka_tidebringer_oaa_passive:IsDebuff()
  return false
end

function modifier_kunkka_tidebringer_oaa_passive:GetAttributes()
  return bit.bor(MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE, MODIFIER_ATTRIBUTE_PERMANENT)
end

--[[
function modifier_kunkka_tidebringer_oaa_passive:GetEffectName()
  return "particles/units/heroes/hero_kunkka/kunkka_weapon_tidebringer.vpcf"
end

function modifier_kunkka_tidebringer_oaa_passive:GetEffectAttachType()
  return PATTACH_OVERHEAD_FOLLOW
end

function modifier_kunkka_tidebringer_oaa_passive:GetStatusEffectName()
  return "particles/units/heroes/hero_kunkka/kunkka_weapon_tidebringer.vpcf"
end
]]

--------------------------------------------------------------------------------

function modifier_kunkka_tidebringer_oaa_passive:OnCreated()
  local parent = self:GetParent()
  -- Add weapon glow
  parent:AddNewModifier(parent, self:GetAbility(), "modifier_kunkka_tidebringer_oaa_weapon_effect", {})
  -- Attack procs
  if not self.procRecords then
    self.procRecords = {}
  end
end

function modifier_kunkka_tidebringer_oaa_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_EVENT_ON_ATTACK,
    MODIFIER_EVENT_ON_ATTACK_FAIL,
    MODIFIER_EVENT_ON_ATTACK_LANDED
  }
end

function modifier_kunkka_tidebringer_oaa_passive:RemoveOnDeath()
  return false
end

function modifier_kunkka_tidebringer_oaa_passive:IsPermanent()
  return true
end

function modifier_kunkka_tidebringer_oaa_passive:GetModifierPreAttack_BonusDamage( event )
  -- Toggled on
  local ability = self:GetAbility()
  if ability:GetAutoCastState() and ability:IsCooldownReady() then
    return ability:GetTalentSpecialValueFor("damage_bonus")
  end
  return 0
end

function modifier_kunkka_tidebringer_oaa_passive:OnAttack(keys)
  local parent = self:GetParent()

  -- process_procs == true in OnAttack means this is an attack that attack modifiers should not apply to
  if keys.attacker ~= parent or keys.process_procs then
    return
  end

  local ability = self:GetAbility()
  local target = keys.target
  -- Wrap in function to defer evaluation
  local function autocast()
    return (
      target.GetUnitName and -- Check for existence of GetUnitName method to determine if target is a unit
      ability:GetAutoCastState() and
      not parent:IsSilenced() and
      ability:IsOwnersManaEnough() and
      ability:IsOwnersGoldEnough(parent:GetPlayerOwnerID()) and
      ability:IsCooldownReady() and
      ability:CastFilterResultTarget(target) == UF_SUCCESS
    )
  end

  if parent:GetCurrentActiveAbility() ~= ability and not autocast() then
    return
  end

  ability:CastAbility()
  -- Enable proc for this attack record number
  self.procRecords[keys.record] = true
end

function modifier_oaa_arcane_orb:OnAttackFail(keys)
  if keys.attacker == self:GetParent() and self.procRecords[keys.record] then
    self.procRecords[keys.record] = nil
  end
end

function modifier_kunkka_tidebringer_oaa_passive:OnAttackLanded( event )
  -- Only attacks FROM parent
  -- process_procs == true in OnAttack means this is an attack that attack modifiers should not apply to
  local parent = self:GetParent()
  if event.attacker ~= parent or not self.procRecords[keys.record] or not event.process_procs then
    return
  end
  self.procRecords[keys.record] = nil

  local ability = self:GetAbility()

  local cleaveInfo = {
    startRadius = ability:GetTalentSpecialValueFor("cleave_starting_width"),
    endRadius = ability:GetTalentSpecialValueFor("cleave_ending_width"),
    length = ability:GetTalentSpecialValueFor("cleave_distance")
  }
  local hitUnits = ability:PerformCleaveOnAttack(
    event,
    cleaveInfo,
    ability:GetTalentSpecialValueFor("cleave_damage") / 100.0,
    "Hero_Kunkka.Tidebringer.Attack",
    "Hero_Kunkka.TidebringerDamage",
    "particles/units/heroes/hero_kunkka/kunkka_spell_tidebringer.vpcf"
  )

  -- Force cooldown
  -- Including cooldown reduction which is why we do not use StartCooldown()
  ability:UseResources(true, true, true)
  -- Remove weapon glow effect
  parent:RemoveModifierByName("modifier_kunkka_tidebringer_oaa_weapon_effect")
  -- Add cooldown timer
  parent:AddNewModifier(parent, ability, "modifier_kunkka_tidebringer_oaa_cooldown", {
    duration = ability:GetCooldownTimeRemaining()
  })
end

--------------------------------------------------------------------------------

modifier_kunkka_tidebringer_oaa_cooldown = class( ModifierBaseClass )

--------------------------------------------------------------------------------

function modifier_kunkka_tidebringer_oaa_cooldown:IsHidden()
  return true
end

function modifier_kunkka_tidebringer_oaa_cooldown:IsPurgable()
  return false
end

function modifier_kunkka_tidebringer_oaa_cooldown:IsDebuff()
  return false
end

function modifier_kunkka_tidebringer_oaa_cooldown:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_kunkka_tidebringer_oaa_cooldown:RemoveOnDeath()
  return false
end

function modifier_kunkka_tidebringer_oaa_cooldown:IsPermanent()
  return false
end

if IsServer() then
  function modifier_kunkka_tidebringer_oaa_cooldown:OnRefresh( keys )
    local ability = self:GetAbility()
    if ability:IsCooldownReady() then

      local parent = self:GetParent()
      -- Add weapon glow
      parent:AddNewModifier(parent, self:GetAbility(), "modifier_kunkka_tidebringer_oaa_weapon_effect", {})
      -- Remove cooldown effect
      parent:RemoveModifierByNameAndCaster("modifier_kunkka_tidebringer_oaa_cooldown", parent)

    else
    -- Change cooldown to ability's remaining time
      self:SetDuration(ability:GetCooldownTimeRemaining(), true)
    end
  end

  function modifier_kunkka_tidebringer_oaa_cooldown:OnRemoved()
    local parent = self:GetParent()

    -- Add weapon glow
    parent:AddNewModifier(parent, self:GetAbility(), "modifier_kunkka_tidebringer_oaa_weapon_effect", {})

    -- Plays an audio effect (only heard by Kunkka) when going off cooldown.
    EmitSoundOnClient("Hero_Kunkaa.Tidebringer", parent:GetPlayerOwner())
  end
end

--------------------------------------------------------------------------------

modifier_kunkka_tidebringer_oaa_weapon_effect = class( ModifierBaseClass )

--------------------------------------------------------------------------------

function modifier_kunkka_tidebringer_oaa_weapon_effect:IsHidden()
  return true
end

function modifier_kunkka_tidebringer_oaa_weapon_effect:IsPurgable()
  return false
end

function modifier_kunkka_tidebringer_oaa_weapon_effect:IsDebuff()
  return false
end

function modifier_kunkka_tidebringer_oaa_weapon_effect:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_kunkka_tidebringer_oaa_weapon_effect:RemoveOnDeath()
  return false
end

function modifier_kunkka_tidebringer_oaa_weapon_effect:IsPermanent()
  return false
end

function modifier_kunkka_tidebringer_oaa_weapon_effect:OnDestroy()
  if IsServer() then
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local cooldown = ability:GetCooldown(ability:GetLevel()-1)

    ParticleManager:DestroyParticle(self.weapon_pfx, true)
    ParticleManager:ReleaseParticleIndex(self.weapon_pfx)
    self.weapon_pfx = 0
  end
end

function modifier_kunkka_tidebringer_oaa_weapon_effect:OnCreated()
  if IsServer() then
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    self.weapon_pfx = self.weapon_pfx or 0
    if self.weapon_pfx == 0 then
      self.weapon_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_kunkka/kunkka_weapon_tidebringer.vpcf", PATTACH_CUSTOMORIGIN, caster)
      ParticleManager:SetParticleControlEnt(self.weapon_pfx, 0, caster, PATTACH_POINT_FOLLOW, "attach_tidebringer", caster:GetAbsOrigin(), true)
      ParticleManager:SetParticleControlEnt(self.weapon_pfx, 2, caster, PATTACH_POINT_FOLLOW, "attach_sword", caster:GetAbsOrigin(), true)
    end
  end
end
