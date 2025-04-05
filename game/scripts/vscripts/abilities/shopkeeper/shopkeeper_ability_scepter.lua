LinkLuaModifier("modifier_shopkeeper_ability_scepter", "abilities/shopkeeper/shopkeeper_ability_scepter", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_shopkeeper_ability_scepter_consume", "abilities/shopkeeper/shopkeeper_ability_scepter", LUA_MODIFIER_MOTION_NONE)

shopkeeper_ability_scepter = class({})

function shopkeeper_ability_scepter:OnSpellStart()
    self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_shopkeeper_ability_scepter", {})
end

modifier_shopkeeper_ability_scepter = class({})
function modifier_shopkeeper_ability_scepter:IsPurgable() return false end
function modifier_shopkeeper_ability_scepter:IsPurgeException() return false end
function modifier_shopkeeper_ability_scepter:IsPurgeException() return false end
function modifier_shopkeeper_ability_scepter:OnCreated()
    if not IsServer() then return end
    self:GetAbility():EndCooldown()
    CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(self:GetParent():GetPlayerOwnerID()), "shopkeeper_item_consume_active", {consume = 1})
    self:GetAbility():SetActivated(false)
end
function modifier_shopkeeper_ability_scepter:OnDestroy()
    if not IsServer() then return end
    CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(self:GetParent():GetPlayerOwnerID()), "shopkeeper_item_consume_active", {consume = 0})
    self:GetAbility():SetActivated(true)
    if self.active then
        self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_shopkeeper_ability_scepter_consume", {item = self.item_icon})
        self:GetAbility():UseResources(false, false, false, true)
    end
end

modifier_shopkeeper_ability_scepter_consume = class({})
function modifier_shopkeeper_ability_scepter_consume:IsHidden() return true end
function modifier_shopkeeper_ability_scepter_consume:IsPurgable() return false end
function modifier_shopkeeper_ability_scepter_consume:IsPurgeException() return false end
function modifier_shopkeeper_ability_scepter_consume:RemoveOnDeath() return false end
function modifier_shopkeeper_ability_scepter_consume:IsPurgeException() return false end
function modifier_shopkeeper_ability_scepter_consume:GetTexture() return self.item_icon end
function modifier_shopkeeper_ability_scepter_consume:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_shopkeeper_ability_scepter_consume:OnCreated(data)
    if not IsServer() then return end
    self.item_icon = data.item
    if self:GetParent().consume_items == nil then
        self:GetParent().consume_items = {}
    end
    table.insert(self:GetParent().consume_items, self.item_icon)
    if #self:GetParent().consume_items >= 3 then
        self:GetAbility():SetActivated(false)
    end
    CustomNetTables:SetTableValue("shop_keeper_items", "shop_keeper_items", self:GetParent().consume_items)
    self:SetHasCustomTransmitterData( true )
end
function modifier_shopkeeper_ability_scepter_consume:AddCustomTransmitterData()
	local data = 
    {
		item_icon = self.item_icon,
	}
	return data
end
function modifier_shopkeeper_ability_scepter_consume:HandleCustomTransmitterData( data )
	self.item_icon = data.item_icon
end