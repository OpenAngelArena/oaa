LinkLuaModifier("modifier_pangolier_heartpiercer_oaa", "abilities/oaa_heartpiercer.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_pangolier_heartpiercer_oaa_delay", "abilities/oaa_heartpiercer.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_pangolier_heartpiercer_oaa_debuff", "abilities/oaa_heartpiercer.lua", LUA_MODIFIER_MOTION_NONE)

pangolier_heartpiercer_oaa = class(AbilityBaseClass)

function pangolier_heartpiercer_oaa:GetIntrinsicModifierName()
  return "modifier_pangolier_heartpiercer_oaa"
end

--------------------------------------------------------------------------------

local debuffModName = "modifier_pangolier_heartpiercer_oaa_debuff"
local delayModName = "modifier_pangolier_heartpiercer_oaa_delay"
modifier_pangolier_heartpiercer_oaa = class(ModifierBaseClass)

function modifier_pangolier_heartpiercer_oaa:IsHidden()
  return true
end

function modifier_pangolier_heartpiercer_oaa:IsPurgable()
  return false
end

function modifier_pangolier_heartpiercer_oaa:RemoveOnDeath()
  return false
end

function modifier_pangolier_heartpiercer_oaa:OnCreated()
  self:SetStackCount(1)
end

function modifier_pangolier_heartpiercer_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_LANDED
  }
end

function modifier_pangolier_heartpiercer_oaa:OnAttackLanded(keys)
  local parent = self:GetParent()
  if keys.attacker ~= parent or not keys.process_procs or parent:PassivesDisabled() then
    return
  end

  local target = keys.target

  -- Can't proc on allies, towers, or wards
  if UnitFilter(target, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE, parent:GetTeamNumber()) ~= UF_SUCCESS then
    return
  end

  local ability = self:GetAbility()
  local procChance = ability:GetSpecialValueFor("chance_pct")
  local prdMult = self:GetStackCount()

  -- Roll proc chance
  if RandomFloat(0.0, 1.0) <= (PrdCFinder:GetCForP(procChance / 100) * prdMult) then
    self:SetStackCount(1) -- Reset PRD counter on successful proc

    -- If the target already has the debuff, then refresh it
    if target:HasModifier(debuffModName) then
      target:AddNewModifier(parent, ability, debuffModName, {duration = ability:GetSpecialValueFor("duration")})
    -- Only apply the delay handler if the target doesn't already have it
    elseif not target:HasModifier(delayModName) then
      target:AddNewModifier(parent, ability, delayModName, {duration = ability:GetSpecialValueFor("debuff_delay")})
    end

    -- Play proc sound
    if target:IsHero() then
      target:EmitSound("Hero_Pangolier.HeartPiercer")
    else
      target:EmitSound("Hero_Pangolier.HeartPiercer.Creep")
    end
  else
    -- Didn't proc; increment PRD counter
    self:IncrementStackCount()
  end
end

--------------------------------------------------------------------------------

modifier_pangolier_heartpiercer_oaa_delay = class(ModifierBaseClass)

function modifier_pangolier_heartpiercer_oaa_delay:IsDebuff()
  return true
end

if IsServer() then
  function modifier_pangolier_heartpiercer_oaa_delay:OnDestroy()
    -- Only apply on expiration and not when purged or removed early
    if self:GetRemainingTime() <= 0 then
      local ability = self:GetAbility()
      local debuffDuration = ability:GetSpecialValueFor("duration")
      -- Apply the Heartpiercer debuff
      self:GetParent():AddNewModifier(self:GetCaster(), ability, debuffModName, {duration = debuffDuration})
    end
  end
end

function modifier_pangolier_heartpiercer_oaa_delay:GetEffectAttachType()
  return PATTACH_OVERHEAD_FOLLOW
end

function modifier_pangolier_heartpiercer_oaa_delay:GetEffectName()
  return "particles/units/heroes/hero_pangolier/pangolier_heartpiercer_delay.vpcf"
end

--------------------------------------------------------------------------------

modifier_pangolier_heartpiercer_oaa_debuff = class(ModifierBaseClass)

function modifier_pangolier_heartpiercer_oaa_debuff:IsDebuff()
  return true
end

function modifier_pangolier_heartpiercer_oaa_debuff:GetEffectAttachType()
  return PATTACH_OVERHEAD_FOLLOW
end

function modifier_pangolier_heartpiercer_oaa_debuff:GetEffectName()
  return "particles/units/heroes/hero_pangolier/pangolier_heartpiercer_debuff.vpcf"
end

function modifier_pangolier_heartpiercer_oaa_debuff:OnCreated(keys)
  local parent = self:GetParent()
  local slow_pct = self:GetAbility():GetSpecialValueFor("slow_pct")
  if IsServer() then
    if parent:IsHero() then
      parent:EmitSound("Hero_Pangolier.HeartPiercer.Proc")
    else
      parent:EmitSound("Hero_Pangolier.HeartPiercer.Proc.Creep")
    end
    self.slow = parent:GetValueChangedByStatusResistance(slow_pct)
  else
    self.slow = slow_pct
  end
end

function modifier_pangolier_heartpiercer_oaa_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
  }
end

function modifier_pangolier_heartpiercer_oaa_debuff:GetModifierMoveSpeedBonus_Percentage()
  return self.slow
end

function modifier_pangolier_heartpiercer_oaa_debuff:GetModifierPhysicalArmorBonus()
  return -self:GetParent():GetPhysicalArmorBaseValue()
end
