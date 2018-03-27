sohei_wholeness_of_body = class( AbilityBaseClass )

LinkLuaModifier( "modifier_sohei_wholeness_of_body_status", "abilities/sohei/sohei_wholeness_of_body.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_sohei_wholeness_of_body_knockback", "abilities/sohei/sohei_wholeness_of_body.lua", LUA_MODIFIER_MOTION_HORIZONTAL )

function sohei_wholeness_of_body:GetBehavior()
  if self:GetCaster():HasTalent("special_bonus_sohei_wholeness_allycast") then
    return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
  else
    return DOTA_ABILITY_BEHAVIOR_NO_TARGET
  end
end
--------------------------------------------------------------------------------

-- unfinished talent stuff
function sohei_wholeness_of_body:CastFilterResultTarget( target )
  local caster = self:GetCaster()

  local ufResult = UnitFilter(
    target,
    self:GetAbilityTargetTeam(),
    self:GetAbilityTargetType(),
    self:GetAbilityTargetFlags(),
    caster:GetTeamNumber()
  )

  return ufResult
end

function sohei_wholeness_of_body:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget() or caster
  target:AddNewModifier(caster, self, "modifier_sohei_wholeness_of_body_status", {duration = self:GetTalentSpecialValueFor("sr_duration")})
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

-- wholeness_of_body projectile reflect modifier
modifier_sohei_wholeness_of_body_status = class(ModifierBaseClass)

--------------------------------------------------------------------------------

function modifier_sohei_wholeness_of_body_status:IsDebuff()
  return false
end

function modifier_sohei_wholeness_of_body_status:IsHidden()
  return false
end

function modifier_sohei_wholeness_of_body_status:IsPurgable()
  return false
end

--------------------------------------------------------------------------------


function modifier_sohei_wholeness_of_body_status:GetEffectName()
  return "particles/hero/sohei/guard.vpcf"
end

function modifier_sohei_wholeness_of_body_status:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_sohei_wholeness_of_body_status:OnCreated()
  self.status_resistance = self:GetAbility():GetTalentSpecialValueFor("status_resistance")
  self.damageheal = self:GetAbility():GetTalentSpecialValueFor("damage_taken_heal") / 100
  self.endHeal = 0
end

function modifier_sohei_wholeness_of_body_status:OnRefresh()
  self.status_resistance = self:GetAbility():GetTalentSpecialValueFor("status_resistance")
  self.damageheal = self:GetAbility():GetTalentSpecialValueFor("damage_taken_heal") / 100
end

function modifier_sohei_wholeness_of_body_status:OnDestroy()
  if IsServer() then
    self:GetParent():Heal(self.endHeal + self:GetAbility():GetTalentSpecialValueFor("post_heal"), self:GetAbility())
  end
end

--------------------------------------------------------------------------------

function modifier_sohei_wholeness_of_body_status:DeclareFunctions()
  local funcs = {MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
                 MODIFIER_EVENT_ON_TAKEDAMAGE,}

  return funcs
end

function modifier_sohei_wholeness_of_body_status:GetModifierStatusResistanceStacking( )
  return self.status_resistance
end

function modifier_sohei_wholeness_of_body_status:OnTakeDamage( params )
  if params.unit == self:GetParent() then
    self.endHeal = params.damage * self.damageheal
  end
end