-- defines item_preemptive_3c
-- defines modifier_item_preemptive_bubble_aura_block
-- defines modifier_item_preemptive_bubble_block
LinkLuaModifier("modifier_item_preemptive_bubble_aura_block", "items/reflex/preemptive_bubble.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_preemptive_bubble_block", "items/reflex/preemptive_bubble.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_generic_bonus", "modifiers/modifier_generic_bonus.lua", LUA_MODIFIER_MOTION_NONE)

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
  local bubbleEffectName = "particles/econ/items/faceless_void/faceless_void_mace_of_aeons/fv_chronosphere_aeons.vpcf"
  local bubbleEffect = ParticleManager:CreateParticle(bubbleEffectName, PATTACH_ABSORIGIN, caster)
  ParticleManager:SetParticleControl(bubbleEffect, 1, Vector(radius, radius, radius))

  -- Timer to destroy dummy unit and particle effect
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

function modifier_item_preemptive_bubble_aura_block:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_item_preemptive_bubble_aura_block:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_item_preemptive_bubble_aura_block:GetAuraSearchType()
  return DOTA_UNIT_TARGET_ALL
end

function modifier_item_preemptive_bubble_aura_block:GetModifierAura()
  return "modifier_item_preemptive_bubble_block"
end

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

function modifier_item_preemptive_bubble_block:GetTexture()
  return self:GetAbility():GetAbilityTextureName()
end

function modifier_item_preemptive_bubble_block:OnCreated(keys)
  self.bubbleCenter = Vector(keys.aura_origin_x, keys.aura_origin_y, 0)
  -- Self-destruct to force refresh of bubbleCenter (relevant when moving between bubbles)
  -- and to reduce stickiness of buff as aura modifiers stick around for 0.5 seconds by default
  -- when leaving the aura
  Timers:CreateTimer(0.1, function()
    self:Destroy()
  end)
end

function modifier_item_preemptive_bubble_block:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ABSORB_SPELL,
    MODIFIER_PROPERTY_AVOID_DAMAGE
  }
end

function modifier_item_preemptive_bubble_block:GetAbsorbSpell(keys)
  Debug.EnabledModules["items:reflex:preemptive_bubble"] = true
  local caster = keys.ability:GetCaster()
  local casterTeam = caster:GetTeamNumber()
  local casterIsAlly = casterTeam == self:GetParent():GetTeamNumber()
  local radius = self:GetAbility():GetSpecialValueFor("radius")
  local unitsInBubble = FindUnitsInRadius(casterTeam, self.bubbleCenter, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
  local casterIsInBubble = index(caster, unitsInBubble)

  if casterIsAlly or casterIsInBubble then
    return 0
  else
    self:PlayBlockEffect()
    return 1
  end
end

function modifier_item_preemptive_bubble_block:GetModifierAvoidDamage(keys)
  local attacker = keys.attacker
  local attackerTeam = attacker:GetTeamNumber()
  local attackerIsAlly = attacker:GetTeamNumber() == self:GetParent():GetTeamNumber()
  local radius = self:GetAbility():GetSpecialValueFor("radius")
  local unitsInBubble = FindUnitsInRadius(attackerTeam, self.bubbleCenter, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
  local attackerIsInBubble = index(attacker, unitsInBubble)
  --DebugPrintTable(keys)
  -- Assume that the existence of the inflictor key means the
  -- damage came from a hero or item ability
  if not keys.inflictor or attackerIsAlly or attackerIsInBubble then
    return 0
  else
    return 1
  end
end

function modifier_item_preemptive_bubble_block:PlayBlockEffect()
  local parent = self:GetParent()
  local blockEffectName = "particles/items_fx/immunity_sphere.vpcf"
  local blockEffect = ParticleManager:CreateParticle(blockEffectName, PATTACH_POINT_FOLLOW, parent)
  ParticleManager:ReleaseParticleIndex(blockEffect)

  EmitSoundOn("DOTA_Item.LinkensSphere.Activate", parent)
end
