require( "libraries/Timers" )	--needed for the timers.
LinkLuaModifier("modifier_item_stoneskin", "items/transformation/stoneskin.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_stoneskin_stone_armor", "items/transformation/stoneskin.lua", LUA_MODIFIER_MOTION_NONE)

item_stoneskin = class(TransformationBaseClass)

function item_stoneskin:GetIntrinsicModifierName()
  return "modifier_item_stoneskin"
end

function item_stoneskin:GetTransformationModifierName()
  return "modifier_item_stoneskin_stone_armor"
end

function item_stoneskin:GetTransformationSounds()
  return { "Hero_EarthSpirit.Petrify", "" }
end

-- caster:EmitSound("Hero_EarthSpirit.RollingBoulder.Loop")

item_stoneskin_2 = item_stoneskin
------------------------------------------------------------------------
modifier_item_stoneskin = class(ModifierBaseClass)

-- function modifier_item_stoneskin:OnStackCountChanged(numOldStacks)
--   -- Echo stack count to a property on the item so that it can be checked for
--   -- item icon purposes
--   if IsClient() then
--     local ability = self:GetAbility()
--     ability.stoneskinState = self:GetStackCount()
--   end
-- end

function modifier_item_stoneskin:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS
  }
end

function modifier_item_stoneskin:IsHidden()
  return true
end

function modifier_item_stoneskin:IsPurgable()
  return false
end

function modifier_item_stoneskin:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_stoneskin:GetModifierPreAttack_BonusDamage()
  return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_stoneskin:GetModifierAttackSpeedBonus_Constant()
  return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_item_stoneskin:GetModifierPhysicalArmorBonus()
  return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_item_stoneskin:GetModifierConstantHealthRegen()
  return self:GetAbility():GetSpecialValueFor("bonus_health_regen")
end

function modifier_item_stoneskin:GetModifierBonusStats_Intellect()
  return self:GetAbility():GetSpecialValueFor("bonus_int")
end
------------------------------------------------------------------------
modifier_item_stoneskin_stone_armor = class(ModifierBaseClass)

function modifier_item_stoneskin_stone_armor:IsPurgable()
  return false
end

function modifier_item_stoneskin_stone_armor:GetStatusEffectName()
  return "particles/status_fx/status_effect_earth_spirit_petrify.vpcf"
end

function modifier_item_stoneskin_stone_armor:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE
  }
end

function modifier_item_stoneskin_stone_armor:GetModifierPhysicalArmorBonus()
  return self:GetAbility():GetSpecialValueFor("stone_armor")
end

function modifier_item_stoneskin_stone_armor:GetModifierMagicalResistanceBonus()
  return self:GetAbility():GetSpecialValueFor("stone_resist")
end

function modifier_item_stoneskin_stone_armor:GetPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA
end

function modifier_item_stoneskin_stone_armor:GetModifierMoveSpeed_Absolute()
  return self:GetAbility():GetSpecialValueFor("stone_move_speed")
end
