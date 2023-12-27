LinkLuaModifier("modifier_angels_halo_passive", "items/angels_halo.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_angels_halo_active", "items/angels_halo.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_angels_halo_aura_effect", "items/angels_halo.lua", LUA_MODIFIER_MOTION_NONE)

item_angels_halo = class(ItemBaseClass)

function item_angels_halo:GetIntrinsicModifierName()
  return "modifier_angels_halo_passive"
end

function item_angels_halo:OnSpellStart()
  local caster = self:GetCaster()

  caster:EmitSound("DOTA_Item.FaerieSpark.Activate")

  local consumed_ms = self:GetSpecialValueFor("consumed_bonus_move_speed")
  local consumed_vision = self:GetSpecialValueFor("consumed_bonus_day_vision")
  local consumed_dmg = self:GetSpecialValueFor("consumed_aura_damage")
  local radius = self:GetSpecialValueFor("radius")

  if not caster:HasModifier("modifier_angels_halo_active") then
    caster:AddNewModifier(caster, self, "modifier_angels_halo_active", {ms = consumed_ms, vision = consumed_vision, dmg = consumed_dmg, radius = radius})

    self:SpendCharge()
  end
end

--------------------------------------------------------------------------------

modifier_angels_halo_active = class({})

function modifier_angels_halo_active:IsHidden()
  return false
end

function modifier_angels_halo_active:IsPurgable()
  return false
end

function modifier_angels_halo_active:IsDebuff()
  return false
end

function modifier_angels_halo_active:RemoveOnDeath()
  return false
end

function modifier_angels_halo_active:GetTexture()
  return "custom/angels_halo"
end

function modifier_angels_halo_active:OnCreated(event)
  if IsServer() then
    self:SetStackCount(0 - event.ms)
    self.vision = event.vision
    self.dmg = event.dmg
    self.radius = event.radius
    ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_guardian_angel_halo_buff.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent())
    self:StartIntervalThink(1)
  end
end

function modifier_angels_halo_active:OnIntervalThink()
  local parent = self:GetParent()

  local enemies = FindUnitsInRadius(
    parent:GetTeamNumber(),
    parent:GetAbsOrigin(),
    nil,
    self.radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO),
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  local damage_table = {
    attacker = parent,
    damage = self.dmg,
    damage_type = DAMAGE_TYPE_MAGICAL,
    damage_flags = DOTA_DAMAGE_FLAG_REFLECTION, -- to prevent Sticky Napalm and similar stuff
  }

  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() and not enemy:IsMagicImmune() then
      damage_table.victim = enemy
      ApplyDamage(damage_table)
    end
  end
end

function modifier_angels_halo_active:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_BONUS_DAY_VISION,
  }
end

function modifier_angels_halo_active:GetModifierMoveSpeedBonus_Constant()
  return math.abs(self:GetStackCount())
end

function modifier_angels_halo_active:GetBonusDayVision()
  return self.vision or 200
end

-- aura stuff

function modifier_angels_halo_active:IsAura()
  return true
end

function modifier_angels_halo_active:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_angels_halo_active:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_angels_halo_active:GetAuraRadius()
  return self.radius or 900
end

function modifier_angels_halo_active:GetModifierAura()
  return "modifier_angels_halo_aura_effect"
end

---------------------------------------------------------------------------------------------------
-- Visual effect, dmg is on aura applier
modifier_angels_halo_aura_effect = class({})

function modifier_angels_halo_aura_effect:IsHidden()
  return false
end

function modifier_angels_halo_aura_effect:IsPurgable()
  return false
end

function modifier_angels_halo_aura_effect:IsDebuff()
  return true
end

function modifier_angels_halo_aura_effect:GetTexture()
  return "custom/angels_halo"
end

---------------------------------------------------------------------------------------------------

modifier_angels_halo_passive = class({})

function modifier_angels_halo_passive:IsHidden()
  return true
end

function modifier_angels_halo_passive:IsPurgable()
  return false
end

function modifier_angels_halo_passive:IsDebuff()
  return false
end

function modifier_angels_halo_passive:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.ms = ability:GetSpecialValueFor("bonus_move_speed")
    self.vision = ability:GetSpecialValueFor("bonus_day_vision")
    self.dmg = ability:GetSpecialValueFor("aura_damage")
    self.radius = ability:GetSpecialValueFor("radius")
  end
  if IsServer() then
    self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_guardian_angel_halo_buff.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent())
    self:StartIntervalThink(1)
  end
end

function modifier_angels_halo_passive:OnIntervalThink()
  local parent = self:GetParent()

  local enemies = FindUnitsInRadius(
    parent:GetTeamNumber(),
    parent:GetAbsOrigin(),
    nil,
    self.radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO),
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  local damage_table = {
    attacker = parent,
    damage = self.dmg,
    damage_type = DAMAGE_TYPE_MAGICAL,
    damage_flags = DOTA_DAMAGE_FLAG_REFLECTION, -- to prevent Sticky Napalm and similar stuff
  }

  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() and not enemy:IsMagicImmune() then
      damage_table.victim = enemy
      ApplyDamage(damage_table)
    end
  end
end

function modifier_angels_halo_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_BONUS_DAY_VISION,
  }
end

function modifier_angels_halo_passive:GetModifierMoveSpeedBonus_Constant()
  return self.ms
end

function modifier_angels_halo_passive:GetBonusDayVision()
  return self.vision
end

-- aura stuff

function modifier_angels_halo_passive:IsAura()
  return true
end

function modifier_angels_halo_passive:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_angels_halo_passive:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_angels_halo_passive:GetAuraRadius()
  return self.radius
end

function modifier_angels_halo_passive:GetModifierAura()
  return "modifier_angels_halo_aura_effect"
end

function modifier_angels_halo_passive:OnDestroy()
  if IsServer() then
    if self.particle then
      ParticleManager:DestroyParticle(self.particle, false)
      ParticleManager:ReleaseParticleIndex(self.particle)
    end
  end
end