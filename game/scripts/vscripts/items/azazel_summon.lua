-- Azazel's Summons
-- by Firetoad, April 17th, 2018

--------------------------------------------------------------------------------

LinkLuaModifier("modifier_azazel_summon_farmer_innate", "items/azazel_summon.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_azazel_summon_scout_innate", "items/azazel_summon.lua", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

azazel_summon = class(ItemBaseClass)

function azazel_summon:OnSpellStart()
  if IsServer() then
    local caster = self:GetCaster()

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
    caster.azazel_summon = CreateUnitByName(summon_name, summon_position, true, caster, caster, caster:GetTeam())
    caster.azazel_summon:SetControllableByPlayer(caster:GetPlayerID(), true)
    --caster.azazel_summon:AddNewModifier(caster, self, "modifier_kill", {duration = self:GetSpecialValueFor("summon_duration")})

    -- Level up any relevant abilities
    if string.find(summon_name, "farmer") then
      caster.azazel_summon:AddAbility("azazel_summon_farmer_innate"):SetLevel(self:GetLevel())
    elseif string.find(summon_name, "scout") then
      caster.azazel_summon:AddAbility("azazel_scout_permanent_invisibility"):SetLevel(1)
      caster.azazel_summon:AddNewModifier(caster.azazel_summon, self, "modifier_azazel_summon_scout_innate", {})
    elseif string.find(summon_name, "fighter") then
      caster.azazel_summon:AddNewModifier(caster, self, "modifier_kill", {duration = self:GetSpecialValueFor("summon_duration")})
    end

    self:SpendCharge()
  end
end

--------------------------------------------------------------------------------

item_azazel_summon_farmer_1 = azazel_summon
item_azazel_summon_farmer_2 = azazel_summon
item_azazel_summon_farmer_3 = azazel_summon
item_azazel_summon_farmer_4 = azazel_summon
item_azazel_summon_scout_1 = azazel_summon
item_azazel_summon_scout_2 = azazel_summon
item_azazel_summon_scout_3 = azazel_summon
item_azazel_summon_scout_4 = azazel_summon
item_azazel_summon_tank_1 = azazel_summon
item_azazel_summon_tank_2 = azazel_summon
item_azazel_summon_tank_3 = azazel_summon
item_azazel_summon_tank_4 = azazel_summon
item_azazel_summon_fighter = azazel_summon

--------------------------------------------------------------------------------

azazel_summon_farmer_innate = class(AbilityBaseClass)

function azazel_summon_farmer_innate:GetIntrinsicModifierName()
  return "modifier_azazel_summon_farmer_innate"
end

--------------------------------------------------------------------------------

modifier_azazel_summon_farmer_innate = class(ModifierBaseClass)

function modifier_azazel_summon_farmer_innate:IsHidden() return true end
function modifier_azazel_summon_farmer_innate:IsPurgable() return false end
function modifier_azazel_summon_farmer_innate:IsDebuff() return false end

function modifier_azazel_summon_farmer_innate:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK,
    MODIFIER_EVENT_ON_ATTACK_LANDED
  }
  return funcs
end

function modifier_azazel_summon_farmer_innate:GetModifierPhysical_ConstantBlock()
  return self:GetAbility():GetSpecialValueFor("damage_block")
end

function modifier_azazel_summon_farmer_innate:OnAttackLanded(keys)
  if IsServer() then
    if keys.attacker == self:GetParent() and (not keys.target:IsBuilding()) then
      local ability = self:GetAbility()
      DoCleaveAttack(self:GetParent(), keys.target, ability, keys.damage * ability:GetSpecialValueFor("cleave_pct") * 0.01, ability:GetSpecialValueFor("cleave_start_radius"), ability:GetSpecialValueFor("cleave_end_radius"), ability:GetSpecialValueFor("cleave_length"), "particles/units/heroes/hero_sven/sven_spell_great_cleave.vpcf")
    end
  end
end

modifier_azazel_summon_scout_innate = class(ModifierBaseClass)

function modifier_azazel_summon_scout_innate:OnCreated()
  self:StartIntervalThink(0.1)
end

function modifier_azazel_summon_scout_innate:OnIntervalThink()
  if IsServer() then
    local parent = self:GetParent()
    -- No other way to have unobstructed vision without making the unit flying
    AddFOWViewer(parent:GetTeam(), parent:GetAbsOrigin(), parent:GetCurrentVisionRange(), 0.1, false)
  end
end

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
