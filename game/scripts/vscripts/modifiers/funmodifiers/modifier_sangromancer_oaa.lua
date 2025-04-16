modifier_sangromancer_oaa = class(ModifierBaseClass)

function modifier_sangromancer_oaa:IsHidden()
  return true
end

function modifier_sangromancer_oaa:IsDebuff()
  return false
end

function modifier_sangromancer_oaa:IsPurgable()
  return false
end

function modifier_sangromancer_oaa:RemoveOnDeath()
  return false
end

function modifier_sangromancer_oaa:OnCreated()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  local bad_blood_magic_heroes = {
    "npc_dota_hero_ancient_apparition",
    "npc_dota_hero_clinkz",
    "npc_dota_hero_drow_ranger",
    "npc_dota_hero_electrician",
    "npc_dota_hero_enchantress",
    "npc_dota_hero_huskar",
    "npc_dota_hero_keeper_of_the_light",
    "npc_dota_hero_leshrac",
    "npc_dota_hero_medusa",
    "npc_dota_hero_morphling",
    "npc_dota_hero_obsidian_destroyer",
    "npc_dota_hero_shredder",
    "npc_dota_hero_silencer",
    "npc_dota_hero_storm_spirit",
    "npc_dota_hero_tusk",
    "npc_dota_hero_viper",
    "npc_dota_hero_winter_wyvern",
    "npc_dota_hero_witch_doctor",
  }

  -- Huskar doesnt benefit from either
  if parent:GetUnitName() == "npc_dota_hero_huskar" then
    -- Add health per INT modifier instead
    if not parent:HasModifier("modifier_bad_design_2_oaa") then
      parent:AddNewModifier(parent, nil, "modifier_bad_design_2_oaa", {})
    end
    return
  end

  for _, v in pairs(bad_blood_magic_heroes) do
    if parent:GetUnitName() == v then
      -- Add Moriah's Shield instead
      if not parent:HasModifier("modifier_hp_mana_switch_oaa") then
        parent:AddNewModifier(parent, nil, "modifier_hp_mana_switch_oaa", {})
      end
      return
    end
  end

  -- Add Blood Magic
  if not parent:HasModifier("modifier_blood_magic_oaa") then
    parent:AddNewModifier(parent, nil, "modifier_blood_magic_oaa", {})
  end
end

-- function modifier_sangromancer_oaa:GetTexture()
  -- return "generic_hidden"
-- end
