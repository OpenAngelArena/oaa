LinkLuaModifier("modifier_brawler_stack_oaa", "modifiers/funmodifiers/modifier_brawler_oaa.lua", LUA_MODIFIER_MOTION_NONE)

modifier_brawler_oaa = class(ModifierBaseClass)

function modifier_brawler_oaa:IsHidden()
  return false
end

function modifier_brawler_oaa:IsDebuff()
  return false
end

function modifier_brawler_oaa:IsPurgable()
  return false
end

function modifier_brawler_oaa:RemoveOnDeath()
  local parent = self:GetParent()
  if parent:IsRealHero() and not parent:IsOAABoss() then
    return false
  end
  return true
end

function modifier_brawler_oaa:OnCreated()
  self.hero_stacks = 2
  self.duration = 5
end

function modifier_brawler_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACKED,
  }
end

if IsServer() then
  function modifier_brawler_oaa:OnAttacked(event)
    local parent = self:GetParent()
    if event.target ~= parent then
      return
    end

    local attacker = event.attacker
    if not attacker or attacker:IsNull() then
      return
    end

    if attacker:IsHero() then
      for i = 1, self.hero_stacks do
        parent:AddNewModifier(parent, nil, "modifier_brawler_stack_oaa", {duration = self.duration})
      end
    else
      parent:AddNewModifier(parent, nil, "modifier_brawler_stack_oaa", {duration = self.duration})
    end
  end
end

function modifier_brawler_oaa:GetTexture()
  return "tusk_walrus_kick"
end

---------------------------------------------------------------------------------------------------

modifier_brawler_stack_oaa = class(ModifierBaseClass)

function modifier_brawler_stack_oaa:IsHidden()
  return false
end

function modifier_brawler_stack_oaa:IsDebuff()
  return false
end

function modifier_brawler_stack_oaa:IsPurgable()
  return false
end

function modifier_brawler_stack_oaa:RemoveOnDeath()
  return true
end

function modifier_brawler_stack_oaa:OnCreated()
  self.as_per_stack = 5
  self.ms_per_stack = 2
  self.dmg_per_stack = 2

  if IsServer() then
    self:SetStackCount(1)
  end
end

function modifier_brawler_stack_oaa:OnRefresh()
  self.as_per_stack = 5
  self.ms_per_stack = 2
  self.dmg_per_stack = 2

  if IsServer() then
    self:IncrementStackCount()
  end
end

function modifier_brawler_stack_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
  }
end

function modifier_brawler_stack_oaa:GetModifierAttackSpeedBonus_Constant()
  return self:GetStackCount() * self.as_per_stack
end

function modifier_brawler_stack_oaa:GetModifierBaseDamageOutgoing_Percentage()
  return self:GetStackCount() * self.dmg_per_stack
end

function modifier_brawler_stack_oaa:GetModifierMoveSpeedBonus_Constant()
  return self:GetStackCount() * self.ms_per_stack
end

function modifier_brawler_stack_oaa:GetTexture()
  return "tusk_walrus_kick"
end
