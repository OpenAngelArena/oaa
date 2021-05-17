
LinkLuaModifier("modifier_visage_gravekeepers_cloak_oaa", "abilities/visage_gravekeepers_cloak.lua", LUA_MODIFIER_MOTION_NONE) --- PETH WEFY INPARFANT
LinkLuaModifier("modifier_visage_gravekeepers_cloak_oaa_aura", "abilities/visage_gravekeepers_cloak.lua", LUA_MODIFIER_MOTION_NONE) --- PETH WEFY INPARFANT

visage_gravekeepers_cloak_oaa = class(AbilityBaseClass)

function visage_gravekeepers_cloak_oaa:GetIntrinsicModifierName()
  return "modifier_visage_gravekeepers_cloak_oaa"
end

function visage_gravekeepers_cloak_oaa:OnUpgrade()
  local caster = self:GetCaster()
  local mod = caster:FindModifierByName("modifier_visage_gravekeepers_cloak_oaa")
  local max_layers = self:GetSpecialValueFor("max_layers")
  -- Talent that increases number of layers
  local talent = caster:FindAbilityByName("special_bonus_unique_visage_5")
  if talent then
    if talent:GetLevel() > 0 then
      max_layers = max_layers + talent:GetSpecialValueFor("value")
    end
  end
  if mod then
    mod:SetStackCount(max_layers)
  end
end

---------------------------------------------------------------

modifier_visage_gravekeepers_cloak_oaa = class(ModifierBaseClass)


function modifier_visage_gravekeepers_cloak_oaa:OnCreated()
  if IsServer() then
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local max_layers = ability:GetSpecialValueFor("max_layers")
    -- Talent that increases number of layers
    local talent = caster:FindAbilityByName("special_bonus_unique_visage_5")
    if talent then
      if talent:GetLevel() > 0 then
        max_layers = max_layers + talent:GetSpecialValueFor("value")
      end
    end
    self:SetStackCount(max_layers)
  end
end

modifier_visage_gravekeepers_cloak_oaa.OnRefresh = modifier_visage_gravekeepers_cloak_oaa.OnCreated

if IsServer() then
  function modifier_visage_gravekeepers_cloak_oaa:DeclareFunctions()
    return {
      MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK
    }
  end

  function modifier_visage_gravekeepers_cloak_oaa:DecreaseStacks()
    local stackCount = self:GetStackCount()
    self:SetStackCount(math.max(0, stackCount - 1))
  end

  function modifier_visage_gravekeepers_cloak_oaa:IncreaseStacks()
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local stackCount = self:GetStackCount()
    local max_layers = ability:GetSpecialValueFor("max_layers")
    -- Talent that increases number of layers
    local talent = caster:FindAbilityByName("special_bonus_unique_visage_5")
    if talent then
      if talent:GetLevel() > 0 then
        max_layers = max_layers + talent:GetSpecialValueFor("value")
      end
    end
    if stackCount < max_layers then
      self:SetStackCount(stackCount + 1)
    end
  end

  function modifier_visage_gravekeepers_cloak_oaa:GetModifierTotal_ConstantBlock(keys)
    local ability = self:GetAbility()
    local caster = self:GetCaster()
    local stackCount = self:GetStackCount()
    local damageReduction = math.min(80, ability:GetSpecialValueFor("damage_reduction") * stackCount)
    local damageThreshold = ability:GetSpecialValueFor("minimum_damage")
    local recovery_time = ability:GetSpecialValueFor("recovery_time")
    -- Talent that decreases recovery time
    if caster:HasLearnedAbility("special_bonus_unique_visage_oaa_5") then
      recovery_time = recovery_time - caster:FindAbilityByName("special_bonus_unique_visage_oaa_5"):GetSpecialValueFor("value")
    end
    if keys.attacker:GetTeam() ~= caster:GetTeam() and keys.attacker:GetTeam() ~= DOTA_TEAM_NEUTRALS then
      if keys.damage > damageThreshold then
        self:DecreaseStacks()
        Timers:CreateTimer(recovery_time, function()
          self:IncreaseStacks()
        end)
      end
    end
    return keys.damage * damageReduction / 100
  end
end

function modifier_visage_gravekeepers_cloak_oaa:IsPurgable()
  return false
end

function modifier_visage_gravekeepers_cloak_oaa:RemoveOnDeath()
  return false
end

--------------------------------------------------------------------------
-- aura stuff

function modifier_visage_gravekeepers_cloak_oaa:IsAura()
  return true
end

function modifier_visage_gravekeepers_cloak_oaa:GetAuraSearchType()
  return DOTA_UNIT_TARGET_ALL
end

function modifier_visage_gravekeepers_cloak_oaa:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_PLAYER_CONTROLLED
end

function modifier_visage_gravekeepers_cloak_oaa:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_visage_gravekeepers_cloak_oaa:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_visage_gravekeepers_cloak_oaa:GetModifierAura()
  return "modifier_visage_gravekeepers_cloak_oaa_aura"
end

function modifier_visage_gravekeepers_cloak_oaa:GetAuraEntityReject(entity)
  return string.sub(entity:GetUnitName(), 0, 24) ~= "npc_dota_visage_familiar"
end

---------------------------------------------------------------

modifier_visage_gravekeepers_cloak_oaa_aura = class(ModifierBaseClass)

function modifier_visage_gravekeepers_cloak_oaa_aura:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK
  }
end

function modifier_visage_gravekeepers_cloak_oaa_aura:GetModifierTotal_ConstantBlock(keys)
  local caster = self:GetCaster()
  local mod = caster:FindModifierByName("modifier_visage_gravekeepers_cloak_oaa")
  if mod then
    local stackCount = mod:GetStackCount()
    local damageReduction = math.min(80, self:GetAbility():GetSpecialValueFor("damage_reduction") * stackCount)
    return keys.damage * damageReduction / 100
  end

  return 0
end
