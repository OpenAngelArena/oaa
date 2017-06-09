item_devDagon = class({})

function item_devDagon:OnSpellStart()
  local target = self:GetCursorTarget()
  local caster = self:GetCaster()

  target:Kill(self, caster)

  local particle1Name = "particles/items_fx/dagon.vpcf"
  local particle1 = ParticleManager:CreateParticle(particle1Name, PATTACH_POINT_FOLLOW, caster)
  ParticleManager:SetParticleControlEnt(particle1, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetOrigin(), true)
  ParticleManager:SetParticleControlEnt(particle1, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetOrigin(), true)
  ParticleManager:SetParticleControl(particle1, 2, Vector(2000, 0, 0))
  ParticleManager:ReleaseParticleIndex(particle1)

  EmitSoundOn("DOTA_Item.Dagon5.Target", target)
end
