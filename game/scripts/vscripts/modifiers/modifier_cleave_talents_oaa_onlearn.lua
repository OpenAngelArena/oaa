modifier_cleave_talents_oaa_onlearn = class( {} )

LinkLuaModifier( "modifier_cleave_talents_oaa", "modifiers/modifier_cleave_talents_oaa.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

function modifier_cleave_talents_oaa_onlearn:IsHidden()
  return true
end

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
    if not pID then
      return
    end
    local hero = PlayerResource:GetSelectedHeroEntity( pID )
    -- string.match(input, regex)
    if hero and string.match(abilityname, "special_bonus_cleave_[0-9]*_oaa") then
      local ability = hero:FindAbilityByName(abilityname)
      if ability ~= nil then
        local modifier = hero:AddNewModifier(hero, ability, "modifier_cleave_talents_oaa", {});
      end
    end
  end)
end
