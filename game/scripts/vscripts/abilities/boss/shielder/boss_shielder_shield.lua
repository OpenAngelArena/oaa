LinkLuaModifier("modifier_boss_shielder_shielded_buff", "abilities/shielder/modifier_boss_shielder_shielded.lua", LUA_MODIFIER_MOTION_NONE) --- BATHS HEAVY IMPORTED

boss_shielder_shield = class(AbilityBaseClass)

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
