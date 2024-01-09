
modifier_rune_hill_super_sight = class(ModifierBaseClass)

function modifier_rune_hill_super_sight:IsHidden()
  return false
end

function modifier_rune_hill_super_sight:IsDebuff()
  return false
end

function modifier_rune_hill_super_sight:IsPurgable()
  return false
end

function modifier_rune_hill_super_sight:GetEffectName()
  return "particles/econ/courier/courier_greevil_white/courier_greevil_white_ambient_3.vpcf"
end

function modifier_rune_hill_super_sight:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_rune_hill_super_sight:GetTexture()
  return "item_gem"
end

function modifier_rune_hill_super_sight:OnCreated()
  if not IsServer() then
    return
  end
  self:StartIntervalThink(0.1)
end

function modifier_rune_hill_super_sight:OnIntervalThink()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()

  -- Remove itself if not in a duel or if parent somehow doesnt exist
  if not Duels:IsActive() or not parent or parent:IsNull() then
    self:StartIntervalThink(-1)
    self:Destroy()
  end
end

-- Flying Vision
function modifier_rune_hill_super_sight:CheckState()
  return {
    [MODIFIER_STATE_FORCED_FLYING_VISION] = true,
  }
end

-- TrueSight part:
function modifier_rune_hill_super_sight:IsAura()
  return true
end

function modifier_rune_hill_super_sight:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_rune_hill_super_sight:GetAuraSearchType()
  return DOTA_UNIT_TARGET_ALL
end

function modifier_rune_hill_super_sight:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_INVULNERABLE)
end

function modifier_rune_hill_super_sight:GetModifierAura()
  return "modifier_truesight"
end

function modifier_rune_hill_super_sight:GetAuraRadius()
  return 800
end
