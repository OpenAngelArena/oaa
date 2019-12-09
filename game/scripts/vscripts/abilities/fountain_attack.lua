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
  return bit.bor(self:GetAbility():GetAbilityTargetFlags(), DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD)
end

function modifier_fountain_attack:GetAuraSearchTeam()
  return self:GetAbility():GetAbilityTargetTeam()
end

function modifier_fountain_attack:GetAuraSearchType()
  return bit.bor(self:GetAbility():GetAbilityTargetType(), DOTA_UNIT_TARGET_OTHER)
end

function modifier_fountain_attack:GetAuraEntityReject(entity)
  return entity:GetTeamNumber() == DOTA_TEAM_NEUTRALS or not IsInTrigger(entity, self.trigger)
end


modifier_fountain_attack_aura = class(ModifierBaseClass)

function modifier_fountain_attack_aura:OnCreated(keys)
  local caster = self:GetCaster()
  local teamID = caster:GetTeamNumber()
  local target = self:GetParent()
  local attackEffect = ""
  if teamID == DOTA_TEAM_GOODGUYS then
    attackEffect = "particles/abilities/tesla_coil_radiant.vpcf"
  elseif teamID == DOTA_TEAM_BADGUYS then
    attackEffect = "particles/abilities/tesla_coil_dire.vpcf"
  end
  local statusEffect = "particles/status_fx/status_effect_wraithking_ghosts.vpcf"

  self.statusParticle = ParticleManager:CreateParticle(statusEffect, PATTACH_POINT_FOLLOW, caster)

  self.attackParticle = ParticleManager:CreateParticle(attackEffect, PATTACH_CUSTOMORIGIN_FOLLOW, target)
  ParticleManager:SetParticleControlEnt(self.attackParticle, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetAbsOrigin(), true)
  ParticleManager:SetParticleControlEnt(self.attackParticle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)

  EmitSoundOn("Abilities.Fountain_Attack.Cast", caster)

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

    if target:IsCourier() then
      return
    end

    target:MakeVisibleDueToAttack(teamID, 0)
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

  ParticleManager:DestroyParticle(self.attackParticle, false)
  ParticleManager:ReleaseParticleIndex(self.attackParticle)
  ParticleManager:DestroyParticle(self.statusParticle, false)
  ParticleManager:ReleaseParticleIndex(self.statusParticle)

  StopSoundOn("Abilities.Fountain_Attack.Cast", caster)
  --EmitSoundOn("Hero_Phoenix.SunRay.Stop", caster)
end
