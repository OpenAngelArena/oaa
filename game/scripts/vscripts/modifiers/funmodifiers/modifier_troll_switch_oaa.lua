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
  -- Check if parent has Berserkers Rage or True Form
  if not parent:HasAbility("troll_warlord_berserkers_rage") and not parent:HasAbility("lone_druid_true_form") then
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
  end

  self:OnIntervalThink()
  self:StartIntervalThink(1)
end

function modifier_troll_switch_oaa:OnIntervalThink()
  if not IsServer() then
    return
  end

  -- Bonus hp for melee heroes, bonus attack speed for ranged heroes
  local parent = self:GetParent()
  if parent:IsRangedAttacker() then -- IsRangedAttacker doesn't return a consistent result on the Client!
    self:SetStackCount(-2) -- negative stacks are allowed but don't appear in the UI
  else
    local attack_range = parent:GetBaseAttackRange()
    if attack_range > self.atkRange then
      self:SetStackCount(300 - attack_range)
    else
      self:SetStackCount(150 - attack_range)
    end
  end

  -- this updates the stacks so the client side range updates correctly
  -- otherwise you need to attack or a-click something/somewhere
  self:GetModifierAttackRangeBonus()

  if parent:IsHero() then
    parent:CalculateStatBonus(true)
  end
end

function modifier_troll_switch_oaa:OnDestroy()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()

  -- Check if parent has Berserkers Rage or True Form
  if not parent:HasAbility("troll_warlord_berserkers_rage") and not parent:HasAbility("lone_druid_true_form") then
    if self.original_attack_capability then
      parent:SetAttackCapability(self.original_attack_capability)
    end
  end

  if parent and parent:IsHero() then
    parent:CalculateStatBonus(true)
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

function modifier_troll_switch_oaa:GetModifierAttackRangeBonus()
  local parent = self:GetParent()
  -- Don't decrease attack range if parent has these modifiers
  if parent:HasModifier("modifier_troll_warlord_berserkers_rage") or parent:HasModifier("modifier_lone_druid_true_form") then
    return 0
  end

  -- Don't increase for Troll Warlord and Lone Druid
  if parent:GetUnitName() == "npc_dota_hero_troll_warlord" or parent:GetUnitName() == "npc_dota_hero_lone_druid" then
    return 0
  end

  if math.abs(self:GetStackCount()) == 2 then
    return self.atkRange -- increasing attack range for former melee heroes
  else
    return self:GetStackCount() -- decreasing attack range for former ranged heroes
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
  local parent = self:GetParent()
  local lvl = parent:GetLevel()
  if math.abs(self:GetStackCount()) ~= 2 then
    return self.bonus_health_per_lvl * lvl
  end

  return 0
end

function modifier_troll_switch_oaa:GetModifierAttackSpeedBonus_Constant()
  local parent = self:GetParent()
  local lvl = parent:GetLevel()
  if math.abs(self:GetStackCount()) == 2 then
    return self.bonus_attack_speed_per_lvl * lvl
  end

  return 0
end

function modifier_troll_switch_oaa:GetTexture()
  return "troll_warlord_berserkers_rage"
end
