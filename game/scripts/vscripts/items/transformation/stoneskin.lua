item_stoneskin = class(TransformationBaseClass)

require( "libraries/Timers" )
--LinkLuaModifier("modifier_item_stoneskin", "items/transformation/stoneskin.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_stoneskin_stone_armor", "items/transformation/stoneskin.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_generic_bonus", "modifiers/modifier_generic_bonus.lua", LUA_MODIFIER_MOTION_NONE)

function item_stoneskin:GetIntrinsicModifierName()
  return "modifier_generic_bonus"
end

function item_stoneskin:GetTransformationModifierName()
  return "modifier_item_stoneskin_stone_armor"
end

item_stoneskin_2 = item_stoneskin
------------------------------------------------------------------------
--modifier_item_stoneskin = class(ModifierBaseClass)

-- function modifier_item_stoneskin:OnStackCountChanged(numOldStacks)
--   -- Echo stack count to a property on the item so that it can be checked for
--   -- item icon purposes
--   if IsClient() then
--     local ability = self:GetAbility()
--     ability.stoneskinState = self:GetStackCount()
--   end
-- end

-- function modifier_item_stoneskin:OnDestroy()
  -- local item = self:GetAbility()
  -- if item and item.mod and not item.mod:IsNull() then
    -- item.mod:Destroy()
    -- item.mod = nil
  -- end
-- end

------------------------------------------------------------------------

modifier_item_stoneskin_stone_armor = class(ModifierBaseClass)

function modifier_item_stoneskin_stone_armor:IsHidden()
  return false
end

function modifier_item_stoneskin_stone_armor:IsDebuff()
  return false
end

function modifier_item_stoneskin_stone_armor:IsPurgable()
  return true
end

function modifier_item_stoneskin_stone_armor:OnCreated()
  self:GetParent():EmitSound("Hero_EarthSpirit.Petrify")
end

function modifier_item_stoneskin_stone_armor:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    --MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE
  }
end

function modifier_item_stoneskin_stone_armor:GetModifierPhysicalArmorBonus()
  if not self:GetAbility() then
    if not self:IsNull() then
      self:Destroy()
    end
    return
  end
  return self:GetAbility():GetSpecialValueFor("stone_armor")
end

function modifier_item_stoneskin_stone_armor:GetModifierMagicalResistanceBonus()
  if not self:GetAbility() then
    if not self:IsNull() then
      self:Destroy()
    end
    return
  end
  return self:GetAbility():GetSpecialValueFor("stone_resist")
end

function modifier_item_stoneskin_stone_armor:GetStatusEffectName()
  return "particles/status_fx/status_effect_earth_spirit_petrify.vpcf"
end

function modifier_item_stoneskin_stone_armor:GetPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA
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
