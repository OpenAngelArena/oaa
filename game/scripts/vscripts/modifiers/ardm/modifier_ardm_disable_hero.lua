modifier_ardm_disable_hero = modifier_ardm_disable_hero or class({})

function modifier_ardm_disable_hero:IsHidden()
  return true
end

function modifier_ardm_disable_hero:IsDebuff()
  return true
end

function modifier_ardm_disable_hero:IsPurgable()
  return false
end

function modifier_ardm_disable_hero:RemoveOnDeath()
  return false
end

function modifier_ardm_disable_hero:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_ardm_disable_hero:IsAura()
  return true
end

function modifier_ardm_disable_hero:GetModifierAura()
  return "modifier_out_of_duel"
end

function modifier_ardm_disable_hero:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_ardm_disable_hero:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO
end

function modifier_ardm_disable_hero:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_INVULNERABLE, DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD)
end

function modifier_ardm_disable_hero:GetAuraRadius()
  return 200
end

function modifier_ardm_disable_hero:GetAuraEntityReject(hEntity)
  local parent = self:GetParent()
  if hEntity ~= parent then
    return true
  end
  return false
end

function modifier_ardm_disable_hero:OnCreated()
  if not IsServer() then
    return
  end
  self.counter = 0
  self:StartIntervalThink(1)
end

function modifier_ardm_disable_hero:OnIntervalThink()
  if not IsServer() then
    return
  end
  local parent = self:GetParent()
  if not parent or parent:IsNull() then
    return
  end
  local num_of_active_modifiers = 0
  for index = 0, parent:GetAbilityCount() - 1 do
    local ability = parent:GetAbilityByIndex(index)
    if ability and not ability:IsNull() then
      if ability.NumModifiersUsingAbility and ability:NumModifiersUsingAbility() then
        num_of_active_modifiers = num_of_active_modifiers + ability:NumModifiersUsingAbility()
      end
    end
  end

  self.counter = self.counter + 1

  if self.counter > 45 or num_of_active_modifiers == 0 then
    self:StartIntervalThink(-1)
    self:Destroy()
  end
end

function modifier_ardm_disable_hero:OnDestroy()
  if not IsServer() then
    return
  end
  if ARDMMode then
    ARDMMode:RemoveOldHero(self:GetParent())
  end
end

function modifier_ardm_disable_hero:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
  }
end

function modifier_ardm_disable_hero:GetAbsoluteNoDamagePhysical()
  return 1
end

function modifier_ardm_disable_hero:GetAbsoluteNoDamageMagical()
  return 1
end

function modifier_ardm_disable_hero:GetAbsoluteNoDamagePure()
  return 1
end

function modifier_ardm_disable_hero:GetPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA + 10000
end

function modifier_ardm_disable_hero:CheckState()
  local state = {
    [MODIFIER_STATE_STUNNED] = true,
    [MODIFIER_STATE_OUT_OF_GAME] = true,
    [MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_UNSELECTABLE] = true,
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
    [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
    [MODIFIER_STATE_PASSIVES_DISABLED] = true,
    [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
    [MODIFIER_STATE_BLIND] = true,
    [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
    --[MODIFIER_STATE_NO_TEAM_MOVE_TO] = true,
    --[MODIFIER_STATE_NO_TEAM_SELECT] = true,
  }
  return state
end
