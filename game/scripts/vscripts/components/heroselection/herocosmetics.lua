if HeroCosmetics == nil then
  DebugPrint ( 'Starting HeroCosmetics' )
  HeroCosmetics = class({})
end

function HeroCosmetics:Sohei (hero)
  DebugPrint ( 'Starting Sohei Cosmetics' )
  hero.body = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/items/juggernaut/thousand_faces_hakama/thousand_faces_hakama.vmdl"})

  -- lock to bone
  hero.body:FollowEntity(hero, true)

end
