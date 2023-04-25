LinkLuaModifier("modifier_item_magic_lamp_oaa_passive", "items/magic_lamp.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_magic_lamp_oaa_buff", "items/magic_lamp.lua", LUA_MODIFIER_MOTION_NONE)

item_magic_lamp_1 = class(ItemBaseClass)

function item_magic_lamp_1:GetIntrinsicModifierName()
  return "modifier_item_magic_lamp_oaa_passive"
end

function item_magic_lamp_1:ShouldUseResources()
  return true
end

---------------------------------------------------------------------------------------------------

modifier_item_magic_lamp_oaa_passive = class(ModifierBaseClass)

function modifier_item_magic_lamp_oaa_passive:IsHidden()
  return true
end

function modifier_item_magic_lamp_oaa_passive:IsDebuff()
  return false
end

function modifier_item_magic_lamp_oaa_passive:IsPurgable()
  return false
end

function modifier_item_magic_lamp_oaa_passive:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_magic_lamp_oaa_passive:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.hp = ability:GetSpecialValueFor("bonus_health")
    self.mana = ability:GetSpecialValueFor("bonus_mana")
    self.min_hp = ability:GetSpecialValueFor("health_threshold")
    self.heal_pct = ability:GetSpecialValueFor("heal_pct")
  end
end

modifier_item_magic_lamp_oaa_passive.OnRefresh = modifier_item_magic_lamp_oaa_passive.OnCreated

function modifier_item_magic_lamp_oaa_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_MANA_BONUS,
    MODIFIER_PROPERTY_MIN_HEALTH,
    MODIFIER_EVENT_ON_TAKEDAMAGE,
  }
end

function modifier_item_magic_lamp_oaa_passive:GetModifierHealthBonus()
  return self.hp or self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_magic_lamp_oaa_passive:GetModifierManaBonus()
  return self.mana or self:GetAbility():GetSpecialValueFor("bonus_mana")
end

if IsServer() then
  function modifier_item_magic_lamp_oaa_passive:GetMinHealth()
    if not self:IsFirstItemInInventory() then
      return
    end

    local ability = self:GetAbility()
    local parent = self:GetParent()

    -- Don't trigger for illusions, Spirit Bear and Tempest Doubles
    if parent:IsIllusion() or not parent:IsRealHero() or parent:IsTempestDouble() then
      return
    end

    -- Don't trigger if item is not in the inventory
    if not ability or ability:IsNull() then
      return
    end

    if ability:IsCooldownReady() and ability:IsOwnersManaEnough() and not parent:HasModifier("modifier_skeleton_king_reincarnation_scepter_active") then
      return 1
    end

    return
  end

  function modifier_item_magic_lamp_oaa_passive:OnTakeDamage(event)
    if not self:IsFirstItemInInventory() then
      return
    end

    local parent = self:GetParent()
    local ability = self:GetAbility()
    local attacker = event.attacker
    local damaged_unit = event.unit
    local damage = event.damage

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if damaged unit exists
    if not damaged_unit or damaged_unit:IsNull() then
      return
    end

    -- Check if damaged unit has this modifier
    if damaged_unit ~= parent then
      return
    end

    -- Don't trigger for illusions, Spirit Bear and Tempest Doubles
    if parent:IsIllusion() or not parent:IsRealHero() or parent:IsTempestDouble() then
      return
    end

    -- Don't trigger if item is not in the inventory
    if not ability or ability:IsNull() then
      return
    end

    local current_health = parent:GetHealth()
    if damage >= current_health and current_health <= 1 and ability:IsCooldownReady() and ability:IsOwnersManaEnough() then
      -- Sound
      parent:EmitSound("DOTA_Item.MagicLamp.Cast")

      -- Dispel all debuffs (99.99% at least)
      parent:DispelUndispellableDebuffs()
      parent:Purge(false, true, false, true, false)

      -- Particle
      parent:AddNewModifier(parent, ability, "modifier_item_magic_lamp_oaa_buff", {duration = 2})

      -- 'Heal'
      local health_increase = parent:GetMaxHealth() * self.heal_pct * 0.01
      parent:SetHealth(math.max(self.min_hp, health_increase))

      -- Start cooldown, spend mana
      ability:UseResources(true, false, false, true)
    end
  end
end

---------------------------------------------------------------------------------------------------

modifier_item_magic_lamp_oaa_buff = class(ModifierBaseClass)

function modifier_item_magic_lamp_oaa_buff:IsHidden()
  return true
end

function modifier_item_magic_lamp_oaa_buff:IsDebuff()
  return false
end

function modifier_item_magic_lamp_oaa_buff:IsPurgable()
  return false
end

function modifier_item_magic_lamp_oaa_buff:GetEffectName()
  return "particles/items5_fx/magic_lamp.vpcf"
end

