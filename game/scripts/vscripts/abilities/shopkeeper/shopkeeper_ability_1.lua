LinkLuaModifier("modifier_shopkeeper_ability_1_debuff", "abilities/shopkeeper/shopkeeper_ability_1", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_shopkeeper_ability_1_buff", "abilities/shopkeeper/shopkeeper_ability_1", LUA_MODIFIER_MOTION_NONE)

shopkeeper_ability_1 = class({})

function shopkeeper_ability_1:Precache(context)
    PrecacheResource("particle", "particles/hero/shopkeeper/amir4an/amir4anmods_shopkeeper_salve_projectile.vpcf", context)
    PrecacheResource("particle", "particles/hero/shopkeeper/amir4an/amir4anmods_shopkeeper_salve_ground.vpcf", context)
    PrecacheResource("particle", "particles/items3_fx/fish_bones_active.vpcf", context)
    PrecacheResource("particle", "particles/econ/items/bristleback/ti7_head_nasal_goo/bristleback_ti7_crimson_nasal_goo_debuff.vpcf", context)
    PrecacheResource("particle", "particles/econ/items/sand_king/sandking_ti7_arms/sandking_ti7_caustic_finale_debuff.vpcf", context)
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_ogre_magi.vsndevts", context)
end

function shopkeeper_ability_1:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end
function shopkeeper_ability_1:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local point = self:GetCursorPosition()
    local attack_position = caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("attach_attack1"))

    if point == attack_position then
        point = attack_position + caster:GetForwardVector()
    end

    local projectile_speed = self:GetSpecialValueFor("projectile_speed")
    local direction = point - attack_position
    direction.z = 0
    local distance = direction:Length2D()
    direction = direction:Normalized()

    local current_team = DOTA_UNIT_TARGET_TEAM_FRIENDLY
    if self:GetAutoCastState() then
        current_team = DOTA_UNIT_TARGET_TEAM_ENEMY
        print("[shopkeeper_ability_1] Alt-casted (autocast ON): targeting enemies")
    else
        print("[shopkeeper_ability_1] Normal cast: targeting allies")
    end

    caster:EmitSound("ShopKeeper.Hero_sound_3")

    local flamebreak_particle = ParticleManager:CreateParticle("particles/hero/shopkeeper/amir4an/amir4anmods_shopkeeper_salve_projectile.vpcf", PATTACH_WORLDORIGIN, caster)
    ParticleManager:SetParticleControl(flamebreak_particle, 0, attack_position)
    ParticleManager:SetParticleControl(flamebreak_particle, 1, Vector(projectile_speed, projectile_speed, projectile_speed))
    ParticleManager:SetParticleControl(flamebreak_particle, 5, point)

    if current_team == DOTA_UNIT_TARGET_TEAM_ENEMY then
        ParticleManager:SetParticleControl(flamebreak_particle, 27, Vector(255, 0, 0))
        ParticleManager:SetParticleControl(flamebreak_particle, 28, Vector(1, 75, 0))
    end

    local info =
    {
        Source = caster,
        Ability = self,
        vSpawnOrigin = attack_position,
        bDeleteOnHit = true,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_NONE,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO,
        EffectName = "",
        fDistance = distance,
        fStartRadius = 0,
        fEndRadius = 0,
        vVelocity = direction * projectile_speed,
        bHasFrontalCone = false,
        bReplaceExisting = false,
        fExpireTime = GameRules:GetGameTime() + 10.0,
        ExtraData =
        {
            particle_fx = flamebreak_particle,
            current_team = current_team,
        }
    }

    ProjectileManager:CreateLinearProjectile(info)
end


function shopkeeper_ability_1:OnProjectileHit_ExtraData(htarget, vLocation, table)
    local duration = self:GetSpecialValueFor("duration")
    local damage = self:GetSpecialValueFor("damage")
    local heal = self:GetSpecialValueFor("heal")
    local radius = self:GetSpecialValueFor("radius")
    if table.particle_fx then
        ParticleManager:DestroyParticle(table.particle_fx, true)
    end
    vLocation = GetGroundPosition(vLocation, nil)

    local explosion_fx = ParticleManager:CreateParticle("particles/hero/shopkeeper/amir4an/amir4anmods_shopkeeper_salve_ground.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(explosion_fx, 0, vLocation)
	ParticleManager:SetParticleControl(explosion_fx, 2, Vector(radius, 0, 1))
    if table.current_team == DOTA_UNIT_TARGET_TEAM_ENEMY then
        ParticleManager:SetParticleControl(explosion_fx, 27, Vector(255, 0, 0))
        ParticleManager:SetParticleControl(explosion_fx, 28, Vector(1, 0, 0))
        EmitSoundOnLocationWithCaster(vLocation, "ShopKeeper.Hero_sound_5", self:GetCaster())
    else
        EmitSoundOnLocationWithCaster(vLocation, "ShopKeeper.Hero_sound_4", self:GetCaster())
    end

    local units = FindUnitsInRadius(self:GetCaster():GetTeamNumber(), vLocation, nil, radius, table.current_team, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false)
    for _, target in pairs(units) do
        if table.current_team ~= DOTA_UNIT_TARGET_TEAM_ENEMY then
            target:HealWithParams(heal, self, false, true, self:GetCaster(), false)
            target:AddNewModifier(self:GetCaster(), self, "modifier_shopkeeper_ability_1_buff", {duration = duration})
            SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, target, heal, self:GetCaster():GetPlayerOwner())
            local particle = ParticleManager:CreateParticle("particles/items3_fx/fish_bones_active.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
            ParticleManager:ReleaseParticleIndex(particle)
        else
            local damage_flags = DOTA_DAMAGE_FLAG_NONE
            if target:GetTeamNumber() == self:GetCaster():GetTeamNumber() then
                damage_flags = DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NON_LETHAL
            end
            ApplyDamage({attacker = self:GetCaster(), victim = target, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL, ability = self, damage_flags = damage_flags})
            target:AddNewModifier(self:GetCaster(), self, "modifier_shopkeeper_ability_1_debuff", {duration = duration * (1-target:GetStatusResistance())})
        end
    end
end

modifier_shopkeeper_ability_1_debuff = class({})

function modifier_shopkeeper_ability_1_debuff:GetTexture()
    return "shopkeeper_potion_of_duality_debuff"
end

function modifier_shopkeeper_ability_1_debuff:OnCreated()
    self.slow_movement_speed = self:GetAbility():GetSpecialValueFor("slow_movement_speed")
    if not IsServer() then return end
    self:IncrementStackCount()
    Timers:CreateTimer(self:GetDuration(), function()
        if self and not self:IsNull() then
            self:DecrementStackCount()
        end
    end)
end

function modifier_shopkeeper_ability_1_debuff:OnRefresh()
    self.slow_movement_speed = self:GetAbility():GetSpecialValueFor("slow_movement_speed")
    if not IsServer() then return end
    self:IncrementStackCount()
    Timers:CreateTimer(self:GetDuration(), function()
        if self and not self:IsNull() then
            self:DecrementStackCount()
        end
    end)
end

function modifier_shopkeeper_ability_1_debuff:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
end

function modifier_shopkeeper_ability_1_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self.slow_movement_speed * self:GetStackCount()
end

function modifier_shopkeeper_ability_1_debuff:GetEffectName()
    return "particles/econ/items/bristleback/ti7_head_nasal_goo/bristleback_ti7_crimson_nasal_goo_debuff.vpcf"
end

function modifier_shopkeeper_ability_1_debuff:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

----------------------------------

modifier_shopkeeper_ability_1_buff = class({})

function modifier_shopkeeper_ability_1_buff:OnCreated()
    self.bonus_movement_speed = self:GetAbility():GetSpecialValueFor("bonus_movement_speed")
    if not IsServer() then return end
    self:IncrementStackCount()
    Timers:CreateTimer(self:GetDuration(), function()
        if self and not self:IsNull() then
            self:DecrementStackCount()
        end
    end)
end

function modifier_shopkeeper_ability_1_buff:OnRefresh()
    self.bonus_movement_speed = self:GetAbility():GetSpecialValueFor("bonus_movement_speed")
    if not IsServer() then return end
    self:IncrementStackCount()
    Timers:CreateTimer(self:GetDuration(), function()
        if self and not self:IsNull() then
            self:DecrementStackCount()
        end
    end)
end

function modifier_shopkeeper_ability_1_buff:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
end

function modifier_shopkeeper_ability_1_buff:GetModifierMoveSpeedBonus_Percentage()
    return self.bonus_movement_speed * self:GetStackCount()
end

function modifier_shopkeeper_ability_1_buff:GetEffectName()
    return "particles/econ/items/sand_king/sandking_ti7_arms/sandking_ti7_caustic_finale_debuff.vpcf"
end

function modifier_shopkeeper_ability_1_buff:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end