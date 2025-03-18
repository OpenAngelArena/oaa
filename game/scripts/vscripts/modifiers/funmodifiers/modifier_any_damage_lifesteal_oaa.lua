-- Hyper Lifesteal

modifier_any_damage_lifesteal_oaa = class(ModifierBaseClass)

function modifier_any_damage_lifesteal_oaa:IsHidden()
  return false
end

function modifier_any_damage_lifesteal_oaa:IsDebuff()
  return false
end

function modifier_any_damage_lifesteal_oaa:IsPurgable()
  return false
end

function modifier_any_damage_lifesteal_oaa:RemoveOnDeath()
  local parent = self:GetParent()
  if parent:IsRealHero() and not parent:IsOAABoss() then
    return false
  end
  return true
end

function modifier_any_damage_lifesteal_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_TAKEDAMAGE,
  }
end

function modifier_any_damage_lifesteal_oaa:OnCreated(kv)
  self.hero_lifesteal = 75
  self.creep_lifesteal = 15 -- self.hero_lifesteal / 5
  self.global = kv.isGlobal == 1

  if not self.global and IsServer() then
    local global_option = OAAOptions.settings.GLOBAL_MODS
    local global_mod = OAAOptions.global_mod
    if global_mod == false and global_option == "GM01" then
      print("modifier_any_damage_lifesteal_oaa - Don't create multiple modifiers if there is a global one")
      self:Destroy()
    end
  end
end

modifier_any_damage_lifesteal_oaa.OnRefresh = modifier_any_damage_lifesteal_oaa.OnCreated

if IsServer() then
  function modifier_any_damage_lifesteal_oaa:OnTakeDamage(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local damaged_unit = event.unit
    local dmg_flags = event.damage_flags
    local damage = event.damage
    local inflictor = event.inflictor

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if not self.global then
      if attacker ~= parent then
        return
      end
    end

    -- Check if damaged entity exists
    if not damaged_unit or damaged_unit:IsNull() then
      return
    end

    -- Ignore self damage
    if damaged_unit == attacker then
      return
    end

    -- Check if entity is an item, rune or something weird
    if damaged_unit.GetUnitName == nil then
      return
    end

    -- Buildings, wards and invulnerable units can't lifesteal
    if attacker:IsTower() or attacker:IsBarracks() or attacker:IsBuilding() or attacker:IsOther() or attacker:IsInvulnerable() then
      return
    end

    -- Don't affect buildings, wards and invulnerable units.
    if damaged_unit:IsTower() or damaged_unit:IsBarracks() or damaged_unit:IsBuilding() or damaged_unit:IsOther() or damaged_unit:IsInvulnerable() then
      return
    end

    local succubus = attacker:FindAbilityByName("queenofpain_succubus")
    local isSuccubus = succubus and succubus:GetLevel() > 0
    local spellLifestealReflected = false
    if isSuccubus then
      spellLifestealReflected = succubus:GetSpecialValueFor("lifesteal_reflected") == 1
    end

    -- Ignore pure damage
    if event.damage_type == DAMAGE_TYPE_PURE then
      if not isSuccubus then
        return
      end
    end

    -- Ignore damage that has the no-reflect flag
    if bit.band(flags, DOTA_DAMAGE_FLAG_REFLECTION) > 0 then
      if not spellLifestealReflected then
        return
      end
    end

    -- Ignore damage that has the no-spell-lifesteal flag
    if bit.band(flags, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL) > 0 then
      if not spellLifestealReflected then
        return
      end
    end

    -- Ignore damage with HP removal flag
    if bit.band(dmg_flags, DOTA_DAMAGE_FLAG_HPLOSS) > 0 then
      return
    end

    -- Ignore damage with no-spell-amplification flag
    -- if bit.band(dmg_flags, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION) > 0 then
      -- return
    -- end

    -- Don't heal while dead
    if not attacker:IsAlive() then
      return
    end

    -- Check damage if 0 or negative
    if damage <= 0 then
      return
    end

    -- Calculate the lifesteal (heal) amount
    local heal_amount = 0
    if damaged_unit:IsRealHero() or damaged_unit:IsStrongIllusionOAA() then
      heal_amount = damage * self.hero_lifesteal / 100
    else
      -- Illusions are treated as creeps too
      heal_amount = damage * self.creep_lifesteal / 100
    end

    if heal_amount > 0 then
      -- Particle
      if inflictor then
        -- Spell Lifesteal
        attacker:HealWithParams(heal_amount, nil, false, true, attacker, true)
        local particle1 = ParticleManager:CreateParticle("particles/items3_fx/octarine_core_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, attacker)
        ParticleManager:SetParticleControl(particle1, 0, attacker:GetAbsOrigin())
        ParticleManager:ReleaseParticleIndex(particle1)
      else
        -- Normal Lifesteal
        attacker:HealWithParams(heal_amount, nil, true, true, attacker, false)
        local particle2 = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, attacker)
        ParticleManager:ReleaseParticleIndex(particle2)
      end
    end
  end
end

function modifier_any_damage_lifesteal_oaa:GetTexture()
  return "item_vampire_fangs"
end
