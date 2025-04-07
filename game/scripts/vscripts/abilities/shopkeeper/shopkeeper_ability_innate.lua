LinkLuaModifier("modifier_shopkeeper_ability_innate", "abilities/shopkeeper/shopkeeper_ability_innate", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_shopkeeper_ability_innate_shop_buff", "abilities/shopkeeper/shopkeeper_ability_innate", LUA_MODIFIER_MOTION_NONE)

shopkeeper_ability_innate = class({})

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

modifier_shopkeeper_ability_innate = class({})
function modifier_shopkeeper_ability_innate:IsHidden() return true end
function modifier_shopkeeper_ability_innate:IsPurgable() return false end
function modifier_shopkeeper_ability_innate:IsPurgeException() return false end
function modifier_shopkeeper_ability_innate:RemoveOnDeath() return false end
function modifier_shopkeeper_ability_innate:OnCreated()
    self.gold_distance = self:GetAbility():GetSpecialValueFor("gold_distance")
    self.distance_damage = self:GetAbility():GetSpecialValueFor("distance_damage")
    self.distance = self:GetAbility():GetSpecialValueFor("distance")
    if not IsServer() then return end
    self.ranged_attacks = {}
    self.timer = 0
    self.gold_timer = self:GetAbility():GetSpecialValueFor("gold_timer")
    self:StartIntervalThink(FrameTime())

    local particle = ParticleManager:CreateParticle("particles/hero/shopkeeper/amir4an/amir4anmods_shopkeeper_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    self:AddParticle(particle, false, false, -1, false, false)
end

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

function modifier_shopkeeper_ability_innate:OnIntervalThink()
    if not IsServer() then return end
    self.gold_distance = self:GetAbility():GetSpecialValueFor("gold_distance")
    self.distance_damage = self:GetAbility():GetSpecialValueFor("distance_damage")
    if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
        if not self:GetParent():IsIllusion() then
            self.timer = self.timer + FrameTime()
            if self.timer >= self.gold_timer then
                self:GetParent():ModifyGoldFiltered(130, false, DOTA_ModifyGold_Unspecified)
                self.timer = 0
            end
        end
    end
    local stack_counter = 0
    if self:GetParent():GetAggroTarget() then
        local base_attack_range = self:GetParent():GetBaseAttackRange() + 75
        local distance = (self:GetParent():GetAggroTarget():GetAbsOrigin() - self:GetParent():GetAbsOrigin()):Length2D()
        if distance > base_attack_range then
            stack_counter = 1
        end
        if self:GetStackCount() ~= stack_counter then
            self:SetStackCount(stack_counter)
        end
    end
end

function modifier_shopkeeper_ability_innate:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
        MODIFIER_EVENT_ON_ATTACK,
        MODIFIER_EVENT_ON_ATTACK_START,
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_EVENT_ON_ATTACK_RECORD,
        MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_MAGICAL,
        MODIFIER_PROPERTY_PROJECTILE_NAME,
        MODIFIER_EVENT_ON_ATTACK_CANCELLED,
        MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
        MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS,
    }
end

function modifier_shopkeeper_ability_innate:GetModifierProjectileSpeedBonus()
    if self:GetStackCount() == 0 then
	    return 5000
    end
end

function modifier_shopkeeper_ability_innate:GetActivityTranslationModifiers()
    if self:GetStackCount() == 0 then
        return "melee_attack"
    end
    return "range_attack"
end

function modifier_shopkeeper_ability_innate:OnAttack(params)
    if self:GetParent() ~= params.attacker then return end
    if self:GetParent():IsIllusion() then return end
    local base_attack_range = self:GetParent():GetBaseAttackRange() + 75
    local distance = (params.target:GetAbsOrigin() - params.attacker:GetAbsOrigin()):Length2D()
    -- distance <= base_attack_range or self:GetParent():GetGold() < self.gold_distance
    if not self.ranged_attacks[params.record] then
        self:GetParent():EmitSound("Hero_Brewmaster.Attack")
    else
        if self.gold_distance > 0 then
            self:GetParent():ModifyGold(-self.gold_distance, false, 0)
            local particle = ParticleManager:CreateParticle("particles/shopkeeper_attacks.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
            ParticleManager:SetParticleControl(particle, 1, Vector(1, math.abs(self.gold_distance), 0))
		    ParticleManager:SetParticleControl(particle, 2, Vector(2, string.len(math.abs(self.gold_distance)) + 1, 0))
            ParticleManager:ReleaseParticleIndex(particle)
        end
        self:GetParent():EmitSound("Hero_Invoker.Attack")
    end
end

function modifier_shopkeeper_ability_innate:OnAttackCancelled(params)
    if params.attacker ~= self:GetParent() then return end
    self:GetParent():StopSound("Hero_Invoker.PreAttack")
    self:GetParent():StopSound("Hero_Brewmaster.PreAttack")
end

function modifier_shopkeeper_ability_innate:OnAttackStart(params)
    if params.attacker ~= self:GetParent() then return end
    local base_attack_range = self:GetParent():GetBaseAttackRange() + 75
    local distance = (params.target:GetAbsOrigin() - self:GetParent():GetAbsOrigin()):Length2D()
    local stack_count = 1
    if distance <= base_attack_range then
        stack_count = 0
    end
    if self:GetParent():GetGold() < self.gold_distance then
        stack_count = 0
    end
    if self:GetStackCount() ~= stack_count then
        self:SetStackCount(stack_count)
    end
end

function modifier_shopkeeper_ability_innate:OnAttackRecord(params)
    if params.attacker ~= self:GetParent() then return end
    local base_attack_range = self:GetParent():GetBaseAttackRange() + 75
    local distance = (params.target:GetAbsOrigin() - self:GetParent():GetAbsOrigin()):Length2D()
    local stack_count = 1
    if distance <= base_attack_range then
        stack_count = 0
    end
    if self:GetParent():GetGold() < self.gold_distance then
        stack_count = 0
    end
    if self:GetStackCount() ~= stack_count then
        self:SetStackCount(stack_count)
    end
    if self:GetStackCount() == 0 then
        self:GetParent():StopSound("Hero_Brewmaster.PreAttack")
        self:GetParent():EmitSound("Hero_Brewmaster.PreAttack")
    else
        self:GetParent():StopSound("Hero_Invoker.PreAttack")
        self:GetParent():EmitSound("Hero_Invoker.PreAttack")
        self.ranged_attacks[params.record] = true
    end
end

function modifier_shopkeeper_ability_innate:OnAttackLanded(params)
    if params.attacker ~= self:GetParent() then return end
    if self.ranged_attacks[params.record] then
        params.target:EmitSound("Hero_Invoker.ProjectileImpact")
        params.target:EmitSound("ShopKeeper.Hero_sound_15")
    end
end

function modifier_shopkeeper_ability_innate:GetModifierProcAttack_BonusDamage_Magical(params)
    if params.attacker ~= self:GetParent() then return end
    if not self.ranged_attacks[params.record] then return end
    return self.distance_damage
end

function modifier_shopkeeper_ability_innate:GetModifierAttackRangeBonus()
    return self:GetStackCount() * self.distance
end

function modifier_shopkeeper_ability_innate:GetModifierProjectileName()
    if self:GetStackCount() == 1 then
        return "particles/hero/shopkeeper/amir4an/amir4anmods_shopkeeper_base_attack.vpcf"
    end
end

modifier_shopkeeper_ability_innate_shop_buff = class({})
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
        local distance = (self:GetParent():GetAbsOrigin() - self.trigger:GetAbsOrigin()):Length2D()
    end
    self:StartIntervalThink(FrameTime())
end

function modifier_shopkeeper_ability_innate_shop_buff:OnDestroy()
    if self.trigger and not self.trigger:IsNull() then
        UTIL_Remove(self.trigger)
        self.trigger = nil
    end
end