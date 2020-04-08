
modifier_building_hide_on_minimap = class(ModifierBaseClass)

function modifier_building_hide_on_minimap:IsHidden()
  return true
end

function modifier_building_hide_on_minimap:IsDebuff()
  return false
end

function modifier_building_hide_on_minimap:IsPurgable()
  return false
end

function modifier_building_hide_on_minimap:CheckState()
  return {
    [MODIFIER_STATE_NOT_ON_MINIMAP] = true
  }
end
