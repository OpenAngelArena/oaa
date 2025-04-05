LinkLuaModifier("modifier_shopkeeper_ability_2", "abilities/shopkeeper/shopkeeper_ability_2", LUA_MODIFIER_MOTION_NONE)

shopkeeper_ability_2 = class({})

function shopkeeper_ability_2:Precache(context)
    PrecacheResource("particle", "particles/units/heroes/hero_ogre_magi/ogre_magi_ignite.vpcf", context)
    PrecacheResource("particle", "particles/units/unit_greevil/greevil_transformation.vpcf", context)
    PrecacheResource("particle", "particles/units/heroes/hero_winter_wyvern/winter_wyvern_base_attack.vpcf", context)
    PrecacheResource("soundfile", "soundevents/game_sounds_greevils.vsndevts", context)
end

function shopkeeper_ability_2:OnAbilityPhaseStart()
    local target = self:GetCursorTarget()
    local is_target_has_slot = false
    for i=0, 8 do
        local item_in_slot = target:GetItemInSlot(i)
        if item_in_slot == nil or item_in_slot:GetName() == "item_shopkeeper_krekker" then
            is_target_has_slot = true
            break
        end
    end
    if not is_target_has_slot then
        CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(self:GetCaster():GetPlayerOwnerID()), "CreateIngameErrorMessage", {message = "У цели нет места в инвентаре"})
        return false
    end
    return true
end

function shopkeeper_ability_2:OnSpellStart()
    if not IsServer() then return end
    self.target = self:GetCursorTarget()
    self.modifier_shopkeeper_ability_2 = self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_shopkeeper_ability_2", {duration = self:GetChannelTime()})
    local particle = ParticleManager:CreateParticle("particles/shopkeeper_attacks.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
    ParticleManager:SetParticleControl(particle, 1, Vector(1, math.abs(50), 0))
	ParticleManager:SetParticleControl(particle, 2, Vector(2, string.len(math.abs(50)) + 1, 0))
    ParticleManager:ReleaseParticleIndex(particle)
end

function shopkeeper_ability_2:OnChannelFinish(bInterrupted)
    if self.modifier_shopkeeper_ability_2 and not self.modifier_shopkeeper_ability_2:IsNull() then
        self.modifier_shopkeeper_ability_2:Destroy()
    end
    local is_target_has_slot = false
    for i=0, 8 do
        local item_in_slot = self.target:GetItemInSlot(i)
        if item_in_slot == nil or item_in_slot:GetName() == "item_shopkeeper_krekker" then
            is_target_has_slot = true
            break
        end
    end
    if not is_target_has_slot then
        self:EndCooldown()
        CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(self:GetCaster():GetPlayerOwnerID()), "CreateIngameErrorMessage", {message = "У цели нет места в инвентаре"})
        return
    end
    if bInterrupted then return end
    --self.target:EmitSound("greevil_receive_present_Stinger")

    local counter = self:GetSpecialValueFor("counter")
    for i=1, counter do
        local item_shopkeeper_krekker = self.target:FindItemInInventory("item_shopkeeper_krekker")
        if item_shopkeeper_krekker then
            item_shopkeeper_krekker:SetPurchaseTime(0)
            item_shopkeeper_krekker:SetCurrentCharges(item_shopkeeper_krekker:GetCurrentCharges() + 1)
            item_shopkeeper_krekker:SetLevel(self:GetLevel())
        else
            item_shopkeeper_krekker = CreateItem("item_shopkeeper_krekker", self.target, self.target)
            item_shopkeeper_krekker:SetLevel(self:GetLevel())
            item_shopkeeper_krekker:SetPurchaseTime(0)
            self.target:AddItem(item_shopkeeper_krekker)
        end
    end
end

modifier_shopkeeper_ability_2 = class({})
function modifier_shopkeeper_ability_2:IsHidden() return true end
function modifier_shopkeeper_ability_2:IsPurgable() return false end
function modifier_shopkeeper_ability_2:IsPurgeException() return false end
function modifier_shopkeeper_ability_2:OnCreated()
    if not IsServer() then return end
    self:GetCaster():EmitSound("ShopKeeper.Hero_sound_2")
end
function modifier_shopkeeper_ability_2:OnDestroy()
    if not IsServer() then return end
    if self:GetRemainingTime() > 0.1 then
        self:GetCaster():StopSound("ShopKeeper.Hero_sound_2")
    end
end