LinkLuaModifier('modifier_rune_hill_tripledamage', 'modifiers/modifier_rune_hill_tripledamage.lua', LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier('modifier_rune_hill_super_sight', 'modifiers/modifier_rune_hill_super_sight.lua', LUA_MODIFIER_MOTION_NONE)

modifier_duel_rune_hill = class(ModifierBaseClass)
modifier_duel_rune_hill_enemy = class(ModifierBaseClass)

function modifier_duel_rune_hill_enemy:IsHidden()
  return true
end

function modifier_duel_rune_hill:OnCreated()
  if not IsServer() then
    return
  end
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
  return bit.bor(DOTA_UNIT_TARGET_FLAG_INVULNERABLE, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD)
end

function modifier_duel_rune_hill:GetAuraRadius()
  return 1200
end

function modifier_duel_rune_hill:GetModifierAura()
  return "modifier_duel_rune_hill_enemy"
end

function modifier_duel_rune_hill:GetAuraEntityReject(entity)
  if not self.zone then
    return true
  else
    return not self.zone:IsTouching(entity)
  end
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
  if not IsServer() then
    return
  end

  local unit = self:GetParent()

  if unit:IsClone() or unit:IsTempestDouble() or unit:IsInvulnerable() or unit:IsOutOfGame() then
    return
  end

  if unit:HasModifier("modifier_duel_rune_hill_enemy") then
    self:SetStackCount(0)
    return
  end

  if self:GetStackCount() == 200 then
    return
  end

  if not DuelRunes or not DuelRunes.active then
    self:SetStackCount(0)
    return
  end

  local stackCount = self:GetStackCount() + 1

  local rewardTable = {
    [30] = "modifier_rune_regen",
    [80] = "modifier_rune_haste",
    [90] = "modifier_rune_regen",
    [100] = "modifier_rune_doubledamage",
    [110] = "modifier_rune_invis",
    [120] = "modifier_rune_regen",
    [130] = "modifier_rune_arcane",
    [150] = "modifier_rune_hill_tripledamage",
    [200] = "modifier_rune_hill_super_sight",
  }

  self:SetStackCount(stackCount)

  if rewardTable[stackCount] ~= nil and unit.AddNewModifier then
    unit:AddNewModifier(unit, nil, rewardTable[stackCount], { duration = 50 })
  end

  local particleTable = {
    [1] = "particles/econ/items/tinker/boots_of_travel/teleport_end_bots_spiral_b.vpcf",
    [30] = "particles/items2_fx/mekanism.vpcf",
    [80] = "particles/units/heroes/hero_phantom_lancer/phantom_lancer_doppleganger_illlmove.vpcf",
    [90] = "particles/items2_fx/mekanism.vpcf",
    [100] = "particles/econ/items/tinker/boots_of_travel/teleport_end_bots_flare.vpcf",
    [110] = "particles/econ/items/gyrocopter/hero_gyrocopter_gyrotechnics/gyro_guided_missle_explosion_smoke.vpcf",
    [120] = "particles/items2_fx/mekanism.vpcf",
    [130] = "particles/items2_fx/mekanism.vpcf",
    [150] = "particles/econ/items/tinker/boots_of_travel/teleport_end_bots_flare.vpcf",
    [200] = "particles/econ/items/tinker/boots_of_travel/teleport_end_bots_flare.vpcf",
  }

  if particleTable[stackCount] ~= nil and unit then
    local part = ParticleManager:CreateParticle(particleTable[stackCount], PATTACH_ABSORIGIN_FOLLOW, unit)
    ParticleManager:SetParticleControlEnt(part, 1, unit, PATTACH_ABSORIGIN_FOLLOW, "attach_origin", unit:GetAbsOrigin(), true)
    ParticleManager:ReleaseParticleIndex(part)
  end
end

if IsServer() then
  function modifier_duel_rune_hill:OnTakeDamage(keys)
    local victim = keys.unit
    local attacker = keys.attacker
    local damage = keys.damage

    -- Don't trigger if attacker doesn't exist
    if not attacker or attacker:IsNull() then
      return
    end

    -- Don't trigger if victim doesn't exist
    if not victim or victim:IsNull() then
      return
    end

    -- Trigger only for parent
    if victim ~= self:GetParent() then
      return
    end

    local attacker_team = attacker:GetTeamNumber()

    -- Don't trigger on damage from neutrals, allies or on self damage
    if attacker_team == DOTA_TEAM_NEUTRALS or attacker_team == victim:GetTeamNumber() then
      return
    end

    -- Don't trigger on damage that is negative or 0 after all reductions
    if damage <= 0 then
      return
    end

    self:SetStackCount(0)
  end
end
