LinkLuaModifier("modifier_meepo_together_we_stand_oaa_bonus_buff", "abilities/oaa_meepo_together_we_stand.lua", LUA_MODIFIER_MOTION_NONE)

meepo_together_we_stand_oaa = class(AbilityBaseClass)

function meepo_together_we_stand_oaa:Spawn()
  if IsServer() then
    self:SetLevel(1)
  end
end

function meepo_together_we_stand_oaa:GetIntrinsicModifierName()
  return "modifier_meepo_together_we_stand_oaa_bonus_buff"
end

function meepo_together_we_stand_oaa:OnUpgrade()
  local caster = self:GetCaster()

  if caster:IsIllusion() then
    return
  end

  -- Find Meepo Prime if we are lvling up this ability from the clone
  if caster:IsClone() then
    caster = caster:GetCloneSource()
  end

  self:RefreshMeepos(caster)
end

function meepo_together_we_stand_oaa:RefreshMeepos(caster)
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
        meepo:AddNewModifier(caster, ability, "modifier_meepo_together_we_stand_oaa_bonus_buff", {})
      end
    end
  end)
end

function meepo_together_we_stand_oaa:IsStealable()
  return false
end

function meepo_together_we_stand_oaa:ProcMagicStick()
  return false
end

---------------------------------------------------------------------------------------------------

modifier_meepo_together_we_stand_oaa_bonus_buff = class(ModifierBaseClass)

function modifier_meepo_together_we_stand_oaa_bonus_buff:IsHidden()
  return false
end

function modifier_meepo_together_we_stand_oaa_bonus_buff:IsDebuff()
  return false
end

function modifier_meepo_together_we_stand_oaa_bonus_buff:IsPurgable()
  return false
end

function modifier_meepo_together_we_stand_oaa_bonus_buff:OnCreated()
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

function modifier_meepo_together_we_stand_oaa_bonus_buff:OnRefresh()
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

function modifier_meepo_together_we_stand_oaa_bonus_buff:OnIntervalThink()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()

  if parent:IsIllusion() or parent:GetUnitName() ~= "npc_dota_hero_meepo" then
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

  -- Damage reduction should work only if Divided We Stand is lvled-up
  local divided_we_stand = parent:FindAbilityByName("meepo_divided_we_stand")
  if divided_we_stand and divided_we_stand:GetLevel() > 0 then
    self.total_dmg_reduction = math.max(#meepos * self.dmg_reduction_per_meepo, self.dmg_reduction_per_meepo)
  else
    self.total_dmg_reduction = 0
  end

  self:SetStackCount(self.total_dmg_reduction)

  -- Fix for custom boots on clones:
  if not parent:IsClone() then
    return
  end

  local vanilla_boots = {
    "item_arcane_boots",
    "item_boots_of_bearing",
    "item_guardian_greaves",
    "item_phase_boots",
    "item_power_treads",
    "item_tranquil_boots",
  }

  local custom_boots = {
    "item_greater_guardian_greaves",
    "item_greater_guardian_greaves_2",
    "item_greater_guardian_greaves_3",
    "item_greater_guardian_greaves_4",
    "item_greater_phase_boots",
    "item_greater_phase_boots_2",
    "item_greater_phase_boots_3",
    "item_greater_phase_boots_4",
    "item_greater_phase_boots_5",
    "item_greater_power_treads",
    "item_greater_power_treads_2",
    "item_greater_power_treads_3",
    "item_greater_power_treads_4",
    "item_greater_boots_of_bearing_1",
    "item_greater_boots_of_bearing_2",
    "item_greater_boots_of_bearing_3",
    "item_greater_boots_of_bearing_4",
    "item_greater_travel_boots",
    "item_greater_travel_boots_2",
    "item_greater_travel_boots_3",
    "item_greater_travel_boots_4",
    "item_sonic",
    "item_sonic_2",
    "item_travel_boots_oaa",
  }

  local meepo_prime = parent:GetCloneSource()
  local found_boots = false
  local has_vanilla_boots = false

  -- HasItemInInventory counts backpack slots as valid item slots!!!
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

function modifier_meepo_together_we_stand_oaa_bonus_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    MODIFIER_PROPERTY_TOOLTIP,
  }
end

if IsServer() then
  function modifier_meepo_together_we_stand_oaa_bonus_buff:GetModifierIncomingDamage_Percentage()
    local parent = self:GetParent()
    if parent:PassivesDisabled() or parent:IsIllusion() or not parent:IsClone() then
      return 0
    end

    return 0 - math.abs(self.total_dmg_reduction)
  end
end

function modifier_meepo_together_we_stand_oaa_bonus_buff:OnTooltip()
  local parent = self:GetParent()
  if parent:PassivesDisabled() or parent:IsIllusion() then
    return 0
  end

  return self:GetStackCount()
end
