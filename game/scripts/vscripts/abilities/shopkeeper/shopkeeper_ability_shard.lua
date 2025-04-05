LinkLuaModifier("modifier_shopkeeper_ability_shard", "abilities/shopkeeper/shopkeeper_ability_shard", LUA_MODIFIER_MOTION_NONE)

shopkeeper_ability_shard = class({})

function shopkeeper_ability_shard:GetIntrinsicModifierName()
    return "modifier_shopkeeper_ability_shard"
end

function shopkeeper_ability_shard:OnSpellStart()
    if not IsServer() then return end
    Timers:CreateTimer(0.1, function()
        self:EndCooldown()
    end)
    CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(self:GetCaster():GetPlayerOwnerID()), "shopkeeper_shard_panel", {})
end

modifier_shopkeeper_ability_shard = class({})
function modifier_shopkeeper_ability_shard:IsHidden() return true end
function modifier_shopkeeper_ability_shard:IsPurgable() return false end
function modifier_shopkeeper_ability_shard:IsPurgeException() return false end
function modifier_shopkeeper_ability_shard:RemoveOnDeath() return false end