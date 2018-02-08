LinkLuaModifier('modifier_duel_rune_hill_enemy', 'modifiers/modifier_duel_rune_hill.lua', LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier('modifier_rune_hill_tripledamage', 'modifiers/modifier_rune_hill_tripledamage.lua', LUA_MODIFIER_MOTION_NONE)

modifier_duel_rune_hill = class(ModifierBaseClass)
modifier_duel_rune_hill_enemy = class(ModifierBaseClass)

function modifier_duel_rune_hill_enemy:IsHidden()
  return true
end

function modifier_duel_rune_hill:OnCreated()
  self:StartIntervalThink(0.1)
  self:SetStackCount(0)
end

--------------------------------------------------------------------------
-- aura stuff

function modifier_duel_rune_hill:IsAura()
  return true
end

function modifier_duel_rune_hill:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO
end

function modifier_duel_rune_hill:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_duel_rune_hill:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

function modifier_duel_rune_hill:GetAuraRadius()
  return 350
end

function modifier_duel_rune_hill:GetModifierAura()
  return "modifier_duel_rune_hill_enemy"
end

function modifier_duel_rune_hill:GetAuraEntityReject(entity)
  self:SetStackCount(0)
  return false
end

--------------------------------------------------------------------------

function modifier_duel_rune_hill:GetTexture()
  return "fountain_heal"
end

function modifier_duel_rune_hill:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_TAKEDAMAGE
  }
end

function modifier_duel_rune_hill:OnIntervalThink()
  if self:GetCaster():HasModifier("modifier_duel_rune_hill_enemy") then
    self:SetStackCount(0)
    return
  end

  if self:GetStackCount() == 130 then
    return
  end

  local stackCount = self:GetStackCount() + 1
  if not DuelRunes or not DuelRunes.active then
    stackCount = 0
  end

  local rewardTable = {
    [30] = "modifier_rune_regen",
    [80] = "modifier_rune_haste",
    [90] = "modifier_rune_regen",
    [100] = "modifier_rune_doubledamage",
    [110] = "modifier_rune_invis",
    [120] = "modifier_rune_regen",
    [130] = "modifier_rune_hill_tripledamage",
  }

  self:SetStackCount(stackCount)

  local unit = self:GetCaster()

  if rewardTable[stackCount] ~= nil and self:GetCaster().AddNewModifier then
    unit:AddNewModifier(self:GetCaster(), nil, rewardTable[stackCount], {
      duration = 60
    })
  end

  local particleTable = {
    [1]  = "particles/econ/items/tinker/boots_of_travel/teleport_end_bots_spiral_b.vpcf",
    [30] = "particles/items2_fx/mekanism.vpcf",
    [80] = "particles/units/heroes/hero_phantom_lancer/phantom_lancer_doppleganger_illlmove.vpcf",
    [90] = "particles/items2_fx/mekanism.vpcf",
    [100]= "particles/econ/items/tinker/boots_of_travel/teleport_end_bots_flare.vpcf",
    [110]= "particles/econ/items/gyrocopter/hero_gyrocopter_gyrotechnics/gyro_guided_missle_explosion_smoke.vpcf",
    [120]= "particles/items2_fx/mekanism.vpcf",
    [130]= "particles/econ/items/tinker/boots_of_travel/teleport_end_bots_flare.vpcf",
  }

  if particleTable[stackCount] ~= nil and self:GetCaster() then
    local part = ParticleManager:CreateParticle(particleTable[stackCount], PATTACH_ABSORIGIN_FOLLOW, unit)
    ParticleManager:SetParticleControlEnt(part, 1, unit, PATTACH_ABSORIGIN_FOLLOW, "attach_origin", unit:GetAbsOrigin(), true)
    ParticleManager:ReleaseParticleIndex(part)
  end
end

function modifier_duel_rune_hill:OnTakeDamage(keys)
  if keys.unit ~= self:GetParent() then
    return
  end

  self:SetStackCount(0)
end
