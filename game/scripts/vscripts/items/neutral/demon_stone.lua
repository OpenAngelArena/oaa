LinkLuaModifier("modifier_item_demon_stone_passive", "items/neutral/demon_stone.lua", LUA_MODIFIER_MOTION_NONE)

item_demon_stone = class(ItemBaseClass)

function item_demon_stone:GetIntrinsicModifierName()
  return "modifier_item_demon_stone_passive"
end

---------------------------------------------------------------------------------------------------

modifier_item_demon_stone_passive = class(ModifierBaseClass)

function modifier_item_demon_stone_passive:IsHidden()
  return true
end
function modifier_item_demon_stone_passive:IsDebuff()
  return false
end
function modifier_item_demon_stone_passive:IsPurgable()
  return false
end

function modifier_item_demon_stone_passive:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.xpm = ability:GetSpecialValueFor("bonus_xpm")
    self.mana = ability:GetSpecialValueFor("bonus_mana")
    self.dmg = ability:GetSpecialValueFor("bonus_damage")
  end
  if IsServer() then
    -- start thinking every 5 seconds
    self:StartIntervalThink(5)
  end
end

function modifier_item_demon_stone_passive:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.xpm = ability:GetSpecialValueFor("bonus_xpm")
    self.mana = ability:GetSpecialValueFor("bonus_mana")
    self.dmg = ability:GetSpecialValueFor("bonus_damage")
  end
end

function modifier_item_demon_stone_passive:OnIntervalThink()
  if not IsServer() then
    return
  end

  if Duels:IsActive() then
    return
  end

  local parent = self:GetParent()

  if parent:IsIllusion() or not parent:IsHero() then
    return
  end

  local xpm = self.xpm or self:GetAbility():GetSpecialValueFor("bonus_xpm")
  local xp = math.floor((xpm/60)*5)

  parent:AddExperience(xp, DOTA_ModifyXP_Unspecified, false, true)
end

function modifier_item_demon_stone_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MANA_BONUS,
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
  }
end

function modifier_item_demon_stone_passive:GetModifierManaBonus()
  return self.mana or self:GetAbility():GetSpecialValueFor("bonus_mana")
end

function modifier_item_demon_stone_passive:GetModifierPreAttack_BonusDamage()
  return self.dmg or self:GetAbility():GetSpecialValueFor("bonus_damage")
end
