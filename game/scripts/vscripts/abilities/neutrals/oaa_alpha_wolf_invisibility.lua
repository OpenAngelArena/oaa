LinkLuaModifier("modifier_alpha_invisibility_oaa_buff", "abilities/neutrals/oaa_alpha_wolf_invisibility.lua", LUA_MODIFIER_MOTION_NONE)

alpha_wolf_invisibility_oaa = class(AbilityBaseClass)

function alpha_wolf_invisibility_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local duration = self:GetSpecialValueFor("duration")

  -- Sound
  caster:EmitSound("Hero_BountyHunter.WindWalk")

  caster:AddNewModifier(caster, self, "modifier_alpha_invisibility_oaa_buff", { duration = duration } )
end
--------------------------------------------------------------------------------

modifier_alpha_invisibility_oaa_buff = class(ModifierBaseClass)

function modifier_alpha_invisibility_oaa_buff:IsHidden()
  return false
end

function modifier_alpha_invisibility_oaa_buff:IsDebuff()
  return false
end

function modifier_alpha_invisibility_oaa_buff:IsPurgable()
  return false
end

function modifier_alpha_invisibility_oaa_buff:OnCreated()
  self.fade_time = self:GetAbility():GetSpecialValueFor("fade_time")

  local particle = ParticleManager:CreateParticle("particles/generic_hero_status/status_invisibility_start.vpcf", PATTACH_ABSORIGIN, self:GetParent())
  ParticleManager:ReleaseParticleIndex(particle)
end

function modifier_alpha_invisibility_oaa_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_INVISIBILITY_LEVEL,
    MODIFIER_EVENT_ON_ABILITY_EXECUTED,
    MODIFIER_EVENT_ON_ATTACK,
  }
end

function modifier_alpha_invisibility_oaa_buff:GetModifierInvisibilityLevel()
  return math.min(1, self:GetElapsedTime() / self.fade_time)
end

if IsServer() then
  function modifier_alpha_invisibility_oaa_buff:OnAbilityExecuted(event)
    local unit = event.unit

    -- Check if unit exists
    if not unit or unit:IsNull() then
      return
    end

    if unit ~= self:GetParent() then
      return
    end

    self:Destroy()
  end

  function modifier_alpha_invisibility_oaa_buff:OnAttack(event)
    local attacker = event.attacker

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    if attacker ~= self:GetParent() then
      return
    end

    self:Destroy()
  end
end

function modifier_alpha_invisibility_oaa_buff:CheckState()
  if self:GetElapsedTime() >= self.fade_time then
    return {
      [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
      [MODIFIER_STATE_INVISIBLE] = true,
    }
  else
    return {}
  end
end

function modifier_alpha_invisibility_oaa_buff:GetPriority()
  return MODIFIER_PRIORITY_ULTRA
end
