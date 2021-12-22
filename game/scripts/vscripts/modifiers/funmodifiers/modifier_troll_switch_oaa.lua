modifier_troll_switch_oaa = class(ModifierBaseClass)

function modifier_troll_switch_oaa:IsHidden()
  return true
end

function modifier_troll_switch_oaa:IsPurgable()
  return true
end

function modifier_troll_switch_oaa:RemoveOnDeath()
  return false
end

function modifier_troll_switch_oaa:OnCreated()
  self.atkRange = 600
  self.projectileSpeed = 900
  self.bonus_health_per_lvl = 50
  self.bonus_attack_speed_per_lvl = 10

  if not IsServer() then
    return
  end

  local parent = self:GetParent()

  -- Check if parent has Berserkers Rage,
  if parent:HasAbility("troll_warlord_berserkers_rage") then
    return
  end

  if parent:IsRangedAttacker() then
    -- Parent is ranged -> turn to melee
    parent:SetAttackCapability(DOTA_UNIT_CAP_MELEE_ATTACK)
    self.set_attack_capability = DOTA_UNIT_CAP_MELEE_ATTACK
  elseif parent:HasAttackCapability() then
    -- Parent is melee -> turn to ranged
    parent:SetAttackCapability(DOTA_UNIT_CAP_RANGED_ATTACK)
    -- Change attack projectile only if parent doesn't have Metamorphosis and Dragon Form
    if not parent:HasAbility("dragon_knight_elder_dragon_form") and not parent:HasAbility("dragon_knight_elder_dragon_form_oaa") and not parent:HasAbility("terrorblade_metamorphosis") then
	    parent:SetRangedProjectileName("particles/base_attacks/ranged_tower_good.vpcf")
    end
    self.set_attack_capability = DOTA_UNIT_CAP_RANGED_ATTACK
  else
    self.set_attack_capability = DOTA_UNIT_CAP_NO_ATTACK
  end

  self:StartIntervalThink(0)
end

function modifier_troll_switch_oaa:OnIntervalThink()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()

  -- Check if parent has True Form
  if parent:HasModifier("modifier_lone_druid_true_form") and self.set_attack_capability == DOTA_UNIT_CAP_MELEE_ATTACK and not parent:IsRangedAttacker() then
    parent:SetAttackCapability(DOTA_UNIT_CAP_RANGED_ATTACK)
    return
  end

  if self.set_attack_capability ~= parent:GetAttackCapability() and not parent:HasModifier("modifier_lone_druid_true_form") then
    parent:SetAttackCapability(self.set_attack_capability)
  end
end

function modifier_troll_switch_oaa:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
    MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS,
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
  }

  return funcs
end


function modifier_troll_switch_oaa:GetModifierAttackRangeBonus()
  if self:GetParent():IsRangedAttacker() then
    return self.atkRange
  end

  return 0
end

function modifier_troll_switch_oaa:GetModifierProjectileSpeedBonus()
  local parent = self:GetParent()
  if not IsServer() or parent:HasModifier("modifier_item_princes_knife") then
    return 0
  end

  if self.lock then
    return 0
  else
    self.lock = true
    local projectile_speed = parent:GetProjectileSpeed()
    self.lock = false
    if projectile_speed > self.projectileSpeed then
      return self.projectileSpeed - projectile_speed
    end
  end

  return 0
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
