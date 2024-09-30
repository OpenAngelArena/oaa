LinkLuaModifier("modifier_grendel_passives", "abilities/boss/grendel/grendel_passives.lua", LUA_MODIFIER_MOTION_NONE)

grendel_passives = class(AbilityBaseClass)

function grendel_passives:GetIntrinsicModifierName()
  return "modifier_grendel_passives"
end

---------------------------------------------------------------------------------------------------

modifier_grendel_passives = class(ModifierBaseClass)

function modifier_grendel_passives:IsHidden()
  return true
end

function modifier_grendel_passives:IsDebuff()
  return false
end

function modifier_grendel_passives:IsPurgable()
  return false
end

function modifier_grendel_passives:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
  }
end

function modifier_grendel_passives:GetModifierTotal_ConstantBlock(keys)
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
    return damage * 90/100
  elseif math.abs(difference) > 15 then
    return damage * 75/100
  elseif math.abs(difference) > 10 then
    return damage * 50/100
  elseif math.abs(difference) > 5 then
    return damage * 25/100
  end

  return 0
end
