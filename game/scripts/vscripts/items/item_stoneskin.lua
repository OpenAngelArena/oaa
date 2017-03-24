require( "libraries/Timers" )	--needed for the timers.

function modifier_stoneskin_toggle(keys)
  if not keys.caster:HasModifier("modifier_item_stoneskin_stone_armor") and keys.ability:IsCooldownReady() then

    cooldown = keys.Cooldown
    keys.ability:EndCooldown()
    keys.ability:StartCooldown(keys.Delay + cooldown)

    Timers:CreateTimer({
      endTime = keys.Delay,
      callback = function()
        keys.ability:ApplyDataDrivenModifier(keys.caster, keys.caster, "modifier_item_stoneskin_stone_armor", {})
      end
    })
  else
    if keys.ability:IsCooldownReady() then
      keys.caster:RemoveModifierByName("modifier_item_stoneskin_stone_armor")
    end
  end
end
