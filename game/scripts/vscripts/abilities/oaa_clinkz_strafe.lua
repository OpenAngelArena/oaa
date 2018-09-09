clinkz_strafe_oaa = class( AbilityBaseClass )

--------------------------------------------------------------------------------

if IsServer() then

  function clinkz_strafe_oaa:OnSpellStart()
    local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor( "duration" )
    local attack_speed_bonus_pct = self:GetSpecialValueFor( "attack_speed_bonus_pct" )

    caster:AddNewModifier( self:GetCaster(), self, "modifier_clinkz_strafe", {
      duration = duration
    } )

    caster:EmitSound("Hero_Clinkz.Strafe")
  end

end

--------------------------------------------------------------------------------

function clinkz_strafe_oaa:GetCooldown( level )
  local caster = self:GetCaster()

  local talent_cooldown_reduction = caster:FindTalentValue("special_bonus_clinkz_strafe_cooldown")
  return self.BaseClass.GetCooldown( self, level ) - talent_cooldown_reduction
end
