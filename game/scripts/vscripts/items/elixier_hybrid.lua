-- Azazel's Hybrid Elixiers
-- by Firetoad, April 1st, 2018

--------------------------------------------------------------------------------

LinkLuaModifier("modifier_elixier_hybrid_active", "items/elixier_hybrid.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_elixier_hybrid_trigger", "items/elixier_hybrid.lua", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

item_elixier_hybrid = class(ItemBaseClass)

function item_elixier_hybrid:OnSpellStart()
  if IsServer() then
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
end

--------------------------------------------------------------------------------

modifier_elixier_hybrid_active = class(ModifierBaseClass)

function modifier_elixier_hybrid_active:IsHidden() return false end
function modifier_elixier_hybrid_active:IsPurgable() return false end
function modifier_elixier_hybrid_active:IsDebuff() return false end

function modifier_elixier_hybrid_active:GetEffectName()
  return "particles/items/elixiers/elixier_hybrid_lesser.vpcf"
end

function modifier_elixier_hybrid_active:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_elixier_hybrid_active:GetAbilityTextureName()
  return "custom/elixier_hybrid_1"
end

function modifier_elixier_hybrid_active:OnCreated()
  if IsServer() then
    self.regen = self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
    --self.damage = self:GetAbility():GetSpecialValueFor("bonus_damage")
    self:SetStackCount(self.regen)
  end
end

function modifier_elixier_hybrid_active:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
    --MODIFIER_EVENT_ON_ABILITY_FULLY_CAST
  }
  return funcs
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

function modifier_elixier_hybrid_trigger:IsHidden() return false end
function modifier_elixier_hybrid_trigger:IsPurgable() return false end
function modifier_elixier_hybrid_trigger:IsDebuff() return false end

function modifier_elixier_hybrid_trigger:GetEffectName()
  return "particles/items/elixiers/elixier_hybrid.vpcf"
end

function modifier_elixier_hybrid_trigger:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_elixier_hybrid_trigger:GetAbilityTextureName()
  return "custom/elixier_hybrid_1"
end

function modifier_elixier_hybrid_trigger:OnCreated(keys)
  if IsServer() then
    self.magic_damage = self:GetAbility():GetSpecialValueFor("bonus_magic_damage")
    self.physical_damage = self:GetAbility():GetSpecialValueFor("bonus_physical_damage")
  end
end

function modifier_elixier_hybrid_trigger:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_TAKEDAMAGE,
  }
  return funcs
end

function modifier_elixier_hybrid_trigger:OnTakeDamage(event)
  if IsServer() then
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local unit = event.unit

    -- Do nothing if attacker doesn't have this buff
    if parent ~= event.attacker then
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

    -- Don't continue if unit doesn't exist or if unit is about to be deleted
    if not unit or unit:IsNull() then
      return
    end

    local damage_type = event.damage_type

    -- Don't proc on pure damage
    if damage_type == DAMAGE_TYPE_PURE then
      return
    end

    -- Don't proc on itself
    if ability == event.inflictor then
      return
    end

    -- Create a damage table for proc damage
    local damage_table = {}
    damage_table.attacker = parent
    damage_table.ability = ability
    damage_table.damage = 200
    damage_table.victim = unit
    damage_table.damage_type = DAMAGE_TYPE_MAGICAL

    -- Set damage, damage type and overhead alert for the proc damage
    local overhead_alert = OVERHEAD_ALERT_DAMAGE
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
end
