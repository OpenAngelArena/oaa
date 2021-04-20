--LinkLuaModifier("modifier_meepo_divided_we_stand_oaa", "abilities/oaa_divided_we_stand.lua", LUA_MODIFIER_MOTION_NONE)
--LinkLuaModifier("modifier_meepo_divided_we_stand_oaa_death", "abilities/oaa_divided_we_stand.lua", LUA_MODIFIER_MOTION_NONE)
--LinkLuaModifier("modifier_meepo_divided_we_stand_oaa_passive", "abilities/oaa_divided_we_stand.lua",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_meepo_divided_we_stand_oaa_bonus_buff", "abilities/oaa_divided_we_stand.lua", LUA_MODIFIER_MOTION_NONE)

meepo_divided_we_stand_oaa = class(AbilityBaseClass)

function meepo_divided_we_stand_oaa:GetIntrinsicModifierName()
  return "modifier_meepo_divided_we_stand_oaa_bonus_buff"
end

function meepo_divided_we_stand_oaa:OnUpgrade()
  local caster = self:GetCaster()

  -- Don't allow illusions to have clones
  if caster:IsIllusion() then
    return
  end

  -- Find Meepo Prime if we are lvling up this ability from the clone
  if caster:IsClone() then
    caster = caster:GetCloneSource()
  end

  --[[
  local PID = caster:GetPlayerOwnerID()
  local mainMeepo = PlayerResource:GetSelectedHeroEntity(PID)

  mainMeepo.meepoList = mainMeepo.meepoList or GetAllMeepos(mainMeepo)

  if caster ~= mainMeepo then
    return nil
  end

  -- Create a clone
  local newMeepo = CreateUnitByName(caster:GetUnitName(), caster:GetAbsOrigin(), true, caster, nil, caster:GetTeamNumber())
  newMeepo:SetPlayerID(PID)
  newMeepo:SetControllableByPlayer(PID, false)
  newMeepo:SetOwner(caster:GetOwner())
  FindClearSpaceForUnit(newMeepo, caster:GetAbsOrigin(), false)

  -- Preventing dropping and selling items in inventory
  newMeepo:SetHasInventory(false)
  newMeepo:SetCanSellItems(false)

  -- Disabling bounties because clone can die
  newMeepo:SetMaximumGoldBounty(0)
  newMeepo:SetMinimumGoldBounty(0)
  newMeepo:SetDeathXP(0)

  newMeepo:AddNewModifier(caster, self, "modifier_meepo_divided_we_stand_oaa", {})

  table.insert(caster.meepoList, newMeepo)
  ]]

  local ability_level = self:GetLevel()
  local vanilla_ability = caster:FindAbilityByName("meepo_divided_we_stand")

  if not vanilla_ability then
    return
  end

  -- Max level for vanilla ability is 3 -> check if its 3 already, if yes don't continue
  if vanilla_ability:GetLevel() == 3  or ability_level >= 4 then
    self:RefreshMeepos(caster)
    return
  end

  vanilla_ability:SetLevel(ability_level)

  self:RefreshMeepos(caster)
end

function meepo_divided_we_stand_oaa:RefreshMeepos(caster)
  if not IsServer() then
    return
  end

  local ability = self

  Timers:CreateTimer(0.5, function()
    -- Find ally heroes everywhere
    local heroes = FindUnitsInRadius(
      caster:GetTeamNumber(),
      caster:GetAbsOrigin(),
      nil,
      FIND_UNITS_EVERYWHERE,
      DOTA_UNIT_TARGET_TEAM_FRIENDLY,
      DOTA_UNIT_TARGET_HERO,
      bit.bor(DOTA_UNIT_TARGET_FLAG_INVULNERABLE, DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD),
      FIND_ANY_ORDER,
      false
    )

    -- Find all meepos (clones and meepo prime)
    local meepos = {}
    for _, hero in pairs(heroes) do
      if hero and not hero:IsNull() then
        if hero:GetUnitName() == "npc_dota_hero_meepo" and not hero:IsIllusion() then
          table.insert(meepos, hero)
        end
      end
    end

    -- Adding the modifier to refresh
    for _, meepo in pairs(meepos) do
      if meepo and not meepo:IsNull() then
        meepo:AddNewModifier(caster, ability, "modifier_meepo_divided_we_stand_oaa_bonus_buff", {})
      end
    end
  end)
end

---------------------------------------------------------------------------------------------------
--[[
modifier_meepo_divided_we_stand_oaa = class(ModifierBaseClass)

function modifier_meepo_divided_we_stand_oaa:IsHidden()
	return true
end

function modifier_meepo_divided_we_stand_oaa:IsDebuff()
	return false
end

function modifier_meepo_divided_we_stand_oaa:IsPurgable()
	return false
end

function modifier_meepo_divided_we_stand_oaa:IsPermanent()
  return true
end

function modifier_meepo_divided_we_stand_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_RESPAWN,
    MODIFIER_EVENT_ON_DEATH,
  }
end

function modifier_meepo_divided_we_stand_oaa:OnCreated(kv)
  if IsServer() then
    self:StartIntervalThink(0.5)
  end
end

function modifier_meepo_divided_we_stand_oaa:OnIntervalThink()
  local meepo = self:GetParent()
  local mainMeepo = self:GetCaster()

  -- Set stats the same as main meepo
  meepo:SetBaseStrength(mainMeepo:GetStrength())
  meepo:SetBaseAgility(mainMeepo:GetAgility())
  meepo:SetBaseIntellect(mainMeepo:GetIntellect())
  meepo:CalculateStatBonus(true)

  -- Set clone level the same as main meepo
  --while meepo.GetLevel(meepo) < mainMeepo.GetLevel(mainMeepo) do
    --meepo:AddExperience(10, DOTA_ModifyXP_Unspecified, false, false)
  --end

  -- Preventing clone from respawning
  --meepo:SetRespawnsDisabled(true)

  --LevelAbilitiesForAllMeepos(mainMeepo) -- This should be done only on the main meepo
end

function modifier_meepo_divided_we_stand_oaa:OnDeath(event)
  local parent = self:GetParent()

  if event.unit ~= parent then
    return
  end

  local mainMeepo = self:GetCaster()
  for _, meepo in pairs(GetAllMeepos(mainMeepo)) do
    if meepo ~= mainMeepo then
      meepo:AddNewModifier(mainMeepo, self:GetAbility(), "modifier_meepo_divided_we_stand_oaa_death", {})
      meepo:AddNoDraw()
    end
  end
end

function modifier_meepo_divided_we_stand_oaa:OnRespawn(event)
  local parent = self:GetParent()
  local mainMeepo = self:GetCaster()
  for _, meepo in pairs(GetAllMeepos(mainMeepo)) do
    if meepo ~= mainMeepo then
      meepo:RemoveModifierByName("modifier_meepo_divided_we_stand_oaa_death")
      meepo:RemoveNoDraw()
      FindClearSpaceForUnit(meepo, mainMeepo:GetAbsOrigin(), true)
      meepo:AddNewModifier(meepo, self:GetAbility(), "modifier_phased", {["duration"] = 0.1})
    end
  end
end
]]

---------------------------------------------------------------------------------------------------
--[[
modifier_meepo_divided_we_stand_oaa_death = class(ModifierBaseClass)

function modifier_meepo_divided_we_stand_oaa_death:IsHidden()
  return false
end

function modifier_meepo_divided_we_stand_oaa_death:IsDebuff()
  return false
end

function  modifier_meepo_divided_we_stand_oaa_death:IsPurgable()
  return false
end

function modifier_meepo_divided_we_stand_oaa_death:CheckState()
  return {
    [MODIFIER_STATE_STUNNED] = true,
    [MODIFIER_STATE_UNSELECTABLE] = true,
    [MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_OUT_OF_GAME] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
  }
end
]]

---------------------------------------------------------------------------------------------------
-- Helper functions
--[[
function LevelAbilitiesForAllMeepos(unit)
  local PID = unit:GetPlayerOwnerID()
  local mainMeepo = PlayerResource:GetSelectedHeroEntity(PID)
  for a = 0, mainMeepo:GetAbilityCount() - 1 do
    local ability = mainMeepo:GetAbilityByIndex(a)
    if ability then
      for _, meepo in pairs(GetAllMeepos(mainMeepo)) do
        if meepo ~= mainMeepo then
          local cloneAbility = meepo:FindAbilityByName(ability:GetAbilityName())
          if ability:GetLevel() > cloneAbility:GetLevel() then
            cloneAbility:SetLevel(ability:GetLevel())
          elseif ability:GetLevel() < cloneAbility:GetLevel() then
            ability:SetLevel(cloneAbility:GetLevel())
            --mainMeepo:SetAbilityPoints(mainMeepo:GetAbilityPoints()-1)
          end
        end
      end
    end
  end
  for _, meepo in pairs(GetAllMeepos(mainMeepo)) do
    if meepo ~= mainMeepo then
      meepo:SetAbilityPoints(0)
    end
  end
end

function GetAllMeepos(caster)
  if caster.meepoList then
    return caster.meepoList
  else
    return {caster}
  end
end
]]

---------------------------------------------------------------------------------------------------
--[[
modifier_meepo_divided_we_stand_oaa_passive = class(ModifierBaseClass)

function modifier_meepo_divided_we_stand_oaa_passive:IsHidden()
  return true
end

function modifier_meepo_divided_we_stand_oaa_passive:IsDebuff()
  return false
end

function modifier_meepo_divided_we_stand_oaa_passive:IsPurgable()
  return false
end

function modifier_meepo_divided_we_stand_oaa_passive:RemoveOnDeath()
  return false
end

function modifier_meepo_divided_we_stand_oaa_passive:IsAura()
	if self:GetParent():PassivesDisabled() then
    return false
  end
	return true
end

function modifier_meepo_divided_we_stand_oaa_passive:GetModifierAura()
  return "modifier_meepo_divided_we_stand_oaa_bonus_buff"
end

function modifier_meepo_divided_we_stand_oaa_passive:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_meepo_divided_we_stand_oaa_passive:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO
end

function modifier_meepo_divided_we_stand_oaa_passive:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("aura_radius")
end
]]

---------------------------------------------------------------------------------------------------

modifier_meepo_divided_we_stand_oaa_bonus_buff = class(ModifierBaseClass)

function modifier_meepo_divided_we_stand_oaa_bonus_buff:IsHidden()
  return false
end

function modifier_meepo_divided_we_stand_oaa_bonus_buff:IsDebuff()
  return false
end

function modifier_meepo_divided_we_stand_oaa_bonus_buff:IsPurgable()
  return false
end

function modifier_meepo_divided_we_stand_oaa_bonus_buff:OnCreated()
  local parent = self:GetParent()
  if parent:IsIllusion() or parent:GetUnitName() ~= "npc_dota_hero_meepo" or not IsServer() then
    self.total_dmg_reduction = 0
    return
  end
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.dmg_reduction_per_meepo = ability:GetLevelSpecialValueFor("bonus_dmg_reduction_pct", ability:GetLevel()-1)
    self.radius = ability:GetSpecialValueFor("aura_radius")
  else
    self.dmg_reduction_per_meepo = 3
    self.radius = 700
  end
  self:StartIntervalThink(0)
end

function modifier_meepo_divided_we_stand_oaa_bonus_buff:OnRefresh()
  local parent = self:GetParent()
  if parent:IsIllusion() or parent:GetUnitName() ~= "npc_dota_hero_meepo" or not IsServer() then
    self.total_dmg_reduction = 0
    return
  end
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.dmg_reduction_per_meepo = ability:GetLevelSpecialValueFor("bonus_dmg_reduction_pct", ability:GetLevel()-1)
    self.radius = ability:GetSpecialValueFor("aura_radius")
  else
    self.dmg_reduction_per_meepo = 3
    self.radius = 700
  end
end

function modifier_meepo_divided_we_stand_oaa_bonus_buff:OnIntervalThink()
  local parent = self:GetParent()

  if parent:PassivesDisabled() or parent:IsIllusion() or parent:GetUnitName() ~= "npc_dota_hero_meepo" then
    return
  end

  if not IsServer() then
    return
  end

  -- Find allied heroes
  local heroes = FindUnitsInRadius(
    parent:GetTeamNumber(),
    parent:GetAbsOrigin(),
    nil,
    self.radius,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    DOTA_UNIT_TARGET_HERO,
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  -- Find all meepos (clones and meepo prime)
  local meepos = {}
  for _, hero in pairs(heroes) do
    if hero and not hero:IsNull() then
      if hero:GetUnitName() == "npc_dota_hero_meepo" and not hero:IsIllusion() then
        table.insert(meepos, hero)
      end
    end
  end

  self.total_dmg_reduction = #meepos * self.dmg_reduction_per_meepo

  -- Failsafe if something goes wrong
  if self.total_dmg_reduction == 0 then
    self.total_dmg_reduction = self.dmg_reduction_per_meepo
  end

  self:SetStackCount(self.total_dmg_reduction)

  local vanilla_boots = {
    "item_phase_boots",
    "item_power_treads",
    "item_tranquil_boots",
    "item_arcane_boots",
    "item_guardian_greaves",
  }

  local custom_boots = {
    "item_travel_boots_oaa",

    "item_greater_guardian_greaves",
    "item_greater_tranquil_boots",
    "item_greater_travel_boots",
    "item_greater_phase_boots",
    "item_greater_power_treads",

    "item_greater_guardian_greaves_2",
    "item_greater_tranquil_boots_2",
    "item_greater_travel_boots_2",
    "item_greater_phase_boots_2",
    "item_greater_power_treads_2",

    "item_greater_guardian_greaves_3",
    "item_greater_tranquil_boots_3",
    "item_greater_travel_boots_3",
    "item_greater_phase_boots_3",
    "item_greater_power_treads_3",
    "item_sonic",

    "item_greater_guardian_greaves_4",
    "item_greater_tranquil_boots_4",
    "item_greater_travel_boots_4",
    "item_greater_phase_boots_4",
    "item_greater_power_treads_4",
    "item_sonic_2",
    "item_force_boots_1",
  }

  if not parent:IsClone() then
    return
  end

  local meepo_prime = parent:GetCloneSource()
  local found_boots = false
  local has_vanilla_boots = false

  for _, boots in pairs(vanilla_boots) do
    if parent:HasItemInInventory(boots) then
      has_vanilla_boots = true
      break -- Breaks the for loop
    end
  end

  -- If clone doesnt have vanilla boots check Meepo Prime for custom boots
  if has_vanilla_boots == false then
    for _, boots in pairs(custom_boots) do
      for item_slot = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
        local item = meepo_prime:GetItemInSlot(item_slot)
        if item then
          if item:GetAbilityName() == boots then
            meepo_prime.main_boots = item
            found_boots = true
            break -- Breaks the for loop with item slots
          end
        end
      end

      if found_boots == true then
        break -- Breaks the for loop with custom boots
      end
    end
  end

  -- If Meepo Prime has custom boots -> copy them to the clone
  if found_boots == true then
    local meepo_prime_boots = meepo_prime.main_boots
    local boots_name = meepo_prime_boots:GetAbilityName()
    -- Check if the clone has those boots
    if not parent:HasItemInInventory(boots_name) then
      self.cloned_boots = parent:AddItemByName(boots_name)
      -- Check the slot of the cloned boots
      if self.cloned_boots and parent:HasItemInInventory(boots_name) and self.cloned_boots:GetItemSlot() ~= meepo_prime_boots:GetItemSlot() then
        parent:SwapItems(self.cloned_boots:GetItemSlot(), meepo_prime_boots:GetItemSlot())
      end
    end
  else
    for _, boots in pairs(custom_boots) do
      for item_slot = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
        local item = parent:GetItemInSlot(item_slot)
        if item then
          if item:GetAbilityName() == boots then
            parent:RemoveItem(item)
            break
          end
        end
      end
    end
  end

  parent:CalculateStatBonus(true)
end

function modifier_meepo_divided_we_stand_oaa_bonus_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    MODIFIER_PROPERTY_TOOLTIP,
  }
end

function modifier_meepo_divided_we_stand_oaa_bonus_buff:GetModifierIncomingDamage_Percentage()
  return -self.total_dmg_reduction
end

function modifier_meepo_divided_we_stand_oaa_bonus_buff:OnTooltip()
  return self:GetStackCount()
end
