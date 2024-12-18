
modifier_wanderer_team_buff = class(ModifierBaseClass)

function modifier_wanderer_team_buff:OnCreated ()
  if IsServer() then
    local duration_in_minutes = BOSS_WANDERER_BUFF_DURATION or 2.5
    local duration_in_seconds = duration_in_minutes * 60
    self:StartIntervalThink(1)
    self:SetStackCount(duration_in_seconds)
    self.stackCount = duration_in_seconds
  end
end

function modifier_wanderer_team_buff:IsPurgable ()
  return false
end

function modifier_wanderer_team_buff:RemoveOnDeath ()
  return false
end

if IsServer() then
  function modifier_wanderer_team_buff:OnIntervalThink()
    if Duels:IsActive() then
      self:SetStackCount(9001)
      return 1
    end

    self.stackCount = self.stackCount - 1
    self:SetStackCount(self.stackCount)

    if self.stackCount < 1 then
      self:Destroy()
    end
  end
end

-- +20% movement speed, attack damage.
function modifier_wanderer_team_buff:DeclareFunctions()
  return {
    --MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE_STACKING,
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
    MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
    MODIFIER_EVENT_ON_TAKEDAMAGE,
  }
end

-- function modifier_wanderer_team_buff:GetModifierPercentageCooldownStacking ()
  -- if self:GetStackCount() > 1000 then
    -- return 0
  -- end
  -- return 20
-- end

function modifier_wanderer_team_buff:GetModifierBaseDamageOutgoing_Percentage ()
  if self:GetStackCount() > 1000 then
    return 0
  end
  return 20
end

function modifier_wanderer_team_buff:GetModifierMoveSpeedBonus_Percentage ()
  if self:GetStackCount() > 1000 then
    return 0
  end
  return 20
end

function modifier_wanderer_team_buff:GetModifierSpellAmplify_Percentage()
  if self:GetStackCount() > 1000 then
    return 0
  end
  return 20
end

if IsServer() then
  function modifier_wanderer_team_buff:OnTakeDamage(event)
    local damaged_entity = event.unit
    local attacker = event.attacker

    if not attacker or attacker:IsNull() then
      return
    end

    if attacker ~= self:GetParent() then
      return
    end

    if not damaged_entity or damaged_entity:IsNull() then
      return
    end

    if damaged_entity.HasModifier == nil then
      return
    end

    if not damaged_entity:HasModifier("modifier_wanderer_boss_buff") then
      return
    end

    -- Remove this buff if the hero that is damaging the Wanderer has this buff
    -- Damaging the Wanderer while using the buff of the previous Wanderer is not cool
    self:Destroy()
  end
end

function modifier_wanderer_team_buff:IsHidden ()
  return self:GetStackCount() > 1000
end

function modifier_wanderer_team_buff:GetTexture()
  return "rune_doubledamage"
end
