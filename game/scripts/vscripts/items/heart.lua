LinkLuaModifier("modifier_item_heart_oaa_passive", "items/heart.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_heart_oaa_active", "items/heart.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_heart_oaa_active_illusions", "items/heart.lua", LUA_MODIFIER_MOTION_NONE)

item_heart_oaa_1 = class(ItemBaseClass)

function item_heart_oaa_1:GetIntrinsicModifierName()
  return "modifier_item_heart_oaa_passive"
end

function item_heart_oaa_1:OnSpellStart()
  local caster = self:GetCaster()
  local buff_duration = self:GetSpecialValueFor("buff_duration")

  -- Apply a Heart special buff to the caster
  caster:AddNewModifier(caster, self, "modifier_item_heart_oaa_active", {duration = buff_duration})

  -- Find enemies
  local center = caster:GetAbsOrigin()
  local radius = self:GetSpecialValueFor("radius")
  local enemies = FindUnitsInRadius(
    caster:GetTeamNumber(),
    center,
    nil,
    radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  -- Havoc Particle
  local particle = ParticleManager:CreateParticle("particles/items5_fx/havoc_hammer.vpcf", PATTACH_ABSORIGIN, caster)
  ParticleManager:SetParticleControl(particle, 1, Vector(radius, radius, radius))
  ParticleManager:ReleaseParticleIndex(particle)

  -- Havoc Sound
  caster:EmitSound("DOTA_Item.HavocHammer.Cast")

  -- Havoc Knockback
  local knockback_table = {
    should_stun = 0,
    center_x = center.x,
    center_y = center.y,
    center_z = center.z,
    duration = self:GetSpecialValueFor("knockback_duration"),
    knockback_duration = self:GetSpecialValueFor("knockback_duration"),
    knockback_distance = self:GetSpecialValueFor("knockback_distance"),
    knockback_height = 10,
  }

  -- Havoc Damage
  local havoc_damage = self:GetSpecialValueFor("nuke_base_dmg")
  if caster:IsHero() then
    havoc_damage = self:GetSpecialValueFor("nuke_base_dmg") + caster:GetStrength() * self:GetSpecialValueFor("nuke_str_dmg")
  end

  local damage_table = {
    attacker = caster,
    damage = havoc_damage,
    damage_type = DAMAGE_TYPE_MAGICAL,
    damage_flags = DOTA_DAMAGE_FLAG_NONE,
    ability = self,
  }

  -- Knockback and Damage enemies
  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() then
      --knockback_table.knockback_distance = radius - (center - enemy:GetAbsOrigin()):Length2D()
      enemy:AddNewModifier(caster, self, "modifier_knockback", knockback_table)
      
      damage_table.victim = enemy
      ApplyDamage(damage_table)
    end
  end
end

item_heart_oaa_2 = item_heart_oaa_1
item_heart_oaa_3 = item_heart_oaa_1
item_heart_oaa_4 = item_heart_oaa_1
item_heart_oaa_5 = item_heart_oaa_1

---------------------------------------------------------------------------------------------------

modifier_item_heart_oaa_passive = class(ModifierBaseClass)

function modifier_item_heart_oaa_passive:IsHidden()
  return true
end

function modifier_item_heart_oaa_passive:IsDebuff()
  return false
end

function modifier_item_heart_oaa_passive:IsPurgable()
  return false
end

function modifier_item_heart_oaa_passive:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_heart_oaa_passive:OnCreated()
  self:OnRefresh()
  if IsServer() then
    self:StartIntervalThink(0.1)
  end
end

function modifier_item_heart_oaa_passive:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.str = ability:GetSpecialValueFor("bonus_strength")
    self.hp = ability:GetSpecialValueFor("bonus_health")
    self.regen = ability:GetSpecialValueFor("health_regen_pct")
  end

  if IsServer() then
    self:OnIntervalThink()
  end
end

function modifier_item_heart_oaa_passive:OnIntervalThink()
  if self:IsFirstItemInInventory() then
    self:SetStackCount(2)
  else
    self:SetStackCount(1)
  end
end

function modifier_item_heart_oaa_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
    --MODIFIER_EVENT_ON_TAKEDAMAGE
  }
end

function modifier_item_heart_oaa_passive:GetModifierBonusStats_Strength()
  return self.str or self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_heart_oaa_passive:GetModifierHealthBonus()
  return self.hp or self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_heart_oaa_passive:GetModifierHealthRegenPercentage()
  if self:GetStackCount() == 2 then
    return self.regen or self:GetAbility():GetSpecialValueFor("health_regen_pct")
  else
    return 0
  end
end

-- if IsServer() then
  -- function modifier_item_heart_oaa_passive:OnTakeDamage(event)
    -- local parent = self:GetParent()
    -- local ability = self:GetAbility()

    -- if event.damage > 0 and event.unit == parent and event.attacker ~= parent and not event.attacker:IsNeutralUnitType() and not event.attacker:IsOAABoss() then
    -- -- Whatever is the effect when taking player-controlled damage
    -- end
  -- end
-- end

---------------------------------------------------------------------------------------------------

modifier_item_heart_oaa_active = class(ModifierBaseClass)

function modifier_item_heart_oaa_active:IsHidden()
  return false
end

function modifier_item_heart_oaa_active:IsDebuff()
  return false
end

function modifier_item_heart_oaa_active:IsPurgable()
  return false
end

function modifier_item_heart_oaa_active:IsAura()
  return true
end

function modifier_item_heart_oaa_active:GetModifierAura()
  return "modifier_item_heart_oaa_active_illusions"
end

function modifier_item_heart_oaa_active:GetAuraRadius()
  return 50000
end

function modifier_item_heart_oaa_active:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_item_heart_oaa_active:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO
end

function modifier_item_heart_oaa_active:GetAuraEntityReject(hEntity)
  local caster = self:GetCaster()
  if hEntity ~= caster then
    if IsServer() then
      if UnitVarToPlayerID(hEntity) ~= UnitVarToPlayerID(caster) or not hEntity:IsIllusion() then
        return true
      end
    else
      if hEntity.GetPlayerOwnerID then
        if hEntity:GetPlayerOwnerID() ~= caster:GetPlayerOwnerID() or not hEntity:IsIllusion() then
          return true
        end
      end
    end
  else
    return true
  end

  return false
end

function modifier_item_heart_oaa_active:OnCreated()
  local parent = self:GetParent()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.str = ability:GetSpecialValueFor("buff_bonus_strength")
    self.bonus_damage = ability:GetSpecialValueFor("buff_bonus_base_damage")
  end

  if IsServer() and parent:IsHero() then
    parent:CalculateStatBonus(true)
  end
end

modifier_item_heart_oaa_active.OnRefresh = modifier_item_heart_oaa_active.OnCreated

function modifier_item_heart_oaa_active:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE     -- this is bonus base damage (white)
  }
end

function modifier_item_heart_oaa_active:GetModifierBonusStats_Strength()
  return self.str
end

function modifier_item_heart_oaa_active:GetModifierBaseAttack_BonusDamage()
  return self.bonus_damage
end

function modifier_item_heart_oaa_active:GetEffectName()
  return "particles/econ/courier/courier_greevil_red/courier_greevil_red_ambient_3.vpcf"
end

function modifier_item_heart_oaa_active:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_item_heart_oaa_active:GetTexture()
  return "item_heart"
end

---------------------------------------------------------------------------------------------------

modifier_item_heart_oaa_active_illusions = class(ModifierBaseClass)

function modifier_item_heart_oaa_active_illusions:IsHidden()
  return false
end

function modifier_item_heart_oaa_active_illusions:IsDebuff()
  return false
end

function modifier_item_heart_oaa_active_illusions:IsPurgable()
  return false
end

function modifier_item_heart_oaa_active_illusions:OnCreated()
  local parent = self:GetParent()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.str = ability:GetSpecialValueFor("buff_bonus_strength")
    self.bonus_damage = ability:GetSpecialValueFor("buff_bonus_base_damage")
  end

  if IsServer() and parent:IsHero() then
    parent:CalculateStatBonus(true)
  end
end

function modifier_item_heart_oaa_active_illusions:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE     -- this is bonus base damage (white)
  }
end

function modifier_item_heart_oaa_active_illusions:GetModifierBonusStats_Strength()
  return self.str
end

function modifier_item_heart_oaa_active_illusions:GetModifierBaseAttack_BonusDamage()
  return self.bonus_damage
end

function modifier_item_heart_oaa_active_illusions:GetEffectName()
  return "particles/econ/courier/courier_greevil_red/courier_greevil_red_ambient_3.vpcf"
end

function modifier_item_heart_oaa_active_illusions:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_item_heart_oaa_active_illusions:GetTexture()
  return "item_heart"
end
