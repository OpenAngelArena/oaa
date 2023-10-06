LinkLuaModifier("modifier_item_demon_stone_passive", "items/neutral/demon_stone.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_demon_stone_summon_passives", "items/neutral/demon_stone.lua", LUA_MODIFIER_MOTION_NONE)

item_demon_stone = class(ItemBaseClass)

function item_demon_stone:GetIntrinsicModifierName()
  return "modifier_item_demon_stone_passive"
end

function item_demon_stone:OnSpellStart()
  local caster = self:GetCaster()
  local summon_duration = self:GetSpecialValueFor("summon_duration")
  local summon_name = "npc_dota_demon_stone_demon"

  local caster_loc = caster:GetAbsOrigin()
  local caster_direction = caster:GetForwardVector()

  -- Sound
  caster:EmitSound("DOTA_Item.Necronomicon.Activate")

  -- Calculate summon position
  local summon_position = RotatePosition(caster_loc, QAngle(0, 30, 0), caster_loc + caster_direction * 180)

  -- Destroy trees around summon position
  GridNav:DestroyTreesAroundPoint(summon_position, 180, false)

  -- Actual summoning
  local summon = CreateUnitByName(summon_name, summon_position, true, caster, caster, caster:GetTeam())
  summon:SetControllableByPlayer(caster:GetPlayerOwnerID(), true)

  -- Add summon passives
  summon:AddNewModifier(caster, self, "modifier_demon_stone_summon_passives", {})
  summon:AddNewModifier(caster, self, "modifier_phased", {duration = FrameTime()}) -- for unstucking
  summon:AddNewModifier(caster, self, "modifier_kill", {duration = summon_duration})
  summon:AddNewModifier(caster, self, "modifier_generic_dead_tracker_oaa", {duration = summon_duration + MANUAL_GARBAGE_CLEANING_TIME})

  -- Fix stats of summons
  local summon_hp = self:GetSpecialValueFor("summon_health")
  local summon_dmg = self:GetSpecialValueFor("summon_damage")
  local summon_armor = self:GetSpecialValueFor("summon_armor")
  local summon_ms = self:GetSpecialValueFor("summon_move_speed")

  -- HP
  if summon_hp and summon_hp > 0 then
    summon:SetBaseMaxHealth(summon_hp)
    summon:SetMaxHealth(summon_hp)
    summon:SetHealth(summon_hp)
  end

  -- DAMAGE
  if summon_dmg then
    summon:SetBaseDamageMin(summon_dmg)
    summon:SetBaseDamageMax(summon_dmg)
  end

  -- ARMOR
  if summon_armor then
    summon:SetPhysicalArmorBaseValue(summon_armor)
  end

  -- Movement speed
  if summon_ms and summon_ms > 0 then
    summon:SetBaseMoveSpeed(summon_ms)
  end
end

---------------------------------------------------------------------------------------------------

modifier_item_demon_stone_passive = class(ModifierBaseClass)

function modifier_item_demon_stone_passive:IsHidden()
  return true
end
function modifier_item_demon_stone_passive:IsDebuff()
  return false
end
function modifier_item_demon_stone_passive:IsPurgable()
  return false
end

function modifier_item_demon_stone_passive:OnCreated()
  self:OnRefresh()
  if IsServer() then
    -- start thinking every 5 seconds
    self:StartIntervalThink(5)
  end
end

function modifier_item_demon_stone_passive:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.xpm = ability:GetSpecialValueFor("bonus_xpm")
    self.mana = ability:GetSpecialValueFor("bonus_mana")
    self.dmg = ability:GetSpecialValueFor("bonus_damage")
    self.attack_speed = ability:GetSpecialValueFor("bonus_attack_speed")
  end
end

function modifier_item_demon_stone_passive:OnIntervalThink()
  if not IsServer() then
    return
  end

  if Duels:IsActive() then
    return
  end

  local parent = self:GetParent()

  if parent:IsIllusion() or not parent:IsHero() then
    return
  end

  local xpm = self.xpm or self:GetAbility():GetSpecialValueFor("bonus_xpm")
  local xp = math.floor((xpm/60)*5)

  parent:AddExperience(xp, DOTA_ModifyXP_Unspecified, false, true)
end

function modifier_item_demon_stone_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MANA_BONUS,
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
  }
end

function modifier_item_demon_stone_passive:GetModifierManaBonus()
  return self.mana or self:GetAbility():GetSpecialValueFor("bonus_mana")
end

function modifier_item_demon_stone_passive:GetModifierPreAttack_BonusDamage()
  return self.dmg or self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_demon_stone_passive:GetModifierAttackSpeedBonus_Constant()
  return self.attack_speed or self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

---------------------------------------------------------------------------------------------------

modifier_demon_stone_summon_passives = class(ModifierBaseClass)

function modifier_demon_stone_summon_passives:IsHidden()
  return true
end

function modifier_demon_stone_summon_passives:IsDebuff()
  return false
end

function modifier_demon_stone_summon_passives:IsPurgable()
  return false
end

function modifier_demon_stone_summon_passives:IsAura()
  return true
end

function modifier_demon_stone_summon_passives:GetModifierAura()
  return "modifier_truesight"
end

function modifier_demon_stone_summon_passives:GetAuraRadius()
  --local parent = self:GetParent()
  --return parent:GetCurrentVisionRange() or 800
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    return ability:GetSpecialValueFor("summon_true_sight_radius")
  end
  return 800
end

function modifier_demon_stone_summon_passives:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_demon_stone_summon_passives:GetAuraSearchType()
  return DOTA_UNIT_TARGET_ALL
end

function modifier_demon_stone_summon_passives:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_INVULNERABLE)
end

function modifier_demon_stone_summon_passives:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
  }
end

if IsServer() then
  function modifier_demon_stone_summon_passives:GetModifierTotal_ConstantBlock(event)
    local attacker = event.attacker

    if not attacker or attacker:IsNull() then
      return 0
    end

    if attacker.IsBaseNPC == nil then
      return 0
    end

    if not attacker:IsBaseNPC() then
      return 0
    end

    local dmg_reduction = 85
    local ability = self:GetAbility()
    if ability and not ability:IsNull() then
      dmg_reduction = ability:GetSpecialValueFor("summon_dmg_reduction")
    end

    -- Block damage from neutrals and always from bosses
    if attacker:IsOAABoss() or attacker:GetTeamNumber() == DOTA_TEAM_NEUTRALS then
      return event.damage * dmg_reduction / 100
    end

    return 0
  end
end
