LinkLuaModifier("modifier_item_martyrs_mail_passive", "items/martyrs_mail.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_martyrs_mail_martyr_active", "items/martyrs_mail.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_martyrs_mail_martyr_aura", "items/martyrs_mail.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_martyrs_mail_death_buff", "items/martyrs_mail.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_martyrs_mail_dummy_stuff", "items/martyrs_mail.lua", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

item_martyrs_mail_1 = class(ItemBaseClass)

function item_martyrs_mail_1:GetIntrinsicModifierName()
  return "modifier_item_martyrs_mail_passive"
end

function item_martyrs_mail_1:OnSpellStart()
	local hCaster = self:GetCaster()
	local martyr_duration = self:GetSpecialValueFor( "martyr_duration" )

	--hCaster:EmitSound("")
	hCaster:AddNewModifier( hCaster, self, "modifier_item_martyrs_mail_martyr_active", { duration = martyr_duration } )
end

--------------------------------------------------------------------------------

modifier_item_martyrs_mail_passive = class(ModifierBaseClass)

function modifier_item_martyrs_mail_passive:IsHidden()
  return true
end

function modifier_item_martyrs_mail_passive:IsDebuff()
  return false
end

function modifier_item_martyrs_mail_passive:IsPurgable()
  return false
end

function modifier_item_martyrs_mail_passive:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_martyrs_mail_passive:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_armor = ability:GetSpecialValueFor("bonus_armor")
    self.bonus_intellect = ability:GetSpecialValueFor("bonus_intellect")
    self.bonus_strength = ability:GetSpecialValueFor("bonus_strength")
  end
end

modifier_item_martyrs_mail_passive.OnRefresh = modifier_item_martyrs_mail_passive.OnCreated

function modifier_item_martyrs_mail_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, -- GetModifierBonusStats_Strength
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, -- GetModifierBonusStats_Intellect
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, -- GetModifierPhysicalArmorBonus
    MODIFIER_EVENT_ON_DEATH,
  }
end

function modifier_item_martyrs_mail_passive:GetModifierBonusStats_Strength()
  return self.bonus_strength or self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_martyrs_mail_passive:GetModifierBonusStats_Intellect()
  return self.bonus_intellect or self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

function modifier_item_martyrs_mail_passive:GetModifierPhysicalArmorBonus()
  return self.bonus_armor or self:GetAbility():GetSpecialValueFor("bonus_armor")
end

if IsServer() then
  function modifier_item_martyrs_mail_passive:OnDeath(event)
    -- Only the first item will proc
    if not self:IsFirstItemInInventory() then
      return
    end

    local parent = self:GetParent()
    local dead = event.unit
    local ability = self:GetAbility()

    -- Check if dead unit is nil or its about to be deleted
    if not dead or dead:IsNull() then
      return
    end

    -- If dead unit is not the parent then dont continue
    if dead ~= parent then
      return
    end

    -- Check if parent is a real hero (it's fine if it works on Spirit Bear)
    if not parent:IsRealHero() or parent:IsTempestDouble() or parent:IsClone() then
      return
    end

    local parent_team = parent:GetTeamNumber()
    local death_location = parent:GetAbsOrigin()

    local heal_amount = 100 + parent:GetMaxHealth() / 2
    local heal_radius = 1800
    local vision_duration = 30
    local effect_duration = 30
    --local vision_radius = 1200

    if ability and not ability:IsNull() then
      heal_amount = ability:GetSpecialValueFor("death_heal_base") + (parent:GetMaxHealth() * ability:GetSpecialValueFor("death_heal_hp_percent") / 100)
      heal_radius = ability:GetSpecialValueFor("death_effect_radius")
      vision_duration = ability:GetSpecialValueFor("death_effect_duration")
      effect_duration = ability:GetSpecialValueFor("death_effect_duration")
      --vision_radius = ability:GetSpecialValueFor("death_vision_radius")
    end

    local allies = FindUnitsInRadius(
      parent_team,
      death_location,
      nil,
      heal_radius,
      DOTA_UNIT_TARGET_TEAM_FRIENDLY,
      bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
      DOTA_UNIT_TARGET_FLAG_NONE,
      FIND_ANY_ORDER,
      false
    )

    for _, ally in pairs(allies) do
      if ally and not ally:IsNull() then
        -- Healing
        ally:Heal(heal_amount, ability)
        SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, ally, heal_amount, nil)
        -- Buff
        ally:AddNewModifier(parent, ability, "modifier_item_martyrs_mail_death_buff", {duration = effect_duration})
      end
    end

    -- Add vision at death location
    local dummy = CreateUnitByName("npc_dota_custom_dummy_unit", death_location, false, parent, parent, parent_team)
    dummy:AddNewModifier(parent, ability, "modifier_item_martyrs_mail_dummy_stuff", {})
    dummy:AddNewModifier(parent, ability, "modifier_kill", {duration = vision_duration})
    dummy:AddNewModifier(parent, ability, "modifier_generic_dead_tracker_oaa", {duration = vision_duration + MANUAL_GARBAGE_CLEANING_TIME})
    --AddFOWViewer(parent_team, death_location, vision_radius, vision_duration, false)
  end
end

---------------------------------------------------------------------------------------------------

modifier_item_martyrs_mail_martyr_active = class(ModifierBaseClass)

function modifier_item_martyrs_mail_martyr_active:IsHidden()
  return false
end

function modifier_item_martyrs_mail_martyr_active:IsDebuff()
  return false
end

function modifier_item_martyrs_mail_martyr_active:IsPurgable()
  return false
end

function modifier_item_martyrs_mail_martyr_active:IsAura()
  return true
end

function modifier_item_martyrs_mail_martyr_active:GetModifierAura()
  return "modifier_item_martyrs_mail_martyr_aura"
end

function modifier_item_martyrs_mail_martyr_active:GetAuraEntityReject( hEntity )
  return self:GetCaster() == hEntity
end

function modifier_item_martyrs_mail_martyr_active:GetAuraRadius()
  return self.martyr_heal_aoe or 1200
end

function modifier_item_martyrs_mail_martyr_active:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_item_martyrs_mail_martyr_active:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
end

function modifier_item_martyrs_mail_martyr_active:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_TAKEDAMAGE,
  }
end

function modifier_item_martyrs_mail_martyr_active:OnCreated()
  local ability = self:GetAbility()
  local radius = 1200
  if ability and not ability:IsNull() then
    radius = ability:GetSpecialValueFor("martyr_heal_aoe")
  end

  self.martyr_heal_aoe = radius

  if IsServer() then
    local parent = self:GetParent()
    if not self.particle then
      self.particle = ParticleManager:CreateParticle("particles/items2_fx/martyrs_plate.vpcf", PATTACH_OVERHEAD_FOLLOW, parent)
      ParticleManager:SetParticleControl(self.particle, 0, parent:GetAbsOrigin())
      ParticleManager:SetParticleControlEnt(self.particle, 1, parent, PATTACH_POINT_FOLLOW, "attach_origin", parent:GetAbsOrigin(), true)
      ParticleManager:SetParticleControl(self.particle, 2, Vector(parent:GetModelRadius()*1.1, 0, 0))
    end
  end
end

modifier_item_martyrs_mail_martyr_active.OnRefresh = modifier_item_martyrs_mail_martyr_active.OnCreated

function modifier_item_martyrs_mail_martyr_active:OnDestroy()
  if IsServer() and self.particle then
    ParticleManager:DestroyParticle(self.particle, true)
    ParticleManager:ReleaseParticleIndex(self.particle)
    self.particle = nil
  end
end

if IsServer() then
  function modifier_item_martyrs_mail_martyr_active:OnTakeDamage(event)
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local attacker = event.attacker
    local damaged_unit = event.unit

    -- Don't continue if attacker doesn't exist or if attacker is about to be deleted
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if damaged entity exists
    if not damaged_unit or damaged_unit:IsNull() then
      return
    end

    -- Check if damaged unit has this modifier
    if damaged_unit ~= parent then
      return
    end

    -- Damage before reductions
    local damage = math.max(event.original_damage, event.damage)

    -- If damage is negative or 0, don't continue
    if damage <= 0 then
      return
    end

    -- Don't continue if ability doesn't exist
    if not ability or ability:IsNull() then
      return
    end

    local martyr_heal_aoe = self.martyr_heal_aoe or ability:GetSpecialValueFor("martyr_heal_aoe")
    local martyr_heal_percent = ability:GetSpecialValueFor("martyr_heal_percent")

    local allies = FindUnitsInRadius(
      parent:GetTeamNumber(),
      parent:GetAbsOrigin(),
      parent,
      martyr_heal_aoe,
      DOTA_UNIT_TARGET_TEAM_FRIENDLY,
      bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
      DOTA_UNIT_TARGET_FLAG_NONE,
      FIND_ANY_ORDER,
      false
    )
    for _, ally in pairs(allies) do
      if ally and not ally:IsNull() and ally ~= parent then
        --ally:Heal(damage * martyr_heal_percent / 100, ability)
        ally:HealWithParams(damage * martyr_heal_percent / 100, ability, false, true, parent, false)
      end
    end
  end
end

function modifier_item_martyrs_mail_martyr_active:GetPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA + 10000
end

-- Unbreakable owner
function modifier_item_martyrs_mail_martyr_active:CheckState()
  return {
    [MODIFIER_STATE_PASSIVES_DISABLED] = false,
  }
end

function modifier_item_martyrs_mail_martyr_active:GetTexture()
  return "custom/martyrs_mail"
end

---------------------------------------------------------------------------------------------------

modifier_item_martyrs_mail_martyr_aura = class(ModifierBaseClass)

function modifier_item_martyrs_mail_martyr_aura:IsHidden()
  return false
end

function modifier_item_martyrs_mail_martyr_aura:IsDebuff()
  return false
end

function modifier_item_martyrs_mail_martyr_aura:IsPurgable()
  return false
end

function modifier_item_martyrs_mail_martyr_aura:GetPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA + 10000
end

-- Unbreakable allies but not the owner
function modifier_item_martyrs_mail_martyr_aura:CheckState()
  return {
    [MODIFIER_STATE_PASSIVES_DISABLED] = false,
  }
end

function modifier_item_martyrs_mail_martyr_aura:GetEffectName()
	return "particles/world_shrine/radiant_shrine_active_ray.vpcf"
end

function modifier_item_martyrs_mail_martyr_aura:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_item_martyrs_mail_martyr_aura:GetTexture()
  return "custom/martyrs_mail"
end

---------------------------------------------------------------------------------------------------

modifier_item_martyrs_mail_death_buff = class(ModifierBaseClass)

function modifier_item_martyrs_mail_death_buff:IsHidden()
  return false
end

function modifier_item_martyrs_mail_death_buff:IsDebuff()
  return false
end

function modifier_item_martyrs_mail_death_buff:IsPurgable()
  return false
end

function modifier_item_martyrs_mail_death_buff:OnCreated()
  self.damage = 180
  self.armor = 15
  self.attack_speed = 50
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.damage = ability:GetSpecialValueFor("death_attack_damage")
    self.armor = ability:GetSpecialValueFor("death_armor")
    self.attack_speed = ability:GetSpecialValueFor("death_attack_speed")
  end
end

modifier_item_martyrs_mail_death_buff.OnRefresh = modifier_item_martyrs_mail_death_buff.OnCreated

function modifier_item_martyrs_mail_death_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
  }
end

function modifier_item_martyrs_mail_death_buff:GetModifierPreAttack_BonusDamage()
  return self.damage
end

function modifier_item_martyrs_mail_death_buff:GetModifierPhysicalArmorBonus()
  return self.armor
end

function modifier_item_martyrs_mail_death_buff:GetModifierAttackSpeedBonus_Constant()
  return self.attack_speed
end

function modifier_item_martyrs_mail_death_buff:GetPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA + 10000
end

function modifier_item_martyrs_mail_death_buff:CheckState()
  return {
    [MODIFIER_STATE_PASSIVES_DISABLED] = false,
  }
end

function modifier_item_martyrs_mail_death_buff:GetEffectName()
	return "particles/world_shrine/radiant_shrine_active_ray.vpcf"
end

function modifier_item_martyrs_mail_death_buff:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_item_martyrs_mail_death_buff:GetTexture()
  return "custom/martyrs_mail"
end

---------------------------------------------------------------------------------------------------

modifier_item_martyrs_mail_dummy_stuff = class(ModifierBaseClass)

function modifier_item_martyrs_mail_dummy_stuff:IsHidden()
  return true
end

function modifier_item_martyrs_mail_dummy_stuff:IsDebuff()
  return false
end

function modifier_item_martyrs_mail_dummy_stuff:IsPurgable()
  return false
end

function modifier_item_martyrs_mail_dummy_stuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
    MODIFIER_PROPERTY_BONUS_DAY_VISION,
    MODIFIER_PROPERTY_BONUS_NIGHT_VISION,
  }
end

function modifier_item_martyrs_mail_dummy_stuff:GetAbsoluteNoDamagePhysical()
  return 1
end

function modifier_item_martyrs_mail_dummy_stuff:GetAbsoluteNoDamageMagical()
  return 1
end

function modifier_item_martyrs_mail_dummy_stuff:GetAbsoluteNoDamagePure()
  return 1
end

function modifier_item_martyrs_mail_dummy_stuff:GetBonusDayVision()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    return ability:GetSpecialValueFor("death_vision_radius")
  end
  return 1200
end

function modifier_item_martyrs_mail_dummy_stuff:GetBonusNightVision()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    return ability:GetSpecialValueFor("death_vision_radius")
  end
  return 1200
end

function modifier_item_martyrs_mail_dummy_stuff:CheckState()
  return {
    [MODIFIER_STATE_UNSELECTABLE] = true,
    [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
    [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_OUT_OF_GAME] = true,
    [MODIFIER_STATE_NO_TEAM_MOVE_TO] = true,
    [MODIFIER_STATE_NO_TEAM_SELECT] = true,
    [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
    [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    [MODIFIER_STATE_FLYING] = true,
  }
end
