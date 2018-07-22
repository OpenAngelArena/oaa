modifier_generic_projectile = class(ModifierBaseClass)

------------------------------------------------------------------------------------

function modifier_generic_projectile:GetOverrideAnimation(projectileTable)
    if self.projectileTable and self.projectileTable.flail then
        return ACT_DOTA_FLAIL
    else
        return nil
    end
end

------------------------------------------------------------------------------------

function modifier_generic_projectile:DeclareFunctions()
    return { MODIFIER_PROPERTY_OVERRIDE_ANIMATION }
end

------------------------------------------------------------------------------------

function modifier_generic_projectile:InitProjectile(projectileTable)
    if projectileTable then
        self.projectileTable = projectileTable
        self.traveled = 0
        self.hits = {}
        self:StartIntervalThink(0.03)
    end
end

------------------------------------------------------------------------------------

function modifier_generic_projectile:IsHidden()
    return true
end

------------------------------------------------------------------------------------

function modifier_generic_projectile:GetPriority()
    return MODIFIER_PRIORITY_SUPER_ULTRA
end

------------------------------------------------------------------------------------

function modifier_generic_projectile:DeclareFunctions()
    local funcs =
    {
        MODIFIER_EVENT_ON_DEATH,
    }

    return funcs
end

------------------------------------------------------------------------------------

function modifier_generic_projectile:OnDeath(keys)
    if IsServer() then
        local caster = self:GetParent()
        if keys.unit:entindex() == caster:entindex() then
            if self.projectileTable and self.projectileTable.onDiedCallback then
                self.projectileTable.onDiedCallback()
            end
        end
    end
end

------------------------------------------------------------------------------------

function modifier_generic_projectile:CheckState()
    if self.projectileTable then
        local state = {
            [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
            [MODIFIER_STATE_UNSELECTABLE] = not self.projectileTable.selectable,
            [MODIFIER_STATE_NO_HEALTH_BAR] = not self.projectileTable.selectable,
            [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
            [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
            [MODIFIER_STATE_INVULNERABLE] = not self.projectileTable.noInvul,
            [MODIFIER_STATE_STUNNED] = false,
        }

        return state
    end
end

------------------------------------------------------------------------------------

function modifier_generic_projectile:OnIntervalThink()
    local projectile = self:GetParent()

    local projectileTable = self.projectileTable

    local onLandedCallback = projectileTable.onLandedCallback
    local onUnitHitCallback = projectileTable.onUnitHitCallback

    if self.traveled < 1 then
        self.traveled = self.traveled + projectileTable.speed

        if self.traveled > 1 then
            self.traveled = 1
        end

        local z = projectileTable.height * math.sin(math.pi * self.traveled)

        local step = math.min(projectileTable.speed, (projectile:GetAbsOrigin() - projectileTable.target):Length2D())
        local newPosition = LerpVectors(projectileTable.origin, projectileTable.target, self.traveled)

        newPosition.z = LerpVectors(Vector(0,0,projectileTable.origin.z), Vector(0,0,projectileTable.target.z), self.traveled).z + z
        projectile:SetAbsOrigin(newPosition)

        if onUnitHitCallback then
            local units = FindUnitsInRadius(
                projectile:GetTeamNumber(),
                projectile:GetAbsOrigin(),
                nil,
                projectileTable.hitRadius,
                DOTA_UNIT_TARGET_TEAM_ENEMY,
                DOTA_UNIT_TARGET_ALL,
                DOTA_UNIT_TARGET_FLAG_NONE,
                FIND_CLOSEST,
                false
            )

            for k,v in pairs(units) do
                if not self.hits[v:entindex()] then
                    self.hits[v:entindex()] = true

                    onUnitHitCallback(v)
                end
            end
        end

        return 0.03
    else
        projectile:SetAbsOrigin(projectileTable.target)
        self:Destroy()

        onLandedCallback()

        print("Projectile done")
    end
end