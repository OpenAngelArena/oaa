LinkLuaModifier( "modifier_intrinsic_multiplexer", "modifiers/modifier_intrinsic_multiplexer.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_drums_of_endurance_oaa", "items/drums_of_endurance.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_drums_of_endurance_oaa_swiftness_aura_effect", "items/drums_of_endurance.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_drums_of_endurance_oaa_active", "items/drums_of_endurance.lua", LUA_MODIFIER_MOTION_NONE )

item_drums_of_endurance_oaa = class(ItemBaseClass)

function item_drums_of_endurance_oaa:GetIntrinsicModifierName()
  return "modifier_intrinsic_multiplexer"
end

function item_drums_of_endurance_oaa:GetIntrinsicModifierNames()
  return {
    "modifier_item_drums_of_endurance_oaa"
  }
end

------------------------------------------------------------------------------------------------------------------------------
--On Casting/Activating Item

function item_drums_of_endurance_oaa:OnSpellStart()
  --Initializing needed variables
  local ability = self
  local caster = ability:GetCaster()
  local casterTeam = caster:GetTeamNumber()

  local units = FindUnitsInRadius(
    casterTeam,
    caster:GetAbsOrigin(),
    nil,
    ability:GetSpecialValueFor("radius"),
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO),
    DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
    FIND_ANY_ORDER,
    false
  )

	-- Play cast sound effect
  caster:EmitSound("DOTA_Item.DoE.Activate")

  local function EnduranceActive(unit)
    unit:AddNewModifier(self:GetCaster(), self, "modifier_item_drums_of_endurance_oaa_active", {duration = self:GetSpecialValueFor("duration")})
  end

  --Applying_Active_Effect_to_allied_units
  units = iter(units)
  foreach(EnduranceActive,units)

end

------------------------------------------------------------------------------------------------------------------------------
--Active_Modifier

modifier_item_drums_of_endurance_oaa_active = class(ModifierBaseClass)

function modifier_item_drums_of_endurance_oaa_active:OnCreated()
  --Ability_specials
  self.active_attack_speed = self:GetAbility():GetSpecialValueFor("bonus_attack_speed_pct")
  self.active_movement_speed = self:GetAbility():GetSpecialValueFor("bonus_movement_speed_pct")
end

function modifier_item_drums_of_endurance_oaa_active:DeclareFunctions()
  local decFuncs = {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
  }
  return decFuncs
end

function modifier_item_drums_of_endurance_oaa_active:GetModifierMoveSpeedBonus_Percentage()
  return self.active_movement_speed
end

function modifier_item_drums_of_endurance_oaa_active:GetModifierAttackSpeedBonus_Constant()
  return self.active_attack_speed
end

------------------------------------------------------------------------------------------------------------------------------
--Aura_Modifier_Effect

modifier_item_drums_of_endurance_oaa_swiftness_aura_effect = class(ModifierBaseClass)

function modifier_item_drums_of_endurance_oaa_swiftness_aura_effect:OnCreated()
  self.aura_movement_speed = self:GetAbility():GetSpecialValueFor("bonus_aura_movement_speed")
end

function modifier_item_drums_of_endurance_oaa_swiftness_aura_effect:IsHidden()
  return false
end

function modifier_item_drums_of_endurance_oaa_swiftness_aura_effect:IsPurgable()
  return false
end

function modifier_item_drums_of_endurance_oaa_swiftness_aura_effect:IsDebuff()
  return false
end

function modifier_item_drums_of_endurance_oaa_swiftness_aura_effect:DeclareFunctions()
  local decFuncs = {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT
  }
  return decFuncs
end

function modifier_item_drums_of_endurance_oaa_swiftness_aura_effect:GetModifierMoveSpeedBonus_Constant()
  return self.aura_movement_speed
end

------------------------------------------------------------------------------------------------------------------------------
-- Stats modifier

modifier_item_drums_of_endurance_oaa = class(ModifierBaseClass)

function modifier_item_drums_of_endurance_oaa:OnCreated()
  self.bonus_intellect = self:GetAbility():GetSpecialValueFor("bonus_int")
  self.bonus_strength = self:GetAbility():GetSpecialValueFor("bonus_str")
  self.bonus_agility = self:GetAbility():GetSpecialValueFor("bonus_agi")
  self.bonus_damage = self:GetAbility():GetSpecialValueFor("bonus_damage")
  self.bonus_mana_regeneration = self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
  self.radius = self:GetAbility():GetSpecialValueFor("radius")
end

modifier_item_drums_of_endurance_oaa.OnRefresh = modifier_item_drums_of_endurance_oaa.OnCreated

function modifier_item_drums_of_endurance_oaa:IsHidden()
  return true
end

function modifier_item_drums_of_endurance_oaa:IsPurgable()
  return false
end

function modifier_item_drums_of_endurance_oaa:IsDebuff()
  return false
end

function modifier_item_drums_of_endurance_oaa:AllowIllusionDuplicate()
  return true
end

function modifier_item_drums_of_endurance_oaa:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_item_drums_of_endurance_oaa:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_drums_of_endurance_oaa:IsAura()
  return true
end

function modifier_item_drums_of_endurance_oaa:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_item_drums_of_endurance_oaa:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_item_drums_of_endurance_oaa:DeclareFunctions()
  local decFuncs = {
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_PROPERTY_MANA_REGEN_CONSTANT}
    return decFuncs
end

function modifier_item_drums_of_endurance_oaa:GetModifierAura()
  return "modifier_item_drums_of_endurance_oaa_swiftness_aura_effect"
end

function modifier_item_drums_of_endurance_oaa:GetModifierBonusStats_Intellect()
  return self.bonus_intellect
end

function modifier_item_drums_of_endurance_oaa:GetModifierBonusStats_Strength()
  return self.bonus_strength
end

function modifier_item_drums_of_endurance_oaa:GetModifierBonusStats_Agility()
  return self.bonus_agility
end

function modifier_item_drums_of_endurance_oaa:GetModifierPreAttack_BonusDamage()
  return self.bonus_damage
end

function modifier_item_drums_of_endurance_oaa:GetModifierConstantManaRegen()
  return self.bonus_mana_regeneration
end

function modifier_item_drums_of_endurance_oaa:GetAuraRadius()
  return self.radius
end

function modifier_item_drums_of_endurance_oaa:OnDestroy()
  if IsServer() then
    if not self:GetCaster():HasModifier("modifier_item_drums_of_endurance_oaa") then
      self:GetCaster():RemoveModifierByName("modifier_item_drums_of_endurance_oaa_swiftness_aura_effect")
    end
  end
end

-----------------------------------------------------------------------------------------------------------------------------
--Upgrades

item_drums_of_endurance_2 = class(item_drums_of_endurance_oaa)
item_drums_of_endurance_3 = class(item_drums_of_endurance_oaa)
item_drums_of_endurance_4 = class(item_drums_of_endurance_oaa)
item_drums_of_endurance_5 = class(item_drums_of_endurance_oaa)
