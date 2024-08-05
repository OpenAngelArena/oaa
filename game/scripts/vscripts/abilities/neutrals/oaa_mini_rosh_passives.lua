LinkLuaModifier("modifier_mini_rosh_passives", "abilities/neutrals/oaa_mini_rosh_passives.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mini_rosh_aura_effect", "abilities/neutrals/oaa_mini_rosh_passives.lua", LUA_MODIFIER_MOTION_NONE)

mini_rosh_passives = class(AbilityBaseClass)

function mini_rosh_passives:GetIntrinsicModifierName()
  return "modifier_mini_rosh_passives"
end

function mini_rosh_passives:ShouldUseResources()
  return true
end

--------------------------------------------------------------------------------

modifier_mini_rosh_passives = class(ModifierBaseClass)

function modifier_mini_rosh_passives:IsHidden()
  return true
end

function modifier_mini_rosh_passives:IsDebuff()
  return false
end

function modifier_mini_rosh_passives:IsPurgable()
  return false
end

function modifier_mini_rosh_passives:IsAura()
  local parent = self:GetParent()
  if parent:PassivesDisabled() then
    return false
  end
  return true
end

function modifier_mini_rosh_passives:GetModifierAura()
  return "modifier_mini_rosh_aura_effect"
end

function modifier_mini_rosh_passives:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_mini_rosh_passives:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_mini_rosh_passives:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
end

function modifier_mini_rosh_passives:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS
end

function modifier_mini_rosh_passives:GetAuraEntityReject(hEntity)
  local caster = self:GetCaster()
  -- Dont provide the aura effect to allies when caster (owner of this aura) cannot be controlled
  if hEntity ~= caster and not caster:IsControllableByAnyPlayer() then
    return true
  end
  return false
end

function modifier_mini_rosh_passives:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
    MODIFIER_PROPERTY_ABSORB_SPELL,
  }
end

-- function modifier_mini_rosh_passives:CheckState()
  -- local parent = self:GetParent()
  -- if not parent:IsControllableByAnyPlayer() then
    -- return {
      -- [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
      -- [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    -- }
  -- end
  -- return {}
-- end

function modifier_mini_rosh_passives:GetModifierStatusResistanceStacking()
  if not self:GetParent():IsHero() then
    return self:GetAbility():GetSpecialValueFor("bonus_status_resistance")
  else
    return 0
  end
end

if IsServer() then
  function modifier_mini_rosh_passives:GetAbsorbSpell(event)
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local casted_ability = event.ability

    -- Don't block if we don't have required variables
    if not ability or ability:IsNull() or not casted_ability or casted_ability:IsNull() then
      return 0
    end

    local caster = casted_ability:GetCaster()

    -- Don't block allied spells
    if caster:GetTeamNumber() == parent:GetTeamNumber() then
      return 0
    end

    -- Don't block if parent is dominated, under break of if parent is an illusion
    -- Some stuff pierce invulnerability (like Nullifier) so we need to block them too
    if parent:IsDominated() or parent:PassivesDisabled() or parent:IsIllusion() then
      return 0
    end

    -- Don't block if on cooldown
    if not ability:IsCooldownReady() then
      return 0
    end

    -- Start cooldown respecting cooldown reductions
    ability:UseResources(false, false, false, true)

    -- Particle
    local particle_name = "particles/items_fx/immunity_sphere.vpcf"
    local particle = ParticleManager:CreateParticle(particle_name, PATTACH_POINT_FOLLOW, parent)
    ParticleManager:ReleaseParticleIndex(particle)

    -- Sound
    parent:EmitSound("DOTA_Item.LinkensSphere.Activate")

    return 1
  end
end

--------------------------------------------------------------------------------

modifier_mini_rosh_aura_effect = class(ModifierBaseClass)

function modifier_mini_rosh_aura_effect:IsHidden()
  return false
end

function modifier_mini_rosh_aura_effect:IsDebuff()
  return false
end

function modifier_mini_rosh_aura_effect:IsPurgable()
  return false
end

function modifier_mini_rosh_aura_effect:OnCreated()
  local ability = self:GetAbility()
  if ability then
    self.bonus_armor = ability:GetSpecialValueFor("aura_bonus_armor")
  end
end

function modifier_mini_rosh_aura_effect:OnRefresh()
  local ability = self:GetAbility()
  if ability then
    self.bonus_armor = ability:GetSpecialValueFor("aura_bonus_armor")
  end
end

function modifier_mini_rosh_aura_effect:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
  }
end

function modifier_mini_rosh_aura_effect:GetModifierPhysicalArmorBonus()
  if self.bonus_armor then
    return self.bonus_armor
  end
  return 5
end
