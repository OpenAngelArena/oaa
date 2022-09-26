ModifierBaseClass = class({})

function ModifierBaseClass:IsFirstItemInInventory()
  local parent = self:GetParent()
  local ability = self:GetAbility()

  if parent:IsNull() or ability:IsNull() then
    return false
  end

  if not IsServer() then
    print("IsFirstItemInInventory will not return the correct result on the client!")
    return true
  end

  local same_items = {}
  for item_slot = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
    local item = parent:GetItemInSlot(item_slot)
    if item then
      if string.sub(item:GetAbilityName(), 0, string.len(item:GetAbilityName())-2) == string.sub(ability:GetAbilityName(), 0, string.len(ability:GetAbilityName())-2) then
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
