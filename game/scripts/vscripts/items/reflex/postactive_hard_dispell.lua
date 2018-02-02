LinkLuaModifier("modifier_generic_bonus", "modifiers/modifier_generic_bonus.lua", LUA_MODIFIER_MOTION_NONE)

item_enrage_crystal_1 = class(ItemBaseClass)
item_enrage_crystal_2 = item_enrage_crystal_1
item_enrage_crystal_3 = item_enrage_crystal_1

function item_enrage_crystal_1:GetIntrinsicModifierName()
  return "modifier_generic_bonus"
end

function item_enrage_crystal_1:OnSpellStart()
  local caster = self:GetCaster()

  caster:Purge(false, true, false, true, true)
  caster:EmitSound("Hero_Abaddon.AphoticShield.Cast")
  local particleName1 = "particles/items/enrage_crystal/enrage_crystal_explosion.vpcf"
  local particle1 = ParticleManager:CreateParticle(particleName1, PATTACH_ABSORIGIN_FOLLOW, caster)
end
