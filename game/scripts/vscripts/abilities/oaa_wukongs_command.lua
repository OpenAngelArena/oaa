monkey_king_wukongs_command_oaa = class(AbilityBaseClass)

LinkLuaModifier("modifier_wukongs_command_oaa_buff", "abilities/oaa_wukongs_command", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_wukongs_command_oaa_thinker", "abilities/oaa_wukongs_command", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_monkey_clone_oaa", "abilities/oaa_wukongs_command", LUA_MODIFIER_MOTION_NONE)

function monkey_king_wukongs_command_oaa:OnAbilityPhaseStart()
  EmitSoundOn("Hero_MonkeyKing.FurArmy.Channel", self:GetCaster())
  return true
end

function monkey_king_wukongs_command_oaa:OnAbilityPhaseInterrupted()
  StopSoundOn("Hero_MonkeyKing.FurArmy.Channel", self:GetCaster())
end

function monkey_king_wukongs_command_oaa:GetAOERadius()
  local caster = self:GetCaster()

  return math.max(caster:FindTalentValue("special_bonus_unique_monkey_king_6", "value"), self:GetSpecialValueFor("second_radius"))
end

function monkey_king_wukongs_command_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local center = self:GetCursorPosition()
  local unit_name = "npc_dota_monkey_clone_oaa"

  local first_ring_radius = self:GetSpecialValueFor("first_radius")
  local second_ring_radius = self:GetSpecialValueFor("second_radius")
  local third_ring_radius = 0
  self.active_radius = second_ring_radius

  -- How many monkeys on each ring
  local first_ring = self:GetSpecialValueFor("num_first_soldiers")
  local second_ring = self:GetSpecialValueFor("num_second_soldiers")
  local third_ring = 0

  if caster:HasTalent("special_bonus_unique_monkey_king_6") then
    third_ring_radius = caster:FindTalentValue("special_bonus_unique_monkey_king_6", "value")
    third_ring = caster:FindTalentValue("special_bonus_unique_monkey_king_6", "value2")
    self.active_radius = third_ring_radius
  end
  -- Particle
  --"particles/units/heroes/hero_monkey_king/monkey_king_fur_army_cast.vpcf"
  -- Sound
  EmitSoundOn("Hero_MonkeyKing.FurArmy", caster)
   -- Remove previos instance of Wukongs Command
  if caster.monkeys_thinker and not caster.monkeys_thinker:IsNull() then
    caster.monkeys_thinker:Destroy()
  end
  -- Thinker
  CreateModifierThinker(caster, self, "modifier_wukongs_command_oaa_thinker", {duration = self:GetSpecialValueFor("duration")}, center, caster:GetTeamNumber(), false)
  -- Inner Ring:
  self:CreateMonkeyRing(unit_name, first_ring, caster, center, first_ring_radius)
  -- Outer Ring:
  self:CreateMonkeyRing(unit_name, second_ring, caster, center, second_ring_radius)
  -- Extra Ring with the talent:
  self:CreateMonkeyRing(unit_name, third_ring, caster, center, third_ring_radius)
end

function monkey_king_wukongs_command_oaa:CreateMonkeyRing(unit_name, number, caster, center, radius)
  if number == 0 or radius == 0 then
    return
  end
  --"particles/units/heroes/hero_monkey_king/monkey_king_furarmy_ring.vpcf"
  local top_direction = Vector(0,1,0)
  local top_point = center + top_direction*radius
  local top_monkey = CreateUnitByName(unit_name, top_point, false, caster, caster:GetOwner(), caster:GetTeam())
  top_monkey:SetOwner(caster)
  top_monkey:AddNewModifier(caster, self, "modifier_monkey_clone_oaa", {})
  local angle_degrees = 360/number
  for i=1, number-1 do
    -- Rotate a point around center for angle_degrees to get a new point
    local point = RotatePosition(center, QAngle(0,i*angle_degrees,0), top_point)
    local monkey = CreateUnitByName(unit_name, point, false, caster, caster:GetOwner(), caster:GetTeam())
    monkey:SetOwner(caster)
    monkey:AddNewModifier(caster, self, "modifier_monkey_clone_oaa", {})
  end
end

function monkey_king_wukongs_command_oaa:RemoveMonkeys(caster)
  local unit_name = "npc_dota_monkey_clone_oaa"
  -- Find all monkeys belonging to the caster on the map and kill them
  local allied_units = FindUnitsInRadius(caster:GetTeamNumber(), Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, bit.bor(DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD), FIND_ANY_ORDER, false)
  for _,unit in pairs(allied_units) do
    if unit:GetUnitName() == unit_name then
      --"particles/units/heroes/hero_monkey_king/monkey_king_fur_army_destroy.vpcf"
      unit:AddNoDraw()
      unit:AddNewModifier(unit, nil, "modifier_kill", {duration = 0.2})
    end
  end
  -- Sounds
  StopSoundOn("Hero_MonkeyKing.FurArmy", caster)
  EmitSoundOn("Hero_MonkeyKing.FurArmy.End", caster)
end

function monkey_king_wukongs_command_oaa:ProcsMagicStick()
  return true
end

--------------------------------------------------------------------------------

modifier_wukongs_command_oaa_thinker = class(ModifierBaseClass)

function modifier_wukongs_command_oaa_thinker:IsHidden()
  return true
end

function modifier_wukongs_command_oaa_thinker:IsDebuff()
  return false
end

function modifier_wukongs_command_oaa_thinker:IsPurgable()
  return false
end

function modifier_wukongs_command_oaa_thinker:IsAura()
  return true
end

function modifier_wukongs_command_oaa_thinker:GetModifierAura()
  return "modifier_wukongs_command_oaa_buff"
end

function modifier_wukongs_command_oaa_thinker:GetAuraRadius()
  local ability = self:GetAbility()
  return ability.active_radius
end

function modifier_wukongs_command_oaa_thinker:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_wukongs_command_oaa_thinker:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO
end

function modifier_wukongs_command_oaa_thinker:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD)
end

function modifier_wukongs_command_oaa_thinker:GetAuraEntityReject(hEntity)
  if hEntity ~= self:GetCaster() then
    return true
  end
  return false
end

function modifier_wukongs_command_oaa_thinker:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_DEATH,
	}
	return funcs
end

function modifier_wukongs_command_oaa_thinker:OnCreated()
  local caster = self:GetCaster()
  caster.monkeys_thinker = self
  -- Start checking caster for the buff
  self:StartIntervalThink(0.3)
end

function modifier_wukongs_command_oaa_thinker:OnIntervalThink()
  local caster = self:GetCaster()
  local ability = self:GetAbility()
  if not caster:HasModifier("modifier_wukongs_command_oaa_buff") then
    self:StartIntervalThink(-1)
    self:SetDuration(0.1, false)
  end
end

function modifier_wukongs_command_oaa_thinker:OnDeath(event)
  if IsServer() then
    if event.unit == self:GetCaster() then
      local ability = self:GetAbility()
      self:StartIntervalThink(-1)
      self:SetDuration(0.1, false)
    end
  end
end

function modifier_wukongs_command_oaa_thinker:OnDestroy()
  if IsServer() then
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    ability:RemoveMonkeys(caster)
  end
end

--------------------------------------------------------------------------------

modifier_wukongs_command_oaa_buff = class(ModifierBaseClass)

function modifier_wukongs_command_oaa_buff:IsHidden()
  return false
end

function modifier_wukongs_command_oaa_buff:IsDebuff()
  return false
end

function modifier_wukongs_command_oaa_buff:IsPurgable()
  return false
end

function modifier_wukongs_command_oaa_buff:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
  }
  return funcs
end

function modifier_wukongs_command_oaa_buff:GetModifierPhysicalArmorBonus()
  return self:GetAbility():GetSpecialValueFor("bonus_armor") + self:GetCaster():FindTalentValue("special_bonus_unique_monkey_king_4")
end

--------------------------------------------------------------------------------

modifier_monkey_clone_oaa = class(ModifierBaseClass)

function modifier_monkey_clone_oaa:IsHidden()
  return true
end

function modifier_monkey_clone_oaa:IsDebuff()
  return false
end

function modifier_monkey_clone_oaa:IsPurgable()
  return false
end

function modifier_monkey_clone_oaa:OnCreated()
  local caster = self:GetCaster()
  local parent = self:GetParent()
  local ability = self:GetAbility()

  local banned_items = {
    "item_abyssal_blade",
    "item_abyssal_blade_2",
    "item_abyssal_blade_3",
    "item_abyssal_blade_4",
    "item_abyssal_blade_5",
    "item_rapier",
    "item_gem",
    "item_courier"
  }
  if IsServer() then
    for item_slot = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
      local item = caster:GetItemInSlot(item_slot)
      if item then
        local item_name = item:GetName()
        local skip = false

        -- Don't add certain items like Abyssal Blade
        for i= 1, #banned_items do
          if item_name == banned_items[i] then
            skip = true
          end
        end

        -- Dont add items with charges to avoid weird bugs
        if item:RequiresCharges() then
          skip = true
        end

        if not skip then
          local new_item = CreateItem(item_name, parent, parent)
          parent:AddItem(new_item)
          new_item:SetStacksWithOtherOwners(true)
          new_item:SetPurchaser(nil)

          if new_item:IsToggle() and item:GetToggleState() then
            new_item:ToggleAbility()
          end
        end
      end
    end

    parent:SetBaseDamageMax(caster:GetBaseDamageMax())
    parent:SetBaseDamageMin(caster:GetBaseDamageMin())
    parent:SetNeverMoveToClearSpace(true)
	  -- For attacking animations - requires Animations library
    AddAnimationTranslate(parent, "attack_normal_range")
  end
end

function modifier_monkey_clone_oaa:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_FIXED_ATTACK_RATE,
  }
  return funcs
end

function modifier_monkey_clone_oaa:GetModifierFixedAttackRate(params)
  local ability = self:GetAbility()
  return ability:GetSpecialValueFor("attack_interval")
end

function modifier_monkey_clone_oaa:CheckState()
  local state = {
    [MODIFIER_STATE_ROOTED] = true,
    [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    [MODIFIER_STATE_SILENCED] = true,
    [MODIFIER_STATE_MUTED] = true,
    [MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_UNSELECTABLE] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
    [MODIFIER_STATE_OUT_OF_GAME] = true,
  }
  return state
end
