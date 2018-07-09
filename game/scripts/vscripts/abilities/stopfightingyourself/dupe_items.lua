
LinkLuaModifier("modifier_boss_stopfightingyourself_dupe_items", "abilities/stopfightingyourself/dupe_items.lua", LUA_MODIFIER_MOTION_NONE)


boss_stopfightingyourself_dupe_items = class(AbilityBaseClass)

function boss_stopfightingyourself_dupe_items:GetIntrinsicModifierName()
  return "modifier_boss_stopfightingyourself_dupe_items"
end


modifier_boss_stopfightingyourself_dupe_items = class(ModifierBaseClass)

function modifier_boss_stopfightingyourself_dupe_items:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACKED
  }
end

function modifier_boss_stopfightingyourself_dupe_items:OnAttacked(keys)
  local attacker = keys.attacker
  local target = keys.target
  local caster = self:GetCaster()
  local blacklist = {
    "item_gem",
    "item_rapier"
  }

  if not self:GetAbility():IsCooldownReady() then
    return
  end

  if caster == target then
    for slot=DOTA_ITEM_SLOT_1,DOTA_ITEM_SLOT_6 do
      local theirItem = attacker:GetItemInSlot(slot)
      local oldItem = caster:GetItemInSlot(slot)

      if oldItem then
        caster:RemoveItem(oldItem)
      end

      if theirItem then
        if not contains(theirItem:GetName(), blacklist) then
          local ourItem = caster:AddItemByName(theirItem:GetAbilityName())

          if ourItem:RequiresCharges() then
            local charges = theirItem:GetCurrentCharges()
            ourItem:SetCurrentCharges(charges)
          end
        end
      end
    end
  end

  self:GetAbility():StartCooldown(self:GetAbility():GetSpecialValueFor('cooldown'))
end
