-- Forest Warden

LinkLuaModifier("modifier_enchantress_innate_oaa", "abilities/oaa_enchantress_innate.lua", LUA_MODIFIER_MOTION_NONE)

enchantress_innate_oaa = class(AbilityBaseClass)

function enchantress_innate_oaa:GetIntrinsicModifierName()
  return "modifier_enchantress_innate_oaa"
end

---------------------------------------------------------------------------------------------------

modifier_enchantress_innate_oaa = class(ModifierBaseClass)

function modifier_enchantress_innate_oaa:IsHidden()
  return self:GetStackCount() == 0
end

function modifier_enchantress_innate_oaa:IsDebuff()
  return false
end

function modifier_enchantress_innate_oaa:IsPurgable()
  return false
end

function modifier_enchantress_innate_oaa:RemoveOnDeath()
  return false
end

function modifier_enchantress_innate_oaa:OnCreated()
  local ability = self:GetAbility()
  self.dmg_amp = ability:GetSpecialValueFor("bonus_dmg_amp_near_neutrals")
  self.radius = ability:GetSpecialValueFor("radius")

  if IsServer() then
    self:StartIntervalThink(0.1)
  end
end

function modifier_enchantress_innate_oaa:OnIntervalThink()
  local parent = self:GetParent()

  if parent:PassivesDisabled() then
    self:SetStackCount(0)
    return
  end

  -- Stop thinking for illusions
  if parent:IsIllusion() then
    self:SetStackCount(0)
    self:StartIntervalThink(-1)
    return
  end

  local parent_team = parent:GetTeamNumber()
  local parent_loc = parent:GetAbsOrigin()

  local enemies = FindUnitsInRadius(
    parent_team,
    parent_loc,
    nil,
    self.radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
    DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
    FIND_ANY_ORDER,
    false
  )

  local allied_summons = FindUnitsInRadius(
    parent_team,
    parent_loc,
    nil,
    self.radius,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
    DOTA_UNIT_TARGET_FLAG_PLAYER_CONTROLLED,
    FIND_ANY_ORDER,
    false
  )

  local near_neutrals = false
  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() and enemy.HasModifier then
      if enemy:GetTeamNumber() == DOTA_TEAM_NEUTRALS and not enemy:HasModifier("modifier_oaa_thinker") then
        near_neutrals = true
        break
      end
    end
  end

  local function CheckIfValid(unit)
    if not unit or unit:IsNull() then
      return false
    end
    if unit.IsBaseNPC == nil or unit.HasModifier == nil or unit.GetUnitName == nil then
      return false
    end
    local name = unit:GetUnitName()
    local valid_name = name ~= "npc_dota_custom_dummy_unit" and name ~= "npc_dota_elder_titan_ancestral_spirit" and name ~= "aghsfort_mars_bulwark_soldier" and name ~= "npc_dota_monkey_clone_oaa"
    local not_thinker = not unit:HasModifier("modifier_oaa_thinker") and not unit:IsPhantomBlocker()
    return not unit:IsCourier() and unit:HasMovementCapability() and not_thinker and valid_name -- and not unit:IsZombie()
  end

  local near_enchanted = false
  for _, ally in pairs(allied_summons) do
    if ally and not ally:IsNull() then
      if CheckIfValid(ally) and ally:GetPlayerOwnerID() == parent:GetPlayerOwnerID() and ally ~= parent and not ally:IsIllusion() then
        near_enchanted = true
        break
      end
    end
  end

  if near_neutrals or near_enchanted then
    self:SetStackCount(-1)
  else
    self:SetStackCount(0)
  end
end

function modifier_enchantress_innate_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
  }
end

function modifier_enchantress_innate_oaa:GetModifierTotalDamageOutgoing_Percentage()
  if self:GetStackCount() == -1 then
    return self.dmg_amp
  end
  return 0
end
