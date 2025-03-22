LinkLuaModifier("modifier_oracle_innate_oaa", "abilities/oaa_oracle_innate.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oracle_innate_oaa_buff", "abilities/oaa_oracle_innate.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oracle_innate_oaa_debuff", "abilities/oaa_oracle_innate.lua", LUA_MODIFIER_MOTION_NONE)

oracle_innate_oaa = class(AbilityBaseClass)

function oracle_innate_oaa:GetIntrinsicModifierName()
  return "modifier_oracle_innate_oaa"
end

---------------------------------------------------------------------------------------------------

modifier_oracle_innate_oaa = class(ModifierBaseClass)

function modifier_oracle_innate_oaa:IsHidden()
  return true
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

function modifier_oracle_innate_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_HEAL_RECEIVED,
  }
end

if IsServer() then
  function modifier_oracle_innate_oaa:OnHealReceived(event)
    local parent = self:GetParent()
    local inflictor = event.inflictor -- Heal ability
    local unit = event.unit -- Healed unit
    local amount = event.gain -- Amount healed

    if parent:PassivesDisabled() or parent:IsIllusion() then
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

    if amount <= 0 then
      return
    end

    local function BuffHealedUnit()
      if unit:GetTeamNumber() == parent:GetTeamNumber() then
        unit:AddNewModifier(parent, innate, "modifier_oracle_innate_oaa_buff", {duration = innate:GetSpecialValueFor("duration")})
      else
        unit:AddNewModifier(parent, innate, "modifier_oracle_innate_oaa_debuff", {duration = innate:GetSpecialValueFor("duration")})
      end
    end

    -- We check what is inflictor just in case Valve randomly changes inflictor handle type or if someone put a caster instead of the ability when using the Heal method
    if inflictor.GetAbilityName == nil then
      -- Inflictor is not an ability or item
      if parent ~= inflictor then
        -- Inflictor is not the parent -> parent is not the healer
        return
      end

      -- Apply buff/debuff to the unit
      BuffHealedUnit()
    else
      -- Inflictor is an ability
      local name = inflictor:GetAbilityName()
      local ability = parent:FindAbilityByName(name)
      if not ability then
        -- Parent doesn't have this ability
        -- Check items:
        local found_item
        local max_slot = DOTA_ITEM_SLOT_6
        if parent:HasModifier("modifier_spoons_stash_oaa") then
          max_slot = DOTA_ITEM_SLOT_9
        end
        for i = DOTA_ITEM_SLOT_1, max_slot do
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
          -- Apply buff/debuff to the unit
          BuffHealedUnit()
        end
      end
    end
  end
end

---------------------------------------------------------------------------------------------------

modifier_oracle_innate_oaa_buff = class(ModifierBaseClass)

function modifier_oracle_innate_oaa_buff:IsHidden()
  return false
end

function modifier_oracle_innate_oaa_buff:IsDebuff()
  return false
end

function modifier_oracle_innate_oaa_buff:IsPurgable()
  return true
end

function modifier_oracle_innate_oaa_buff:OnCreated()
  local ability = self:GetAbility()
  self.move_speed = 10
  self.attack_speed = 10

  if ability and not ability:IsNull() then
    self.move_speed = ability:GetSpecialValueFor("move_speed_bonus")
    self.attack_speed = ability:GetSpecialValueFor("attack_speed_bonus")
  end
end

modifier_oracle_innate_oaa_buff.OnRefresh = modifier_oracle_innate_oaa_buff.OnCreated

function modifier_oracle_innate_oaa_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
  }
end

function modifier_oracle_innate_oaa_buff:GetModifierMoveSpeedBonus_Percentage()
  return math.abs(self.move_speed)
end

function modifier_oracle_innate_oaa_buff:GetModifierAttackSpeedBonus_Constant()
  return math.abs(self.attack_speed)
end

---------------------------------------------------------------------------------------------------

modifier_oracle_innate_oaa_debuff = class(ModifierBaseClass)

function modifier_oracle_innate_oaa_debuff:IsHidden()
  return false
end

function modifier_oracle_innate_oaa_debuff:IsDebuff()
  return true
end

function modifier_oracle_innate_oaa_debuff:IsPurgable()
  return true
end

function modifier_oracle_innate_oaa_debuff:OnCreated()
  local ability = self:GetAbility()
  local move_slow = 10
  local attack_slow = 10

  if ability and not ability:IsNull() then
    move_slow = ability:GetSpecialValueFor("move_speed_slow")
    attack_slow = ability:GetSpecialValueFor("attack_speed_slow")
  end

  -- Move Speed Slow is reduced with Slow Resistance
  self.move_slow = move_slow --parent:GetValueChangedBySlowResistance(move_slow)
  self.attack_slow = attack_slow
end

modifier_oracle_innate_oaa_debuff.OnRefresh = modifier_oracle_innate_oaa_debuff.OnCreated

function modifier_oracle_innate_oaa_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
  }
end

function modifier_oracle_innate_oaa_debuff:GetModifierMoveSpeedBonus_Percentage()
  return 0 - math.abs(self.move_slow)
end

function modifier_oracle_innate_oaa_debuff:GetModifierAttackSpeedBonus_Constant()
  return 0 - math.abs(self.attack_slow)
end
