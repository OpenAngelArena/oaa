LinkLuaModifier("modifier_meepo_divided_we_stand_oaa", "abilities/oaa_meepo_divided_we_stand.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_meepo_divided_we_stand_oaa_death", "abilities/oaa_meepo_divided_we_stand.lua", LUA_MODIFIER_MOTION_NONE)

meepo_divided_we_stand_oaa = class(AbilityBaseClass)

function meepo_divided_we_stand_oaa:GetIntrinsicModifierName()
  return "modifier_meepo_divided_we_stand_oaa"
end

function meepo_divided_we_stand_oaa:OnUpgrade()
  local caster = self:GetCaster()

  -- Don't allow illusions to have clones
  if caster:IsIllusion() then
    return
  end

  -- Needs a case when a clone lvls up this ability

  -- Don't run the rest on clones
  if IsMeepoCloneOAA(caster) then
    return
  end

  local PID = caster:GetPlayerOwnerID()

  -- Init meepo list
  caster.meepoList = caster.meepoList or GetAllMeepos(caster)

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

  -- Preventing clone from respawning
  newMeepo:SetRespawnsDisabled(true)

  -- Refresh the intrinsic modifier on the clone
  newMeepo:AddNewModifier(caster, self, "modifier_meepo_divided_we_stand_oaa", {})

  -- Mark the created Meepo as a clone
  newMeepo.IsCloneOAA = true

  table.insert(caster.meepoList, newMeepo)
end

function meepo_divided_we_stand_oaa:OnHeroCalculateStatBonus()
  local caster = self:GetCaster()

  -- Don't run this on clones
  if IsMeepoCloneOAA(caster) then
    return
  end

  local mainMeepo = GetMeepoPrimeOAA(caster)
  for _, meepo in pairs(GetAllMeepos(mainMeepo)) do
    if meepo ~= mainMeepo then
      -- Set stats the same as main meepo
      meepo:SetBaseStrength(mainMeepo:GetStrength())
      meepo:SetBaseAgility(mainMeepo:GetAgility())
      meepo:SetBaseIntellect(mainMeepo:GetIntellect(false))
      meepo:CalculateStatBonus(true)

    -- Set clone level the same as main meepo
    --while meepo.GetLevel(meepo) < mainMeepo.GetLevel(mainMeepo) do
      --meepo:AddExperience(10, DOTA_ModifyXP_Unspecified, false, false)
    --end
    end
  end

  --LevelAbilitiesForAllMeepos(mainMeepo) -- This should be done only on the main meepo
end

function meepo_divided_we_stand_oaa:IsStealable()
  return false
end

function meepo_divided_we_stand_oaa:ProcMagicStick()
  return false
end

---------------------------------------------------------------------------------------------------

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

function modifier_meepo_divided_we_stand_oaa:RemoveOnDeath()
  return false
end

function modifier_meepo_divided_we_stand_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_RESPAWN,
    MODIFIER_EVENT_ON_DEATH,
  }
end

function modifier_meepo_divided_we_stand_oaa:OnCreated()
  if not IsServer() then
    return
  end

  self:StartIntervalThink(0)
end

function modifier_meepo_divided_we_stand_oaa:OnRefresh()
  if not IsServer() then
    return
  end

  self:OnIntervalThink()
end

function modifier_meepo_divided_we_stand_oaa:OnDeath(event)
  if not IsServer() then
    return
  end

  local parent = self:GetParent()

  if event.unit ~= parent then
    return
  end

  local mainMeepo = self:GetCaster() or GetMeepoPrimeOAA(parent)
  if IsMeepoCloneOAA(parent) then
    -- CLone died, kill Meepo Prime
    if mainMeepo:IsAlive() then
      mainMeepo:Kill(event.inflictor, event.attacker)
    end
  end

  -- Hide clones (try to revive dead ones first)
  for _, meepo in pairs(GetAllMeepos(mainMeepo)) do
    if meepo ~= mainMeepo then
      if not meepo:IsAlive() then
        meepo:RespawnHero(false, false)
      end
      meepo:AddNewModifier(mainMeepo, self:GetAbility(), "modifier_meepo_divided_we_stand_oaa_death", {})
      meepo:AddNoDraw()
    end
  end
end

function modifier_meepo_divided_we_stand_oaa:OnRespawn(event)
  if not IsServer() then
    return
  end

  local parent = self:GetParent()

  if event.unit ~= parent then
    return
  end

  if IsMeepoCloneOAA(parent) then
    -- Clone respawned -> do nothing
    return
  end

  for _, meepo in pairs(GetAllMeepos(parent)) do
    if meepo ~= parent then
      if not meepo:IsAlive() then
        -- If somehow clone is still dead, try respawning it
        meepo:RespawnHero(false, false)
      end
      -- Unhide the clone
      meepo:RemoveModifierByName("modifier_meepo_divided_we_stand_oaa_death")
      meepo:RemoveNoDraw()
      FindClearSpaceForUnit(meepo, parent:GetAbsOrigin(), true)
      meepo:AddNewModifier(meepo, self:GetAbility(), "modifier_phased", {duration = 0.1})
    end
  end
end

function modifier_meepo_divided_we_stand_oaa:OnIntervalThink()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  if parent:IsIllusion() or parent:GetUnitName() ~= "npc_dota_hero_meepo" or not IsMeepoCloneOAA(parent) then
    return
  end

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

  local meepo_prime = GetMeepoPrimeOAA(parent)
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

---------------------------------------------------------------------------------------------------

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

---------------------------------------------------------------------------------------------------
-- Helper functions

function IsMeepoCloneOAA(unit)
  if unit:IsClone() or unit.IsCloneOAA then
    return true
  end
end

function GetMeepoPrimeOAA(unit)
  if unit:IsClone() then
    return unit:GetCloneSource()
  end

  local PID = unit:GetPlayerOwnerID()

  return PlayerResource:GetSelectedHeroEntity(PID)
end

function GetAllMeepos(unit)
  local mainMeepo = GetMeepoPrimeOAA(unit)
  if mainMeepo.meepoList then
    return mainMeepo.meepoList
  else
    return {mainMeepo}
  end
end

function LevelAbilitiesForAllMeepos(unit)
  local mainMeepo = GetMeepoPrimeOAA(unit)
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
