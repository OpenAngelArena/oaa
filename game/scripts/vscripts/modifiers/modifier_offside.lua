LinkLuaModifier('modifier_onside_buff', 'modifiers/modifier_onside_buff.lua', LUA_MODIFIER_MOTION_NONE)

modifier_offside = class(ModifierBaseClass)
modifier_onside_buff = class(ModifierBaseClass)

function modifier_offside:OnCreated()
  if IsServer() then
    self:StartIntervalThink(1)
  end
end
--------------------------------------------------------------------
--aura
function modifier_offside:IsAura()
  return true
end

function modifier_offside:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO
end

function modifier_offside:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_offside:GetAuraRadius()
  return 2500
end

function modifier_offside:GetModifierAura()
  return "modifier_onside_buff"
end
--------------------------------------------------------------------
--% health damage
function modifier_offside:GetTexture()
  return "custom/modifier_offside"
end

function modifier_offside:IsDebuff()
  return true
end

function modifier_offside:OnIntervalThink()
  local playerHero = self:GetCaster()
  local h = self:GetParent():GetMaxHealth()
  local stackCount = self:GetElapsedTime()
  local location = self:GetParent():GetAbsOrigin()
  local team = self:GetParent():GetTeamNumber()
  local defenders = FindUnitsInRadius(
    team,
    location,
    nil,
    2000,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_HERO,
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false) or nil

  fountain = Entities:FindByClassnameNearest("ent_dota_fountain", location, 10000)

  local damageTable = {
  victim = self:GetParent(),
  attacker = defenders or fountain,
  damage = (h * ((0.02 * (stackCount-10)^2)/100)),
  damage_type = DAMAGE_TYPE_PURE,
  damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS + DOTA_DAMAGE_FLAG_REFLECTION,
  }

  if stackCount >= 10 then
    return ApplyDamage(damageTable)
  end
--
  local particleTable = {
      [1]  = "particles/blood_impact/blood_advisor_pierce_spray.vpcf",
      [10] = "particles/blood_impact/blood_advisor_pierce_spray.vpcf",
      [13] = "particles/blood_impact/blood_advisor_pierce_spray.vpcf",
      [16] = "particles/blood_impact/blood_advisor_pierce_spray.vpcf",
      [19] = "particles/blood_impact/blood_advisor_pierce_spray.vpcf",
      [22] = "particles/blood_impact/blood_advisor_pierce_spray.vpcf",
      [25] = "particles/blood_impact/blood_advisor_pierce_spray.vpcf",
      [28] = "particles/blood_impact/blood_advisor_pierce_spray.vpcf",
    }

    if particleTable[stackCount] ~= nil and self:GetCaster() then
      local part = ParticleManager:CreateParticle(particleTable[stackCount], PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
      ParticleManager:SetParticleControlEnt(part, 1, self:GetCaster(), PATTACH_ABSORIGIN_FOLLOW, "attach_origin", self:GetCaster():GetAbsOrigin(), true)
      ParticleManager:ReleaseParticleIndex(part)
    end
end

