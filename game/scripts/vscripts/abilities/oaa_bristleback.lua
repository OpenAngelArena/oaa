--[[
Author: Ragnar Homsar
Date: July 10, 2015

Gets the angle at which Bristleback is facing a unit that damages him, then applies "damage reduction" (in actuality: healing him for the appropriate percentage) based on the resulting angle.

It's important to note something about angles in Dota:

Pretend the upcoming O is a unit, and -----> is the angle they are facing.

O---->
This is a 0 degree rotation as far as Dota is concerned.

^
|
|
O
This is a 90 degree rotation.

<-----O
This is a 180 degree rotation.

O
|
|
V
This is a -90 degree rotation.

Therefore, when dealing with angles in Dota, I prefer to just add 180 to whatever degree value you're working with; that way, you go from dealing with positive and negative angles to just angles that increment clockwise from 3 o'clock.

2017-06-08: Adapted to work in OAA by Chronophylos
]]

LinkLuaModifier("modifier_bristleback_oaa", "abilities/oaa_bristleback.lua", LUA_MODIFIER_MOTION_NONE)

bristleback_bristleback_oaa = class(AbilityBaseClass)

function bristleback_bristleback_oaa:GetIntrinsicModifierName()
  return "modifier_bristleback_oaa"
end

function bristleback_bristleback_oaa:ShouldUseResources()
  return true
end

function bristleback_bristleback_oaa:IsStealable()
  return false
end

function bristleback_bristleback_oaa:ProcMagicStick()
  return false
end

-- Lazy 'hack' to make scepter effect work
function bristleback_bristleback_oaa:OnHeroCalculateStatBonus()
  local caster = self:GetCaster()
  local scepter_bristleback = caster:FindAbilityByName("bristleback_scepter_oaa")
  if not scepter_bristleback then
    return
  end
  if caster:HasScepter() then
	scepter_bristleback:SetHidden(false)
    if scepter_bristleback:GetLevel() <= 0 then
      scepter_bristleback:SetLevel(1)
    end
  else
    scepter_bristleback:SetHidden(true)
  end
end

---------------------------------------------------------------------------------------------------

modifier_bristleback_oaa = class(ModifierBaseClass)

function modifier_bristleback_oaa:IsHidden()
  return true
end

function modifier_bristleback_oaa:IsDebuff()
  return false
end

function modifier_bristleback_oaa:IsPurgable()
  return false
end

function modifier_bristleback_oaa:RemoveOnDeath()
  return false
end

function modifier_bristleback_oaa:OnCreated()
  local parent = self:GetParent()

  if not parent.quill_threshold_counter_oaa and not parent:IsIllusion() then
    parent.quill_threshold_counter_oaa = 0
  end
end

modifier_bristleback_oaa.OnRefresh = modifier_bristleback_oaa.OnCreated

function modifier_bristleback_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK
  }
end

function modifier_bristleback_oaa:GetModifierTotal_ConstantBlock(keys)
  local ability = self:GetAbility()
  local parent = self:GetParent()

  if parent:PassivesDisabled() or (not ability) or ability:IsNull() then
    return 0
  end

  -- Do nothing if damage has HP removal flag
  if bit.band(keys.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then
    return 0
  end

  -- Do nothing if damage has Reflection flag
  if bit.band(keys.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) == DOTA_DAMAGE_FLAG_REFLECTION then
    return 0
  end

  local attacker = keys.attacker
  --local damage_before_reductions = keys.original_damage
  local damage_after_reductions = keys.damage

  local back_reduction_percentage = ability:GetLevelSpecialValueFor("back_damage_reduction", ability:GetLevel() - 1) / 100
  local side_reduction_percentage = ability:GetLevelSpecialValueFor("side_damage_reduction", ability:GetLevel() - 1) / 100

  -- If talent doesn't work automatically, fix it here

  -- Particles and Sound
  local back_particle = "particles/units/heroes/hero_bristleback/bristleback_back_dmg.vpcf"
  local side_particle = "particles/units/heroes/hero_bristleback/bristleback_side_dmg.vpcf"
  local sound = "Hero_Bristleback.Bristleback"

  -- The y value of the angles vector contains the angle we actually want: where units are directionally facing in the world.
  local victim_angle = parent:GetAnglesAsVector().y
  local origin_difference = parent:GetAbsOrigin() - attacker:GetAbsOrigin()
  -- Get the radian of the origin difference between the attacker and Bristleback. We use this to figure out at what angle the attacker is at relative to Bristleback.
  local origin_difference_radian = math.atan2(origin_difference.y, origin_difference.x)
  -- Convert the radian to degrees.
  origin_difference_radian = origin_difference_radian * 180
  local attacker_angle = origin_difference_radian / math.pi
  -- See the opening block comment for why I do this. Basically it's to turn negative angles into positive ones and make the math simpler.
  attacker_angle = attacker_angle + 180.0
  -- Finally, get the angle at which Bristleback is facing the attacker.
  local result_angle = attacker_angle - victim_angle
  result_angle = math.abs(result_angle)

  local blocked_damage = 0

  -- Check for the side angle first. If the attack doesn't pass this check, we don't have to do back angle calculations.
  if result_angle >= (180 - (ability:GetSpecialValueFor("side_angle") / 2)) and result_angle <= (180 + (ability:GetSpecialValueFor("side_angle") / 2)) then
    -- Check for back angle. If this check doesn't pass, then do side angle "damage reduction".
    if result_angle >= (180 - (ability:GetSpecialValueFor("back_angle") / 2)) and result_angle <= (180 + (ability:GetSpecialValueFor("back_angle") / 2)) then
        -- Create the back particle effect.
        local back_damage_particle = ParticleManager:CreateParticle(back_particle, PATTACH_ABSORIGIN_FOLLOW, parent)
        -- Set Control Point 1 for the back damage particle; this controls where it's positioned in the world. In this case, it should be positioned on Bristleback.
        ParticleManager:SetParticleControlEnt(back_damage_particle, 1, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
        ParticleManager:ReleaseParticleIndex(back_damage_particle)
        -- Calculate blocked damage
        blocked_damage = damage_after_reductions * back_reduction_percentage
        -- Play the sound on Bristleback.
        parent:EmitSound(sound)

        if not parent:IsIllusion() then
          -- Increase the Quill Spray damage counter
          parent.quill_threshold_counter_oaa = parent.quill_threshold_counter_oaa + damage_after_reductions - blocked_damage
        end
    else
        -- Create the side particle effect.
        local side_damage_particle = ParticleManager:CreateParticle(side_particle, PATTACH_ABSORIGIN_FOLLOW, parent)
        -- Set Control Point 1 for the side damage particle; same stuff as the back damage particle.
        ParticleManager:SetParticleControlEnt(side_damage_particle, 1, parent, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
        ParticleManager:SetParticleControlEnt(side_damage_particle, 2, parent, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", Vector(0, result_angle, 0), true)
        ParticleManager:ReleaseParticleIndex(side_damage_particle)
        -- Calculate blocked damage
        blocked_damage = damage_after_reductions * side_reduction_percentage
    end
  end

  -- Don't release Quill Sprays on illusions
  if not parent:IsIllusion() then
    -- Check for Quill Spray ability
    local quill_spray_ability = parent:FindAbilityByName("bristleback_quill_spray")
    if quill_spray_ability and quill_spray_ability:GetLevel() ~= 0 then
      -- If the amount of damage taken since the last Quill Spray proc is equal to or exceeds what's defined as the threshold, release a Quill Spray.
      if parent.quill_threshold_counter_oaa >= ability:GetSpecialValueFor("quill_release_threshold") and ability:IsCooldownReady() then
        -- Trigger Quill Spray
        quill_spray_ability:OnSpellStart()
        -- Start cooldown for Bristleback passive (OAA unique)
        ability:StartCooldown(ability:GetCooldown(ability:GetLevel()))
        -- Reset the Quill Spray damage counter
        parent.quill_threshold_counter_oaa = 0
      end
    end
  end

  return blocked_damage
end
