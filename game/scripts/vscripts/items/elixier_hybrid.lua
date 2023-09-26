-- Azazel's Hybrid Elixiers
-- by Firetoad, April 1st, 2018

--------------------------------------------------------------------------------

LinkLuaModifier("modifier_elixier_hybrid_active", "items/elixier_hybrid.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_elixier_hybrid_trigger", "items/elixier_hybrid.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_elixier_hybrid_not_allowed", "items/elixier_hybrid.lua", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

item_elixier_hybrid = class(ItemBaseClass)

function item_elixier_hybrid:OnSpellStart()
  local caster = self:GetCaster()

  caster:EmitSound("DOTA_Item.FaerieSpark.Activate")

  caster:RemoveModifierByName("modifier_elixier_burst_active")
  caster:RemoveModifierByName("modifier_elixier_burst_trigger")
  caster:RemoveModifierByName("modifier_elixier_burst_bonus")
  caster:RemoveModifierByName("modifier_elixier_sustain_active")
  caster:RemoveModifierByName("modifier_elixier_sustain_trigger")
  caster:RemoveModifierByName("modifier_elixier_hybrid_active")
  caster:RemoveModifierByName("modifier_elixier_hybrid_trigger")

  caster:AddNewModifier(caster, self, "modifier_elixier_hybrid_active", {duration = self:GetSpecialValueFor("bonus_duration")})
  caster:AddNewModifier(caster, self, "modifier_elixier_hybrid_trigger", {duration = self:GetSpecialValueFor("bonus_duration")})

  self:SpendCharge()
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
  return "particles/items/elixiers/elixier_hybrid_lesser.vpcf"
end

function modifier_elixier_hybrid_active:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_elixier_hybrid_active:GetTexture()
  return "custom/elixier_hybrid_2"
end

function modifier_elixier_hybrid_active:OnCreated()
  if IsServer() then
    self.regen = self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
    self:SetStackCount(self.regen)
  end
end

function modifier_elixier_hybrid_active:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
    --MODIFIER_EVENT_ON_ABILITY_FULLY_CAST
  }
end

function modifier_elixier_hybrid_active:GetModifierConstantManaRegen()
  return self:GetStackCount()
end

-- function modifier_elixier_hybrid_active:OnAbilityFullyCast(keys)
  -- if IsServer() then
    -- if keys.unit == self:GetParent() and not keys.ability:IsItem() then
      -- self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_elixier_hybrid_trigger", {damage = self.damage, duration = self:GetRemainingTime()})
    -- end
  -- end
-- end

--------------------------------------------------------------------------------

modifier_elixier_hybrid_trigger = class(ModifierBaseClass)

function modifier_elixier_hybrid_trigger:IsHidden()
  return false
end

function modifier_elixier_hybrid_trigger:IsPurgable()
  return false
end

function modifier_elixier_hybrid_trigger:IsDebuff()
  return false
end

function modifier_elixier_hybrid_trigger:RemoveOnDeath()
  return false
end

function modifier_elixier_hybrid_trigger:GetEffectName()
  return "particles/items/elixiers/elixier_hybrid.vpcf"
end

function modifier_elixier_hybrid_trigger:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_elixier_hybrid_trigger:GetTexture()
  return "custom/elixier_hybrid_2"
end

function modifier_elixier_hybrid_trigger:OnCreated(keys)
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.magic_damage = ability:GetSpecialValueFor("bonus_magic_damage")
    self.physical_damage = ability:GetSpecialValueFor("bonus_physical_damage")
  else
    self.magic_damage = 200
    self.physical_damage = 300
  end
end

function modifier_elixier_hybrid_trigger:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_TAKEDAMAGE,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

if IsServer() then
  function modifier_elixier_hybrid_trigger:OnTakeDamage(event)
    local parent = self:GetParent()
    --local ability = self:GetAbility() -- always nil, probably because its a consumable item, thx Valve
    local attacker = event.attacker
    local unit = event.unit -- damaged unit

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Do nothing if attacker doesn't have this buff
    if attacker ~= parent then
      return
    end

    -- Don't continue if unit doesn't exist or if unit is about to be deleted
    if not unit or unit:IsNull() then
      return
    end

    -- Don't continue if its self damage
    if parent == unit then
      return
    end

    -- Don't continue if damage has HP removal flag
    if bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then
      return
    end

    -- Don't continue if damage has Reflection flag
    if bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) == DOTA_DAMAGE_FLAG_REFLECTION then
      return
    end

    local damage_type = event.damage_type

    -- Don't proc on pure damage
    if damage_type == DAMAGE_TYPE_PURE then
      return
    end

    -- Don't proc on damage from attacks (we use OnAttackLanded for that);
    -- it also prevents procing on itself (prevents infinite loop)
    -- because source of proc damage is nil
    local inflictor = event.inflictor
    if not inflictor then
      return
    end

    -- Don't proc on stuff that procs on any damage
    -- it prevents infinite damage loop (proc on damage proc)
    local non_trigger_inflictors = {
      ["batrider_sticky_napalm"] = true,
      ["batrider_sticky_napalm_oaa"] = true,
      --["item_orb_of_venom"] = true,
      --["item_orb_of_corrosion"] = true,
      --["item_radiance"] = true,
      --["item_radiance_2"] = true,
      --["item_radiance_3"] = true,
      --["item_radiance_4"] = true,
      --["item_radiance_5"] = true,
      --["item_urn_of_shadows"] = true,
      --["item_spirit_vessel"] = true,
      --["item_spirit_vessel_oaa"] = true,
      --["item_spirit_vessel_2"] = true,
      --["item_spirit_vessel_3"] = true,
      --["item_spirit_vessel_4"] = true,
      --["item_spirit_vessel_5"] = true,
      --["item_cloak_of_flames"] = true,
      ["item_trumps_fists"] = true,           -- Blade of Judecca
      ["item_trumps_fists_2"] = true,
      --["item_silver_staff"] = true,
      --["item_silver_staff_2"] = true,
      --["item_paintball"] = true,              -- Fae Grenade
    }

    if non_trigger_inflictors[inflictor:GetName()] then
      return
    end

    -- Check if modifier_elixier_hybrid_not_allowed is applied to prevent proccing on DOTs with with short time intervals
    if unit:FindModifierByNameAndCaster("modifier_elixier_hybrid_not_allowed", parent) then
      return
    end

    -- Add a modifier before dealing damage
    unit:AddNewModifier(parent, nil, "modifier_elixier_hybrid_not_allowed", {duration = 0.5})

    -- Create a damage table for proc damage
    local damage_table = {
      attacker = parent,
      victim = unit,
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
      damage_table.damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_BLOCK
      overhead_alert = OVERHEAD_ALERT_DAMAGE
    end

    local damage_dealt = ApplyDamage(damage_table)
    SendOverheadEventMessage(parent:GetPlayerOwner(), overhead_alert, unit, damage_dealt, parent:GetPlayerOwner())
  end

  function modifier_elixier_hybrid_trigger:OnAttackLanded(event)
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
