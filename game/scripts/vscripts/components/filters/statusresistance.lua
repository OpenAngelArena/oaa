if StatusResistance == nil then
  DebugPrint('creating new StatusResistance object')
  StatusResistance = class({})
end

function StatusResistance:Init ()
  FilterManager:AddFilter(FilterManager.ModifierGained, self, Dynamic_Wrap(StatusResistance, "StatusResistanceFilter"))
end

function StatusResistance:StatusResistanceFilter(filterTable)
  local parent_index = filterTable["entindex_parent_const"]
  local caster_index = filterTable["entindex_caster_const"]
  local ability_index = filterTable["entindex_ability_const"]

  if not parent_index or not caster_index or not ability_index then
    return true
  end

  local duration = filterTable["duration"]
  local parent = EntIndexToHScript( parent_index )
  local caster = EntIndexToHScript( caster_index )
  local ability = EntIndexToHScript( ability_index )
  local name = filterTable["name_const"]

  if parent and caster and duration ~= -1 and parent:GetTeam() ~= caster:GetTeam() then
    local params = {caster = caster, target = parent, duration = duration, ability = ability, modifier_name = name}
    local resistance = 0
    local stackResist = 0
    for _, modifier in ipairs( parent:FindAllModifiers() ) do
      if modifier.GetModifierStatusResistanceStacking and modifier:GetModifierStatusResistanceStacking(params) then
        stackResist = (stackResist or 0) + modifier:GetModifierStatusResistanceStacking(params)
      end
      if modifier.GetModifierStatusResistance and modifier:GetModifierStatusResistance(params) and modifier:GetModifierStatusResistance(params) > resistance then
        resistance = modifier:GetModifierStatusResistance( params )
      end
    end
    local newDuration = filterTable["duration"] * (1 - resistance/100) * (1 - stackResist/100)
    filterTable["duration"] = newDuration
  end
  if filterTable["duration"] == 0 then return false end
  return true
end
