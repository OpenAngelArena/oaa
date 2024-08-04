LinkLuaModifier("modifier_item_dragon_scale_oaa_passive", "items/neutral/dragon_scale.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_dragon_scale_oaa_debuff", "items/neutral/dragon_scale.lua", LUA_MODIFIER_MOTION_NONE)

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
    self.boss_dmg = ability:GetSpecialValueFor("bonus_boss_damage")
  end
end

modifier_item_dragon_scale_oaa_passive.OnRefresh = modifier_item_dragon_scale_oaa_passive.OnCreated

function modifier_item_dragon_scale_oaa_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
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

    -- Trigger only for this modifier
    if unit ~= parent then
      return
    end

    -- Don't trigger on illusions
    if parent:IsIllusion() then
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

    -- Check if item exists (if it's inside the inventory)
    if not ability or ability:IsNull() then
      return
    end

    local damage = event.damage

    -- If damage is negative or 0, don't continue
    if damage <= 0 then
      return
    end

    -- Apply damage-over-time debuff
    attacker:AddNewModifier(parent, ability, "modifier_item_dragon_scale_oaa_debuff", {duration = ability:GetSpecialValueFor("dragon_skin_debuff_duration")})
  end
end

function modifier_item_dragon_scale_oaa_passive:GetModifierTotalDamageOutgoing_Percentage(event)
  if event.target:IsOAABoss() then
    return self.boss_dmg or self:GetAbility():GetSpecialValueFor("bonus_boss_damage")
  end
  return 0
end

---------------------------------------------------------------------------------------------------

modifier_item_dragon_scale_oaa_debuff = class(ModifierBaseClass)

function modifier_item_dragon_scale_oaa_debuff:IsHidden()
  return false
end

function modifier_item_dragon_scale_oaa_debuff:IsPurgable()
  return true
end

function modifier_item_dragon_scale_oaa_debuff:IsDebuff()
  return true
end

function modifier_item_dragon_scale_oaa_debuff:DestroyOnExpire()
  return true
end

function modifier_item_dragon_scale_oaa_debuff:OnCreated()
  local damage_per_second = 45
  local interval = 1
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    damage_per_second = ability:GetSpecialValueFor("dragon_skin_damage")
    interval = ability:GetSpecialValueFor("damage_interval")
  end
  self.damage_per_interval = damage_per_second*interval
  self.damage_type = DAMAGE_TYPE_MAGICAL

  if IsServer() then
    self:OnIntervalThink()
    self:StartIntervalThink(interval)
  end
end

function modifier_item_dragon_scale_oaa_debuff:OnIntervalThink()
  local parent = self:GetParent()
  local ability = self:GetAbility()
  local caster = self:GetCaster()
  if caster and not caster:IsNull() then
    local new_damage_flags = bit.bor(DOTA_DAMAGE_FLAG_REFLECTION, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL)
    if self.damage_type == DAMAGE_TYPE_PHYSICAL then
      new_damage_flags = bit.bor(new_damage_flags, DOTA_DAMAGE_FLAG_BYPASSES_PHYSICAL_BLOCK)
    end
    -- Create a damage table
    local damage_table = {
      attacker = caster,
      victim = parent,
      damage = self.damage_per_interval,
      damage_type = self.damage_type,
      damage_flags = new_damage_flags,
      ability = ability,
    }

    -- Apply damage on interval
    local damage_dealt = ApplyDamage(damage_table)
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, parent, damage_dealt, nil)
  end
end

function modifier_item_dragon_scale_oaa_debuff:GetTexture()
  return "item_dragon_scale"
end

-- function modifier_item_dragon_scale_oaa_debuff:GetEffectName()
  -- return ""
-- end
