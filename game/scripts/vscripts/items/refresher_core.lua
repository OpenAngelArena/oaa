
LinkLuaModifier( "modifier_octarine_vampirism_applier", "modifiers/modifier_octarine_vampirism_applier.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_octarine_vampirism_buff", "modifiers/modifier_octarine_vampirism_buff.lua", LUA_MODIFIER_MOTION_NONE )

item_octarine_core_2 = class({})

function item_octarine_core_2:GetIntrinsicModifierName()
  return "modifier_octarine_vampirism_applier"
end

item_refresher_core = item_octarine_core_2

function item_refresher_core:OnSpellStart()
  local caster = self:GetCaster()

  -- Put ability exemption in here
  local exempt_ability_table = {
    tinker_rearm = true
  }

  -- Put item exemption in here
  local exempt_item_table = {
    item_black_king_bar = true,
    item_charge_bkb = true,
    item_arcane_boots = true,
    item_hand_of_midas = true,
    item_hand_of_midas_2 = true,
    item_hand_of_midas_3 = true,
    item_helm_of_the_dominator = true,
    item_refresher = true,
    item_refresher_2 = true,
    item_refresher_core = true,
    item_refresher_core_2 = true,
    item_refresher_core_3 = true,
    item_sphere = true,
    item_sphere_2 = true,
    item_bottle = true,
    item_infinite_bottle = true,
    item_necronomicon = true,
    item_necronomicon_2 = true,
    item_necronomicon_3 = true,
    item_necronomicon_4 = true,
    item_necronomicon_5 = true
  }

  -- Reset cooldown for abilities that is not rearm
  for i = 0, caster:GetAbilityCount() - 1 do
    local ability = caster:GetAbilityByIndex(i)
    if ability and not exempt_ability_table[ability:GetAbilityName()] then
      local timeLeft = ability:GetCooldownTimeRemaining()
      ability:EndCooldown()
    end
  end

  -- Reset cooldown for items
  for i = 0, 5 do
    local item = caster:GetItemInSlot(i)
    if item and not exempt_item_table[item:GetAbilityName()] then
      item:EndCooldown()
    end
  end
end

function item_refresher_core:IsRefreshable()
  return false
end

item_refresher_core_2 = item_refresher_core --luacheck: ignore item_refresher_core_2
item_refresher_core_3 = item_refresher_core --luacheck: ignore item_refresher_core_3
