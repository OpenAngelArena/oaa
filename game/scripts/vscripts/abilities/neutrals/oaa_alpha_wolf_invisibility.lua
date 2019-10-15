require("libraries/timers")

alpha_wolf_invisibility_oaa = class(AbilityBaseClass)

LinkLuaModifier("modifier_alpha_invisibility_oaa_buff", "abilities/neutrals/oaa_alpha_wolf_invisibility.lua", LUA_MODIFIER_MOTION_NONE)

function alpha_wolf_invisibility_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local duration = self:GetSpecialValueFor("duration")
  local fade_time = self:GetSpecialValueFor("fade_time")

  -- Sound
  caster:EmitSound("Hero_BountyHunter.WindWalk")

  -- Apply a buff after fade time
  Timers:CreateTimer(fade_time, function()
    caster:AddNewModifier(caster, self, "modifier_alpha_invisibility_oaa_buff", { duration = duration } )
  end)
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
  local particle = ParticleManager:CreateParticle("particles/generic_hero_status/status_invisibility_start.vpcf", PATTACH_ABSORIGIN, self:GetParent())
  ParticleManager:ReleaseParticleIndex(particle)
end

function modifier_alpha_invisibility_oaa_buff:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_INVISIBILITY_LEVEL,
    MODIFIER_EVENT_ON_ABILITY_EXECUTED,
    MODIFIER_EVENT_ON_ATTACK,
  }
  return funcs
end

function modifier_alpha_invisibility_oaa_buff:GetModifierInvisibilityLevel()
  if IsClient() then
    return 1
  end
end
if IsServer() then
  function modifier_alpha_invisibility_oaa_buff:OnAbilityExecuted(event)
    if event.unit ~= self:GetParent() then
      return
    end
    self:Destroy()
  end

  function modifier_alpha_invisibility_oaa_buff:OnAttack(event)
    if event.attacker ~= self:GetParent() then
      return
    end
    self:Destroy()
  end

  function modifier_alpha_invisibility_oaa_buff:CheckState()
    local state = {
      [MODIFIER_STATE_INVISIBLE] = true,
      [MODIFIER_STATE_NO_UNIT_COLLISION] = true
    }
    return state
  end
end
function modifier_alpha_invisibility_oaa_buff:GetPriority()
  return MODIFIER_PRIORITY_ULTRA
end
