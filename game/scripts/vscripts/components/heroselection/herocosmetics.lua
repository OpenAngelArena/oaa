
LinkLuaModifier( "modifier_animation_translate_permanent_string", "libraries/modifiers/modifier_animation_translate_permanent_string.lua", LUA_MODIFIER_MOTION_NONE )

if HeroCosmetics == nil then
  DebugPrint ( 'Starting HeroCosmetics' )
  HeroCosmetics = class({})
end

function HeroCosmetics:Sohei (hero)
  DebugPrint ( 'Starting Sohei Cosmetics' )
  hero.body = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/items/juggernaut/thousand_faces_hakama/thousand_faces_hakama.vmdl"})
  hero.hand = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/sohei/so_weapon.vmdl"})
  hero.head = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/sohei/so_head.vmdl"})
  --hero.cape = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/items/wraith_king/deadreborn_cape/deadreborn_cape.vmdl"})
  -- lock to bone
  hero.body:FollowEntity(hero, true)
  hero.hand:FollowEntity(hero, true)
  hero.head:FollowEntity(hero, true)
  --hero.cape:FollowEntity(hero, true)

  --hero:AddNewModifier(hero, nil, 'modifier_animation_translate_permanent_string', {translate = 'walk'})
  --hero:AddNewModifier(hero, nil, 'modifier_animation_translate_permanent_string', {translate = 'odachi'})
  --hero:AddNewModifier(hero, nil, 'modifier_animation_translate_permanent_string', {translate = 'aggressive'})
end
