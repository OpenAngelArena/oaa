LinkLuaModifier("modifier_universal_summons_oaa", "modifiers/funmodifiers/modifier_universal_oaa.lua", LUA_MODIFIER_MOTION_NONE)

modifier_universal_oaa = class(ModifierBaseClass)

function modifier_universal_oaa:IsHidden()
  return false
end

function modifier_universal_oaa:IsDebuff()
  return false
end

function modifier_universal_oaa:IsPurgable()
  return false
end

function modifier_universal_oaa:RemoveOnDeath()
  return false
end

function modifier_universal_oaa:OnCreated()
  self.stack_uni = 25
  self.stack_other = 5
  self.spell_amp_uni = 25
  self.spell_amp_other = 5
  self.heal_amp_uni = 25
  self.heal_amp_other = 5

  if not IsServer() then
    return
  end

  local parent = self:GetParent()

  -- Check if parent has the stuff
  if parent.GetPrimaryAttribute == nil then
    return
  end

  local old_primary_attribute = parent:GetPrimaryAttribute()
  if old_primary_attribute == DOTA_ATTRIBUTE_ALL then
    self:SetStackCount(self.stack_uni)
  else
    self:SetStackCount(self.stack_other)
  end

  -- Change Primary attribute
  parent:SetPrimaryAttribute(DOTA_ATTRIBUTE_ALL)
end

function modifier_universal_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE,
    MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
    MODIFIER_PROPERTY_TOOLTIP,
  }
end

function modifier_universal_oaa:GetModifierSpellAmplify_Percentage()
  if self:GetStackCount() == self.stack_uni then
    return self.spell_amp_uni
  else
    return self.spell_amp_other
  end
end

function modifier_universal_oaa:GetModifierHealAmplify_PercentageSource()
  if self:GetStackCount() == self.stack_uni then
    return self.heal_amp_uni
  else
    return self.heal_amp_other
  end
end

function modifier_universal_oaa:GetModifierHealAmplify_PercentageTarget()
  if self:GetStackCount() == self.stack_uni then
    return self.heal_amp_uni
  else
    return self.heal_amp_other
  end
end

function modifier_universal_oaa:OnTooltip()
  return self:GetStackCount()
end

function modifier_universal_oaa:IsAura()
  return true
end

function modifier_universal_oaa:GetModifierAura()
  return "modifier_universal_summons_oaa"
end

function modifier_universal_oaa:GetAuraRadius()
  return 50000
end

function modifier_universal_oaa:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_universal_oaa:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_OTHER)
end

function modifier_universal_oaa:GetAuraEntityReject(hEntity)
  local caster = self:GetCaster()
  -- Dont provide the aura effect to the caster and allies that you can't control
  if hEntity ~= caster then
    if IsServer() then
      if UnitVarToPlayerID(hEntity) ~= UnitVarToPlayerID(caster) then
        return true
      end
    else
      if hEntity.GetPlayerOwnerID then
        if hEntity:GetPlayerOwnerID() ~= caster:GetPlayerOwnerID() then
          return true
        end
      end
    end
  else
    return true
  end

  return false
end

function modifier_universal_oaa:GetTexture()
  return "item_ultimate_orb"
end

---------------------------------------------------------------------------------------------------

modifier_universal_summons_oaa = class(ModifierBaseClass)

function modifier_universal_summons_oaa:IsHidden()
  return true
end

function modifier_universal_summons_oaa:IsDebuff()
  return false
end

function modifier_universal_summons_oaa:IsPurgable()
  return false
end

function modifier_universal_summons_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
    MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
  }
end

if IsServer() then
  function modifier_universal_summons_oaa:GetModifierTotal_ConstantBlock(event)
    local caster = self:GetCaster()
    local attacker = event.attacker

    if not attacker or attacker:IsNull() then
      return 0
    end

    if attacker.IsBaseNPC == nil then
      return 0
    end

    if not attacker:IsBaseNPC() then
      return 0
    end

    local dmg_reduction = caster:GetModifierStackCount("modifier_universal_oaa", caster)

    -- Block damage
    return event.damage * dmg_reduction / 100
  end

  function modifier_universal_summons_oaa:GetModifierTotalDamageOutgoing_Percentage(event)
    local caster = self:GetCaster()
    return caster:GetModifierStackCount("modifier_universal_oaa", caster)
  end
end
