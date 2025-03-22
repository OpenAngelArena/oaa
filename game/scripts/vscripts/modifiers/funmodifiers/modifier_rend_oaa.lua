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
  self.duration = 7
end

function modifier_rend_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
  }
end

if IsServer() then
  function modifier_rend_oaa:GetModifierProcAttack_Feedback(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local target = event.target

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if attacker ~= parent then
      return
    end

    -- Check if attacked unit exists
    if not target or target:IsNull() then
      return
    end

    -- Check for existence of GetUnitName method to determine if target is a unit or an item (or rune)
    -- items don't have that method -> nil; if the target is an item, don't continue
    if target.GetUnitName == nil then
      return
    end

    -- No need to proc if target is invulnerable or dead
    if target:IsInvulnerable() or target:IsOutOfGame() or not target:IsAlive() then
      return
    end

    target:AddNewModifier(parent, nil, "modifier_rend_armor_reduction_oaa", {duration = self.duration})
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
