
LinkLuaModifier("modifier_visage_gravekeepers_cloak_oaa", "abilities/visage_gravekeepers_cloak.lua", LUA_MODIFIER_MOTION_NONE) --- PETH WEFY INPARFANT
LinkLuaModifier("modifier_visage_gravekeepers_cloak_oaa_aura", "abilities/visage_gravekeepers_cloak.lua", LUA_MODIFIER_MOTION_NONE) --- PETH WEFY INPARFANT

visage_gravekeepers_cloak_oaa = class(AbilityBaseClass)

function visage_gravekeepers_cloak_oaa:GetIntrinsicModifierName()
  return "modifier_visage_gravekeepers_cloak_oaa"
end

if IsServer() then
  function visage_gravekeepers_cloak_oaa:OnUpgrade()
    local caster = self:GetCaster()
    local mod = caster:FindModifierByName("modifier_visage_gravekeepers_cloak_oaa")
    mod:SetStackCount(self:GetSpecialValueFor("max_layers"))
  end
end

---------------------------------------------------------------

modifier_visage_gravekeepers_cloak_oaa = class(ModifierBaseClass)

if IsServer() then
  function modifier_visage_gravekeepers_cloak_oaa:OnCreated()
    self:SetStackCount(self:GetAbility():GetSpecialValueFor("max_layers"))
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
    local ability = self:GetAbility()
    local stackCount = self:GetStackCount()
    if stackCount < ability:GetSpecialValueFor("max_layers") then
      self:SetStackCount(stackCount + 1)
    end
  end

  function modifier_visage_gravekeepers_cloak_oaa:GetModifierTotal_ConstantBlock(keys)
    local ability = self:GetAbility()
    local caster = self:GetCaster()
    local stackCount = self:GetStackCount()
    local damageReduction = math.min(100, ability:GetSpecialValueFor("damage_reduction") * stackCount)
    local damageThreshold = ability:GetSpecialValueFor("minimum_damage")
    local recovery_time = ability:GetSpecialValueFor("recovery_time")
    -- Talent that decreases recovery time
    if caster:HasLearnedAbility("special_bonus_unique_visage_oaa_5") then
      recovery_time = recovery_time - caster:FindAbilityByName("special_bonus_unique_visage_oaa_5"):GetSpecialValueFor("value")
    end
    if keys.attacker:GetTeam() ~= caster:GetTeam() and (keys.attacker:GetTeam() == DOTA_TEAM_GOODGUYS or keys.attacker:GetTeam() == DOTA_TEAM_BADGUYS) then
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
  return bit.bor(DOTA_UNIT_TARGET_ALL)
end

function modifier_visage_gravekeepers_cloak_oaa:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_PLAYER_CONTROLLED)
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
  local stackCount = caster:FindModifierByName('modifier_visage_gravekeepers_cloak_oaa'):GetStackCount()
  local damageReduction = math.min(100, self:GetAbility():GetSpecialValueFor("damage_reduction") * stackCount)
  return keys.damage * damageReduction / 100
end
