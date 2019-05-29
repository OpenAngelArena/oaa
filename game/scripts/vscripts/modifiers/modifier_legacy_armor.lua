modifier_legacy_armor = class(ModifierBaseClass)
-- Adjusts armor so that it is equivalent to the old armor damage reduction formula:
-- (0.05 * armor) / (1 + 0.05 * |armor|)

function modifier_legacy_armor:IsPurgable()
  return false
end

function modifier_legacy_armor:IsHidden()
  return true
end

function modifier_legacy_armor:RemoveOnDeath()
  return false
end

function modifier_legacy_armor:IsPermanent()
  return true
end

function modifier_legacy_armor:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
  }
end

-- Only run on server so client still shows unmodified armor values
if IsServer() then
  function modifier_legacy_armor:GetModifierPhysicalArmorBonus()
    if (self.checkArmor) then
      return 0
    else
      self.checkArmor = true
      self.armor = self:GetParent():GetPhysicalArmorValue(false)
      self.checkArmor = false
      return 45 * self.armor / (52 + 0.2 * math.abs(self.armor)) - self.armor
    end
  end
end
