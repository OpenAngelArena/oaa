wanderer_aoe_cleanse = class(AbilityBaseClass)

function wanderer_aoe_cleanse:Precache(context)
  PrecacheResource("particle", "particles/dark_moon/darkmoon_creep_warning.vpcf", context)
  PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_batrider.vsndevts", context)
end

function wanderer_aoe_cleanse:OnAbilityPhaseStart()
  if IsServer() then
    local caster = self:GetCaster()
    self.nPreviewFX = ParticleManager:CreateParticle("particles/dark_moon/darkmoon_creep_warning.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControlEnt(self.nPreviewFX, 0, caster, PATTACH_ABSORIGIN_FOLLOW, nil, caster:GetOrigin(), true)
    ParticleManager:SetParticleControl(self.nPreviewFX, 1, Vector(175, 175, 175))
    ParticleManager:SetParticleControl(self.nPreviewFX, 15, Vector(255, 140, 0))
  end
  return true
end

function wanderer_aoe_cleanse:OnAbilityPhaseInterrupted()
	if IsServer() then
    if self.nPreviewFX then
      ParticleManager:DestroyParticle(self.nPreviewFX, true)
      ParticleManager:ReleaseParticleIndex(self.nPreviewFX)
      self.nPreviewFX = nil
    end
  end
end

function wanderer_aoe_cleanse:OnSpellStart()
  -- Remove ability phase (cast) particle
  if self.nPreviewFX then
    ParticleManager:DestroyParticle(self.nPreviewFX, true)
    ParticleManager:ReleaseParticleIndex(self.nPreviewFX)
    self.nPreviewFX = nil
  end
end


