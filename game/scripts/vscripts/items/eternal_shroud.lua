LinkLuaModifier("modifier_item_eternal_shroud_oaa", "items/eternal_shroud.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_eternal_shroud_oaa_barrier", "items/eternal_shroud.lua", LUA_MODIFIER_MOTION_NONE)

---------------------------------------------------------------------------------------------------

item_eternal_shroud_oaa = class(ItemBaseClass)

function item_eternal_shroud_oaa:GetIntrinsicModifierName()
  return "modifier_intrinsic_multiplexer"
end

function item_eternal_shroud_oaa:GetIntrinsicModifierNames()
  return {
    "modifier_item_eternal_shroud_oaa",
    "modifier_item_spell_lifesteal_oaa"
  }
end

function item_eternal_shroud_oaa:OnSpellStart()
  local hCaster = self:GetCaster()
  local barrier_duration = self:GetSpecialValueFor("barrier_duration")

  -- Sound
  hCaster:EmitSound("DOTA_Item.Pipe.Activate")
  -- Remove previous instance
  hCaster:RemoveModifierByName("modifier_eternal_shroud_oaa_barrier")
  -- Apply new instance
  hCaster:AddNewModifier(hCaster, self, "modifier_eternal_shroud_oaa_barrier", {duration = barrier_duration})
end

item_eternal_shroud_oaa_2 = item_eternal_shroud_oaa
item_eternal_shroud_oaa_3 = item_eternal_shroud_oaa
item_eternal_shroud_oaa_4 = item_eternal_shroud_oaa
item_eternal_shroud_oaa_5 = item_eternal_shroud_oaa

---------------------------------------------------------------------------------------------------

modifier_item_eternal_shroud_oaa = class(ModifierBaseClass)

function modifier_item_eternal_shroud_oaa:IsHidden()
  return true
end

function modifier_item_eternal_shroud_oaa:IsDebuff()
  return false
end

function modifier_item_eternal_shroud_oaa:IsPurgable()
  return false
end

function modifier_item_eternal_shroud_oaa:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_eternal_shroud_oaa:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_magic_resist = ability:GetSpecialValueFor("bonus_spell_resist")
    self.hp_regen = ability:GetSpecialValueFor("bonus_health_regen")
    self.hp = ability:GetSpecialValueFor("bonus_health")
  end
end

modifier_item_eternal_shroud_oaa.OnRefresh = modifier_item_eternal_shroud_oaa.OnCreated

function modifier_item_eternal_shroud_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    MODIFIER_PROPERTY_HEALTH_BONUS,
  }
end

function modifier_item_eternal_shroud_oaa:GetModifierConstantHealthRegen()
  return self.hp_regen or self:GetAbility():GetSpecialValueFor("bonus_health_regen")
end

function modifier_item_eternal_shroud_oaa:GetModifierMagicalResistanceBonus()
  return self.bonus_magic_resist or self:GetAbility():GetSpecialValueFor("bonus_spell_resist")
end

function modifier_item_eternal_shroud_oaa:GetModifierHealthBonus()
  return self.hp or self:GetAbility():GetSpecialValueFor("bonus_health")
end

---------------------------------------------------------------------------------------------------

modifier_eternal_shroud_oaa_barrier = class(ModifierBaseClass)

function modifier_eternal_shroud_oaa_barrier:IsHidden()
  return true
end

function modifier_eternal_shroud_oaa_barrier:IsDebuff()
  return false
end

function modifier_eternal_shroud_oaa_barrier:IsPurgable()
  return false
end

function modifier_eternal_shroud_oaa_barrier:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.max_shield_hp = ability:GetSpecialValueFor("barrier_block")
  end
  if IsServer() then
    local parent = self:GetParent()
    if not self.particle then
      self.particle = ParticleManager:CreateParticle("particles/items2_fx/eternal_shroud.vpcf", PATTACH_OVERHEAD_FOLLOW, parent)
      ParticleManager:SetParticleControl(self.particle, 0, parent:GetAbsOrigin())
      ParticleManager:SetParticleControlEnt(self.particle, 1, parent, PATTACH_POINT_FOLLOW, "attach_origin", parent:GetAbsOrigin(), true)
      ParticleManager:SetParticleControl(self.particle, 2, Vector(parent:GetModelRadius()*1.1, 0, 0))
    end
    self:SetStackCount(self.max_shield_hp)
  end
end

modifier_eternal_shroud_oaa_barrier.OnRefresh = modifier_eternal_shroud_oaa_barrier.OnCreated

function modifier_eternal_shroud_oaa_barrier:OnDestroy()
  if IsServer() and self.particle then
    ParticleManager:DestroyParticle(self.particle, true)
    ParticleManager:ReleaseParticleIndex(self.particle)
    self.particle = nil
  end
end

function modifier_eternal_shroud_oaa_barrier:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_INCOMING_SPELL_DAMAGE_CONSTANT,
  }
end

function modifier_eternal_shroud_oaa_barrier:GetModifierIncomingSpellDamageConstant(event)
  if IsClient() then
    if event.report_max then
      return self.max_shield_hp
    else
      return self:GetStackCount() -- current shield hp
    end
  else
    if event.damage_type == DAMAGE_TYPE_MAGICAL then
      local parent = self:GetParent()
      local damage = event.damage
      local barrier_hp = self:GetStackCount()

      -- Don't block more than remaining barrier hp
      local block_amount = math.min(damage, barrier_hp)

      -- Reduce barrier hp
      self:SetStackCount(barrier_hp - block_amount)

      if block_amount > 0 then
        -- Visual effect
        SendOverheadEventMessage(nil, OVERHEAD_ALERT_MANA_ADD, parent, block_amount, nil)
        -- Give mana to the parent, mana amount is equal to block amount
        parent:GiveMana(block_amount)
      end

      -- Destroy the modifier if barrier hp is reduced to 0
      if self:GetStackCount() <= 0 then
        self:Destroy()
      end

      return -block_amount
    end

    return 0
  end
end
