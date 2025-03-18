item_ghost_king_bar_1 = class(ItemBaseClass)

LinkLuaModifier("modifier_item_ghost_king_bar_passives", "items/ghost_king_bar.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ghost_king_bar_aura_effect", "items/ghost_king_bar.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ghost_king_bar_active", "items/ghost_king_bar.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ghost_king_bar_buff", "items/ghost_king_bar.lua", LUA_MODIFIER_MOTION_NONE)

function item_ghost_king_bar_1:GetIntrinsicModifierName()
  return "modifier_item_ghost_king_bar_passives"
end

function item_ghost_king_bar_1:OnSpellStart()
  local caster = self:GetCaster()

  -- Apply Ghost King Bar buff to caster (but only if they dont have spell immunity)
  if not caster:IsMagicImmune() then
    caster:AddNewModifier(caster, self, "modifier_item_ghost_king_bar_active", {duration = self:GetSpecialValueFor("duration")})
  end

  -- Emit Activation sound
  caster:EmitSound("DOTA_Item.GhostScepter.Activate")

  local current_charges = self:GetCurrentCharges()

  -- Restore hp and mana to all allies including the caster
  if current_charges > 0 then
    local amount_to_restore = current_charges * self:GetSpecialValueFor("active_restore_per_charge")
    local allies = FindUnitsInRadius(
      caster:GetTeamNumber(),
      caster:GetAbsOrigin(),
      nil,
      self:GetSpecialValueFor("active_radius"),
      DOTA_UNIT_TARGET_TEAM_FRIENDLY,
      bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
      DOTA_UNIT_TARGET_FLAG_NONE,
      FIND_ANY_ORDER,
      false
    )
    for _, unit in pairs(allies) do
      if unit and not unit:IsNull() then
        -- Restore health (it should work with heal amp)
        unit:Heal(amount_to_restore, self)
        -- Restore mana
        unit:GiveMana(amount_to_restore)
        -- Particle
        local particle = ParticleManager:CreateParticle("particles/items2_fx/magic_stick.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
        ParticleManager:SetParticleControl(particle, 0, unit:GetAbsOrigin())
        ParticleManager:SetParticleControl(particle, 1, Vector(10,0,0))
        ParticleManager:ReleaseParticleIndex(particle)
        -- Sound
        if unit ~= caster then
          unit:EmitSound("DOTA_Item.MagicWand.Activate")
        end
      end
    end
  end

  -- Trigger cd and spend charges on all Holy Lockets and Magic Wands
  local kv_cooldown = self:GetAbilityKeyValues().AbilityCooldown or 20
  for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
    local item = caster:GetItemInSlot(i)
    if item then
      local name = item:GetName()
      if name == "item_holy_locket" or name == "item_magic_wand" or name == "item_magic_stick" then
        item:StartCooldown(kv_cooldown*caster:GetCooldownReduction())
        item:SetCurrentCharges(0)
      end
    end
  end

  -- Spend charges
  self:SetCurrentCharges(0)
  caster.ghostKingBarChargesOAA = 0
end

item_ghost_king_bar_2 = item_ghost_king_bar_1
item_ghost_king_bar_3 = item_ghost_king_bar_1
item_ghost_king_bar_4 = item_ghost_king_bar_1
item_ghost_king_bar_5 = item_ghost_king_bar_1

---------------------------------------------------------------------------------------------------

modifier_item_ghost_king_bar_passives = class(ModifierBaseClass)

function modifier_item_ghost_king_bar_passives:IsHidden()
  return true
end

function modifier_item_ghost_king_bar_passives:IsDebuff()
  return false
end

function modifier_item_ghost_king_bar_passives:IsPurgable()
  return false
end

function modifier_item_ghost_king_bar_passives:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_ghost_king_bar_passives:OnCreated()
  self.interval = 0.1
  self.counter = 0
  self:OnRefresh()
  if IsServer() then
    self:StartIntervalThink(self.interval)
    local parent = self:GetParent()
    if parent.ghostKingBarChargesOAA and parent.ghostKingBarChargesOAA ~= 0 then
      local item = self:GetAbility()
      if item and not item:IsNull() then
        item:SetCurrentCharges(parent.ghostKingBarChargesOAA)
      end
    end
    -- Remove aura effect modifier from units in radius to force refresh
    local units = FindUnitsInRadius(
      parent:GetTeamNumber(),
      parent:GetAbsOrigin(),
      nil,
      self:GetAuraRadius(),
      self:GetAuraSearchTeam(),
      self:GetAuraSearchType(),
      DOTA_UNIT_TARGET_FLAG_NONE,
      FIND_ANY_ORDER,
      false
    )

    local function RemoveAuraEffect(unit)
      unit:RemoveModifierByName(self:GetModifierAura())
    end

    foreach(RemoveAuraEffect, units)
  end
end

function modifier_item_ghost_king_bar_passives:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.str = ability:GetSpecialValueFor("bonus_all_stats")
    self.agi = ability:GetSpecialValueFor("bonus_all_stats")
    self.int = ability:GetSpecialValueFor("bonus_all_stats")
    self.hp = ability:GetSpecialValueFor("bonus_health")
    self.mana = ability:GetSpecialValueFor("bonus_mana")
    self.heal_amp = ability:GetSpecialValueFor("heal_amp")
    self.aura_radius = ability:GetSpecialValueFor("aura_radius")
  end

  if IsServer() then
    self:OnIntervalThink()
  end
end

function modifier_item_ghost_king_bar_passives:OnIntervalThink()
  if self:IsFirstItemInInventory() then
    self:SetStackCount(2)

    -- Gaining charges over time
    local ability = self:GetAbility()
    local gain_charge_interval = ability:GetSpecialValueFor("charge_gain_timer")
    local max_charges = ability:GetSpecialValueFor("max_charges")
    local gain_charge_iteration = math.ceil(gain_charge_interval / self.interval)
    if self.counter % gain_charge_iteration == 0 and self.counter ~= 0 then
      -- Add a charge to the item
      ability:SetCurrentCharges(math.min(ability:GetCurrentCharges() + 1, max_charges))
      -- Add a charge to the hero
      local parent = self:GetParent()
      parent.ghostKingBarChargesOAA = ability:GetCurrentCharges()
      -- Reset counter just in case of overflow
      self.counter = 0
    end

    -- Increase counter
    self.counter = self.counter + 1
  else
    self:SetStackCount(1)
  end
end

function modifier_item_ghost_king_bar_passives:OnDestroy()
  if not IsServer() then
    return
  end

  local charges = 0
  local ability = self:GetAbility()
  local caster = self:GetCaster()
  if ability and not ability:IsNull() then
    if ability:GetCurrentCharges() >= charges then
      charges = ability:GetCurrentCharges()
    end
  end
  if caster and not caster:IsNull() then
    if not caster.ghostKingBarChargesOAA then
      caster.ghostKingBarChargesOAA = charges
    else
      caster.ghostKingBarChargesOAA = math.max(caster.ghostKingBarChargesOAA, charges)
    end
  end
end

function modifier_item_ghost_king_bar_passives:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_MANA_BONUS,
    MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE,
    MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
    MODIFIER_EVENT_ON_ABILITY_EXECUTED,
  }
end

function modifier_item_ghost_king_bar_passives:GetModifierBonusStats_Strength()
  return self.str or self:GetAbility():GetSpecialValueFor("bonus_all_stats")
end

function modifier_item_ghost_king_bar_passives:GetModifierBonusStats_Agility()
  return self.agi or self:GetAbility():GetSpecialValueFor("bonus_all_stats")
end

function modifier_item_ghost_king_bar_passives:GetModifierBonusStats_Intellect()
  return self.int or self:GetAbility():GetSpecialValueFor("bonus_all_stats")
end

function modifier_item_ghost_king_bar_passives:GetModifierHealthBonus()
  return self.hp or self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_ghost_king_bar_passives:GetModifierManaBonus()
  return self.mana or self:GetAbility():GetSpecialValueFor("bonus_mana")
end

function modifier_item_ghost_king_bar_passives:GetModifierHealAmplify_PercentageSource()
  if self:GetStackCount() == 2 then
    return self.heal_amp or self:GetAbility():GetSpecialValueFor("heal_amp")
  else
    return 0
  end
end

function modifier_item_ghost_king_bar_passives:GetModifierHealAmplify_PercentageTarget()
  if self:GetStackCount() == 2 then
    return self.heal_amp or self:GetAbility():GetSpecialValueFor("heal_amp")
  else
    return 0
  end
end

function modifier_item_ghost_king_bar_passives:IsAura()
  return true
end

function modifier_item_ghost_king_bar_passives:GetModifierAura()
  return "modifier_item_ghost_king_bar_aura_effect"
end

function modifier_item_ghost_king_bar_passives:GetAuraRadius()
  return self.aura_radius or self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_item_ghost_king_bar_passives:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_item_ghost_king_bar_passives:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
end

-- function modifier_item_ghost_king_bar_passives:GetAuraEntityReject(hTarget)
  -- return hTarget:HasModifier("modifier_item_headdress_aura")
-- end

-- Add charges when abilities are cast by visible enemies
if IsServer() then
  function modifier_item_ghost_king_bar_passives:OnAbilityExecuted(event)
    -- Only the first item will get charges
    if not self:IsFirstItemInInventory() then
      return
    end

    local parent = self:GetParent()
    local ability = self:GetAbility()
    local unit = event.unit

    -- Check if parent is dead
    if not parent or parent:IsNull() or not parent:IsAlive() then
      return
    end

    -- Uncomment the flag stuff if you don't want to gain charges from every enemy but just from visible enemies
    local filterResult = UnitFilter(
      unit,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_OTHER),
      DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, --bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, DOTA_UNIT_TARGET_FLAG_NO_INVIS),
      parent:GetTeamNumber()
    )

    local charge_radius = ability:GetSpecialValueFor("charge_radius")
    local distanceToUnit = (parent:GetAbsOrigin() - unit:GetAbsOrigin()):Length2D()
    local unitIsInRange = distanceToUnit <= charge_radius

    if filterResult == UF_SUCCESS and event.ability:ProcsMagicStick() and unitIsInRange then
      ability:SetCurrentCharges(math.min(ability:GetCurrentCharges() + 1, ability:GetSpecialValueFor("max_charges")))
      parent.ghostKingBarChargesOAA = ability:GetCurrentCharges()
    end
  end
end

---------------------------------------------------------------------------------------------------

modifier_item_ghost_king_bar_aura_effect = class({})

function modifier_item_ghost_king_bar_aura_effect:IsHidden() -- needs tooltip
  return self:GetParent():HasModifier("modifier_item_headdress_aura")
end

function modifier_item_ghost_king_bar_aura_effect:IsDebuff()
  return false
end

function modifier_item_ghost_king_bar_aura_effect:IsPurgable()
  return false
end

function modifier_item_ghost_king_bar_aura_effect:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.hp_regen = ability:GetSpecialValueFor("aura_health_regen")
  end
end

modifier_item_ghost_king_bar_aura_effect.OnRefresh = modifier_item_ghost_king_bar_aura_effect.OnCreated

function modifier_item_ghost_king_bar_aura_effect:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
  }
end

function modifier_item_ghost_king_bar_aura_effect:GetModifierConstantHealthRegen()
  if self:GetParent():HasModifier("modifier_item_headdress_aura") then
    return 0
  end
  return self.hp_regen or self:GetAbility():GetSpecialValueFor("aura_health_regen")
end

function modifier_item_ghost_king_bar_aura_effect:GetTexture()
  return "item_headdress"
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
  end

  --self:StartIntervalThink(FrameTime())
end

modifier_item_ghost_king_bar_active.OnRefresh = modifier_item_ghost_king_bar_active.OnCreated

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

if IsServer() then
  function modifier_item_ghost_king_bar_active:OnHealReceived(event)
    local parent = self:GetParent()
    local inflictor = event.inflictor -- Heal ability
    local unit = event.unit -- Healed unit
    local amount = event.gain -- Amount healed

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

    if amount <= 0 then
      return
    end

    local function BuffHealedUnit()
      unit:AddNewModifier(parent, ghost_king_bar, "modifier_item_ghost_king_bar_buff", {duration = ghost_king_bar:GetSpecialValueFor("buff_duration")})
    end

    -- We check what is inflictor just in case Valve randomly changes inflictor handle type or if someone put a caster instead of the ability when using the Heal method
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
        -- Parent doesn't have this ability
        -- Check items:
        local found_item
        local max_slot = DOTA_ITEM_SLOT_6
        if parent:HasModifier("modifier_spoons_stash_oaa") then
          max_slot = DOTA_ITEM_SLOT_9
        end
        for i = DOTA_ITEM_SLOT_1, max_slot do
          local item = parent:GetItemInSlot(i)
          if item and item:GetName() == name then
            found_item = true
            ability = item
            break
          end
        end
        if not found_item then
          --  Parent doesn't have this item -> parent is not the healer
          return
        end
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
  local state = {
    [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
  }

  -- Check for Muerta innate
  if not self:GetParent():HasModifier("modifier_muerta_supernatural") then
    state[MODIFIER_STATE_DISARMED] = true
  end

  return state
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

modifier_item_ghost_king_bar_buff.OnRefresh = modifier_item_ghost_king_bar_buff.OnCreated

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
