-- Taken from bb template
if HeroKillGold == nil then
  DebugPrint ( 'Creating new HeroKillGold object.' )
  HeroKillGold = class({})
  Debug.EnabledModules['gold:hero_kills'] = true
end

function HeroKillGold:Init()
end
