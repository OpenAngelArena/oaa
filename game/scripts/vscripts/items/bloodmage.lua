---
--- Created by Zarnotox.
--- DateTime: 03-Dec-17 21:32
---

item_bloodmage = class(ItemBaseClass)

LinkLuaModifier( "modifier_item_bloodmage_sangromancy", "items/bloodmage.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

function item_bloodmage:GetAbilityTextureName()
  local baseName = self.BaseClass.GetAbilityTextureName( self )

  local activeName = ""

  if self.mod and not self.mod:IsNull() then
    activeName = "_active"
  end

  return baseName .. activeName
end

--------------------------------------------------------------------------------

function item_bloodmage:GetIntrinsicModifierName()
  return "item_bloodmage"
end

--------------------------------------------------------------------------------

function item_bloodmage:OnSpellStart()
  local caster = self:GetCaster()

  -- if we have the modifier while this thing is "toggled"
  -- ( which we should, but 'should' isn't a concept in programming )
  -- remove it
  local mod = caster:FindModifierByName( "modifier_item_bloodmage_sangromancy" )

  if mod and not mod:IsNull() then
    mod:Destroy()

    -- caster:EmitSound( "OAA_Item.SiegeMode.Deactivate" )
  else
    -- if it isn't toggled, add the modifier and keep track of it
    caster:AddNewModifier( caster, self, "modifier_item_bloodmage_sangromancy", {} )

    -- caster:EmitSound( "OAA_Item.SiegeMode.Activate" )
  end
end

--------------------------------------------------------------------------------

modifier_item_bloodmage_sangromancy = class(ModifierBaseClass)

--------------------------------------------------------------------------------

function modifier_item_bloodmage_sangromancy:IsHidden()
  return false
end

function modifier_item_bloodmage_sangromancy:IsDebuff()
  return false
end

function modifier_item_bloodmage_sangromancy:IsPurgable()
  return false
end


--------------------------------------------------------------------------------

function modifier_item_bloodmage_sangromancy:OnCreated( event )
  local spell = self:GetAbility()

  spell.mod = self

  self.spellamp = spell:GetSpecialValueFor( "sangromancy_spell_amp" )
  self.selfDamage = spell:GetSpecialValueFor( "sangromancy_self_damage" )
end

--------------------------------------------------------------------------------

function modifier_item_bloodmage_sangromancy:OnRefresh( event )
  local spell = self:GetAbility()

  spell.mod = self

  self.spellamp = spell:GetSpecialValueFor( "sangromancy_spell_amp" )
  self.selfDamage = spell:GetSpecialValueFor( "sangromancy_self_damage" )
end

--------------------------------------------------------------------------------

function modifier_item_bloodmage_sangromancy:OnRemoved()
  local spell = self:GetAbility()

  if spell and not spell:IsNull() then
    spell.mod = nil
  end
end

--------------------------------------------------------------------------------

function modifier_item_bloodmage_sangromancy:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
    MODIFIER_EVENT_ON_TAKEDAMAGE,
  }

  return funcs
end

--------------------------------------------------------------------------------

function modifier_item_bloodmage_sangromancy:GetModifierSpellAmplify_Percentage( event )
  local spell = self:GetAbility()

  return self.spellamp or spell:GetSpecialValueFor( "sangromancy_spell_amp" )
end

--------------------------------------------------------------------------------

function modifier_item_bloodmage_sangromancy:OnTakeDamage(event)
  if event.damage_category == 0 and event.attacker == self:GetCaster() and not (event.unit == self:GetCaster()) then

    local damage = {
      victim = event.attacker,
      attacker = event.attacker,
      damage = event.original_damage * (self.selfDamage / 100),
      damage_type = event.damage_type,
      ability = event.inflictor,
    }

    ApplyDamage( damage )

  end
end

--------------------------------------------------------------------------------

item_bloodmage_2 = item_bloodmage