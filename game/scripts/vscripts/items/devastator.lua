LinkLuaModifier("modifier_item_devastator_desolator", "modifiers/modifier_item_devastator_desolator.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_devastator_corruption_armor", "modifiers/modifier_item_devastator_corruption_armor.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_devastator_slow_movespeed", "modifiers/modifier_item_devastator_slow_movespeed.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_devastator_reduce_armor", "modifiers/modifier_item_devastator_reduce_armor.lua", LUA_MODIFIER_MOTION_NONE)

item_devastator_1 = class(ItemBaseClass)

function item_devastator_1:GetIntrinsicModifierName()
  return "modifier_item_devastator_desolator"
end

function item_devastator_1:OnSpellStart()
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
function item_devastator_1:OnProjectileHit( hTarget, vLocation )
  if hTarget ~= nil  and ( not hTarget:IsInvulnerable() ) and ( not hTarget:IsAttackImmune() ) then
    local armor_reduction_duration = hTarget:GetValueChangedByStatusResistance(self.devastator_armor_reduction_duration)

    -- Apply the slow debuff always
    hTarget:AddNewModifier( hTarget, self, "modifier_item_devastator_slow_movespeed", { duration = self.devastator_movespeed_reduction_duration } )

    -- Armor reduction values
    local armor_reduction = self:GetSpecialValueFor( "devastator_armor_reduction" )
    local corruption_armor = self:GetSpecialValueFor( "corruption_armor" )

    -- If the target has Desolator debuff then remove it
    if hTarget:HasModifier("modifier_desolator_buff") then
      hTarget:RemoveModifierByName("modifier_desolator_buff")
    end

    -- if the target has Devastator passive armor reduction debuff then check which armor reduction is better
    if hTarget:HasModifier("modifier_item_devastator_corruption_armor") then
      -- If active armor reduction is better than passive then remove Devastator passive armor reduction debuff
      -- and apply Devastator active armor reduction debuff
      if math.abs(armor_reduction) > math.abs(corruption_armor) then
        hTarget:RemoveModifierByName("modifier_item_devastator_corruption_armor")
        hTarget:AddNewModifier( hTarget, self, "modifier_item_devastator_reduce_armor", { duration = armor_reduction_duration } )
      end
    else
      -- Apply the Devastator active armor reduction debuff if Devastator passive armor reduction debuff is not there
      hTarget:AddNewModifier( hTarget, self, "modifier_item_devastator_reduce_armor", { duration = armor_reduction_duration } )
    end

    -- Damage part should always be applied
    local damage = {
      victim = hTarget,
      attacker = self:GetCaster(),
      damage = self.devastator_damage,
      damage_type = DAMAGE_TYPE_PHYSICAL,
      damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_BLOCK,
      ability = self
    }

    ApplyDamage( damage )
    self:GetCaster():PerformAttack(hTarget, true, true, true, false, false, false, true)

    -- Particles
    local vDirection = vLocation - self:GetCaster():GetOrigin()
    vDirection.z = 0.0
    vDirection = vDirection:Normalized()
    -- Replace with the particles for the item
    local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_lina/lina_spell_dragon_slave_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, hTarget )
    ParticleManager:SetParticleControlForward( nFXIndex, 1, vDirection )
    ParticleManager:ReleaseParticleIndex( nFXIndex )
  end
  return false
end

item_devastator_2 = item_devastator_1
item_devastator_3 = item_devastator_1
item_devastator_4 = item_devastator_1
item_devastator_5 = item_devastator_1
