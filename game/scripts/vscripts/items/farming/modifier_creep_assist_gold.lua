LinkLuaModifier( "modifier_creep_assist_gold_aura", "items/farming/modifier_creep_assist_gold.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------

modifier_creep_assist_gold = class(ModifierBaseClass)

function modifier_creep_assist_gold:IsHidden()
  return true
end

function modifier_creep_assist_gold:IsPurgable()
  return false
end

function modifier_creep_assist_gold:OnCreated()
  if IsServer() then
    local parent = self:GetParent()
    local units = FindUnitsInRadius(
      parent:GetTeamNumber(),
      parent:GetAbsOrigin(),
      nil,
      self:GetAuraRadius(),
      self:GetAuraSearchTeam(),
      self:GetAuraSearchType(),
      self:GetAuraSearchFlags(),
      FIND_ANY_ORDER,
      false
    )

    local function DestroyModifier(modifier)
      modifier:Destroy()
    end

    local function DestroyCreepAssistModifiers(unit)
      local modifiers = unit:FindAllModifiersByName("modifier_creep_assist_gold_aura")
      foreach(DestroyModifier, modifiers)
    end

    -- Force refresh of all creep assist gold effect modifiers in area to avoid issues when items are upgraded
    foreach(DestroyCreepAssistModifiers, units)
  end
end

modifier_creep_assist_gold.OnRefresh = modifier_creep_assist_gold.OnCreated

--------------------------------------------------------------------------
-- aura stuff

function modifier_creep_assist_gold:IsAura()
  return Gold:IsGoldGenActive()
end

function modifier_creep_assist_gold:GetAuraDuration()
  return self:GetAbility():GetSpecialValueFor("assist_stickiness")
end

function modifier_creep_assist_gold:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_OTHER)
end

function modifier_creep_assist_gold:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_creep_assist_gold:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

function modifier_creep_assist_gold:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("assist_radius")
end

function modifier_creep_assist_gold:GetModifierAura()
  return "modifier_creep_assist_gold_aura"
end

function modifier_creep_assist_gold:GetAuraEntityReject(entity)
  local caster = self:GetCaster()
  local playerOwnerID = caster:GetPlayerOwnerID()
  local creepAssistModifiers = entity:FindAllModifiersByName("modifier_creep_assist_gold_aura")

  local function IsFromSamePlayer(modifier)
    return modifier:GetCaster():GetPlayerOwnerID() == playerOwnerID
  end

  -- Apply only one modifier per player and don't apply to units owned by the same player
  if any(IsFromSamePlayer, creepAssistModifiers) or entity:GetPlayerOwnerID() == playerOwnerID then
    return true
  else
    return false
  end
end

--------------------------------------------------------------------------

modifier_creep_assist_gold_aura = class(ModifierBaseClass)

function modifier_creep_assist_gold_aura:IsHidden()
  return true
end

function modifier_creep_assist_gold_aura:IsPurgable()
  return false
end

function modifier_creep_assist_gold_aura:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_creep_assist_gold_aura:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH
  }
end

function modifier_creep_assist_gold_aura:OnDeath(keys)
  local attacked = keys.unit
  if keys.attacker ~= self:GetParent() or self:GetParent() == self:GetCaster() or not attacked:IsNeutralUnitType() then
    return
  end
  --[[
[   VScript              ]: process_procs: false
[   VScript              ]: order_type: 0
[   VScript              ]: issuer_player_index: 1
[   VScript              ]: fail_type: 32767
[   VScript              ]: damage_category: 0
[   VScript              ]: reincarnate: false
[   VScript              ]: damage: 0
[   VScript              ]: ignore_invis: false
[   VScript              ]: attacker: table: 0x006bc3d0
[   VScript              ]: ranged_attack: false
[   VScript              ]: record: 72
[   VScript              ]: unit: table: 0x00635458
[   VScript              ]: do_not_consume: false
[   VScript              ]: damage_type: 1053999872
[   VScript              ]: activity: -1
[   VScript              ]: heart_regen_applied: false
[   VScript              ]: diffusal_applied: false
[   VScript              ]: no_attack_cooldown: false
[   VScript              ]: damage_flags: 0
[   VScript              ]: original_damage: 0
[   VScript              ]: gain: 0
[   VScript              ]: cost: 0
[   VScript              ]: basher_tested: false
[   VScript              ]: distance: 0
  int ModifyGold(int playerID, int goldAmmt, bool reliable, int nReason)
]]
  local caster = self:GetCaster() -- caster is hero with boots
  local playerID = caster:GetPlayerID()
  local player = PlayerResource:GetPlayer(playerID)
  local bounty = attacked:GetGoldBounty() * self:GetAbility():GetSpecialValueFor("assist_percent") / 100

  PlayerResource:ModifyGold(playerID, bounty, true, DOTA_ModifyGold_SharedGold)

  SendOverheadEventMessage(player, OVERHEAD_ALERT_GOLD, attacked, math.floor(bounty), player)
end
