-- modifier_item_devastator_desolator
LinkLuaModifier("modifier_item_devastator_corruption_armor", "modifiers/modifier_item_devastator_corruption_armor.lua", LUA_MODIFIER_MOTION_NONE)

modifier_item_devastator_desolator = class(ModifierBaseClass)

function modifier_item_devastator_desolator:IsHidden()
  return true
end

function modifier_item_devastator_desolator:IsDebuff()
  return false
end

function modifier_item_devastator_desolator:IsPurgable()
  return false
end

function modifier_item_devastator_desolator:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_devastator_desolator:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_damage = ability:GetSpecialValueFor("bonus_damage")
  end

  if IsServer() then
    self:GetParent():ChangeAttackProjectile()
  end
end

modifier_item_devastator_desolator.OnRefresh = modifier_item_devastator_desolator.OnCreated

function modifier_item_devastator_desolator:OnDestroy()
  local parent = self:GetParent()
  if IsServer() and parent and not parent:IsNull() then
    parent:ChangeAttackProjectile()
  end
end

function modifier_item_devastator_desolator:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE
  }
end

function modifier_item_devastator_desolator:GetModifierPreAttack_BonusDamage()
  return self.bonus_damage or self:GetAbility():GetSpecialValueFor("bonus_damage")
end

if IsServer() then
  function modifier_item_devastator_desolator:OnAttackLanded(event)
    if not self:IsFirstItemInInventory() then
      return
    end

    local parent = self:GetParent()
    local ability = self:GetAbility()
    local target = event.target

    if parent ~= event.attacker then
      return
    end

    if parent:IsIllusion() then
      return
    end

    -- To prevent crashes:
    if not target or target:IsNull() then
      return
    end

    -- Check for existence of GetUnitName method to determine if target is a unit or an item (or rune)
    -- items don't have that method -> nil; if the target is an item, don't continue
    if target.GetUnitName == nil then
      return
    end

    -- Doesn't work on allies
    if target:GetTeamNumber() == parent:GetTeamNumber() then
      return
    end

    -- If the target has desolator debuff then remove it (to prevent stacking armor reductions)
    if target:HasModifier("modifier_desolator_buff") then
      target:RemoveModifierByName("modifier_desolator_buff")
    end

    local armor_reduction = ability:GetSpecialValueFor( "devastator_armor_reduction" )
    local corruption_armor = ability:GetSpecialValueFor( "corruption_armor" )

    -- If the target has Devastator active debuff
    if target:HasModifier("modifier_item_devastator_reduce_armor") then
      -- If devastator_armor_reduction (active armor reduction) is higher than corruption_armor (passive armor reduction) then do nothing
      if math.abs(armor_reduction) > math.abs(corruption_armor) then
        return
      end
      -- If devastator_armor_reduction is lower than corruption_armor then remove the Devastator active debuff
      target:RemoveModifierByName("modifier_item_devastator_reduce_armor")
    end

    -- Calculate duration of the debuff
    local corruption_duration = ability:GetSpecialValueFor("corruption_duration")
    -- Calculate duration while keeping status resistance in mind
    local armor_reduction_duration = target:GetValueChangedByStatusResistance(corruption_duration)
    -- Apply Devastator passive debuff
    target:AddNewModifier( parent, ability, "modifier_item_devastator_corruption_armor", {duration = armor_reduction_duration})
  end
end
