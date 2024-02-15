LinkLuaModifier("modifier_item_lucience_aura_handler", "items/lucience.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_lucience_regen_aura", "items/lucience.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_lucience_movespeed_aura", "items/lucience.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_lucience_regen_effect", "items/lucience.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_lucience_movespeed_effect", "items/lucience.lua", LUA_MODIFIER_MOTION_NONE)

-- Name constants
local regenAuraName = "modifier_item_lucience_regen_aura"
local movespeedAuraName = "modifier_item_lucience_movespeed_aura"
local auraTypeRegen = 1
local auraTypeMovespeed = 2

item_lucience = class(ItemBaseClass)

function item_lucience:GetIntrinsicModifierName()
  return "modifier_item_lucience_aura_handler"
end

function item_lucience:OnSpellStart()
  self:StartCooldown(self:GetCooldown(self:GetLevel()))

  -- Switch state
  self.serverLucienceState = not self.serverLucienceState

  -- Switch auras
  if self.auraHandler then
    self.auraHandler:OnRefresh()
  end
end

function item_lucience:GetToggleState()
  if self.serverLucienceState == nil then
    self.serverLucienceState = false
  end

  return self.serverLucienceState
end

function item_lucience:GetAbilityTextureName()
  local baseIconName = self.BaseClass.GetAbilityTextureName(self)

  -- Update state based on stacks of the intrinsic modifier
  if self.auraHandler and not self.auraHandler:IsNull() then
    self.lucienceState = self.auraHandler:GetStackCount()
  end

  if not self.lucienceState then
    return baseIconName
  elseif self.lucienceState == auraTypeRegen then
    return baseIconName
  elseif self.lucienceState == auraTypeMovespeed then
    return baseIconName .. "_movespeed"
  else
    return baseIconName
  end
end

function item_lucience.RemoveLucienceAuras(unit)
  unit:RemoveModifierByName(regenAuraName)
  unit:RemoveModifierByName(movespeedAuraName)
end

function item_lucience.RemoveLucienceEffects(ability, effectModifierName, unit)
  local effectModifier = unit:FindModifierByName(effectModifierName)
  if effectModifier then
    unit:RemoveModifierByName(effectModifierName)
  end
end

item_lucience_2 = class(item_lucience)
item_lucience_3 = class(item_lucience)
item_lucience_4 = class(item_lucience)

------------------------------------------------------------------------

modifier_item_lucience_aura_handler = class(ModifierBaseClass)

function modifier_item_lucience_aura_handler:IsHidden()
  return true
end

function modifier_item_lucience_aura_handler:IsPurgable()
  return false
end

function modifier_item_lucience_aura_handler:GetLuciences()
  local caster = self:GetCaster()

  local function IsItemLucience(item)
    return item and string.sub(item:GetAbilityName(), 0, 13) == "item_lucience"
  end

  local inventoryItems = map(partial(caster.GetItemInSlot, caster), range(0, 5))
  local lucienceItems = filter(IsItemLucience, inventoryItems)

  return lucienceItems
end

function modifier_item_lucience_aura_handler:IsHighestLevelLucience(item)
  local function IsLowerOrEqualLevel(item2)
    return item2:GetLevel() <= item:GetLevel()
  end

  return every(IsLowerOrEqualLevel, self:GetLuciences())
end

function modifier_item_lucience_aura_handler:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    ability.auraHandler = self
    self.str = ability:GetSpecialValueFor("bonus_strength")
    self.int = ability:GetSpecialValueFor("bonus_intellect")
  end

  if IsServer() then
    local parent = self:GetParent()
    local caster = self:GetCaster()

    -- Set stack count to update item icon
    if ability:GetToggleState() then
      self:SetStackCount(auraTypeMovespeed)
    else
      self:SetStackCount(auraTypeRegen)
    end

    -- If the owner has a higher level Lucience then don't do anything
    if not self:IsHighestLevelLucience(ability) then
      return
    end

    -- Delay adding the aura modifiers by a frame
    Timers:CreateTimer(function()
      item_lucience.RemoveLucienceAuras(parent)
      if ability:GetToggleState() then
        parent:AddNewModifier(caster, ability, movespeedAuraName, {})
      else
        parent:AddNewModifier(caster, ability, regenAuraName, {})
      end
    end)
  end
end

modifier_item_lucience_aura_handler.OnRefresh = modifier_item_lucience_aura_handler.OnCreated

function modifier_item_lucience_aura_handler:OnDestroy()
  if IsServer() then
    local parent = self:GetParent()
    local ability = self:GetAbility()

    -- If the owner has a higher level Lucience then don't do anything
    if not self:IsHighestLevelLucience(ability) then
      return
    end

    local function RefreshHandler(modifier)
      modifier:OnRefresh()
    end

    item_lucience.RemoveLucienceAuras(parent)

    -- Refresh any other handlers on the parent so that lower level Lucience will take effect when dropping a higher level
    if parent:HasModifier(self:GetName()) then
      local auraHandlers = parent:FindAllModifiersByName(self:GetName())
      foreach(RefreshHandler, auraHandlers)
    end
  end
end

function modifier_item_lucience_aura_handler:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_lucience_aura_handler:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
  }
end

function modifier_item_lucience_aura_handler:GetModifierBonusStats_Strength()
  return self.str or self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_lucience_aura_handler:GetModifierBonusStats_Intellect()
  return self.int or self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

---------------------------------------------------------------------------------------------------

modifier_item_lucience_regen_aura = class(ModifierBaseClass)

function modifier_item_lucience_regen_aura:OnCreated()
  if IsServer() then
    local parent = self:GetParent()
    local units = FindUnitsInRadius(parent:GetTeamNumber(), parent:GetOrigin(), nil, self:GetAbility():GetSpecialValueFor("aura_radius"), self:GetAuraSearchTeam(), self:GetAuraSearchType(), self:GetAuraSearchFlags(), FIND_ANY_ORDER, false)
    local ability = self:GetAbility()
    local effectModifierName = "modifier_item_lucience_regen_effect"

    -- Force reapplication of effect modifiers so that effects update immediately when Lucience is upgraded
    foreach(partial(ability.RemoveLucienceEffects, ability, effectModifierName), units)
  end
end

function modifier_item_lucience_regen_aura:IsHidden()
  return true
end

function modifier_item_lucience_regen_aura:IsDebuff()
  return false
end

function modifier_item_lucience_regen_aura:IsPurgable()
  return false
end

function modifier_item_lucience_regen_aura:IsAura()
  return true
end

function modifier_item_lucience_regen_aura:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_item_lucience_regen_aura:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_item_lucience_regen_aura:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
end

function modifier_item_lucience_regen_aura:GetModifierAura()
  return "modifier_item_lucience_regen_effect"
end

---------------------------------------------------------------------------------------------------

modifier_item_lucience_movespeed_aura = class(modifier_item_lucience_regen_aura)

-- IsHidden is effectively repeated, but it's for the tooltip parser
function modifier_item_lucience_movespeed_aura:IsHidden()
  return true
end

function modifier_item_lucience_movespeed_aura:OnCreated()
  if IsServer() then
    local parent = self:GetParent()
    local units = FindUnitsInRadius(parent:GetTeamNumber(), parent:GetOrigin(), nil, self:GetAbility():GetSpecialValueFor("aura_radius"), self:GetAuraSearchTeam(), self:GetAuraSearchType(), self:GetAuraSearchFlags(), FIND_ANY_ORDER, false)
    local ability = self:GetAbility()
    local effectModifierName = "modifier_item_lucience_movespeed_effect"

    -- Force reapplication of effect modifiers so that effects update immediately when Lucience is upgraded
    foreach(partial(ability.RemoveLucienceEffects, ability, effectModifierName), units)
  end
end

function modifier_item_lucience_movespeed_aura:GetModifierAura()
  return "modifier_item_lucience_movespeed_effect"
end

---------------------------------------------------------------------------------------------------

modifier_item_lucience_regen_effect = class(ModifierBaseClass)

function modifier_item_lucience_regen_effect:IsHidden()
  return false
end

function modifier_item_lucience_regen_effect:IsDebuff()
  return false
end

function modifier_item_lucience_regen_effect:OnCreated()
  self.hp_regen = 60
  self.mana_regen = 1.75
  --local regen_interval = 1/3
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.hp_regen = ability:GetSpecialValueFor("aura_bonus_hp_regen")
    self.mana_regen = ability:GetSpecialValueFor("aura_bonus_mana_regen")
    --regen_interval = 1 / ability:GetSpecialValueFor("heals_per_sec")
  end

  --self.healInterval = regen_interval

  --if IsServer() then
    --self:StartIntervalThink(self.healInterval)
  --end
end

function modifier_item_lucience_regen_effect:OnRefresh()
  local hp_regen = 60
  local mana_regen = 1.75
  --local regen_interval = 1/3
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    hp_regen = ability:GetSpecialValueFor("aura_bonus_hp_regen")
    mana_regen = ability:GetSpecialValueFor("aura_bonus_mana_regen")
    --regen_interval = 1 / ability:GetSpecialValueFor("heals_per_sec")
  end

  --self.healInterval = regen_interval
  if self.hp_regen and self.mana_regen then
    self.hp_regen = math.max(self.hp_regen, hp_regen)
    self.mana_regen = math.max(self.mana_regen, mana_regen)
  else
    self.hp_regen = hp_regen
    self.mana_regen = mana_regen
  end
end

-- function modifier_item_lucience_regen_effect:OnIntervalThink()
  -- local parent = self:GetParent()
  -- local ability = self:GetAbility()

  -- parent:Heal(self.hp_regen * self.healInterval, ability)
-- end

function modifier_item_lucience_regen_effect:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
  }
end

function modifier_item_lucience_regen_effect:GetModifierConstantHealthRegen()
  return self.hp_regen
end

function modifier_item_lucience_regen_effect:GetModifierConstantManaRegen()
  return self.mana_regen
end

function modifier_item_lucience_regen_effect:GetEffectName()
  return "particles/units/heroes/hero_necrolyte/necrolyte_ambient_glow.vpcf"
end

function modifier_item_lucience_regen_effect:GetTexture()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    local baseIconName = ability.BaseClass.GetAbilityTextureName(ability)
    return baseIconName
  end
end

---------------------------------------------------------------------------------------------------

modifier_item_lucience_movespeed_effect = class(ModifierBaseClass)

function modifier_item_lucience_movespeed_effect:IsHidden()
  return false
end

function modifier_item_lucience_movespeed_effect:IsDebuff()
  return false
end

function modifier_item_lucience_movespeed_effect:OnCreated()
  self.move_speed = 20
  self.attack_speed = 20
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.move_speed = ability:GetSpecialValueFor("aura_percentage_bonus_movement_speed")
    self.attack_speed = ability:GetSpecialValueFor("aura_bonus_attack_speed")
  end
end

function modifier_item_lucience_movespeed_effect:OnRefresh()
  local move_speed = 20
  local attack_speed = 20
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    move_speed = ability:GetSpecialValueFor("aura_percentage_bonus_movement_speed")
    attack_speed = ability:GetSpecialValueFor("aura_bonus_attack_speed")
  end

  if self.move_speed and self.attack_speed then
    self.move_speed = math.max(self.move_speed, move_speed)
    self.attack_speed = math.max(self.attack_speed, attack_speed)
  else
    self.move_speed = move_speed
    self.attack_speed = attack_speed
  end
end

function modifier_item_lucience_movespeed_effect:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
  }
end

function modifier_item_lucience_movespeed_effect:GetModifierMoveSpeedBonus_Percentage()
  return self.move_speed
end

function modifier_item_lucience_movespeed_effect:GetModifierAttackSpeedBonus_Constant()
  return self.attack_speed
end

function modifier_item_lucience_movespeed_effect:GetEffectName()
  return "particles/units/heroes/hero_ancient_apparition/ancient_apparition_ambient_glow.vpcf"
end

function modifier_item_lucience_movespeed_effect:GetTexture()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    local baseIconName = ability.BaseClass.GetAbilityTextureName(ability)
    return baseIconName .. "_movespeed"
  end
end
