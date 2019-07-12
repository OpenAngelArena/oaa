sohei_wholeness_of_body = class( AbilityBaseClass )

LinkLuaModifier("modifier_sohei_wholeness_of_body_status", "abilities/sohei/sohei_wholeness_of_body.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sohei_wholeness_of_body_knockback", "abilities/sohei/sohei_wholeness_of_body.lua", LUA_MODIFIER_MOTION_HORIZONTAL)

function sohei_wholeness_of_body:GetBehavior()
  local caster = self:GetCaster()
  -- caster:HasTalent(...) will return true on the client only when OnPlayerLearnedAbility event happens
  -- caster:HasModifier(...) will return true on the client only if the talent is leveled up with aghanim scepter
  if caster:HasTalent("special_bonus_sohei_wholeness_allycast") or caster:HasModifier("modifier_special_bonus_sohei_wholeness_allycast") then
    return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
  end

  return bit.bor(DOTA_ABILITY_BEHAVIOR_NO_TARGET, DOTA_ABILITY_BEHAVIOR_IMMEDIATE)
end
--------------------------------------------------------------------------------

function sohei_wholeness_of_body:CastFilterResultTarget( target )
  local default_result = self.BaseClass.CastFilterResultTarget(self, target)
  return default_result
end

function sohei_wholeness_of_body:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget() or caster
  -- Activation sound
  target:EmitSound("Sohei.Guard")
  -- Strong Dispel
  target:Purge(false, true, false, true, false)
  -- Applying the buff
  target:AddNewModifier(caster, self, "modifier_sohei_wholeness_of_body_status", {duration = self:GetTalentSpecialValueFor("sr_duration")})
  -- Knockback talent
  if caster:HasTalent("special_bonus_sohei_wholeness_knockback") then
    local position = target:GetAbsOrigin()
    local radius = caster:FindTalentValue("special_bonus_sohei_wholeness_knockback")
    local team = caster:GetTeamNumber()
    local enemies = FindUnitsInRadius(team, position, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
    for _, enemy in ipairs( enemies ) do
    local modifierKnockback = {
        center_x = position.x,
        center_y = position.y,
        center_z = position.z,
        duration = caster:FindTalentValue("special_bonus_sohei_wholeness_knockback", "duration"),
        knockback_duration = caster:FindTalentValue("special_bonus_sohei_wholeness_knockback", "duration"),
        knockback_distance = radius - (position - enemy:GetAbsOrigin()):Length2D(),
      }
      enemy:AddNewModifier(caster, self, "modifier_knockback", modifierKnockback )
    end
  end
end

--------------------------------------------------------------------------------

-- wholeness_of_body modifier
modifier_sohei_wholeness_of_body_status = class(ModifierBaseClass)
--------------------------------------------------------------------------------

function modifier_sohei_wholeness_of_body_status:IsDebuff()
  return false
end

function modifier_sohei_wholeness_of_body_status:IsHidden()
  return false
end

function modifier_sohei_wholeness_of_body_status:IsPurgable()
  return true
end

--------------------------------------------------------------------------------

function modifier_sohei_wholeness_of_body_status:GetEffectName()
  return "particles/hero/sohei/guard.vpcf"
end

function modifier_sohei_wholeness_of_body_status:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_sohei_wholeness_of_body_status:OnCreated()
  local ability = self:GetAbility()
  self.status_resistance = ability:GetTalentSpecialValueFor("status_resistance")
  self.damageheal = ability:GetTalentSpecialValueFor("damage_taken_heal") / 100
  self.endHeal = 0
end

function modifier_sohei_wholeness_of_body_status:OnRefresh()
  local ability = self:GetAbility()
  self.status_resistance = ability:GetTalentSpecialValueFor("status_resistance")
  self.damageheal = ability:GetTalentSpecialValueFor("damage_taken_heal") / 100
end

function modifier_sohei_wholeness_of_body_status:OnDestroy()
  if IsServer() then
    self:GetParent():Heal(self.endHeal + self:GetAbility():GetTalentSpecialValueFor("post_heal"), self:GetAbility())
  end
end

--------------------------------------------------------------------------------

function modifier_sohei_wholeness_of_body_status:DeclareFunctions()
  local funcs = {
  MODIFIER_PROPERTY_STATUS_RESISTANCE,
  MODIFIER_EVENT_ON_TAKEDAMAGE,
  }

  return funcs
end

function modifier_sohei_wholeness_of_body_status:GetModifierStatusResistance( )
  return self.status_resistance
end

function modifier_sohei_wholeness_of_body_status:OnTakeDamage( params )
  if params.unit == self:GetParent() then
    self.endHeal = self.endHeal + params.damage * self.damageheal
  end
end

if modifier_special_bonus_sohei_wholeness_allycast == nil then
  modifier_special_bonus_sohei_wholeness_allycast = class({})
end

function modifier_special_bonus_sohei_wholeness_allycast:IsHidden()
  return true
end

function modifier_special_bonus_sohei_wholeness_allycast:IsPurgable()
  return false
end

function modifier_special_bonus_sohei_wholeness_allycast:AllowIllusionDuplicate()
	return false
end

function modifier_special_bonus_sohei_wholeness_allycast:RemoveOnDeath()
  return false
end
