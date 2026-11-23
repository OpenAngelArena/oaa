-- abilities/shopkeeper/shopkeeper_vagabond.lua

-- Link the modifier directly in this file
LinkLuaModifier("modifier_shopkeeper_vagabond", "abilities/shopkeeper/shopkeeper_vagabond", LUA_MODIFIER_MOTION_NONE)

shopkeeper_vagabond = class(AbilityBaseClass)

function shopkeeper_vagabond:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local initial_gold = caster:GetGold()
    local threshold_percent = self:GetSpecialValueFor("threshold_percent") / 100
    local min_gold = math.floor(initial_gold * threshold_percent)
    local duration = self:GetSpecialValueFor("duration")

    -- Apply the modifier to the caster with the calculated values
    caster:AddNewModifier(caster, self, "modifier_shopkeeper_vagabond", {
        duration = duration,
        min_gold = min_gold,
        threshold_percent = threshold_percent
    })
end

-- Modifier definition inside the same file
modifier_shopkeeper_vagabond = class(ModifierBaseClass)

function modifier_shopkeeper_vagabond:IsPurgable()
    return false
end

function modifier_shopkeeper_vagabond:OnCreated(kv)
    if not IsServer() then return end

    -- Set the min_gold from the values passed in OnCreated
    self.min_gold = kv.min_gold
    self.threshold_percent = kv.threshold_percent

    -- Set the stack count to show min_gold in the tooltip
    self:SetStackCount(self.min_gold)

    -- Poll gold each tick and restore if below threshold
    self:StartIntervalThink(0.1)
end

function modifier_shopkeeper_vagabond:OnIntervalThink()
    if not IsServer() then return end

    local caster = self:GetCaster()
    if caster:GetGold() < self.min_gold then
        caster:SetGold(self.min_gold, false)
    end
end

-- Tooltip function to show the current min_gold value
function modifier_shopkeeper_vagabond:OnTooltip()
    return self:GetStackCount()
end
