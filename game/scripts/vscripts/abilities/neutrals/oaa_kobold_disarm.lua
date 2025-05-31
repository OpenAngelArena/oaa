
kobold_disarm_oaa = class(AbilityBaseClass)

function kobold_disarm_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()

  if not target then
    return
  end

  -- Don't do anything if target has Linken's effect or it's spell-immune
  if target:TriggerSpellAbsorb(self) or target:IsMagicImmune() then
    return
  end

  target:AddNewModifier(caster, self, "modifier_disarmed", {duration = self:GetSpecialValueFor("duration")})
end

