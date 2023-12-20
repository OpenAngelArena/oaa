LinkLuaModifier("modifier_item_dragon_scale_oaa_passive", "items/neutral/dragon_scale.lua", LUA_MODIFIER_MOTION_NONE)

item_dragon_scale_oaa = class(ItemBaseClass)

function item_dragon_scale_oaa:GetIntrinsicModifierName()
  return "modifier_item_dragon_scale_oaa_passive"
end

function item_dragon_scale_oaa:ShouldUseResources()
  return true
end

---------------------------------------------------------------------------------------------------

modifier_item_dragon_scale_oaa_passive = class(ModifierBaseClass)

function modifier_item_dragon_scale_oaa_passive:IsHidden()
  return true
end
function modifier_item_dragon_scale_oaa_passive:IsDebuff()
  return false
end
function modifier_item_dragon_scale_oaa_passive:IsPurgable()
  return false
end

function modifier_item_dragon_scale_oaa_passive:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.armor = ability:GetSpecialValueFor("bonus_armor")
    self.hp_regen = ability:GetSpecialValueFor("bonus_hp_regen")
  end
end

modifier_item_dragon_scale_oaa_passive.OnRefresh = modifier_item_dragon_scale_oaa_passive.OnCreated

function modifier_item_dragon_scale_oaa_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_EVENT_ON_TAKEDAMAGE,
  }
end

function modifier_item_dragon_scale_oaa_passive:GetModifierPhysicalArmorBonus()
  return self.armor or self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_item_dragon_scale_oaa_passive:GetModifierConstantHealthRegen()
  return self.hp_regen or self:GetAbility():GetSpecialValueFor("bonus_hp_regen")
end

if IsServer() then
  function modifier_item_dragon_scale_oaa_passive:OnTakeDamage(event)
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local attacker = event.attacker
    local unit = event.unit -- damaged unit

    -- Don't continue if attacker doesn't exist or if attacker is about to be deleted
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if damaged entity exists
    if not unit or unit:IsNull() then
      return
    end

    -- Do nothing if damaged unit doesn't have this buff
    if unit ~= parent or not ability then
      return
    end

    local damage_flags = event.damage_flags

    -- Don't continue if damage has HP removal flag
    if bit.band(damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then
      return
    end

    -- Don't continue if damage has Reflection flag
    if bit.band(damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) == DOTA_DAMAGE_FLAG_REFLECTION then
      return
    end

    -- Don't trigger on self damage or on damage originating from allies
    if attacker == parent or attacker:GetTeamNumber() == parent:GetTeamNumber() then
      return
    end

    -- Don't trigger if attacker is dead, invulnerable or banished
    if not attacker:IsAlive() or attacker:IsInvulnerable() or attacker:IsOutOfGame() then
      return
    end

    -- Don't trigger on buildings, towers and wards
    if attacker:IsBuilding() or attacker:IsTower() or attacker:IsOther() then
      return
    end

    if not ability:IsCooldownReady() then
      return
    end

    local damage_type = DAMAGE_TYPE_MAGICAL --event.damage_type

    -- Create a damage table
    local damage_table = {
      attacker = parent,
      victim = attacker,
      damage = ability:GetSpecialValueFor("afterburn_damage"),
      damage_type = damage_type,
      damage_flags = bit.bor(DOTA_DAMAGE_FLAG_REFLECTION, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL, DOTA_DAMAGE_FLAG_BYPASSES_BLOCK),
      ability = ability,
    }

    -- Set overhead alert
    local overhead_alert = OVERHEAD_ALERT_BONUS_SPELL_DAMAGE
    if damage_type == DAMAGE_TYPE_PHYSICAL then
      overhead_alert = OVERHEAD_ALERT_DAMAGE
    elseif damage_type == DAMAGE_TYPE_MAGICAL then
      overhead_alert = OVERHEAD_ALERT_BONUS_SPELL_DAMAGE
    end

    local damage_dealt = ApplyDamage(damage_table)
    SendOverheadEventMessage(parent:GetPlayerOwner(), overhead_alert, attacker, damage_dealt, parent:GetPlayerOwner())

    -- Start cooldown because of low interval dmg instances
    ability:UseResources(false, false, false, true)
  end
end
