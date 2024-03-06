LinkLuaModifier("modifier_vengefulspirit_command_aura_oaa", "abilities/oaa_vengefulspirit_command_aura.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_vengefulspirit_command_aura_oaa_damage_buff", "abilities/oaa_vengefulspirit_command_aura.lua", LUA_MODIFIER_MOTION_NONE)
--LinkLuaModifier("modifier_vengefulspirit_command_aura_oaa_scepter_illusion_tracker", "abilities/oaa_vengefulspirit_command_aura.lua", LUA_MODIFIER_MOTION_NONE)
--LinkLuaModifier("modifier_vengefulspirit_command_aura_oaa_scepter_illusion_hide", "abilities/oaa_vengefulspirit_command_aura.lua", LUA_MODIFIER_MOTION_NONE)

vengefulspirit_command_aura_oaa = class(AbilityBaseClass)

function vengefulspirit_command_aura_oaa:GetIntrinsicModifierName()
  return "modifier_vengefulspirit_command_aura_oaa"
end

---------------------------------------------------------------------------------------------------

modifier_vengefulspirit_command_aura_oaa = class(ModifierBaseClass)

function modifier_vengefulspirit_command_aura_oaa:IsHidden()
  return true
end

function modifier_vengefulspirit_command_aura_oaa:IsPurgable()
  return false
end

function modifier_vengefulspirit_command_aura_oaa:RemoveOnDeath()
  return false
end

function modifier_vengefulspirit_command_aura_oaa:IsAura()
  if self:GetParent():PassivesDisabled() then
    return false
  end
  return true
end

function modifier_vengefulspirit_command_aura_oaa:GetModifierAura()
  return "modifier_vengefulspirit_command_aura_oaa_damage_buff"
end

function modifier_vengefulspirit_command_aura_oaa:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_vengefulspirit_command_aura_oaa:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
end

function modifier_vengefulspirit_command_aura_oaa:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

function modifier_vengefulspirit_command_aura_oaa:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_vengefulspirit_command_aura_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH,
    MODIFIER_EVENT_ON_RESPAWN,
  }
end

if IsServer() then
  function modifier_vengefulspirit_command_aura_oaa:OnDeath(event)
    local parent = self:GetParent()
    if not parent:HasScepter() or parent:IsIllusion() then
      return
    end

    if event.unit ~= parent then
      return
    end

    local ability = self:GetAbility()
    if not ability or ability:IsNull() then
      return
    end

    local playerID = parent:GetPlayerOwnerID()

    local illusion_table = {
      outgoing_damage = 100 - ability:GetSpecialValueFor("scepter_illusion_damage_out_pct"),
      incoming_damage = ability:GetSpecialValueFor("scepter_illusion_damage_in_pct") - 100,
      bounty_base = 0,
      bounty_growth = 0,
      outgoing_damage_structure = 0,
      outgoing_damage_roshan = 0,
    }
    local illusions = CreateIllusions(parent, parent, illusion_table, 1, parent:GetHullRadius(), true, true)
    for _, illusion in pairs(illusions) do
      illusion:SetHealth(illusion:GetMaxHealth())
      illusion:SetMana(illusion:GetMaxMana())
      illusion:AddNewModifier(parent, ability, "modifier_vengefulspirit_hybrid_special", {})
      --illusion:AddNewModifier(parent, ability, "modifier_vengefulspirit_command_aura_oaa_scepter_illusion_tracker", {})
      self.illusion = illusion

      Timers:CreateTimer(1/30, function()
        local player = PlayerResource:GetPlayer(playerID)
        if player then
          CustomGameEventManager:Send_ServerToPlayer(player, "AddRemoveSelection", {entity_to_add = illusion:GetEntityIndex(), entity_to_remove = parent:GetEntityIndex()})
        end
      end)
    end
  end

  function modifier_vengefulspirit_command_aura_oaa:OnRespawn(event)
    local parent = self:GetParent()
    if not parent:HasScepter() or parent:IsIllusion() then
      return
    end

    -- Stuff that shoudln't happen if this ability is put on other heroes
    if parent:IsTempestDouble() or parent:IsClone() or parent:IsSpiritBearOAA() then
      return
    end

    if event.unit ~= parent then
      return
    end
    --[[
    if self.illusion and not self.illusion:IsNull() then
      self.illusion:AddNoDraw()
      self.illusion:AddNewModifier(parent, nil, "modifier_vengefulspirit_command_aura_oaa_scepter_illusion_hide", {})
    end
    ]]
    local playerID = parent:GetPlayerOwnerID()
    local player = PlayerResource:GetPlayer(playerID)
    if player then
      if self.illusion and not self.illusion:IsNull() then
        CustomGameEventManager:Send_ServerToPlayer(player, "AddRemoveSelection", {entity_to_add = parent:GetEntityIndex(), entity_to_remove = self.illusion:GetEntityIndex()})
      else
        CustomGameEventManager:Send_ServerToPlayer(player, "AddRemoveSelection", {entity_to_add = parent:GetEntityIndex()})
      end
    end
  end
end

---------------------------------------------------------------------------------------------------

modifier_vengefulspirit_command_aura_oaa_damage_buff = class(ModifierBaseClass)

function modifier_vengefulspirit_command_aura_oaa_damage_buff:IsHidden()
  return false
end

function modifier_vengefulspirit_command_aura_oaa_damage_buff:IsDebuff()
  return false
end

function modifier_vengefulspirit_command_aura_oaa_damage_buff:IsPurgable()
  return false
end

function modifier_vengefulspirit_command_aura_oaa_damage_buff:OnCreated()
  self.damage = self:GetAbility():GetSpecialValueFor("bonus_base_damage")
end

function modifier_vengefulspirit_command_aura_oaa_damage_buff:OnRefresh()
  self:OnCreated()
end

function modifier_vengefulspirit_command_aura_oaa_damage_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
  }
end

function modifier_vengefulspirit_command_aura_oaa_damage_buff:GetModifierBaseDamageOutgoing_Percentage()
  local caster = self:GetCaster()
  if caster and not caster:IsNull() then
    -- Talent that increases bonus damage
    local talent = caster:FindAbilityByName("special_bonus_unique_vengeful_spirit_2")
    if talent and talent:GetLevel() > 0 then
      return self.damage + math.abs(talent:GetSpecialValueFor("value"))
    end
  end

  return self.damage
end

---------------------------------------------------------------------------------------------------
--[[ -- if 'modifier_vengefulspirit_hybrid_special' doesn't handle everything
modifier_vengefulspirit_command_aura_oaa_scepter_illusion_tracker = class(ModifierBaseClass)

function modifier_vengefulspirit_command_aura_oaa_scepter_illusion_tracker:IsHidden()
  return true
end

function modifier_vengefulspirit_command_aura_oaa_scepter_illusion_tracker:IsDebuff()
  return false
end

function modifier_vengefulspirit_command_aura_oaa_scepter_illusion_tracker:IsPurgable()
  return false
end

function modifier_vengefulspirit_command_aura_oaa_scepter_illusion_tracker:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH,
  }
end

if IsServer() then
  function modifier_vengefulspirit_command_aura_oaa_scepter_illusion_tracker:OnDeath(event)
    local parent = self:GetParent()
    if not parent:HasScepter() or not parent:IsIllusion() then
      return
    end

    if event.unit ~= parent then
      return
    end

    parent:RespawnUnit() -- idk if this works on illusions
    parent:AddNoDraw()
    parent:AddNewModifier(parent, nil, "modifier_vengefulspirit_command_aura_oaa_scepter_illusion_hide", {})
  end
end

---------------------------------------------------------------------------------------------------

modifier_vengefulspirit_command_aura_oaa_scepter_illusion_hide = class(ModifierBaseClass)

function modifier_vengefulspirit_command_aura_oaa_scepter_illusion_hide:IsHidden()
  return true
end

function modifier_vengefulspirit_command_aura_oaa_scepter_illusion_hide:IsDebuff()
  return false
end

function modifier_vengefulspirit_command_aura_oaa_scepter_illusion_hide:IsPurgable()
  return false
end

function modifier_vengefulspirit_command_aura_oaa_scepter_illusion_hide:OnCreated()
  if not IsServer() then
    return
  end
  self.counter = 0
  self:StartIntervalThink(1)
end

function modifier_vengefulspirit_command_aura_oaa_scepter_illusion_hide:OnIntervalThink()
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

  if self.counter > 9 or num_of_active_modifiers == 0 then
    self:StartIntervalThink(-1)
    self:Destroy()
  end
end

function modifier_vengefulspirit_command_aura_oaa_scepter_illusion_hide:OnDestroy()
  if not IsServer() then
    return
  end
  local parent = self:GetParent()
  if not parent or parent:IsNull() then
    return
  end

  parent:ForceKillOAA(false)
end

function modifier_vengefulspirit_command_aura_oaa_scepter_illusion_hide:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
  }
end

function modifier_vengefulspirit_command_aura_oaa_scepter_illusion_hide:GetAbsoluteNoDamagePhysical()
  return 1
end

function modifier_vengefulspirit_command_aura_oaa_scepter_illusion_hide:GetAbsoluteNoDamageMagical()
  return 1
end

function modifier_vengefulspirit_command_aura_oaa_scepter_illusion_hide:GetAbsoluteNoDamagePure()
  return 1
end

function modifier_vengefulspirit_command_aura_oaa_scepter_illusion_hide:GetPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA + 10000
end

function modifier_vengefulspirit_command_aura_oaa_scepter_illusion_hide:CheckState()
  return {
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
  }
end
]]
