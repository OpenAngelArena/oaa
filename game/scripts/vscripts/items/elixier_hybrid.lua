-- Azazel's Hybrid Elixiers
-- by Firetoad, April 1st, 2018
-- changed and modified by Darkonius many times

--------------------------------------------------------------------------------

LinkLuaModifier("modifier_elixier_hybrid_active", "items/elixier_hybrid.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_elixier_hybrid_not_allowed", "items/elixier_hybrid.lua", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

item_elixier_hybrid = class(ItemBaseClass)

function item_elixier_hybrid:OnSpellStart()
  local caster = self:GetCaster()

  -- Activation sound
  caster:EmitSound("DOTA_Item.FaerieSpark.Activate")

  -- Apply a buff
  local buff = caster:AddNewModifier(caster, self, "modifier_elixier_hybrid_active", {duration = self:GetSpecialValueFor("duration")})
  buff.regen = self:GetSpecialValueFor("bonus_mana_regen")
  buff.magic_damage = self:GetSpecialValueFor("bonus_magic_damage")
  buff.physical_damage = self:GetSpecialValueFor("bonus_physical_damage")

  -- Consume the item
  self:SpendCharge(0.1)
end

--------------------------------------------------------------------------------

modifier_elixier_hybrid_active = class(ModifierBaseClass)

function modifier_elixier_hybrid_active:IsHidden()
  return false
end

function modifier_elixier_hybrid_active:IsPurgable()
  return false
end

function modifier_elixier_hybrid_active:IsDebuff()
  return false
end

function modifier_elixier_hybrid_active:RemoveOnDeath()
  return false
end

function modifier_elixier_hybrid_active:GetEffectName()
  return "particles/items/elixiers/elixier_hybrid.vpcf" --"particles/items/elixiers/elixier_hybrid_lesser.vpcf"
end

function modifier_elixier_hybrid_active:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_elixier_hybrid_active:GetTexture()
  return "custom/elixier_hybrid"
end

function modifier_elixier_hybrid_active:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.regen = ability:GetSpecialValueFor("bonus_mana_regen")
    self.magic_damage = ability:GetSpecialValueFor("bonus_magic_damage")
    self.physical_damage = ability:GetSpecialValueFor("bonus_physical_damage")
  else
    self.regen = self.regen or 10
    self.magic_damage = self.magic_damage or 200
    self.physical_damage = self.physical_damage or 300
  end
end

function modifier_elixier_hybrid_active:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
    MODIFIER_EVENT_ON_TAKEDAMAGE,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

function modifier_elixier_hybrid_active:GetModifierConstantManaRegen()
  return self.regen
end

if IsServer() then
  function modifier_elixier_hybrid_active:OnTakeDamage(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local damaged_unit = event.unit
    local dmg_flags = event.damage_flags
    local damage_type = event.damage_type
    local inflictor = event.inflictor

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if attacker ~= parent then
      return
    end

    -- Check if damaged entity exists
    if not damaged_unit or damaged_unit:IsNull() then
      return
    end

    -- Ignore self damage
    if damaged_unit == attacker then
      return
    end

    -- Check if entity is an item, rune or something weird
    if damaged_unit.GetUnitName == nil then
      return
    end

    -- Don't affect buildings, wards and invulnerable units.
    if damaged_unit:IsTower() or damaged_unit:IsBarracks() or damaged_unit:IsBuilding() or damaged_unit:IsOther() or damaged_unit:IsInvulnerable() then
      return
    end

    -- Don't continue if damage has HP removal flag
    if bit.band(dmg_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then
      return
    end

    -- Don't continue if damage has Reflection flag
    if bit.band(dmg_flags, DOTA_DAMAGE_FLAG_REFLECTION) == DOTA_DAMAGE_FLAG_REFLECTION then
      return
    end

    -- Don't proc on pure damage
    if damage_type == DAMAGE_TYPE_PURE then
      return
    end

    --if event.damage <= 0 then
      --return
    --end

    -- Don't proc on damage from attacks (we use OnAttackLanded for that);
    -- it also prevents procing on itself (prevents infinite loop)
    -- because source of proc damage is nil
    if not inflictor then
      return
    end

    -- Don't proc on stuff that procs on any damage
    -- it prevents infinite damage loop (proc on damage proc)
    local non_trigger_inflictors = {
      ["batrider_sticky_napalm"] = true,
      ["batrider_sticky_napalm_oaa"] = true,
      ["item_trumps_fists"] = true,           -- Blade of Judecca
      ["item_trumps_fists_2"] = true,
    }

    if non_trigger_inflictors[inflictor:GetName()] then
      return
    end

    -- Check if modifier_elixier_hybrid_not_allowed is applied to prevent proccing on DOTs with with short time intervals
    if damaged_unit:FindModifierByNameAndCaster("modifier_elixier_hybrid_not_allowed", parent) then
      return
    end

    -- Add a modifier before dealing damage
    damaged_unit:AddNewModifier(parent, nil, "modifier_elixier_hybrid_not_allowed", {duration = 0.5})

    -- Create a damage table for proc damage
    local damage_table = {
      attacker = parent,
      victim = damaged_unit,
    }

    -- Set damage, damage type and overhead alert for the proc damage
    local overhead_alert = OVERHEAD_ALERT_BONUS_SPELL_DAMAGE
    if damage_type == DAMAGE_TYPE_PHYSICAL then
      damage_table.damage = self.magic_damage
      damage_table.damage_type = DAMAGE_TYPE_MAGICAL
      overhead_alert = OVERHEAD_ALERT_BONUS_SPELL_DAMAGE
    elseif damage_type == DAMAGE_TYPE_MAGICAL then
      damage_table.damage = self.physical_damage
      damage_table.damage_type = DAMAGE_TYPE_PHYSICAL
      damage_table.damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_PHYSICAL_BLOCK
      overhead_alert = OVERHEAD_ALERT_DAMAGE
    end

    local damage_dealt = ApplyDamage(damage_table)
    SendOverheadEventMessage(parent:GetPlayerOwner(), overhead_alert, damaged_unit, damage_dealt, parent:GetPlayerOwner())
  end

  function modifier_elixier_hybrid_active:OnAttackLanded(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local target = event.target -- attacked unit

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Do nothing if attacker doesn't have this buff
    if attacker ~= parent then
      return
    end

    -- Don't continue if target doesn't exist or if target is about to be deleted
    if not target or target:IsNull() then
      return
    end

    -- Check if attacked entity is an item, rune or something weird
    if target.GetUnitName == nil then
      return
    end

    -- Create a damage table for proc damage
    local damage_table = {
      attacker = parent,
      victim = target,
      damage = self.magic_damage,
      damage_type = DAMAGE_TYPE_MAGICAL,
    }

    local damage_dealt = ApplyDamage(damage_table)
    SendOverheadEventMessage(parent:GetPlayerOwner(), OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, target, damage_dealt, parent:GetPlayerOwner())
  end
end

---------------------------------------------------------------------------------------------------

modifier_elixier_hybrid_not_allowed = class(ModifierBaseClass)

function modifier_elixier_hybrid_not_allowed:IsHidden()
  return true
end

function modifier_elixier_hybrid_not_allowed:IsPurgable()
  return false
end

function modifier_elixier_hybrid_not_allowed:IsDebuff()
  return false
end

function modifier_elixier_hybrid_not_allowed:RemoveOnDeath()
  return true
end
