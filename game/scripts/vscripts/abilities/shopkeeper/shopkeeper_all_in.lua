-- Link the new modifier
LinkLuaModifier("modifier_shopkeeper_all_in_shield", "abilities/shopkeeper/shopkeeper_all_in", LUA_MODIFIER_MOTION_NONE)

shopkeeper_all_in = class({})

function shopkeeper_all_in:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local level = self:GetLevel() - 1  -- Ability level starts at 1, so subtract 1
    local gold_spent = caster:GetGold()

    -- Calculate the gold cost as 100% of the Shopkeeper's net worth
    local gold_cost = gold_spent  -- Full net worth of the Shopkeeper

    -- Get scaling values from the KV
    local conversion_rate = self:GetSpecialValueFor("conversion_rate")[level + 1]  -- Indexing for conversion rate
    local shield_max_value = self:GetSpecialValueFor("shield_max_value")[level + 1]  -- Max shield value
    local shield_value = math.floor(gold_cost * conversion_rate)

    -- Ensure the shield value doesn't exceed the max shield value
    shield_value = math.min(shield_value, shield_max_value)

    -- Spend the full gold
    caster:SpendGold(gold_cost, DOTA_ModifyGold_Unspecified)

    -- Apply the shield modifier to the target
    target:AddNewModifier(caster, self, "modifier_shopkeeper_all_in_shield", {
        duration = self:GetSpecialValueFor("duration")[level + 1],  -- Duration scaling based on level
        shield_value = shield_value
    })

    -- Feedback
    EmitSoundOn("Hero_Alchemist.ChemicalRage.Start", target)
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_GOLD, target, gold_cost, caster:GetPlayerOwner())
end

modifier_shopkeeper_all_in_shield = class({})

function modifier_shopkeeper_all_in_shield:IsHidden() return false end
function modifier_shopkeeper_all_in_shield:IsDebuff() return false end
function modifier_shopkeeper_all_in_shield:IsPurgable() return false end
function modifier_shopkeeper_all_in_shield:IsPermanent() return true end

-- This modifier provides a damage shield and debuff immunity
function modifier_shopkeeper_all_in_shield:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,  -- A function to reduce incoming damage based on the shield value
        MODIFIER_PROPERTY_STATUS_RESISTANCE,           -- Provides debuff immunity
    }
end

function modifier_shopkeeper_all_in_shield:GetModifierIncomingDamage_Percentage(params)
    -- Reduce damage based on the shield value
    if self:GetParent():IsMagicImmune() then
        return 0  -- If immune, no damage
    end

    if self.shield_value > 0 then
        local damage_block = math.min(self.shield_value, params.damage)
        self.shield_value = self.shield_value - damage_block
        return -damage_block  -- Return a negative value to reduce the incoming damage
    end

    return 0  -- No shield left
end

-- Provide status resistance (debuff immunity)
function modifier_shopkeeper_all_in_shield:GetModifierStatusResistance()
    return 100  -- 100% resistance to debuffs (i.e., debuff immunity)
end

-- Handle shield destruction (when time is up or the shield runs out)
function modifier_shopkeeper_all_in_shield:OnDestroy()
    if not IsServer() then return end

    -- Optional: Play sound or effect when the shield expires
    EmitSoundOn("Hero_Alchemist.ChemicalRage.End", self:GetParent())
end

-- On creation, initialize shield value
function modifier_shopkeeper_all_in_shield:OnCreated(kv)
    if not IsServer() then return end

    self.shield_value = kv.shield_value or 0
end
