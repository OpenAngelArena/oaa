-- Azazel's Summons
-- by Firetoad, April 17th, 2018

--------------------------------------------------------------------------------

LinkLuaModifier("modifier_azazel_summon_farmer_innate", "items/azazel_summon.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_azazel_summon_scout_innate", "items/azazel_summon.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_azazel_summon_tank_innate", "items/azazel_summon.lua", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

azazel_summon = class(ItemBaseClass)

function azazel_summon:OnSpellStart()
  local caster = self:GetCaster()

  -- Prevent use on Tempest Doubles, clones, Spirit Bears and not real heroes
  if not caster:IsRealHero() or caster:IsTempestDouble() or caster:IsClone() or caster:IsSpiritBearOAA() then
    return
  end

  caster:EmitSound("DOTA_Item.Necronomicon.Activate")

  -- Destroy any existing summons tied to this caster
  if caster.azazel_summon ~= nil and not caster.azazel_summon:IsNull() and IsValidEntity(caster.azazel_summon) then
    if caster:GetTeamNumber() == DOTA_TEAM_NEUTRALS then
      caster.azazel_summon:ForceKillOAA(false)
    else
      caster.azazel_summon:Kill(nil, caster)
    end
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
    azazel_summon:AddNewModifier(caster, self, "modifier_azazel_summon_farmer_innate", {dmg_block = self:GetSpecialValueFor("summon_damage_block")})
  elseif string.find(summon_name, "tank") then
    azazel_summon:AddNewModifier(caster, self, "modifier_azazel_summon_tank_innate", {dmg_reduction = self:GetSpecialValueFor("damage_reduction_against_neutrals")})
  elseif string.find(summon_name, "scout") then
    azazel_summon:AddAbility("azazel_scout_permanent_invisibility"):SetLevel(1)
    azazel_summon:AddNewModifier(caster, self, "modifier_azazel_summon_scout_innate", {})
  elseif string.find(summon_name, "fighter") then
    local summon_duration = self:GetSpecialValueFor("summon_duration")
    azazel_summon:AddNewModifier(caster, self, "modifier_kill", {duration = summon_duration})
    azazel_summon:AddNewModifier(caster, self, "modifier_generic_dead_tracker_oaa", {duration = summon_duration + MANUAL_GARBAGE_CLEANING_TIME})
  end

  azazel_summon:AddNewModifier(caster, self, "modifier_phased", {duration = FrameTime()}) -- for unstucking

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

  self:SpendCharge(0.1)
end

--------------------------------------------------------------------------------

item_azazel_summon_farmer = azazel_summon
item_azazel_summon_scout = azazel_summon
item_azazel_summon_tank = azazel_summon
item_azazel_summon_fighter = azazel_summon

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

function modifier_azazel_summon_farmer_innate:OnCreated(event)
  if IsServer() then
    self:SetStackCount(event.dmg_block)
  end
end

function modifier_azazel_summon_farmer_innate:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK,
    MODIFIER_EVENT_ON_ATTACK_LANDED
  }
end

function modifier_azazel_summon_farmer_innate:GetModifierPhysical_ConstantBlock()
  return self:GetStackCount()
end

if IsServer() then
  function modifier_azazel_summon_farmer_innate:OnAttackLanded(event)
    local parent = self:GetParent()
    if event.attacker ~= parent then
      return
    end

    if not parent or parent:IsNull() then
      return
    end

    if parent:IsIllusion() or parent:IsRangedAttacker() then
      return
    end

    local target = event.target
    if not target or target:IsNull() then
      return
    end

    if target.GetUnitName == nil then
      return
    end

    -- Don't affect buildings, wards and invulnerable units.
    if target:IsTower() or target:IsBarracks() or target:IsBuilding() or target:IsOther() or target:IsInvulnerable() then
      return
    end

    -- get the cleave parameters
    local start_radius = 200
    local end_radius = 360
    local distance = 650
    local percent = 50

    -- get the attacker's damage
    local damage = event.original_damage

    -- get the damage modifier
    local actual_damage = damage*percent*0.01

    DoCleaveAttack(parent, target, nil, actual_damage, start_radius, end_radius, distance, "particles/items_fx/battlefury_cleave.vpcf")
  end
end

---------------------------------------------------------------------------------------------------

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

---------------------------------------------------------------------------------------------------

modifier_azazel_summon_tank_innate = class(ModifierBaseClass)

function modifier_azazel_summon_tank_innate:IsHidden()
  return true
end

function modifier_azazel_summon_tank_innate:IsDebuff()
  return false
end

function modifier_azazel_summon_tank_innate:IsPurgable()
  return false
end

function modifier_azazel_summon_tank_innate:OnCreated(event)
  if IsServer() then
    self.dmg_reduction = event.dmg_reduction
  end
end

function modifier_azazel_summon_tank_innate:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
  }
end

if IsServer() then
  function modifier_azazel_summon_tank_innate:GetModifierTotal_ConstantBlock(event)
    local attacker = event.attacker

    if not attacker or attacker:IsNull() then
      return 0
    end

    if attacker.IsBaseNPC == nil then
      return 0
    end

    if not attacker:IsBaseNPC() then
      return 0
    end

    -- Block damage from neutrals and always from bosses
    if attacker:IsOAABoss() or attacker:GetTeamNumber() == DOTA_TEAM_NEUTRALS then
      return event.damage * self.dmg_reduction / 100
    end

    return 0
  end
end

