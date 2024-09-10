LinkLuaModifier("modifier_urn_of_shadows_oaa_buff", "items/spirit_vessel.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_urn_of_shadows_oaa_debuff", "items/spirit_vessel.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_spirit_vessel_oaa_passive", "items/spirit_vessel.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_spirit_vessel_oaa_buff", "items/spirit_vessel.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_spirit_vessel_oaa_debuff_with_charge", "items/spirit_vessel.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_spirit_vessel_oaa_debuff_no_charge", "items/spirit_vessel.lua", LUA_MODIFIER_MOTION_NONE)

item_urn_of_shadows_oaa = class(ItemBaseClass)

function item_urn_of_shadows_oaa:GetIntrinsicModifierName()
  return "modifier_intrinsic_multiplexer"
end

function item_urn_of_shadows_oaa:GetIntrinsicModifierNames()
  return {
    "modifier_generic_bonus",
    "modifier_spirit_vessel_oaa_passive",
  }
end

function item_urn_of_shadows_oaa:CastFilterResultTarget(target)
  local defaultFilterResult = self.BaseClass.CastFilterResultTarget(self, target)
  local current_charges = self:GetCurrentCharges()

  if current_charges < 1 then
    return UF_FAIL_CUSTOM
  end

  return defaultFilterResult
end

function item_urn_of_shadows_oaa:GetCustomCastErrorTarget(target)
  local current_charges = self:GetCurrentCharges()

  if current_charges < 1 then
    return "#dota_hud_error_no_charges"
  end
end

function item_urn_of_shadows_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()
  local duration = self:GetSpecialValueFor("duration")

  local particle_fx = ParticleManager:CreateParticle("particles/items2_fx/urn_of_shadows.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
  ParticleManager:SetParticleControl(particle_fx, 0, caster:GetAbsOrigin())
  ParticleManager:SetParticleControl(particle_fx, 1, target:GetAbsOrigin())
  ParticleManager:ReleaseParticleIndex(particle_fx)

  local current_charges = self:GetCurrentCharges()
  if current_charges < 1 then
    self:EndCooldown()
    return -- no charges, not possible to reach through normal means
  end

  if target:GetTeam() == caster:GetTeam() then
    target:AddNewModifier(caster, self, "modifier_urn_of_shadows_oaa_buff", {duration = duration})
  else
    target:AddNewModifier(caster, self, "modifier_urn_of_shadows_oaa_debuff", {duration = duration})
  end

  -- Decrement charges
  self:SetCurrentCharges(current_charges - 1)
  caster.spiritVesselChargesOAA = current_charges - 1

  -- Sound
  target:EmitSound("DOTA_Item.UrnOfShadows.Activate")
end

---------------------------------------------------------------------------------------------------

item_spirit_vessel_oaa = class(ItemBaseClass)

function item_spirit_vessel_oaa:GetIntrinsicModifierName()
  return "modifier_intrinsic_multiplexer"
end

function item_spirit_vessel_oaa:GetIntrinsicModifierNames()
  return {
    "modifier_generic_bonus",
    "modifier_spirit_vessel_oaa_passive",
  }
end

function item_spirit_vessel_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()
  local duration = self:GetSpecialValueFor("duration")

  local particle_fx = ParticleManager:CreateParticle("particles/items4_fx/spirit_vessel_cast.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
  ParticleManager:SetParticleControl(particle_fx, 0, caster:GetAbsOrigin())
  ParticleManager:SetParticleControl(particle_fx, 1, target:GetAbsOrigin())
  ParticleManager:ReleaseParticleIndex(particle_fx)

  local current_charges = self:GetCurrentCharges()
  if target:GetTeam() == caster:GetTeam() then
    -- Apply stronger version when you have charges and consume a charge, otherwise don't consume a charge but apply a weaker version
    if current_charges >= 1 then
      target:AddNewModifier(caster, self, "modifier_spirit_vessel_oaa_buff", {duration = duration})
      self:SetCurrentCharges(current_charges - 1)
      caster.spiritVesselChargesOAA = current_charges - 1
      target:EmitSound("DOTA_Item.SpiritVessel.Target.Ally")
    else
      target:AddNewModifier(caster, self, "modifier_spirit_vessel_oaa_buff", {duration = duration / 2})
      target:EmitSound("DOTA_Item.UrnOfShadows.Activate")
    end
  else
    -- Apply stronger version when you have charges and consume a charge, otherwise don't consume a charge but apply a weaker version
    if current_charges >= 1 then
      if target:HasModifier("modifier_spirit_vessel_oaa_debuff_no_charge") then
        target:RemoveModifierByName("modifier_spirit_vessel_oaa_debuff_no_charge")
      end
      target:AddNewModifier(caster, self, "modifier_spirit_vessel_oaa_debuff_with_charge", {duration = duration})
      self:SetCurrentCharges(current_charges - 1)
      caster.spiritVesselChargesOAA = current_charges - 1
      target:EmitSound("DOTA_Item.SpiritVessel.Target.Enemy")
    else
      if target:HasModifier("modifier_spirit_vessel_oaa_debuff_with_charge") then
        target:RemoveModifierByName("modifier_spirit_vessel_oaa_debuff_with_charge")
      end
      target:AddNewModifier(caster, self, "modifier_spirit_vessel_oaa_debuff_no_charge", {duration = duration})
      target:EmitSound("DOTA_Item.UrnOfShadows.Activate")
    end
  end
end

item_spirit_vessel_2 = item_spirit_vessel_oaa
item_spirit_vessel_3 = item_spirit_vessel_oaa
item_spirit_vessel_4 = item_spirit_vessel_oaa
item_spirit_vessel_5 = item_spirit_vessel_oaa

---------------------------------------------------------------------------------------------------

modifier_spirit_vessel_oaa_passive = class({})

function modifier_spirit_vessel_oaa_passive:IsHidden()
  return true
end

function modifier_spirit_vessel_oaa_passive:IsPurgable()
  return false
end

function modifier_spirit_vessel_oaa_passive:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_spirit_vessel_oaa_passive:OnCreated()
  if not IsServer() then
    return
  end
  local caster = self:GetParent()
  if caster.spiritVesselChargesOAA and caster.spiritVesselChargesOAA ~= 0 then
    local item = self:GetAbility()
    if item and not item:IsNull() then
      item:SetCurrentCharges(caster.spiritVesselChargesOAA)
    end
  end
end

function modifier_spirit_vessel_oaa_passive:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH,
  }
end

if IsServer() then
  function modifier_spirit_vessel_oaa_passive:OnDeath(event)
    local caster = self:GetCaster()
    local dead = event.unit
    local killer = event.attacker
    local item = self:GetAbility()

    if not caster:IsRealHero() then
      return
    end

    -- someone else died
    if caster ~= dead then
      -- Dead unit is not on caster's team
      if caster:GetTeamNumber() ~= dead:GetTeamNumber() then
        -- Dead unit is an actually dead real enemy hero unit or a boss
        if (dead:IsRealHero() and (not dead:IsTempestDouble()) and (not dead:IsReincarnating()) and (not dead:IsClone()) and (not dead:IsSpiritBearOAA())) or dead:IsOAABoss() then
          local casterToDeadVector = dead:GetAbsOrigin() - caster:GetAbsOrigin()
          local isDeadInChargeRange = casterToDeadVector:Length2D() <= item:GetSpecialValueFor("soul_radius")

          -- Charge gain - only if caster is near the dead unit or if caster is the killer
          if isDeadInChargeRange or killer == caster then
            local current_charges = item:GetCurrentCharges() or 0
            local charges_per_kill = item:GetSpecialValueFor("kill_charges")
            if current_charges >= 1 then
              item:SetCurrentCharges(current_charges + charges_per_kill)
            else
              item:SetCurrentCharges(current_charges + 2*charges_per_kill)
            end
            caster.spiritVesselChargesOAA = item:GetCurrentCharges()
          end
        end
      end
    -- caster died
    elseif not caster:IsTempestDouble() and not caster:IsReincarnating() and not caster:IsClone() and not caster:IsSpiritBearOAA() then
      local current_charges = item:GetCurrentCharges() or 0
      -- caster has no charges? add 1 on death
      if current_charges == 0 then
        item:SetCurrentCharges(1)
      end
      caster.spiritVesselChargesOAA = item:GetCurrentCharges()
    end
  end
end

function modifier_spirit_vessel_oaa_passive:OnDestroy()
  if not IsServer() then
    return
  end

  local charges = self.charges or 0
  local ability = self:GetAbility()
  local caster = self:GetCaster()
  if ability and not ability:IsNull() then
    if ability:GetCurrentCharges() >= charges then
      charges = ability:GetCurrentCharges()
    end
  end
  if caster and not caster:IsNull() then
    if not caster.spiritVesselChargesOAA then
      caster.spiritVesselChargesOAA = charges
    else
      caster.spiritVesselChargesOAA = math.max(caster.spiritVesselChargesOAA, charges)
    end
  end
end

---------------------------------------------------------------------------------------------------

modifier_urn_of_shadows_oaa_buff = class({})

function modifier_urn_of_shadows_oaa_buff:IsDebuff()
  return false
end

function modifier_urn_of_shadows_oaa_buff:IsHidden()
  return false
end

function modifier_urn_of_shadows_oaa_buff:IsPurgable()
  return true
end

function modifier_urn_of_shadows_oaa_buff:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.health_regen = ability:GetSpecialValueFor("soul_heal_amount")
  end
end

modifier_urn_of_shadows_oaa_buff.OnRefresh = modifier_urn_of_shadows_oaa_buff.OnCreated

function modifier_urn_of_shadows_oaa_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_EVENT_ON_TAKEDAMAGE,
  }
end

if IsServer() then
  function modifier_urn_of_shadows_oaa_buff:OnTakeDamage(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local damaged_unit = event.unit
    local damage = event.damage -- damage after reductions

    -- Check if damaged unit exists
    if not damaged_unit or damaged_unit:IsNull() then
      return
    end

    -- Check if damaged unit has this modifier
    if damaged_unit ~= parent then
      return
    end

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Ignore self damage
    if parent == attacker then
      return
    end

    -- Check if attacker is something weird
    if attacker.GetUnitName == nil then
      return
    end

    -- Check if attacker is on the neutral team or uncontrollable by the players
    if attacker:GetTeamNumber() == DOTA_TEAM_NEUTRALS or not attacker:IsControllableByAnyPlayer() then
      return
    end

    -- Check if damage is negative or 0
    if damage <= 0 then
      return
    end

    self:Destroy()
  end
end

function modifier_urn_of_shadows_oaa_buff:GetModifierConstantHealthRegen()
  return self.health_regen or self:GetAbility():GetSpecialValueFor("soul_heal_amount")
end

function modifier_urn_of_shadows_oaa_buff:GetEffectName()
  return "particles/items2_fx/urn_of_shadows_heal.vpcf"
end

function modifier_urn_of_shadows_oaa_buff:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_urn_of_shadows_oaa_buff:GetTexture()
  return "item_urn_of_shadows"
end

---------------------------------------------------------------------------------------------------

modifier_spirit_vessel_oaa_buff = class({})

function modifier_spirit_vessel_oaa_buff:IsDebuff()
  return false
end

function modifier_spirit_vessel_oaa_buff:IsHidden()
  return false
end

function modifier_spirit_vessel_oaa_buff:IsPurgable()
  return true
end

function modifier_spirit_vessel_oaa_buff:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.health_regen = ability:GetSpecialValueFor("soul_heal_amount")
  end
end

modifier_spirit_vessel_oaa_buff.OnRefresh = modifier_spirit_vessel_oaa_buff.OnCreated

function modifier_spirit_vessel_oaa_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_EVENT_ON_TAKEDAMAGE,
  }
end

if IsServer() then
  function modifier_spirit_vessel_oaa_buff:OnTakeDamage(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local damaged_unit = event.unit
    local damage = event.damage -- damage after reductions

    -- Check if damaged unit exists
    if not damaged_unit or damaged_unit:IsNull() then
      return
    end

    -- Check if damaged unit has this modifier
    if damaged_unit ~= parent then
      return
    end

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Ignore self damage
    if parent == attacker then
      return
    end

    -- Check if attacker is something weird
    if attacker.GetUnitName == nil then
      return
    end

    -- Check if attacker is on the neutral team or uncontrollable by the players
    if attacker:GetTeamNumber() == DOTA_TEAM_NEUTRALS or not attacker:IsControllableByAnyPlayer() then
      return
    end

    -- Check if damage is negative or 0
    if damage <= 0 then
      return
    end

    -- Stop started thinking if there is any
    self:StartIntervalThink(-1)
    -- Changed buff state (it can be anything we want, in this case we halve the regen)
    -- negative stack counts arent shown in the UI
    self:SetStackCount(-2)
    -- Start damage cooldown
    self:StartIntervalThink(3)
  end

  function modifier_spirit_vessel_oaa_buff:OnIntervalThink()
    -- Revert the buff to normal state
    self:SetStackCount(0)
    -- Stop thinking
    self:StartIntervalThink(-1)
  end
end

function modifier_spirit_vessel_oaa_buff:GetModifierConstantHealthRegen()
  if math.abs(self:GetStackCount()) ~= 2 then
    return self.health_regen or self:GetAbility():GetSpecialValueFor("soul_heal_amount")
  elseif self.health_regen then
    return self.health_regen / 2
  end
end

function modifier_spirit_vessel_oaa_buff:GetEffectName()
  return "particles/items2_fx/urn_of_shadows_heal.vpcf"
end

function modifier_spirit_vessel_oaa_buff:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_spirit_vessel_oaa_buff:GetTexture()
  return "item_spirit_vessel"
end

---------------------------------------------------------------------------------------------------

modifier_urn_of_shadows_oaa_debuff = class({})

function modifier_urn_of_shadows_oaa_debuff:IsDebuff()
  return true
end

function modifier_urn_of_shadows_oaa_debuff:IsHidden()
  return false
end

function modifier_urn_of_shadows_oaa_debuff:IsPurgable()
  return true
end

function modifier_urn_of_shadows_oaa_debuff:GetEffectName()
  return "particles/items2_fx/urn_of_shadows_damage.vpcf"
end

function modifier_urn_of_shadows_oaa_debuff:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_urn_of_shadows_oaa_debuff:OnCreated()
  if not IsServer() then
    return
  end

  self:OnRefresh()
  self:OnIntervalThink()
  self:StartIntervalThink(1)
end

function modifier_urn_of_shadows_oaa_debuff:OnRefresh()
  if not IsServer() then
    return
  end

  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.damage_per_second = ability:GetSpecialValueFor("soul_damage_amount")
  else
    self.damage_per_second = 20
  end
end

function modifier_urn_of_shadows_oaa_debuff:OnIntervalThink()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  local caster = self:GetCaster()
  local ability = self:GetAbility()

  -- ApplyDamage crashes the game if attacker or victim do not exist
  if not parent or parent:IsNull() or not caster or caster:IsNull() then
    self:StartIntervalThink(-1)
    self:Destroy()
    return
  end

  local damageTable = {
    victim = parent,
    attacker = caster,
    damage = self.damage_per_second,
    damage_type = DAMAGE_TYPE_MAGICAL,
    ability = ability
  }

  ApplyDamage(damageTable)
end

function modifier_urn_of_shadows_oaa_debuff:GetTexture()
  return "item_urn_of_shadows"
end

---------------------------------------------------------------------------------------------------

modifier_spirit_vessel_oaa_debuff_with_charge = class({})

function modifier_spirit_vessel_oaa_debuff_with_charge:IsDebuff()
  return true
end

function modifier_spirit_vessel_oaa_debuff_with_charge:IsHidden()
  return false
end

function modifier_spirit_vessel_oaa_debuff_with_charge:IsPurgable()
  return true
end

function modifier_spirit_vessel_oaa_debuff_with_charge:GetEffectName()
  return "particles/items4_fx/spirit_vessel_damage.vpcf"
end

function modifier_spirit_vessel_oaa_debuff_with_charge:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_spirit_vessel_oaa_debuff_with_charge:OnCreated()
  if not IsServer() then
    return
  end

  self:OnRefresh()
  self:OnIntervalThink()
  self:StartIntervalThink(1)
end

function modifier_spirit_vessel_oaa_debuff_with_charge:OnRefresh()
  if not IsServer() then
    return
  end

  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.damage_per_second = ability:GetSpecialValueFor("soul_damage_amount")
    self.current_hp_dmg = ability:GetSpecialValueFor("current_hp_as_dmg")
    self.heal_reduction = ability:GetSpecialValueFor("heal_reduction_with_charge")
  else
    self.damage_per_second = 25
    self.current_hp_dmg = 4
    self.heal_reduction = 50
  end

  -- Do reduced damage to bosses
  if self:GetParent():IsOAABoss() then
    self.current_hp_dmg = self.current_hp_dmg * (1 - BOSS_DMG_RED_FOR_PCT_SPELLS/100)
  end
end

function modifier_spirit_vessel_oaa_debuff_with_charge:OnIntervalThink()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  local caster = self:GetCaster()
  local ability = self:GetAbility()

  -- ApplyDamage crashes the game if attacker or victim do not exist
  if not parent or parent:IsNull() or not caster or caster:IsNull() then
    self:StartIntervalThink(-1)
    self:Destroy()
    return
  end

  local damageTable = {
    victim = parent,
    attacker = caster,
    damage = self.damage_per_second + (parent:GetHealth() * self.current_hp_dmg / 100),
    damage_type = DAMAGE_TYPE_MAGICAL,
    ability = ability
  }

  ApplyDamage(damageTable)
end

function modifier_spirit_vessel_oaa_debuff_with_charge:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
    MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
  }
end

function modifier_spirit_vessel_oaa_debuff_with_charge:GetModifierHPRegenAmplify_Percentage()
  return 0 - math.abs(self.heal_reduction or self:GetAbility():GetSpecialValueFor("heal_reduction_with_charge"))
end

function modifier_spirit_vessel_oaa_debuff_with_charge:GetModifierHealAmplify_PercentageTarget()
  return 0 - math.abs(self.heal_reduction or self:GetAbility():GetSpecialValueFor("heal_reduction_with_charge"))
end

function modifier_spirit_vessel_oaa_debuff_with_charge:GetModifierLifestealRegenAmplify_Percentage()
  return 0 - math.abs(self.heal_reduction or self:GetAbility():GetSpecialValueFor("heal_reduction_with_charge"))
end

function modifier_spirit_vessel_oaa_debuff_with_charge:GetModifierSpellLifestealRegenAmplify_Percentage()
  return 0 - math.abs(self.heal_reduction or self:GetAbility():GetSpecialValueFor("heal_reduction_with_charge"))
end

function modifier_spirit_vessel_oaa_debuff_with_charge:GetTexture()
  return "item_spirit_vessel"
end

---------------------------------------------------------------------------------------------------

modifier_spirit_vessel_oaa_debuff_no_charge = class({})

function modifier_spirit_vessel_oaa_debuff_no_charge:IsDebuff()
  return true
end

function modifier_spirit_vessel_oaa_debuff_no_charge:IsHidden()
  return false
end

function modifier_spirit_vessel_oaa_debuff_no_charge:IsPurgable()
  return true
end

function modifier_spirit_vessel_oaa_debuff_no_charge:GetEffectName()
  return "particles/items4_fx/spirit_vessel_damage.vpcf"
end

function modifier_spirit_vessel_oaa_debuff_no_charge:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_spirit_vessel_oaa_debuff_no_charge:OnCreated()
  if not IsServer() then
    return
  end
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.heal_reduction = ability:GetSpecialValueFor("heal_reduction_no_charge")
  end
end

modifier_spirit_vessel_oaa_debuff_no_charge.OnRefresh = modifier_spirit_vessel_oaa_debuff_no_charge.OnCreated

function modifier_spirit_vessel_oaa_debuff_no_charge:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
    MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
  }
end

function modifier_spirit_vessel_oaa_debuff_no_charge:GetModifierHPRegenAmplify_Percentage()
  return 0 - math.abs(self.heal_reduction or self:GetAbility():GetSpecialValueFor("heal_reduction_no_charge"))
end

function modifier_spirit_vessel_oaa_debuff_no_charge:GetModifierHealAmplify_PercentageTarget()
  return 0 - math.abs(self.heal_reduction or self:GetAbility():GetSpecialValueFor("heal_reduction_no_charge"))
end

function modifier_spirit_vessel_oaa_debuff_no_charge:GetModifierLifestealRegenAmplify_Percentage()
  return 0 - math.abs(self.heal_reduction or self:GetAbility():GetSpecialValueFor("heal_reduction_no_charge"))
end

function modifier_spirit_vessel_oaa_debuff_no_charge:GetModifierSpellLifestealRegenAmplify_Percentage()
  return 0 - math.abs(self.heal_reduction or self:GetAbility():GetSpecialValueFor("heal_reduction_no_charge"))
end

function modifier_spirit_vessel_oaa_debuff_no_charge:GetTexture()
  return "item_spirit_vessel"
end
