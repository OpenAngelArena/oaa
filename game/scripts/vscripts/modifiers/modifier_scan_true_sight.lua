---
--- Created by Zarnotox.
--- DateTime: 29-Nov-17 10:50
---

modifier_scan_true_sight_thinker = class( ModifierBaseClass )

--------- modifier_scan_true_sight_thinker ---------

function modifier_scan_true_sight_thinker:IsPurgable()
    return false
end

if IsServer() then

    function modifier_scan_true_sight_thinker:OnCreated( event )

        self.debuff_interval = 0.4
        self.debuff_duration = 0.5
        self.radius = SCAN_REVEAL_RADIUS

        self:StartIntervalThink(self.debuff_interval)
    end

    function modifier_scan_true_sight_thinker:OnIntervalThink()

        local found_targets = FindUnitsInRadius(self:GetParent():GetTeamNumber(), self:GetParent():GetOrigin(), self:GetParent(), self.radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, FIND_ANY_ORDER, false)

        if #found_targets > 0 then
            for _,unit in pairs(found_targets) do
                unit:AddNewModifier(self:GetCaster(), nil, "modifier_truesight", {
                    duration = self.debuff_duration
                })
            end
        end
    end

    function modifier_scan_true_sight_thinker:OnDestroy()
        UTIL_Remove( self:GetParent() )
    end

end