
modifier_mars_arena_of_blood_leash_oaa = modifier_mars_arena_of_blood_leash_oaa or class({})

function modifier_mars_arena_of_blood_leash_oaa:IsHidden()
  return true
end

function modifier_mars_arena_of_blood_leash_oaa:IsDebuff()
  return false
end

function modifier_mars_arena_of_blood_leash_oaa:IsPurgable()
  return false
end

function modifier_mars_arena_of_blood_leash_oaa:OnCreated()
  if IsServer() then
    self:StartIntervalThink(0.1)
  end
end

function modifier_mars_arena_of_blood_leash_oaa:OnIntervalThink()
  local parent = self:GetParent()
  -- Remove this debuff if parent is not affected by Arena anymore
  if not parent:HasModifier("modifier_mars_arena_of_blood_leash") then
    self:StartIntervalThink(-1)
    self:Destroy()
    return
  end
end

function modifier_mars_arena_of_blood_leash_oaa:DeclareFunctions()
  return {
    --MODIFIER_PROPERTY_BONUS_DAY_VISION,
    --MODIFIER_PROPERTY_BONUS_NIGHT_VISION,
    MODIFIER_PROPERTY_BONUS_VISION_PERCENTAGE
  }
end

function modifier_mars_arena_of_blood_leash_oaa:GetBonusVisionPercentage()
  return -50
end

-- function modifier_mars_arena_of_blood_leash_oaa:GetBonusDayVision()
  -- return -550
-- end

-- function modifier_mars_arena_of_blood_leash_oaa:GetBonusNightVision()
  -- return -550
-- end

function modifier_mars_arena_of_blood_leash_oaa:CheckState()
  return {
    [MODIFIER_STATE_TETHERED] = true, -- leash
  }
end
