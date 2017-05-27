LinkLuaModifier("modifier_item_bloodstone_oaa", "items/bloodstone.lua", LUA_MODIFIER_MOTION_NONE)
--LinkLuaModifier("modifier_item_bloodstone_charge_collector", "items/bloodstone.lua", LUA_MODIFIER_MOTION_NONE)

item_bloodstone_1 = class({})

function item_bloodstone_1:GetIntrinsicModifierName()
  return "modifier_item_bloodstone_oaa"
end

function item_bloodstone_1:OnSpellStart()
  self:GetCaster():Kill(self, self:GetCaster())
end

-- upgrades
item_bloodstone_2 = item_bloodstone_1
item_bloodstone_3 = item_bloodstone_1
item_bloodstone_4 = item_bloodstone_1
item_bloodstone_5 = item_bloodstone_1

--------------------------------------------------------------------------
-- base modifier

modifier_item_bloodstone_oaa = class({})

function modifier_item_bloodstone_oaa:OnCreated()
  if IsServer() then
    self:Setup(true)
  end
end
function modifier_item_bloodstone_oaa:OnRefreshed()
  if IsServer() then
    self:Setup()
  end
end
function modifier_item_bloodstone_oaa:Setup(created)
  local ability = self:GetAbility()
  local caster = self:GetCaster()

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
        print('I have an upgraded bloodstone without stored charges... is it ' .. caster.surplusCharges .. '?')
        self.charges = 12
        caster.surplusCharges = math.min(12, caster.surplusCharges)
        needsSetCharges = true
      end
    end

    if created and ability.addedCharges then
      if self.charges > caster.surplusCharges then
        print('It looks like charges got duplicated, truncating ' .. self.charges .. ' to ' .. caster.surplusCharges)
        self.charges = caster.surplusCharges
        needsSetCharges = true
      end
      caster.surplusCharges = caster.surplusCharges - self.charges
      if caster.surplusCharges > 0 then
        print('I think theres a bloodstone in a stash somewhere ' .. caster.surplusCharges)
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

function modifier_item_bloodstone_oaa:OnDestroy()
  if IsServer() then
    local ability = self:GetAbility()
    -- store our point values for later
    if ability:GetCurrentCharges() > self.charges then
      print('gained ' .. (ability:GetCurrentCharges() - self.charges) .. ' charges')
      self.charges = ability:GetCurrentCharges()
    end
    self:GetCaster().surplusCharges = (self:GetCaster().surplusCharges or 0) + self.charges
    self:GetCaster().storedCharges = self.charges
  end
end

function modifier_item_bloodstone_oaa:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_bloodstone_oaa:IsHidden()
  return true
end
function modifier_item_bloodstone_oaa:IsDebuff()
  return false
end
function modifier_item_bloodstone_oaa:IsPurgable()
  return false
end

function modifier_item_bloodstone_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH,
    MODIFIER_PROPERTY_HEALTH_BONUS, -- GetModifierHealthBonus
    MODIFIER_PROPERTY_MANA_BONUS, -- GetModifierManaBonus
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, -- GetModifierConstantHealthRegen
    MODIFIER_PROPERTY_MANA_REGEN_PERCENTAGE, -- GetModifierPercentageManaRegen
    MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, -- GetModifierConstantManaRegen
  }
end

--------------------------------------------------------------------------
-- bloodstone stats

function modifier_item_bloodstone_oaa:GetModifierHealthBonus()
  return self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_bloodstone_oaa:GetModifierManaBonus()
  return self:GetAbility():GetSpecialValueFor("bonus_mana")
end

function modifier_item_bloodstone_oaa:GetModifierConstantHealthRegen()
  return self:GetAbility():GetSpecialValueFor("bonus_health_regen")
end

function modifier_item_bloodstone_oaa:GetModifierPercentageManaRegen()
  return self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
end

function modifier_item_bloodstone_oaa:GetModifierConstantManaRegen()
  return self:GetAbility():GetCurrentCharges()
end

--------------------------------------------------------------------------
-- charge handling

function modifier_item_bloodstone_oaa:OnDeath(keys)
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
        stone:SetCurrentCharges(stone:GetCurrentCharges() + 1)
        self.charges = stone:GetCurrentCharges()
      end
    end
    return
  end

  -- Charge loss

  local oldCharges = stone:GetCurrentCharges()
  local newCharges = math.max(1, math.ceil(oldCharges * stone:GetSpecialValueFor("on_death_removal")))

  stone:SetCurrentCharges(newCharges)
  self.charges = newCharges

  if not caster:IsRealHero() or caster:IsTempestDouble() then
    return
  end

  local healAmount = stone:GetSpecialValueFor("heal_on_death_base") + (stone:GetSpecialValueFor("heal_on_death_per_charge") * oldCharges)
  local heroes = FindUnitsInRadius(
    caster:GetTeamNumber(),
    caster:GetAbsOrigin(),
    nil,
    stone:GetSpecialValueFor("heal_on_death_range"),
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    DOTA_UNIT_TARGET_HERO,
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  heroes = iter(heroes)
  heroes:each(function (hero)
    hero:Heal(healAmount, stone)
  end)
end

--------------------------------------------------------------------------
-- aura stuff

-- function modifier_item_bloodstone_oaa:IsAura()
--   return true
-- end

-- function modifier_item_bloodstone_oaa:GetAuraSearchType()
--   return DOTA_UNIT_TARGET_HERO
-- end

-- function modifier_item_bloodstone_oaa:GetAuraSearchTeam()
--   return DOTA_UNIT_TARGET_TEAM_ENEMY
-- end

-- function modifier_item_bloodstone_oaa:GetAuraRadius()
--   return self:GetAbility():GetSpecialValueFor("charge_range")
-- end

-- function modifier_item_bloodstone_oaa:GetModifierAura()
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
