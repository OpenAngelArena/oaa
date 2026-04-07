LinkLuaModifier("modifier_item_oaa_dagon_passive", "items/dagon.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_oaa_dagon_non_stacking_stats", "items/dagon.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_oaa_dagon_debuff", "items/dagon.lua", LUA_MODIFIER_MOTION_NONE)

item_dagon_oaa_1 = class(ItemBaseClass)
item_dagon_oaa_2 = item_dagon_oaa_1
item_dagon_oaa_3 = item_dagon_oaa_1
item_dagon_oaa_4 = item_dagon_oaa_1
item_dagon_oaa_5 = item_dagon_oaa_1
item_dagon_oaa_6 = item_dagon_oaa_1
item_dagon_oaa_7 = item_dagon_oaa_1
item_dagon_oaa_8 = item_dagon_oaa_1
item_dagon_oaa_9 = item_dagon_oaa_1

function item_dagon_oaa_1:GetIntrinsicModifierName()
  return "modifier_intrinsic_multiplexer"
end

function item_dagon_oaa_1:GetIntrinsicModifierNames()
  return {
    "modifier_item_oaa_dagon_passive",
    "modifier_item_oaa_dagon_non_stacking_stats",
  }
end

function item_dagon_oaa_1:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()
  local level = self:GetLevel()

  local soundCaster = "DOTA_Item.Dagon.Activate"
  local soundTarget = "DOTA_Item.Dagon5.Target"

  local particleName = "particles/items/dagon_oaa.vpcf"
  local particleThickness = 300 + (100 * level) -- Control Point 2 in Dagon's particle effect takes a number between 400 and 2000, depending on its level.

  local damage = self:GetSpecialValueFor("damage") -- Damage should never be a big value because of the spells like Fatal Bonds that share dmg
  local hp_percent = self:GetSpecialValueFor("current_hp_dmg")
  --local burst_heal_percent = self:GetSpecialValueFor("burst_heal_percent")
  --local hero_spell_lifesteal = self:GetSpecialValueFor("hero_spell_lifesteal")
  --local creep_spell_lifesteal = self:GetSpecialValueFor("creep_spell_lifesteal")
  local damage_type = DAMAGE_TYPE_MAGICAL

  local particle = ParticleManager:CreateParticle(particleName,  PATTACH_POINT_FOLLOW, caster)
  ParticleManager:SetParticleControlEnt(particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetOrigin(), true)
  ParticleManager:SetParticleControlEnt(particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetOrigin(), true)
  ParticleManager:SetParticleControl(particle, 2, Vector(particleThickness))
  ParticleManager:ReleaseParticleIndex(particle)

  -- Sound on caster
  caster:EmitSound(soundCaster)

  -- Sound on target
  target:EmitSound(soundTarget)

  -- Don't do anything if target has Linken's effect or it's spell-immune
  if target:TriggerSpellAbsorb(self) or target:IsMagicImmune() then
    return
  end

  -- If the target is an illusion, just kill it and don't do damage;
  if (target:IsIllusion() and not target:IsNull() and not target:IsStrongIllusionOAA()) then --or (target:IsCreep() and not target:IsAncient() and not target:IsOAABoss() and not target:IsCreepHero()) then
    --if target:IsCreep() then
      --caster:HealWithParams(target:GetHealth() * burst_heal_percent / 100, self, false, true, caster, true)
    --end
    if caster:GetTeamNumber() == DOTA_TEAM_NEUTRALS then
      target:ForceKillOAA(false)
    else
      target:Kill(self, caster)
    end
    return
  end

  -- Add debuff
  if level > 5 then
    local debuff_duration = target:GetValueChangedByStatusResistance(self:GetSpecialValueFor("blind_duration"), caster, self)
    target:AddNewModifier(caster, self, "modifier_item_oaa_dagon_debuff", {duration = debuff_duration})
  end

  --local isRealHero = target:IsRealHero() -- do this check before doing dmg to prevent doing check on a killed/deleted target
  --local isStrongIllu = target:IsStrongIllusionOAA()

  if target:IsOAABoss() then
    hp_percent = hp_percent * (1 - BOSS_DMG_RED_FOR_PCT_SPELLS/100)
  end

  --local damageDone =
  ApplyDamage({
    victim = target,
    attacker = caster,
    damage = damage + target:GetHealth() * hp_percent * 0.01,
    damage_type = damage_type,
    ability = self
  })

  -- Dagon Burst Spell Lifesteal based on dmg done
  --local heal_amount = 0
  --if isRealHero or isStrongIllu then
    --heal_amount = damageDone * (burst_heal_percent - hero_spell_lifesteal) / 100
  --else
    -- For ancients and bosses
    --heal_amount = damageDone * (burst_heal_percent - creep_spell_lifesteal) / 100
  --end
  --caster:HealWithParams(heal_amount, self, false, true, caster, true)
end

---------------------------------------------------------------------------------------------------

modifier_item_oaa_dagon_passive = class(ModifierBaseClass)

function modifier_item_oaa_dagon_passive:IsHidden()
  return true
end
function modifier_item_oaa_dagon_passive:IsDebuff()
  return false
end
function modifier_item_oaa_dagon_passive:IsPurgable()
  return false
end

function modifier_item_oaa_dagon_passive:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_oaa_dagon_passive:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.int = ability:GetSpecialValueFor("bonus_int")
    self.str = ability:GetSpecialValueFor("bonus_str")
    self.agi = ability:GetSpecialValueFor("bonus_agi")
    self.hp = ability:GetSpecialValueFor("bonus_health")
    self.mana = ability:GetSpecialValueFor("bonus_mana")
  end
end

modifier_item_oaa_dagon_passive.OnRefresh = modifier_item_oaa_dagon_passive.OnCreated

function modifier_item_oaa_dagon_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_MANA_BONUS,
  }
end

function modifier_item_oaa_dagon_passive:GetModifierBonusStats_Strength()
  return self.str or self:GetAbility():GetSpecialValueFor("bonus_str")
end

function modifier_item_oaa_dagon_passive:GetModifierBonusStats_Agility()
  return self.agi or self:GetAbility():GetSpecialValueFor("bonus_agi")
end

function modifier_item_oaa_dagon_passive:GetModifierBonusStats_Intellect()
  return self.int or self:GetAbility():GetSpecialValueFor("bonus_int")
end

function modifier_item_oaa_dagon_passive:GetModifierHealthBonus()
  return self.hp or self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_oaa_dagon_passive:GetModifierManaBonus()
  return self.mana or self:GetAbility():GetSpecialValueFor("bonus_mana")
end

---------------------------------------------------------------------------------------------------

modifier_item_oaa_dagon_non_stacking_stats = class(ModifierBaseClass)

function modifier_item_oaa_dagon_non_stacking_stats:IsHidden()
  return true
end

function modifier_item_oaa_dagon_non_stacking_stats:IsDebuff()
  return false
end

function modifier_item_oaa_dagon_non_stacking_stats:IsPurgable()
  return false
end

function modifier_item_oaa_dagon_non_stacking_stats:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.cast_range = ability:GetSpecialValueFor("cast_range_bonus")
    --self.spell_amp = ability:GetSpecialValueFor("spell_amp")
  end
end

modifier_item_oaa_dagon_non_stacking_stats.OnRefresh = modifier_item_oaa_dagon_non_stacking_stats.OnCreated

function modifier_item_oaa_dagon_non_stacking_stats:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_CAST_RANGE_BONUS_STACKING,
    --MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
  }
end

function modifier_item_oaa_dagon_non_stacking_stats:GetModifierCastRangeBonusStacking()
  local parent = self:GetParent()

  -- Prevent stacking with Aether Lens and Far Sight
  if parent:HasModifier("modifier_item_aether_lens") or parent:HasModifier("modifier_item_far_sight_non_stacking_stats") then
    return 0
  end

  return self.cast_range or self:GetAbility():GetSpecialValueFor("cast_range_bonus")
end

--function modifier_item_oaa_dagon_non_stacking_stats:GetModifierSpellAmplify_Percentage()
  --return self.spell_amp or self:GetAbility():GetSpecialValueFor("spell_amp")
--end

---------------------------------------------------------------------------------------------------

modifier_item_oaa_dagon_debuff = class(ModifierBaseClass)

function modifier_item_oaa_dagon_debuff:IsHidden()
  return false
end

function modifier_item_oaa_dagon_debuff:IsDebuff()
  return true
end

function modifier_item_oaa_dagon_debuff:IsPurgable()
  return true
end

function modifier_item_oaa_dagon_debuff:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.blind_pct = ability:GetSpecialValueFor("blind_pct")
  end
end

modifier_item_oaa_dagon_debuff.OnRefresh = modifier_item_oaa_dagon_debuff.OnCreated

function modifier_item_oaa_dagon_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MISS_PERCENTAGE,
  }
end

function modifier_item_oaa_dagon_debuff:GetModifierMiss_Percentage()
  return self.blind_pct or self:GetAbility():GetSpecialValueFor("blind_pct")
end

function modifier_item_oaa_dagon_debuff:GetTexture()
  return "item_dagon_5"
end
