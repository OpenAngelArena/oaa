LinkLuaModifier("modifier_intrinsic_multiplexer", "modifiers/modifier_intrinsic_multiplexer.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_aeon_disk_oaa_stacking_stats", "items/aeon_disk.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_aeon_disk_oaa_tracker", "items/aeon_disk.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_aeon_disk_oaa_buff", "items/aeon_disk.lua", LUA_MODIFIER_MOTION_NONE)

item_aeon_disk_oaa = class(ItemBaseClass)

function item_aeon_disk_oaa:GetIntrinsicModifierName()
  return "modifier_intrinsic_multiplexer"
end

function item_aeon_disk_oaa:GetIntrinsicModifierNames()
  return {
    "modifier_item_aeon_disk_oaa_stacking_stats",
    "modifier_item_aeon_disk_oaa_tracker"
  }
end

function item_aeon_disk_oaa:ProcsMagicStick()
  return false
end

function item_aeon_disk_oaa:ShouldUseResources()
  return true
end

item_aeon_disk_2 = item_aeon_disk_oaa
item_aeon_disk_3 = item_aeon_disk_oaa
item_aeon_disk_4 = item_aeon_disk_oaa
item_aeon_disk_5 = item_aeon_disk_oaa

---------------------------------------------------------------------------------------------------
-- Parts of Aeon Disk that should stack with other items

modifier_item_aeon_disk_oaa_stacking_stats = class(ModifierBaseClass)

function modifier_item_aeon_disk_oaa_stacking_stats:IsHidden()
  return true
end

function modifier_item_aeon_disk_oaa_stacking_stats:IsDebuff()
  return false
end

function modifier_item_aeon_disk_oaa_stacking_stats:IsPurgable()
  return false
end

function modifier_item_aeon_disk_oaa_stacking_stats:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_aeon_disk_oaa_stacking_stats:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.hp = ability:GetSpecialValueFor("bonus_health")
    self.mana = ability:GetSpecialValueFor("bonus_mana")
  end
end

modifier_item_aeon_disk_oaa_stacking_stats.OnRefresh = modifier_item_aeon_disk_oaa_stacking_stats.OnCreated

function modifier_item_aeon_disk_oaa_stacking_stats:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_MANA_BONUS,
  }
end

function modifier_item_aeon_disk_oaa_stacking_stats:GetModifierHealthBonus()
  return self.hp or self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_aeon_disk_oaa_stacking_stats:GetModifierManaBonus()
  return self.mana or self:GetAbility():GetSpecialValueFor("bonus_mana")
end

---------------------------------------------------------------------------------------------------
-- Parts of Aeon Disk that should NOT stack with other Aeon Disks

modifier_item_aeon_disk_oaa_tracker = class(ModifierBaseClass)

function modifier_item_aeon_disk_oaa_tracker:IsHidden()
  return true
end

function modifier_item_aeon_disk_oaa_tracker:IsDebuff()
  return false
end

function modifier_item_aeon_disk_oaa_tracker:IsPurgable()
  return false
end

function modifier_item_aeon_disk_oaa_tracker:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
  }
end

if IsServer() then
  -- "The damage instance triggering Combo Breaker is negated." That's why we use this instead of OnTakeDamage
  -- OnTakeDamage event also ignores some damage that has hp removal flag
  function modifier_item_aeon_disk_oaa_tracker:GetModifierIncomingDamage_Percentage(keys)
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local attacker = keys.attacker
    local damage = keys.damage
    local damage_flags = keys.damage_flags

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return 0
    end

    -- Don't trigger on self damage
    if attacker == parent then
      return 0
    end

    -- Don't trigger on non-player damage
    if attacker:GetTeamNumber() == DOTA_TEAM_NEUTRALS then -- and not attacker:IsOAABoss()
      return 0
    end

    -- Don't trigger for illusions
    if parent:IsIllusion() then
      return 0
    end

    -- Don't trigger if parent already has Combo Breaker buff
    if parent:HasModifier("modifier_item_aeon_disk_oaa_buff") then
      return 0
    end

    -- Don't trigger if item is not in the inventory
    if not ability or ability:IsNull() then
      return 0
    end

    -- Don't trigger if item is on cooldown or not enough mana
    if not ability:IsCooldownReady() or not ability:IsOwnersManaEnough() then
      return 0
    end

    -- Don't trigger for 0 or negative damage
    if damage <= 0 then
      return 0
    end

    -- Don't trigger on damage with HP removal flag
    if bit.band(damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then
      return 0
    end

    local buff_duration = ability:GetSpecialValueFor("buff_duration")
    local health_threshold_pct = ability:GetSpecialValueFor("health_threshold_pct") / 100

    local current_health = parent:GetHealth()
    local current_health_pct = current_health / parent:GetMaxHealth()
    local health_pct_after_dmg = (current_health - damage) / parent:GetMaxHealth()

    if current_health_pct < health_threshold_pct or health_pct_after_dmg <= health_threshold_pct then
      -- Sound
      parent:EmitSound("DOTA_Item.ComboBreaker")

      -- Strong Dispel
      parent:Purge(false, true, false, true, true)

      -- Apply Combo Breaker buff
      parent:AddNewModifier(parent, ability, "modifier_item_aeon_disk_oaa_buff", {duration = buff_duration})

      -- If current_health_pct < health_threshold_pct then hp = current_health; If current_health_pct > health_threshold_pct then hp = max_hp * health_threshold_pct
      parent:SetHealth(math.min(current_health, parent:GetMaxHealth() * health_threshold_pct))

      -- Start cooldown, spend mana
      ability:UseResources(true, true, true)

      return -100
    end

    return 0
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

  if IsServer() then
    local parent = self:GetParent()
    local particle = ParticleManager:CreateParticle("particles/items4_fx/combo_breaker_buff.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControlEnt(particle, 1, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
    self:AddParticle(particle, false, false, -1, true, false)
  end
end

modifier_item_aeon_disk_oaa_buff.OnRefresh = modifier_item_aeon_disk_oaa_buff.OnCreated

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
