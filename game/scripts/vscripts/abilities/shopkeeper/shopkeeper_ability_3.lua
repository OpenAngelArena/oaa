LinkLuaModifier("modifier_shopkeeper_ability_3_debuff", "abilities/shopkeeper/shopkeeper_ability_3", LUA_MODIFIER_MOTION_NONE)

shopkeeper_ability_3 = class({})

function shopkeeper_ability_3:Precache(context)
    PrecacheResource("particle", "particles/units/heroes/hero_monkey_king/monkey_king_disguise.vpcf", context)
    PrecacheResource("model", "models/props_gameplay/aghanim_scepter.vmdl", context)
    PrecacheResource("model", "models/props_gameplay/boots_of_speed.vmdl", context)
    PrecacheResource("model", "models/props_gameplay/bottle_blue.vmdl", context)
    PrecacheResource("model", "models/props_gameplay/bottle_empty.vmdl", context)
    PrecacheResource("model", "models/props_gameplay/branch.vmdl", context)
    PrecacheResource("model", "models/props_gameplay/clarity.vmdl", context)
    PrecacheResource("model", "models/props_gameplay/gem01.vmdl", context)
    PrecacheResource("model", "models/props_gameplay/mango.vmdl", context)
    PrecacheResource("model", "models/props_gameplay/magic_wand.vmdl", context)
    PrecacheResource("model", "models/props_gameplay/quelling_blade.vmdl", context)
    PrecacheResource("model", "models/props_gameplay/recipe.vmdl", context)
    PrecacheResource("model", "models/props_gameplay/refresher_shard.vmdl", context)
    PrecacheResource("model", "models/props_gameplay/salve.vmdl", context)
    PrecacheResource("model", "models/props_gameplay/smoke.vmdl", context)
    PrecacheResource("model", "models/heroes/shopkeeper/itemmodels/item_1.vmdl", context)
    PrecacheResource("model", "models/heroes/shopkeeper/itemmodels/item_2.vmdl", context)
    PrecacheResource("model", "models/heroes/shopkeeper/itemmodels/item_3.vmdl", context)
    PrecacheResource("model", "models/heroes/shopkeeper/itemmodels/item_4.vmdl", context)
    PrecacheResource("model", "models/heroes/shopkeeper/itemmodels/item_5.vmdl", context)
    PrecacheResource("model", "models/heroes/shopkeeper/itemmodels/item_6.vmdl", context)
    PrecacheResource("model", "models/heroes/shopkeeper/itemmodels/item_7.vmdl", context)
    PrecacheResource("model", "models/heroes/shopkeeper/itemmodels/item_8.vmdl", context)
    PrecacheResource("model", "models/heroes/shopkeeper/itemmodels/item_9.vmdl", context)
    PrecacheResource("model", "models/heroes/shopkeeper/itemmodels/item_10.vmdl", context)
    PrecacheResource("model", "models/heroes/shopkeeper/itemmodels/item_11.vmdl", context)
    PrecacheResource("model", "models/heroes/shopkeeper/itemmodels/item_12.vmdl", context)
    PrecacheResource("model", "models/heroes/shopkeeper/itemmodels/item_13.vmdl", context)
    PrecacheResource("model", "models/heroes/shopkeeper/itemmodels/item_14.vmdl", context)
    PrecacheResource("model", "models/heroes/shopkeeper/itemmodels/item_15.vmdl", context)
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_monkey_king.vsndevts", context)
    PrecacheResource("particle", "particles/hero/shopkeeper/amir4an/amir4anmods_shopkeeper_hex_ground_pre_cast.vpcf", context)
    PrecacheResource("particle", "particles/hero/shopkeeper/amir4an/amir4anmods_shopkeeper_hex_ground.vpcf", context)
    PrecacheResource("particle", "particles/hero/shopkeeper/amir4an/amir4anmods_shopkeeper_hex_target.vpcf", context)
end

function shopkeeper_ability_3:OnAbilityPhaseStart()
    local radius = self:GetSpecialValueFor("radius")
    self.pre_particle = ParticleManager:CreateParticle("particles/hero/shopkeeper/amir4an/amir4anmods_shopkeeper_hex_ground_pre_cast.vpcf", PATTACH_WORLDORIGIN, self:GetCaster())
    ParticleManager:SetParticleControl(self.pre_particle, 0, self:GetCaster():GetAbsOrigin())
    ParticleManager:SetParticleControl(self.pre_particle, 2, Vector(radius, 0, 0))
    self:GetCaster():EmitSound("ShopKeeper.Hero_sound_1")
    return true
end

function shopkeeper_ability_3:OnAbilityPhaseInterrupted()
    if self.pre_particle then
        ParticleManager:DestroyParticle(self.pre_particle, true)
    end
    self:GetCaster():StopSound("ShopKeeper.Hero_sound_1")
end

function shopkeeper_ability_3:OnSpellStart()
    if not IsServer() then return end
    if self.pre_particle then
        ParticleManager:DestroyParticle(self.pre_particle, false)
    end
    self.model_list = 
    {
       "models/heroes/shopkeeper/itemmodels/item_1.vmdl",
       "models/heroes/shopkeeper/itemmodels/item_2.vmdl",
       "models/heroes/shopkeeper/itemmodels/item_3.vmdl",
       "models/heroes/shopkeeper/itemmodels/item_4.vmdl",
       "models/heroes/shopkeeper/itemmodels/item_5.vmdl",
       "models/heroes/shopkeeper/itemmodels/item_6.vmdl",
       "models/heroes/shopkeeper/itemmodels/item_7.vmdl",
       "models/heroes/shopkeeper/itemmodels/item_8.vmdl",
       "models/heroes/shopkeeper/itemmodels/item_9.vmdl",
       "models/heroes/shopkeeper/itemmodels/item_10.vmdl",
       "models/heroes/shopkeeper/itemmodels/item_11.vmdl",
       "models/heroes/shopkeeper/itemmodels/item_12.vmdl",
       "models/heroes/shopkeeper/itemmodels/item_13.vmdl",
       "models/heroes/shopkeeper/itemmodels/item_14.vmdl",
       "models/heroes/shopkeeper/itemmodels/item_15.vmdl",
    }
    local radius = self:GetSpecialValueFor("radius")
    local duration = self:GetSpecialValueFor("duration")

    local fx = ParticleManager:CreateParticle("particles/hero/shopkeeper/amir4an/amir4anmods_shopkeeper_hex_ground.vpcf", PATTACH_WORLDORIGIN, self:GetCaster())
    ParticleManager:SetParticleControl(fx, 0, self:GetCaster():GetAbsOrigin())
    ParticleManager:SetParticleControl(fx, 2, Vector(radius, 0, 0))
    ParticleManager:ReleaseParticleIndex(fx)

    local damage = self:GetSpecialValueFor("damage")

    local units = FindUnitsInRadius( self:GetCaster():GetTeamNumber(), self:GetCaster():GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
    for _, unit in pairs(units) do
        if unit ~= self:GetCaster() then
            if unit:IsHero() then
                local buff_duration = duration
                if unit:GetTeamNumber() ~= self:GetCaster():GetTeamNumber() then
                    buff_duration = buff_duration * (1-unit:GetStatusResistance())
                end
                if unit:IsIllusion() and not unit:IsStrongIllusion() then
                    unit:Kill(self, self:GetCaster())
                else
                    unit:RemoveModifierByName("modifier_shopkeeper_ability_3_debuff")
                    unit:AddNewModifier(self:GetCaster(), self, "modifier_shopkeeper_ability_3_debuff", {duration = buff_duration})
                end
            elseif unit:GetTeamNumber() ~= self:GetCaster():GetTeamNumber() then
                ApplyDamage({ attacker = self:GetCaster(), victim = unit, ability = self, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL })
                local particle = ParticleManager:CreateParticle("particles/hero/shopkeeper/amir4an/amir4anmods_shopkeeper_hex_target_flares_start.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit)
                ParticleManager:SetParticleControl(particle, 0, unit:GetAbsOrigin())
                ParticleManager:SetParticleControl(particle, 1, Vector(100, 0, 100))
                ParticleManager:SetParticleControl(particle, 27, Vector(0, 174, 255))
                ParticleManager:ReleaseParticleIndex(particle)
            end
        end
    end
end

modifier_shopkeeper_ability_3_debuff = class({})
function modifier_shopkeeper_ability_3_debuff:IsPurgable() return false end
function modifier_shopkeeper_ability_3_debuff:IsPurgeException() return false end
function modifier_shopkeeper_ability_3_debuff:OnCreated()
    if not IsServer() then return end
    if #self:GetAbility().model_list <= 0 then
        table.insert(self:GetAbility().model_list, "models/props_gameplay/aghanim_scepter.vmdl")
        table.insert(self:GetAbility().model_list, "models/props_gameplay/boots_of_speed.vmdl")
        table.insert(self:GetAbility().model_list, "models/props_gameplay/bottle_blue.vmdl")
        table.insert(self:GetAbility().model_list, "models/props_gameplay/branch.vmdl")
        table.insert(self:GetAbility().model_list, "models/props_gameplay/clarity.vmdl")
        table.insert(self:GetAbility().model_list, "models/props_gameplay/gem01.vmdl")
    end
    self.damage = self:GetAbility():GetSpecialValueFor("damage")
    self.model = table.remove(self:GetAbility().model_list, RandomInt(1, #self:GetAbility().model_list))
    Timers:CreateTimer(FrameTime(), function()
        local particle = ParticleManager:CreateParticle("particles/hero/shopkeeper/amir4an/amir4anmods_shopkeeper_hex_target.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, self:GetParent())
        ParticleManager:SetParticleControlEnt(particle, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
        ParticleManager:SetParticleControl(particle, 1, Vector(150, 0, 0))
        self:AddParticle(particle, false, false, -1, false, false)
    end)
    self:GetCaster():EmitSound("Hero_MonkeyKing.Transform.On")
    local children = self:GetParent():GetChildren();
    for k,child in pairs(children) do
        if child:GetClassname() == "dota_item_wearable" then
            child:AddEffects(EF_NODRAW);
        end
    end
end

function modifier_shopkeeper_ability_3_debuff:OnDestroy()
    if not IsServer() then return end
    local particle = ParticleManager:CreateParticle("particles/hero/shopkeeper/amir4an/amir4anmods_shopkeeper_hex_target_flares_start.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    ParticleManager:SetParticleControl(particle, 0, self:GetParent():GetAbsOrigin())
    ParticleManager:SetParticleControl(particle, 1, Vector(100, 0, 100))
    ParticleManager:SetParticleControl(particle, 27, Vector(0, 174, 255))
    ParticleManager:ReleaseParticleIndex(particle)
    self:GetCaster():EmitSound("Hero_MonkeyKing.Transform.Off")
    local children = self:GetParent():GetChildren();
    for k,child in pairs(children) do
        if child:GetClassname() == "dota_item_wearable" then
            child:RemoveEffects(EF_NODRAW);
        end
    end
    if self:GetParent():GetTeamNumber() ~= self:GetCaster():GetTeamNumber() then
        ApplyDamage({ attacker = self:GetCaster(), victim = self:GetParent(), ability = self:GetAbility(), damage = self.damage, damage_type = DAMAGE_TYPE_MAGICAL })
    end
end

function modifier_shopkeeper_ability_3_debuff:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_MODEL_CHANGE,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
    }
end

function modifier_shopkeeper_ability_3_debuff:GetAbsoluteNoDamagePhysical()
    if self:GetParent():IsDebuffImmune() then return end
    return 1
end

function modifier_shopkeeper_ability_3_debuff:GetAbsoluteNoDamageMagical()
    if self:GetParent():IsDebuffImmune() then return end
    return 1
end

function modifier_shopkeeper_ability_3_debuff:GetAbsoluteNoDamagePure()
    if self:GetParent():IsDebuffImmune() then return end
    return 1
end

function modifier_shopkeeper_ability_3_debuff:GetModifierModelChange()
    if self:GetParent():IsDebuffImmune() then
        print(self:GetParent():GetModelName())
        return self:GetParent():GetModelName()
    end
    return self.model
end

function modifier_shopkeeper_ability_3_debuff:CheckState()
    if self:GetParent():IsDebuffImmune() then return end
    return
    {
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_ROOTED] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_UNTARGETABLE] = true,
        --[MODIFIER_STATE_INVULNERABLE] = true,
    }
end