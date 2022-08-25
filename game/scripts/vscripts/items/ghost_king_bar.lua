item_ghost_king_bar = class(ItemBaseClass)

LinkLuaModifier("modifier_intrinsic_multiplexer", "modifiers/modifier_intrinsic_multiplexer.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ghost_king_bar_stacking_stats", "items/ghost_king_bar.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ghost_king_bar_non_stacking_stats", "items/ghost_king_bar.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ghost_king_bar_active", "items/ghost_king_bar.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ghost_king_bar_buff", "items/ghost_king_bar.lua", LUA_MODIFIER_MOTION_NONE)

function item_ghost_king_bar:GetIntrinsicModifierName()
  return "modifier_intrinsic_multiplexer"
end

function item_ghost_king_bar:GetIntrinsicModifierNames()
  return {
    "modifier_item_ghost_king_bar_stacking_stats",
    "modifier_item_ghost_king_bar_non_stacking_stats"
  }
end

function item_ghost_king_bar:OnSpellStart()
  local caster = self:GetCaster()

  -- Apply Basic Dispel
  caster:Purge(false, true, false, false, false)

  -- Apply Ghost King Bar buff to caster (but only if he doesnt have spell immunity)
  if not caster:IsMagicImmune() then
    caster:AddNewModifier(caster, self, "modifier_item_ghost_king_bar_active", {duration = self:GetSpecialValueFor("duration")})
  end

  -- Emit Activation sound
  caster:EmitSound("DOTA_Item.GhostScepter.Activate")
end

item_ghost_king_bar_2 = item_ghost_king_bar
item_ghost_king_bar_3 = item_ghost_king_bar

---------------------------------------------------------------------------------------------------

modifier_item_ghost_king_bar_stacking_stats = class(ModifierBaseClass)

function modifier_item_ghost_king_bar_stacking_stats:IsHidden()
  return true
end

function modifier_item_ghost_king_bar_stacking_stats:IsDebuff()
  return false
end

function modifier_item_ghost_king_bar_stacking_stats:IsPurgable()
  return false
end

function modifier_item_ghost_king_bar_stacking_stats:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_ghost_king_bar_stacking_stats:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.str = ability:GetSpecialValueFor("bonus_strength")
    self.agi = ability:GetSpecialValueFor("bonus_agility")
    self.int = ability:GetSpecialValueFor("bonus_intellect")
  end
end

modifier_item_ghost_king_bar_stacking_stats.OnRefresh = modifier_item_ghost_king_bar_stacking_stats.OnCreated

function modifier_item_ghost_king_bar_stacking_stats:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
  }
end

function modifier_item_ghost_king_bar_stacking_stats:GetModifierBonusStats_Strength()
  return self.str or self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_ghost_king_bar_stacking_stats:GetModifierBonusStats_Agility()
  return self.agi or self:GetAbility():GetSpecialValueFor("bonus_agility")
end

function modifier_item_ghost_king_bar_stacking_stats:GetModifierBonusStats_Intellect()
  return self.int or self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

---------------------------------------------------------------------------------------------------

modifier_item_ghost_king_bar_non_stacking_stats = class(ModifierBaseClass)

function modifier_item_ghost_king_bar_non_stacking_stats:IsHidden()
  return true
end

function modifier_item_ghost_king_bar_non_stacking_stats:IsDebuff()
  return false
end

function modifier_item_ghost_king_bar_non_stacking_stats:IsPurgable()
  return false
end

function modifier_item_ghost_king_bar_non_stacking_stats:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.spell_amp = ability:GetSpecialValueFor("spell_amp")
    self.spell_lifesteal_amp = ability:GetSpecialValueFor("spell_lifesteal_amp")
    self.mana_regen_amp = ability:GetSpecialValueFor("mana_regen_multiplier")
  end
end

modifier_item_ghost_king_bar_non_stacking_stats.OnRefresh = modifier_item_ghost_king_bar_non_stacking_stats.OnCreated

function modifier_item_ghost_king_bar_non_stacking_stats:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE, -- GetModifierMPRegenAmplify_Percentage
    MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,    -- GetModifierSpellAmplify_Percentage
    MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE, -- GetModifierSpellLifestealRegenAmplify_Percentage
  }
end

-- Doesn't stack with Kaya items
function modifier_item_ghost_king_bar_non_stacking_stats:GetModifierMPRegenAmplify_Percentage()
  local parent = self:GetParent()
  if parent:HasModifier("modifier_item_kaya") or parent:HasModifier("modifier_item_yasha_and_kaya") or parent:HasModifier("modifier_item_kaya_and_sange") or parent:HasModifier("modifier_item_ethereal_blade") then
    return 0
  end
  if parent:HasModifier("modifier_item_sacred_skull_non_stacking_stats") then
    return 0
  end
  return self.mana_regen_amp or self:GetAbility():GetSpecialValueFor("mana_regen_multiplier")
end

-- Doesn't stack with Kaya items
function modifier_item_ghost_king_bar_non_stacking_stats:GetModifierSpellAmplify_Percentage()
  local parent = self:GetParent()
  if parent:HasModifier("modifier_item_kaya") or parent:HasModifier("modifier_item_yasha_and_kaya") or parent:HasModifier("modifier_item_kaya_and_sange") or parent:HasModifier("modifier_item_ethereal_blade") then
    return 0
  end
  if parent:HasModifier("modifier_item_sacred_skull_non_stacking_stats") then
    return 0
  end
  return self.spell_amp or self:GetAbility():GetSpecialValueFor("spell_amp")
end

-- Doesn't stack with Kaya items
function modifier_item_ghost_king_bar_non_stacking_stats:GetModifierSpellLifestealRegenAmplify_Percentage()
  local parent = self:GetParent()
  if parent:HasModifier("modifier_item_kaya") or parent:HasModifier("modifier_item_yasha_and_kaya") or parent:HasModifier("modifier_item_kaya_and_sange") or parent:HasModifier("modifier_item_ethereal_blade") then
    return 0
  end
  if parent:HasModifier("modifier_item_sacred_skull_non_stacking_stats") then
    return 0
  end
  return self.spell_lifesteal_amp or self:GetAbility():GetSpecialValueFor("spell_lifesteal_amp")
end

---------------------------------------------------------------------------------------------------

modifier_item_ghost_king_bar_active = class(ModifierBaseClass)

function modifier_item_ghost_king_bar_active:IsHidden()
  return false
end

function modifier_item_ghost_king_bar_active:IsDebuff()
  return false
end

function modifier_item_ghost_king_bar_active:IsPurgable()
  return true
end

function modifier_item_ghost_king_bar_active:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.extra_spell_damage_percent = ability:GetSpecialValueFor("ethereal_damage_bonus")
    self.heal_amp = ability:GetSpecialValueFor("active_heal_amp")
    self.spell_lifesteal_amp = ability:GetSpecialValueFor("active_spell_lifesteal_amp")
    self.mana_regen_amp = ability:GetSpecialValueFor("active_mana_regen_amp")
  end

  --self:StartIntervalThink(FrameTime())
end

function modifier_item_ghost_king_bar_active:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.extra_spell_damage_percent = ability:GetSpecialValueFor("ethereal_damage_bonus")
    self.heal_amp = ability:GetSpecialValueFor("active_heal_amp")
    self.spell_lifesteal_amp = ability:GetSpecialValueFor("active_spell_lifesteal_amp")
    self.mana_regen_amp = ability:GetSpecialValueFor("active_mana_regen_amp")
  end
end

--function modifier_item_ghost_king_bar_active:OnIntervalThink()
  --local parent = self:GetParent()
  -- To prevent invicibility:
  --if parent:IsMagicImmune() then
    --self:Destroy()
  --end
--end

function modifier_item_ghost_king_bar_active:DeclareFunctions()
  return {
    --MODIFIER_PROPERTY_AVOID_DAMAGE,
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_DECREPIFY_UNIQUE,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE,
    MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
    MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE,
    MODIFIER_EVENT_ON_HEAL_RECEIVED,
  }
end

-- function modifier_item_ghost_king_bar_active:GetModifierAvoidDamage(event)
  -- if event.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK then
    -- return 1
  -- end

  -- return 0
-- end

function modifier_item_ghost_king_bar_active:GetModifierMagicalResistanceDecrepifyUnique()
  return self.extra_spell_damage_percent or self:GetAbility():GetSpecialValueFor("ethereal_damage_bonus")
end

function modifier_item_ghost_king_bar_active:GetAbsoluteNoDamagePhysical()
  return 1
end

function modifier_item_ghost_king_bar_active:GetModifierHealAmplify_PercentageSource()
  return self.heal_amp or self:GetAbility():GetSpecialValueFor("active_heal_amp")
end

function modifier_item_ghost_king_bar_active:GetModifierHealAmplify_PercentageTarget()
  return self.heal_amp or self:GetAbility():GetSpecialValueFor("active_heal_amp")
end

function modifier_item_ghost_king_bar_active:GetModifierSpellLifestealRegenAmplify_Percentage()
  return self.spell_lifesteal_amp or self:GetAbility():GetSpecialValueFor("active_spell_lifesteal_amp")
end

function modifier_item_ghost_king_bar_active:GetModifierMPRegenAmplify_Percentage()
  return self.mana_regen_amp or self:GetAbility():GetSpecialValueFor("active_mana_regen_amp")
end

if IsServer() then
  function modifier_item_ghost_king_bar_active:OnHealReceived(event)
    local parent = self:GetParent()
    local inflictor = event.inflictor -- Heal ability
    local unit = event.unit -- Healed unit
    --local amount = event.gain -- Amount healed

    local ghost_king_bar = self:GetAbility()
    if not ghost_king_bar or ghost_king_bar:IsNull() then
      return
    end

    -- Don't continue if healing entity/ability doesn't exist
    if not inflictor or inflictor:IsNull() then
      return
    end

    -- Don't continue if healed unit doesn't exist
    if not unit or unit:IsNull() then
      return
    end

    local function BuffHealedUnit()
      if not unit:HasModifier("modifier_item_ghost_king_bar_buff") then
        unit:AddNewModifier(parent, ghost_king_bar, "modifier_item_ghost_king_bar_buff", {duration = ghost_king_bar:GetSpecialValueFor("buff_duration")})
      end
    end

    if inflictor.GetAbilityName == nil then
      -- Inflictor is not an ability or item
      if parent ~= inflictor then
        -- Inflictor is not the parent -> parent is not the healer
        return
      end

      -- Apply buff to the unit
      BuffHealedUnit()
    else
      -- Inflictor is an ability
      local name = inflictor:GetAbilityName()
      local ability = parent:FindAbilityByName(name)
      if not ability then
        -- Parent doesn't have this ability or item -> parent is not the healer
        return
      end
      if ability:GetLevel() > 0 or ability:IsItem() then
        -- Parent has this ability or item with the same name as inflictor
        -- Check if it's exactly the same by comparing indexes
        if ability:entindex() == inflictor:entindex() then
          -- Indexes are the same -> parent is the healer
          -- if index of the ability changes randomly and this never happens, then thank you Valve
          -- Apply buff to the unit
          BuffHealedUnit()
        end
      end
    end
  end
end

function modifier_item_ghost_king_bar_active:CheckState()
  return {
    [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_DISARMED] = true,
  }
end

function modifier_item_ghost_king_bar_active:GetStatusEffectName()
  return "particles/status_fx/status_effect_ghost.vpcf"
end

function modifier_item_ghost_king_bar_active:StatusEffectPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA
end

function modifier_item_ghost_king_bar_active:GetTexture()
  return "custom/ghoststaff_1"
end

---------------------------------------------------------------------------------------------------

modifier_item_ghost_king_bar_buff = class(ModifierBaseClass)

function modifier_item_ghost_king_bar_buff:IsHidden()
  return false
end

function modifier_item_ghost_king_bar_buff:IsDebuff()
  return false
end

function modifier_item_ghost_king_bar_buff:IsPurgable()
  return true
end

function modifier_item_ghost_king_bar_buff:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.magic_resist = ability:GetSpecialValueFor("buff_magic_resistance")
    self.status_resist = ability:GetSpecialValueFor("buff_status_resistance")
    self.move_speed = ability:GetSpecialValueFor("buff_move_speed")
  end
end

function modifier_item_ghost_king_bar_buff:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.magic_resist = ability:GetSpecialValueFor("buff_magic_resistance")
    self.status_resist = ability:GetSpecialValueFor("buff_status_resistance")
    self.move_speed = ability:GetSpecialValueFor("buff_move_speed")
  end
end

function modifier_item_ghost_king_bar_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, -- GetModifierMagicalResistanceBonus
    MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING, -- GetModifierStatusResistanceStacking
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
  }
end

function modifier_item_ghost_king_bar_buff:GetModifierMagicalResistanceBonus()
  return self.magic_resist or self:GetAbility():GetSpecialValueFor("buff_magic_resistance")
end

function modifier_item_ghost_king_bar_buff:GetModifierStatusResistanceStacking()
  return self.status_resist or self:GetAbility():GetSpecialValueFor("buff_status_resistance")
end

function modifier_item_ghost_king_bar_buff:GetModifierMoveSpeedBonus_Percentage()
  return self.move_speed or self:GetAbility():GetSpecialValueFor("buff_move_speed")
end

function modifier_item_ghost_king_bar_buff:GetTexture()
  return "custom/ghoststaff_1"
end
