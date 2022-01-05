LinkLuaModifier("modifier_intrinsic_multiplexer", "modifiers/modifier_intrinsic_multiplexer.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_heart_oaa_stacking_stats", "items/heart.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_heart_oaa_non_stacking_stats", "items/heart.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_heart_oaa_active", "items/heart.lua", LUA_MODIFIER_MOTION_NONE)

item_heart_oaa = class(ItemBaseClass)

function item_heart_oaa:GetIntrinsicModifierName()
  return "modifier_intrinsic_multiplexer"
end

function item_heart_oaa:GetIntrinsicModifierNames()
  return {
    "modifier_item_heart_oaa_stacking_stats",
    "modifier_item_heart_oaa_non_stacking_stats"
  }
end

function item_heart_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local buff_duration = self:GetSpecialValueFor("buff_duration")

  -- Apply a Heart special buff to the caster
  caster:AddNewModifier(caster, self, "modifier_item_heart_oaa_active", {duration = buff_duration})

  -- Find enemies
  local center = caster:GetAbsOrigin()
  local radius = self:GetSpecialValueFor("radius")
  local enemies = FindUnitsInRadius(
    caster:GetTeamNumber(),
    center,
    nil,
    radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  -- Havoc Particle
  local particle = ParticleManager:CreateParticle("particles/items5_fx/havoc_hammer.vpcf", PATTACH_ABSORIGIN, caster)
  ParticleManager:SetParticleControl(particle, 1, Vector(radius, radius, radius))
  ParticleManager:ReleaseParticleIndex(particle)

  -- Havoc Sound
  caster:EmitSound("DOTA_Item.HavocHammer.Cast")

  -- Havoc Knockback
  local knockback_table = {
    should_stun = 0,
    center_x = center.x,
    center_y = center.y,
    center_z = center.z,
    duration = self:GetSpecialValueFor("knockback_duration"),
    knockback_duration = self:GetSpecialValueFor("knockback_duration"),
    knockback_distance = self:GetSpecialValueFor("knockback_distance"),
  }

  -- Knockback enemies
  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() then
      --knockback_table.knockback_distance = radius - (center - enemy:GetAbsOrigin()):Length2D()
      enemy:AddNewModifier(caster, self, "modifier_knockback", knockback_table)
    end
  end

  -- Havoc Damage
  local havoc_damage = self:GetSpecialValueFor("nuke_base_dmg")
  if caster:IsHero() then
    havoc_damage = self:GetSpecialValueFor("nuke_base_dmg") + caster:GetStrength() * self:GetSpecialValueFor("nuke_str_dmg")
  end

  local damage_table = {
    attacker = caster,
    damage = havoc_damage,
    damage_type = DAMAGE_TYPE_MAGICAL,
    damage_flags = DOTA_DAMAGE_FLAG_NONE,
    ability = self,
  }

  -- Damage enemies
  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() then
      damage_table.victim = enemy
      ApplyDamage(damage_table)
    end
  end
end

function item_heart_oaa:ProcsMagicStick()
  return false
end

item_heart_2 = item_heart_oaa
item_heart_3 = item_heart_oaa
item_heart_4 = item_heart_oaa
item_heart_5 = item_heart_oaa

---------------------------------------------------------------------------------------------------
-- Parts of Heart that should stack with other items

modifier_item_heart_oaa_stacking_stats = class(ModifierBaseClass)

function modifier_item_heart_oaa_stacking_stats:IsHidden()
  return true
end

function modifier_item_heart_oaa_stacking_stats:IsDebuff()
  return false
end

function modifier_item_heart_oaa_stacking_stats:IsPurgable()
  return false
end

function modifier_item_heart_oaa_stacking_stats:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_heart_oaa_stacking_stats:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.str = ability:GetSpecialValueFor("bonus_strength")
    self.hp = ability:GetSpecialValueFor("bonus_health")
  end
end

modifier_item_heart_oaa_stacking_stats.OnRefresh = modifier_item_heart_oaa_stacking_stats.OnCreated

function modifier_item_heart_oaa_stacking_stats:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_HEALTH_BONUS,
  }
end

function modifier_item_heart_oaa_stacking_stats:GetModifierBonusStats_Strength()
  return self.str or self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_heart_oaa_stacking_stats:GetModifierHealthBonus()
  return self.hp or self:GetAbility():GetSpecialValueFor("bonus_health")
end

---------------------------------------------------------------------------------------------------
-- Parts of Heart that should NOT stack with other Hearts and Heart Transplants

modifier_item_heart_oaa_non_stacking_stats = class(ModifierBaseClass)

function modifier_item_heart_oaa_non_stacking_stats:IsHidden()
  return true
end

function modifier_item_heart_oaa_non_stacking_stats:IsDebuff()
  return false
end

function modifier_item_heart_oaa_non_stacking_stats:IsPurgable()
  return false
end

function modifier_item_heart_oaa_non_stacking_stats:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.regen = ability:GetSpecialValueFor("health_regen_pct")
  end
end

modifier_item_heart_oaa_non_stacking_stats.OnRefresh = modifier_item_heart_oaa_non_stacking_stats.OnCreated

function modifier_item_heart_oaa_non_stacking_stats:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
    --MODIFIER_EVENT_ON_TAKEDAMAGE
  }
end

function modifier_item_heart_oaa_non_stacking_stats:GetModifierHealthRegenPercentage()
  return self.regen or self:GetAbility():GetSpecialValueFor("health_regen_pct")
end

-- function modifier_item_heart_oaa_non_stacking_stats:OnTakeDamage(event)
  -- local parent = self:GetParent()
  -- local ability = self:GetAbility()

  -- if event.damage > 0 and event.unit == parent and event.attacker ~= parent and not event.attacker:IsNeutralUnitType() and not event.attacker:IsOAABoss() then
    -- Whatever is the effect when taking player-controlled damage
  -- end
-- end

---------------------------------------------------------------------------------------------------

modifier_item_heart_oaa_active = class(ModifierBaseClass)

function modifier_item_heart_oaa_active:IsHidden()
  return false
end

function modifier_item_heart_oaa_active:IsDebuff()
  return false
end

function modifier_item_heart_oaa_active:IsPurgable()
  return false
end

function modifier_item_heart_oaa_active:AllowIllusionDuplicate()
  return true
end

function modifier_item_heart_oaa_active:OnCreated()
  local parent = self:GetParent()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.str = ability:GetSpecialValueFor("buff_bonus_strength")
    self.bonus_damage = ability:GetSpecialValueFor("buff_bonus_base_damage")
  end

  -- if IsServer() then
    -- if self.nPreviewFX == nil then
      -- self.nPreviewFX = ParticleManager:CreateParticle("", PATTACH_ABSORIGIN_FOLLOW, parent)
      -- ParticleManager:SetParticleControlEnt(self.nPreviewFX, 0, parent, PATTACH_ABSORIGIN_FOLLOW, nil, parent:GetOrigin(), true)
    -- end
  -- end

  if IsServer() and parent:IsHero() then
    parent:CalculateStatBonus(true)
  end
end

function modifier_item_heart_oaa_active:OnRefresh()
  local parent = self:GetParent()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.str = ability:GetSpecialValueFor("buff_bonus_strength")
    self.bonus_damage = ability:GetSpecialValueFor("buff_bonus_base_damage")
  end

  if IsServer() and parent:IsHero() then
    parent:CalculateStatBonus(true)
  end
end

-- function modifier_item_heart_oaa_active:OnDestroy()
  -- if IsServer() then
    -- if self.nPreviewFX then
      -- ParticleManager:DestroyParticle(self.nPreviewFX, false)
      -- ParticleManager:ReleaseParticleIndex(self.nPreviewFX)
      -- self.nPreviewFX = nil
    -- end
  -- end
-- end

function modifier_item_heart_oaa_active:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE     -- this is bonus base damage (white)
  }
end

function modifier_item_heart_oaa_active:GetModifierBonusStats_Strength()
  return self.str
end

function modifier_item_heart_oaa_active:GetModifierBaseAttack_BonusDamage()
  return self.bonus_damage
end

function modifier_item_heart_oaa_active:GetEffectName()
  return "particles/econ/courier/courier_greevil_red/courier_greevil_red_ambient_3.vpcf"
end

function modifier_item_heart_oaa_active:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_item_heart_oaa_active:GetTexture()
  return "item_heart"
end
