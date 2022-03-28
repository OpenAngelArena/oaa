item_devDagger = class(ItemBaseClass)

function item_devDagger:OnSpellStart()
  local target = self:GetCursorPosition()
  local caster = self:GetCaster()

  -- Start Sound
  caster:EmitSound("DOTA_Item.BlinkDagger.Activate")

  -- Start Particle
  local blink_start_particle = ParticleManager:CreateParticle("particles/items_fx/blink_dagger_start.vpcf", PATTACH_ABSORIGIN, caster)
  ParticleManager:SetParticleControl(blink_start_particle, 0, caster:GetAbsOrigin())
  ParticleManager:ReleaseParticleIndex(blink_start_particle)

  -- Teleporting caster and preventing getting stuck
  FindClearSpaceForUnit(caster, target, false)

  -- Disjoint disjointable/dodgeable projectiles
  ProjectileManager:ProjectileDodge(caster)

  -- End Particle
  local blink_end_particle = ParticleManager:CreateParticle("particles/items_fx/blink_dagger_end.vpcf", PATTACH_ABSORIGIN, caster)
  ParticleManager:ReleaseParticleIndex(blink_end_particle)

  -- End Sound
  caster:EmitSound("DOTA_Item.BlinkDagger.NailedIt")
end
