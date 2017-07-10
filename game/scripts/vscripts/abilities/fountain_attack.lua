require("internal/util")

LinkLuaModifier("modifier_fountain_attack", "abilities/fountain_attack.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_fountain_attack_aura", "abilities/fountain_attack.lua", LUA_MODIFIER_MOTION_NONE)

fountain_attack = class(AbilityBaseClass)

function fountain_attack:GetIntrinsicModifierName()
    return "modifier_fountain_attack"
end


modifier_fountain_attack = class(ModifierBaseClass)

function modifier_fountain_attack:OnCreated(keys)
  if IsServer() then
    local teamID = self:GetCaster():GetTeamNumber()
    self.trigger = Entities:FindByName(nil, 'fountain_' .. GetShortTeamName(teamID) .. '_trigger')
  end
end

function modifier_fountain_attack:IsAura()
return true
end

function modifier_fountain_attack:IsHidden()
  return true
end

function modifier_fountain_attack:GetModifierAura()
  return "modifier_fountain_attack_aura"
end

function modifier_fountain_attack:GetAuraRadius()
  return self.trigger:GetBoundingMaxs():Length2D()
end

function modifier_fountain_attack:GetAuraSearchFlags()
  return self:GetAbility():GetAbilityTargetFlags()
end

function modifier_fountain_attack:GetAuraSearchTeam()
  return self:GetAbility():GetAbilityTargetTeam()
end

function modifier_fountain_attack:GetAuraSearchType()
  return self:GetAbility():GetAbilityTargetType()
end

function modifier_fountain_attack:GetAuraEntityReject(entity)
  return entity:GetTeamNumber() == DOTA_TEAM_NEUTRALS or not IsInTrigger(entity, self.trigger)
end


modifier_fountain_attack_aura = class(ModifierBaseClass)

function modifier_fountain_attack_aura:OnCreated(keys)
  local caster = self:GetCaster()
  local target = self:GetParent()
  local attackEffect = "particles/fountain_lazor.vpcf"

  self.particle = ParticleManager:CreateParticle(attackEffect, PATTACH_CUSTOMORIGIN_FOLLOW, target)
  ParticleManager:SetParticleControlEnt(self.particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetAbsOrigin(), true)
  ParticleManager:SetParticleControlEnt(self.particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)

  EmitSoundOn("Hero_Phoenix.SunRay.Cast", caster)
  EmitSoundOn("Hero_Phoenix.SunRay.Loop", caster)

  if IsServer() then
    self:StartIntervalThink(0.1)
  end
end

function modifier_fountain_attack_aura:OnIntervalThink()
  if IsServer() then
    local caster = self:GetCaster()
    local teamID = caster:GetTeamNumber()
    local target = self:GetParent()
    local timetokill = self:GetAbility():GetSpecialValueFor("timetokill")
    local killTicks = timetokill / 0.1
    local targetHealth = target:GetHealth()
    local targetMaxHealth = target:GetMaxHealth()
    local healthReductionAmount = targetMaxHealth / killTicks
    local targetMaxMana = target:GetMaxMana()
    local manaReductionAmount = targetMaxMana / killTicks

    target:MakeVisibleDueToAttack(teamID)
    target:Purge(true, false, false, false, true)
    target:ReduceMana(manaReductionAmount)
    if targetHealth - healthReductionAmount < 1 then
      target:Kill(self, caster)
    else
      target:SetHealth(targetHealth - healthReductionAmount)
    end
  end
end

function modifier_fountain_attack_aura:IsHidden()
  return true
end

function modifier_fountain_attack_aura:OnDestroy()
  local caster = self:GetCaster()

  ParticleManager:DestroyParticle(self.particle, false)
  StopSoundOn("Hero_Phoenix.SunRay.Loop", caster)
  EmitSoundOn("Hero_Phoenix.SunRay.Stop", caster)
end
