LinkLuaModifier('modifier_duel_rune_hill_enemy', 'modifiers/modifier_duel_rune_hill.lua', LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier('modifier_rune_hill_tripledamage', 'modifiers/modifier_rune_hill_tripledamage.lua', LUA_MODIFIER_MOTION_NONE)

modifier_duel_rune_hill = class({})
modifier_duel_rune_hill_enemy = class({})

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

function modifier_duel_rune_hill:GetAuraRadius()
  return 800
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
  end

  local stackCount = self:GetStackCount() + 1
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

  if rewardTable[stackCount] ~= nil and self:GetCaster().AddNewModifier then
    self:GetCaster():AddNewModifier(self:GetCaster(), nil, rewardTable[stackCount], {
      duration = 60
    })
  end
end

function modifier_duel_rune_hill:OnTakeDamage(keys)
  if keys.unit ~= self:GetParent() then
    return
  end

  self:SetStackCount(0)
end
