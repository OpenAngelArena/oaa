-- Anti-Judecca

modifier_all_healing_amplify_oaa = class(ModifierBaseClass)

function modifier_all_healing_amplify_oaa:IsHidden()
  return false
end

function modifier_all_healing_amplify_oaa:IsDebuff()
  return false
end

function modifier_all_healing_amplify_oaa:IsPurgable()
  return false
end

function modifier_all_healing_amplify_oaa:RemoveOnDeath()
  return false
end

function modifier_all_healing_amplify_oaa:OnCreated()
  self.heal_amp = 50
end

function modifier_all_healing_amplify_oaa:DeclareFunctions()
  return {
    --MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE,
    --MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
    --MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
    --MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
    MODIFIER_EVENT_ON_HEALTH_GAINED,
  }
end

-- function modifier_all_healing_amplify_oaa:GetModifierHealAmplify_PercentageSource()
  -- return self.heal_amp
-- end

-- Doesn't work, Thanks Valve!
-- function modifier_all_healing_amplify_oaa:GetModifierLifestealRegenAmplify_Percentage()
  -- return self.heal_amp
-- end

-- Doesn't work, Thanks Valve!
-- function modifier_all_healing_amplify_oaa:GetModifierSpellLifestealRegenAmplify_Percentage()
  -- return self.heal_amp
-- end

-- function modifier_all_healing_amplify_oaa:GetModifierHPRegenAmplify_Percentage()
  -- return self.heal_amp
-- end

if IsServer() then
  function modifier_all_healing_amplify_oaa:OnHealthGained(event)
    local parent = self:GetParent()
    local unit_that_gained_hp = event.unit

    -- Check if unit has this modifier
    if unit_that_gained_hp ~= parent then
      return
    end

    local gained_hp = event.gain

    -- Check if gained health is negative or 0
    if gained_hp <= 0 then
      return
    end

    -- Prevent looping
    if self.flag then
      return
    end

    local extra_health = gained_hp * self.heal_amp / 100

    -- Imitate heal amp and health restoration amp
    self.flag = true
    parent:Heal(extra_health, nil)
    self.flag = false
  end
end

function modifier_all_healing_amplify_oaa:GetTexture()
  return "item_kaya_and_sange"
end
