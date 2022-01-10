LinkLuaModifier("modifier_boss_stopfightingyourself_dupe_items", "abilities/boss/stopfightingyourself/dupe_items.lua", LUA_MODIFIER_MOTION_NONE)

boss_stopfightingyourself_dupe_items = class(AbilityBaseClass)

function boss_stopfightingyourself_dupe_items:GetIntrinsicModifierName()
  return "modifier_boss_stopfightingyourself_dupe_items"
end

---------------------------------------------------------------------------------------------------

modifier_boss_stopfightingyourself_dupe_items = class(ModifierBaseClass)

function modifier_boss_stopfightingyourself_dupe_items:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACKED
  }
end

function modifier_boss_stopfightingyourself_dupe_items:OnAttacked(event)
  local attacker = event.attacker
  local target = event.target
  local parent = self:GetParent()
  local blacklist = {
    "item_gem",
    "item_rapier"
  }

  if target ~= parent then
    return
  end

  if not attacker:IsHero() or not attacker:HasInventory() then
    return
  end

  local ability = self:GetAbility()
  if not ability:IsCooldownReady() then
    return
  end

  for slot = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
    local theirItem = attacker:GetItemInSlot(slot)
    local oldItem = parent:GetItemInSlot(slot)

    if oldItem then
      parent:RemoveItem(oldItem)
    end

    if theirItem then
      if not contains(theirItem:GetName(), blacklist) then
        local ourItem = parent:AddItemByName(theirItem:GetAbilityName())

        if ourItem:RequiresCharges() then
          local charges = theirItem:GetCurrentCharges()
          ourItem:SetCurrentCharges(charges)
        end
      end
    end
  end

  ability:StartCooldown(ability:GetSpecialValueFor('cooldown'))
end
