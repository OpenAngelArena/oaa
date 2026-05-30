item_stoneskin = class(ItemBaseClass)

LinkLuaModifier("modifier_item_stoneskin_passives", "items/stoneskin.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_stoneskin_stone_armor", "items/stoneskin.lua", LUA_MODIFIER_MOTION_NONE)

function item_stoneskin:GetIntrinsicModifierName()
  return "modifier_item_stoneskin_passives"
end

function item_stoneskin:OnSpellStart()
  local caster = self:GetCaster()

  local stoneskin_duration = self:GetSpecialValueFor("duration")

  -- Buff Amp
  local real_buff_duration = GetValueChangedByBuffAmplification(stoneskin_duration, caster, caster)

  -- Apply Stoneskin buff to caster
  caster:AddNewModifier(caster, self, "modifier_item_stoneskin_stone_armor", {duration = real_buff_duration})

  -- Tough enchantment
  caster:ApplyNonStackableBuff(caster, self, "modifier_item_enhancement_tough", real_buff_duration)

  -- Activation Sound
  caster:EmitSound("Hero_EarthSpirit.Petrify")
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
    self:StartIntervalThink(0.3)
  end
end

function modifier_item_stoneskin_passives:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.stats = ability:GetSpecialValueFor("bonus_all_stats")
    self.bonus_armor = ability:GetSpecialValueFor("bonus_armor")
    self.hp_regen = ability:GetSpecialValueFor("bonus_health_regen")
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
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
  }
end

function modifier_item_stoneskin_passives:GetModifierPhysicalArmorBonus()
  return self.bonus_armor or self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_item_stoneskin_passives:GetModifierConstantHealthRegen()
  return self.hp_regen or self:GetAbility():GetSpecialValueFor("bonus_health_regen")
end

function modifier_item_stoneskin_passives:GetModifierStatusResistanceStacking()
  -- Prevent multiple Stoneskin Armors stacking status resistance
  if self:GetStackCount() ~= 2 then
    return 0
  end

  return self.bonus_status_resist or self:GetAbility():GetSpecialValueFor("bonus_status_resist")
end

---------------------------------------------------------------------------------------------------

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

function modifier_item_stoneskin_stone_armor:OnCreated()
  self:OnRefresh()
end

function modifier_item_stoneskin_stone_armor:OnRefresh()
  local parent = self:GetParent()
  local ability = self:GetAbility()
  if not ability or ability:IsNull() then
    return
  end

  self.armor = ability:GetSpecialValueFor("stone_armor")
  --self.magic_resist = ability:GetSpecialValueFor("stone_magic_resist")
  self.deflect_chance = ability:GetSpecialValueFor("stone_deflect_chance")
  self.max_move_speed = parent:GetBaseMoveSpeed() + ability:GetSpecialValueFor("stone_max_move_speed_bonus")
  --self.min_move_speed = ability:GetSpecialValueFor("stone_min_move_speed")
end

function modifier_item_stoneskin_stone_armor:OnDestroy()
  if not IsServer() then
    return
  end
  local parent = self:GetParent()
  local ability = self:GetAbility()
  local caster = self:GetCaster()
  if not parent or parent:IsNull() then
    return
  end

  local mods = parent:FindAllModifiersByName("modifier_item_enhancement_tough")
  for _, mod in pairs(mods) do
    if mod and not mod:IsNull() then
      local mod_ability = mod:GetAbility()
      local mod_caster = mod:GetCaster()
      if mod_ability and mod_caster then
        if mod_ability == ability and mod_caster == caster then
          mod:Destroy()
          break
        end
      end
    end
  end
end

function modifier_item_stoneskin_stone_armor:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_AVOID_DAMAGE,
    --MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    --MODIFIER_PROPERTY_MOVESPEED_MIN_OVERRIDE,
    MODIFIER_PROPERTY_MOVESPEED_MAX_OVERRIDE,
  }
end

function modifier_item_stoneskin_stone_armor:GetModifierPhysicalArmorBonus()
  return self.armor or self:GetAbility():GetSpecialValueFor("stone_armor")
end

--function modifier_item_stoneskin_stone_armor:GetModifierMagicalResistanceBonus()
  --return self.magic_resist or self:GetAbility():GetSpecialValueFor("stone_magic_resist")
--end

function modifier_item_stoneskin_stone_armor:GetModifierAvoidDamage(params)
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  local attacker = params.attacker

  if not attacker or attacker:IsNull() then
    return 0
  end

  -- Do not deflect when attacking self
  if attacker == parent then
    return 0
  end

  -- Deflect only from ranged attackers
  if not attacker:IsRangedAttacker() then
    return 0
  end

  -- Deflect only attacks and dmg from attack based spells
  if params.damage_category ~= DOTA_DAMAGE_CATEGORY_ATTACK then
    local inflictor = params.inflictor
    if not inflictor or inflictor:IsNull() then
      return 0
    end
    if not IsAttackAbilityCustom(inflictor) then
      return 0
    end
  end

  local chance = self.deflect_chance / 100

  if not self.deflect_failures then
    self.deflect_failures = 0
  end

  -- Get number of failures
  local prngMult = self.deflect_failures + 1

  if RandomFloat(0.0, 1.0) <= (PrdCFinder:GetCForP(chance) * prngMult) then
    -- Reset failure count
    self.deflect_failures = 0

    return 1
  else
    -- Increment number of failures
    self.deflect_failures = prngMult
  end

  return 0
end

function modifier_item_stoneskin_stone_armor:GetModifierMoveSpeed_MaxOverride()
  return self.max_move_speed
end

--function modifier_item_stoneskin_stone_armor:GetModifierMoveSpeed_MinOverride()
  --return self.min_move_speed or self:GetAbility():GetSpecialValueFor("stone_min_move_speed")
--end

function modifier_item_stoneskin_stone_armor:GetStatusEffectName()
  return "particles/status_fx/status_effect_earth_spirit_petrify.vpcf"
end

function modifier_item_stoneskin_stone_armor:StatusEffectPriority()
  return MODIFIER_PRIORITY_ULTRA
end

function modifier_item_stoneskin_stone_armor:GetTexture()
  return "custom/stoneskin_2_active"
end
