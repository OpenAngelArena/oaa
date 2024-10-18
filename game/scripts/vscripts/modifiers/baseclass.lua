ModifierBaseClass = class({})

function ModifierBaseClass:IsFirstItemInInventory()
  local parent = self:GetParent()
  local ability = self:GetAbility()

  if parent:IsNull() or ability:IsNull() then
    return false
  end

  if not IsServer() then
    print("IsFirstItemInInventory will not return the correct result on the client!")
    return
  end

  -- return parent:FindModifierByName(self:GetName()) == self -- idk if FindModifierByName always returns the same result
  return parent:FindAllModifiersByName(self:GetName())[1] == self -- same thing could be said for FindAllModifiersByName

  --[[
  local ability_name = ability:GetAbilityName()
  local same_items = {}
  local max_slot = DOTA_ITEM_SLOT_6
  if parent:HasModifier("modifier_techies_spoons_stash") then
    max_slot = DOTA_ITEM_SLOT_9
  end
  for item_slot = DOTA_ITEM_SLOT_1, max_slot do
    local item = parent:GetItemInSlot(item_slot)
    if item then
      local item_name = item:GetAbilityName()
      if string.sub(item_name, 0, string.len(item_name)-2) == string.sub(ability_name, 0, string.len(ability_name)-2) then
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
  ]]
end
