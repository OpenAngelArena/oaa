-- abilities/shopkeeper/shopkeeper_vagabond.lua

-- Link the modifier directly in this file
LinkLuaModifier("modifier_shopkeeper_vagabond", "abilities/shopkeeper/shopkeeper_vagabond", LUA_MODIFIER_MOTION_NONE)

shopkeeper_vagabond = class({})

function shopkeeper_vagabond:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local initial_gold = caster:GetGold()
    local threshold_percent = self:GetSpecialValueFor("threshold_percent") / 100
    local min_gold = initial_gold * threshold_percent
    local duration = self:GetSpecialValueFor("duration")  -- Duration of the modifier from KV

    -- Apply the modifier to the caster with the calculated values
    caster:AddNewModifier(caster, self, "modifier_shopkeeper_vagabond", {
        duration = duration,  -- Duration from KV file
        min_gold = min_gold,
        threshold_percent = threshold_percent
    })
end

-- Modifier definition inside the same file
modifier_shopkeeper_vagabond = class({})

function modifier_shopkeeper_vagabond:IsPurgable()
    return false
end

function modifier_shopkeeper_vagabond:OnCreated(kv)
    if not IsServer() then return end

    -- Set the min_gold from the values passed in OnCreated
    self.min_gold = kv.min_gold
    self.threshold_percent = kv.threshold_percent

    -- Ensure the caster's gold doesn't drop below the minimum threshold
    self:GetCaster():SetGold(self.min_gold, false)

    -- Set the stack count to show min_gold in the tooltip
    self:SetStackCount(self.min_gold)
end

function modifier_shopkeeper_vagabond:OnGoldChange(event)
    local caster = self:GetCaster()

    -- Only act if the caster's gold changes
    if event.unit == caster then
        -- If the gold goes below the minimum, set it back
        if caster:GetGold() < self.min_gold then
            caster:SetGold(self.min_gold, false)
        end
    end
end

-- Tooltip function to show the current min_gold value
function modifier_shopkeeper_vagabond:OnTooltip()
    return self:GetStackCount()
end
