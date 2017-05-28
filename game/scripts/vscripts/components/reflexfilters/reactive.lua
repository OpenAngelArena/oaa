-- Component for handling the ModifierGained Filter used for spell effect blocking
-- from the Reactive Reflex Items

if not ReactiveFilter then
  DebugPrint("Creating filter for Reactive Items")
  ReactiveFilter = class({})

  Debug.EnabledModules["reflexfilters:reactive"] = false
end

function ReactiveFilter:Init()
  FilterManager:AddFilter(FilterManager.ModifierGained, self, Dynamic_Wrap(self, "ModifierGainedFilter"))
end

function ReactiveFilter:ModifierGainedFilter(keys)
  if not keys.entindex_caster_const then
    return true
  end

  local caster = EntIndexToHScript(keys.entindex_caster_const)
  local parent = EntIndexToHScript(keys.entindex_parent_const)
  local casterIsAlly = caster:GetTeamNumber() == parent:GetTeamNumber()
  local reactiveModifiers = {
    "modifier_item_reactive_reflect",
    "modifier_item_reactive_2b",
    "modifier_reactive_immunity"
  }
  local parentHasReactiveModifiers = any(partial(parent.HasModifier, parent), reactiveModifiers)

  return not parentHasReactiveModifiers or casterIsAlly
end
