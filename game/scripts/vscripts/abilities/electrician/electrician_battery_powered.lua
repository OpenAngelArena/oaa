LinkLuaModifier( "modifier_electrician_battery_powered", "abilities/electrician/electrician_battery_powered.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
electrician_battery_powered = class( AbilityBaseClass )
--------------------------------------------------------------------------------

function electrician_battery_powered:GetIntrinsicModifierName()
  return "modifier_electrician_battery_powered"
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
modifier_electrician_battery_powered = class( ModifierBaseClass )
--------------------------------------------------------------------------------

function modifier_electrician_battery_powered:IsDebuff()
  return false
end

function modifier_electrician_battery_powered:IsHidden()
  return true
end

function modifier_electrician_battery_powered:IsPurgable()
  return false
end

if IsServer() then
  function modifier_electrician_battery_powered:DeclareFunctions()
    return {
      MODIFIER_PROPERTY_MANA_BONUS,
    }
  end

  function modifier_electrician_battery_powered:GetModifierManaBonus()
    local parent = self:GetParent()
    if not parent or parent:IsNull() then
      return 0
    end
    self.lastValueUsed = self.lastValueUsed or 0

    local maxMana = parent:GetMaxMana() - self.lastValueUsed
    local maxHealth = parent:GetMaxHealth()

    local amountToGain = 0

    if maxHealth > maxMana then
      amountToGain = maxHealth - maxMana
    end

    self.lastValueUsed = amountToGain
    return amountToGain
  end
end


--------------------------------------------------------------------------------
