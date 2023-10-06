abaddon_borrowed_time_oaa = class(AbilityBaseClass)

LinkLuaModifier("modifier_oaa_borrowed_time_passive", "abilities/oaa_abaddon_borrowed_time.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oaa_borrowed_time_buff_caster", "abilities/oaa_abaddon_borrowed_time.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oaa_borrowed_time_buff_ally", "abilities/oaa_abaddon_borrowed_time.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oaa_borrowed_time_immolation", "abilities/oaa_abaddon_borrowed_time.lua", LUA_MODIFIER_MOTION_NONE)

function abaddon_borrowed_time_oaa:GetIntrinsicModifierName()
  return "modifier_oaa_borrowed_time_passive"
end

--[[
function abaddon_borrowed_time_oaa:GetCooldown(level)
  local caster = self:GetCaster()
  local base_cd = self.BaseClass.GetCooldown(self, level)

  -- Talent that reduces cooldown
  local talent = caster:FindAbilityByName("special_bonus_unique_abaddon_5")
  if talent and talent:GetLevel() > 0 then
    return base_cd - math.abs(talent:GetSpecialValueFor("value"))
  end

  return base_cd
end
]]

function abaddon_borrowed_time_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local buff_duration = self:GetSpecialValueFor("duration")

  if caster:HasScepter() then
    buff_duration = self:GetSpecialValueFor("duration_scepter")
  end

  -- Strong Dispel
  caster:Purge(false, true, false, true, false)

  -- Add the Borrowed Time modifier to the caster
  caster:AddNewModifier(caster, self, "modifier_oaa_borrowed_time_buff_caster", {duration = buff_duration})

  -- Immolation talent
  local talent = caster:FindAbilityByName("special_bonus_unique_abaddon_1_oaa")
  if talent and talent:GetLevel() > 0 then
    caster:AddNewModifier(caster, talent, "modifier_oaa_borrowed_time_immolation", {duration = buff_duration})
  end

  -- Caster responses (not really important)
  -- local responses = {
    -- "abaddon_abad_borrowedtime_01",
    -- "abaddon_abad_borrowedtime_02",
    -- "abaddon_abad_borrowedtime_03",
    -- "abaddon_abad_borrowedtime_04",
    -- "abaddon_abad_borrowedtime_05",
    -- "abaddon_abad_borrowedtime_06",
    -- "abaddon_abad_borrowedtime_07",
    -- "abaddon_abad_borrowedtime_08",
    -- "abaddon_abad_borrowedtime_09",
    -- "abaddon_abad_borrowedtime_10",
    -- "abaddon_abad_borrowedtime_11"
  -- }

  -- Play Sound
  caster:EmitSound("Hero_Abaddon.BorrowedTime")
end

function abaddon_borrowed_time_oaa:ProcsMagicStick()
  return true
end

function abaddon_borrowed_time_oaa:OnUnStolen()
  local caster = self:GetCaster()
  local modifier = caster:FindModifierByName("modifier_oaa_borrowed_time_passive")
  if modifier then
    caster:RemoveModifierByName("modifier_oaa_borrowed_time_passive")
  end
end

---------------------------------------------------------------------------------------------------

modifier_oaa_borrowed_time_passive = class(ModifierBaseClass)

function modifier_oaa_borrowed_time_passive:IsHidden()
  return true
end

function modifier_oaa_borrowed_time_passive:IsDebuff()
  return false
end

function modifier_oaa_borrowed_time_passive:IsPurgable()
  return false
end

function modifier_oaa_borrowed_time_passive:OnCreated()
  if IsServer() then
    if self:GetParent():IsIllusion() then
      self:Destroy()
      return
    end
    local ability = self:GetAbility()
    self.hp_threshold = ability:GetSpecialValueFor("hp_threshold")
    self.pct = ability:GetSpecialValueFor("hp_threshold_max_hp_percent")
    -- Check if we need to auto cast immediately
    self:CheckHealthToTrigger()
  end
end

function modifier_oaa_borrowed_time_passive:CheckHealthToTrigger()
  local parent = self:GetParent()
  local ability = self:GetAbility()

	-- Check for ability state, if parent has break debuff
  if not ability:IsHidden() and ability:IsCooldownReady() and ability:IsOwnersManaEnough() and not parent:PassivesDisabled() and parent:IsAlive() and not parent:IsIllusion() then
    local current_hp = parent:GetHealth()
    local max_hp = parent:GetMaxHealth()
    local hp_threshold = self.hp_threshold + max_hp * self.pct / 100
    if current_hp <= hp_threshold and not parent:HasModifier("modifier_oaa_borrowed_time_buff_caster") then
      if parent:IsChanneling() then
        ability:OnSpellStart()
        ability:UseResources(true, false, false, true)
      else
        parent:CastAbilityImmediately(ability, parent:GetPlayerID())
      end
    end
  end
end

function modifier_oaa_borrowed_time_passive:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_TAKEDAMAGE,
  }
end

if IsServer() then
  function modifier_oaa_borrowed_time_passive:OnTakeDamage(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local damaged_unit = event.unit

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if damaged entity exists
    if not damaged_unit or damaged_unit:IsNull() then
      return
    end

    -- Check if damaged entity has this modifier
    if damaged_unit ~= parent then
      return
    end

    -- Do nothing if damage has HP removal flag
    -- Necro Hearstopper Aura (modifier_necrolyte_heartstopper_aura_effect) doesn't trigger OnTakeDamage event
    -- maybe it's intentional
    if bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then
      return
    end

    -- Do nothing if damaged by a neutral creep
    -- Boss damage can still proc Borrowed Time
    if attacker:GetTeamNumber() == DOTA_TEAM_NEUTRALS and not attacker:IsOAABoss() then
      return
    end

    self:CheckHealthToTrigger()
  end
end

---------------------------------------------------------------------------------------------------

modifier_oaa_borrowed_time_buff_caster = class(ModifierBaseClass)

function modifier_oaa_borrowed_time_buff_caster:IsHidden()
  return false
end

function modifier_oaa_borrowed_time_buff_caster:IsDebuff()
  return false
end

function modifier_oaa_borrowed_time_buff_caster:IsPurgable()
  return false
end

function modifier_oaa_borrowed_time_buff_caster:GetEffectName()
  return "particles/units/heroes/hero_abaddon/abaddon_borrowed_time.vpcf"
end

function modifier_oaa_borrowed_time_buff_caster:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_oaa_borrowed_time_buff_caster:GetStatusEffectName()
  return "particles/status_fx/status_effect_abaddon_borrowed_time.vpcf"
end

function modifier_oaa_borrowed_time_buff_caster:StatusEffectPriority()
  return 15
end

function modifier_oaa_borrowed_time_buff_caster:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK -- using this instead of MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
    -- because Necrophos Aura (modifier_necrolyte_heartstopper_aura_effect) ignores damage reduction but it doesn't ...
    -- ... ignore total damage block
  }
end

if IsServer() then
  function modifier_oaa_borrowed_time_buff_caster:GetModifierTotal_ConstantBlock(kv)
    local parent = self:GetParent()

    -- Show borrowed time heal particle
    local heal_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_abaddon/abaddon_borrowed_time_heal.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    local target_vector = parent:GetAbsOrigin()
    ParticleManager:SetParticleControl(heal_particle, 0, target_vector)
    ParticleManager:SetParticleControl(heal_particle, 1, target_vector)
    ParticleManager:ReleaseParticleIndex(heal_particle)

    -- Heal amount is equal to the damage amount (damage after reductions, not original damage)
    parent:Heal(kv.damage, self:GetAbility())

    -- Block the damage
    return kv.damage
  end
end

function modifier_oaa_borrowed_time_buff_caster:IsAura()
  return self:GetParent():HasScepter()
end

function modifier_oaa_borrowed_time_buff_caster:GetModifierAura()
  return "modifier_oaa_borrowed_time_buff_ally"
end

function modifier_oaa_borrowed_time_buff_caster:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO
end

function modifier_oaa_borrowed_time_buff_caster:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_oaa_borrowed_time_buff_caster:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("redirect_range_scepter")
end

function modifier_oaa_borrowed_time_buff_caster:GetAuraEntityReject(hEntity)
  -- Do not apply aura to the owner of the aura
  if hEntity == self:GetParent() or hEntity:HasModifier("modifier_oaa_borrowed_time_buff_caster") then
    return true
  end

  return false
end

---------------------------------------------------------------------------------------------------

modifier_oaa_borrowed_time_buff_ally = class(ModifierBaseClass)

function modifier_oaa_borrowed_time_buff_ally:IsHidden()
  return false
end

function modifier_oaa_borrowed_time_buff_ally:IsDebuff()
  return false
end

function modifier_oaa_borrowed_time_buff_ally:IsPurgable()
  return false
end

function modifier_oaa_borrowed_time_buff_ally:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
  }
end

if IsServer() then
  function modifier_oaa_borrowed_time_buff_ally:GetModifierIncomingDamage_Percentage(kv)
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    local redirect_pct = 40
    if ability then
      redirect_pct = ability:GetSpecialValueFor("damage_redirect_scepter")
    end

    local redirect_damage = kv.damage * (redirect_pct/100)

    local damage_table = {
      attacker = kv.attacker,
      victim = caster,
      damage = redirect_damage,
      damage_type = kv.damage_type or DAMAGE_TYPE_PURE,
      ability = ability,
    }

    -- Redirect the damage to Abaddon (caster) if Borrowed Time is still active and if damage is not negative
    if caster:HasModifier("modifier_oaa_borrowed_time_buff_caster") and redirect_damage > 0 then
      ApplyDamage(damage_table)
    end

    -- Block the amount of damage on the ally
    return 0 - math.abs(redirect_pct)
  end
end

function modifier_oaa_borrowed_time_buff_ally:GetEffectName()
  return "particles/units/heroes/hero_abaddon/abaddon_borrowed_time_h.vpcf"
end

function modifier_oaa_borrowed_time_buff_ally:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

---------------------------------------------------------------------------------------------------

modifier_oaa_borrowed_time_immolation = class(ModifierBaseClass)

function modifier_oaa_borrowed_time_immolation:IsHidden()
  return false
end

function modifier_oaa_borrowed_time_immolation:IsDebuff()
  return false
end

function modifier_oaa_borrowed_time_immolation:IsPurgable()
  return false
end

function modifier_oaa_borrowed_time_immolation:OnCreated()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  local talent = self:GetAbility()

  self.ability = parent:FindAbilityByName("abaddon_borrowed_time_oaa")

  self.dps = talent:GetSpecialValueFor("bonus_immolate_damage")
  self.radius = talent:GetSpecialValueFor("bonus_immolate_aoe")
  self.interval = talent:GetSpecialValueFor("immolate_tick")

  self:OnIntervalThink()
  self:StartIntervalThink(self.interval)
end

function modifier_oaa_borrowed_time_immolation:OnIntervalThink()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()

  -- Damage table
  local damage_table = {
    attacker = parent,
    damage = self.dps * self.interval,
    ability = self.ability,
  }

  -- Self damage
  damage_table.victim = parent
  damage_table.damage_type = DAMAGE_TYPE_PURE
  damage_table.damage_flags = bit.bor(DOTA_DAMAGE_FLAG_REFLECTION, DOTA_DAMAGE_FLAG_NON_LETHAL, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL)

  ApplyDamage(damage_table)

  -- Damage enemies
  damage_table.damage_type = DAMAGE_TYPE_MAGICAL
  damage_table.damage_flags = DOTA_DAMAGE_FLAG_NONE

  local enemies = FindUnitsInRadius(
    parent:GetTeamNumber(),
    parent:GetAbsOrigin(),
    nil,
    self.radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() then
      damage_table.victim = enemy

      ApplyDamage(damage_table)
    end
  end
end
