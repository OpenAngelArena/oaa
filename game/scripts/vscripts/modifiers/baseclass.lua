ModifierBaseClass = class({})

function ModifierBaseClass:IsFirstItemInInventory()
  local parent = self:GetParent()
  local ability = self:GetAbility()

  if parent:IsNull() or ability:IsNull() then
    return false
  end

  if not IsServer() then
    return true
  end

  local same_items = {}
  for item_slot = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
    local item = parent:GetItemInSlot(item_slot)
    if item then
      if item:GetAbilityName() == ability:GetAbilityName() then
        table.insert(same_items, item)
      end
    end
  end

  if #same_items <= 1 then
    return true
  end

  if same_items[1] == ability then
    return true
  end

  return false
end
