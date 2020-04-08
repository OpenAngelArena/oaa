LinkLuaModifier("modifier_bottle_regeneration", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bottle_texture_tracker", "items/bottle.lua", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

local bonusNames = {
  'custom/bottles/bottle_contributor',
  'custom/bottles/bottle_tournament',
  'custom/bottles/bottle_03',
  'custom/bottles/bottle_20',
  'custom/bottles/bottle_50', --5
  'custom/bottles/bottle_baumi',
  'custom/bottles/bottle_timo',
  'custom/bottles/bottle_frej',
  'custom/bottles/bottle_melon',
  'custom/bottles/bottle_karmatic', --10
  'custom/bottles/bottle_athight',
  'custom/bottles/bottle_calmstormred',
  'custom/bottles/bottle_ghostfrombe',
  'custom/bottles/bottle_jamesgoodfellow',
  'custom/bottles/bottle_zedling', --15
  'custom/bottles/bottle_adhesivejotun',
  'custom/bottles/bottle_archimo',
  'custom/bottles/bottle_godsend24',
  'custom/bottles/bottle_greenscreen',
  'custom/bottles/bottle_gymleadergiovani', --20
  'custom/bottles/bottle_silverfennekin',
  'custom/bottles/bottle_takiru',
  'custom/bottles/bottle_therealxagent',
  'custom/bottles/bottle_yommi1999',
  'custom/bottles/bottle_fabianotten', --25
  'custom/bottles/bottle_devilsunrise',
  'custom/bottles/bottle_mrpootis',
  'custom/bottles/bottle_tokengoat',
  'custom/bottles/bottle_sms77',
  'custom/bottles/bottle_assassinsfurr', --30
  'custom/bottles/bottle_hl_vortex',
  'custom/bottles/bottle_pavlav',
  'custom/bottles/bottle_nologic',
  'custom/bottles/bottle_original',
  'custom/bottles/bottle_firenere', --35
  'custom/bottles/bottle_goldenhamster',
  'custom/bottles/bottle_hylageo',
  'custom/bottles/bottle_icedragon241',
  'custom/bottles/bottle_jamesgoodfellow_2',
  'custom/bottles/bottle_nastydaddy', --40
  'custom/bottles/bottle_lordsxey',
  'custom/bottles/bottle_shonkjr',
  'custom/bottles/bottle_zapp',
  'custom/bottles/bottle_sdakfreezes',
  'custom/bottles/bottle_brickbrack743', --45
  'custom/bottles/bottle_yoloswag',
  'custom/bottles/bottle_kyler',
  'custom/bottles/bottle_maxpower',
  'custom/bottles/bottle_trufflehunt',
  'custom/bottles/bottle_darkknighthawk', --50
  'custom/bottles/bottle_zeldamasterrt',
  'custom/bottles/bottle_nohnius',
  'custom/bottles/bottle_archemagarch',
  'custom/bottles/bottle_obby',
  'custom/bottles/bottle_darkonius',

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
    self:SetStackCount(tonumber(HeroSelection:GetSelectedBottleForPlayer(playerID)) or 0)
  end
end

function modifier_bottle_texture_tracker:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_bottle_texture_tracker:IsHidden()
  return true
end
