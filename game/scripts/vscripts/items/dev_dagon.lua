item_devDagon = class(ItemBaseClass)

function item_devDagon:OnSpellStart()
  local target = self:GetCursorTarget()
  local caster = self:GetCaster()

  target:Kill(self, caster)

  local particleName = "particles/items_fx/dagon.vpcf"
  local particle = ParticleManager:CreateParticle(particleName, PATTACH_POINT_FOLLOW, caster)
  ParticleManager:SetParticleControlEnt(particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetOrigin(), true)
  ParticleManager:SetParticleControlEnt(particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetOrigin(), true)
  ParticleManager:SetParticleControl(particle, 2, Vector(2000))
  ParticleManager:ReleaseParticleIndex(particle)

  caster:EmitSound("DOTA_Item.Dagon.Activate")
  target:EmitSound("DOTA_Item.Dagon5.Target")
end
