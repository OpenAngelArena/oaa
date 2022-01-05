-- defines item_reduction_orb_1
-- defines item_reduction_orb_3
-- defines modifier_item_preemptive_damage_reduction
LinkLuaModifier( "modifier_item_preemptive_damage_reduction", "items/reflex/preemptive_damage_block.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_generic_bonus", "modifiers/modifier_generic_bonus.lua", LUA_MODIFIER_MOTION_NONE )

------------------------------------------------------------------------

item_reduction_orb_1 = class(ItemBaseClass)
item_reduction_orb_2 = item_reduction_orb_1
item_reduction_orb_3 = item_reduction_orb_1

function item_reduction_orb_1:GetIntrinsicModifierName()
  return 'modifier_generic_bonus'
end

function item_reduction_orb_1:OnSpellStart()
  local caster = self:GetCaster()
  local duration = self:GetSpecialValueFor("duration")

  -- for damage-to-heal
  caster:AddNewModifier(caster, self, 'modifier_item_preemptive_damage_reduction', { duration = duration })
end

function item_reduction_orb_1:ProcsMagicStick ()
  return false
end

------------------------------------------------------------------------

modifier_item_preemptive_damage_reduction = class(ModifierBaseClass)

function modifier_item_preemptive_damage_reduction:IsHidden()
  return false
end

function modifier_item_preemptive_damage_reduction:IsDebuff()
  return false
end

function modifier_item_preemptive_damage_reduction:IsPurgable()
  return false
end

function modifier_item_preemptive_damage_reduction:OnCreated()
  self.damageheal = 50
  self.damageReduction = 100
  self.endHeal = 0

  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.damageheal = ability:GetSpecialValueFor("damage_as_healing")
    self.damageReduction = ability:GetSpecialValueFor("damage_reduction")
  end
end

function modifier_item_preemptive_damage_reduction:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.damageheal = ability:GetSpecialValueFor("damage_as_healing")
    self.damageReduction = ability:GetSpecialValueFor("damage_reduction")
  end
end

function modifier_item_preemptive_damage_reduction:OnDestroy()
  if IsServer() then
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local amountToHeal = self.endHeal

    parent:Heal(amountToHeal, ability)
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, parent, amountToHeal, nil)
  end
end

function modifier_item_preemptive_damage_reduction:DeclareFunctions()
  return {
    --MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
    MODIFIER_PROPERTY_MODEL_SCALE
  }
end

--function modifier_item_preemptive_damage_reduction:GetModifierIncomingDamage_Percentage(event)
  --[[
    % reduction!
    process_procs: true
    order_type: 0
    issuer_player_index: 1177213984
    target: table: 0x006df7a0
    damage_category: 1
    reincarnate: false
    damage: 6.9628648757935
    ignore_invis: false
    attacker: table: 0x00537470
    ranged_attack": false
    record: 12
    do_not_consume: false
    damage_type: 1
    activity: -1
    heart_regen_applied: false
    diffusal_applied: false
    distance: 0
    no_attack_cooldown: false
    damage_flags: 0
    original_damage: 10
    cost: 0
    gain: 0
    basher_tested: false
    fail_type: 0
  ]]

  --self.endHeal = self.endHeal + event.original_damage * self.damageheal / 100

  --return self.damageReduction * -1
--end

function modifier_item_preemptive_damage_reduction:GetModifierTotal_ConstantBlock(event)
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  local damage = event.damage

  self.endHeal = self.endHeal + damage * self.damageheal / 100

  local block_amount = damage * self.damageReduction / 100

  if block_amount > 0 then
    -- Visual effect
    local alert_type = OVERHEAD_ALERT_MAGICAL_BLOCK
    if event.damage_type == DAMAGE_TYPE_PHYSICAL then
      alert_type = OVERHEAD_ALERT_BLOCK
    end

    SendOverheadEventMessage(nil, alert_type, parent, block_amount, nil)
  end

  return block_amount
end

function modifier_item_preemptive_damage_reduction:GetModifierModelScale()
  return -40
end

function modifier_item_preemptive_damage_reduction:GetTexture()
  return "custom/reduction_orb_3"
end
