LinkLuaModifier( "modifier_dire_tower_boss_glyph", "abilities/boss/dire_tower_boss/modifier_dire_tower_boss_glyph", LUA_MODIFIER_MOTION_NONE )

dire_tower_boss_glyph = class(AbilityBaseClass)

--------------------------------------------------------------------------------


function dire_tower_boss_glyph:OnSpellStart()
  local caster = self:GetCaster()

  caster:AddNewModifier( caster, self, "modifier_dire_tower_boss_glyph", { duration = self:GetSpecialValueFor( "glyph_duration" ) } )
  caster:EmitSound("")


end
