LinkLuaModifier("modifier_item_craggy_coat_active", "items/neutral/craggy_coat.lua", LUA_MODIFIER_MOTION_NONE)

item_craggy_coat_oaa = class(ItemBaseClass)

function item_craggy_coat_oaa:OnSpellStart()
  local caster = self:GetCaster()

  -- Apply the buff
  caster:AddNewModifier(caster, self, "modifier_item_craggy_coat_active", {duration = self:GetSpecialValueFor("duration")})

  -- Particle
  local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_tiny/tiny_transform.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
  ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
  ParticleManager:ReleaseParticleIndex(particle)

  -- Sound
  caster:EmitSound("Tiny.Grow")
end

---------------------------------------------------------------------------------------------------

modifier_item_craggy_coat_active = class(ModifierBaseClass)

function modifier_item_craggy_coat_active:IsHidden()
  return false
end

function modifier_item_craggy_coat_active:IsDebuff()
  return false
end

function modifier_item_craggy_coat_active:IsPurgable()
  return true
end

function modifier_item_craggy_coat_active:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
  }
end

if IsServer() then
  function modifier_item_craggy_coat_active:GetModifierTotal_ConstantBlock(event)
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local attacker = event.attacker

    -- Check if attacker and ability exist
    if not attacker or attacker:IsNull() or not ability or ability:IsNull() then
      return 0
    end

    local original_dmg = event.original_damage
    local dmg_after_reductions = event.damage
    local damage_type = event.damage_type

    -- Check if damage is somehow 0 or negative
    if dmg_after_reductions <= 0 then
      return 0
    end

    -- Don't do anything if damage is already physical
    if damage_type == DAMAGE_TYPE_PHYSICAL then
      return 0
    end

    local conversion_pct = ability:GetSpecialValueFor("damage_conversion_pct")

    -- "Convert" a part of the original damage to physical
    local damage_table = {
      victim = parent,
      attacker = attacker,
      damage = original_dmg * conversion_pct / 100,
      damage_type = DAMAGE_TYPE_PHYSICAL,
      damage_flags = event.damage_flags,
      ability = event.inflictor,
    }

    ApplyDamage(damage_table)

    -- Block part of the 'damage after reductions' (magic or pure) to mimic damage conversion
    local block_amount = dmg_after_reductions * conversion_pct / 100

    if block_amount > 0 then
      -- Visual effect
      SendOverheadEventMessage(nil, OVERHEAD_ALERT_BLOCK, parent, block_amount, nil)
    end

    return block_amount
  end
end
