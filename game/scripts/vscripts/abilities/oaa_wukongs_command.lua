monkey_king_wukongs_command_oaa = class(AbilityBaseClass)

--LinkLuaModifier("modifier_wukongs_command_oaa_thinker", "abilities/oaa_wukongs_command", LUA_MODIFIER_MOTION_NONE)

function monkey_king_wukongs_command_oaa:OnAbilityPhaseStart()
  EmitSoundOn("Hero_MonkeyKing.FurArmy.Channel", self:GetCaster())
  return true
end

function monkey_king_wukongs_command_oaa:OnAbilityPhaseInterrupted()
  StopSoundOn("Hero_MonkeyKing.FurArmy.Channel", self:GetCaster())
end

function monkey_king_wukongs_command_oaa:GetAOERadius()
  local caster = self:GetCaster()

  if caster:HasTalent("special_bonus_unique_monkey_king_6") then
    return caster:FindTalentValue("special_bonus_unique_monkey_king_6", "value")
  end

  return self:GetSpecialValueFor("second_radius")
end

function monkey_king_wukongs_command_oaa:OnSpellStart()
  local caster = self:GetCaster()

  local first_ring_radius = self:GetSpecialValueFor("first_radius")
  local second_ring_radius = self:GetSpecialValueFor("second_radius")
  local third_ring_radius = 0

  local units_on_first_ring = self:GetSpecialValueFor("num_first_soldiers")
  local units_on_second_ring = self:GetSpecialValueFor("num_second_soldiers")
  local units_on_third_ring = 0

  if caster:HasTalent("special_bonus_unique_monkey_king_6") then
    third_ring_radius = caster:FindTalentValue("special_bonus_unique_monkey_king_6", "value")
    units_on_third_ring = caster:FindTalentValue("special_bonus_unique_monkey_king_6", "value2")
  end

  --CreateModifierThinker(caster, self, "modifier_wukongs_command_oaa_thinker", {duration = self:GetSpecialValueFor("duration")}, self:GetCursorPosition(), caster:GetTeamNumber(), false)
  EmitSoundOn("Hero_MonkeyKing.FurArmy", caster)
end

function monkey_king_wukongs_command_oaa:ProcsMagicStick()
  return true
end
