LinkLuaModifier( "modifier_item_reactive_2b", "items/reflex/reactive_block_blink.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_generic_bonus", "modifiers/modifier_generic_bonus.lua", LUA_MODIFIER_MOTION_NONE)

item_reactive_2b = class({})

function item_reactive_2b:GetIntrinsicModifierName()
  return "modifier_generic_bonus"
end

function item_reactive_2b:OnSpellStart()
  local caster = self:GetCaster()
  local duration = self:GetSpecialValueFor("duration")

  caster:AddNewModifier( caster, self, "modifier_item_reactive_2b", { duration = duration } )
end

modifier_item_reactive_2b = class({})

function modifier_item_reactive_2b:IsHidden()
  return false
end

function modifier_item_reactive_2b:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ABSORB_SPELL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE
  }
end

function modifier_item_reactive_2b:GetAbsoluteNoDamagePhysical()
  return 1
end

function modifier_item_reactive_2b:GetAbsoluteNoDamageMagical()
  return 1
end

function modifier_item_reactive_2b:GetAbsoluteNoDamagePure()
  return 1
end

function modifier_item_reactive_2b:GetAbsorbSpell()
  if self.hasBlinked then
    return 1
  end

  local caster = self:GetCaster()
  local casterTeam = caster:GetTeamNumber()

  self.hasBlinked = true

  local function IsAlly(entity)
    return entity:GetTeamNumber() == casterTeam
  end

  local fountains = Entities:FindAllByClassname("ent_dota_fountain")
  local hTarget = head(filter(IsAlly, iter(fountains)))

  local startParticleName = "particles/items_fx/blink_dagger_start.vpcf"
  local endParticleName = "particles/items_fx/blink_dagger_end.vpcf"
  local startParticle = ParticleManager:CreateParticle(startParticleName, PATTACH_ABSORIGIN, caster)
  ParticleManager:ReleaseParticleIndex(startParticle)

  local direction = (hTarget:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
  FindClearSpaceForUnit(caster, caster:GetAbsOrigin() + (direction * self:GetAbility():GetSpecialValueFor("distance")), false)

  local endParticle = ParticleManager:CreateParticle(endParticleName, PATTACH_ABSORIGIN, caster)
  ParticleManager:ReleaseParticleIndex(endParticle)

  EmitSoundOn("DOTA_Item.BlinkDagger.Activate", caster)

  return 1
end
