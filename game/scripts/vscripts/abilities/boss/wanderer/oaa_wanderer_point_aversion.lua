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
end

modifier_wanderer_point_aversion_passive.OnRefresh = modifier_wanderer_point_aversion_passive.OnCreated

function modifier_wanderer_point_aversion_passive:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
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

    -- If target is not a hero (real hero, illusion, clone, tempest double), don't continue
    if not target:IsHero() then
      return
    end

    local target_team = target:GetTeamNumber()
    local opposite_team
    if target_team == DOTA_TEAM_GOODGUYS then
      opposite_team = DOTA_TEAM_BADGUYS
    elseif target_team == DOTA_TEAM_BADGUYS then
      opposite_team = DOTA_TEAM_GOODGUYS
    else
      print("Wanderer attacked a hero with an invalid team.")
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
