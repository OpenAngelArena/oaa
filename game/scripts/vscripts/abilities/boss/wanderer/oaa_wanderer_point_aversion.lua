LinkLuaModifier("modifier_wanderer_point_aversion_passive", "abilities/boss/wanderer/oaa_wanderer_point_aversion.lua", LUA_MODIFIER_MOTION_NONE)

wanderer_point_aversion = class(AbilityBaseClass)

function wanderer_point_aversion:GetIntrinsicModifierName()
  return "modifier_wanderer_point_aversion_passive"
end

---------------------------------------------------------------------------------------------------

modifier_wanderer_point_aversion_passive = class(ModifierBaseClass)

function modifier_wanderer_point_aversion_passive:IsHidden()
  return true
end

function modifier_wanderer_point_aversion_passive:IsDebuff()
  return false
end

function modifier_wanderer_point_aversion_passive:IsPurgable()
  return false
end

function modifier_wanderer_point_aversion_passive:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.damage = ability:GetSpecialValueFor("damage_per_point_difference")
  else
    self.damage = 100
  end
  local parent = self:GetParent()
  self.thresholds = {}
  if parent:GetUnitName() == "npc_dota_boss_grendel" then
    self.thresholds = {0.25, 0.5, 0.75, 0.9}
  else
    self.thresholds = {0.2, 0.4, 0.6, 0.8}
  end
end

modifier_wanderer_point_aversion_passive.OnRefresh = modifier_wanderer_point_aversion_passive.OnCreated

function modifier_wanderer_point_aversion_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

function modifier_wanderer_point_aversion_passive:GetModifierTotal_ConstantBlock(keys)
  local parent = self:GetParent()
  local attacker = keys.attacker
  local damage = keys.damage

  if attacker == parent then -- boss degen
    return 0
  end

  local attacker_team = attacker:GetTeamNumber()
  local opposite_team
  if attacker_team == DOTA_TEAM_GOODGUYS then
    opposite_team = DOTA_TEAM_BADGUYS
  elseif attacker_team == DOTA_TEAM_BADGUYS then
    opposite_team = DOTA_TEAM_GOODGUYS
  else
    return 0
  end

  local difference = PointsManager:GetPoints(attacker_team) - PointsManager:GetPoints(opposite_team)

  -- If the score difference is negative or 0, it means attacker's team is losing or even, don't block damage
  if difference <= 0 then
    return 0
  end

  if math.abs(difference) > 20 then
    return damage * self.thresholds[4]
  elseif math.abs(difference) > 15 then
    return damage * self.thresholds[3]
  elseif math.abs(difference) > 10 then
    return damage * self.thresholds[2]
  elseif math.abs(difference) > 5 then
    return damage * self.thresholds[1]
  end

  return 0
end

if IsServer() then
  function modifier_wanderer_point_aversion_passive:OnAttackLanded(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local target = event.target

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- If attacker isnt the parent -> don't continue
    if attacker ~= parent then
      return
    end

    -- If attacked unit doesn't exist or its about to be deleted -> don't continue
    if not target or target:IsNull() then
      return
    end

    -- If target is some weird entity (item, rune, ward etc.) -> don't continue
    if target.IsHero == nil or target.GetTeamNumber == nil then
      return
    end

    -- If target is a ward type unit, don't continue
    if target:IsOther() then
      return
    end

    local target_team = target:GetTeamNumber()
    local opposite_team
    if target_team == DOTA_TEAM_GOODGUYS then
      opposite_team = DOTA_TEAM_BADGUYS
    elseif target_team == DOTA_TEAM_BADGUYS then
      opposite_team = DOTA_TEAM_GOODGUYS
    else
      print("Wanderer attacked a unit with an invalid team.")
      return
    end

    local difference = PointsManager:GetPoints(target_team) - PointsManager:GetPoints(opposite_team)

    -- If the score difference is negative or 0, it means this team is losing or even, don't do bonus damage
    if difference <= 0 then
      return
    end

    -- Don't damage spell immune heroes
    if not target:IsMagicImmune() and not target:IsDebuffImmune() then
      local damage_table = {
        attacker = parent,
        victim = target,
        damage = self.damage * difference,
        damage_type = DAMAGE_TYPE_PURE,
        ability = self:GetAbility(),
      }

      ApplyDamage(damage_table)
    end
  end
end
