LinkLuaModifier("modifier_intrinsic_multiplexer", "modifiers/modifier_intrinsic_multiplexer.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_aghanims_talents", "items/aghanims.lua", LUA_MODIFIER_MOTION_NONE)
-- Modifiers for problematic talents
LinkLuaModifier("modifier_special_bonus_sohei_wholeness_allycast", "abilities/sohei/sohei_wholeness_of_body.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_special_bonus_unique_monkey_king_armor", "abilities/oaa_wukongs_command.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_special_bonus_unique_monkey_king_ring", "abilities/oaa_wukongs_command.lua", LUA_MODIFIER_MOTION_NONE)

item_aghanims_scepter_2 = class(ItemBaseClass)

function item_aghanims_scepter_2:GetIntrinsicModifierName()
  return "modifier_intrinsic_multiplexer"
end

function item_aghanims_scepter_2:GetIntrinsicModifierNames()
  return {
    "modifier_item_ultimate_scepter", -- handles normal aghs effect and stats
    "modifier_item_aghanims_talents"
  }
end

item_aghanims_scepter_3 = item_aghanims_scepter_2
item_aghanims_scepter_4 = item_aghanims_scepter_2
item_aghanims_scepter_5 = item_aghanims_scepter_2

------------------------------------------------------------------------

modifier_item_aghanims_talents = class(ModifierBaseClass)

function modifier_item_aghanims_talents:OnCreated()
  if IsServer () then
    local parent = self:GetParent()
    local noDropHeroes = {
      npc_dota_hero_undying = true
    }
    self.isRunning = true

    self.aghsPower = 0

    for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
      local item = parent:GetItemInSlot(i)

      if item then
        if string.sub(item:GetName(), 0, 22) == 'item_aghanims_scepter_' then
          local level = tonumber(string.sub(item:GetName(), 23))
          if level > self.aghsPower then
            self.aghsPower = level
          end
        end
      end
    end

    -- print('Found an aghs of power ' .. self.aghsPower)

    -- Make Talent Agh's undroppable for certain heroes
    if noDropHeroes[parent:GetName()] and self.aghsPower > 1 then
      local item = self:GetAbility()
      item:SetDroppable(false)
      item:SetSellable(false)
    end
    self:StartIntervalThink(1)
  end
end
modifier_item_aghanims_talents.OnRefresh = modifier_item_aghanims_talents.OnCreated

function modifier_item_aghanims_talents:IsHidden()
  return true
end

function modifier_item_aghanims_talents:IsPurgable()
  return false
end

function modifier_item_aghanims_talents:RemoveOnDeath()
  return false
end

function modifier_item_aghanims_talents:OnDestroy()
  if IsServer () then
    self.isRunning = false
    self:SetTalents({})
  end
end

function modifier_item_aghanims_talents:OnIntervalThink()
  if not self.isRunning then
    self:SetTalents({})
    self:StartIntervalThink(-1)
    return
  end

  local caster = self:GetParent()

  self:SetTalents({
    [10] = self.aghsPower > 1,
    [15] = self.aghsPower > 2,
    [20] = self.aghsPower > 3,
    [25] = self.aghsPower > 4,
  })
end

function modifier_item_aghanims_talents:SetTalents(tree)
  -- 10 - 17
  -- input is { [10] = true, [15] = true, ... }
  local talentOverrides = {}
  local parent = self:GetParent()
  local function setTalentLevel (level, leftAbility, rightAbility, claim)
    if not leftAbility or not rightAbility then
      -- print('No ability for index ' .. leftIndex .. ', ' .. rightIndex)
      return
    end
    local leftLevel = leftAbility:GetLevel()
    local rightLevel = rightAbility:GetLevel()
    -- print (leftAbility:GetName() .. ' vs ' .. rightAbility:GetName())
    if leftLevel == 0 and rightLevel == 0 then
      -- the player hasn't chosen a talent yet
      return
    end
    if leftLevel ~= rightLevel then
      -- they have chosen a talent and it's the only one skilled
      if leftLevel == 0 then
        parent['talentChoice' .. level] = 'right'
      elseif rightLevel == 0 then
        parent['talentChoice' .. level] = 'left'
      end
    elseif claim then
      -- both abilities are upgraded
      -- print(" both abilities are upgraded already")
      return
    end
    -- make sure our talent selection has been made
    assert(
      parent['talentChoice' .. level] == 'left' or parent['talentChoice' .. level] == 'right',
      'Trying to update talent but talent choice was let through!'
    )

    local problematic_talents ={
      {"special_bonus_sohei_wholeness_allycast", "modifier_special_bonus_sohei_wholeness_allycast"},
      {"special_bonus_unique_monkey_king_4", "modifier_special_bonus_unique_monkey_king_armor"},
      {"special_bonus_unique_monkey_king_6", "modifier_special_bonus_unique_monkey_king_ring"},
      {"special_bonus_unique_hero_name", "modifier_special_bonus_unique_hero_name"}
    }

    if claim then
      if leftLevel == 0 then
        leftAbility:SetLevel(1)
        -- Check if this talent is on problematic list, add modifier if true
        for i = 1, #problematic_talents do
          local talent = problematic_talents[i]
          local leftAbilityName = leftAbility:GetName()
          if leftAbilityName == talent[1] then
            local talent_ability = parent:FindAbilityByName(leftAbilityName)
            if talent_ability then
              local talent_modifier = talent[2]
              parent:AddNewModifier(parent, talent_ability, talent_modifier, {})
            end
          end
        end

      end
      if rightLevel == 0 then
        rightAbility:SetLevel(1)
        -- Check if this talent is on problematic list, add modifier if true
        for i = 1, #problematic_talents do
          local talent = problematic_talents[i]
          local rightAbilityName = rightAbility:GetName()
          if rightAbilityName == talent[1] then
            local talent_ability = parent:FindAbilityByName(rightAbilityName)
            if talent_ability then
              local talent_modifier = talent[2]
              parent:AddNewModifier(parent, talent_ability, talent_modifier, {})
            end
          end
        end

      end
    else
      -- print ('disabling talents')
      if parent['talentChoice' .. level] == 'left' then
        if rightLevel ~= 0 then
          rightAbility:SetLevel(0)
          parent:RemoveModifierByName(self:GetTalentModifier(rightAbility:GetName()))
        end
      else
        if leftLevel ~= 0 then
          leftAbility:SetLevel(0)
          parent:RemoveModifierByName(self:GetTalentModifier(leftAbility:GetName()))
        end
      end
    end

    local player = PlayerResource:GetPlayer(parent:GetPlayerID());

    if (parent['talentChoice' .. level] == 'left' or parent['talentChoice' .. level] == 'right') then
      CustomGameEventManager:Send_ServerToPlayer(player, "oaa_scepter_upgrade",
      {
        IsRightSide = parent['talentChoice' .. level] == 'left',
        IsUpgrade = claim,
        Level = level
      })
    end
  end

  local abilityTable = {}

  for abilityIndex = 0, parent:GetAbilityCount() - 1 do
    local ability = parent:GetAbilityByIndex(abilityIndex)
    if ability and ability:IsAttributeBonus() then
      abilityTable[#abilityTable + 1] = ability
    end
  end


  setTalentLevel("10", abilityTable[2], abilityTable[1], tree[10])
  setTalentLevel("15", abilityTable[4], abilityTable[3], tree[15])
  setTalentLevel("20", abilityTable[6], abilityTable[5], tree[20])
  setTalentLevel("25", abilityTable[8], abilityTable[7], tree[25])
end

function modifier_item_aghanims_talents:GetTalentModifier(name)
  -- Map of special_bonus names to modifier names for Talents that don't follow the pattern
  local exceptionBonuses = {
    special_bonus_spell_immunity = "modifier_special_bonus_spell_immunity",
    special_bonus_haste = "modifier_special_bonus_haste",
    special_bonus_truestrike = "modifier_special_bonus_truestrike",
    special_bonus_unique_morphling_4 = "modifier_special_bonus_unique_morphling_4",
    special_bonus_unique_treant_3 = "modifier_special_bonus_unique_treant_3",
    special_bonus_unique_warlock_1 = "modifier_special_bonus_unique_warlock_1",
    special_bonus_unique_warlock_2 = "modifier_special_bonus_unique_warlock_2",
    special_bonus_unique_undying_3 = "modifier_undying_tombstone_death_trigger",
    special_bonus_sohei_wholeness_allycast = "modifier_special_bonus_sohei_wholeness_allycast",
    special_bonus_unique_monkey_king_4 = "modifier_special_bonus_unique_monkey_king_armor",
    special_bonus_unique_monkey_king_6 = "modifier_special_bonus_unique_monkey_king_ring"
  }

  if exceptionBonuses[name] then
    return exceptionBonuses[name]
  end
  -- Handle crit specially as it has a unique pattern
  if string.find(name, "_crit_") then
    return "modifier_special_bonus_crit"
  end

  -- Cut out the last underscore and everything following it
  local chopBonusName = string.match(name, "(.*)_")

  return "modifier_" .. chopBonusName
end
