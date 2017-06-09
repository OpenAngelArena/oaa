LinkLuaModifier("modifier_generic_bonus", "modifiers/modifier_generic_bonus.lua", LUA_MODIFIER_MOTION_NONE)

item_dagon = class({})
item_dagon_2 = item_dagon
item_dagon_3 = item_dagon
item_dagon_4 = item_dagon
item_dagon_5 = item_dagon
item_dagon_6 = item_dagon
item_dagon_7 = item_dagon
item_dagon_8 = item_dagon
item_dagon_9 = item_dagon


function item_dagon:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()
  local level = self:GetLevel()

  local soundCaster = "DOTA_Item.Dagon.Activate"
  local soundTarget = "DOTA_Item.Dagon5.Target"

  local particleName = "particles/items/dagon_oaa.vpcf"
  local particleThickness = 300 + (100 * level) --Control Point 2 in Dagon's particle effect takes a number between 400 and 2000, depending on its level.

  local damage = self:GetSpecialValueFor("damage")

  local particle = ParticleManager:CreateParticle(particleName,  PATTACH_POINT_FOLLOW, caster)
  ParticleManager:SetParticleControlEnt(particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetOrigin(), true)
  ParticleManager:SetParticleControlEnt(particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetOrigin(), true)
  ParticleManager:SetParticleControl(particle, 2, Vector(particleThickness))
  ParticleManager:ReleaseParticleIndex(particle)


  caster:EmitSound("DOTA_Item.Dagon.Activate")
  if level >= 5 then
    target:EmitSound("DOTA_Item.Dagon5.Target")
  end

  ApplyDamage({
    victim = target,
    attacker = caster,
    damage = damage,
    damage_type = DAMAGE_TYPE_MAGICAL,
    ability = self
  })
end

function item_dagon:GetIntrinsicModifierName()
  return "modifier_generic_bonus"
end
