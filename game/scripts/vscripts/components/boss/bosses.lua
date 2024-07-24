
local function shielder_filter ()
  local lowPlayerCount = GetMapName() == "1v1" or GetMapName() == "tinymode"
  if HeroSelection then
    lowPlayerCount = HeroSelection.lowPlayerCount
  end
  if lowPlayerCount then
    return "npc_dota_boss_twin"
  else
    return "npc_dota_boss_shielder"
  end
end

Bosses = {
  -----------------------------
  ---- TIER 1 SAFE BOSS PIT
  -----------------------------
  {
    "npc_dota_boss_tier_1", -- Roshan
    "npc_dota_boss_twin",
    "npc_dota_creature_ogre_tank_boss",
    "npc_dota_boss_tier_4", -- Killer Tomato
    {
      "npc_dota_boss_tier_1_tier5", -- Tier 5 Roshan
      "npc_dota_boss_twin_tier5",
      "npc_dota_creature_ogre_tank_boss_tier5",
      --"npc_dota_creature_temple_guardian_spawner_tier5",
      "npc_dota_boss_tier_5", -- Big Bird
    }
  },
  -----------------------------
  ---- OTHER PITS
  -----------------------------
  {
    {
      "npc_dota_boss_simple_1", -- Skeleton Boss (Geostrike)
      "npc_dota_boss_simple_5", -- Dire Creep Boss (Great Cleave)
      "npc_dota_boss_simple_7", -- Dire Creep Boss (Kraken Shell)
    },
    {
      --"npc_dota_boss_twin",
      shielder_filter(),
      "npc_dota_boss_simple_2", -- Bear Boss (Fury Swipes)
      "npc_dota_creature_slime_spawner",
      "npc_dota_boss_charger",
      "npc_dota_boss_swiper",
      "npc_dota_boss_carapace",
      "npc_dota_creature_tormentor_boss",
    },
    {
      "npc_dota_creature_ogre_tank_boss",
      "npc_dota_creature_lycan_boss",
      "npc_dota_creature_magma_boss",
      "npc_dota_creature_dire_tower_boss",
    },
    {
      --"npc_dota_boss_tier_4", -- Killer Tomato
      "npc_dota_creature_spider_boss",
      "npc_dota_creature_temple_guardian_spawner",
      "npc_dota_boss_stopfightingyourself",
      "npc_dota_boss_tier_6", -- Spooky Ghost
      "npc_dota_boss_spiders", -- Alchemist Boss
    },
    {
      "npc_dota_boss_simple_1_tier5", -- Tier 5 Skeleton Boss (Geostrike)
      "npc_dota_boss_simple_5_tier5", -- Tier 5 Dire Creep Boss (Great Cleave)
      "npc_dota_boss_twin_tier5",
      "npc_dota_boss_simple_2_tier5", -- Tier 5 Bear Boss (Fury Swipes)
      --"npc_dota_boss_charger_tier5",
      "npc_dota_creature_ogre_tank_boss_tier5",
      "npc_dota_creature_lycan_boss_tier5",
      "npc_dota_creature_temple_guardian_spawner_tier5",
      "npc_dota_boss_stopfightingyourself_tier5"
    }
  },
  -----------------------------
  ---- TIER 1
  -----------------------------
  {
    {
      "npc_dota_boss_simple_1", -- Geostrike
      "npc_dota_boss_simple_5", -- Great Cleave
      "npc_dota_boss_simple_7", -- Kraken Shell
    },
    {
      --"npc_dota_boss_twin",
      shielder_filter(),
      "npc_dota_boss_simple_2", -- Fury Swipes
      "npc_dota_creature_slime_spawner",
      "npc_dota_boss_charger",
      "npc_dota_boss_swiper",
      "npc_dota_boss_carapace",
      "npc_dota_creature_tormentor_boss",
    },
    {
      "npc_dota_creature_ogre_tank_boss",
      "npc_dota_creature_lycan_boss",
      "npc_dota_creature_magma_boss",
      "npc_dota_creature_dire_tower_boss",
    },
    {
      --"npc_dota_boss_tier_4",
      "npc_dota_creature_spider_boss",
      "npc_dota_creature_temple_guardian_spawner",
      "npc_dota_boss_stopfightingyourself",
      "npc_dota_boss_tier_6",
      "npc_dota_boss_spiders",
    },
    {
      "npc_dota_boss_simple_1_tier5", -- Geostrike
      "npc_dota_boss_simple_5_tier5", -- Great Cleave
      "npc_dota_boss_twin_tier5",
      "npc_dota_boss_simple_2_tier5", -- Fury Swipes
      --"npc_dota_boss_charger_tier5",
      "npc_dota_creature_ogre_tank_boss_tier5",
      "npc_dota_creature_lycan_boss_tier5",
      "npc_dota_creature_temple_guardian_spawner_tier5",
      "npc_dota_boss_stopfightingyourself_tier5"
    }
  },
  -----------------------------
  ---- TIER 2
  -----------------------------
  {
    {
      --"npc_dota_boss_twin",
      shielder_filter(),
      "npc_dota_boss_simple_2", -- Fury Swipes
      "npc_dota_creature_slime_spawner",
      "npc_dota_boss_charger",
      "npc_dota_boss_swiper",
      "npc_dota_boss_carapace",
      "npc_dota_creature_tormentor_boss",
    },
    {
      "npc_dota_creature_ogre_tank_boss",
      "npc_dota_creature_lycan_boss",
      "npc_dota_creature_magma_boss",
      "npc_dota_creature_dire_tower_boss",
    },
    {
      --"npc_dota_boss_tier_4",
      "npc_dota_creature_spider_boss",
      "npc_dota_creature_temple_guardian_spawner",
      "npc_dota_boss_stopfightingyourself",
      "npc_dota_boss_tier_6",
      "npc_dota_boss_spiders",
    },
    {
      "npc_dota_boss_simple_1_tier5", -- Geostrike
      "npc_dota_boss_simple_5_tier5", -- Great Cleave
      "npc_dota_boss_twin_tier5",
      "npc_dota_boss_simple_2_tier5", -- Fury Swipes
      --"npc_dota_boss_charger_tier5",
      "npc_dota_creature_ogre_tank_boss_tier5",
      "npc_dota_creature_lycan_boss_tier5",
      "npc_dota_creature_temple_guardian_spawner_tier5",
      "npc_dota_boss_stopfightingyourself_tier5"
    }
  },
  -----------------------------
  ---- TIER 3
  -----------------------------
  {
    {
      "npc_dota_creature_ogre_tank_boss",
      "npc_dota_creature_lycan_boss",
      "npc_dota_creature_magma_boss",
      "npc_dota_creature_dire_tower_boss",
    },
    {
      --"npc_dota_boss_tier_4",
      "npc_dota_creature_spider_boss",
      "npc_dota_creature_temple_guardian_spawner",
      "npc_dota_boss_stopfightingyourself",
      "npc_dota_boss_tier_6",
      "npc_dota_boss_spiders",
    },
    {
      "npc_dota_boss_simple_1_tier5", -- Geostrike
      "npc_dota_boss_simple_5_tier5", -- Great Cleave
      "npc_dota_boss_twin_tier5",
      "npc_dota_boss_simple_2_tier5", -- Fury Swipes
      --"npc_dota_boss_charger_tier5",
      "npc_dota_creature_ogre_tank_boss_tier5",
      "npc_dota_creature_lycan_boss_tier5",
      "npc_dota_creature_temple_guardian_spawner_tier5",
      "npc_dota_boss_stopfightingyourself_tier5"
    }
  },
  -----------------------------
  ---- TIER 3 10v10 ONLY
  -----------------------------
  {
    {
      "npc_dota_creature_ogre_tank_boss",
      "npc_dota_creature_lycan_boss",
      "npc_dota_creature_magma_boss",
      "npc_dota_creature_dire_tower_boss",
    },
    {
      "npc_dota_boss_tier_4",
      "npc_dota_creature_spider_boss",
      "npc_dota_creature_temple_guardian_spawner",
      "npc_dota_boss_stopfightingyourself",
      "npc_dota_boss_tier_6",
      "npc_dota_boss_spiders",
    },
    {
      "npc_dota_boss_simple_1_tier5", -- Geostrike
      "npc_dota_boss_simple_5_tier5", -- Great Cleave
      "npc_dota_boss_twin_tier5",
      "npc_dota_boss_shielder_tier5",
      "npc_dota_boss_simple_2_tier5", -- Fury Swipes
      "npc_dota_boss_charger_tier5",
      "npc_dota_creature_ogre_tank_boss_tier5",
      "npc_dota_creature_lycan_boss_tier5",
      "npc_dota_creature_temple_guardian_spawner_tier5",
      "npc_dota_boss_stopfightingyourself_tier5"
    }
  },
  -----------------------------
  ---- TIER 3 10v10 ONLY
  -----------------------------
  {
    {
      "npc_dota_creature_ogre_tank_boss",
      "npc_dota_creature_lycan_boss",
      "npc_dota_creature_magma_boss",
      "npc_dota_creature_dire_tower_boss",
    },
    {
      "npc_dota_boss_tier_4",
      "npc_dota_creature_spider_boss",
      "npc_dota_creature_temple_guardian_spawner",
      "npc_dota_boss_stopfightingyourself",
      "npc_dota_boss_tier_6",
      "npc_dota_boss_spiders",
    },
    {
      "npc_dota_boss_simple_1_tier5", -- Geostrike
      "npc_dota_boss_simple_5_tier5", -- Great Cleave
      "npc_dota_boss_twin_tier5",
      "npc_dota_boss_shielder_tier5",
      "npc_dota_boss_simple_2_tier5", -- Fury Swipes
      "npc_dota_boss_charger_tier5",
      "npc_dota_creature_ogre_tank_boss_tier5",
      "npc_dota_creature_lycan_boss_tier5",
      "npc_dota_creature_temple_guardian_spawner_tier5",
      "npc_dota_boss_stopfightingyourself_tier5"
    }
  },
}
