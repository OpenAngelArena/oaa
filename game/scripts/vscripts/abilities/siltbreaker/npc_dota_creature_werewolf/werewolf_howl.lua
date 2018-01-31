werewolf_howl = class(AbilityBaseClass)

----------------------------------------

LinkLuaModifier( "modifier_werewolf_howl_aura", "modifiers/modifier_werewolf_howl_aura", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_werewolf_howl_aura_effect", "modifiers/modifier_werewolf_howl_aura_effect", LUA_MODIFIER_MOTION_NONE )

----------------------------------------

function werewolf_howl:OnSpellStart()
  local caster = self:GetCaster()
	caster:EmitSound("LycanBoss.Howl")

	local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_lycan/lycan_howl_cast.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
	ParticleManager:SetParticleControlEnt( nFXIndex, 1, caster, PATTACH_POINT_FOLLOW, "attach_mouth", caster:GetOrigin(), true )
	ParticleManager:ReleaseParticleIndex( nFXIndex )

	caster:AddNewModifier( caster, self, "modifier_werewolf_howl_aura", { duration = self:GetSpecialValueFor( "duration" ) } )
end

----------------------------------------
