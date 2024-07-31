terrorblade_conjure_image_oaa = class(AbilityBaseClass)

LinkLuaModifier("modifier_terrorblade_illusion_oaa", "abilities/oaa_terrorblade_conjure_image.lua", LUA_MODIFIER_MOTION_NONE)

function terrorblade_conjure_image_oaa:IsStealable()
  return true
end

function terrorblade_conjure_image_oaa:IsHiddenWhenStolen()
  return false
end

function terrorblade_conjure_image_oaa:CastFilterResultTarget(target)
  local default_result = self.BaseClass.CastFilterResultTarget(self, target)

  if target:IsOAABoss() or target:IsCourier() then
    return UF_FAIL_CUSTOM
  end

  return default_result
end

function terrorblade_conjure_image_oaa:GetCustomCastErrorTarget(target)
	if target:IsOAABoss() or target:IsCourier() then
		return "#dota_hud_error_cant_cast_on_other"
	end
	return ""
end

function terrorblade_conjure_image_oaa:OnSpellStart()
  local target = self:GetCursorTarget()
  local caster = self:GetCaster()

  -- Check if target exists
  if not target or target:IsNull() then
    return
  end

  -- If cast filter is bypassed
  if target:IsOAABoss() or target:IsCourier() then
    return
  end

  -- Checking if target has spell block, if target has spell block, there is no need to execute the spell
  if (not target:TriggerSpellAbsorb(self)) or (target:GetTeamNumber() == caster:GetTeamNumber()) then
    -- Target is a friend or an enemy that doesn't have Spell Block
    local duration = self:GetSpecialValueFor("illusion_duration")
    local damage_dealt = self:GetSpecialValueFor("illusion_outgoing_damage")
    local damage_taken = self:GetSpecialValueFor("illusion_incoming_damage")

    self:CreateIllusion(caster, target, duration, nil, damage_dealt, damage_taken, true)

    -- Sound on the target
    target:EmitSound("Hero_Terrorblade.ConjureImage")
  end
end

function terrorblade_conjure_image_oaa:ProcsMagicStick()
	return true
end

function terrorblade_conjure_image_oaa:CreateIllusion(caster, target, duration, position, damage_dealt, damage_taken, controllable)
  if caster:IsNull() or target:IsNull() or duration == nil then
    return
  end

  local ability = self
  local playerID = caster:GetPlayerID()
  local unit_name = target:GetUnitName()
  local unit_HP = target:GetHealth()
  local unit_MP = target:GetMana()
  local owner = caster:GetOwner() or caster
  local origin = position or target:GetAbsOrigin() + RandomVector(150)
  local illusion_damage_dealt = damage_dealt or 0
  local illusion_damage_taken = damage_taken or 0
  local unit_ability_count = math.max(target:GetAbilityCount(), DOTA_MAX_ABILITIES)

  if controllable == nil then
    controllable = true
  end

  -- Modifiers that we want to apply but don't have AllowIllusionDuplicate or their GetRemainingTime is 0
  local wanted_modifiers = {
    "modifier_item_armlet_unholy_strength",
    "modifier_alchemist_chemical_rage",
    "modifier_terrorblade_metamorphosis",
  }

  -- Modifiers that we DON'T want to apply - modifiers that cause bugs
  local modifier_ignore_list = {
    "modifier_terrorblade_metamorphosis_transform_aura",
    "modifier_terrorblade_metamorphosis_transform_aura_applier",
    "modifier_meepo_divided_we_stand",
    "modifier_vengefulspirit_hybrid_special",
    "modifier_morphling_replicate_illusion",
    "modifier_grimstroke_scepter_buff",
  }

  -- Abilities that cause bugs
  local ability_ignore_list = {
    "meepo_divided_we_stand",
    "skeleton_king_reincarnation",
    "special_bonus_reincarnation_200",
    "roshan_spell_block",
    "roshan_bash",
    "roshan_slam",
    "roshan_inherent_buffs",
    "roshan_devotion",
    "ability_capture",
    "abyssal_underlord_portal_warp",
    "twin_gate_portal_warp",
    "ability_lamp_use",
    "ability_pluck_famango",
  }

  local illusion
  if target:IsRealHero() or target:IsSpiritBearOAA() or target:IsTempestDouble() or target:IsClone() then
    local illu_table = {
      outgoing_damage = illusion_damage_dealt,
      incoming_damage = illusion_damage_taken,
      bounty_base = 1,
      bounty_growth = 4,
      outgoing_damage_structure = illusion_damage_dealt,
      outgoing_damage_roshan = illusion_damage_dealt,
      duration = duration,
    }

    -- Use Valve's function
    local illusions = CreateIllusions(caster, target, illu_table, 1, target:GetHullRadius(), false, true)
    illusion = illusions[1]
  elseif target:IsHero() then
    -- target is a hero creep or an illusion (of a hero or a creep), that's how IsHero() works -> weird I know
    local unit_level = target:GetLevel()

    -- handle_UnitOwner needs to be nil, else it will crash the game.
    illusion = CreateUnitByName(unit_name, origin, true, caster, nil, caster:GetTeamNumber())
    illusion:SetPlayerID(playerID)
    if controllable then
      illusion:SetControllableByPlayer(playerID, true)
    end
    illusion:SetOwner(owner)
    FindClearSpaceForUnit(illusion, origin, false)

    -- Level Up the illusion to the same level as the hero
    for i = 1, unit_level-1 do
      illusion:HeroLevelUp(false) -- false because we don't want to see level up effects
    end

    -- Set the skill points to 0 and learn the skills of the caster
    illusion:SetAbilityPoints(0)
    for ability_slot = 0, unit_ability_count-1 do
      local current_ability = target:GetAbilityByIndex(ability_slot)
      if current_ability then
        local current_ability_level = current_ability:GetLevel()
        local current_ability_name = current_ability:GetAbilityName()
        local illusion_ability = illusion:FindAbilityByName(current_ability_name)
        if illusion_ability then
          local skip = false
          for i = 1, #ability_ignore_list do
            if current_ability_name == ability_ignore_list[i] then
              skip = true
            end
          end
          if not skip then
            illusion_ability:SetLevel(current_ability_level)
          end
        end
      end
    end

    -- Recreate the items of the target to be the same on illusion
    for item_slot = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
      local item = target:GetItemInSlot(item_slot)
      if item then
        local item_name = item:GetName()
        local new_item = CreateItem(item_name, illusion, illusion)
        illusion:AddItem(new_item)
        new_item:SetStacksWithOtherOwners(true)
        new_item:SetPurchaser(nil)
        if new_item:RequiresCharges() then
          new_item:SetCurrentCharges(item:GetCurrentCharges())
        end
        if new_item:IsToggle() and item:GetToggleState() then
          new_item:ToggleAbility()
        end
      end
    end

    for _, modifier in ipairs(target:FindAllModifiers()) do
      local modifier_name = modifier:GetName()
      -- This doesn't work for vanilla modifiers because they don't have AllowIllusionDuplicate
      if modifier.AllowIllusionDuplicate and modifier:AllowIllusionDuplicate() and modifier:GetDuration() ~= -1 then
        local skip = false
        for i = 1, #modifier_ignore_list do
          if modifier_name == modifier_ignore_list[i] then
            skip = true
          end
        end
        if not skip then
          illusion:AddNewModifier(modifier:GetCaster(), modifier:GetAbility(), modifier_name, { duration = modifier:GetRemainingTime() })
        end
      end

      for i = 1, #wanted_modifiers do
        if modifier_name == wanted_modifiers[i] then
          illusion:AddNewModifier(modifier:GetCaster(), modifier:GetAbility(), modifier_name, { duration = modifier:GetDuration() })
        end
      end
    end

    -- Preventing dropping and selling items in inventory
    illusion:SetHasInventory(false)
    illusion:SetCanSellItems(false)

    -- Set the unit as an illusion
    -- modifier_illusion controls many illusion properties like +Green damage not adding to the unit damage, not being able to cast spells and the team-only blue particle
    illusion:AddNewModifier(caster, ability, "modifier_illusion", {duration = duration, outgoing_damage = illusion_damage_dealt, incoming_damage = illusion_damage_taken})

    -- Without MakeIllusion the unit counts as a hero, e.g. if it dies to neutrals it says killed by neutrals, it respawns, etc.
    illusion:MakeIllusion()
  else
    -- target is a creep and not an illusion of a creep
    illusion = CreateUnitByName(unit_name, origin, true, caster, caster, caster:GetTeamNumber())
    if controllable then
      illusion:SetControllableByPlayer(playerID, true)
    end
    illusion:SetOwner(owner)
    FindClearSpaceForUnit(illusion, origin, false)

    for ability_slot = 0, unit_ability_count-1 do
      local current_ability = target:GetAbilityByIndex(ability_slot)
      if current_ability then
        local current_ability_level = current_ability:GetLevel()
        local current_ability_name = current_ability:GetAbilityName()
        local illusion_ability = illusion:FindAbilityByName(current_ability_name)
        if illusion_ability then
          local skip = false
          for i = 1, #ability_ignore_list do
            if illusion_ability:GetAbilityName() == ability_ignore_list[i] then
              skip = true
            end
          end
          if not skip then
            illusion_ability:SetLevel(current_ability_level)
          else
            illusion:RemoveAbility(illusion_ability:GetAbilityName())
          end
        end
      end
    end

    for _, modifier in ipairs(target:FindAllModifiers()) do
      local modifier_name = modifier:GetName()
      if modifier.AllowIllusionDuplicate and modifier:AllowIllusionDuplicate() and modifier:GetDuration() ~= -1 then
        local skip = false
        for i = 1, #modifier_ignore_list do
          if modifier_name == modifier_ignore_list[i] then
            skip = true
          end
        end
        if not skip then
          illusion:AddNewModifier(modifier:GetCaster(), modifier:GetAbility(), modifier_name, { duration = modifier:GetRemainingTime() })
        end
      end

      for i = 1, #wanted_modifiers do
        if modifier_name == wanted_modifiers[i] then
          illusion:AddNewModifier(modifier:GetCaster(), modifier:GetAbility(), modifier_name, { duration = modifier:GetDuration() })
        end
      end
    end

    -- Important for creeps
    local max_hp = target:GetMaxHealth()
    illusion:SetBaseMaxHealth(max_hp)
    illusion:SetMaxHealth(max_hp)

    illusion:AddNewModifier(caster, ability, "modifier_illusion", {duration = duration, outgoing_damage = illusion_damage_dealt, incoming_damage = illusion_damage_taken})
    illusion:AddNewModifier(caster, ability, "modifier_kill", {duration = duration})

    illusion:MakeIllusion()
  end

  -- Setting health and mana to be the same as the target with items, abilities, buffs, debuffs...
  illusion:SetHealth(unit_HP)
  illusion:SetMana(unit_MP)

  -- Visually distinct illusions
  illusion:AddNewModifier(caster, ability, "modifier_terrorblade_illusion_oaa", {duration = duration})

  -- Garbage collector
  illusion:AddNewModifier(caster, ability, "modifier_generic_dead_tracker_oaa", {duration = duration + MANUAL_GARBAGE_CLEANING_TIME})
end

---------------------------------------------------------------------------------------------------

modifier_terrorblade_illusion_oaa = class(ModifierBaseClass)

function modifier_terrorblade_illusion_oaa:IsHidden()
  return true
end

function modifier_terrorblade_illusion_oaa:IsDebuff()
  return false
end

function modifier_terrorblade_illusion_oaa:IsPurgable()
  return false
end

function modifier_terrorblade_illusion_oaa:GetStatusEffectName()
  return "particles/status_fx/status_effect_terrorblade_reflection.vpcf"
end

function modifier_terrorblade_illusion_oaa:StatusEffectPriority()
  return 100000
end
