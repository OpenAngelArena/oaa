LinkLuaModifier("modifier_witch_doctor_innate_oaa_applier", "abilities/oaa_witch_doctor_innate.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_witch_doctor_innate_oaa_effect", "abilities/oaa_witch_doctor_innate.lua", LUA_MODIFIER_MOTION_NONE)

witch_doctor_innate_oaa = class(AbilityBaseClass)

function witch_doctor_innate_oaa:GetIntrinsicModifierName()
  return "modifier_witch_doctor_innate_oaa_applier"
end

--------------------------------------------------------------------------------

modifier_witch_doctor_innate_oaa_applier = class(ModifierBaseClass)

function modifier_witch_doctor_innate_oaa_applier:IsHidden()
  return true
end

function modifier_witch_doctor_innate_oaa_applier:IsDebuff()
  return false
end

function modifier_witch_doctor_innate_oaa_applier:IsPurgable()
  return false
end

function modifier_witch_doctor_innate_oaa_applier:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.heal_prevent_duration = ability:GetSpecialValueFor("duration")
  else
    self.heal_prevent_duration = 3
  end
end

modifier_witch_doctor_innate_oaa_applier.OnRefresh = modifier_witch_doctor_innate_oaa_applier.OnCreated

function modifier_witch_doctor_innate_oaa_applier:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_TAKEDAMAGE,
  }
end

if IsServer() then
  function modifier_witch_doctor_innate_oaa_applier:OnTakeDamage(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local damaged_unit = event.unit
    -- local inflictor = event.inflictor

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if attacker ~= parent then
      return
    end

    -- Check if damaged entity exists
    if not damaged_unit or damaged_unit:IsNull() then
      return
    end

    -- Ignore self damage and allies
    if damaged_unit == attacker or damaged_unit:GetTeamNumber() == attacker:GetTeamNumber() then
      return
    end

    -- Check if attacker is dead
    -- if not attacker:IsAlive() then
      -- return
    -- end

    -- Check if damaged entity is an item, rune or something weird
    if damaged_unit.GetUnitName == nil then
      return
    end

    -- Don't affect buildings, wards and invulnerable units.
    if damaged_unit:IsTower() or damaged_unit:IsBarracks() or damaged_unit:IsBuilding() or damaged_unit:IsOther() or damaged_unit:IsInvulnerable() then
      return
    end

    local ability = self:GetAbility()

    -- Check if inflictor exists (if it doesn't, it's not a spell) and damage category
    -- if not inflictor or event.damage_category ~= DOTA_DAMAGE_CATEGORY_SPELL then
      -- return
    -- end

    -- If inflictor is an item (radiance e.g.), don't continue
    -- if inflictor and inflictor:IsItem() then
      -- return
    -- end

    -- Ignore damage that has the no-reflect flag (do not change this because Death Ward has this flag)
    -- if bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) > 0 then
      -- return
    -- end

    -- Ignore damage that has hp removal flag
    if bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) > 0 then
      return
    end

    -- Ignore damage that is <= 0
    if event.damage <= 0 then
      return
    end

    -- Apply Heal reduction debuff
    damaged_unit:AddNewModifier(parent, self:GetAbility(), "modifier_witch_doctor_innate_oaa_effect", {duration = self.heal_prevent_duration})
  end
end

function modifier_witch_doctor_innate_oaa_applier:GetTexture()
  return "item_grisgris"
end

--------------------------------------------------------------------------------

modifier_witch_doctor_innate_oaa_effect = class(ModifierBaseClass)

function modifier_witch_doctor_innate_oaa_effect:IsHidden()
  return false
end

function modifier_witch_doctor_innate_oaa_effect:IsDebuff()
  return true
end

function modifier_witch_doctor_innate_oaa_effect:IsPurgable()
  return true
end

function modifier_witch_doctor_innate_oaa_effect:OnCreated()
  local ability = self:GetAbility()
  if ability then
    self.heal_prevent_percent = ability:GetSpecialValueFor("heal_prevent_percent")
  else
    self.heal_prevent_percent = -15
  end
end

modifier_witch_doctor_innate_oaa_effect.OnRefresh = modifier_witch_doctor_innate_oaa_effect.OnCreated

function modifier_witch_doctor_innate_oaa_effect:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
    MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
  }
end

function modifier_witch_doctor_innate_oaa_effect:GetModifierHealAmplify_PercentageTarget()
  return self.heal_prevent_percent
end

function modifier_witch_doctor_innate_oaa_effect:GetModifierHPRegenAmplify_Percentage()
  return self.heal_prevent_percent
end

function modifier_witch_doctor_innate_oaa_effect:GetModifierLifestealRegenAmplify_Percentage()
  return self.heal_prevent_percent
end

function modifier_witch_doctor_innate_oaa_effect:GetModifierSpellLifestealRegenAmplify_Percentage()
  return self.heal_prevent_percent
end

function modifier_witch_doctor_innate_oaa_effect:GetTexture()
  return "item_grisgris"
end
