LinkLuaModifier("modifier_intrinsic_multiplexer", "modifiers/modifier_intrinsic_multiplexer.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_aghanims_talents", "items/aghanims.lua", LUA_MODIFIER_MOTION_NONE)

item_ultimate_scepter_1 = class(ItemBaseClass)

function item_ultimate_scepter_1:GetIntrinsicModifierName()
  return "modifier_intrinsic_multiplexer"
end

function item_ultimate_scepter_1:GetIntrinsicModifierNames()
  return {
    "modifier_item_ultimate_scepter", -- handles normal aghs effect and stats
    "modifier_item_aghanims_talents"
  }
end

item_ultimate_scepter_2 = item_ultimate_scepter_1
item_ultimate_scepter_3 = item_ultimate_scepter_1
item_ultimate_scepter_4 = item_ultimate_scepter_1
item_ultimate_scepter_5 = item_ultimate_scepter_1

------------------------------------------------------------------------

modifier_item_aghanims_talents = class(ModifierBaseClass)

function modifier_item_aghanims_talents:OnCreated()
  if IsServer () then
    local caster = self:GetParent()

    self.isRunning = true

    self.aghsPower = 0

    for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
      local item = caster:GetItemInSlot(i)

      if item then
        if string.sub(item:GetName(), 0, 22) == 'item_ultimate_scepter_' then
          local level = tonumber(string.sub(item:GetName(), 23))
          if level > self.aghsPower then
            self.aghsPower = level
          end
        end
      end
    end

    -- print('Found an aghs of power ' .. self.aghsPower)

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

function modifier_item_aghanims_talents:OnDestroy()
  if IsServer () then
    self.isRunning = false
    self:SetTalents({})
  end
end

if IsServer() then
  function modifier_item_aghanims_talents:DeclareFunctions()
    return {
      MODIFIER_PROPERTY_HEALTH_BONUS, -- GetModifierHealthBonus
      MODIFIER_PROPERTY_MANA_BONUS , -- GetModifierManaBonus
      MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT, -- GetModifierMoveSpeedBonus_Constant
    }
  end

  function modifier_item_aghanims_talents:GetModifierHealthBonus()
    return self.hp or 0
  end

  function modifier_item_aghanims_talents:GetModifierManaBonus()
    return self.mp or 0
  end

  function modifier_item_aghanims_talents:GetModifierMoveSpeedBonus_Constant()
    return self.movement_speed or 0
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
  local madeChanges = false
  local talentOverrides = {}
  local parent = self:GetParent()
  local function setTalentLevel (level, leftAbility, rightAbility, claim)
    if not leftAbility or not rightAbility then
      -- print('No ability for index ' .. leftIndex .. ', ' .. rightIndex)
      return
    end
    -- print (leftAbility:GetName() .. ' vs ' .. rightAbility:GetName())
    if leftAbility:GetLevel() == 0 and rightAbility:GetLevel() == 0 then
      -- the player hasn't chosen a talent yet
      return
    end
    if leftAbility:GetLevel() == 0 or rightAbility:GetLevel() == 0 then
      -- they have chosen a talent and it's the only one skilled
      if leftAbility:GetLevel() == 0 then
        parent['talentChoice' .. level] = 'right'
      elseif rightAbility:GetLevel() == 0 then
        parent['talentChoice' .. level] = 'left'
      end
    end
    -- make sure our talent selection has been made
    assert(
      parent['talentChoice' .. level] == 'left' or parent['talentChoice' .. level] == 'right',
      'Trying to update talent but talent choice was let through!'
    )

    -- print('At leve ' .. level .. ' hero chose ' .. parent['talentChoice' .. level])

    if self:IsStatsTalent(leftAbility:GetName()) and parent['talentChoice' .. level] == 'right' then
      talentOverrides[#talentOverrides + 1] = leftAbility:GetName()
    elseif self:IsStatsTalent(rightAbility:GetName()) and parent['talentChoice' .. level] == 'left' then
      talentOverrides[#talentOverrides + 1] = rightAbility:GetName()
    else

      if claim then
        if leftAbility:GetLevel() == 0 or rightAbility:GetLevel() == 0 then
          leftAbility:SetLevel(0)
          rightAbility:SetLevel(0)
          leftAbility:SetLevel(1)
          rightAbility:SetLevel(1)
          madeChanges = true
        end
      else
        -- print ('disabling talents')
        if parent['talentChoice' .. level] == 'left' then
          if rightAbility:GetLevel() ~= 0 then
            rightAbility:SetLevel(0)
            madeChanges = true
          end
        else
          if leftAbility:GetLevel() ~= 0 then
            leftAbility:SetLevel(0)
            madeChanges = true
          end
        end
      end
    end
  end

  local abilityTable = {}

  for abilityIndex = 0, parent:GetAbilityCount() - 1 do
    local ability = parent:GetAbilityByIndex(abilityIndex)
    if ability and ability:IsAttributeBonus() then
      abilityTable[#abilityTable + 1] = ability
    end
  end

  setTalentLevel("10", abilityTable[1], abilityTable[2], tree[10])
  setTalentLevel("15", abilityTable[3], abilityTable[4], tree[15])
  setTalentLevel("20", abilityTable[5], abilityTable[6], tree[20])
  setTalentLevel("25", abilityTable[7], abilityTable[8], tree[25])

  local statsOverride = {}
  for _,abilityName in ipairs(talentOverrides) do
    statsOverride = self:AddTalentStats(abilityName, statsOverride)
  end

  if statsOverride.hp ~= self.hp then
    madeChanges = true
    self.hp = statsOverride.hp
  end
  if statsOverride.mp ~= self.mp then
    madeChanges = true
    self.mp = statsOverride.mp
  end
  if statsOverride.movement_speed ~= self.movement_speed then
    madeChanges = true
    self.movement_speed = statsOverride.movement_speed
  end

  if madeChanges then
    print('Edited talents, recalculating stat bonus')
    parent:CalculateStatBonus()
  end
end

function modifier_item_aghanims_talents:IsStatsTalent(name)
  if string.sub(name, 0, 22) == 'special_bonus_hp_regen' then
    return false
  end
  if string.sub(name, 0, 17) == 'special_bonus_hp_' then
    return true
  end
  if string.sub(name, 0, 22) == 'special_bonus_mp_regen' then
    return false
  end
  if string.sub(name, 0, 17) == 'special_bonus_mp_' then
    return true
  end
  if string.sub(name, 0, 29) == 'special_bonus_movement_speed_' then
    return true
  end

  return false
end

function modifier_item_aghanims_talents:AddTalentStats(name, data)
  if string.sub(name, 0, 17) == 'special_bonus_hp_' then
    if not data['hp'] then
      data['hp'] = 0
    end
    data['hp'] = data['hp'] + tonumber(string.sub(name, 18))
  elseif string.sub(name, 0, 17) == 'special_bonus_mp_' then
    if not data['mp'] then
      data['mp'] = 0
    end
    data['mp'] = data['mp'] + tonumber(string.sub(name, 18))
  elseif string.sub(name, 0, 29) == 'special_bonus_movement_speed_' then
    if not data['movement_speed'] then
      data['movement_speed'] = 0
    end
    data['movement_speed'] = data['movement_speed'] + tonumber(string.sub(name, 30))
  end
  return data
end
