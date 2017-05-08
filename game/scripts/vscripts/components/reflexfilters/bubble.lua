-- Component for handling the ModifierGained Filter used for spell effect blocking
-- from the Postactive 3c Reflex Item (Bubble Orb)

if not BubbleOrbFilter then
  DebugPrint("Creating filter for Preemptive 3c (Bubble Orb)")
  BubbleOrbFilter = class({})

  Debug.EnabledModules["reflexfilters:bubble"] = false
end

function BubbleOrbFilter:Init()
  FilterManager:AddFilter(FilterManager.ModifierGained, self, Dynamic_Wrap(self, "ModifierGainedFilter"))
end

function BubbleOrbFilter:ModifierGainedFilter(keys)
  if not keys.entindex_caster_const then
    return true
  end

  local caster = EntIndexToHScript(keys.entindex_caster_const)
  local parent = EntIndexToHScript(keys.entindex_parent_const)
  local bubbleModifierName = "modifier_item_preemptive_bubble_block"
  local casterIsAlly = caster:GetTeamNumber() == parent:GetTeamNumber()
  local parentHasBubbleModifier = parent:HasModifier(bubbleModifierName)
  local bubbleModifiers = parent:FindAllModifiersByName(bubbleModifierName)
  local casterIsInBubbles = false

  local function UnitIsInSpecificBubble(unit, bubbleModifier)
    return bubbleModifier:UnitIsInBubble(unit)
  end

  if parentHasBubbleModifier then
    casterIsInBubbles = reduce(operator.land, true, map(partial(UnitIsInSpecificBubble, caster), iter(bubbleModifiers)))
  end

  if not parentHasBubbleModifier or casterIsAlly or casterIsInBubbles then
    return true
  else
    return false
  end
end
