-- Attack Range Switch

modifier_troll_switch_oaa = class(ModifierBaseClass)

function modifier_troll_switch_oaa:IsHidden()
  return false
end

function modifier_troll_switch_oaa:IsDebuff()
  return false
end

function modifier_troll_switch_oaa:IsPurgable()
  return false
end

function modifier_troll_switch_oaa:RemoveOnDeath()
  return false
end

function modifier_troll_switch_oaa:OnCreated()
  self.atkRange = 500
  self.projectileSpeed = 1100
  self.bonus_health_per_lvl = 50
  self.bonus_attack_speed_per_lvl = 5

  if not IsServer() then
    return
  end

  local parent = self:GetParent()

  -- Check if parent has Berserkers Rage
  if parent:HasAbility("troll_warlord_berserkers_rage") then
    return
  end

  if parent:IsRangedAttacker() then
    -- Parent is ranged -> turn to melee
    parent:SetAttackCapability(DOTA_UNIT_CAP_MELEE_ATTACK)
    self.set_attack_capability = DOTA_UNIT_CAP_MELEE_ATTACK
    self.original_attack_capability = DOTA_UNIT_CAP_RANGED_ATTACK
  elseif parent:HasAttackCapability() then
    -- Parent is melee -> turn to ranged
    parent:SetAttackCapability(DOTA_UNIT_CAP_RANGED_ATTACK)
    -- Change attack projectile only if parent doesn't have Metamorphosis and Dragon Form
    if parent:HasAbility("dragon_knight_elder_dragon_form") and parent:HasAbility("dragon_knight_elder_dragon_form_oaa") then
      parent:SetRangedProjectileName("particles/units/heroes/hero_dragon_knight/dragon_knight_elder_dragon_fire.vpcf")
    elseif parent:HasAbility("terrorblade_metamorphosis") then
      parent:SetRangedProjectileName("particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis_base_attack.vpcf")
    else
      parent:SetRangedProjectileName("particles/base_attacks/ranged_tower_good.vpcf")
    end
    self.set_attack_capability = DOTA_UNIT_CAP_RANGED_ATTACK
    self.original_attack_capability = DOTA_UNIT_CAP_MELEE_ATTACK
  else
    self.set_attack_capability = DOTA_UNIT_CAP_NO_ATTACK
  end

  self:StartIntervalThink(1)
end

function modifier_troll_switch_oaa:OnIntervalThink()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  local hasTrueForm = parent:HasModifier("modifier_lone_druid_true_form")

  -- Check if parent has True Form
  if hasTrueForm and self.set_attack_capability == DOTA_UNIT_CAP_MELEE_ATTACK and not parent:IsRangedAttacker() then
    parent:SetAttackCapability(DOTA_UNIT_CAP_RANGED_ATTACK)
    -- this updates the stacks so the client side range updates correctly
    -- otherwise you need to attack or a-click something/somewhere
    self:GetModifierAttackRangeBonus()
    return
  end

  if self.set_attack_capability ~= parent:GetAttackCapability() and not hasTrueForm then
    parent:SetAttackCapability(self.set_attack_capability)
    -- this updates the stacks so the client side range updates correctly
    -- otherwise you need to attack or a-click something/somewhere
    self:GetModifierAttackRangeBonus()
  end
end

function modifier_troll_switch_oaa:OnDestroy()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()

  -- Check if parent has Berserkers Rage
  if parent:HasAbility("troll_warlord_berserkers_rage") then
    return
  end

  if self.original_attack_capability then
    parent:SetAttackCapability(self.original_attack_capability)
  end
end

function modifier_troll_switch_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
    MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS,
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
  }
end

-- offset all stack counts by -500
-- the max stack count we'll ever have is 500, so this makes the max 0
-- negative stacks are allowed but don't appear in the UI, so this makes things clearer
local RangeBufferOffset = 0 - 500

function modifier_troll_switch_oaa:GetModifierAttackRangeBonus()
  local currentStackCount = self:GetStackCount()
  -- client side doesn't know we swapped their stuff
  if not IsServer() then
    return currentStackCount - RangeBufferOffset
    -- return 0
    -- isRangedHero = not isRangedHero
  end

  local parent = self:GetParent()
  local isRangedHero = parent:IsRangedAttacker()

  local function setCurrentBonus(range)
    if currentStackCount - RangeBufferOffset ~= range then
      self:SetStackCount(range + RangeBufferOffset)
    end
    return range
  end

  if parent:HasAbility("troll_warlord_berserkers_rage") then
    return setCurrentBonus(0)
  end

  -- if we used to be melee but now we're ranged, add exactly 500 range
  if isRangedHero then
    return setCurrentBonus(self.atkRange)

  -- if we used to be ranged, we set our base range to either 300 or 150 depending on if the original hero had over 500 attack range base
  else
    local attack_range = parent:GetBaseAttackRange()
    if attack_range > self.atkRange then
      return setCurrentBonus(300 - attack_range)
    else
      return setCurrentBonus(150 - attack_range)
    end
  end
end

if IsServer() then
  function modifier_troll_switch_oaa:GetModifierProjectileSpeedBonus()
    local parent = self:GetParent()
    if parent:HasModifier("modifier_item_princes_knife") then
      return 0
    end

    if self.ps_lock then
      return 0
    else
      self.ps_lock = true
      local projectile_speed = parent:GetProjectileSpeed()
      self.ps_lock = false
      if projectile_speed <= self.projectileSpeed then
        return self.projectileSpeed - projectile_speed
      --elseif projectile_speed > self.projectileSpeed then
        --return self.projectileSpeed - projectile_speed
      end
    end

    return 0
  end
end

function modifier_troll_switch_oaa:GetModifierHealthBonus()
  -- Bonus hp for melee heroes
  local parent = self:GetParent()
  if not parent:IsRangedAttacker() then
    return self.bonus_health_per_lvl * parent:GetLevel()
  end

  return 0
end

function modifier_troll_switch_oaa:GetModifierAttackSpeedBonus_Constant()
  -- Bonus attack speed for ranged heroes
  local parent = self:GetParent()
  if parent:IsRangedAttacker() then
    return self.bonus_attack_speed_per_lvl * parent:GetLevel()
  end

  return 0
end

function modifier_troll_switch_oaa:GetTexture()
  return "troll_warlord_berserkers_rage"
end
