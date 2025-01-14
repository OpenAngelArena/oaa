LinkLuaModifier("modifier_item_aeon_disk_oaa_passive", "items/aeon_disk.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_aeon_disk_oaa_buff", "items/aeon_disk.lua", LUA_MODIFIER_MOTION_NONE)

item_aeon_disk_oaa_1 = class(ItemBaseClass)

function item_aeon_disk_oaa_1:GetIntrinsicModifierName()
  return "modifier_item_aeon_disk_oaa_passive"
end

function item_aeon_disk_oaa_1:ShouldUseResources()
  return true
end

item_aeon_disk_oaa_2 = item_aeon_disk_oaa_1
item_aeon_disk_oaa_3 = item_aeon_disk_oaa_1
item_aeon_disk_oaa_4 = item_aeon_disk_oaa_1
item_aeon_disk_oaa_5 = item_aeon_disk_oaa_1

---------------------------------------------------------------------------------------------------

modifier_item_aeon_disk_oaa_passive = class(ModifierBaseClass)

function modifier_item_aeon_disk_oaa_passive:IsHidden()
  return true
end

function modifier_item_aeon_disk_oaa_passive:IsDebuff()
  return false
end

function modifier_item_aeon_disk_oaa_passive:IsPurgable()
  return false
end

function modifier_item_aeon_disk_oaa_passive:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_aeon_disk_oaa_passive:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.hp = ability:GetSpecialValueFor("bonus_health")
    self.mana = ability:GetSpecialValueFor("bonus_mana")
  end
end

modifier_item_aeon_disk_oaa_passive.OnRefresh = modifier_item_aeon_disk_oaa_passive.OnCreated

function modifier_item_aeon_disk_oaa_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_MANA_BONUS,
    --MODIFIER_PROPERTY_AVOID_DAMAGE,
    MODIFIER_PROPERTY_AVOID_DAMAGE_AFTER_REDUCTIONS,
  }
end

function modifier_item_aeon_disk_oaa_passive:GetModifierHealthBonus()
  return self.hp or self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_aeon_disk_oaa_passive:GetModifierManaBonus()
  return self.mana or self:GetAbility():GetSpecialValueFor("bonus_mana")
end

-- Things we need to mimic:
-- 1) The damage instance triggering Aeon Disk is negated.
-- 2) Instant kill abilities ignore Aeon Disk trigger, Aeon Disk doesnt go on cd
-- 3) Ignoring self and damage with hp removal flag
if IsServer() then
  function modifier_item_aeon_disk_oaa_passive:GetModifierAvoidDamageAfterReductions(event)
    if not self:IsFirstItemInInventory() then
      return 0
    end

    local parent = self:GetParent()
    local ability = self:GetAbility()
    local attacker = event.attacker
    local damaged_unit = event.target
    local damage_after = event.damage -- after reductions
    local damage_before = event.original_damage -- before reductions
    local damage_flags = event.damage_flags

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return 0
    end

    -- Check if attacker is a valid entity
    if attacker.GetTeamNumber == nil then
      return 0
    end

    -- Don't trigger on non-player damage
    if attacker:GetTeamNumber() == DOTA_TEAM_NEUTRALS then -- and not attacker:IsOAABoss()
      return 0
    end

    -- Don't trigger on self damage
    if attacker == parent then -- or attacker:GetTeamNumber() == parent:GetTeamNumber() then
      return 0
    end

    -- Check if damaged unit exists
    if not damaged_unit or damaged_unit:IsNull() then
      return 0
    end

    -- Check if damaged unit has this modifier
    if damaged_unit ~= parent then
      return 0
    end

    -- Don't trigger for illusions
    if parent:IsIllusion() then
      return 0
    end

    -- Don't trigger on damage with HP removal flag
    if bit.band(damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then
      return 0
    end

    -- Don't trigger for 0 or negative damage
    if damage_before <= 0 or damage_after <= 0 then
      return 0
    end

    -- Don't trigger if item is not in the inventory
    if not ability or ability:IsNull() then
      return 0
    end

    local buff_duration = ability:GetSpecialValueFor("buff_duration")
    local health_threshold_pct = ability:GetSpecialValueFor("health_threshold_pct") / 100

    local current_health = parent:GetHealth()
    local max_health = parent:GetMaxHealth()
    local health_pct = current_health / max_health -- health pct before damage occured

    if (health_pct <= health_threshold_pct or current_health - damage_after <= 1) and ability:IsCooldownReady() and ability:IsOwnersManaEnough() and parent:IsAlive() then
      -- Sound
      parent:EmitSound("DOTA_Item.ComboBreaker")

      -- Strong Dispel (for the caster)
      parent:Purge(false, true, false, true, true)

      -- Apply Combo Breaker buff
      parent:AddNewModifier(parent, ability, "modifier_item_aeon_disk_oaa_buff", {duration = buff_duration})

      -- Start cooldown, spend mana
      ability:UseResources(true, false, false, true)

      return 1
    end
  end
end

---------------------------------------------------------------------------------------------------

modifier_item_aeon_disk_oaa_buff = class(ModifierBaseClass)

function modifier_item_aeon_disk_oaa_buff:IsHidden()
  return false
end

function modifier_item_aeon_disk_oaa_buff:IsDebuff()
  return false
end

function modifier_item_aeon_disk_oaa_buff:IsPurgable()
  return true
end

function modifier_item_aeon_disk_oaa_buff:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.status_resist = ability:GetSpecialValueFor("status_resistance")
  end

  if IsServer() and self.particle == nil then
    local parent = self:GetParent()
    self.particle = ParticleManager:CreateParticle("particles/items4_fx/combo_breaker_buff.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControlEnt(self.particle, 1, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
  end
end

function modifier_item_aeon_disk_oaa_buff:OnRefresh()
  if IsServer() and self.particle then
    ParticleManager:DestroyParticle(self.particle, true)
    ParticleManager:ReleaseParticleIndex(self.particle)
    self.particle = nil
  end
  self:OnCreated()
end

function modifier_item_aeon_disk_oaa_buff:OnDestroy()
  if IsServer() and self.particle then
    ParticleManager:DestroyParticle(self.particle, false)
    ParticleManager:ReleaseParticleIndex(self.particle)
    self.particle = nil
  end
end

function modifier_item_aeon_disk_oaa_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
    --MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    --MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
    --MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
  }
end

function modifier_item_aeon_disk_oaa_buff:GetModifierIncomingDamage_Percentage()
  return -100
end

function modifier_item_aeon_disk_oaa_buff:GetModifierTotalDamageOutgoing_Percentage()
  return -100
end

function modifier_item_aeon_disk_oaa_buff:GetModifierStatusResistanceStacking()
  return self.status_resist or self:GetAbility():GetSpecialValueFor("status_resistance")
end

-- function modifier_item_aeon_disk_oaa_buff:GetAbsoluteNoDamagePhysical()
  -- return 1
-- end

-- function modifier_item_aeon_disk_oaa_buff:GetAbsoluteNoDamageMagical()
  -- return 1
-- end

-- function modifier_item_aeon_disk_oaa_buff:GetAbsoluteNoDamagePure()
  -- return 1
-- end

function modifier_item_aeon_disk_oaa_buff:GetStatusEffectName()
  return "particles/status_fx/status_effect_combo_breaker.vpcf"
end

function modifier_item_aeon_disk_oaa_buff:StatusEffectPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA
end

function modifier_item_aeon_disk_oaa_buff:GetTexture()
  return "item_aeon_disk"
end
