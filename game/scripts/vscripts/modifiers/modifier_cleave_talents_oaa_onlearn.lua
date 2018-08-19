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
    -- string.match(input, regex)
    if pID and string.match(abilityname, "special_bonus_cleave_[0-9]*_oaa") then
      local ability = player:FindAbilityByName(abilityname)
      if ability ~= nil then
        local modifier = player:AddNewModifier(player, ability, "modifier_cleave_talents_oaa", {});
      end
    end
  end)
end
