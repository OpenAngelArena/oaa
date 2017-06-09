-- defines item_preemptive_3c
-- defines modifier_item_preemptive_bubble_aura_block
-- defines modifier_item_preemptive_bubble_block
-- Notes: Blocking of non-targeted spell effects is done by a ModifierGained filter found in components/reflexfilters/bubble.lua
-- Uses a thinker as a pseudo-aura instead of a proper aura because those always have a stickiness of 0.5 and cause issues with
-- multiple bubles on the same team. This makes the display for the modifier a little odd.
-- Does not block hook movement.
-- Visual effects such as screenshake from stun not always blocked.
-- Does not block effects from non-targeted spells from being refreshed. e.g. being stunned again by the same skill
LinkLuaModifier("modifier_item_preemptive_bubble_aura_block", "items/reflex/preemptive_bubble.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_preemptive_bubble_block", "items/reflex/preemptive_bubble.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_generic_bonus", "modifiers/modifier_generic_bonus.lua", LUA_MODIFIER_MOTION_NONE)
require('libraries/timers')

------------------------------------------------------------------------

item_preemptive_3c = class({})

function item_preemptive_3c:GetIntrinsicModifierName()
  return "modifier_generic_bonus"
end

function item_preemptive_3c:OnSpellStart()
  local caster = self:GetCaster()
  local targetPoint = caster:GetOrigin()
  local duration = self:GetSpecialValueFor("duration")
  local radius = self:GetSpecialValueFor("radius")

  -- Create bubble
  CreateModifierThinker(caster, self, "modifier_item_preemptive_bubble_aura_block", {duration = duration}, targetPoint, caster:GetTeamNumber(), false)

  EmitSoundOnLocationWithCaster(targetPoint, "Hero_ArcWarden.MagneticField.Cast", caster)
  -- Particle effect
  local bubbleEffectName = "particles/items/bubble_orb_base.vpcf"
  local bubbleEffect = ParticleManager:CreateParticle(bubbleEffectName, PATTACH_ABSORIGIN, caster)
  ParticleManager:SetParticleControl(bubbleEffect, 1, Vector(radius, radius, radius))

  -- Timer to destroy particle effect
  Timers:CreateTimer(duration, function()
    ParticleManager:DestroyParticle(bubbleEffect, false)
    ParticleManager:ReleaseParticleIndex(bubbleEffect)
  end)
end

------------------------------------------------------------------------

modifier_item_preemptive_bubble_aura_block = class({})

function modifier_item_preemptive_bubble_aura_block:IsHidden()
  return true
end

function modifier_item_preemptive_bubble_aura_block:IsDebuff()
  return false
end

function modifier_item_preemptive_bubble_aura_block:IsPurgable()
  return false
end

function modifier_item_preemptive_bubble_aura_block:IsPurgeException()
  return false
end

function modifier_item_preemptive_bubble_aura_block:IsAura()
  return true
end

function modifier_item_preemptive_bubble_aura_block:OnCreated(keys)
  if IsServer() then
    self.bubbleCenter = self:GetParent():GetOrigin()
    self.caster = self:GetCaster()
    self.casterTeam = self.caster:GetTeamNumber()
    self.bubbleID = "BubbleOrbID: " .. self.casterTeam .. "," .. self.bubbleCenter.x .. "," .. self.bubbleCenter.y
    self.ability = self:GetAbility()
    self.radius = self.ability:GetSpecialValueFor("radius")
    self.aura_stickiness = self.ability:GetSpecialValueFor("aura_stickiness")
    self:StartIntervalThink(self.aura_stickiness)
    self:OnIntervalThink()
  end
end

function modifier_item_preemptive_bubble_aura_block:OnIntervalThink()
  local alliedUnitsInBubble = FindUnitsInRadius(
    self.casterTeam,
    self.bubbleCenter,
    nil,
    self.radius,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    DOTA_UNIT_TARGET_ALL,
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  local function ApplyBlockModifier(unit)
    local bubbleModifierName = "modifier_item_preemptive_bubble_block"
    local bubbleModifiers = unit:FindAllModifiersByName(bubbleModifierName)

    -- Checks if the given modifier comes from the bubble represented by self by comparing centers
    local function IsFromThisBubble(modifier)
      return modifier.bubbleCenter.x == self.bubbleCenter.x and modifier.bubbleCenter.y == self.bubbleCenter.y
    end

    local duplicateModifier = nth(1, filter(IsFromThisBubble, bubbleModifiers))
    local bubbleModifierID = self.bubbleID .. "," .. unit:entindex()
    -- If the unit already has a modifier with the same center then refresh its timer
    if duplicateModifier then
      Timers:RemoveTimer(bubbleModifierID)
      Timers:CreateTimer(bubbleModifierID, {
        endTime = self.aura_stickiness,
        callback = function()
          duplicateModifier:Destroy()
        end
      })
    else -- Else create a new modifier and set a timer so that it gets destroyed if not refreshed
      local newBubbleModifier = unit:AddNewModifier(self.caster, self.ability, bubbleModifierName, {
        aura_origin_x = self.bubbleCenter.x,
        aura_origin_y = self.bubbleCenter.y
      })
      Timers:CreateTimer(bubbleModifierID, {
        endTime = self.aura_stickiness,
        callback = function()
          newBubbleModifier:Destroy()
        end
      })
    end
  end

  foreach(ApplyBlockModifier, iter(alliedUnitsInBubble))
end

-- function modifier_item_preemptive_bubble_aura_block:GetAuraRadius()
--   return self:GetAbility():GetSpecialValueFor("radius")
-- end

-- function modifier_item_preemptive_bubble_aura_block:GetAuraSearchTeam()
--   return DOTA_UNIT_TARGET_TEAM_FRIENDLY
-- end

-- function modifier_item_preemptive_bubble_aura_block:GetAuraSearchType()
--   return DOTA_UNIT_TARGET_ALL
-- end

-- function modifier_item_preemptive_bubble_aura_block:GetModifierAura()
--   return "modifier_item_preemptive_bubble_block"
-- end

------------------------------------------------------------------------

modifier_item_preemptive_bubble_block = class({})

function modifier_item_preemptive_bubble_block:IsHidden()
  return false
end

function modifier_item_preemptive_bubble_block:IsDebuff()
  return false
end

function modifier_item_preemptive_bubble_block:IsPurgable()
  return false
end

function modifier_item_preemptive_bubble_block:IsPurgeException()
  return false
end

function modifier_item_preemptive_bubble_block:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_preemptive_bubble_block:GetTexture()
  return self:GetAbility():GetAbilityTextureName()
end

function modifier_item_preemptive_bubble_block:OnCreated(keys)
  self.bubbleCenter = Vector(keys.aura_origin_x, keys.aura_origin_y, 0)
end

function modifier_item_preemptive_bubble_block:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ABSORB_SPELL,
    MODIFIER_PROPERTY_AVOID_DAMAGE
  }
end

function modifier_item_preemptive_bubble_block:GetAbsorbSpell(keys)
  local caster = keys.ability:GetCaster()
  local casterIsAlly = caster:GetTeamNumber() == self:GetParent():GetTeamNumber()

  if casterIsAlly or self:UnitIsInBubble(caster) then
    return 0
  else
    self:PlayBlockEffect()
    return 1
  end
end

function modifier_item_preemptive_bubble_block:GetModifierAvoidDamage(keys)
  local attacker = keys.attacker
  local attackerIsAlly = attacker:GetTeamNumber() == self:GetParent():GetTeamNumber()
  local parent = self:GetParent()

  -- Assume that the existence of the inflictor key means the
  -- damage came from a hero or item ability
  if not keys.inflictor or attackerIsAlly or self:UnitIsInBubble(attacker) then
    return 0
  else
    --self:PlayBlockEffect()
    return 1
  end
end

function modifier_item_preemptive_bubble_block:UnitIsInBubble(unit)
  local radius = self:GetAbility():GetSpecialValueFor("radius")
  local unitsInBubble = FindUnitsInRadius(unit:GetTeamNumber(), self.bubbleCenter, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

  return index(unit, unitsInBubble)
end

function modifier_item_preemptive_bubble_block:PlayBlockEffect()
  local parent = self:GetParent()
  local blockEffectName = "particles/items_fx/immunity_sphere.vpcf"
  local blockEffect = ParticleManager:CreateParticle(blockEffectName, PATTACH_POINT_FOLLOW, parent)
  ParticleManager:ReleaseParticleIndex(blockEffect)

  EmitSoundOn("DOTA_Item.LinkensSphere.Activate", parent)
end
