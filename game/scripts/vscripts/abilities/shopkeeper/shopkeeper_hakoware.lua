-- Link the modifier
LinkLuaModifier("modifier_shopkeeper_hakoware_debt", "abilities/shopkeeper/shopkeeper_hakoware", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_shopkeeper_hakoware_item_mute", "abilities/shopkeeper/shopkeeper_hakoware", LUA_MODIFIER_MOTION_NONE)

shopkeeper_hakoware = class({})

function shopkeeper_hakoware:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local duration = self:GetSpecialValueFor("duration")

    -- gold transfer
    local current_gold = caster:GetGold()
    local loan_amount = math.floor(current_gold * 0.10)
    caster:SpendGold(loan_amount, DOTA_ModifyGold_Unspecified)

    -- Apply the debt modifier to the target
    target:AddNewModifier(caster, self, "modifier_shopkeeper_hakoware_debt", {
        duration = duration,
        loan_amount = loan_amount
    })
    target:ModifyGold(loan_amount, true, DOTA_ModifyGold_Unspecified)

    -- Feedback
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_GOLD, target, loan_amount, caster:GetPlayerOwner())
    EmitSoundOn("Hero_Alchemist.ChemicalRage.Start", target)
end

modifier_shopkeeper_hakoware_debt = class({})

function modifier_shopkeeper_hakoware_debt:IsHidden() return false end
function modifier_shopkeeper_hakoware_debt:IsDebuff() return true end
function modifier_shopkeeper_hakoware_debt:IsPurgable() return false end

-- Declare functions for the modifier
function modifier_shopkeeper_hakoware_debt:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOOLTIP,
        MODIFIER_EVENT_ON_TAKEDAMAGE,  -- Listen for damage events
    }
end

-- Show the current debt on the tooltip
function modifier_shopkeeper_hakoware_debt:OnTooltip()
    return self:GetStackCount()
end

-- Handle the creation of the modifier
function modifier_shopkeeper_hakoware_debt:OnCreated(kv)
    if not IsServer() then return end

    self.debt = kv.loan_amount or 0
    self.interest_rate = self:GetAbility():GetSpecialValueFor("interest_rate")
    self:StartIntervalThink(1.0)

    -- Set the initial debt as the stack count
    self:SetStackCount(math.floor(self.debt))
end

-- Update debt every second based on the interest rate
function modifier_shopkeeper_hakoware_debt:OnIntervalThink()
    self.debt = self.debt + self.debt * self.interest_rate
    self:SetStackCount(math.floor(self.debt))
end

function modifier_shopkeeper_hakoware_debt:OnDestroy()
    if not IsServer() then return end

    -- Calculate the final debt with interest
    local final_debt = self:GetStackCount()  -- Debt is stored in stack count

    -- Apply pure damage based on the debt amount
    local damage_table = {
        victim = self:GetParent(),
        attacker = self:GetCaster(),
        damage = final_debt,
        damage_type = self:GetAbility():GetAbilityDamageType(),
        ability = self:GetAbility(),
        damage_flags = DOTA_DAMAGE_FLAG_NONE,  -- Or use other flags as needed
    }

    ApplyDamage(damage_table)

    -- Deduct the final debt from the target's gold (make them spend it)
    local target = self:GetParent()
    target:ModifyGold(-final_debt, true, DOTA_ModifyGold_Unspecified)

    -- Transfer the final debt (after interest) to the shopkeeper
    self:GetCaster():ModifyGold(final_debt, true, DOTA_ModifyGold_Unspecified)

    -- Retrieve the mute duration from the kv file based on ability level
    local mute_duration = self:GetAbility():GetSpecialValueFor("mute_duration")

    -- Apply the mute modifier when the debt is settled
    self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_shopkeeper_hakoware_item_mute", {duration = mute_duration})
end

if IsServer() then
    function modifier_shopkeeper_hakoware_debt:OnTakeDamage(event)
        local parent = self:GetParent()
        local ability = self:GetAbility()
        local attacker = event.attacker
        local damaged_unit = event.unit

        -- validate attacker and damaged unit
        if not attacker or attacker:IsNull() or not damaged_unit or damaged_unit:IsNull() then
            return
        end

        -- ensure attacker is the debt holder
        if attacker ~= parent then
            return
        end

        -- ensure damaged unit is the shopkeeper (caster)
        if damaged_unit ~= ability:GetCaster() then
            return
        end

        local damage = event.damage
        if damage <= 0 then
            return
        end

        -- calculate repayment
        local old_debt = self.debt
        self.debt = math.max(self.debt - damage, 0)
        local repayment = old_debt - self.debt

        -- transfer gold from attacker to shopkeeper
        if repayment > 0 then
            attacker:SpendGold(math.floor(repayment), DOTA_ModifyGold_Unspecified)
            damaged_unit:ModifyGold(math.floor(repayment), true, DOTA_ModifyGold_Unspecified)
        end

        self:SetStackCount(math.floor(self.debt))
    end
end

-- Mute Modifier for Item Use
modifier_shopkeeper_hakoware_item_mute = class({})

function modifier_shopkeeper_hakoware_item_mute:IsHidden() return false end
function modifier_shopkeeper_hakoware_item_mute:IsDebuff() return true end
function modifier_shopkeeper_hakoware_item_mute:IsPurgable() return true end

-- Status effects: mute the usage of items
function modifier_shopkeeper_hakoware_item_mute:CheckState()
    local state = {
        [MODIFIER_STATE_MUTED] = true,  -- Mutes items for the target
    }
    return state
end