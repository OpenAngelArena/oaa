LinkLuaModifier("modifier_item_shopkeeper_krekker", "items/shopkeeper_krekker", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_shopkeeper_krekker_handler", "items/shopkeeper_krekker", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_shopkeeper_krekker_thinker", "items/shopkeeper_krekker", LUA_MODIFIER_MOTION_NONE)

item_shopkeeper_krekker = class({})

function item_shopkeeper_krekker:OnSpellStart()
    if not IsServer() then return end
    local ability = self:GetCaster():FindAbilityByName("shopkeeper_ability_2_cast")
    if not ability then return end
    ability:SetLevel(self:GetLevel())
    local hero = self:GetCaster()
    self.point = self:GetCursorPosition()
    self.point = GetGroundPosition(self.point, nil)
	self.point_start = self:GetCaster():GetAbsOrigin()

    ability.callback_custom = function() 
        hero:StartGesture(ACT_DOTA_TELEPORT)
        hero:AddNewModifier(self:GetCaster(), self, "modifier_item_shopkeeper_krekker", {duration = ability:GetChannelTime()})
    
        self.teleportFromEffect = ParticleManager:CreateParticle("amir4an/particles/shopkeeper/amir4anmods_shopkeeper_teleport.vpcf", PATTACH_ABSORIGIN, self:GetCaster())
    
        self.teleport_center = CreateUnitByName("npc_dota_companion", self.point, false, nil, nil, self:GetCaster():GetTeamNumber())
        local modifier_item_shopkeeper_krekker_thinker = self.teleport_center:AddNewModifier(self:GetCaster(), nil, "modifier_item_shopkeeper_krekker_thinker", {duration = ability:GetChannelTime() + 1})
        self.teleport_center:AddNewModifier(self.teleport_center, nil, "modifier_invulnerable", {})
        self.teleport_center:AddNewModifier(self.teleport_center, nil, "modifier_kill", {})
        self.teleport_center:SetAbsOrigin(self.point)
    
        self.teleportToEffect = ParticleManager:CreateParticle("amir4an/particles/shopkeeper/amir4anmods_shopkeeper_teleport.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.teleport_center)
        ParticleManager:SetParticleControlEnt(self.teleportToEffect, 3, self:GetCaster(), PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", self.teleport_center:GetAbsOrigin(), true)
        ParticleManager:SetParticleControl(self.teleportToEffect, 4, Vector(0.9, 0, 0))
        ParticleManager:SetParticleControlEnt(self.teleportToEffect, 5, self.teleport_center, PATTACH_POINT_FOLLOW, "attach_hitloc", self.teleport_center:GetAbsOrigin(), true)
    
        if modifier_item_shopkeeper_krekker_thinker then
            modifier_item_shopkeeper_krekker_thinker:AddParticle(self.teleportFromEffect, false, false, -1, false, false)
            modifier_item_shopkeeper_krekker_thinker:AddParticle(self.teleportToEffect, false, false, -1, false, false)
        end
    end

    ability.original_item = self
    self:GetCaster():CastAbilityNoTarget(ability, self:GetCaster():GetPlayerOwnerID())
    -- Timers:CreateTimer(FrameTime(), function()
    --     if not ability:IsChanneling() then
    --         ability:OnChannelFinish(true)
    --     end
    -- end)
end

modifier_item_shopkeeper_krekker = class({})
function modifier_item_shopkeeper_krekker:IsHidden() return false end
function modifier_item_shopkeeper_krekker:IsPurgable() return false end
function modifier_item_shopkeeper_krekker:DeclareFunctions()
	return
    {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION
    }
end
function modifier_item_shopkeeper_krekker:GetOverrideAnimation()
	return ACT_DOTA_TELEPORT
end

modifier_item_shopkeeper_krekker_handler = class({})
function modifier_item_shopkeeper_krekker_handler:IsPurgable() return false end
function modifier_item_shopkeeper_krekker_handler:IsHidden() return true end
function modifier_item_shopkeeper_krekker_handler:IsPurgeException() return false end
function modifier_item_shopkeeper_krekker_handler:RemoveOnDeath() return false end
function modifier_item_shopkeeper_krekker_handler:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_shopkeeper_krekker_handler:OnCreated()
    if not IsServer() then return end
    if self:GetParent():IsIllusion() then return end
    self.item_interval = self:GetAbility():GetSpecialValueFor("item_interval") + 1
    self:OnIntervalThink()
    self:StartIntervalThink(1)
end

function modifier_item_shopkeeper_krekker_handler:OnIntervalThink()
    if not IsServer() then return end
    self.item_interval = self.item_interval - 1
    CustomGameEventManager:Send_ServerToAllClients("shopkeeper_item_time_update", {item_entindex = self:GetAbility():entindex(), item_interval = self.item_interval})
    if self.item_interval <= 0 then
        self:Destroy()
    end
end

function modifier_item_shopkeeper_krekker_handler:OnDestroy()
    if not IsServer() then return end
    if self:GetAbility() and not self:GetAbility():IsNull() then
        UTIL_Remove(self:GetAbility())
    end
    CustomGameEventManager:Send_ServerToAllClients("shopkeeper_item_time_destroy", {item_entindex = self:GetAbility():entindex()})
end

modifier_item_shopkeeper_krekker_thinker = class({})
function modifier_item_shopkeeper_krekker_thinker:IsPurgable() return false end
function modifier_item_shopkeeper_krekker_thinker:IsPurgeException() return false end
function modifier_item_shopkeeper_krekker_thinker:OnCreated()
    if not IsServer() then return end
    self.viewer = AddFOWViewer(self:GetCaster():GetTeamNumber(), self:GetParent():GetAbsOrigin(), 200, 3, false)
end
function modifier_item_shopkeeper_krekker_thinker:OnDestroy()
    if not IsServer() then return end
    if self.viewer then
        RemoveFOWViewer(self:GetCaster():GetTeamNumber(), self.viewer)
    end
end
function modifier_item_shopkeeper_krekker_thinker:CheckState()
    return
    {
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_OUT_OF_GAME] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true
    }
end