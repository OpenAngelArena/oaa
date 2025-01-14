
LinkLuaModifier("modifier_item_aghanims_talents", "items/aghanims.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aghanim_talent_oaa_10", "components/abilities/custom_talent_system.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aghanim_talent_oaa_15", "components/abilities/custom_talent_system.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aghanim_talent_oaa_20", "components/abilities/custom_talent_system.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aghanim_talent_oaa_25", "components/abilities/custom_talent_system.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_aghanims_scepter_oaa_consumed", "items/aghanims.lua", LUA_MODIFIER_MOTION_NONE)

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

---------------------------------------------------------------------------------------------------
-- Custom Aghanim Blessing with stats and talents
item_aghanims_scepter_6 = item_aghanims_scepter_5

function item_aghanims_scepter_6:OnSpellStart()
  local caster = self:GetCaster()

  -- Prevent Tempest Double abuse
  if caster:IsTempestDouble() then
    return
  end

  -- Stats for consumed item
  local stats = self:GetSpecialValueFor("bonus_all_stats")
  local hp = self:GetSpecialValueFor("bonus_health")
  local mana = self:GetSpecialValueFor("bonus_mana")

  local table_to_send = {
    stats = stats,
    hp = hp,
    mana = mana,
  }

  if not caster:HasModifier("modifier_item_aghanims_scepter_oaa_consumed") then
    -- Add stats
    caster:AddNewModifier(caster, self, "modifier_item_aghanims_scepter_oaa_consumed", table_to_send)

    -- Add vanilla Aghanim Blessing buff
    if not caster:HasModifier("modifier_item_ultimate_scepter_consumed") then
      caster:AddNewModifier(caster, nil, "modifier_item_ultimate_scepter_consumed", {})
    end

    -- Add aghanim talents
    caster:AddNewModifier(caster, self, "modifier_aghanim_talent_oaa_10", {})
    caster:AddNewModifier(caster, self, "modifier_aghanim_talent_oaa_15", {})
    caster:AddNewModifier(caster, self, "modifier_aghanim_talent_oaa_20", {})
    caster:AddNewModifier(caster, self, "modifier_aghanim_talent_oaa_25", {})

    -- Sound
    caster:EmitSound("DOTA_Item.IronTalon.Activate")

    -- Consume the item
    self:SpendCharge(0.1) -- Removes the item without errors or crashes, and the modifiers lose the ability reference
  end
end

---------------------------------------------------------------------------------------------------

modifier_item_aghanims_talents = class(ModifierBaseClass)

function modifier_item_aghanims_talents:IsHidden()
  return true
end

function modifier_item_aghanims_talents:IsPurgable()
  return false
end

function modifier_item_aghanims_talents:RemoveOnDeath()
  return false
end

function modifier_item_aghanims_talents:GetAghsPower()
  local parent = self:GetParent()
  local aghsPower = 0
  for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
    local item = parent:GetItemInSlot(i)
    if item then
      if string.sub(item:GetName(), 0, 22) == 'item_aghanims_scepter_' then
        local level = tonumber(string.sub(item:GetName(), 23))
        if level > aghsPower then
          aghsPower = level
        end
      end
    end
  end

  return aghsPower
end

function modifier_item_aghanims_talents:OnCreated()
  if IsServer () then
    local parent = self:GetParent()
    local noDropHeroes = {}
    self.isRunning = true

    -- Make Talent Agh's undroppable for certain heroes
    if noDropHeroes[parent:GetName()] and self:GetAghsPower() > 1 then
      local aghanim_scepter = self:GetAbility()
      aghanim_scepter:SetDroppable(false)
      aghanim_scepter:SetSellable(false)
    end
    self:StartIntervalThink(1)
  end
end

modifier_item_aghanims_talents.OnRefresh = modifier_item_aghanims_talents.OnCreated

function modifier_item_aghanims_talents:OnIntervalThink()
  local parent = self:GetParent()
  local aghanim_scepter = self:GetAbility()

  -- Check if needed stuff exists
  if not parent or parent:IsNull() or not aghanim_scepter or aghanim_scepter:IsNull() then
    return
  end

  -- Check if parent has custom Aghanim Blessing that provides all aghanim talents
  if parent:HasModifier("modifier_item_aghanims_scepter_oaa_consumed") then
    -- Stop thinking and don't try to remove or readd aghanim talents
    self:StartIntervalThink(-1)
    return
  end

  if not self.isRunning then
    parent:RemoveModifierByName("modifier_aghanim_talent_oaa_10")
    parent:RemoveModifierByName("modifier_aghanim_talent_oaa_15")
    parent:RemoveModifierByName("modifier_aghanim_talent_oaa_20")
    parent:RemoveModifierByName("modifier_aghanim_talent_oaa_25")
    --self:SetTalents({})
    self:StartIntervalThink(-1)
    return
  end

  -- AddNewModifier doesn't work for dead units
  if not parent:IsAlive() then
    return
  end

  local aghsPower = self:GetAghsPower()

  if aghsPower > 1 and not parent:HasModifier("modifier_aghanim_talent_oaa_10") then
    parent:AddNewModifier(parent, aghanim_scepter, "modifier_aghanim_talent_oaa_10", {})
  end

  if aghsPower > 2 and not parent:HasModifier("modifier_aghanim_talent_oaa_15") then
    parent:AddNewModifier(parent, aghanim_scepter, "modifier_aghanim_talent_oaa_15", {})
  end

  if aghsPower > 3 and not parent:HasModifier("modifier_aghanim_talent_oaa_20") then
    parent:AddNewModifier(parent, aghanim_scepter, "modifier_aghanim_talent_oaa_20", {})
  end

  if aghsPower > 4 and not parent:HasModifier("modifier_aghanim_talent_oaa_25") then
    parent:AddNewModifier(parent, aghanim_scepter, "modifier_aghanim_talent_oaa_25", {})
  end

  -- self:SetTalents({
    -- [10] = aghsPower > 1,
    -- [15] = aghsPower > 2,
    -- [20] = aghsPower > 3,
    -- [25] = aghsPower > 4,
  -- })
end

--[[
function modifier_item_aghanims_talents:SetTalents(tree)
  -- 10 - 17
  -- input is { [10] = true, [15] = true, ... }
  local parent = self:GetParent()
  if parent:GetLevel() >= 50 then
    tree = {
      [10] = true,
      [15] = true,
      [20] = true,
      [25] = true,
    }
  end
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

    local problematic_talents = {
      {"special_bonus_unique_hero_name", "modifier_special_bonus_unique_hero_name"},
    }

    if claim then
      if leftLevel == 0 then
        leftAbility:SetLevel(1)
        leftAbility.granted_with_oaa_scepter = true
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
        rightAbility.granted_with_oaa_scepter = true
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
          rightAbility.granted_with_oaa_scepter = nil
          parent:RemoveModifierByName(AbilityLevels:GetTalentModifier(rightAbility:GetName()))
        end
      else
        if leftLevel ~= 0 then
          leftAbility:SetLevel(0)
          leftAbility.granted_with_oaa_scepter = nil
          parent:RemoveModifierByName(AbilityLevels:GetTalentModifier(leftAbility:GetName()))
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
    if ability and IsTalentCustom(ability) then
      abilityTable[#abilityTable + 1] = ability
    end
  end

  setTalentLevel("10", abilityTable[2], abilityTable[1], tree[10])
  setTalentLevel("15", abilityTable[4], abilityTable[3], tree[15])
  setTalentLevel("20", abilityTable[6], abilityTable[5], tree[20])
  setTalentLevel("25", abilityTable[8], abilityTable[7], tree[25])
end
]]

function modifier_item_aghanims_talents:OnDestroy()
  if IsServer () then
    self.isRunning = false
    --self:SetTalents({})
  end
end

---------------------------------------------------------------------------------------------------

modifier_item_aghanims_scepter_oaa_consumed = class({})

function modifier_item_aghanims_scepter_oaa_consumed:IsHidden()
  return false
end

function modifier_item_aghanims_scepter_oaa_consumed:IsDebuff()
  return false
end

function modifier_item_aghanims_scepter_oaa_consumed:IsPurgable()
  return false
end

function modifier_item_aghanims_scepter_oaa_consumed:RemoveOnDeath()
  return false
end

function modifier_item_aghanims_scepter_oaa_consumed:GetTexture()
  return "custom/aghanim_melter"
end

function modifier_item_aghanims_scepter_oaa_consumed:OnCreated(event)
  if IsServer() then
    self.stats = event.stats
    self.hp = event.hp
    self.mana = event.mana
    self:SetHasCustomTransmitterData(true)
  end
end

function modifier_item_aghanims_scepter_oaa_consumed:OnRefresh(event)
  if IsServer() then
    self.stats = self.stats or event.stats
    self.hp = self.hp or event.hp
    self.mana = self.mana or event.mana
    self:SendBuffRefreshToClients()
  end
end

-- server-only function that is called whenever SetHasCustomTransmitterData(true) or SendBuffRefreshToClients() is called
function modifier_item_aghanims_scepter_oaa_consumed:AddCustomTransmitterData()
  return {
    stats = self.stats,
    hp = self.hp,
    mana = self.mana,
  }
end

-- client-only function that is called with the table returned by AddCustomTransmitterData()
function modifier_item_aghanims_scepter_oaa_consumed:HandleCustomTransmitterData(data)
  self.stats = data.stats
  self.hp = data.hp
  self.mana = data.mana
end

function modifier_item_aghanims_scepter_oaa_consumed:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_MANA_BONUS,
  }
end

function modifier_item_aghanims_scepter_oaa_consumed:GetModifierBonusStats_Strength()
  return self.stats
end

function modifier_item_aghanims_scepter_oaa_consumed:GetModifierBonusStats_Agility()
  return self.stats
end

function modifier_item_aghanims_scepter_oaa_consumed:GetModifierBonusStats_Intellect()
  return self.stats
end

function modifier_item_aghanims_scepter_oaa_consumed:GetModifierHealthBonus()
  return self.hp
end

function modifier_item_aghanims_scepter_oaa_consumed:GetModifierManaBonus()
  return self.mana
end
