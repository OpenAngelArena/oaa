modifier_cleave_talents_oaa_onlearn = class( {} )

LinkLuaModifier( "modifier_cleave_talents_oaa", "modifiers/modifier_cleave_talents_oaa.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

function modifier_cleave_talents_oaa_onlearn:IsPurgable()
  return false
end

function modifier_cleave_talents_oaa_onlearn:IsPermanent()
  return true
end

--------------------------------------------------------------------------------

if IsServer() then
  GameEvents:OnPlayerLearnedAbility(function(keys)
    local player = EntIndexToHScript(keys.player)
    local abilityname = keys.abilityname
    local pID = keys.PlayerID
    if pID and string.match(abilityname, "special_bonus_cleave_oaa") then
      local ability = player:FindAbilityByName(abilityname)


      local modifier = caster:AddNewModifier(caster, ability, "modifier_cleave_talents_oaa", {});
    end
  end)
end
