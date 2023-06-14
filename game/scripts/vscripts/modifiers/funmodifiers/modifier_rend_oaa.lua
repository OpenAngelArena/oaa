LinkLuaModifier("modifier_rend_armor_reduction_oaa", "modifiers/funmodifiers/modifier_rend_oaa.lua", LUA_MODIFIER_MOTION_NONE)

modifier_rend_oaa = class(ModifierBaseClass)

function modifier_rend_oaa:IsHidden()
  return false
end

function modifier_rend_oaa:IsDebuff()
  return false
end

function modifier_rend_oaa:IsPurgable()
  return false
end

function modifier_rend_oaa:RemoveOnDeath()
  return false
end

function modifier_rend_oaa:OnCreated()
  self.duration = 6
end

function modifier_rend_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

if IsServer() then
  function modifier_rend_oaa:OnAttackLanded(event)
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local target = event.target

    -- Doesn't work on units that dont have this modifier, doesn't work on illusions
    if parent ~= event.attacker or parent:IsIllusion() then
      return
    end

    -- To prevent crashes:
    if not target then
      return
    end

    if target:IsNull() then
      return
    end

    -- Doesn't work on allies, towers, or wards
    if UnitFilter(target, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, parent:GetTeamNumber()) ~= UF_SUCCESS then
      return
    end

    -- Get duration
    local duration = self.duration

    target:AddNewModifier(parent, ability, "modifier_rend_armor_reduction_oaa", {duration = duration})
  end
end

function modifier_rend_oaa:GetTexture()
  return "item_blight_stone"
end

---------------------------------------------------------------------------------------------------

modifier_rend_armor_reduction_oaa = class(ModifierBaseClass)

function modifier_rend_armor_reduction_oaa:IsHidden()
  return false
end

function modifier_rend_armor_reduction_oaa:IsDebuff()
  return true
end

function modifier_rend_armor_reduction_oaa:IsPurgable()
  return true
end

function modifier_rend_armor_reduction_oaa:RemoveOnDeath()
  return true
end

function modifier_rend_armor_reduction_oaa:OnCreated()
  if not IsServer() then
    return
  end

  self:SetStackCount(1)
end

function modifier_rend_armor_reduction_oaa:OnRefresh()
  if not IsServer() then
    return
  end

  self:IncrementStackCount()
end

function modifier_rend_armor_reduction_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
  }
end

function modifier_rend_armor_reduction_oaa:GetModifierPhysicalArmorBonus()
  local armor_per_stack = 1
  local stacks = self:GetStackCount()

  return 0 - armor_per_stack * stacks
end

function modifier_rend_armor_reduction_oaa:GetTexture()
  return "item_blight_stone"
end
