
lich_sacrifice_oaa = class(AbilityBaseClass)

function lich_sacrifice_oaa:CastFilterResultTarget(target)
  local default_result = self.BaseClass.CastFilterResultTarget(self, target)

  if default_result == UF_SUCCESS then
    if target:IsCourier() then
      return UF_FAIL_COURIER
    elseif target:IsConsideredHero() then
      return UF_FAIL_CONSIDERED_HERO
    elseif target:IsOAABoss() then
      return UF_FAIL_OTHER
    elseif target:IsAncient() and self:GetCaster():GetLevel() < self:GetSpecialValueFor("hero_lvl_requirement_for_ancients") then
      return UF_FAIL_ANCIENT
    elseif IsServer() then
      if target:IsZombie() then
        return UF_FAIL_OTHER
      end
    end
  end

  return default_result
end

function lich_sacrifice_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()

  -- Check if target exists
  if not target or target:IsNull() then
    return
  end

  -- If cast filter is bypassed
  if target:IsOAABoss() or target:IsCourier() or target:IsZombie() or target:IsConsideredHero() or (target:IsAncient() and caster:GetLevel() < self:GetSpecialValueFor("hero_lvl_requirement_for_ancients")) then
    return
  end

  local caster_team = caster:GetTeamNumber()
  local target_team = target:GetTeamNumber()

  -- Checking if target has spell block, if target has spell block, there is no need to execute the spell
  if target:TriggerSpellAbsorb(self) and target_team ~= caster_team then
    return
  end

  -- KVs
  local xpMult = self:GetSpecialValueFor("xp_pct") / 100
  local current_hp_to_mana = self:GetSpecialValueFor("active_mana_restore_pct_of_health") / 100

  local target_bounty = target:GetDeathXP()
  local target_health = target:GetHealth()

  -- Particle
  local part = ParticleManager:CreateParticle("particles/units/heroes/hero_lich/lich_dark_ritual.vpcf", PATTACH_POINT_FOLLOW, target)
  ParticleManager:SetParticleControl(part, 0, caster:GetAbsOrigin())
  ParticleManager:SetParticleControl(part, 1, target:GetAbsOrigin())
  ParticleManager:ReleaseParticleIndex(part)

  -- Sound
  caster:EmitSound("Hero_Lich.Sacrifice")

  -- Grant experience if used on allied creeps
  if caster.AddExperience and target_team == caster_team then
    local xp_gain = target_bounty * xpMult
    caster:AddExperience(xp_gain, DOTA_ModifyXP_CreepKill, false, false)
  end

  -- Grant mana
  local mana_gain = target_health * current_hp_to_mana
  caster:GiveMana(mana_gain)
  SendOverheadEventMessage(caster:GetPlayerOwner(), OVERHEAD_ALERT_MANA_ADD, caster, mana_gain, nil)

  -- Kill the creep
  if caster_team == DOTA_TEAM_NEUTRALS then
    target:ForceKillOAA(false)
  else
    target:Kill(self, caster)
  end
end

function lich_sacrifice_oaa:ProcsMagicStick()
  return true
end
