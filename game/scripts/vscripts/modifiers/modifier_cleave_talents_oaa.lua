modifier_cleave_talents_oaa = class( {} )

--------------------------------------------------------------------------------

function modifier_cleave_talents_oaa:IsPurgable()
  return false
end

function modifier_cleave_talents_oaa:IsPermanent()
  return true
end

--------------------------------------------------------------------------------

function modifier_cleave_talents_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_LANDED
  }
end

--TODO replace by string.match
local cleaveTalents =
{
  "special_bonus_cleave_150_oaa",
  "special_bonus_cleave_100_oaa",
  "special_bonus_cleave_60_oaa",
  "special_bonus_cleave_30_oaa",
  "special_bonus_cleave_25_oaa",
  "special_bonus_cleave_20_oaa",
  "special_bonus_cleave_15_oaa",
  "special_bonus_cleave_5_oaa"
}

if IsServer() then
  function modifier_cleave_talents_oaa:OnAttackLanded( event )
    local attacker = event.attacker
    if attacker == nil then
      return
    end

    local ability = nil
    for _,ab in pairs(cleaveTalents) do
      if ability == nil or ability:GetLevel() <= 0 then
        ability = attacker:FindAbilityByName(ab)
      end
    end

    if ability == nil then
      return
    end

    local cleaveInfo = {
      startRadius = ability:GetSpecialValueFor("cleave_starting_width"),
      endRadius = ability:GetSpecialValueFor("cleave_ending_width"),
      length = ability:GetSpecialValueFor("cleave_distance")
    }
    if cleaveInfo.startRadius <= 0 then
      cleaveInfo.startRadius = nil -- Use default
    end
    if cleaveInfo.endRadius <= 0 then
      cleaveInfo.endRadius = nil -- Use default
    end
    if cleaveInfo.length <= 0 then
      cleaveInfo.length = nil -- Use default
    end

    local cleaveDmgPct = ability:GetSpecialValueFor("value")
    if cleaveDmgPct == nil then
      cleaveDmgPct = ability:GetSpecialValueFor("cleave_damage")
    end
    --[[
    if cleaveDmgPct == nil then
      cleaveDmgPct = ability:GetSpecialValueFor("damage")
    end
    ]]

    ability:PerformCleaveOnAttack(
      event,
      cleaveInfo,
      cleaveDmgPct / 100.0,
      nil, -- Sound on attack
      nil, -- Sound on target
      nil, -- Wave particle
      nil -- Hit particle
    )
  end
end
