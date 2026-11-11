---------------------------------------------------------------------------------------------------

modifier_muerta_pierce_the_veil_penalty_oaa = modifier_muerta_pierce_the_veil_penalty_oaa or class({})

function modifier_muerta_pierce_the_veil_penalty_oaa:IsHidden()
  return true
end

function modifier_muerta_pierce_the_veil_penalty_oaa:IsDebuff()
  return false
end

function modifier_muerta_pierce_the_veil_penalty_oaa:IsPurgable()
  return false
end

function modifier_muerta_pierce_the_veil_penalty_oaa:OnCreated()
  self.dmg_penalty = -30
  self.dmg_penalty_bosses = -50

  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.dmg_penalty = 0 - math.abs(ability:GetSpecialValueFor("damage_penalty"))
    self.dmg_penalty_bosses = 0 - math.abs(ability:GetSpecialValueFor("damage_penalty_bosses"))
  end
end

modifier_muerta_pierce_the_veil_penalty_oaa.OnRefresh = modifier_muerta_pierce_the_veil_penalty_oaa.OnCreated

function modifier_muerta_pierce_the_veil_penalty_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
  }
end

function modifier_muerta_pierce_the_veil_penalty_oaa:GetModifierTotalDamageOutgoing_Percentage(event)
  local parent = self:GetParent()
  local dmg_category = event.damage_category
  local target = event.target

  -- Do nothing if damage is not an attack or if damaged target does not exist
  if dmg_category ~= DOTA_DAMAGE_CATEGORY_ATTACK or not target or target:IsNull() then
    -- Combat Log considers attacks against ethereal and while ethereal as Pierce the Veil damage ...
    -- ... while in here dmg category is still attack, so keep this in mind if this modifier randomly stops working ...
    -- ... it would mean that Valve changed ethereal attacks to be considered spells with Pierce the Veil as inflictor.
    --print("Ability is: "..tostring(event.inflictor))
    --if event.inflictor then
      --print(event.inflictor:GetAbilityName())
    --end
    return 0
  end

  -- Do nothing if damaged target isn't a valid npc unit
  if not target:IsBaseNPC() then
    --print("damaged target is a rune, item or something invalid")
    return 0
  end

  if parent:IsAttackImmune() or target:IsAttackImmune() then
    --print("attacker or target is ethereal")
    if target:IsOAABoss() then
      return self.dmg_penalty_bosses
    end

    return self.dmg_penalty
  end

  return 0
end
