-- Azazel's Sustainability Elixiers
-- by Firetoad, April 1st, 2018

--------------------------------------------------------------------------------

LinkLuaModifier("modifier_elixier_sustain_active", "items/elixier_sustain.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_elixier_sustain_trigger", "items/elixier_sustain.lua", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

item_elixier_sustain = class(ItemBaseClass)

function item_elixier_sustain:OnSpellStart()
  local caster = self:GetCaster()

  caster:EmitSound("DOTA_Item.FaerieSpark.Activate")

  caster:RemoveModifierByName("modifier_elixier_burst_active")
  caster:RemoveModifierByName("modifier_elixier_burst_trigger")
  caster:RemoveModifierByName("modifier_elixier_burst_bonus")
  caster:RemoveModifierByName("modifier_elixier_sustain_active")
  caster:RemoveModifierByName("modifier_elixier_sustain_trigger")
  caster:RemoveModifierByName("modifier_elixier_hybrid_active")
  caster:RemoveModifierByName("modifier_elixier_hybrid_trigger")

  caster:AddNewModifier(caster, self, "modifier_elixier_sustain_active", {duration = self:GetSpecialValueFor("bonus_duration")})

  self:SpendCharge()
end

--------------------------------------------------------------------------------

modifier_elixier_sustain_active = class(ModifierBaseClass)

function modifier_elixier_sustain_active:IsHidden()
  return false
end

function modifier_elixier_sustain_active:IsPurgable()
  return false
end

function modifier_elixier_sustain_active:IsDebuff()
  return false
end

function modifier_elixier_sustain_active:RemoveOnDeath()
  return false
end

function modifier_elixier_sustain_active:GetEffectName()
  return "particles/generic_gameplay/rune_regeneration_sparks.vpcf"
end

function modifier_elixier_sustain_active:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_elixier_sustain_active:GetTexture()
  return "custom/elixier_sustain_2"
end

function modifier_elixier_sustain_active:OnCreated()
  if IsServer() then
    self.regen = self:GetAbility():GetSpecialValueFor("bonus_hp_regen")
    self.dmg_reduction = self:GetAbility():GetSpecialValueFor("bonus_dmg_reduction")
    self:SetStackCount(self.regen)
    self:StartIntervalThink(0.03)
  end
end

function modifier_elixier_sustain_active:OnIntervalThink()
  if IsServer() then
    local caster = self:GetParent()
    if caster:IsStunned() or caster:IsHexed() or caster:IsOutOfGame() then
      if not caster:HasModifier("modifier_elixier_sustain_trigger") then
        caster:AddNewModifier(caster, self:GetAbility(), "modifier_elixier_sustain_trigger", {dmg_reduction = self.dmg_reduction})
      end
    else
      caster:RemoveModifierByName("modifier_elixier_sustain_trigger")
    end
  end
end

function modifier_elixier_sustain_active:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
  }
end

function modifier_elixier_sustain_active:GetModifierConstantHealthRegen()
  return self:GetStackCount()
end

--------------------------------------------------------------------------------

modifier_elixier_sustain_trigger = class(ModifierBaseClass)

function modifier_elixier_sustain_trigger:IsHidden()
  return false
end

function modifier_elixier_sustain_trigger:IsPurgable()
  return false
end

function modifier_elixier_sustain_trigger:IsDebuff()
  return false
end

function modifier_elixier_sustain_trigger:GetEffectName()
  return "particles/generic_gameplay/rune_regeneration.vpcf"
end

function modifier_elixier_sustain_trigger:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_elixier_sustain_trigger:GetTexture()
  return "custom/elixier_sustain_2"
end

function modifier_elixier_sustain_trigger:OnCreated(keys)
  if IsServer() then
    self.dmg_reduction = keys.dmg_reduction
  end
end

function modifier_elixier_sustain_trigger:DeclareFunctions()
  return {
    --MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
  }
end

-- function modifier_elixier_sustain_trigger:GetModifierIncomingDamage_Percentage()
  -- if IsServer() then
    -- return (-1) * self.dmg_reduction
  -- end
-- end

function modifier_elixier_sustain_trigger:GetModifierTotal_ConstantBlock(event)
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  local damage = event.damage

  local block_amount = damage * self.dmg_reduction / 100

  if block_amount > 0 then
    -- Visual effect
    local alert_type = OVERHEAD_ALERT_MAGICAL_BLOCK
    if event.damage_type == DAMAGE_TYPE_PHYSICAL then
      alert_type = OVERHEAD_ALERT_BLOCK
    end

    SendOverheadEventMessage(nil, alert_type, parent, block_amount, nil)
  end

  return block_amount
end
