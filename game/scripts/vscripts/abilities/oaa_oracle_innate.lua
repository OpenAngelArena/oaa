LinkLuaModifier("modifier_oracle_innate_oaa", "abilities/oaa_oracle_innate.lua", LUA_MODIFIER_MOTION_NONE)

oracle_innate_oaa = class(AbilityBaseClass)

function oracle_innate_oaa:GetIntrinsicModifierName()
  return "modifier_oracle_innate_oaa"
end

---------------------------------------------------------------------------------------------------

modifier_oracle_innate_oaa = class(ModifierBaseClass)

function modifier_oracle_innate_oaa:IsHidden()
  return self:GetStackCount() <= 0
end

function modifier_oracle_innate_oaa:IsDebuff()
  return false
end

function modifier_oracle_innate_oaa:IsPurgable()
  return false
end

function modifier_oracle_innate_oaa:RemoveOnDeath()
  return false
end

function modifier_oracle_innate_oaa:OnCreated()
  local ability = self:GetAbility()
  self.speed = ability:GetSpecialValueFor("ms_pct")
  self.duration = ability:GetSpecialValueFor("duration")
end

modifier_oracle_innate_oaa.OnRefresh = modifier_oracle_innate_oaa.OnCreated

function modifier_oracle_innate_oaa:OnIntervalThink()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  if not parent or parent:IsNull() then
    self:StartIntervalThink(-1)
    self:SetStackCount(0)
    return
  end

  if parent:IsIllusion() or not parent:IsAlive() then
    self:StartIntervalThink(-1)
    self:SetStackCount(0)
    return
  end

  if self:GetStackCount() > 0 then
    self:DecrementStackCount()
  else
    self:StartIntervalThink(-1)
  end
end

function modifier_oracle_innate_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_EVENT_ON_HEAL_RECEIVED,
  }
end

function modifier_oracle_innate_oaa:GetModifierMoveSpeedBonus_Percentage()
  local parent = self:GetParent()
  if parent:PassivesDisabled() then
    return 0
  end
  if self:GetStackCount() > 0 then
    return self.speed
  end
  return 0
end

if IsServer() then
  function modifier_oracle_innate_oaa:OnHealReceived(event)
    local parent = self:GetParent()
    local inflictor = event.inflictor -- Heal ability
    local unit = event.unit -- Healed unit
    local amount = event.gain -- Amount healed

    if parent:PassivesDisabled() or parent:IsIllusion() or not parent:IsAlive() then
      return
    end

    local innate = self:GetAbility()
    if not innate or innate:IsNull() then
      return
    end

    -- Don't continue if healing entity/ability doesn't exist
    if not inflictor or inflictor:IsNull() then
      return
    end

    -- Don't continue if healed unit doesn't exist
    if not unit or unit:IsNull() then
      return
    end

    -- Don't continue if healed unit is the parent
    if unit == parent then
      return
    end

    if amount <= 0 then
      return
    end

    local function BuffHealer()
      self:IncrementStackCount()
      self:StartIntervalThink(self.duration)
    end

    -- We check what is inflictor just in case Valve randomly changes inflictor handle type or if someone put a caster instead of the ability when using the Heal method
    if inflictor.GetAbilityName == nil then
      -- Inflictor is not an ability or item
      if parent ~= inflictor then
        -- Inflictor is not the parent -> parent is not the healer
        return
      end

      -- Buff the parent
      BuffHealer()
    else
      -- Inflictor is an ability
      local name = inflictor:GetAbilityName()
      local ability = parent:FindAbilityByName(name)
      if not ability then
        -- Parent doesn't have this ability
        -- Check items:
        local found_item
        for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
          local item = parent:GetItemInSlot(i)
          if item and item:GetName() == name then
            found_item = true
            ability = item
            break
          end
        end
        if not found_item then
          --  Parent doesn't have this item -> parent is not the healer
          return
        end
      end
      if ability:GetLevel() > 0 or ability:IsItem() then
        -- Parent has this ability or item with the same name as inflictor
        -- Check if it's exactly the same by comparing indexes
        if ability:entindex() == inflictor:entindex() then
          -- Indexes are the same -> parent is the healer
          -- if index of the ability changes randomly and this never happens, then thank you Valve
          -- Buff the parent
          BuffHealer()
        end
      end
    end
  end
end
