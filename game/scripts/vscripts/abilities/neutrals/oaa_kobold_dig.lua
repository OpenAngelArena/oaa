LinkLuaModifier("modifier_kobold_dig_oaa_buff", "abilities/neutrals/oaa_kobold_dig.lua", LUA_MODIFIER_MOTION_NONE)

kobold_dig_oaa = class(AbilityBaseClass)

function kobold_dig_oaa:Precache(context)
  PrecacheResource("particle", "particles/econ/events/ti9/shovel_dig.vpcf", context)
  PrecacheResource("particle", "particles/units/heroes/hero_nyx_assassin/nyx_assassin_burrow_exit.vpcf", context)
  PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_nyx_assassin.vsndevts", context)
end

function kobold_dig_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local position = self:GetCursorPosition()

  if not position then
    return
  end

  -- Particle
  self.pfx = ParticleManager:CreateParticle("particles/econ/events/ti9/shovel_dig.vpcf", PATTACH_WORLDORIGIN, caster)
  ParticleManager:SetParticleControl(self.pfx, 0, position)

  -- Sound
  caster:EmitSound("SeasonalConsumable.TI9.Shovel.Dig")
end

function kobold_dig_oaa:OnChannelFinish(bInterrupted)
  local caster = self:GetCaster()
  local position = self:GetCursorPosition()

  -- Remove particle, doesn't matter if channel is successful or not
  if self.pfx then
    ParticleManager:DestroyParticle(self.pfx, false)
    ParticleManager:ReleaseParticleIndex(self.pfx)
  end

  -- Stop sound, doesn't matter if channel is successful or not
  caster:StopSound("SeasonalConsumable.TI9.Shovel.Dig")

  -- If channel was cancelled or interrupted, don't continue
  if bInterrupted then
    return
  end

  -- Dig In (root, banish, silence, mute, blind, invulnerable etc.)
  FindClearSpaceForUnit(caster, position, true)
  caster:AddNewModifier(caster, self, "modifier_kobold_dig_oaa_buff", {duration = self:GetSpecialValueFor("duration")})

  -- Hide the model
  caster:AddNoDraw()
end

-----------------------------------------------------------------------------------------------------------------------------------------------------

modifier_kobold_dig_oaa_buff = class({})

function modifier_kobold_dig_oaa_buff:IsHidden()
  return false
end

function modifier_kobold_dig_oaa_buff:IsDebuff()
  return false
end

function modifier_kobold_dig_oaa_buff:IsPurgable()
  return false
end

function modifier_kobold_dig_oaa_buff:CheckState()
  return {
    [MODIFIER_STATE_ROOTED] = true,
    [MODIFIER_STATE_DISARMED] = true,
    [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    [MODIFIER_STATE_SILENCED] = true,
    [MODIFIER_STATE_MUTED] = true,
    --[MODIFIER_STATE_INVISIBLE] = true,
    [MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_BLIND] = true,
    [MODIFIER_STATE_OUT_OF_GAME] = true,
    [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
    [MODIFIER_STATE_DEBUFF_IMMUNE] = true,
  }
end

if IsServer() then
  function modifier_kobold_dig_oaa_buff:OnDestroy()
    local parent = self:GetParent()

    -- Sound
    parent:EmitSound("Hero_NyxAssassin.Burrow.Out")

    -- Particle
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_nyx_assassin/nyx_assassin_burrow_exit.vpcf", PATTACH_ABSORIGIN, parent)
    ParticleManager:SetParticleControl(particle, 0, parent:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(particle)

    -- Unhide the model
    parent:RemoveNoDraw()
  end
end
