require( "libraries/Timers" )	--needed for the timers.

function modifier_stoneskin_on_spell_start(keys)
  if keys.ability:GetModifierValue() == 1 then

    --cooldownLeft = keys.ability:GetCooldownTimeRemaining()

    --keys.ability:EndCooldown()
    --keys.ability:StartCooldown(keys.Delay + cooldownLeft)

    Timers:CreateTimer({
      endTime = keys.Delay,
      callback = function()
        keys.ability:ApplyDataDrivenModifier(keys.caster, keys.caster, "modifier_item_stoneskin_stone_armor", {})
      end
    })
  --else
  --  if keys.ability:IsCooldownReady() then
    --  keys.BaseNPC:RemoveModifierByNameAndCaster("modifier_item_stoneskin_stone_armor", keys.caster)
  --  end
  end
end
