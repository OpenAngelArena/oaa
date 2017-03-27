
LinkLuaModifier("modifier_boss_charger_charge", "abilities/charger/boss_charger_charge.lua", LUA_MODIFIER_MOTION_BOTH) --- PARTH WEVY IMPARTAYT

boss_charger_charge = class({})

function boss_charger_charge:OnSpellStart()
  local cursorPosition = self:GetCursorPosition()
  local caster = self:GetCaster()
  local origin = caster:GetAbsOrigin()
  local direction = (origin - cursorPosition)
  local hTarget = self:GetCursorTarget()

  caster:AddNewModifier(caster, self, "modifier_boss_charger_charge", {
    duration = 0.5,
    direction = direction:Normalized()
  })

end

modifier_boss_charger_charge = class({})

function modifier_boss_charger_charge:OnIntervalThink()
  if not IsServer() then
    return
  end

  local origin = self:GetCaster():GetAbsOrigin()
  self:GetCaster():SetAbsOrigin(origin + (self.direction * 50))
end

function modifier_boss_charger_charge:OnCreated(keys)
  if IsServer() then
    self.direction = keys.direction
    self:StartIntervalThink(0.1)
  end
end
