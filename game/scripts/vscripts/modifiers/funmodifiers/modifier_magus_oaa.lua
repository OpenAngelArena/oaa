LinkLuaModifier("modifier_magus_cooldown_oaa", "modifiers/funmodifiers/modifier_magus_oaa.lua", LUA_MODIFIER_MOTION_NONE)

modifier_magus_oaa = class(ModifierBaseClass)

function modifier_magus_oaa:IsHidden()
  return false
end

function modifier_magus_oaa:IsDebuff()
  return false
end

function modifier_magus_oaa:IsPurgable()
  return false
end

function modifier_magus_oaa:RemoveOnDeath()
  local parent = self:GetParent()
  if parent:IsRealHero() and not parent:IsOAABoss() then
    return false
  end
  return true
end

function modifier_magus_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

function modifier_magus_oaa:OnCreated()
  self.chance = 25
  self.cooldown = 0.5
  self.ignore_abilities = {
    abaddon_borrowed_time_oaa = true,
    brewmaster_primal_split = true,
    dark_willow_shadow_realm = true,
    --dazzle_good_juju = true,
    dazzle_shallow_grave = true,
    earth_spirit_petrify = true,
    --obsidian_destroyer_astral_imprisonment = true,
    --oracle_fates_edict = true,
    oracle_false_promise = true,
    phantom_lancer_doppelwalk = true,
    puck_phase_shift = true,
    riki_tricks_of_the_trade = true,
    --shadow_demon_disruption = true,
    tusk_snowball = true,
    void_spirit_dissimilate = true,
    witch_doctor_voodoo_switcheroo_oaa = true,
    zuus_thundergods_wrath = 1,
    enigma_demonic_conversion = 1,
    enigma_demonic_conversion_oaa = true,
    silencer_global_silence = 1,
    chen_holy_persuasion = 1,
    ember_spirit_sleight_of_fist = 1,
    enchantress_enchant = 1,
    --furion_wrath_of_nature = 1,
    --furion_wrath_of_nature_oaa = true,
    life_stealer_infest = 1,
    morphling_morph = 1,
    --warlock_upheaval = 1,
    --wisp_spirits = 1,
    clinkz_death_pact = 1,
    clinkz_death_pact_oaa = true,
    treant_eyes_in_the_forest = 1,
    rubick_telekinesis_land_self = 1,
    monkey_king_wukongs_command = 1,
    monkey_king_wukongs_command_oaa = true,
    --antimage_blink = 1,
    chaos_knight_phantasm = 1,
    naga_siren_mirror_image = 1,
    --phantom_lancer_spirit_lance = 1,
    spectre_haunt = 1,
    terrorblade_conjure_image = 1,
    arc_warden_tempest_double = 1,
    tidehunter_anchor_smash = 1,
    monkey_king_boundless_strike = 1,
    mars_gods_rebuke = 1,
    void_spirit_astral_step = 1,
    night_stalker_hunter_in_the_night = true,
    sohei_flurry_of_blows = true,
    spectre_reality = 1,
    medusa_stone_gaze = 1,
    pangolier_swashbuckle = 1,
    tiny_toss_tree = 1,
    snapfire_gobble_up = 1,
    juggernaut_omnislash = 1,
  }
end

if IsServer() then
  function modifier_magus_oaa:OnAttackLanded(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local target = event.target

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if attacker ~= parent then
      return
    end

    -- Check if attacker is alive, silenced, hexed or disarmed
    if not attacker:IsAlive() or attacker:IsSilenced() or attacker:IsHexed() or attacker:IsDisarmed() then
      return
    end

    -- Check if attacked unit exists
    if not target or target:IsNull() then
      return
    end

    -- Check for existence of GetUnitName method to determine if target is a unit or an item (or rune)
    -- items don't have that method -> nil; if the target is an item, don't continue
    if target.GetUnitName == nil then
      return
    end

    -- No need to proc if target is invulnerable, spell immune or dead
    if target:IsInvulnerable() or target:IsOutOfGame() or not target:IsAlive() or target:IsMagicImmune() then
      return
    end

    -- Don't proc if passive is on cooldown
    if attacker:HasModifier("modifier_magus_cooldown_oaa") then
      return
    end

    if RandomInt(1, 100) <= self.chance then

      self:CastASpell(attacker, target)

      -- Start cooldown by adding a modifier
      attacker:AddNewModifier(attacker, nil, "modifier_magus_cooldown_oaa", {duration = self.cooldown})
    end
  end
end

function modifier_magus_oaa:CastASpell(caster, target)
  local ability = self:GetRandomSpell(caster)

  if not ability then
    return
  end

  local target_team = ability:GetAbilityTargetTeam() or DOTA_UNIT_TARGET_TEAM_BOTH
  local behavior = ability:GetBehaviorInt()
  local real_target = target
  local isUnitTargetting = bit.band(behavior, DOTA_ABILITY_BEHAVIOR_UNIT_TARGET) > 0
  local isPointTargetting = bit.band(behavior, DOTA_ABILITY_BEHAVIOR_POINT) > 0
  local isChannel = bit.band(behavior, DOTA_ABILITY_BEHAVIOR_CHANNELLED) > 0

  if target_team == DOTA_UNIT_TARGET_TEAM_FRIENDLY then
    if RandomInt(1, 2) == 1 then
      real_target = caster
    else
      real_target = self:FindRandomAlly(ability)
    end
  elseif target_team == DOTA_UNIT_TARGET_TEAM_BOTH then
    local rand = RandomInt(1, 4)
    if rand == 1 then
      real_target = caster
    elseif rand == 2 then
      real_target = target
    elseif rand == 3 then
      real_target = self:FindRandomAlly(ability)
    else
      real_target = self:FindRandomEnemy(ability, target)
    end
  end

  if real_target then
    local real_caster = caster or ability:GetCaster()

    if isUnitTargetting then
      real_caster:SetCursorCastTarget(real_target)
    end

    if isPointTargetting then
      real_caster:SetCursorPosition(real_target:GetAbsOrigin())
    end

    -- Spell Block check
    if real_target:TriggerSpellAbsorb(ability) and isUnitTargetting then
      return
    end

    local modern = false
    if modern then
      local storedcooldown = ability:GetCooldownTimeRemaining()
      local storedmanacost = ability:GetManaCost(ability:GetLevel())
      ability:EndCooldown()
      real_caster:CastAbilityImmediately(ability, real_caster:GetPlayerOwnerID())
      ability:EndCooldown()
      if (storedcooldown > 0) then
        ability:StartCooldown(storedcooldown)
      end
      real_caster:GiveMana(storedmanacost)
    else
      if isChannel then
        -- Create a dummy and cast the spell
        return
      else
        ability:OnAbilityPhaseStart()
        ability:OnSpellStart()
      end
    end
  end
end

function modifier_magus_oaa:GetRandomSpell(caster)
  if not caster or caster:IsIllusion() or caster:IsTempestDouble() then
    return nil
  end

  local candidates = {}
  for i = 0, caster:GetAbilityCount()-1 do
    local ability = caster:GetAbilityByIndex(i)
    if ability then
      if not ability:IsItem() and not ability:IsHidden() and not ability:IsToggle() and ability:IsTrained() and ability:IsStealable() and not ability:IsPassive() and not self.ignore_abilities[ability:GetName()] then
        table.insert(candidates, ability)
      end
    end
  end

  if #candidates > 0 then
    return candidates[RandomInt(1, #candidates)]
  end

  return nil
end

function modifier_magus_oaa:FindRandomAlly(ability)
  local random_ally
  local parent = self:GetParent()

  local allies = FindUnitsInRadius(
    parent:GetTeamNumber(),
    parent:GetAbsOrigin(),
    nil,
    ability:GetEffectiveCastRange(parent:GetAbsOrigin(), parent),
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    ability:GetAbilityTargetType(),
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  for _, ally in pairs(allies) do
    if ally and ally ~= parent then
      random_ally = ally
      break
    end
  end

  return random_ally or parent
end

function modifier_magus_oaa:FindRandomEnemy(ability, target)
  local random_enemy
  local parent = self:GetParent()

  local enemies = FindUnitsInRadius(
    parent:GetTeamNumber(),
    parent:GetAbsOrigin(),
    nil,
    ability:GetEffectiveCastRange(target:GetAbsOrigin(), target),
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    ability:GetAbilityTargetType(),
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  for _, enemy in pairs(enemies) do
    if enemy and enemy ~= target then
      random_enemy = enemy
      break
    end
  end

  return random_enemy or target
end

function modifier_magus_oaa:GetTexture()
  return "wisp_spirits"
end

---------------------------------------------------------------------------------------------------

modifier_magus_cooldown_oaa = class(ModifierBaseClass)

function modifier_magus_cooldown_oaa:IsHidden()
  return true
end

function modifier_magus_cooldown_oaa:IsDebuff()
  return true
end

function modifier_magus_cooldown_oaa:IsPurgable()
  return false
end
