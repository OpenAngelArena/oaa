LinkLuaModifier("modifier_item_butterfly_oaa_passive", "items/butterfly.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_butterfly_oaa_active", "items/butterfly.lua", LUA_MODIFIER_MOTION_NONE)

item_butterfly_oaa = class(ItemBaseClass)

function item_butterfly_oaa:GetIntrinsicModifierName()
  return "modifier_item_butterfly_oaa_passive"
end

function item_butterfly_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local buff_duration = self:GetSpecialValueFor("buff_duration")

  -- Apply a Butterfly special buff to the caster
  caster:AddNewModifier(caster, self, "modifier_item_butterfly_oaa_active", {duration = buff_duration})

  -- Sound
  caster:EmitSound("DOTA_Item.Butterfly")
end

item_butterfly_2 = item_butterfly_oaa
item_butterfly_3 = item_butterfly_oaa
item_butterfly_4 = item_butterfly_oaa
item_butterfly_5 = item_butterfly_oaa

---------------------------------------------------------------------------------------------------

modifier_item_butterfly_oaa_passive = class(ModifierBaseClass)

function modifier_item_butterfly_oaa_passive:IsHidden()
  return true
end

function modifier_item_butterfly_oaa_passive:IsDebuff()
  return false
end

function modifier_item_butterfly_oaa_passive:IsPurgable()
  return false
end

function modifier_item_butterfly_oaa_passive:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_butterfly_oaa_passive:OnCreated()
  self:OnRefresh()
  self:StartIntervalThink(0.3)
end

function modifier_item_butterfly_oaa_passive:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.agi = ability:GetSpecialValueFor("bonus_agility")
    self.evasion = ability:GetSpecialValueFor("bonus_evasion")
    self.attack_speed = ability:GetSpecialValueFor("bonus_attack_speed")
    self.as_per_agi = ability:GetSpecialValueFor("bonus_attack_speed_per_agility_pct")
    self.dmg = ability:GetSpecialValueFor("bonus_damage")
  end

  if IsServer() then
    -- Check only on the server
    if self:IsFirstItemInInventory() then
      self:SetStackCount(2)
    else
      self:SetStackCount(1)
    end
  end
end

function modifier_item_butterfly_oaa_passive:OnIntervalThink()
  if IsServer() then
    if self:IsFirstItemInInventory() then
      self:SetStackCount(2)
    else
      self:SetStackCount(1)
    end
  end
end

function modifier_item_butterfly_oaa_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_EVASION_CONSTANT,
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
  }
end

function modifier_item_butterfly_oaa_passive:GetModifierBonusStats_Agility()
  return self.agi or self:GetAbility():GetSpecialValueFor("bonus_agility")
end

function modifier_item_butterfly_oaa_passive:GetModifierAttackSpeedBonus_Constant()
  -- Prevent stacking with itself
  if self:GetStackCount() ~= 2 then
    return 0
  end
  local parent = self:GetParent()
  if parent.GetAgility == nil then
    return self.attack_speed or self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
  end
  return self.attack_speed + (self.as_per_agi * parent:GetAgility() * 0.01)
end

function modifier_item_butterfly_oaa_passive:GetModifierEvasion_Constant()
  return self.evasion or self:GetAbility():GetSpecialValueFor("bonus_evasion")
end

function modifier_item_butterfly_oaa_passive:GetModifierPreAttack_BonusDamage()
  return self.dmg or self:GetAbility():GetSpecialValueFor("bonus_damage")
end

---------------------------------------------------------------------------------------------------

modifier_item_butterfly_oaa_active = class(ModifierBaseClass)

function modifier_item_butterfly_oaa_active:IsHidden()
  return false
end

function modifier_item_butterfly_oaa_active:IsDebuff()
  return false
end

function modifier_item_butterfly_oaa_active:IsPurgable()
  return false
end

function modifier_item_butterfly_oaa_active:OnCreated()
  local parent = self:GetParent()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.move_speed = ability:GetSpecialValueFor("buff_ms_per_agility")
    self.evasion = ability:GetSpecialValueFor("buff_evasion")
  end

  if parent:IsRealHero() then
    self.agi = parent:GetAgility()
  end
end

modifier_item_butterfly_oaa_active.OnRefresh = modifier_item_butterfly_oaa_active.OnCreated

function modifier_item_butterfly_oaa_active:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_EVASION_CONSTANT,
  }
end

function modifier_item_butterfly_oaa_active:GetModifierMoveSpeedBonus_Percentage()
  local ms_per_agi = self.move_speed or self:GetAbility():GetSpecialValueFor("buff_ms_per_agility")
  if self.agi and ms_per_agi then
    return ms_per_agi * self.agi
  end

  return 0
end

function modifier_item_butterfly_oaa_active:GetModifierEvasion_Constant()
  return self.evasion or self:GetAbility():GetSpecialValueFor("buff_evasion")
end

function modifier_item_butterfly_oaa_active:GetEffectName()
  return "particles/ui/blessing_icon_unlock_green.vpcf"--"particles/items2_fx/butterfly_buff.vpcf"
end

function modifier_item_butterfly_oaa_active:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_item_butterfly_oaa_active:GetTexture()
  return "item_butterfly"
end
