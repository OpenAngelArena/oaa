
if HeroCosmetics == nil then
  DebugPrint ( 'Starting HeroCosmetics' )
  HeroCosmetics = class({})
end

function HeroCosmetics:Init()
  DebugPrint('HeroCosmetics module Initialization started!')
  self.moduleName = "OAA hero cosmetics"
  ChatCommand:LinkDevCommand("-testheroarcana", Dynamic_Wrap(HeroCosmetics, "TestHeroArcana"), HeroCosmetics)
end

function HeroCosmetics:ApplySelectedArcana (hero, arcana)
  if hero:GetUnitName() == 'npc_dota_hero_sohei' then
    if arcana == 'DBZSohei' then
      --print('Applying Arcana DBZSohei')
      hero:AddNewModifier( hero, nil, 'modifier_arcana_dbz', nil )
    elseif arcana == 'PepsiSohei' then
      --print('Applying Arcana PepsiSohei')
      hero:AddNewModifier( hero, nil, 'modifier_arcana_pepsi', nil )
    end
  elseif hero:GetUnitName() == 'npc_dota_hero_electrician' then
    if arcana == 'RockElectrician' then
      --print('Applying Arcana RockElectrician')
      hero:AddNewModifier( hero, nil, 'modifier_arcana_rockelec', nil )
    end
  elseif hero:GetUnitName() == 'npc_dota_hero_marci' then
    if arcana == 'MaidMarci' then
      --print('Applying Arcana MaidMarci')
      hero:AddNewModifier( hero, nil, 'modifier_arcana_maid', nil )
    end
  elseif hero:GetUnitName() == 'npc_dota_hero_phoenix' then
    if arcana == 'GryphonPhoenix' then
      --print('Applying Arcana GryphonPhoenix')
      hero:AddNewModifier( hero, nil, 'modifier_arcana_gryphon', nil )
    end
  end
end

function HeroCosmetics:TestHeroArcana(keys)
  local short_names = {
    dbz = "modifier_arcana_dbz",
    pepsi = "modifier_arcana_pepsi",
    rockstar = "modifier_arcana_rockelec",
    maid = "modifier_arcana_maid",
    gryphon = "modifier_arcana_gryphon",
  }
  local text = keys.text
  local hero = PlayerResource:GetSelectedHeroEntity(keys.playerid)
  local splitted = split(text, " ")
  local name = splitted[2]
  local extra = splitted[3]
  if name then
    if short_names[name] then
      local mod_name = short_names[name]
      if extra and extra == "remove" then
        hero:RemoveModifierByName(mod_name)
      else
        hero:AddNewModifier(hero, nil, mod_name, {})
      end
    end
  end
end
