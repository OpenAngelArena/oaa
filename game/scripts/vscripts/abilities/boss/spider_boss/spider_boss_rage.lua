LinkLuaModifier( "modifier_spider_boss_rage", "abilities/boss/spider_boss/modifier_spider_boss_rage", LUA_MODIFIER_MOTION_NONE )

spider_boss_rage = class( AbilityBaseClass )

function spider_boss_rage:OnSpellStart()
  self:GetCaster():AddNewModifier( self:GetCaster(), self, "modifier_spider_boss_rage", { duration = self:GetSpecialValueFor( "duration" ) } )
end
