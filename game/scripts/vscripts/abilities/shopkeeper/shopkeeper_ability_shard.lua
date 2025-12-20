LinkLuaModifier("modifier_shopkeeper_ability_shard", "abilities/shopkeeper/shopkeeper_ability_shard", LUA_MODIFIER_MOTION_NONE)

shopkeeper_ability_shard = class({})

function shopkeeper_ability_shard:GetIntrinsicModifierName()
    return "modifier_shopkeeper_ability_shard"
end

modifier_shopkeeper_ability_shard = class({})

-- Blacklist of items that should NOT trigger the cooldown reduction
-- Add item names here to exclude them (e.g., consumables, TPs)
modifier_shopkeeper_ability_shard.ITEM_BLACKLIST = {
    ["item_tpscroll"] = true,
    ["item_travel_boots"] = true,
    ["item_travel_boots_2"] = true,
    ["item_flask"] = true,
    ["item_clarity"] = true,
    ["item_enchanted_mango"] = true,
    ["item_faerie_fire"] = true,
    ["item_tango"] = true,
    ["item_tango_single"] = true,
    ["item_ward_observer"] = true,
    ["item_ward_sentry"] = true,
    ["item_dust"] = true,
    ["item_smoke_of_deceit"] = true,
    ["item_tome_of_knowledge"] = true,
    ["item_cheese"] = true,
    ["item_refresher_shard"] = true,
}

function modifier_shopkeeper_ability_shard:IsHidden() return true end
function modifier_shopkeeper_ability_shard:IsPurgable() return false end
function modifier_shopkeeper_ability_shard:IsPurgeException() return false end
function modifier_shopkeeper_ability_shard:RemoveOnDeath() return false end

function modifier_shopkeeper_ability_shard:OnCreated()
    self.radius = self:GetAbility():GetSpecialValueFor("radius")
    self.cooldown_reduction = self:GetAbility():GetSpecialValueFor("cooldown_reduction")
end

function modifier_shopkeeper_ability_shard:OnRefresh()
    self:OnCreated()
end

function modifier_shopkeeper_ability_shard:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
    }
end

function modifier_shopkeeper_ability_shard:OnAbilityFullyCast(event)
    if not IsServer() then return end

    local caster = event.unit
    local ability = event.ability
    local parent = self:GetParent()

    -- Check if caster is nil or dead
    if not caster or caster:IsNull() or not caster:IsAlive() then return end

    -- Check if ability is an item
    if not ability or ability:IsNull() or not ability:IsItem() then return end

    -- Check if item is blacklisted
    local item_name = ability:GetAbilityName()
    if modifier_shopkeeper_ability_shard.ITEM_BLACKLIST[item_name] then return end

    -- Check if caster is within radius
    local distance = (caster:GetAbsOrigin() - parent:GetAbsOrigin()):Length2D()
    if distance > self.radius then return end

    -- Reduce cooldowns on all Shopkeeper abilities
    for i = 0, parent:GetAbilityCount() - 1 do
        local shop_ability = parent:GetAbilityByIndex(i)
        if shop_ability and not shop_ability:IsNull() and shop_ability:GetCooldownTimeRemaining() > 0 then
            local new_cooldown = shop_ability:GetCooldownTimeRemaining() - self.cooldown_reduction
            if new_cooldown < 0 then new_cooldown = 0 end
            shop_ability:EndCooldown()
            if new_cooldown > 0 then
                shop_ability:StartCooldown(new_cooldown)
            end
        end
    end
end