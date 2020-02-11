abaddon_borrowed_time_oaa = class(AbilityBaseClass)

LinkLuaModifier("modifier_oaa_borrowed_time_passive", "abilities/oaa_abaddon_borrowed_time.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oaa_borrowed_time_buff_caster", "abilities/oaa_abaddon_borrowed_time.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oaa_borrowed_time_buff_ally", "abilities/oaa_abaddon_borrowed_time.lua", LUA_MODIFIER_MOTION_NONE)

function abaddon_borrowed_time_oaa:GetIntrinsicModifierName()
  return "modifier_oaa_borrowed_time_passive"
end

function abaddon_borrowed_time_oaa:OnSpellStart()
  if IsServer() then
    local caster = self:GetCaster()
    local buff_duration = self:GetSpecialValueFor("duration")

    if caster:HasScepter() then
      buff_duration = self:GetSpecialValueFor("duration_scepter")
    end

    -- Strong Dispel
    caster:Purge(false, true, false, true, true)

    -- Add the Borrowed Time modifier to the caster
    caster:AddNewModifier(caster, self, "modifier_oaa_borrowed_time_buff_caster", {duration = buff_duration})

    -- Caster responses (not really important)
    --local responses = {"abaddon_abad_borrowedtime_02","abaddon_abad_borrowedtime_03","abaddon_abad_borrowedtime_04","abaddon_abad_borrowedtime_05","abaddon_abad_borrowedtime_06","abaddon_abad_borrowedtime_07","abaddon_abad_borrowedtime_08","abaddon_abad_borrowedtime_09","abaddon_abad_borrowedtime_10","abaddon_abad_borrowedtime_11"}
    --if not caster:EmitCasterSound("npc_dota_hero_abaddon", responses, 50, DOTA_CAST_SOUND_FLAG_BOTH_TEAMS, nil, nil) then
      --caster:EmitCasterSound("npc_dota_hero_abaddon", {"abaddon_abad_borrowedtime_01"}, 1, DOTA_CAST_SOUND_FLAG_BOTH_TEAMS, nil, nil)
    --end

    -- Play Sound
    caster:EmitSound("Hero_Abaddon.BorrowedTime")
  end
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

function modifier_oaa_borrowed_time_passive:AllowIllusionDuplicate()
  return false
end

function modifier_oaa_borrowed_time_passive:OnCreated()
  if IsServer() then
    self.hp_threshold = self:GetAbility():GetSpecialValueFor("hp_threshold")
    -- Check if we need to auto cast immediately
    self:CheckHealthToTrigger()
  end
end

function modifier_oaa_borrowed_time_passive:CheckHealthToTrigger()
  local parent = self:GetParent()
  local ability = self:GetAbility()

	-- Check for ability state, if parent has break debuff
  if not ability:IsHidden() and ability:IsCooldownReady() and ability:IsOwnersManaEnough() and not parent:PassivesDisabled() and parent:IsAlive() and not parent:IsIllusion() then
    local hp_threshold = self.hp_threshold
    local current_hp = parent:GetHealth()
    if current_hp <= hp_threshold and not parent:HasModifier("modifier_oaa_borrowed_time_buff_caster") then
      parent:CastAbilityImmediately(ability, parent:GetPlayerID())
      -- ^ this is not good because it cancels channeling but its not gamebreaking either
    end
  end
end

function modifier_oaa_borrowed_time_passive:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_TAKEDAMAGE
  }

  return funcs
end

function modifier_oaa_borrowed_time_passive:OnTakeDamage(event)
  if IsServer() then
    local parent = self:GetParent()

    if parent ~= event.unit then
      return
    end

    -- Do nothing if damage has HP removal flag
    -- Necro Hearstopper Aura (modifier_necrolyte_heartstopper_aura_effect) doesn't trigger OnTakeDamage event
    -- maybe its intentional
    if bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then
      return
    end

    -- Do nothing if damaged by non-player controlled creep or neutral creep
    -- Boss damage can still proc Borrowed Time
    if event.attacker:IsNeutralCreep(false) then
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
  local funcs = {
    MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK -- using this instead of MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
    -- because Necrophos Aura (modifier_necrolyte_heartstopper_aura_effect) ignores damage reduction but it doesn't ...
    -- ... ignore damage block
  }

  return funcs
end

function modifier_oaa_borrowed_time_buff_caster:GetModifierTotal_ConstantBlock(kv)
  if IsServer() then
    local parent = self:GetParent()

    -- Show borrowed time heal particle
    local heal_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_abaddon/abaddon_borrowed_time_heal.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    local target_vector = parent:GetAbsOrigin()
    ParticleManager:SetParticleControl(heal_particle, 0, target_vector)
    ParticleManager:SetParticleControl(heal_particle, 1, target_vector)
    ParticleManager:ReleaseParticleIndex(heal_particle)

    -- Heal amount is equal to the damage amount (damage after reductions, not original damage)
    parent:Heal(kv.damage, parent)

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
  local funcs = {
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
  }

  return funcs
end

function modifier_oaa_borrowed_time_buff_ally:GetModifierIncomingDamage_Percentage(kv)
  if IsServer() then
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    local damage_table = {}
    damage_table.attacker = kv.attacker
    damage_table.damage_type = kv.damage_type or DAMAGE_TYPE_PURE

    local redirect_pct = 40
    if ability then
      redirect_pct = ability:GetSpecialValueFor("damage_redirect_scepter")
      damage_table.ability = ability
    end

    local redirect_damage = kv.damage * (redirect_pct/100)
    damage_table.damage = redirect_damage
    damage_table.victim = caster

    -- Redirect the damage to Abaddon (caster) if Borrowed Time is still active and if damage is not negative
    if caster:HasModifier("modifier_oaa_borrowed_time_buff_caster") and redirect_damage > 0 then
      ApplyDamage(damage_table)
    end

    -- Block the amount of damage on the ally
    return -(redirect_pct)
  end
end

function modifier_oaa_borrowed_time_buff_ally:GetEffectName()
  return "particles/units/heroes/hero_abaddon/abaddon_borrowed_time_h.vpcf"
end

function modifier_oaa_borrowed_time_buff_ally:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end
