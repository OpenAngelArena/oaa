require( "libraries/Timers" )	--needed for the timers.

function modifier_stoneskin_toggle(keys)
  if not keys.caster:HasModifier("modifier_item_stoneskin_stone_armor") and keys.ability:IsCooldownReady() then
    --Apply modifier branch

    local cooldown = keys.Cooldown
    keys.ability:StartCooldown(keys.Delay + cooldown) --Adds delay and cooldown after delay so the player has
                                                      --the cooldown indication that the item is working.
                                                      -- *Want* eventually add a particle effect
    --Delay timer
    Timers:CreateTimer({
      endTime = keys.Delay,
      callback = function()
        keys.ability:ApplyDataDrivenModifier(keys.caster, keys.caster, "modifier_item_stoneskin_stone_armor", {})
      end
    })
  else

    --Remove modifier Branch
    if keys.ability:IsCooldownReady() then
      keys.caster:RemoveModifierByName("modifier_item_stoneskin_stone_armor")
    end
  end
end
