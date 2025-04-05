LinkLuaModifier("modifier_shopkeeper_ability_4", "abilities/shopkeeper/shopkeeper_ability_4", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_shopkeeper_ability_4_choose", "abilities/shopkeeper/shopkeeper_ability_4", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_shopkeeper_ability_4_handler", "abilities/shopkeeper/shopkeeper_ability_4", LUA_MODIFIER_MOTION_NONE)

shopkeeper_ability_4 = class({})

function shopkeeper_ability_4:Precache(context)
    PrecacheResource("particle", "particles/hero/shopkeeper/amir4an/amir4anmods_shopkeeper_recipe_overhead.vpcf", context)
    PrecacheResource("particle", "particles/hero/shopkeeper/amir4an/amir4anmods_shopkeeper_recipe_body.vpcf", context)
end

function shopkeeper_ability_4:GetIntrinsicModifierName()
    return "modifier_shopkeeper_ability_4_handler"
end

function shopkeeper_ability_4:OnAbilityPhaseStart()
    local is_target_has_slot = false
    for i=0, 5 do
        local item_in_slot = self:GetCaster():GetItemInSlot(i)
        if item_in_slot == nil then
            is_target_has_slot = true
            break
        end
    end
    if not is_target_has_slot then
        CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(self:GetCaster():GetPlayerOwnerID()), "CreateIngameErrorMessage", {message = "Нет свободного места в инвентаре"})
        return false
    end
    return true
end

function shopkeeper_ability_4:OnAbilityUpgrade(ability)
    if not IsServer() then return end
    if ability ~= self then return end
    local shopkeeper_ability_innate = self:GetCaster():FindAbilityByName("shopkeeper_ability_innate")
    if shopkeeper_ability_innate then
        --shopkeeper_ability_innate:SetLevel(shopkeeper_ability_innate:GetLevel() + 1)
    end
end

function shopkeeper_ability_4:OnSpellStart()
    if not IsServer() then return end
    local duration = 30
    if IsInToolsMode() then
        duration = 300
    end
    self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_shopkeeper_ability_4_choose", {duration = duration})
end

modifier_shopkeeper_ability_4 = class({})
function modifier_shopkeeper_ability_4:IsPurgable() return false end
function modifier_shopkeeper_ability_4:IsPurgeException() return false end

function modifier_shopkeeper_ability_4:OnCreated(params)
    if not IsServer() then return end
    local particle = ParticleManager:CreateParticle("particles/hero/shopkeeper/amir4an/amir4anmods_shopkeeper_recipe_overhead.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent())
    local particle_body = ParticleManager:CreateParticle("particles/hero/shopkeeper/amir4an/amir4anmods_shopkeeper_recipe_body.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    Timers:CreateTimer(3, function()
        if particle then
            ParticleManager:DestroyParticle(particle, false)
        end
        if particle_body then
            ParticleManager:DestroyParticle(particle_body, false)
        end
    end)
    local random_item_name = params.item_name
    self:GetAbility().old_item_name = random_item_name
    self.unique_item = CreateItem(random_item_name, self:GetCaster(), self:GetCaster())
    if self.unique_item then
        self.unique_item:SetDroppable(false)
        self.unique_item:SetSellable(false)
        self.unique_item:SetPurchaseTime(0)
        self.unique_item:SetLevel(self:GetAbility():GetLevel())
        self:GetParent():AddItem(self.unique_item)
    end
    self:GetAbility():SetActivated(false)
    self:GetAbility():EndCooldown()
    self:StartIntervalThink(FrameTime())
end

function modifier_shopkeeper_ability_4:OnIntervalThink()
    if not IsServer() then return end
    if self.unique_item and not self.unique_item:IsNull() then
        self.unique_item:SetPurchaseTime(0)
    end
end

function modifier_shopkeeper_ability_4:OnDestroy()
    if not IsServer() then return end
    local item_object = self.unique_item
    Timers:CreateTimer(0.1, function()
        if item_object and not item_object:IsNull() then
            local container = item_object:GetContainer()
            if container then
                UTIL_Remove(container)
            end
            item_object:Destroy()
        end
    end)
    self:GetAbility():SetActivated(true)
    self:GetAbility():UseResources(false, false, false, true)
end

modifier_shopkeeper_ability_4_choose = class({})
function modifier_shopkeeper_ability_4_choose:IsHidden() return true end
function modifier_shopkeeper_ability_4_choose:IsPurgable() return false end
function modifier_shopkeeper_ability_4_choose:IsPurgeException() return false end

function modifier_shopkeeper_ability_4_choose:OnCreated()
    if not IsServer() then return end
    self:GetAbility():SetActivated(false)
    self:GetAbility():EndCooldown()
    local all_items = 
    {
        "item_shopkeeper_aegis",
        "item_shopkeeper_cyclone",
        "item_shopkeeper_cheese",
        "item_shopkeeper_octarine_core",
        --"item_shopkeeper_blink",
        "item_shopkeeper_sheepstick",
        "item_shopkeeper_force_staff",
    }
    if self:GetAbility().old_item_name then
        for i=#all_items, 1,-1 do
            if all_items[i] == self:GetAbility().old_item_name then
                table.remove(all_items, i)
            end
        end
    end
    local items_list = {}
    for i=1, 2 do
        table.insert(items_list, table.remove(all_items, RandomInt(1, #all_items)))
    end
    self.items = items_list
    CustomGameEventManager:Send_ServerToPlayer(self:GetParent():GetPlayerOwner(), "shopkeeper_ultimate_create_items", {items = items_list})
    self:StartIntervalThink(0.1)
    self:GetCaster():StartGesture(ACT_DOTA_CAST_ABILITY_4)

    local particle = ParticleManager:CreateParticle("models/heroes/shopkeeper/particles/cracker/cracker_idle_compos.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, self:GetParent())
    ParticleManager:SetParticleControlEnt(particle, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "hand_L_offset", self:GetParent():GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle, 1, self:GetParent(), PATTACH_POINT_FOLLOW, "hand_R_offset", self:GetParent():GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle, 8, self:GetParent(), PATTACH_POINT_FOLLOW, "hand_L", self:GetParent():GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle, 10, self:GetParent(), PATTACH_POINT_FOLLOW, "hand_R", self:GetParent():GetAbsOrigin(), true)
    self:AddParticle(particle, false, false, -1, false, false)

    self:GetParent():EmitSound("ShopKeeper.Hero_sound_9")
    self:GetParent():EmitSound("ShopKeeper.Hero_sound_10")
end

function modifier_shopkeeper_ability_4_choose:OnIntervalThink()
    if not IsServer() then return end
    CustomGameEventManager:Send_ServerToPlayer(self:GetParent():GetPlayerOwner(), "shopkeeper_ultimate_update_time", {time = self:GetRemainingTime(), max = self:GetDuration()})
end

function modifier_shopkeeper_ability_4_choose:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_OVERRIDE_ANIMATION
    }
end

function modifier_shopkeeper_ability_4_choose:GetOverrideAnimation()
    return ACT_DOTA_OVERRIDE_ABILITY_4
end

function modifier_shopkeeper_ability_4_choose:OnDestroy()
    if not IsServer() then return end
    if not self.use then
        self:GetAbility():SetActivated(true)
        CustomGameEventManager:Send_ServerToPlayer(self:GetParent():GetPlayerOwner(), "shopkeeper_ultimate_create_items_close", {})
    end
    self:GetParent():StopSound("ShopKeeper.Hero_sound_9")
end

function modifier_shopkeeper_ability_4_choose:CheckState()
    if IsClient() then return end
    return
    {
        [MODIFIER_STATE_STUNNED] = true,
    }
end

modifier_shopkeeper_ability_4_handler = class({})
function modifier_shopkeeper_ability_4_handler:IsHidden() return true end
function modifier_shopkeeper_ability_4_handler:IsPurgable() return false end
function modifier_shopkeeper_ability_4_handler:IsPurgeException() return false end
function modifier_shopkeeper_ability_4_handler:RemoveOnDeath() return false end
function modifier_shopkeeper_ability_4_handler:DeclareFunctions()
    return
    {
        MODIFIER_EVENT_ON_RESPAWN
    }
end
function modifier_shopkeeper_ability_4_handler:OnRespawn(params)
    if not IsServer() then return end
    if params.unit ~= self:GetParent() then return end
    if self:GetParent().respawn_aegis_percent then
        local parent = self:GetParent()
        Timers:CreateTimer(FrameTime(), function()
            local health = min(parent:GetMaxHealth() / 100 * parent.respawn_aegis_percent, parent:GetMaxHealth())
            local mana = min(parent:GetMaxMana() / 100 * parent.respawn_aegis_percent, parent:GetMaxMana())
            parent:SetHealth(health)
            parent:SetMana(mana)
            parent.respawn_aegis_percent = nil
        end)
    end
end