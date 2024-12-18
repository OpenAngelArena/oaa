LinkLuaModifier( "modifier_item_shade_staff_passive", "items/shade_staff.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_shade_staff_trees_buff", "items/shade_staff.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_shade_staff_trees_debuff", "items/shade_staff.lua", LUA_MODIFIER_MOTION_NONE )

item_shade_staff_1 = class(ItemBaseClass)

function item_shade_staff_1:GetIntrinsicModifierName()
  return "modifier_item_shade_staff_passive"
end

function item_shade_staff_1:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()

  local tree_buff_duration = self:GetSpecialValueFor("tree_protection_duration")

  if target:GetTeamNumber() == caster:GetTeamNumber() then
    if target ~= caster then
      -- Apply Tree Protection buff to the ally (don't apply when self-cast because the caster already has it)
      target:AddNewModifier(caster, self, "modifier_item_shade_staff_trees_buff", {duration = tree_buff_duration})
    end

    -- Create trees around the target
    self:Sprout(target)
  else

    -- Create the projectile
    local info = {
      Target = target,
      Source = caster,
      Ability = self,
      EffectName = "particles/units/heroes/hero_abaddon/abaddon_death_coil.vpcf",
      bDodgeable = true,
      bProvidesVision = true,
      bVisibleToEnemies = true,
      bReplaceExisting = false,
      iMoveSpeed = self:GetSpecialValueFor("projectile_speed"),
      iVisionRadius = 250,
      iVisionTeamNumber = caster:GetTeamNumber(),
    }

    ProjectileManager:CreateTrackingProjectile(info)
  end
end

function item_shade_staff_1:Sprout(target)
  local caster = self:GetCaster()
  local duration = self:GetSpecialValueFor("sprout_duration")
  local target_loc = target:GetAbsOrigin()
  --local team = caster:GetTeamNumber()

  -- Create an invisible dummy/thinker
  --local dummy = CreateUnitByName("npc_dota_custom_dummy_unit", target_loc, false, caster, caster, team)
  --dummy:AddNewModifier(caster, self, "modifier_oaa_thinker", {})
  --dummy:AddNewModifier(caster, self, "modifier_kill", {duration = duration})
  --dummy:AddNewModifier(caster, self, "modifier_generic_dead_tracker_oaa", {duration = duration + MANUAL_GARBAGE_CLEANING_TIME})

  local r = 150
  local c = math.sqrt(2) * 0.5 * r
  local x_offset = { -r, -c, 0.0, c, r, c, 0.0, -c }
  local y_offset = { 0.0, c, r, c, 0.0, -c, -r, -c }

  -- Create trees
  for i = 1, 8 do
    CreateTempTree(target_loc + Vector(x_offset[i], y_offset[i], 0.0), duration)
  end

  -- Unstuck entities
  for i = 1, 8 do
    ResolveNPCPositions(target_loc + Vector(x_offset[i], y_offset[i], 0.0), 64.0)
  end

  -- Sound
  EmitSoundOnLocationWithCaster(target_loc, "Hero_Furion.Sprout", caster)
end

function item_shade_staff_1:OnProjectileHit(target, location)
  local caster = self:GetCaster()

  if not target or target:IsNull() then
    return
  end

  -- Don't do anything if target has Linken's effect or it's spell-immune
  if target:TriggerSpellAbsorb(self) or target:IsMagicImmune() then
    return
  end

  local debuff_duration = self:GetSpecialValueFor("slow_duration")
  -- Ignore status resistance
  target:AddNewModifier(caster, self, "modifier_item_shade_staff_trees_debuff", {duration = debuff_duration})

  self:Sprout(target)
end

item_shade_staff_2 = item_shade_staff_1
item_shade_staff_3 = item_shade_staff_1
item_shade_staff_4 = item_shade_staff_1

---------------------------------------------------------------------------------------------------

modifier_item_shade_staff_passive = class(ModifierBaseClass)

function modifier_item_shade_staff_passive:IsHidden()
  return true
end

function modifier_item_shade_staff_passive:IsDebuff()
  return false
end

function modifier_item_shade_staff_passive:IsPurgable()
  return false
end

-- function modifier_item_shade_staff_passive:GetAttributes()
  -- return MODIFIER_ATTRIBUTE_MULTIPLE
-- end

function modifier_item_shade_staff_passive:OnCreated()
  self:OnRefresh()
  if IsServer() then
    self:StartIntervalThink(0.1)
  end
end

function modifier_item_shade_staff_passive:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_str = ability:GetSpecialValueFor("bonus_str")
    -- Stuff active only near trees:
    self.dmg_reduction = ability:GetSpecialValueFor("tree_damage_reduction")
    self.tree_radius = ability:GetSpecialValueFor("tree_radius")
  end
end

if IsServer() then
  function modifier_item_shade_staff_passive:OnIntervalThink()
    local parent = self:GetParent()

    if not parent or parent:IsNull() then
      self:StartIntervalThink(-1)
      return
    end

    -- Ignore illusions
    if parent:IsIllusion() then
      self:StartIntervalThink(-1) -- dynamic illusions still don't exist, so we can stop thinking
      self:SetStackCount(0) -- don't grant tree stats
      return
    end

    -- Ignore Meepo clones
    if parent:IsClone() then
      self:StartIntervalThink(-1) -- dynamic clones still don't exist, so we can stop thinking
      self:SetStackCount(0) -- don't grant tree stats
      return
    end

    -- Ignore banished units
    if parent:IsOutOfGame() then
      self:SetStackCount(0) -- don't grant tree stats
      return
    end

    local parent_origin = parent:GetAbsOrigin()
    -- Check if tree is nearby
    if self.tree_radius and GridNav:IsNearbyTree(parent_origin, self.tree_radius, true) then
      self:SetStackCount(1) -- grant tree stats
    else
      self:SetStackCount(0) -- don't grant tree stats
    end
  end
end

function modifier_item_shade_staff_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, -- GetModifierBonusStats_Strength
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE, -- GetModifierIncomingDamage_Percentage
  }
end

function modifier_item_shade_staff_passive:GetModifierBonusStats_Strength()
  return self.bonus_str or self:GetAbility():GetSpecialValueFor("bonus_str")
end

function modifier_item_shade_staff_passive:GetModifierIncomingDamage_Percentage() -- Tree Damage Reduction
  if self:GetStackCount() ~= 1 then
    return 0
  end

  return self.dmg_reduction or self:GetAbility():GetSpecialValueFor("tree_damage_reduction")
end

function modifier_item_shade_staff_passive:CheckState()
  return {
    [MODIFIER_STATE_ALLOW_PATHING_THROUGH_TREES] = true, -- Tree-Walking
  }
end

---------------------------------------------------------------------------------------------------

modifier_item_shade_staff_trees_buff = class(ModifierBaseClass)

function modifier_item_shade_staff_trees_buff:IsHidden()
  return false
end

function modifier_item_shade_staff_trees_buff:IsDebuff()
  return false
end

function modifier_item_shade_staff_trees_buff:IsPurgable()
  return true
end

function modifier_item_shade_staff_trees_buff:OnCreated()
  self:OnRefresh()
  if IsServer() then
    self:StartIntervalThink(0.1)
  end
end

function modifier_item_shade_staff_trees_buff:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.dmg_reduction = ability:GetSpecialValueFor("tree_damage_reduction")
    self.tree_radius = ability:GetSpecialValueFor("tree_radius")
  end
end

if IsServer() then
  function modifier_item_shade_staff_trees_buff:OnIntervalThink()
    local parent = self:GetParent()

    if not parent or parent:IsNull() then
      self:StartIntervalThink(-1)
      return
    end

    -- Ignore banished units and units that have passive Tree Protection
    if parent:IsOutOfGame() or parent:HasModifier("modifier_item_shade_staff_passive") then
      self:SetStackCount(0) -- don't grant tree stats
      return
    end

    local parent_origin = parent:GetAbsOrigin()
    -- Check if tree is nearby
    if self.tree_radius and GridNav:IsNearbyTree(parent_origin, self.tree_radius, true) then
      self:SetStackCount(1) -- grant tree stats
    else
      self:SetStackCount(0) -- don't grant tree stats
    end
  end
end

function modifier_item_shade_staff_trees_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
  }
end

function modifier_item_shade_staff_trees_buff:GetModifierIncomingDamage_Percentage()
  if self:GetStackCount() ~= 1 or self:GetParent():HasModifier("modifier_item_shade_staff_passive") then
    return 0
  end

  return self.dmg_reduction
end

-- Flying Vision because Tree-vision needs wizardry
function modifier_item_shade_staff_trees_buff:CheckState()
  return {
    [MODIFIER_STATE_FORCED_FLYING_VISION] = true,
  }
end

---------------------------------------------------------------------------------------------------

modifier_item_shade_staff_trees_debuff = class(ModifierBaseClass)

function modifier_item_shade_staff_trees_debuff:IsHidden()
  return false
end

function modifier_item_shade_staff_trees_debuff:IsDebuff()
  return true
end

function modifier_item_shade_staff_trees_debuff:IsPurgable()
  return false
end

function modifier_item_shade_staff_trees_debuff:OnCreated()
  self:OnRefresh()
  if IsServer() then
    self:StartIntervalThink(0.1)
  end
end

function modifier_item_shade_staff_trees_debuff:OnRefresh()
  local parent = self:GetParent()
  local ability = self:GetAbility()
  local attack_slow = 350

  if ability and not ability:IsNull() then
    attack_slow = ability:GetSpecialValueFor("attack_speed_slow")
    self.tree_radius = ability:GetSpecialValueFor("tree_radius")
  end

  if parent:IsOAABoss() then
    attack_slow = 0
  end

  self.attack_slow = attack_slow
end

if IsServer() then
  function modifier_item_shade_staff_trees_debuff:OnIntervalThink()
    local parent = self:GetParent()

    if not parent or parent:IsNull() then
      self:StartIntervalThink(-1)
      return
    end

    if parent:IsOAABoss() then
      self:StartIntervalThink(-1)
      self:Destroy()
      return
    end

    local parent_origin = parent:GetAbsOrigin()
    -- Check if tree is nearby
    if self.tree_radius and GridNav:IsNearbyTree(parent_origin, self.tree_radius, true) then
      self:SetStackCount(1) -- slow attack speed
    else
      self:SetStackCount(0) -- don't slow attack speed
    end
  end
end

function modifier_item_shade_staff_trees_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
  }
end

function modifier_item_shade_staff_trees_debuff:GetModifierAttackSpeedBonus_Constant()
  if self:GetStackCount() ~= 1 then
    return 0
  end

  return 0 - math.abs(self.attack_slow)
end

function modifier_item_shade_staff_trees_debuff:GetModifierProvidesFOWVision()
  return 1
end

function modifier_item_shade_staff_trees_debuff:CheckState()
  return {
    [MODIFIER_STATE_PROVIDES_VISION] = true,
  }
end

function modifier_item_shade_staff_trees_debuff:GetEffectName()
  return "particles/units/heroes/hero_enchantress/enchantress_untouchable.vpcf"
end

function modifier_item_shade_staff_trees_debuff:GetEffectAttachType()
  return PATTACH_OVERHEAD_FOLLOW
end
