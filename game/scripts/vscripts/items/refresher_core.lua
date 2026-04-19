LinkLuaModifier( "modifier_item_refresher_core", "items/refresher_core.lua", LUA_MODIFIER_MOTION_NONE )

item_octarine_core_2 = class(ItemBaseClass)
item_octarine_core_3 = item_octarine_core_2
item_octarine_core_4 = item_octarine_core_2
item_octarine_core_5 = item_octarine_core_2

function item_octarine_core_2:GetIntrinsicModifierName()
  return "modifier_intrinsic_multiplexer"
end

function item_octarine_core_2:GetIntrinsicModifierNames()
  return {
    "modifier_item_spell_lifesteal_oaa",
    "modifier_item_octarine_core"
  }
end

--------------------------------------------------------------------------------

item_refresher_core = class(item_octarine_core_2)

function item_refresher_core:GetIntrinsicModifierNames()
  return {
    "modifier_item_spell_lifesteal_oaa",
    "modifier_item_refresher_core"
  }
end

function item_refresher_core:OnSpellStart()
  local caster = self:GetCaster()
  caster:EmitSound( "DOTA_Item.Refresher.Activate" )
  local particle = ParticleManager:CreateParticle("particles/items2_fx/refresher.vpcf", PATTACH_CUSTOMORIGIN, caster)
  ParticleManager:SetParticleControlEnt( particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetOrigin(), true )
  ParticleManager:ReleaseParticleIndex(particle)

  -- Reset cooldown for abilities that is not rearm
  for i = 0, caster:GetAbilityCount() - 1 do
    local ability = caster:GetAbilityByIndex(i)
    if ability and AllowedToRefresh(ability, true) then
      if not IsFakeItemCustom(ability) then
        ability:RefreshCharges()
      end
      ability:EndCooldown()
    end
  end

  -- Put item exemption in here
  local exempt_item_table = {
    item_ex_machina = true,
    --item_hand_of_midas_1 = true,
    item_refresher = true,
    item_refresher_2 = true,
    item_refresher_3 = true,
    item_refresher_4 = true,
    item_refresher_5 = true,
    item_refresher_core = true,
    item_refresher_core_2 = true,
    item_refresher_core_3 = true
    item_refresher_shard_oaa = true,
    item_tranquil_boots = true,
  }

  -- Reset cooldown for items
  -- Reset cooldown for items that are not in backpack
  local max_slot = DOTA_ITEM_SLOT_6
  if caster:HasModifier("modifier_spoons_stash_oaa") then
    max_slot = DOTA_ITEM_SLOT_9
  end
  for i = DOTA_ITEM_SLOT_1, max_slot do
    local item = caster:GetItemInSlot(i)
    if item and not exempt_item_table[item:GetAbilityName()] then
      item:EndCooldown()
    end
  end

  -- Reset TP scroll cooldown
  local tp_scroll = caster:GetItemInSlot(DOTA_ITEM_TP_SCROLL)
  if tp_scroll and tp_scroll:GetAbilityName() == "item_tpscroll" then
    tp_scroll:EndCooldown()
  end

  -- Reset neutral item cooldown
  local neutral_item = caster:GetItemInSlot(DOTA_ITEM_NEUTRAL_SLOT)
  if neutral_item and neutral_item:IsActiveNeutral() and not exempt_item_table[neutral_item:GetAbilityName()] then
    neutral_item:EndCooldown()
  end
end

function item_refresher_core:IsRefreshable()
  return false
end

item_refresher_core_2 = item_refresher_core --luacheck: ignore item_refresher_core_2
item_refresher_core_3 = item_refresher_core --luacheck: ignore item_refresher_core_3

--------------------------------------------------------------------------------

modifier_item_refresher_core = class({})

function modifier_item_refresher_core:IsHidden()
  return true
end

function modifier_item_refresher_core:IsPurgable()
  return false
end

function modifier_item_refresher_core:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_refresher_core:OnCreated()
  if IsServer() then
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    if caster:IsTempestDouble() then
      ability:StartCooldown(ability:GetCooldown(ability:GetLevel()))
    end
  end
end

function modifier_item_refresher_core:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_MANA_BONUS,
    MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
    MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
  }
end

function modifier_item_refresher_core:GetModifierConstantHealthRegen()
  return self:GetAbility():GetSpecialValueFor('bonus_health_regen')
end

function modifier_item_refresher_core:GetModifierConstantManaRegen()
  return self:GetAbility():GetSpecialValueFor('bonus_mana_regen')
end

function modifier_item_refresher_core:GetModifierBonusStats_Intellect()
  return self:GetAbility():GetSpecialValueFor('bonus_intelligence')
end

function modifier_item_refresher_core:GetModifierHealthBonus()
  return self:GetAbility():GetSpecialValueFor('bonus_health')
end

function modifier_item_refresher_core:GetModifierManaBonus()
  return self:GetAbility():GetSpecialValueFor('bonus_mana')
end

function modifier_item_refresher_core:GetModifierPercentageCooldown()
  return self:GetAbility():GetSpecialValueFor('bonus_cooldown')
end
