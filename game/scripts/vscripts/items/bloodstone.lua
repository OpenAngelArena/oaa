LinkLuaModifier("modifier_intrinsic_multiplexer", "modifiers/modifier_intrinsic_multiplexer.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_bloodstone_stacking_stats", "items/bloodstone.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_bloodstone_non_stacking_stats", "items/bloodstone.lua", LUA_MODIFIER_MOTION_NONE)
--LinkLuaModifier("modifier_item_bloodstone_charge_collector", "items/bloodstone.lua", LUA_MODIFIER_MOTION_NONE)

item_bloodstone_1 = class(ItemBaseClass)

function item_bloodstone_1:GetIntrinsicModifierName()
  return "modifier_intrinsic_multiplexer"
end

function item_bloodstone_1:GetIntrinsicModifierNames()
  return {
    "modifier_item_bloodstone_stacking_stats",
    "modifier_item_bloodstone_non_stacking_stats"
  }
end

function item_bloodstone_1:GetManaCost(nLevel)
  local caster = self:GetCaster() or self:GetOwner() or self:GetPurchaser()
  local mana_cost_percentage = self:GetSpecialValueFor("mana_cost_percentage")
  local caster_max_mana = caster:GetMaxMana()

  return caster_max_mana*mana_cost_percentage/100
end

function item_bloodstone_1:OnSpellStart()
  local caster = self:GetCaster()
  --caster:Kill(self, caster) -- old bloodstone (Pocket Deny)
  local duration = self:GetSpecialValueFor("restore_duration")
  caster:AddNewModifier(caster, self, "modifier_item_bloodstone_active", {duration = duration})
  -- modifier_item_bloodstone_active is a built-in bloodstone modifier.
end

-- upgrades
item_bloodstone_2 = item_bloodstone_1
item_bloodstone_3 = item_bloodstone_1
item_bloodstone_4 = item_bloodstone_1
item_bloodstone_5 = item_bloodstone_1

--------------------------------------------------------------------------
-- Parts of bloodstone that should stack with other bloodstones

modifier_item_bloodstone_stacking_stats = class(ModifierBaseClass)

function modifier_item_bloodstone_stacking_stats:OnCreated()
  if IsServer() then
    self:Setup(true)
  end
end
function modifier_item_bloodstone_stacking_stats:OnRefreshed()
  if IsServer() then
    self:Setup()
  end
end
function modifier_item_bloodstone_stacking_stats:Setup(created)
  local ability = self:GetAbility()
  local caster = self:GetCaster()
  local initial_charges = ability:GetSpecialValueFor("initial_charges_tooltip")

  -- destroy happens after create when upgrading, and also item doesn't have half of it's abilities yet
  Timers:CreateTimer(0.1, function()
    --[[
    first run lvl 1
      charges = 12, skips first block
      addedCharges = false, assigns to true
      if there's a stored charge of 12 it will be nil'd out

    inventory upgrade
      on destroy
        sets storedCharges to charges
        adds charges to caster.surplusCharges
      charges = 0,
        assigns charges to stored charges
        nils stored charges
        sets addedCharge
      addedCharges = true
        removes charges from surplus
      sets charges

    stash upgrade
      on destroy (from removal from inventory)
        sets storedCharges to charges
        adds charges to caster.surplusCharges
      upgrade sets charges to 0
      when item is added, above flow executes

    ]]
    self.charges = ability:GetCurrentCharges()
    local needsSetCharges = false

    if self.charges == 0 then
      -- freshly upgraded bloodstone, find stored charges
      if caster.storedCharges then
        -- stored charges found
        self.charges = caster.storedCharges
        caster.storedCharges = nil
        needsSetCharges = true
        ability.addedCharges = true
      else
        if not caster.surplusCharges then
          caster.surplusCharges = initial_charges
        end
        DebugPrint('I have an upgraded bloodstone without stored charges... is it ' .. caster.surplusCharges .. '?')
        self.charges = initial_charges
        caster.surplusCharges = math.min(initial_charges, caster.surplusCharges)
        needsSetCharges = true
      end
    end

    if created and ability.addedCharges then
      if self.charges > caster.surplusCharges then
        DebugPrint('It looks like charges got duplicated, truncating ' .. self.charges .. ' to ' .. caster.surplusCharges)
        self.charges = caster.surplusCharges
        needsSetCharges = true
      end
      caster.surplusCharges = caster.surplusCharges - self.charges
      if caster.surplusCharges > 0 then
        DebugPrint('I think theres a bloodstone in a stash somewhere ' .. caster.surplusCharges)
      end
    else -- has to run created before it can run without created
      ability.addedCharges = true
    end

    if needsSetCharges then
      ability:SetCurrentCharges(self.charges)
    end

    if caster.storedCharges == self.charges then
      caster.storedCharges = nil
      return
    end
  end)
end

function modifier_item_bloodstone_stacking_stats:OnDestroy()
  if IsServer() then
    local ability = self:GetAbility()
    -- store our point values for later
    if ability:GetCurrentCharges() > self.charges then
      DebugPrint('gained ' .. (ability:GetCurrentCharges() - self.charges) .. ' charges')
      self.charges = ability:GetCurrentCharges()
    end
    self:GetCaster().surplusCharges = (self:GetCaster().surplusCharges or 0) + self.charges
    self:GetCaster().storedCharges = self.charges
  end
end

function modifier_item_bloodstone_stacking_stats:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_bloodstone_stacking_stats:IsHidden()
  return true
end
function modifier_item_bloodstone_stacking_stats:IsDebuff()
  return false
end
function modifier_item_bloodstone_stacking_stats:IsPurgable()
  return false
end

if IsServer() then
  function modifier_item_bloodstone_stacking_stats:DeclareFunctions()
    return {
      MODIFIER_EVENT_ON_DEATH,
      MODIFIER_PROPERTY_HEALTH_BONUS, -- GetModifierHealthBonus
      MODIFIER_PROPERTY_MANA_BONUS, -- GetModifierManaBonus
      MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, -- GetModifierConstantHealthRegen
      MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, -- GetModifierConstantManaRegen
      MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    }
  end
end

--------------------------------------------------------------------------
-- bloodstone stats

function modifier_item_bloodstone_stacking_stats:GetModifierHealthBonus()
  return self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_bloodstone_stacking_stats:GetModifierManaBonus()
  return self:GetAbility():GetSpecialValueFor("bonus_mana")
end

function modifier_item_bloodstone_stacking_stats:GetModifierConstantHealthRegen()
  local ability = self:GetAbility()
  return ability:GetSpecialValueFor("bonus_health_regen") + (ability:GetCurrentCharges() * ability:GetSpecialValueFor("regen_per_charge"))
end

function modifier_item_bloodstone_stacking_stats:GetModifierConstantManaRegen()
  local ability = self:GetAbility()
  return ability:GetSpecialValueFor("bonus_mana_regen") + (ability:GetCurrentCharges() * ability:GetSpecialValueFor("regen_per_charge"))
end

function modifier_item_bloodstone_stacking_stats:GetModifierBonusStats_Intellect()
  return self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

--------------------------------------------------------------------------
-- charge handling

function modifier_item_bloodstone_stacking_stats:OnDeath(keys)
  local caster = self:GetCaster()
  local dead = keys.unit
  local killer = keys.attacker
  local stone = self:GetAbility()

  -- someone else died or owner is reincarnating
  if caster ~= dead or caster:IsReincarnating() then
    -- Dead unit is an actually dead real enemy hero unit
    if caster:GetTeamNumber() ~= dead:GetTeamNumber() and dead:IsRealHero() and not dead:IsTempestDouble() and not dead:IsReincarnating() then
      -- Charge gain

      local function IsItemBloodstone(item)
        return item and string.sub(item:GetAbilityName(), 0, 15) == "item_bloodstone"
      end

      local items = map(partial(caster.GetItemInSlot, caster), range(0, 5))
      local firstBloodstone = nth(1, filter(IsItemBloodstone, items))
      local isSelfFirstBloodstone = firstBloodstone == stone

      local casterToDeadVector = dead:GetAbsOrigin() - caster:GetAbsOrigin()
      local isDeadInChargeRange = casterToDeadVector:Length2D() <= stone:GetSpecialValueFor("charge_range")

      if (isDeadInChargeRange or killer == caster) and isSelfFirstBloodstone then
        stone:SetCurrentCharges(stone:GetCurrentCharges() + stone:GetSpecialValueFor("kill_charges"))
        self.charges = stone:GetCurrentCharges()
      end
    end
    return
  end

  -- Charge loss

  local oldCharges = stone:GetCurrentCharges()
  --local newCharges = math.max(1, math.ceil(oldCharges * stone:GetSpecialValueFor("on_death_removal")))
  local newCharges = math.max(0, math.ceil(oldCharges - stone:GetSpecialValueFor("death_charges")))

  stone:SetCurrentCharges(newCharges)
  self.charges = newCharges

  --if not caster:IsRealHero() or caster:IsTempestDouble() then
    --return
  --end

  -- local healAmount = stone:GetSpecialValueFor("heal_on_death_base") + (stone:GetSpecialValueFor("heal_on_death_per_charge") * oldCharges)
  -- local heroes = FindUnitsInRadius(
    -- caster:GetTeamNumber(),
    -- caster:GetAbsOrigin(),
    -- nil,
    -- stone:GetSpecialValueFor("heal_on_death_range"),
    -- DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    -- DOTA_UNIT_TARGET_HERO,
    -- DOTA_UNIT_TARGET_FLAG_NONE,
    -- FIND_ANY_ORDER,
    -- false
  -- )

  -- heroes = iter(heroes)
  -- heroes:each(function (hero)
    -- hero:Heal(healAmount, stone)
  -- end)
end

-------------------------------------------------------------------------
-- Parts of bloodstone that should NOT stack with other bloodstones

modifier_item_bloodstone_non_stacking_stats = class(ModifierBaseClass)

function modifier_item_bloodstone_non_stacking_stats:IsHidden()
  return true
end

function modifier_item_bloodstone_non_stacking_stats:IsDebuff()
  return false
end

function modifier_item_bloodstone_non_stacking_stats:IsPurgable()
  return false
end

function modifier_item_bloodstone_non_stacking_stats:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE, -- GetModifierMPRegenAmplify_Percentage
    MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,    -- GetModifierSpellAmplify_Percentage
    MODIFIER_PROPERTY_MANACOST_PERCENTAGE_STACKING -- GetModifierPercentageManacostStacking
  }
end

function modifier_item_bloodstone_non_stacking_stats:GetModifierMPRegenAmplify_Percentage()
  return self:GetAbility():GetSpecialValueFor("mana_regen_multiplier")-100
end

function modifier_item_bloodstone_non_stacking_stats:GetModifierSpellAmplify_Percentage()
  local ability = self:GetAbility()
  return ability:GetSpecialValueFor("spell_amp") + (ability:GetCurrentCharges() * ability:GetSpecialValueFor("amp_per_charge"))
end

function modifier_item_bloodstone_non_stacking_stats:GetModifierPercentageManacostStacking()
  return self:GetAbility():GetSpecialValueFor("manacost_reduction")
end

--------------------------------------------------------------------------
-- aura stuff

-- function modifier_item_bloodstone_stacking_stats:IsAura()
--   return true
-- end

-- function modifier_item_bloodstone_stacking_stats:GetAuraSearchType()
--   return DOTA_UNIT_TARGET_HERO
-- end

-- function modifier_item_bloodstone_stacking_stats:GetAuraSearchTeam()
--   return DOTA_UNIT_TARGET_TEAM_ENEMY
-- end

-- function modifier_item_bloodstone_stacking_stats:GetAuraRadius()
--   return self:GetAbility():GetSpecialValueFor("charge_range")
-- end

-- function modifier_item_bloodstone_stacking_stats:GetModifierAura()
--   return "modifier_item_bloodstone_charge_collector"
-- end

-- --------------------------------------------------------------------------
-- -- charge collector, stacking modifiers that gives stacks
-- -- stacking auras don't get applied more than once no matter what

-- modifier_item_bloodstone_charge_collector = class({})

-- function modifier_item_bloodstone_charge_collector:DeclareFunctions()
--   return {
--     MODIFIER_EVENT_ON_DEATH
--   }
-- end

-- function modifier_item_bloodstone_charge_collector:IsHidden()
--   return true
-- end
-- function modifier_item_bloodstone_charge_collector:GetAttributes()
--   return MODIFIER_ATTRIBUTE_MULTIPLE
-- end

-- -- charge gain
-- function modifier_item_bloodstone_charge_collector:OnDeath(keys)
--   if not IsServer() then
--     return
--   end

--   local dead = self:GetParent()

--   if dead ~= keys.unit or not keys.unit:IsRealHero() or keys.unit:IsReincarnating() or keys.unit:IsTempestDouble() then
--     -- someone else died or it was not a real hero, Tempest Double, or is reincarnating
--     return
--   end

--   local caster = self:GetCaster()

--   -- Find the first bloodstone we can
--   local found = false
--   for i = 0, 5 do
--     local item = caster:GetItemInSlot(i)
--     if not found and item and string.sub(item:GetAbilityName(), 0, 15) == "item_bloodstone" then
--       found = true
--       item:SetCurrentCharges( item:GetCurrentCharges() + 1 )
--     end
--   end
-- end
