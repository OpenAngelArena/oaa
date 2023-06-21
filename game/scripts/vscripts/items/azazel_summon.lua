-- Azazel's Summons
-- by Firetoad, April 17th, 2018

--------------------------------------------------------------------------------

LinkLuaModifier("modifier_azazel_summon_farmer_innate", "items/azazel_summon.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_azazel_summon_scout_innate", "items/azazel_summon.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_generic_dead_tracker_oaa", "modifiers/modifier_generic_dead_tracker_oaa.lua", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

azazel_summon = class(ItemBaseClass)

function azazel_summon:OnSpellStart()
  local caster = self:GetCaster()

  -- Prevent use on Spirit Bear and other non-hero units with inventory
  if not caster:IsRealHero() then
    return
  end

  caster:EmitSound("DOTA_Item.Necronomicon.Activate")

  -- Destroy any existing summons tied to this caster
  if caster.azazel_summon ~= nil and not caster.azazel_summon:IsNull() and IsValidEntity(caster.azazel_summon) then
    caster.azazel_summon:Kill(nil, caster)
  end

  -- Summon parameters
  local summon_position = caster:GetAbsOrigin() + caster:GetForwardVector() * 100
  local summon_name = self:GetAbilityName()
  summon_name = "npc_dota_"..summon_name:sub(6)

  -- Summon the creature
  GridNav:DestroyTreesAroundPoint(summon_position, 128, false)
  local azazel_summon = CreateUnitByName(summon_name, summon_position, true, caster, caster, caster:GetTeam())
  azazel_summon:SetControllableByPlayer(caster:GetPlayerOwnerID(), true)

  -- Level up any relevant abilities
  if string.find(summon_name, "farmer") then
    azazel_summon:AddAbility("azazel_summon_farmer_innate"):SetLevel(self:GetLevel())
  elseif string.find(summon_name, "scout") then
    azazel_summon:AddAbility("azazel_scout_permanent_invisibility"):SetLevel(1)
    azazel_summon:AddNewModifier(caster, self, "modifier_azazel_summon_scout_innate", {})
  elseif string.find(summon_name, "fighter") then
    local summon_duration = self:GetSpecialValueFor("summon_duration")
    azazel_summon:AddNewModifier(caster, self, "modifier_kill", {duration = summon_duration})
    azazel_summon:AddNewModifier(caster, self, "modifier_generic_dead_tracker_oaa", {duration = summon_duration + MANUAL_GARBAGE_CLEANING_TIME})
  end

  -- Fix stats of summons
  local summon_hp = self:GetSpecialValueFor("summon_health")
  local summon_dmg = self:GetSpecialValueFor("summon_damage")
  local summon_armor = self:GetSpecialValueFor("summon_armor")
  local summon_ms = self:GetSpecialValueFor("summon_ms")

  -- HP
  if summon_hp and summon_hp > 0 then
    azazel_summon:SetBaseMaxHealth(summon_hp)
    azazel_summon:SetMaxHealth(summon_hp)
    azazel_summon:SetHealth(summon_hp)
  end

  -- DAMAGE
  if summon_dmg and summon_dmg > 0 then
    azazel_summon:SetBaseDamageMin(summon_dmg)
    azazel_summon:SetBaseDamageMax(summon_dmg)
  end

  -- ARMOR
  if summon_armor and summon_armor > 0 then
    azazel_summon:SetPhysicalArmorBaseValue(summon_armor)
  end

  -- Movement speed
  if summon_ms and summon_ms > 0 then
    azazel_summon:SetBaseMoveSpeed(summon_ms)
  end

  caster.azazel_summon = azazel_summon

  self:SpendCharge()
end

--------------------------------------------------------------------------------

item_azazel_summon_farmer = azazel_summon
item_azazel_summon_scout = azazel_summon
item_azazel_summon_tank = azazel_summon
item_azazel_summon_fighter = azazel_summon

--------------------------------------------------------------------------------

azazel_summon_farmer_innate = class(AbilityBaseClass)

function azazel_summon_farmer_innate:GetIntrinsicModifierName()
  return "modifier_azazel_summon_farmer_innate"
end

--------------------------------------------------------------------------------

modifier_azazel_summon_farmer_innate = class(ModifierBaseClass)

function modifier_azazel_summon_farmer_innate:IsHidden()
  return true
end

function modifier_azazel_summon_farmer_innate:IsDebuff()
  return false
end

function modifier_azazel_summon_farmer_innate:IsPurgable()
  return false
end

function modifier_azazel_summon_farmer_innate:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK,
    MODIFIER_EVENT_ON_ATTACK_LANDED
  }
end

function modifier_azazel_summon_farmer_innate:GetModifierPhysical_ConstantBlock()
  return self:GetAbility():GetSpecialValueFor("damage_block")
end

if IsServer() then
  function modifier_azazel_summon_farmer_innate:OnAttackLanded(keys)
    if keys.attacker == self:GetParent() and (not keys.target:IsBuilding()) then
      local ability = self:GetAbility()
      DoCleaveAttack(self:GetParent(), keys.target, ability, keys.damage * ability:GetSpecialValueFor("cleave_pct") * 0.01, ability:GetSpecialValueFor("cleave_start_radius"), ability:GetSpecialValueFor("cleave_end_radius"), ability:GetSpecialValueFor("cleave_length"), "particles/units/heroes/hero_sven/sven_spell_great_cleave.vpcf")
    end
  end
end

modifier_azazel_summon_scout_innate = class(ModifierBaseClass)

-- old flying vision
--[[
function modifier_azazel_summon_scout_innate:OnCreated()
  self:StartIntervalThink(0.1)
end

function modifier_azazel_summon_scout_innate:OnIntervalThink()
  if IsServer() then
    local parent = self:GetParent()
    -- unobstructed vision
    AddFOWViewer(parent:GetTeam(), parent:GetAbsOrigin(), parent:GetCurrentVisionRange(), 0.1, false)
  end
end
]]

function modifier_azazel_summon_scout_innate:IsHidden()
  return true
end

function modifier_azazel_summon_scout_innate:IsDebuff()
  return false
end

function modifier_azazel_summon_scout_innate:IsPurgable()
  return false
end

function modifier_azazel_summon_scout_innate:IsAura()
  return true
end

function modifier_azazel_summon_scout_innate:GetModifierAura()
  return "modifier_truesight"
end

function modifier_azazel_summon_scout_innate:GetAuraRadius()
  local parent = self:GetParent()
  return parent:GetCurrentVisionRange() or 1200
end

function modifier_azazel_summon_scout_innate:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_azazel_summon_scout_innate:GetAuraSearchType()
  return DOTA_UNIT_TARGET_ALL
end

function modifier_azazel_summon_scout_innate:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_INVULNERABLE)
end

-- Flying Vision
function modifier_azazel_summon_scout_innate:CheckState()
  return {
    [MODIFIER_STATE_FORCED_FLYING_VISION] = true,
  }
end
