sohei_way_of_the_ki = class( AbilityBaseClass )

LinkLuaModifier("modifier_sohei_way_of_the_ki_passive", "abilities/sohei/sohei_way_of_the_ki.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sohei_way_of_the_ki_buff", "abilities/sohei/sohei_way_of_the_ki.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sohei_way_of_the_ki_debuff", "abilities/sohei/sohei_way_of_the_ki.lua", LUA_MODIFIER_MOTION_NONE)

function sohei_way_of_the_ki:GetIntrinsicModifierName()
  return "modifier_sohei_way_of_the_ki_passive"
end

function sohei_way_of_the_ki:OnHeroCalculateStatBonus()
  local caster = self:GetCaster()

  if caster:HasShardOAA() or self:IsStolen() then
    self:SetHidden(false)
    if self:GetLevel() <= 0 then
      self:SetLevel(1)
    end
  else
    self:SetHidden(true)
  end
end

function sohei_way_of_the_ki:OnToggle()
  local caster = self:GetCaster()

  -- Activation sound
  --caster:EmitSound("")

  if caster:HasModifier("modifier_sohei_way_of_the_ki_buff") then
    caster:RemoveModifierByName("modifier_sohei_way_of_the_ki_buff")
  else
    caster:AddNewModifier(caster, self, "modifier_sohei_way_of_the_ki_buff", {})
  end
end

---------------------------------------------------------------------------------------------------

modifier_sohei_way_of_the_ki_passive = class(ModifierBaseClass)

function modifier_sohei_way_of_the_ki_passive:IsHidden()
  return true
end

function modifier_sohei_way_of_the_ki_passive:IsDebuff()
  return false
end

function modifier_sohei_way_of_the_ki_passive:IsPurgable()
  return false
end

function modifier_sohei_way_of_the_ki_passive:RemoveOnDeath()
  return false
end

function modifier_sohei_way_of_the_ki_passive:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_TAKEDAMAGE,
  }
end

if IsServer() then
  function modifier_sohei_way_of_the_ki_passive:OnTakeDamage(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local damaged_unit = event.unit
    local inflictor = event.inflictor

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if attacker ~= parent then
      return
    end

    -- Check if damaged entity exists
    if not damaged_unit or damaged_unit:IsNull() then
      return
    end

    -- Ignore self damage and damage to allies
    if damaged_unit == attacker or damaged_unit:GetTeamNumber() == attacker:GetTeamNumber() then
      return
    end

    -- Check if attacker is an illusion or dead
    if attacker:IsIllusion() or not attacker:IsAlive() then
      return
    end

    -- Check if damaged entity is an item, rune or something weird
    if damaged_unit.GetUnitName == nil then
      return
    end

    -- Don't affect buildings, wards and invulnerable units.
    if damaged_unit:IsTower() or damaged_unit:IsBarracks() or damaged_unit:IsBuilding() or damaged_unit:IsOther() or damaged_unit:IsInvulnerable() then
      return
    end

    -- Check if damage source is a spell or item
    if not inflictor then
      return
    end

    -- If inflictor is an item (radiance e.g.), don't continue
    if inflictor:IsItem() then
      return
    end

    -- Ignore damage that has the no-reflect flag
    if bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) > 0 then
      return
    end

    -- Ignore damage that has hp removal flag
    if bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) > 0 then
      return
    end

    -- Apply debuff
    local ability = self:GetAbility()
    local duration = ability:GetSpecialValueFor("debuff_duration")
    damaged_unit:AddNewModifier(parent, ability, "modifier_sohei_way_of_the_ki_debuff", {duration = duration})
  end
end

---------------------------------------------------------------------------------------------------

modifier_sohei_way_of_the_ki_buff = class(ModifierBaseClass)

function modifier_sohei_way_of_the_ki_buff:IsHidden()
  return not IsInToolsMode()
end

function modifier_sohei_way_of_the_ki_buff:IsDebuff()
  return false
end

function modifier_sohei_way_of_the_ki_buff:IsPurgable()
  return false
end

---------------------------------------------------------------------------------------------------

modifier_sohei_way_of_the_ki_debuff = class(ModifierBaseClass)

function modifier_sohei_way_of_the_ki_debuff:IsHidden()
  return false
end

function modifier_sohei_way_of_the_ki_debuff:IsDebuff()
  return true
end

function modifier_sohei_way_of_the_ki_debuff:IsPurgable()
  return true
end

function modifier_sohei_way_of_the_ki_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
  }
end

function modifier_sohei_way_of_the_ki_debuff:GetModifierTotalDamageOutgoing_Percentage(keys)
  if not self:GetCaster():HasModifier("modifier_sohei_way_of_the_ki_buff") then
    return self:GetAbility():GetSpecialValueFor("push_enemy_damage_reduction")
  end
  return 0
end

function modifier_sohei_way_of_the_ki_debuff:GetModifierIncomingDamage_Percentage(keys)
  if self:GetCaster():HasModifier("modifier_sohei_way_of_the_ki_buff") then
    return self:GetAbility():GetSpecialValueFor("pull_damage_amp")
  end
  return 0
end
