LinkLuaModifier("modifier_wanderer_team_buff", "modifiers/modifier_wanderer_team_buff.lua", LUA_MODIFIER_MOTION_NONE)

modifier_wanderer_team_buff = class(ModifierBaseClass)

function modifier_wanderer_team_buff:OnCreated ()
  if IsServer() then
    self:StartIntervalThink(1)
    self:SetStackCount(180)
    self.stackCount = 180
  end
end

function modifier_wanderer_team_buff:IsPurgable ()
  return false
end

function modifier_wanderer_team_buff:IsPurgeException ()
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

-- +20% cdr, movement speed, attack damage.
function modifier_wanderer_team_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE_STACKING,
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE
    -- MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE
  }
end

function modifier_wanderer_team_buff:GetModifierPercentageCooldownStacking ()
  if self:GetStackCount() > 1000 then
    return 0
  end
  return 20
end

function modifier_wanderer_team_buff:GetModifierBaseDamageOutgoing_Percentage ()
-- function modifier_wanderer_team_buff:GetModifierPreAttack_BonusDamage ()
  if self:GetStackCount() > 1000 then
    return 0
  end
  -- return self:GetParent():GetBaseDamageMax() * 0.2
  return 20
end

function modifier_wanderer_team_buff:GetModifierMoveSpeedBonus_Percentage ()
  if self:GetStackCount() > 1000 then
    return 0
  end
  return 20
end

function modifier_wanderer_team_buff:IsHidden ()
  return self:GetStackCount() > 1000
end

function modifier_wanderer_team_buff:GetTexture()
  return "rune_doubledamage"
end
