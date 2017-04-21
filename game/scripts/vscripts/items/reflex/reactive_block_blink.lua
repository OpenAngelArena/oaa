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
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
  }
end

function modifier_item_reactive_2b:GetModifierIncomingDamage_Percentage()
  return -100
end

function modifier_item_reactive_2b:GetAbsorbSpell()
  if self.hasBlinked then
    return true
  end

  local caster = self:GetCaster()
  local casterTeam = caster:GetTeamNumber()

  self.hasBlinked = true

  function IsAlly(entity)
    return entity:GetTeamNumber() == casterTeam
  end

  local fountains = Entities:FindAllByClassname("ent_dota_fountain")
  local hTarget = head(filter(IsAlly, iter(fountains)))

  local direction = (hTarget:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
  FindClearSpaceForUnit(caster, caster:GetAbsOrigin() + (direction * self:GetAbility():GetSpecialValueFor("distance")), false)

  return true
end
