LinkLuaModifier("modifier_bottle_regeneration", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bottle_texture_tracker", "items/bottle.lua", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

local special_bottles = {
  -- TP master, and Lord of the Lotus Orb
  [43305444] = 3, -- baumi
  -- devs
  [7131038] = 1, -- chrisinajar
  [109151532] = 1, -- Chronophylos
  [60408038] = 1, -- Trildar
  [141335296] = 1, -- SquawkyArctangent
  [56309069] = 1, -- imaGecko
  [116407282] = 1, -- Haganeko
  [123791730] = 1, -- Warpdragon
  [98536810] = 1, -- Honeth
  [53917791] = 1, -- Minnakht
  [103179022] = 1, -- Allan vbhg
  [114538910] = 1, -- Apisal
  [53999591] = 1, -- carlosrpg
  -- golden tournament winners
  [124585666] = 2,
  [75435056] = 2,
  [136897804] = 2,
  [57898114] = 2,
  [89367798] = 2,
  -- special people
  [55159483] = 4,
  [34314091] = 5,
  [117027938] = 6
}

local bonusNames = {
  'custom/bottle_contributor',
  'custom/bottle_tournament',
  'custom/bottle_lotus',
  'custom/bottle_timo',
  'custom/bottle_frej',
  'custom/bottle_rearm'
}

--------------------------------------------------------------------------------

item_infinite_bottle = class(ItemBaseClass)

function item_infinite_bottle:GetIntrinsicModifierName()
  return "modifier_bottle_texture_tracker"
end

function item_infinite_bottle:OnSpellStart()
  local restore_time = self:GetSpecialValueFor("restore_time")
  local caster = self:GetCaster()

  EmitSoundOnClient("Bottle.Drink", caster:GetPlayerOwner())

  caster:AddNewModifier(caster, self, "modifier_bottle_regeneration", { duration = restore_time })

  if self:GetCurrentCharges() - 1 <= 0 then
    caster:RemoveItem(self)
  else
    self:SetCurrentCharges(self:GetCurrentCharges() - 1)
  end
end

function item_infinite_bottle:GetAbilityTextureName()
  if self.bonus then
    return self.bonus
  end
  if self.mod and not self.mod:IsNull() then
    local stacks = self.mod:GetStackCount()
    if stacks > 0 then
      self.bonus = bonusNames[self.mod:GetStackCount()]
      return self.bonus
    end
  end
  return "item_bottle"
end

--------------------------------------------------------------------------------

Debug:EnableDebugging()

modifier_bottle_texture_tracker = class(ModifierBaseClass)

function modifier_bottle_texture_tracker:OnCreated()
  local parent = self:GetParent()
  local item = self:GetAbility()
  item.mod = self

  if IsServer() then
    local playerID = parent:GetPlayerOwnerID()
    local steamid = PlayerResource:GetSteamAccountID(playerID)
    local playerName = PlayerResource:GetPlayerName(playerID)
    DebugPrint("Steam ID of " .. playerName .. ": " .. steamid)

    self:SetStackCount(special_bottles[steamid] or 0)
  end
end

function modifier_bottle_texture_tracker:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_bottle_texture_tracker:IsHidden()
  return true
end
