LinkLuaModifier( "modifier_item_heart_transplant", "items/heart_transplant.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_heart_transplant_debuff", "items/heart_transplant.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_heart_transplant_buff", "items/heart_transplant.lua", LUA_MODIFIER_MOTION_NONE )

item_heart_transplant = class(ItemBaseClass)

function item_heart_transplant:GetIntrinsicModifierName()
  return "modifier_item_heart_transplant"
end

-- This is client only
function item_heart_transplant:CastFilterResultTarget(target)
  local caster = self:GetCaster()
  local defaultFilterResult = self.BaseClass.CastFilterResultTarget(self, target)
  if target == caster or target:HasModifier("modifier_item_heart_transplant_buff") or caster:HasModifier("modifier_item_heart_transplant_debuff") then
    return UF_FAIL_CUSTOM
  end

  return defaultFilterResult
end

-- This is client only
function item_heart_transplant:GetCustomCastErrorTarget(target)
  local caster = self:GetCaster()
  if target == caster then
    return "#dota_hud_error_cant_cast_on_self"
  elseif target:HasModifier("modifier_item_heart_transplant_buff") or caster:HasModifier("modifier_item_heart_transplant_debuff") then
    return "#oaa_hud_error_only_one_transplant"
  end
end

function item_heart_transplant:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()

  if not target or target:IsNull() then
    return
  end

  local transplant_max_duration = self:GetSpecialValueFor("transplant_max_duration")

  -- Remove the previous instance of heart transplant - only allow one active transfer
  if self.transferred_buff and not self.transferred_buff:IsNull() then
    self.transferred_buff:Destroy()
  end

  -- Apply a Heart Transplant buff to the target unit
  self.transferred_buff = target:AddNewModifier(caster, self, "modifier_item_heart_transplant_buff", {duration = transplant_max_duration})

  -- Apply a Heart Transplant debuff to the caster
  caster:AddNewModifier(caster, self, "modifier_item_heart_transplant_debuff", {})
end

function item_heart_transplant:TransplantEnd(caster)
  if IsServer() then
    -- Remove debuff from the caster
    caster:RemoveModifierByName("modifier_item_heart_transplant_debuff")

    local cooldown = self:GetSpecialValueFor("cooldown")

    -- Start cooldown unaffected by cooldown reductions
    self:StartCooldown(cooldown)
  end
end

item_heart_transplant_2 = item_heart_transplant

---------------------------------------------------------------------------------------------------

modifier_item_heart_transplant = class(ModifierBaseClass)

function modifier_item_heart_transplant:IsHidden()
  return true
end

function modifier_item_heart_transplant:IsDebuff()
  return false
end

function modifier_item_heart_transplant:IsPurgable()
  return false
end

function modifier_item_heart_transplant:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_heart_transplant:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.str = ability:GetSpecialValueFor("bonus_strength")
    self.hp = ability:GetSpecialValueFor("bonus_health")
    self.regen = ability:GetSpecialValueFor("health_regen_pct")
    self.t_str = ability:GetSpecialValueFor("transplant_bonus_strength")
    self.t_hp = ability:GetSpecialValueFor("transplant_bonus_health")
    self.t_regen = ability:GetSpecialValueFor("transplant_health_regen_pct")
  end
end

modifier_item_heart_transplant.OnRefresh = modifier_item_heart_transplant.OnCreated

function modifier_item_heart_transplant:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
    --MODIFIER_EVENT_ON_TAKEDAMAGE
  }
end

function modifier_item_heart_transplant:GetModifierBonusStats_Strength()
  local parent = self:GetParent()
  local bonus_str = self.str or self:GetAbility():GetSpecialValueFor("bonus_strength")
  if parent:HasModifier("modifier_item_heart_transplant_debuff") and self.t_str then
    return bonus_str - self.t_str
  end
  return bonus_str
end

function modifier_item_heart_transplant:GetModifierHealthBonus()
  local parent = self:GetParent()
  local bonus_hp = self.hp or self:GetAbility():GetSpecialValueFor("bonus_health")
  if parent:HasModifier("modifier_item_heart_transplant_debuff") and self.t_hp then
    return bonus_hp - self.t_hp
  end
  return bonus_hp
end

-- Prevent stacking with other heart transplants and other hearts
function modifier_item_heart_transplant:GetModifierHealthRegenPercentage()
  local parent = self:GetParent()
  local parentHasHeart = parent:HasModifier("modifier_item_heart")

  if IsServer() then
    if not parent:IsIllusion() and not parentHasHeart and self:IsFirstItemInInventory() then
      local bonus_regen = self.regen or self:GetAbility():GetSpecialValueFor("health_regen_pct")
      if parent:HasModifier("modifier_item_heart_transplant_debuff") and self.t_regen then
        return bonus_regen - self.t_regen
      end
      return bonus_regen
    end
  end

  return 0
end

-- function modifier_item_heart_transplant:OnTakeDamage(event)
  -- local parent = self:GetParent()
  -- local ability = self:GetAbility()

  -- if event.damage > 0 and event.unit == parent and event.attacker ~= parent and not event.attacker:IsNeutralUnitType() and not event.attacker:IsOAABoss() then
    -- if ability.transferred_buff and not ability.transferred_buff:IsNull() then
      -- ability.transferred_buff:Destroy()
    -- end
  -- end
-- end

---------------------------------------------------------------------------------------------------

modifier_item_heart_transplant_debuff = class(ModifierBaseClass)

function modifier_item_heart_transplant_debuff:IsHidden()
  return false
end

function modifier_item_heart_transplant_debuff:IsDebuff()
  return true
end

function modifier_item_heart_transplant_debuff:IsPurgable()
  return false
end

function modifier_item_heart_transplant_debuff:OnCreated()
  local parent = self:GetParent()

  if IsServer() then
    if parent:IsHero() then
      parent:CalculateStatBonus(true)
    elseif parent:IsCreep() then
      parent:CalculateGenericBonuses()
    end
  end
end

modifier_item_heart_transplant_debuff.OnRefresh = modifier_item_heart_transplant_debuff.OnCreated
modifier_item_heart_transplant_debuff.OnDestroy = modifier_item_heart_transplant_debuff.OnCreated

function modifier_item_heart_transplant_debuff:GetTexture()
  return "custom/heart_transplant"
end

---------------------------------------------------------------------------------------------------

modifier_item_heart_transplant_buff = class(ModifierBaseClass)

function modifier_item_heart_transplant_buff:IsHidden()
  return false
end

function modifier_item_heart_transplant_buff:IsDebuff()
  return false
end

function modifier_item_heart_transplant_buff:IsPurgable()
  return false
end

function modifier_item_heart_transplant_buff:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.str = ability:GetSpecialValueFor("transplant_bonus_strength")
    self.hp = ability:GetSpecialValueFor("transplant_bonus_health")
    self.regen = ability:GetSpecialValueFor("transplant_health_regen_pct")
  end

  if IsServer() then
    local parent = self:GetParent()
    if parent:IsHero() then
      parent:CalculateStatBonus(true)
    elseif parent:IsCreep() then
      parent:CalculateGenericBonuses()
    end
    local caster = self:GetCaster()
    if self.particle == nil then
      self.particle = ParticleManager:CreateParticle("particles/items/heart_transplant/heart_transplant.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, parent)
      ParticleManager:SetParticleControlEnt(self.particle, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
      ParticleManager:SetParticleControlEnt(self.particle, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
    end

    self:StartIntervalThink(0.1)
  end
end

-- OnRefresh() will rarely happen because reapplying this buff isn't allowed in CastFilterResultTarget
function modifier_item_heart_transplant_buff:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.str = ability:GetSpecialValueFor("transplant_bonus_strength")
    self.hp = ability:GetSpecialValueFor("transplant_bonus_health")
    self.regen = ability:GetSpecialValueFor("transplant_health_regen_pct")
  end

  if IsServer() then
    local parent = self:GetParent()
    if parent:IsHero() then
      parent:CalculateStatBonus(true)
    elseif parent:IsCreep() then
      parent:CalculateGenericBonuses()
    end
    if self.particle then
      ParticleManager:DestroyParticle(self.particle, true)
      ParticleManager:ReleaseParticleIndex(self.particle)
      self.particle = nil
    end
    local caster = self:GetCaster()
    if self.particle == nil then
      self.particle = ParticleManager:CreateParticle("particles/items/heart_transplant/heart_transplant.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, parent)
      ParticleManager:SetParticleControlEnt(self.particle, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
      ParticleManager:SetParticleControlEnt(self.particle, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
    end
  end
end

function modifier_item_heart_transplant_buff:OnIntervalThink()
  local parent = self:GetParent()
  local caster = self:GetCaster()
  local ability = self:GetAbility()

  if not parent or parent:IsNull() or not caster or caster:IsNull() or not caster:IsAlive() or not ability or ability:IsNull() then
    --self:StartIntervalThink(-1)
    --self:SetDuration(0.01, true)
    self:Destroy()
    return
  end

  local break_distance = ability:GetSpecialValueFor("transplant_max_range") + caster:GetCastRangeBonus()
  local caster_position = caster:GetAbsOrigin()
  local parent_position = parent:GetAbsOrigin()
  local distance = (parent_position - caster_position):Length2D()

  -- If distance is higher than break distance, remove modifiers
  if distance > break_distance then
    --self:StartIntervalThink(-1)
    --self:SetDuration(0.01, true)
    self:Destroy()
  end

  if parent:IsHero() then
    parent:CalculateStatBonus(true)
  elseif parent:IsCreep() then
    parent:CalculateGenericBonuses()
  end
end

function modifier_item_heart_transplant_buff:OnDestroy()
  if IsServer() and self.particle then
    ParticleManager:DestroyParticle(self.particle, true)
    ParticleManager:ReleaseParticleIndex(self.particle)
    self.particle = nil
  end
  local ability = self:GetAbility()
  local caster = self:GetCaster()
  if ability and caster then
    -- End the Heart transplant
    ability:TransplantEnd(caster)
  end
end

function modifier_item_heart_transplant_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
  }
end

function modifier_item_heart_transplant_buff:GetModifierBonusStats_Strength()
  local parent = self:GetParent()
  if self.str and parent:IsRealHero() then
    return self.str
  end

  return 0
end

function modifier_item_heart_transplant_buff:GetModifierHealthBonus()
  local parent = self:GetParent()
  if self.hp and not parent:IsIllusion() then
    return self.hp
  end

  return 0
end

function modifier_item_heart_transplant_buff:GetModifierHealthRegenPercentage()
  local parent = self:GetParent()
  if self.regen and not parent:IsIllusion() then
    return self.regen
  end

  return 0
end

function modifier_item_heart_transplant_buff:GetTexture()
  return "custom/heart_transplant"
end
