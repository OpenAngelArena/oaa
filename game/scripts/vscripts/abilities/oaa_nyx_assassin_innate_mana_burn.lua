
LinkLuaModifier("modifier_nyx_assassin_innate_mana_burn_oaa", "abilities/oaa_nyx_assassin_innate_mana_burn.lua", LUA_MODIFIER_MOTION_NONE)

---------------------------------------------------------------------------------------------------
nyx_assassin_innate_mana_burn_oaa = class(AbilityBaseClass)
---------------------------------------------------------------------------------------------------

function nyx_assassin_innate_mana_burn_oaa:GetIntrinsicModifierName()
  return "modifier_nyx_assassin_innate_mana_burn_oaa"
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
modifier_nyx_assassin_innate_mana_burn_oaa = class(ModifierBaseClass)
---------------------------------------------------------------------------------------------------

function modifier_nyx_assassin_innate_mana_burn_oaa:IsHidden()
  return true
end

function modifier_nyx_assassin_innate_mana_burn_oaa:IsDebuff()
  return false
end

function modifier_nyx_assassin_innate_mana_burn_oaa:IsPurgable()
  return false
end

function modifier_nyx_assassin_innate_mana_burn_oaa:RemoveOnDeath()
  return false
end

function modifier_nyx_assassin_innate_mana_burn_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_TAKEDAMAGE
  }
end

if IsServer() then
  function modifier_nyx_assassin_innate_mana_burn_oaa:OnTakeDamage(event)
    local attacker = event.attacker
    local damaged_unit = event.unit
    local caster = self:GetParent() or self:GetCaster()
    local ability = self:GetAbility()

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if attacker ~= caster then
      return
    end

    -- Check if attacker is broken or illusion
    if attacker:IsIllusion() or attacker:PassivesDisabled() then
      return
    end

    -- If ability doesn't exist -> don't continue
    if not ability or ability:IsNull() then
      return
    end

    -- Check if damaged entity exists
    if not damaged_unit or damaged_unit:IsNull() then
      return
    end

    -- Don't continue if self damage
    if damaged_unit == attacker then
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

    local inflictor = event.inflictor

    -- happpens for auto attacks and other specific situations
    if not inflictor or inflictor:IsNull() then
      return
    end

    -- this inflictor is not the right type
    if not inflictor.IsItem or not inflictor.GetAbilityName then
      return
    end

    -- skip items
    if inflictor:IsItem() then
      return
    end

    -- should only be abilities now
    local threshold = ability:GetSpecialValueFor("damage_threshold")

    -- original damage is before reductions and amps
    -- if event.damage < threshold then
    if event.original_damage < threshold then
      return
    end

    -- unit has no max mana, don't show visual effects
    if damaged_unit:GetMaxMana() < 1 then
      return
    end

    -- as 0-1 percent
    local manaPercent = ability:GetSpecialValueFor("mana_pct") / 100
    local manaCurrent = damaged_unit:GetMana()
    local manaToBurn = manaCurrent * manaPercent

    local nFXIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_nyx_assassin/nyx_assassin_mana_burn.vpcf", PATTACH_ABSORIGIN_FOLLOW, damaged_unit)
    -- ParticleManager:SetParticleControlEnt(nFXIndex, 1, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetOrigin(), false)
    ParticleManager:ReleaseParticleIndex(nFXIndex)

    damaged_unit:EmitSound("Hero_NyxAssassin.ManaBurn.Target")
    damaged_unit:ReduceMana(manaToBurn, ability)
  end
end
