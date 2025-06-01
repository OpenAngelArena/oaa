LinkLuaModifier("modifier_boss_shielder_shielded_buff", "abilities/boss/shielder/modifier_boss_shielder_shielded.lua", LUA_MODIFIER_MOTION_NONE) --- BATHS HEAVY IMPORTED

boss_shielder_shield = class(AbilityBaseClass)

function boss_shielder_shield:Precache(context)
  PrecacheResource("particle", "particles/shielder/hex_shield_1.vpcf", context)
  PrecacheResource("particle", "particles/shielder/hex_shield_2.vpcf", context)
  PrecacheResource("particle", "particles/shielder/hex_shield_3.vpcf", context)
  PrecacheResource("particle", "particles/units/heroes/hero_spectre/spectre_desolate.vpcf", context)
  PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_mars.vsndevts", context)
end

if IsServer() then
  function boss_shielder_shield:SetLevel(level)
    if self.intrinsicMod and not self.intrinsicMod:IsNull() then
      self.intrinsicMod:OnPhaseChanged(level)
    end
    self.BaseClass.SetLevel(self, level)
  end
end

function boss_shielder_shield:GetIntrinsicModifierName()
  return "modifier_boss_shielder_shielded_buff"
end
