item_stoneskin = class(ItemBaseClass)

LinkLuaModifier("modifier_item_stoneskin_passives", "items/stoneskin.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_stoneskin_stone_armor", "items/stoneskin.lua", LUA_MODIFIER_MOTION_NONE)

function item_stoneskin:GetIntrinsicModifierName()
  return "modifier_item_stoneskin_passives"
end

function item_stoneskin:OnSpellStart()
  local caster = self:GetCaster()

  -- Apply Stoneskin buff to caster
  caster:AddNewModifier(caster, self, "modifier_item_stoneskin_stone_armor", {duration = self:GetSpecialValueFor("duration")})

  -- Activation Sound
  caster:EmitSound("Hero_EarthSpirit.Petrify")
end

item_stoneskin_2 = item_stoneskin

------------------------------------------------------------------------

modifier_item_stoneskin_passives = class(ModifierBaseClass)

function modifier_item_stoneskin_passives:IsHidden()
  return true
end

function modifier_item_stoneskin_passives:IsDebuff()
  return false
end

function modifier_item_stoneskin_passives:IsPurgable()
  return false
end

function modifier_item_stoneskin_passives:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_stoneskin_passives:OnCreated()
  self:OnRefresh()
  if IsServer() then
    self:StartIntervalThink(0.1)
  end
end

function modifier_item_stoneskin_passives:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.stats = ability:GetSpecialValueFor("bonus_all_stats")
    self.bonus_armor = ability:GetSpecialValueFor("bonus_armor")
    self.hp_regen = ability:GetSpecialValueFor("bonus_health_regen")
    self.bonus_status_resist = ability:GetSpecialValueFor("bonus_status_resist")
  end

  if IsServer() then
    self:OnIntervalThink()
  end
end

function modifier_item_stoneskin_passives:OnIntervalThink()
  if self:IsFirstItemInInventory() then
    self:SetStackCount(2)
  else
    self:SetStackCount(1)
  end
end

function modifier_item_stoneskin_passives:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
  }
end

function modifier_item_stoneskin_passives:GetModifierPhysicalArmorBonus()
  return self.bonus_armor or self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_item_stoneskin_passives:GetModifierConstantHealthRegen()
  return self.hp_regen or self:GetAbility():GetSpecialValueFor("bonus_health_regen")
end

function modifier_item_stoneskin_passives:GetModifierStatusResistanceStacking()
  if self:GetStackCount() == 2 then
    return self.bonus_status_resist or self:GetAbility():GetSpecialValueFor("bonus_status_resist")
  else
    return 0
  end
end

---------------------------------------------------------------------------------------------------

modifier_item_stoneskin_stone_armor = class(ModifierBaseClass)

function modifier_item_stoneskin_stone_armor:IsHidden() -- needs tooltip
  return false
end

function modifier_item_stoneskin_stone_armor:IsDebuff()
  return false
end

function modifier_item_stoneskin_stone_armor:IsPurgable()
  return false
end

function modifier_item_stoneskin_stone_armor:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_AVOID_DAMAGE,
    --MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    --MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
  }
end

function modifier_item_stoneskin_stone_armor:GetModifierPhysicalArmorBonus()
  if not self:GetAbility() then
    if not self:IsNull() then
      self:Destroy()
    end
    return 0
  end
  return self:GetAbility():GetSpecialValueFor("stone_armor")
end

-- function modifier_item_stoneskin_stone_armor:GetModifierMagicalResistanceBonus()
  -- if not self:GetAbility() then
    -- if not self:IsNull() then
      -- self:Destroy()
    -- end
    -- return 0
  -- end
  -- return self:GetAbility():GetSpecialValueFor("stone_magic_resist")
-- end

function modifier_item_stoneskin_stone_armor:GetModifierAvoidDamage(event)
  local parent = self:GetParent()
  local ability = self:GetAbility()
  local chance = 25
  if ability and not ability:IsNull() then
    chance = ability:GetSpecialValueFor("stone_deflect_chance")
  end
  if event.ranged_attack == true and event.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK and RollPseudoRandomPercentage(chance, DOTA_PSEUDO_RANDOM_CUSTOM_GAME_1, parent) == true then
    return 1
  end

  return 0
end

function modifier_item_stoneskin_stone_armor:GetStatusEffectName()
  return "particles/status_fx/status_effect_earth_spirit_petrify.vpcf"
end

function modifier_item_stoneskin_stone_armor:StatusEffectPriority()
  return MODIFIER_PRIORITY_ULTRA
end

-- function modifier_item_stoneskin_stone_armor:GetModifierMoveSpeed_Absolute()
  -- if not self:GetAbility() then
    -- if not self:IsNull() then
      -- self:Destroy()
    -- end
    -- return
  -- end
  -- return self:GetAbility():GetSpecialValueFor("stone_move_speed")
-- end

function modifier_item_stoneskin_stone_armor:GetTexture()
  return "custom/stoneskin_2_active"
end
