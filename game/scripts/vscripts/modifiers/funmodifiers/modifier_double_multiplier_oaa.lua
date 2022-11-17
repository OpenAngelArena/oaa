modifier_double_multiplier_oaa = class(ModifierBaseClass)

function modifier_double_multiplier_oaa:IsHidden()
  return false
end

function modifier_double_multiplier_oaa:IsDebuff()
  return false
end

function modifier_double_multiplier_oaa:IsPurgable()
  return false
end

function modifier_double_multiplier_oaa:RemoveOnDeath()
  local parent = self:GetParent()
  if parent:IsRealHero() and not parent:IsOAABoss() then
    return false
  end
  return true
end

function modifier_double_multiplier_oaa:OnCreated()
  self.multiplier = 2
  if IsServer() then
    self:SetStackCount(self.multiplier)
  end
end

function modifier_double_multiplier_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
    MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE
  }
end

local ignored_abilities = {
  "arc_warden_tempest_double",          -- because fuck you
  "bristleback_bristleback",            -- breakable but annoying
  "bristleback_bristleback_oaa",        -- breakable but annoying
  "kunkka_ghostship",                   -- 80% dmg reduction
  "legion_commander_duel",              -- here because of scepter - 100% dmg reduction
  "medusa_mana_shield",                 -- 140% dmg reduction
  "meepo_divided_we_stand",             -- probably crashes
  "meepo_together_we_stand_oaa",        -- 100% dmg reduction
  "monkey_king_wukongs_command",        -- LAG
  "monkey_king_wukongs_command_oaa",    -- LAG
  "nyx_assassin_burrow",                -- 80% dmg reduction
  --"pangolier_shield_crash",           -- dispellable
  "spectre_dispersion",                 -- breakable but annoying
  "ursa_enrage",                        -- 160% dmg reduction
  --"vengefulspirit_nether_swap",       -- dispellable
  --"visage_gravekeepers_cloak",        -- breakable and has downsides as well
  --"visage_gravekeepers_cloak_oaa",    -- breakable and has downsides as well
}

local ignore_kvs = {
  "ancient_creeps_scepter",
  "count",
  "dominate_duration",
  "health_cost_percent",
  "health_damage",
  "illusion_1_damage_out_pct",
  "illusion_2_amount",
  "illusion_2_damage_out_pct",
  "illusion_count",
  "illusion_damage_incoming",
  "illusion_damage_out_pct",
  "illusion_damage_outgoing",
  "illusion_incoming_damage",
  "illusion_incoming_damage_total_tooltip",
  "illusion_outgoing_damage",
  "illusion_outgoing_tooltip",
  "images_count",
  "incoming_damage",
  "incoming_damage_tooltip",
  "max_illusions",
  "max_skeleton_charges",
  "max_targets",
  "max_traps",
  "max_treants",
  "max_units",
  "min_skeleton_spawn",
  "outgoing_damage",
  "outgoing_damage_tooltip",
  "replica_damage_incoming",
  "replica_damage_outgoing",
  "scepter_illusion_damage_in_pct",
  "scepter_illusion_damage_out_pct",
  "scepter_incoming_illusion_damage",
  "shard_total_hits",
  "soldier_count",
  "spawn_count",
  "spiderling_max_count",
  "spirit_amount",
  "spirit_count",
  "spirits",
  "tooltip_health_cost_percent",
  "tooltip_health_damage",
  "tooltip_illusion_damage",
  "tooltip_illusion_total_damage_incoming",
  "tooltip_incoming_damage_total_pct",
  "tooltip_outgoing",
  "tooltip_replica_total_damage_incoming",
  "tooltip_total_illusion_incoming_damage",
  "tooltip_wolf_count",
  "ward_count",
}

function modifier_double_multiplier_oaa:GetModifierOverrideAbilitySpecial(keys)
  local ability = keys.ability
  if not ability or not keys.ability_special_value then
    return 0
  end

  for _, v in pairs(ignored_abilities) do
    if ability:GetAbilityName() == v then
      return 0
    end
  end

  if ability:IsItem() then
    return 0
  end

  return 1
end

function modifier_double_multiplier_oaa:GetModifierOverrideAbilitySpecialValue(keys)
  local ability = keys.ability
  if not keys.ability_special_value or not keys.ability_special_level then
    return
  end

  local value = ability:GetLevelSpecialValueNoOverride(keys.ability_special_value, keys.ability_special_level)

  for _, v in pairs(ignored_abilities) do
    if ability:GetAbilityName() == v then
      return value
    end
  end

  for _, v in pairs(ignore_kvs) do
    if keys.ability_special_value == v then
      return value
    end
  end

  if ability:IsItem() then
    return value
  end

  return value * self.multiplier
end

function modifier_double_multiplier_oaa:GetTexture()
  return "item_talisman_of_evasion"
end
