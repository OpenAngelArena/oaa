
modifier_rune_hill_lesser_regeneration = class(ModifierBaseClass)

function modifier_rune_hill_lesser_regeneration:IsHidden()
  return false
end

function modifier_rune_hill_lesser_regeneration:IsDebuff()
  return false
end

function modifier_rune_hill_lesser_regeneration:IsPurgable()
  return true
end

function modifier_rune_hill_lesser_regeneration:GetEffectName()
  return "particles/generic_gameplay/rune_regen_owner.vpcf"
end

function modifier_rune_hill_lesser_regeneration:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_rune_hill_lesser_regeneration:GetTexture()
  return "rune_regen"
end

function modifier_rune_hill_lesser_regeneration:OnCreated()
  if not IsServer() then
    return
  end
  self:StartIntervalThink(0.1)
end

function modifier_rune_hill_lesser_regeneration:OnIntervalThink()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()

  -- Remove itself if not in a duel or if parent somehow doesnt exist
  if not Duels:IsActive() or not parent or parent:IsNull() then
    self:StartIntervalThink(-1)
    self:Destroy()
    return
  end

  -- Remove itself if the parent is full hp and full mana
  if parent:GetHealth() == parent:GetMaxHealth() and parent:GetMana() == parent:GetMaxMana() then
    self:StartIntervalThink(-1)
    self:Destroy()
  end
end

function modifier_rune_hill_lesser_regeneration:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
    MODIFIER_PROPERTY_MANA_REGEN_TOTAL_PERCENTAGE,
    MODIFIER_EVENT_ON_TAKEDAMAGE,
  }
end

function modifier_rune_hill_lesser_regeneration:GetModifierHealthRegenPercentage()
  return 6
end

function modifier_rune_hill_lesser_regeneration:GetModifierTotalPercentageManaRegen()
  return 6
end

if IsServer() then
  function modifier_rune_hill_lesser_regeneration:OnTakeDamage(event)
    local victim = event.unit
    local attacker = event.attacker
    local damage = event.damage

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

    self:StartIntervalThink(-1)
    self:Destroy()
  end
end
