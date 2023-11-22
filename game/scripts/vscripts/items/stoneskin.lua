item_stoneskin = class(ItemBaseClass)

LinkLuaModifier("modifier_item_stoneskin_passives", "items/stoneskin.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_stoneskin_aura_effect", "items/stoneskin.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_stoneskin_stone_armor", "items/stoneskin.lua", LUA_MODIFIER_MOTION_NONE)

function item_stoneskin:GetIntrinsicModifierName()
  return "modifier_item_stoneskin_passives"
end

function item_stoneskin:OnSpellStart()
  local caster = self:GetCaster()

  -- Apply Stoneskin buff to caster
  caster:AddNewModifier(caster, self, "modifier_item_stoneskin_stone_armor", {duration = self:GetSpecialValueFor("duration")})

  -- Activation Sound
  caster:EmitSound("Hero_EarthSpirit.Petrify")
end

-- OnProjectileHit_ExtraData doesn't work for items which is sad
function item_stoneskin:OnProjectileHit(target, location)
  if not target or not location then
    return
  end

  if target:IsMagicImmune() or target:IsAttackImmune() then
    return
  end

  local attacker
  if self.deflect_attacker then
    attacker = EntIndexToHScript(self.deflect_attacker)
  end

  if not attacker or attacker:IsNull() then
    return
  end

  local damage = self.deflect_damage or 0

  -- Initialize damage table
  local damage_table = {
    attacker = attacker,
    victim = target,
    damage = damage,
    damage_type = DAMAGE_TYPE_PHYSICAL,
    damage_flags = bit.bor(DOTA_DAMAGE_FLAG_REFLECTION, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL, DOTA_DAMAGE_FLAG_NON_LETHAL),
    ability = self,
  }

  -- Apply damage
  ApplyDamage(damage_table)

  return true
end

item_stoneskin_2 = item_stoneskin

------------------------------------------------------------------------

modifier_item_stoneskin_passives = class(ModifierBaseClass)

function modifier_item_stoneskin_passives:IsHidden()
  return true
end

function modifier_item_stoneskin_passives:IsDebuff()
  return false
end

function modifier_item_stoneskin_passives:IsPurgable()
  return false
end

function modifier_item_stoneskin_passives:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_stoneskin_passives:OnCreated()
  self:OnRefresh()
  if IsServer() then
    self:StartIntervalThink(0.1)
  end
end

function modifier_item_stoneskin_passives:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_armor = ability:GetSpecialValueFor("bonus_armor")
    self.bonus_int = ability:GetSpecialValueFor("bonus_intellect")
    self.bonus_status_resist = ability:GetSpecialValueFor("bonus_status_resist")
  end

  if IsServer() then
    self:OnIntervalThink()
  end
end

function modifier_item_stoneskin_passives:OnIntervalThink()
  if self:IsFirstItemInInventory() then
    self:SetStackCount(2)
  else
    self:SetStackCount(1)
  end
end

function modifier_item_stoneskin_passives:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
  }
end

function modifier_item_stoneskin_passives:GetModifierPhysicalArmorBonus()
  return self.bonus_armor or self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_item_stoneskin_passives:GetModifierBonusStats_Intellect()
  return self.bonus_int or self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

function modifier_item_stoneskin_passives:GetModifierStatusResistanceStacking()
  if self:GetStackCount() == 2 then
    return self.bonus_status_resist or self:GetAbility():GetSpecialValueFor("bonus_status_resist")
  else
    return 0
  end
end

function modifier_item_stoneskin_passives:IsAura()
  return true
end

function modifier_item_stoneskin_passives:GetModifierAura()
  return "modifier_item_stoneskin_aura_effect"
end

function modifier_item_stoneskin_passives:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_item_stoneskin_passives:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_item_stoneskin_passives:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
end

---------------------------------------------------------------------------------------------------

modifier_item_stoneskin_aura_effect = class(ModifierBaseClass)

function modifier_item_stoneskin_aura_effect:IsHidden() -- needs tooltip
  return false
end

function modifier_item_stoneskin_aura_effect:IsDebuff()
  return false
end

function modifier_item_stoneskin_aura_effect:IsPurgable()
  return false
end

function modifier_item_stoneskin_aura_effect:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.hp_regen_amp = ability:GetSpecialValueFor("hp_regen_amp")
    self.lifesteal_amp = ability:GetSpecialValueFor("lifesteal_amp")
    self.heal_amp = ability:GetSpecialValueFor("heal_amp")
    self.spell_lifesteal_amp = ability:GetSpecialValueFor("spell_lifesteal_amp")
  end
end

function modifier_item_stoneskin_aura_effect:OnRefresh()
  self:OnCreated()
end

function modifier_item_stoneskin_aura_effect:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
    MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
  }
end

function modifier_item_stoneskin_aura_effect:GetModifierHPRegenAmplify_Percentage()
  return self.hp_regen_amp or self:GetAbility():GetSpecialValueFor("hp_regen_amp")
end

function modifier_item_stoneskin_aura_effect:GetModifierHealAmplify_PercentageTarget()
  return self.heal_amp or self:GetAbility():GetSpecialValueFor("heal_amp")
end

function modifier_item_stoneskin_aura_effect:GetModifierLifestealRegenAmplify_Percentage()
  return self.lifesteal_amp or self:GetAbility():GetSpecialValueFor("lifesteal_amp")
end

function modifier_item_stoneskin_aura_effect:GetModifierSpellLifestealRegenAmplify_Percentage()
  return self.spell_lifesteal_amp or self:GetAbility():GetSpecialValueFor("spell_lifesteal_amp")
end

function modifier_item_stoneskin_aura_effect:GetTexture()
  return "custom/stoneskin_2"
end

------------------------------------------------------------------------

modifier_item_stoneskin_stone_armor = class(ModifierBaseClass)

function modifier_item_stoneskin_stone_armor:IsHidden() -- needs tooltip
  return false
end

function modifier_item_stoneskin_stone_armor:IsDebuff()
  return false
end

function modifier_item_stoneskin_stone_armor:IsPurgable()
  return false
end

function modifier_item_stoneskin_stone_armor:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_AVOID_DAMAGE,
    --MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    --MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
    --MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
  }
end

function modifier_item_stoneskin_stone_armor:GetModifierPhysicalArmorBonus()
  if not self:GetAbility() then
    if not self:IsNull() then
      self:Destroy()
    end
    return 0
  end
  return self:GetAbility():GetSpecialValueFor("stone_armor")
end

-- function modifier_item_stoneskin_stone_armor:GetModifierMagicalResistanceBonus()
  -- if not self:GetAbility() then
    -- if not self:IsNull() then
      -- self:Destroy()
    -- end
    -- return 0
  -- end
  -- return self:GetAbility():GetSpecialValueFor("stone_magic_resist")
-- end

function modifier_item_stoneskin_stone_armor:GetModifierAvoidDamage(event)
  local parent = self:GetParent()
  local ability = self:GetAbility()
  local chance = 40
  local radius = 400
  if ability and not ability:IsNull() then
    chance = ability:GetSpecialValueFor("stone_deflect_chance")
    radius = ability:GetSpecialValueFor("stone_deflect_radius")
  end
  if event.ranged_attack == true and event.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK and RollPseudoRandomPercentage(chance, DOTA_PSEUDO_RANDOM_CUSTOM_GAME_1, parent) == true then
    local units = FindUnitsInRadius(
      parent:GetTeamNumber(),
      parent:GetAbsOrigin(),
      nil,
      radius,
      DOTA_UNIT_TARGET_TEAM_BOTH,
      bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
      DOTA_UNIT_TARGET_FLAG_NONE,
      FIND_CLOSEST,
      false
    )
    local closest
    local attacker = event.attacker
    for _, unit in ipairs(units) do
      if unit ~= parent then
        closest = unit
        break
      end
    end
    if closest and attacker then
      local info = {
        EffectName = attacker:GetRangedProjectileName(),
        Ability = ability,
        Source = parent,
        vSourceLoc = parent:GetAbsOrigin(),
        Target = closest,
        iMoveSpeed = attacker:GetProjectileSpeed() * 3/4,
        bDodgeable = true,
        bProvidesVision = true,
        iVisionRadius = 250,
        iVisionTeamNumber = attacker:GetTeamNumber(),
        --bIsAttack = true,
        --bReplaceExisting = false,
        --bIgnoreObstructions = true,
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
        bDrawsOnMinimap = false,
        bVisibleToEnemies = true,
        -- ExtraData = {
          -- attacker = attacker:GetEntityIndex(),
          -- damage = math.max(event.original_damage, event.damage),
        -- }
      }
      -- Create a tracking projectile
      ProjectileManager:CreateTrackingProjectile(info)

      if ability then
        ability.deflect_attacker = attacker:GetEntityIndex()
        ability.deflect_damage = math.max(event.original_damage, event.damage)
      end
    end

    return 1
  end

  return 0
end

-- function modifier_item_stoneskin_stone_armor:GetModifierStatusResistanceStacking()
  -- if not self:GetAbility() then
    -- if not self:IsNull() then
      -- self:Destroy()
    -- end
    -- return 0
  -- end
  -- return self:GetAbility():GetSpecialValueFor("stone_status_resist")
-- end

function modifier_item_stoneskin_stone_armor:GetStatusEffectName()
  return "particles/status_fx/status_effect_earth_spirit_petrify.vpcf"
end

function modifier_item_stoneskin_stone_armor:StatusEffectPriority()
  return MODIFIER_PRIORITY_ULTRA
end

-- function modifier_item_stoneskin_stone_armor:GetModifierMoveSpeed_Absolute()
  -- if not self:GetAbility() then
    -- if not self:IsNull() then
      -- self:Destroy()
    -- end
    -- return
  -- end
  -- return self:GetAbility():GetSpecialValueFor("stone_move_speed")
-- end

function modifier_item_stoneskin_stone_armor:GetTexture()
  return "custom/stoneskin_2_active"
end
