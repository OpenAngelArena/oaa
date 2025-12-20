-- Link the new modifier
LinkLuaModifier("modifier_shopkeeper_all_in_shield", "abilities/shopkeeper/shopkeeper_all_in", LUA_MODIFIER_MOTION_NONE)

shopkeeper_all_in = class({})

function shopkeeper_all_in:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local gold_cost = caster:GetGold()

    -- Deduct the gold manually
    caster:SpendGold(gold_cost, DOTA_ModifyGold_Unspecified)

    -- Hard dispel the target before applying the shield
    target:Purge(true, true, false, true, true)

    -- Get scaling values from the KV
    local conversion_rate = self:GetSpecialValueFor("conversion_rate")
    local shield_max_value = self:GetSpecialValueFor("shield_max_value")
    local shield_value = math.floor(gold_cost * conversion_rate)
    shield_value = math.min(shield_value, shield_max_value)

    -- Apply the shield
    target:AddNewModifier(caster, self, "modifier_shopkeeper_all_in_shield", {
        duration = self:GetSpecialValueFor("duration"),
        shield_value = shield_value
    })

    EmitSoundOn("Hero_Alchemist.ChemicalRage.Start", target)
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_GOLD, target, gold_cost, caster:GetPlayerOwner())
end


modifier_shopkeeper_all_in_shield = class({})

function modifier_shopkeeper_all_in_shield:IsHidden() return false end
function modifier_shopkeeper_all_in_shield:IsDebuff() return false end
function modifier_shopkeeper_all_in_shield:IsPurgable() return false end
function modifier_shopkeeper_all_in_shield:IsPermanent() return true end

-- This modifier provides a damage shield and debuff immunity
function modifier_shopkeeper_all_in_shield:CheckState()
    return {
        [MODIFIER_STATE_DEBUFF_IMMUNE] = true,
    }
end

function modifier_shopkeeper_all_in_shield:OnCreated(kv)local ability = self:GetAbility()
    if ability and not ability:IsNull() then
        self.shield_max_value = ability:GetSpecialValueFor("shield_max_value")
    else
        self.shield_max_value = 0
    end


    if not IsServer() then return end

    local shield_value = kv.shield_value or 0

    self:SetStackCount(0 - shield_value)
end

-- This modifier provides a damage shield and debuff immunity
function modifier_shopkeeper_all_in_shield:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
        MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT,
    }
end

if IsServer() then
    function modifier_shopkeeper_all_in_shield:GetModifierTotal_ConstantBlock(event)
        -- Do nothing if damage has HP removal flag
        if bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then
            return 0
        end

        local current_shield = math.abs(self:GetStackCount())
        local block_amount = math.min(event.damage, current_shield)
        self:SetStackCount(block_amount - current_shield)

        -- Remove the shield if hp is reduced to nothing
        if self:GetStackCount() >= 0 then
            self:Destroy()
        end

        return block_amount
    end
end

function modifier_shopkeeper_all_in_shield:GetModifierIncomingDamageConstant(event)
    if IsClient() then
        local max_shield = self.shield_max_value
        local current_shield = math.abs(self:GetStackCount())
        if event.report_max then
            return max_shield -- max shield hp
        else
            return current_shield -- current shield hp
        end
    else
        return 0
    end
end
