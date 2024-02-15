-- Notes: Blocking of non-targeted spell effects is done by a ModifierGained filter found in components/reflexfilters/bubble.lua
-- Uses a thinker as a pseudo-aura instead of a proper aura because those always have a stickiness of 0.5 and cause issues with
-- multiple bubles on the same team.
-- Does not block hook movement.
-- Visual effects such as screenshake from stun not always blocked.
-- Does not block effects from non-targeted spells from being refreshed. e.g. being stunned again by the same skill
LinkLuaModifier("modifier_item_preemptive_bubble_aura_block", "items/bubble_orb.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_preemptive_bubble_block", "items/bubble_orb.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_bubble_orb_visible_buff", "items/bubble_orb.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_bubble_orb_effect_cd", "items/bubble_orb.lua", LUA_MODIFIER_MOTION_NONE)

item_bubble_orb_1 = class(ItemBaseClass)
item_bubble_orb_2 = item_bubble_orb_1

function item_bubble_orb_1:GetIntrinsicModifierName()
  return "modifier_generic_bonus"
end

function item_bubble_orb_1:OnSpellStart()
  local caster = self:GetCaster()
  local targetPoint = caster:GetOrigin()
  local duration = self:GetSpecialValueFor("duration")
  local radius = self:GetSpecialValueFor("radius")

  -- Create bubble
  CreateModifierThinker(caster, self, "modifier_item_preemptive_bubble_aura_block", {duration = duration}, targetPoint, caster:GetTeamNumber(), false)

  EmitSoundOnLocationWithCaster(targetPoint, "Hero_ArcWarden.MagneticField.Cast", caster)

  -- Knockback enemies
  local enemies = FindUnitsInRadius(
    caster:GetTeamNumber(),
    targetPoint,
    nil,
    radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
    DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
    FIND_ANY_ORDER,
    false
  )
  local knockback_table = {
    should_stun = 1,
    center_x = targetPoint.x,
    center_y = targetPoint.y,
    center_z = targetPoint.z,
    knockback_distance = radius,
    knockback_height = 10,
  }
  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() then
      --knockback_table.knockback_distance = radius - (targetPoint - enemy:GetAbsOrigin()):Length2D()
      knockback_table.knockback_duration = enemy:GetValueChangedByStatusResistance(1.0)
      knockback_table.duration = knockback_table.knockback_duration

      enemy:AddNewModifier(caster, self, "modifier_knockback", knockback_table)
    end
  end

  -- Strong Dispel allies
  local allies = FindUnitsInRadius(
    caster:GetTeamNumber(),
    targetPoint,
    nil,
    radius,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )
  for _, ally in pairs(allies) do
    if ally and not ally:IsNull() then
      ally:Purge(false, true, false, true, false)
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Thinker modifier
modifier_item_preemptive_bubble_aura_block = class(ModifierBaseClass)

function modifier_item_preemptive_bubble_aura_block:IsHidden()
  return true
end

function modifier_item_preemptive_bubble_aura_block:IsDebuff()
  return false
end

function modifier_item_preemptive_bubble_aura_block:IsPurgable()
  return false
end

function modifier_item_preemptive_bubble_aura_block:OnCreated(keys)
  if IsServer() then
    local caster = self:GetCaster()
    local radius
    local aura_stickiness
    local ability = self:GetAbility()
    if ability and not ability:IsNull() then
      radius = ability:GetSpecialValueFor("radius")
      aura_stickiness = ability:GetSpecialValueFor("aura_stickiness")
    else
      radius = 300
      aura_stickiness = 0.1
    end

    self.radius = radius
    self.aura_stickiness = aura_stickiness

    -- Particle effect
    local bubbleEffectName = "particles/items/bubble_orb_base.vpcf"
    self.bubbleEffect = ParticleManager:CreateParticle(bubbleEffectName, PATTACH_ABSORIGIN, caster)
    ParticleManager:SetParticleControl(self.bubbleEffect, 1, Vector(radius, radius, radius))

    self:OnIntervalThink()
    self:StartIntervalThink(aura_stickiness - 0.04)
  end
end

function modifier_item_preemptive_bubble_aura_block:OnIntervalThink()
  local parent = self:GetParent()
  local caster = self:GetCaster()
  local ability = self:GetAbility()
  local team = caster:GetTeamNumber()
  local center = parent:GetAbsOrigin()
  local bubbleModifierName = "modifier_item_preemptive_bubble_block"

  local alliedUnitsInBubble = FindUnitsInRadius(
    team,
    center,
    nil,
    self.radius,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    DOTA_UNIT_TARGET_ALL,
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  for _, ally in pairs(alliedUnitsInBubble) do
    if ally and not ally:IsNull() and ally.AddNewModifier ~= nil then
      ally:AddNewModifier(caster, ability, bubbleModifierName, {
        duration = self.aura_stickiness,
        aura_origin_x = center.x,
        aura_origin_y = center.y
      })
    end
  end
end

function modifier_item_preemptive_bubble_aura_block:OnDestroy()
  if not IsServer() then
    return
  end
  if self.bubbleEffect then
    ParticleManager:DestroyParticle(self.bubbleEffect, false)
    ParticleManager:ReleaseParticleIndex(self.bubbleEffect)
  end
  local parent = self:GetParent()
  if parent and not parent:IsNull() then
    parent:ForceKillOAA(false)
  end
end

-- Aura part is just for the visual buff
function modifier_item_preemptive_bubble_aura_block:IsAura()
  return true
end

function modifier_item_preemptive_bubble_aura_block:GetAuraRadius()
  return self.radius or self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_item_preemptive_bubble_aura_block:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_item_preemptive_bubble_aura_block:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
end

function modifier_item_preemptive_bubble_aura_block:GetModifierAura()
  return "modifier_item_bubble_orb_visible_buff"
end

function modifier_item_preemptive_bubble_aura_block:GetAuraDuration()
  return self.aura_stickiness or self:GetAbility():GetSpecialValueFor("aura_stickiness")
end

---------------------------------------------------------------------------------------------------
-- modifier that blocks damage if they came from outside the bubble
modifier_item_preemptive_bubble_block = class(ModifierBaseClass)

function modifier_item_preemptive_bubble_block:IsHidden()
  return true
end

function modifier_item_preemptive_bubble_block:IsDebuff()
  return false
end

function modifier_item_preemptive_bubble_block:IsPurgable()
  return false
end

function modifier_item_preemptive_bubble_block:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_preemptive_bubble_block:OnCreated(keys)
  if IsServer() then
    self.bubbleCenter = Vector(keys.aura_origin_x, keys.aura_origin_y, 0)
  end
end

function modifier_item_preemptive_bubble_block:DeclareFunctions()
  return {
    --MODIFIER_PROPERTY_ABSORB_SPELL,
    MODIFIER_PROPERTY_AVOID_DAMAGE,
  }
end

if IsServer() then
  -- Spell block is done with modifier filter
  -- function modifier_item_preemptive_bubble_block:GetAbsorbSpell(keys)
    -- local ability = self:GetAbility()
    -- local casted_ability = keys.ability
    -- -- Don't block if we don't have required variables
    -- if not ability or ability:IsNull() or not casted_ability or casted_ability:IsNull() then
    --   return 0
    -- end
    -- local caster = casted_ability:GetCaster()
    -- local casterIsAlly = caster:GetTeamNumber() == self:GetParent():GetTeamNumber()

    -- if casterIsAlly or IsUnitInBubble(caster, self.bubbleCenter, ability) then
      -- return 0
    -- else
      -- self:PlayBlockEffect()
      -- return 1
    -- end
  -- end

  function modifier_item_preemptive_bubble_block:GetModifierAvoidDamage(keys)
    local attacker = keys.attacker
    local attackerIsAlly = attacker:GetTeamNumber() == self:GetParent():GetTeamNumber()

    -- Assume that the existence of the inflictor key means the
    -- damage came from a hero or item ability
    if not keys.inflictor or attackerIsAlly or IsUnitInBubble(attacker, self.bubbleCenter, self:GetAbility()) then
      return 0
    else
      return 1
    end
  end

  function IsUnitInBubble(unit, center, ability)
    if not center or not ability or ability:IsNull() or not unit or unit:IsNull() then
      return
    end
    local radius = ability:GetSpecialValueFor("radius")
    local unitsInBubble = FindUnitsInRadius(
      unit:GetTeamNumber(),
      center,
      nil,
      radius,
      DOTA_UNIT_TARGET_TEAM_FRIENDLY,
      DOTA_UNIT_TARGET_ALL,
      bit.bor(DOTA_UNIT_TARGET_FLAG_INVULNERABLE, DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD),
      FIND_ANY_ORDER,
      false
    )

    return index(unit, unitsInBubble)
  end

  -- function modifier_item_preemptive_bubble_block:PlayBlockEffect()
    -- local parent = self:GetParent()
    -- local blockEffectName = "particles/items_fx/immunity_sphere.vpcf"
    -- local blockEffect = ParticleManager:CreateParticle(blockEffectName, PATTACH_POINT_FOLLOW, parent)
    -- ParticleManager:ReleaseParticleIndex(blockEffect)

    -- parent:EmitSound("DOTA_Item.LinkensSphere.Activate")
  -- end
end

---------------------------------------------------------------------------------------------------

modifier_item_bubble_orb_visible_buff = class(ModifierBaseClass)

function modifier_item_bubble_orb_visible_buff:IsHidden()
  return false
end

function modifier_item_bubble_orb_visible_buff:IsDebuff()
  return false
end

function modifier_item_bubble_orb_visible_buff:IsPurgable()
  return false
end

function modifier_item_bubble_orb_visible_buff:GetTexture()
  return "custom/bubble_orb_1"
end

---------------------------------------------------------------------------------------------------

modifier_item_bubble_orb_effect_cd = class(ModifierBaseClass)

function modifier_item_bubble_orb_effect_cd:IsHidden()
  return true
end

function modifier_item_bubble_orb_effect_cd:IsDebuff()
  return false
end

function modifier_item_bubble_orb_effect_cd:IsPurgable()
  return false
end
