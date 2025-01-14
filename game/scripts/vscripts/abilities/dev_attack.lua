LinkLuaModifier("modifier_dev_attack", "abilities/dev_attack.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dev_attack_aura", "abilities/dev_attack.lua", LUA_MODIFIER_MOTION_NONE)

dev_attack = class(AbilityBaseClass)

function dev_attack:GetIntrinsicModifierName()
  return "modifier_dev_attack"
end


modifier_dev_attack = class(ModifierBaseClass)

function modifier_dev_attack:IsAura()
  return true
end

function modifier_dev_attack:GetModifierAura()
  return "modifier_dev_attack_aura"
end

function modifier_dev_attack:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_dev_attack:GetAuraSearchFlags()
  return bit.bor(self:GetAbility():GetAbilityTargetFlags(), DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD)
end

function modifier_dev_attack:GetAuraSearchTeam()
  return self:GetAbility():GetAbilityTargetTeam()
end

function modifier_dev_attack:GetAuraSearchType()
  return bit.bor(self:GetAbility():GetAbilityTargetType(), DOTA_UNIT_TARGET_OTHER)
end

function modifier_dev_attack:GetTexture()
  return "custom/shoopdawhoop"
end

modifier_dev_attack_aura = class(ModifierBaseClass)

function modifier_dev_attack_aura:OnCreated(keys)
  if IsServer() then
    local caster = self:GetCaster()
    local target = self:GetParent()
    local attackEffect = "particles/fountain_lazor.vpcf"

    self.particle = ParticleManager:CreateParticle(attackEffect, PATTACH_CUSTOMORIGIN_FOLLOW, target)
    ParticleManager:SetParticleControlEnt(self.particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(self.particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)

    --EmitSoundOn("Hero_Phoenix.SunRay.Cast", caster)
    --EmitSoundOn("Hero_Phoenix.SunRay.Loop", caster)

    self:StartIntervalThink(0.1)
  end
end

function modifier_dev_attack_aura:OnIntervalThink()
  if IsServer() then
    local caster = self:GetCaster()
    local teamID = caster:GetTeamNumber()
    local ability = self:GetAbility()
    local target = self:GetParent()
    local timetokill = ability:GetSpecialValueFor("timetokill")
    local killTicks = timetokill / 0.1
    if not target or target:IsNull() or (target.IsAlive and not target:IsAlive()) then
      self:StartIntervalThink(-1)
      self:Destroy()
    end

    local targetHealth = target:GetHealth()
    local targetMaxHealth = target:GetMaxHealth()
    local healthReductionAmount = targetMaxHealth / killTicks
    local targetMaxMana = target:GetMaxMana()
    local manaReductionAmount = targetMaxMana / killTicks

    target:MakeVisibleDueToAttack(teamID, 200)
    -- Basic Dispel (for enemies)
    target:Purge(true, false, false, false, false)
    target:ReduceMana(manaReductionAmount, ability)
    caster:GiveMana(manaReductionAmount)
    if targetHealth - healthReductionAmount < 1 then
      target:Kill(ability, caster)
    else
      target:SetHealth(targetHealth - healthReductionAmount)
      caster:Heal(healthReductionAmount, ability)
    end
  end
end

function modifier_dev_attack_aura:IsHidden()
  return true
end

function modifier_dev_attack_aura:OnDestroy()
  if IsServer() then
    if self.particle then
      ParticleManager:DestroyParticle(self.particle, false)
      ParticleManager:ReleaseParticleIndex(self.particle)
    end
    --local caster = self:GetCaster()
    --StopSoundOn("Hero_Phoenix.SunRay.Loop", caster)
    --EmitSoundOn("Hero_Phoenix.SunRay.Stop", caster)
  end
end
