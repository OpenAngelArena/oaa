LinkLuaModifier("modifier_shopkeeper_ability_innate", "abilities/shopkeeper/shopkeeper_ability_innate", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_shopkeeper_ability_innate_shop_buff", "abilities/shopkeeper/shopkeeper_ability_innate", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_shopkeeper_warranty_aura", "abilities/shopkeeper/shopkeeper_ability_innate", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_shopkeeper_warranty", "abilities/shopkeeper/shopkeeper_ability_innate", LUA_MODIFIER_MOTION_NONE)

shopkeeper_ability_innate = class(AbilityBaseClass)

function shopkeeper_ability_innate:Precache(context)
    PrecacheResource("particle", "particles/blink/blink_dagger_end.vpcf", context)
    PrecacheResource("particle", "particles/items2_fx/aegis.vpcf", context)
    PrecacheResource("particle", "particles/items3_fx/blink_arcane_start.vpcf", context)
    PrecacheResource("particle", "particles/items3_fx/blink_arcane_end.vpcf", context)
    PrecacheResource("particle", "particles/units/heroes/hero_sniper/concussive_grenade_disarm.vpcf", context)
    PrecacheResource("particle", "particles/items2_fx/radiance.vpcf", context)
    PrecacheResource("particle", "particles/items2_fx/radiance_owner.vpcf", context)
    PrecacheResource("particle", "particles/econ/events/ti9/cyclone_ti9.vpcf", context)
    PrecacheResource("particle", "particles/items2_fx/aegis.vpcf", context)
    PrecacheResource("particle", "particles/shopkeeper_attacks.vpcf", context)
    PrecacheResource("particle", "particles/units/heroes/hero_enigma/enigma_black_hole_scepter_pull_debuff.vpcf", context)
    PrecacheResource("particle", "particles/shopkeeper_ui.vpcf", context)
    PrecacheResource("particle", "particles/shopkeeper_base_attack.vpcf", context)
    PrecacheResource("particle", "particles/hero/shopkeeper/amir4an/amir4anmods_shopkeeper_teleport.vpcf", context)
    PrecacheResource("particle", "particles/hero/shopkeeper/amir4an/amir4anmods_shopkeeper_cyclone.vpcf", context)
    PrecacheResource("particle", "particles/neutral_fx/roshan_roar.vpcf", context)
    PrecacheResource("particle", "particles/shopkeeper_roar.vpcf", context)
    PrecacheResource("particle", "particles/units/heroes/hero_sniper/concussive_grenade_disarm.vpcf", context)
    PrecacheResource("particle", "particles/shopkeeper_debuff_overhead_aegis.vpcf", context)
    PrecacheResource("particle", "particles/econ/events/fall_2021/blink_dagger_fall_2021_end_lvl2.vpcf", context)
    PrecacheResource("particle", "particles/econ/events/fall_2021/blink_dagger_fall_2021_start_lvl2.vpcf", context)
    PrecacheResource("particle", "particles/hero/shopkeeper/amir4an/amir4anmods_shopkeeper_octarine_overhead.vpcf", context)
    PrecacheResource("particle", "particles/hero/shopkeeper/amir4an/amir4anmods_shopkeeper_octarine.vpcf", context)
    PrecacheResource("particle", "particles/shopkeeper_ambient_cheese.vpcf", context)
    PrecacheResource("particle", "particles/econ/events/fall_2021/radiance_fall_2021.vpcf", context)
    PrecacheResource("particle", "particles/econ/events/fall_2021/radiance_owner_fall_2021.vpcf", context)
    PrecacheResource("particle", "particles/items_fx/generic_item_spell_caster.vpcf", context)
    PrecacheResource("particle", "particles/items_fx/item_sheepstick.vpcf", context)
    PrecacheResource("particle", "particles/hero/shopkeeper/amir4an/amir4anmods_shopkeeper_base_attack.vpcf", context)
    PrecacheResource("particle", "particles/units/heroes/hero_rubick/rubick_telekinesis.vpcf", context)
    PrecacheResource("particle", "particles/units/heroes/hero_rubick/rubick_telekinesis_land.vpcf", context)
    PrecacheResource("particle", "particles/hero/shopkeeper/amir4an/amir4anmods_shopkeeper_hex_status_effect.vpcf", context)
    PrecacheResource("particle", "particles/items_fx/aegis_respawn.vpcf", context)
    PrecacheResource("particle", "particles/items_fx/aegis_timer.vpcf", context)
    PrecacheResource("particle", "particles/force_staff_custom_ambient.vpcf", context)
    PrecacheResource("particle", "particles/force_staff_amb_ground.vpcf", context)
    PrecacheResource("particle", "particles/force_staff_custom_end.vpcf", context)
    PrecacheResource("particle", "models/heroes/shopkeeper/particles/cracker/cracker_idle_compos.vpcf", context)
    PrecacheResource("particle", "particles/hero/shopkeeper/amir4an/amir4anmods_shopkeeper_ambient.vpcf", context)

    PrecacheResource("soundfile", "soundevents/game_sounds_custom.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_invoker.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_brewmaster.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_rubick.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_primal_beast.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_necrolyte.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_monkey_king.vsndevts", context)

    PrecacheResource("model", "models/props_gameplay/pumpkin_rune.vmdl", context)
    PrecacheResource("model", "models/props_gameplay/rune_arcane.vmdl", context)
    PrecacheResource("model", "models/props_gameplay/rune_doubledamage01.vmdl", context)
    PrecacheResource("model", "models/props_gameplay/rune_goldxp.vmdl", context)
    PrecacheResource("model", "models/props_gameplay/rune_haste01.vmdl", context)
    PrecacheResource("model", "models/props_gameplay/rune_illusion01.vmdl", context)
    PrecacheResource("model", "models/props_gameplay/rune_invisibility01.vmdl", context)
    PrecacheResource("model", "models/props_gameplay/rune_point001.vmdl", context)
    PrecacheResource("model", "models/props_gameplay/rune_regeneration01.vmdl", context)
    PrecacheResource("model", "models/props_gameplay/rune_shield01.vmdl", context)
    PrecacheResource("model", "models/props_gameplay/rune_water.vmdl", context)
    PrecacheResource("model", "models/props_gameplay/rune_xp.vmdl", context)
    PrecacheResource("model", "models/creeps/mega_greevil/mega_greevil.vmdl", context)
    PrecacheResource("model", "models/props_gameplay/aegis.vmdl", context)
end

function shopkeeper_ability_innate:GetIntrinsicModifierName()
    return "modifier_shopkeeper_ability_innate"
end

modifier_shopkeeper_ability_innate = class(ModifierBaseClass)
function modifier_shopkeeper_ability_innate:IsHidden() return true end
function modifier_shopkeeper_ability_innate:IsPurgable() return false end
function modifier_shopkeeper_ability_innate:IsPurgeException() return false end
function modifier_shopkeeper_ability_innate:RemoveOnDeath() return false end
function modifier_shopkeeper_ability_innate:OnCreated()
    if not IsServer() then return end
    local parent = self:GetParent()

    local particle = ParticleManager:CreateParticle("particles/hero/shopkeeper/amir4an/amir4anmods_shopkeeper_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    self:AddParticle(particle, false, false, -1, false, false)

    -- Warranty is a second aura, so it runs on its own modifier (one modifier can only be one aura)
    if not parent:IsIllusion() then
        parent:AddNewModifier(parent, self:GetAbility(), "modifier_shopkeeper_warranty_aura", {})
    end
end

-- Shop aura: heroes next to Shopkeeper can buy from him
function modifier_shopkeeper_ability_innate:IsAura()
    if self:GetParent():IsIllusion() then return end
    return true
end

function modifier_shopkeeper_ability_innate:GetModifierAura()
    return "modifier_shopkeeper_ability_innate_shop_buff"
end

function modifier_shopkeeper_ability_innate:GetAuraRadius()
    return 300
end

function modifier_shopkeeper_ability_innate:IsAuraActiveOnDeath()
    return false
end

function modifier_shopkeeper_ability_innate:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_BOTH
end

function modifier_shopkeeper_ability_innate:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO
end

function modifier_shopkeeper_ability_innate:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

---------------------------------------------------------------------------------------------------
-- Warranty: allied heroes near Shopkeeper get Item Potency (7.42 attack potency)

modifier_shopkeeper_warranty_aura = class(ModifierBaseClass)

function modifier_shopkeeper_warranty_aura:IsHidden() return true end
function modifier_shopkeeper_warranty_aura:IsPurgable() return false end
function modifier_shopkeeper_warranty_aura:RemoveOnDeath() return false end
function modifier_shopkeeper_warranty_aura:IsAura() return true end
function modifier_shopkeeper_warranty_aura:IsAuraActiveOnDeath() return false end

function modifier_shopkeeper_warranty_aura:GetModifierAura()
    return "modifier_shopkeeper_warranty"
end

function modifier_shopkeeper_warranty_aura:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("warranty_radius")
end

function modifier_shopkeeper_warranty_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_shopkeeper_warranty_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO
end

modifier_shopkeeper_warranty = class(ModifierBaseClass)

function modifier_shopkeeper_warranty:IsHidden() return false end
function modifier_shopkeeper_warranty:IsDebuff() return false end
function modifier_shopkeeper_warranty:IsPurgable() return false end

function modifier_shopkeeper_warranty:GetTexture()
    return "alchemist_goblins_greed"
end

function modifier_shopkeeper_warranty:OnCreated()
    local ability = self:GetAbility()
    self.potency = ability and not ability:IsNull() and ability:GetSpecialValueFor("warranty_potency") or 0
end

function modifier_shopkeeper_warranty:OnRefresh()
    self:OnCreated()
end

function modifier_shopkeeper_warranty:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACK_POTENCY, -- 7.42; untested: confirm in game that potency-flagged items get stronger
        MODIFIER_PROPERTY_TOOLTIP,
    }
end

function modifier_shopkeeper_warranty:GetModifierPropertyAttackPotency()
    return self.potency
end

function modifier_shopkeeper_warranty:OnTooltip()
    return self.potency
end

modifier_shopkeeper_ability_innate_shop_buff = class(ModifierBaseClass)
function modifier_shopkeeper_ability_innate_shop_buff:IsPurgable() return false end
function modifier_shopkeeper_ability_innate_shop_buff:IsPurgeException() return false end
function modifier_shopkeeper_ability_innate_shop_buff:IsHidden() return true end

function modifier_shopkeeper_ability_innate_shop_buff:OnCreated()
    if not IsServer() then return end
    self:StartIntervalThink(1)
end

function modifier_shopkeeper_ability_innate_shop_buff:ReCreateStore()
    local store_type = DOTA_SHOP_SECRET
    if self:GetCaster():GetHeroFacetID() == 2 then
        store_type = DOTA_SHOP_HOME
    end
    local trigger = SpawnDOTAShopTriggerRadiusApproximate( self:GetParent():GetOrigin(), 200 )
    if trigger then
        trigger:SetShopType( store_type )
        self.trigger = trigger
    end
end

function modifier_shopkeeper_ability_innate_shop_buff:OnIntervalThink()
    if not IsServer() then return end
    local triggers = Entities:FindAllByClassnameWithin("trigger_shop", self:GetParent():GetAbsOrigin(), 150)
    local delete_trigger = false
    for i=#triggers, 1, -1 do
        if triggers[i] ~= self.trigger then
            delete_trigger = true
        end
    end
    if delete_trigger then
        if self.trigger and not self.trigger:IsNull() then
            UTIL_Remove(self.trigger)
            self.trigger = nil
        end
    else
        if not self.trigger then
            self:ReCreateStore()
            self:StartIntervalThink(1)
        end
    end
    if self.trigger and not self.trigger:IsNull() then
        self.trigger:SetAbsOrigin(self:GetParent():GetAbsOrigin())
    end
    self:StartIntervalThink(FrameTime())
end

function modifier_shopkeeper_ability_innate_shop_buff:OnDestroy()
    if self.trigger and not self.trigger:IsNull() then
        UTIL_Remove(self.trigger)
        self.trigger = nil
    end
end