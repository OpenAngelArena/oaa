LinkLuaModifier("modifier_pangolier_lucky_shot_oaa", "abilities/oaa_pangolier_lucky_shot.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_pangolier_lucky_shot_oaa_slow_debuff", "abilities/oaa_pangolier_lucky_shot.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_pangolier_lucky_shot_oaa_armor_and_disarm_debuff", "abilities/oaa_pangolier_lucky_shot.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_pangolier_lucky_shot_oaa_armor_debuff", "abilities/oaa_pangolier_lucky_shot.lua", LUA_MODIFIER_MOTION_NONE)

pangolier_lucky_shot_oaa = class(AbilityBaseClass)

function pangolier_lucky_shot_oaa:GetIntrinsicModifierName()
  return "modifier_pangolier_lucky_shot_oaa"
end

---------------------------------------------------------------------------------------------------

modifier_pangolier_lucky_shot_oaa = class(ModifierBaseClass)

function modifier_pangolier_lucky_shot_oaa:IsHidden()
  return true
end

function modifier_pangolier_lucky_shot_oaa:IsPurgable()
  return false
end

function modifier_pangolier_lucky_shot_oaa:RemoveOnDeath()
  return false
end

function modifier_pangolier_lucky_shot_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_LANDED
  }
end

if IsServer() then
  function modifier_pangolier_lucky_shot_oaa:OnAttackLanded(event)
    local parent = self:GetParent()
    local ability = self:GetAbility()
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

    -- Don't proc on illusion or if broken
    if parent:IsIllusion() or parent:PassivesDisabled() then
      return
    end

    -- Check if attacked unit exists
    if not target or target:IsNull() then
      return
    end

    -- Check if attacked entity is an item, rune or something weird
    if target.GetUnitName == nil then
      return
    end

    -- Can't proc on allies, towers, or wards
    if UnitFilter(target, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE, parent:GetTeamNumber()) ~= UF_SUCCESS then
      return
    end

    local chance = ability:GetSpecialValueFor("chance_pct")/100

    -- Get number of failures
    local prngMult = self:GetStackCount() + 1

    -- Roll proc chance
    if RandomFloat(0.0, 1.0) <= (PrdCFinder:GetCForP(chance) * prngMult) then
      -- Reset PRD failure count on successful proc
      self:SetStackCount(0)

      -- Calculate duration
      local duration = ability:GetSpecialValueFor("duration")
      -- Different for ranged units
      if target:IsRangedAttacker() then
        duration = ability:GetSpecialValueFor("duration_ranged")
      end

      -- Armor reduction and disarm duration with status resistance in mind
      local disarm_duration = target:GetValueChangedByStatusResistance(duration)

      -- Apply slow debuff
      --target:AddNewModifier(parent, ability, "modifier_pangolier_lucky_shot_oaa_slow_debuff", {duration = duration})

      -- Apply armor reduction and disarm debuff (don't apply disarm to bosses)
      if not target:IsOAABoss() then
        target:AddNewModifier(parent, ability, "modifier_pangolier_lucky_shot_oaa_armor_and_disarm_debuff", {duration = disarm_duration})
      else
        -- If debuff applies only armor reduction, don't change duration with status resistance
        target:AddNewModifier(parent, ability, "modifier_pangolier_lucky_shot_oaa_armor_debuff", {duration = duration})
      end

      -- Play proc sound
      if target:IsConsideredHero() then
        target:EmitSound("Hero_Pangolier.LuckyShot.Proc")
      else
        target:EmitSound("Hero_Pangolier.LuckyShot.Proc.Creep")
      end

      -- Play particle effect
      local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_pangolier/pangolier_luckyshot_disarm_cast.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
      ParticleManager:SetParticleControl(particle, 1, target:GetAbsOrigin())
      ParticleManager:ReleaseParticleIndex(particle)
    else
      -- Didn't proc; Increment number of failures
      self:SetStackCount(prngMult)
    end
  end
end

---------------------------------------------------------------------------------------------------

modifier_pangolier_lucky_shot_oaa_slow_debuff = class(ModifierBaseClass)

function modifier_pangolier_lucky_shot_oaa_slow_debuff:IsHidden()
  return false
end

function modifier_pangolier_lucky_shot_oaa_slow_debuff:IsDebuff()
  return true
end

function modifier_pangolier_lucky_shot_oaa_slow_debuff:IsPurgable()
  return true
end

function modifier_pangolier_lucky_shot_oaa_slow_debuff:OnCreated(event)
  local parent = self:GetParent()
  local ability = self:GetAbility()
  local movement_slow = ability:GetSpecialValueFor("slow")
  if IsServer() then
    -- Slow is reduced with Status Resistance
    self.slow = parent:GetValueChangedByStatusResistance(movement_slow)
  else
    self.slow = movement_slow
  end
end

function modifier_pangolier_lucky_shot_oaa_slow_debuff:OnRefresh(event)
  local parent = self:GetParent()
  local ability = self:GetAbility()
  local movement_slow = ability:GetSpecialValueFor("slow")
  if IsServer() then
    -- Slow is reduced with Status Resistance
    self.slow = parent:GetValueChangedByStatusResistance(movement_slow)
  else
    self.slow = movement_slow
  end
end

function modifier_pangolier_lucky_shot_oaa_slow_debuff:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
  }
  return funcs
end

function modifier_pangolier_lucky_shot_oaa_slow_debuff:GetModifierMoveSpeedBonus_Percentage()
  return self.slow
end

---------------------------------------------------------------------------------------------------

modifier_pangolier_lucky_shot_oaa_armor_and_disarm_debuff = class(ModifierBaseClass)

function modifier_pangolier_lucky_shot_oaa_armor_and_disarm_debuff:IsHidden()
  return false
end

function modifier_pangolier_lucky_shot_oaa_armor_and_disarm_debuff:IsDebuff()
  return true
end

function modifier_pangolier_lucky_shot_oaa_armor_and_disarm_debuff:IsPurgable()
  return true
end

function modifier_pangolier_lucky_shot_oaa_armor_and_disarm_debuff:GetEffectAttachType()
  return PATTACH_OVERHEAD_FOLLOW
end

function modifier_pangolier_lucky_shot_oaa_armor_and_disarm_debuff:GetEffectName()
  return "particles/units/heroes/hero_pangolier/pangolier_luckyshot_disarm_debuff.vpcf"
end

function modifier_pangolier_lucky_shot_oaa_armor_and_disarm_debuff:CheckState()
  local state = {
    [MODIFIER_STATE_DISARMED] = true
  }
  return state
end

function modifier_pangolier_lucky_shot_oaa_armor_and_disarm_debuff:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
  }
  return funcs
end

function modifier_pangolier_lucky_shot_oaa_armor_and_disarm_debuff:GetModifierPhysicalArmorBonus()
  return self:GetAbility():GetSpecialValueFor("armor")
end

---------------------------------------------------------------------------------------------------

modifier_pangolier_lucky_shot_oaa_armor_debuff = class(ModifierBaseClass)

function modifier_pangolier_lucky_shot_oaa_armor_debuff:IsHidden()
  return false
end

function modifier_pangolier_lucky_shot_oaa_armor_debuff:IsDebuff()
  return true
end

function modifier_pangolier_lucky_shot_oaa_armor_debuff:IsPurgable()
  return true
end

function modifier_pangolier_lucky_shot_oaa_armor_debuff:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
  }
  return funcs
end

function modifier_pangolier_lucky_shot_oaa_armor_debuff:GetModifierPhysicalArmorBonus()
  return self:GetAbility():GetSpecialValueFor("armor")
end

