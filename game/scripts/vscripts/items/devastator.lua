LinkLuaModifier("modifier_item_devastator_oaa_desolator", "items/devastator.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_devastator_oaa_corruption_armor", "items/devastator.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_devastator_oaa_slow_movespeed", "items/devastator.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_devastator_oaa_reduce_armor", "items/devastator.lua", LUA_MODIFIER_MOTION_NONE)

item_devastator_oaa_1 = class(ItemBaseClass)

function item_devastator_oaa_1:GetIntrinsicModifierName()
  return "modifier_item_devastator_oaa_desolator"
end

function item_devastator_oaa_1:OnSpellStart()
  local caster = self:GetCaster()
  self.devastator_speed = self:GetSpecialValueFor( "devastator_speed" )
  self.devastator_width_initial = self:GetSpecialValueFor( "devastator_width_initial" )
  self.devastator_width_end = self:GetSpecialValueFor( "devastator_width_end" )
  self.devastator_distance = self:GetSpecialValueFor( "devastator_distance" )
  self.devastator_damage = self:GetSpecialValueFor( "devastator_damage" )
  self.devastator_movespeed_reduction_duration = self:GetSpecialValueFor( "devastator_movespeed_reduction_duration" )
  self.devastator_armor_reduction_duration = self:GetSpecialValueFor( "devastator_armor_reduction_duration" )

  -- Sound
  caster:EmitSound("Item_Desolator.Target")

  local vPos
  if self:GetCursorTarget() then
    vPos = self:GetCursorTarget():GetOrigin()
  else
    vPos = self:GetCursorPosition()
  end

  local vDirection = vPos - caster:GetOrigin()
  vDirection.z = 0.0
  vDirection = vDirection:Normalized()

  self.devastator_speed = self.devastator_speed * ( self.devastator_distance / ( self.devastator_distance - self.devastator_width_initial ) )

  local info = {
    EffectName = "particles/items/devastator/devastator_active.vpcf",
    Ability = self,
    vSpawnOrigin = caster:GetOrigin(),
    fStartRadius = self.devastator_width_initial,
    fEndRadius = self.devastator_width_end,
    vVelocity = vDirection * self.devastator_speed,
    fDistance = self.devastator_distance + caster:GetCastRangeBonus(),
    Source = caster,
    iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
    iUnitTargetType = bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
    iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
    --bReplaceExisting = false,
    --bDeleteOnHit = false,
    --bProvidesVision = false,
  }

  ProjectileManager:CreateLinearProjectile( info )
end

-- Impact of the projectile
function item_devastator_oaa_1:OnProjectileHit( hTarget, vLocation )
  if hTarget ~= nil  and ( not hTarget:IsInvulnerable() ) and ( not hTarget:IsAttackImmune() ) then
    local caster = self:GetCaster()
    local armor_reduction_duration = hTarget:GetValueChangedByStatusResistance(self.devastator_armor_reduction_duration)

    -- Apply the slow debuff always
    hTarget:AddNewModifier( caster, self, "modifier_item_devastator_oaa_slow_movespeed", { duration = self.devastator_movespeed_reduction_duration } )

    -- Armor reduction values
    local armor_reduction = self:GetSpecialValueFor( "devastator_armor_reduction" )
    local corruption_armor = self:GetSpecialValueFor( "corruption_armor" )

    -- If the target has Desolator debuff then remove it
    if hTarget:HasModifier("modifier_desolator_buff") then
      hTarget:RemoveModifierByName("modifier_desolator_buff")
    end

    -- if the target has Devastator passive armor reduction debuff then check which armor reduction is better
    if hTarget:HasModifier("modifier_item_devastator_oaa_corruption_armor") then
      -- If active armor reduction is better than passive then remove Devastator passive armor reduction debuff
      -- and apply Devastator active armor reduction debuff
      if math.abs(armor_reduction) > math.abs(corruption_armor) then
        hTarget:RemoveModifierByName("modifier_item_devastator_oaa_corruption_armor")
        hTarget:AddNewModifier( caster, self, "modifier_item_devastator_oaa_reduce_armor", { duration = armor_reduction_duration } )
      end
    else
      -- Apply the Devastator active armor reduction debuff if Devastator passive armor reduction debuff is not there
      hTarget:AddNewModifier( caster, self, "modifier_item_devastator_oaa_reduce_armor", { duration = armor_reduction_duration } )
    end

    -- Damage part should always be applied
    local damage_table = {
      victim = hTarget,
      attacker = caster,
      damage = self.devastator_damage,
      damage_type = DAMAGE_TYPE_PHYSICAL,
      damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_BLOCK,
      ability = self
    }

    ApplyDamage(damage_table)

    caster:PerformAttack(hTarget, true, true, true, false, false, false, true)

    -- Particles
    local vDirection = vLocation - caster:GetOrigin()
    vDirection.z = 0.0
    vDirection = vDirection:Normalized()
    -- Replace with the particles for the item
    local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_lina/lina_spell_dragon_slave_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
    ParticleManager:SetParticleControlForward( nFXIndex, 1, vDirection )
    ParticleManager:ReleaseParticleIndex( nFXIndex )
  end
  return false
end

item_devastator_oaa_2 = item_devastator_oaa_1
item_devastator_oaa_3 = item_devastator_oaa_1
item_devastator_oaa_4 = item_devastator_oaa_1
item_devastator_oaa_5 = item_devastator_oaa_1

---------------------------------------------------------------------------------------------------

modifier_item_devastator_oaa_desolator = class(ModifierBaseClass)

function modifier_item_devastator_oaa_desolator:IsHidden()
  return true
end

function modifier_item_devastator_oaa_desolator:IsDebuff()
  return false
end

function modifier_item_devastator_oaa_desolator:IsPurgable()
  return false
end

function modifier_item_devastator_oaa_desolator:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_devastator_oaa_desolator:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_damage = ability:GetSpecialValueFor("bonus_damage")
  end

  if IsServer() then
    self:GetParent():ChangeAttackProjectile()
  end
end

modifier_item_devastator_oaa_desolator.OnRefresh = modifier_item_devastator_oaa_desolator.OnCreated

function modifier_item_devastator_oaa_desolator:OnDestroy()
  local parent = self:GetParent()
  if IsServer() and parent and not parent:IsNull() then
    parent:ChangeAttackProjectile()
  end
end

function modifier_item_devastator_oaa_desolator:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE
  }
end

function modifier_item_devastator_oaa_desolator:GetModifierPreAttack_BonusDamage()
  return self.bonus_damage or self:GetAbility():GetSpecialValueFor("bonus_damage")
end

if IsServer() then
  function modifier_item_devastator_oaa_desolator:OnAttackLanded(event)
    if not self:IsFirstItemInInventory() then
      return
    end

    local parent = self:GetParent()
    local ability = self:GetAbility()
    local target = event.target

    if parent ~= event.attacker then
      return
    end

    if parent:IsIllusion() then
      return
    end

    -- To prevent crashes:
    if not target or target:IsNull() then
      return
    end

    -- Check for existence of GetUnitName method to determine if target is a unit or an item (or rune)
    -- items don't have that method -> nil; if the target is an item, don't continue
    if target.GetUnitName == nil then
      return
    end

    -- Doesn't work on allies
    if target:GetTeamNumber() == parent:GetTeamNumber() then
      return
    end

    -- If the target has desolator debuff then remove it (to prevent stacking armor reductions)
    if target:HasModifier("modifier_desolator_buff") then
      target:RemoveModifierByName("modifier_desolator_buff")
    end

    local armor_reduction = ability:GetSpecialValueFor( "devastator_armor_reduction" )
    local corruption_armor = ability:GetSpecialValueFor( "corruption_armor" )

    -- If the target has Devastator active debuff
    if target:HasModifier("modifier_item_devastator_oaa_reduce_armor") then
      -- If devastator_armor_reduction (active armor reduction) is higher than corruption_armor (passive armor reduction) then do nothing
      if math.abs(armor_reduction) > math.abs(corruption_armor) then
        return
      end
      -- If devastator_armor_reduction is lower than corruption_armor then remove the Devastator active debuff
      target:RemoveModifierByName("modifier_item_devastator_oaa_reduce_armor")
    end

    -- Calculate duration of the debuff
    local corruption_duration = ability:GetSpecialValueFor("corruption_duration")
    -- Calculate duration while keeping status resistance in mind
    local armor_reduction_duration = target:GetValueChangedByStatusResistance(corruption_duration)
    -- Apply Devastator passive debuff
    target:AddNewModifier( parent, ability, "modifier_item_devastator_oaa_corruption_armor", {duration = armor_reduction_duration})
  end
end

---------------------------------------------------------------------------------------------------

modifier_item_devastator_oaa_corruption_armor = class(ModifierBaseClass)

function modifier_item_devastator_oaa_corruption_armor:IsHidden()
  return false
end

function modifier_item_devastator_oaa_corruption_armor:IsDebuff()
  return true
end

function modifier_item_devastator_oaa_corruption_armor:IsPurgable()
  return true
end

function modifier_item_devastator_oaa_corruption_armor:OnCreated()
  if IsServer() then
    self:StartIntervalThink(0.1)
  end
end

function modifier_item_devastator_oaa_corruption_armor:OnIntervalThink()
  local parent = self:GetParent()

  if parent:HasModifier("modifier_desolator_buff") then
    parent:RemoveModifierByName("modifier_desolator_buff")
    --self:StartIntervalThink(-1)
    --self:SetDuration(0.01, false)
  end
end

function modifier_item_devastator_oaa_corruption_armor:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
  }
end

function modifier_item_devastator_oaa_corruption_armor:GetModifierPhysicalArmorBonus()
  return self:GetAbility():GetSpecialValueFor("corruption_armor")
end

function modifier_item_devastator_oaa_corruption_armor:GetTexture()
  return "item_desolator"
end

---------------------------------------------------------------------------------------------------

modifier_item_devastator_oaa_slow_movespeed = class(ModifierBaseClass)

function modifier_item_devastator_oaa_slow_movespeed:IsHidden()
  return false
end

function modifier_item_devastator_oaa_slow_movespeed:IsDebuff()
  return true
end

function modifier_item_devastator_oaa_slow_movespeed:IsPurgable()
  return true
end

function modifier_item_devastator_oaa_slow_movespeed:OnCreated()
  --local parent = self:GetParent()
  local ability = self:GetAbility()
  local move_speed_slow = -10
  local interval = 3
  local damage_per_interval = 50

  if ability then
    move_speed_slow = ability:GetSpecialValueFor("devastator_movespeed_reduction")
    interval = ability:GetSpecialValueFor("interval")
    damage_per_interval = ability:GetSpecialValueFor("damage_per_interval")
  end

  self.damage_per_interval = damage_per_interval

  -- Move Speed Slow is reduced with Slow Resistance
  self.slow = move_speed_slow --parent:GetValueChangedBySlowResistance(move_speed_slow)

  -- Start DoT
  if IsServer() then
    self:StartIntervalThink(interval)
  end
end

modifier_item_devastator_oaa_slow_movespeed.OnRefresh = modifier_item_devastator_oaa_slow_movespeed.OnCreated

function modifier_item_devastator_oaa_slow_movespeed:OnIntervalThink()
  if IsServer() then
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    local damage_table = {
      victim = parent,
      attacker = caster,
      damage = self.damage_per_interval,
      damage_type = DAMAGE_TYPE_PURE,
      ability = ability,
    }

    ApplyDamage(damage_table)
  end
end

function modifier_item_devastator_oaa_slow_movespeed:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
  }
end

function modifier_item_devastator_oaa_slow_movespeed:GetModifierMoveSpeedBonus_Percentage()
  return 0 - math.abs(self.slow)
end

function modifier_item_devastator_oaa_slow_movespeed:GetTexture()
  return "custom/devastator_1"
end

---------------------------------------------------------------------------------------------------

modifier_item_devastator_oaa_reduce_armor = class(ModifierBaseClass)

function modifier_item_devastator_oaa_reduce_armor:IsHidden()
  return false
end

function modifier_item_devastator_oaa_reduce_armor:IsDebuff()
  return true
end

function modifier_item_devastator_oaa_reduce_armor:IsPurgable()
  return true
end

function modifier_item_devastator_oaa_reduce_armor:OnCreated()
  if IsServer() then
    self:StartIntervalThink(0.1)
  end
end

function modifier_item_devastator_oaa_reduce_armor:OnIntervalThink()
  local parent = self:GetParent()
  -- We assume that devastator active has a better armor reduction than the desolator armor reduction
  -- Remove the desolator debuff to prevent stacking armor reductions
  if parent:HasModifier("modifier_desolator_buff") then
    parent:RemoveModifierByName("modifier_desolator_buff")
  end
end

function modifier_item_devastator_oaa_reduce_armor:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
  }
end

function modifier_item_devastator_oaa_reduce_armor:GetModifierPhysicalArmorBonus()
  return self:GetAbility():GetSpecialValueFor("devastator_armor_reduction")
end

function modifier_item_devastator_oaa_reduce_armor:GetTexture()
  return "custom/devastator_1"
end
