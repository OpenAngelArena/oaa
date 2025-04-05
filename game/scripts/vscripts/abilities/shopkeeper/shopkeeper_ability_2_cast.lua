shopkeeper_ability_2_cast = class({})

function shopkeeper_ability_2_cast:OnSpellStart()
    if not IsServer() then return end
    self:GetCaster():EmitSound("ShopKeeper.Hero_sound_14")
    self:GetCaster():EmitSound("ShopKeeper.Hero_sound_8")
    self.callback_custom()
end

function shopkeeper_ability_2_cast:GetChannelAnimation()
    return ACT_DOTA_GENERIC_CHANNEL_1
end

function shopkeeper_ability_2_cast:IsHiddenAbilityCastable()
    return true
end

function shopkeeper_ability_2_cast:OnChannelThink(fInterval)
    if self:GetCaster():IsRooted() then
        self:GetCaster():Stop()
        self:GetCaster():Interrupt()
    end
end

function shopkeeper_ability_2_cast:OnChannelFinish(bInterrupted)
    local hero = self:GetCaster()
    self:GetCaster():StopSound("ShopKeeper.Hero_sound_8")
    local ability = self.original_item
    if ability == nil then return end
    if ability.teleport_center and not ability.teleport_center:IsNull() then
        ability.teleport_center:Destroy()
    end
	self:GetCaster():RemoveGesture(ACT_DOTA_TELEPORT)
    if ability.teleportFromEffect then
        ParticleManager:DestroyParticle(ability.teleportFromEffect, false)
        ParticleManager:ReleaseParticleIndex(ability.teleportFromEffect)
    end
    if ability.teleportToEffect then
        ParticleManager:DestroyParticle(ability.teleportToEffect, false)
        ParticleManager:ReleaseParticleIndex(ability.teleportToEffect)
    end
    if not bInterrupted then
        EmitSoundOnLocationWithCaster(ability.point_start, "ShopKeeper.Hero_sound_13", self:GetCaster())
	    self:GetCaster():SetAbsOrigin(ability.point)
	    FindClearSpaceForUnit(self:GetCaster(), ability.point, true)
	    self:GetCaster():Stop()
	    self:GetCaster():Interrupt()
	    self:GetCaster():StartGesture(ACT_DOTA_TELEPORT_END)
        self:GetCaster():EmitSound("ShopKeeper.Hero_sound_13")
    end
    self:GetCaster():RemoveModifierByName("modifier_item_shopkeeper_krekker")
    if ability:GetCurrentCharges() > 1 then
        ability:SpendCharge(0)
    else
        UTIL_Remove(ability)
    end
end