
function CDOTA_BaseNPC_Hero:GetNetworth()
  if not IsServer() then
    return 0
  end

  local hero = self
  local playerID = hero:GetPlayerOwnerID()
  local networth = 0 --PlayerResource:GetNetWorth(playerID)

  -- Gold on the hero itself
  if Gold then
    networth = Gold:GetGold(playerID)
  else
    networth = PlayerResource:GetGold(playerID)
  end

  -- Iterate over item slots adding up its gold cost
  -- Normal slots and backpack slots
  for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
    local item = hero:GetItemInSlot(i)
    if item then
      -- Don't do it for neutral items
      if not item:IsNeutralDrop() then
        local name = item:GetName()
        local purchaser = item:GetPurchaser()
        -- Don't do it for bottles and items that don't belong to the hero
        if (not purchaser or purchaser == hero) and name ~= "item_infinite_bottle" then
          networth = networth + item:GetCost()
        end
      end
    end
  end
  -- Stash slots
  for i = DOTA_STASH_SLOT_1, DOTA_STASH_SLOT_6 do
    local item = hero:GetItemInSlot(i)
    if item then
      -- Don't do it for neutral items
      if not item:IsNeutralDrop() then
        local name = item:GetName()
        local purchaser = item:GetPurchaser()
        -- Don't do it for bottles and items that don't belong to the hero
        if (not purchaser or purchaser == hero) and name ~= "item_infinite_bottle" then
          networth = networth + item:GetCost()
        end
      end
    end
  end
  -- TODO: Items on the ground
  -- TODO: Items on Spirit Bear

  -- Calculate core points worth in gold
  if CorePointsManager then
    local cp_value = CorePointsManager:GetGoldValueOfCorePoint()
    local cps = CorePointsManager:GetCorePointsOnHero(hero, playerID)
    if cp_value and cps then
      networth = networth + cps * cp_value
    end
  end

  return networth
end

CDOTA_BaseNPC_Hero.UnfilteredAddExperience = CDOTA_BaseNPC_Hero.UnfilteredAddExperience or CDOTA_BaseNPC_Hero.AddExperience
function CDOTA_BaseNPC_Hero:AddExperience(flXP, nReason, bApplyBotDifficultyScaling, bIncrementTotal)
  local eventData = {
    experience = flXP,
    player_id_const = self:GetPlayerOwnerID(),
    reason_const = nReason,
    is_from_method_call = true,
  }
  if FilterManager:RunFilterForType(eventData, FilterManager.ModifyExperience) then
    self:UnfilteredAddExperience(flXP, nReason, bApplyBotDifficultyScaling, bIncrementTotal)
  end
end

function CDOTA_BaseNPC_Hero:GetBaseRangedProjectileName()
  if not IsServer() then
    return ""
  end
  local unit_name = self:GetUnitName()
  local unit_table = GetUnitKeyValuesByName(unit_name)

  if not unit_table or not unit_table["ProjectileModel"] then
    return self:GetRangedProjectileName()
  end

  return unit_table["ProjectileModel"] or ""
end


function CDOTA_BaseNPC_Hero:ChangeAttackProjectile()
  if not IsServer() then
    return
  end
  local unit = self

  -- Priority Items > Hero Attack Modifiers > Base Attack

  if unit:HasModifier("modifier_item_splash_cannon_passive") then
    unit:SetRangedProjectileName("particles/base_attacks/ranged_tower_bad.vpcf")

  elseif unit:HasModifier("modifier_item_trumps_fists_passive") then
    unit:SetRangedProjectileName("particles/items/trumps_fists/trumps_fists_projectile.vpcf")

  elseif unit:HasModifier("modifier_item_devastator_oaa_desolator") then
    unit:SetRangedProjectileName("particles/items_fx/desolator_projectile.vpcf")

  elseif unit:HasModifier("modifier_oaa_glaives_of_wisdom_fx") then
    unit:SetRangedProjectileName("particles/units/heroes/hero_silencer/silencer_glaives_of_wisdom.vpcf")

  elseif unit:HasModifier("modifier_oaa_arcane_orb_sound") then
    unit:SetRangedProjectileName("particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_arcane_orb.vpcf")

  -- If it's one of Dragon Knight's forms, use its attack projectile instead
  elseif unit:HasModifier("modifier_dragon_knight_frost_breath") then
    unit:SetRangedProjectileName("particles/units/heroes/hero_dragon_knight/dragon_knight_elder_dragon_frost.vpcf")

  elseif unit:HasModifier("modifier_dragon_knight_splash_attack") then
    unit:SetRangedProjectileName("particles/units/heroes/hero_dragon_knight/dragon_knight_elder_dragon_fire.vpcf")

  elseif unit:HasModifier("modifier_dragon_knight_corrosive_breath") then
    unit:SetRangedProjectileName("particles/units/heroes/hero_dragon_knight/dragon_knight_elder_dragon_corrosive.vpcf")

  -- If it's a metamorphosed Terrorblade, use its attack projectile instead
  elseif unit:HasModifier("modifier_terrorblade_metamorphosis") then
    unit:SetRangedProjectileName("particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis_base_attack.vpcf")
	-- Else, default to the base ranged projectile
	else
		unit:SetRangedProjectileName(unit:GetBaseRangedProjectileName())
  end

end
