wanderer_point_aversion = class(AbilityBaseClass)

LinkLuaModifier("modifier_wanderer_point_aversion_passive", "abilities/wanderer/oaa_wanderer_point_aversion.lua", LUA_MODIFIER_MOTION_NONE)

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
    self.damage = 25
  end
end

modifier_wanderer_point_aversion_passive.OnRefresh = modifier_wanderer_point_aversion_passive.OnCreated

function modifier_wanderer_point_aversion_passive:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_wanderer_point_aversion_passive:OnAttackLanded(event)
  if IsServer() then
    local parent = self:GetParent()

    local attacker = event.attacker
    local target = event.target

    -- If attacker isnt the parent -> don't continue
    if attacker ~= parent then
      return
    end

    -- If parent doesn't exist or its about to be deleted -> don't continue
    if not parent or parent:IsNull() then
      return
    end

    -- If target doesn't exist or its about to be deleted -> don't continue
    if not target or target:IsNull() then
      return
    end

    -- If target is some weird entity (item, rune, ward etc.) -> don't continue
    if target.IsHero == nil or target.GetTeamNumber == nil then
      return
    end

    -- If target is not a hero (real hero, illusion, clone, tempest double), don't continue
    if not target:IsHero() then
      return
    end

    local target_team = target:GetTeamNumber()
    local oposite_team
    if target_team == DOTA_TEAM_GOODGUYS then
      oposite_team = DOTA_TEAM_BADGUYS
    elseif target_team == DOTA_TEAM_BADGUYS then
      oposite_team = DOTA_TEAM_GOODGUYS
    else
      print("Wanderer attacked a hero on and invalid team.")
      return
    end

    local difference = PointsManager:GetPoints(target_team) - PointsManager:GetPoints(oposite_team)

    -- If the score difference is negative, it means this team is losing, don't do bonus damage
    if difference < 0 then
      return
    end

    -- Don't damage spell immune heroes
    if not target:IsMagicImmune() then
      local damage_table = {}
      damage_table.victim = target
      damage_table.damage_type = DAMAGE_TYPE_PURE
      damage_table.damage_flags = DOTA_DAMAGE_FLAG_NONE
      damage_table.attacker = parent
      damage_table.ability = self:GetAbility()
      damage_table.damage = self.damage * difference
      ApplyDamage(damage_table)
    end
  end
end
