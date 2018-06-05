LinkLuaModifier( "modifier_item_reactive_reflect", "items/reflex/reactive_reflect.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_charge_replenisher", "modifiers/modifier_charge_replenisher.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_generic_bonus", "modifiers/modifier_generic_bonus.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier( "modifier_intrinsic_multiplexer", "modifiers/modifier_intrinsic_multiplexer.lua", LUA_MODIFIER_MOTION_NONE)

item_reflection_shard_1 = class(ItemBaseClass)
item_reflection_shard_2 = item_reflection_shard_1
item_reflection_shard_3 = item_reflection_shard_1

function item_reflection_shard_1:GetIntrinsicModifierName()
    return "modifier_charge_replenisher"
end

function item_reflection_shard_1:OnSpellStart()
  local charges = self:GetCurrentCharges()
  if charges <= 0 then
    return false
  end

  local caster = self:GetCaster()
  local duration = self:GetSpecialValueFor( "duration" )

  self:SetCurrentCharges( charges - 1 )
  if charges == 1 then
    self:StartCooldown(self:GetCooldownTime())
  end

  local chargeReplenishIn = self:GetCooldownTime()

  caster:AddNewModifier( caster, self, "modifier_item_reactive_reflect", { duration = duration } )
end

modifier_item_reactive_reflect = class(ModifierBaseClass)

function modifier_item_reactive_reflect:IsHidden()
  return false
end

function modifier_item_reactive_reflect:OnCreated( event )
  if IsServer() and self.nPreviewFX == nil then
    self:GetParent():EmitSound( "Item.LotusOrb.Target" )
    self.nPreviewFX = ParticleManager:CreateParticle( "particles/items/reflection_shard/reflection_shield.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
  end
end

function modifier_item_reactive_reflect:OnDestroy(  )
  if IsServer() and self.nPreviewFX ~= nil then
    self:GetParent():EmitSound( "Item.LotusOrb.Destroy" )
    ParticleManager:DestroyParticle( self.nPreviewFX, false )
    ParticleManager:ReleaseParticleIndex(self.nPreviewFX)
    self.nPreviewFX = nil
  end
end

function modifier_item_reactive_reflect:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
    MODIFIER_PROPERTY_ABSORB_SPELL,
    MODIFIER_PROPERTY_REFLECT_SPELL,
  }
end

function modifier_item_reactive_reflect:GetAbsoluteNoDamagePhysical()
  return 1
end

function modifier_item_reactive_reflect:GetAbsoluteNoDamageMagical()
  return 1
end

function modifier_item_reactive_reflect:GetAbsoluteNoDamagePure()
  return 1
end

function modifier_item_reactive_reflect:GetAbsorbSpell()
  return 1
end

function modifier_item_reactive_reflect:GetReflectSpell(kv)
  if self.stored ~= nil then
      self.stored:RemoveSelf() --we make sure to remove previous spell.
  end

  if IsServer() then
    local hCaster = self:GetParent()
    hCaster:EmitSound( "Item.LotusOrb.Activate" )

    local burst = ParticleManager:CreateParticle( "particles/items/reflection_shard/immunity_sphere_yellow.vpcf", PATTACH_ABSORIGIN, self:GetParent() )
    Timers:CreateTimer(1.5, function()
      ParticleManager:DestroyParticle( burst, false )
      ParticleManager:ReleaseParticleIndex(burst)
    end)

    local hAbility = hCaster:AddAbility(kv.ability:GetAbilityName())

    if hAbility ~= nil then
      hAbility:SetStolen(true) --just to be safe with some interactions.
      hAbility:SetHidden(true) --hide the ability.
      hAbility:SetLevel(kv.ability:GetLevel()) --same level of ability as the origin.
      hCaster:SetCursorCastTarget(kv.ability:GetCaster()) --lets send this spell back.
      hAbility:OnSpellStart() --cast the spell.
      print("abilityCount")
      print(hCaster:GetAbilityCount(  ))
      --
      self.stored = hAbility --store the spell reference for future use.
    end
  end

end
