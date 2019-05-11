monkey_king_wukongs_command_oaa = class(AbilityBaseClass)

LinkLuaModifier("modifier_wukongs_command_oaa_buff", "abilities/oaa_wukongs_command", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_wukongs_command_oaa_thinker", "abilities/oaa_wukongs_command", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_monkey_clone_oaa", "abilities/oaa_wukongs_command", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_monkey_clone_oaa_status_effect", "abilities/oaa_wukongs_command", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_monkey_clone_oaa_idle_effect", "abilities/oaa_wukongs_command", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_monkey_clone_oaa_hidden", "abilities/oaa_wukongs_command", LUA_MODIFIER_MOTION_NONE)

if IsServer() then
  -- For Rubick OnUpgrade never happens, that's why OnStolen is needed but then it will lag
  function monkey_king_wukongs_command_oaa:OnUpgrade()
    if self.clones == nil and self:GetCaster():IsRealHero() then
      local unit_name = "npc_dota_monkey_clone_oaa"
      local max_number_of_rings = 3
      local max_number_of_monkeys_per_ring = math.max(9, self:GetSpecialValueFor("num_second_soldiers"))
      local hidden_point = Vector(-10000,-10000,-10000)
      local caster = self:GetCaster()
      -- Initialize tables
      self.clones={}
      self.clones[1]={}
      self.clones[2]={}
      self.clones[3]={}
      -- Populate tables
      for i= 1, max_number_of_rings do
        self.clones[i]["top"] = CreateUnitByName(unit_name, hidden_point, false, caster, caster:GetOwner(), caster:GetTeam())
        self.clones[i]["top"]:SetOwner(caster)
        self.clones[i]["top"]:AddNewModifier(caster, self, "modifier_monkey_clone_oaa_hidden", {})
        self.clones[i]["top"]:AddNewModifier(caster, self, "modifier_monkey_clone_oaa", {})
        print("[MONKEY KING WUKONG'S COMMAND] Creating unit: " .. unit_name .. " at: self.clones[" .. tostring(i) .. "]['top']")
        for j=1, max_number_of_monkeys_per_ring-1 do
          self.clones[i][j] = CreateUnitByName(unit_name, hidden_point, false, caster, caster:GetOwner(), caster:GetTeam())
          self.clones[i][j]:SetOwner(caster)
          self.clones[i][j]:AddNewModifier(caster, self, "modifier_monkey_clone_oaa_hidden", {})
          self.clones[i][j]:AddNewModifier(caster, self, "modifier_monkey_clone_oaa", {})
          print("[MONKEY KING WUKONG'S COMMAND] Creating unit: " .. unit_name .. " at: self.clones[" .. tostring(i) .. "][" .. tostring(j) .. "]")
        end
      end
      -- Update items of the clones for the first time
      self:OnInventoryContentsChanged()
    end
  end

  function monkey_king_wukongs_command_oaa:OnInventoryContentsChanged()
    local caster = self:GetCaster()
    -- Do this only if Wukong's command is not active to prevent lag (Wukong's Command is active only if caster has a buff)
    if self.clones and (not caster:HasModifier("modifier_wukongs_command_oaa_buff")) and caster:IsRealHero() then
      local max_number_of_rings = 3
      local max_number_of_monkeys_per_ring = math.max(9, self:GetSpecialValueFor("num_second_soldiers"))
      -- Update items of the clones
      for i= 1, max_number_of_rings do
        self:CopyCasterItems(self.clones[i]["top"], caster)
        for j=1, max_number_of_monkeys_per_ring-1 do
          self:CopyCasterItems(self.clones[i][j], caster)
        end
      end
    end
  end
end

function monkey_king_wukongs_command_oaa:CopyCasterItems(parent, caster)
  local banned_items = {
    -- prevent nutty passive gpm shenanigans
    "item_arcane_origin",
    "item_greater_arcane_boots",
    "item_greater_arcane_boots_2",
    "item_greater_arcane_boots_3",
    "item_greater_arcane_boots_4",
    "item_greater_guardian_greaves",
    "item_greater_guardian_greaves_2",
    "item_greater_guardian_greaves_3",
    "item_greater_guardian_greaves_4",
    -- none of the other boots matter for MK...
    "item_abyssal_blade",
    "item_abyssal_blade_2",
    "item_abyssal_blade_3",
    "item_abyssal_blade_4",
    "item_abyssal_blade_5",
    "item_rapier",
    "item_gem",
    "item_courier",
    "item_upgrade_core",
    "item_upgrade_core_2",
    "item_upgrade_core_3",
    "item_upgrade_core_4"
  }
  -- Recreate items of the caster (ignore backpack and stash)
  for item_slot = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
    local item = caster:GetItemInSlot(item_slot)
    local clone_item = parent:GetItemInSlot(item_slot)
    if item == nil and clone_item then parent:RemoveItem(clone_item) end
    if item then
      local item_name = item:GetName()
      local skip = false
      if clone_item then
        if clone_item:GetName() == item_name then
          skip = true
        else
          parent:RemoveItem(clone_item)
        end
      end
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

      -- Create new Item
      if not skip then
        local new_item = CreateItem(item_name, parent, parent)
        --print("copy item: " .. item_name)
        parent:AddItem(new_item)

        -- Set correct inventory position
        if parent:GetItemInSlot(item_slot) ~= new_item then
          for slot = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
            if parent:GetItemInSlot(slot) == new_item then
              parent:SwapItems(slot, item_slot)
              break
            end
          end
        end

        new_item:SetStacksWithOtherOwners(true)
        new_item:SetPurchaser(nil)

        if new_item:IsToggle() and item:GetToggleState() then
          new_item:ToggleAbility()
        end
      end
    end
  end
end

function monkey_king_wukongs_command_oaa:OnAbilityPhaseStart()
  local caster = self:GetCaster()
  EmitSoundOn("Hero_MonkeyKing.FurArmy.Channel", caster)
  -- Particle during casting
  if IsServer() then
    self.castHandle = ParticleManager:CreateParticle("particles/units/heroes/hero_monkey_king/monkey_king_fur_army_cast.vpcf", PATTACH_ABSORIGIN, caster)
  end
  return true
end

function monkey_king_wukongs_command_oaa:OnAbilityPhaseInterrupted()
  StopSoundOn("Hero_MonkeyKing.FurArmy.Channel", self:GetCaster())
  if IsServer() then
    if self.castHandle then
      ParticleManager:DestroyParticle(self.castHandle, true)
      ParticleManager:ReleaseParticleIndex(self.castHandle)
      self.castHandle = nil
    end
  end
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

  -- Sound
  EmitSoundOn("Hero_MonkeyKing.FurArmy", caster)

  if IsServer() then
    -- Remove ability phase (cast) particle
    if self.castHandle then
      ParticleManager:DestroyParticle(self.castHandle, false)
      ParticleManager:ReleaseParticleIndex(self.castHandle)
      self.castHandle = nil
    end

    -- Remove previos instance of Wukongs Command
    if caster.monkeys_thinker and not caster.monkeys_thinker:IsNull() then
      caster.monkeys_thinker:Destroy()
    end

    -- Thinker
    CreateModifierThinker(caster, self, "modifier_wukongs_command_oaa_thinker", {duration = self:GetSpecialValueFor("duration")}, center, caster:GetTeamNumber(), false)

    if self.clones == nil then
      print("[MONKEY KING WUKONG'S COMMAND] Clones/Soldiers were not created when Monkey King spawned for the first time!")
      self.clones={}
      self.clones[1]={}
      self.clones[2]={}
      self.clones[3]={}
    end

    -- Inner Ring:
    self:CreateMonkeyRing(unit_name, first_ring, caster, center, first_ring_radius, 1)
    -- Outer Ring:
    self:CreateMonkeyRing(unit_name, second_ring, caster, center, second_ring_radius, 2)
    -- Extra Ring with the talent:
    self:CreateMonkeyRing(unit_name, third_ring, caster, center, third_ring_radius, 3)
  end
end

function monkey_king_wukongs_command_oaa:CreateMonkeyRing(unit_name, number, caster, center, radius, ringNumber)
  if number == 0 or radius == 0 then
    return
  end

  local top_direction = Vector(0,1,0)
  local top_point = center + top_direction*radius

  if self.clones[ringNumber]["top"] == nil or self.clones[ringNumber]["top"]:IsNull() or not self.clones[ringNumber]["top"]:IsAlive() then
    print("[MONKEY KING WUKONG'S COMMAND] Monkey on the top point doesn't exist for some reason!")
    self.clones[ringNumber]["top"] = CreateUnitByName(unit_name, top_point, false, caster, caster:GetOwner(), caster:GetTeam())
    self.clones[ringNumber]["top"]:SetOwner(caster)
  end
  local top_monkey = self.clones[ringNumber]["top"]
  -- setting the origin is causing a wierd visual glitch I could not fix
  top_monkey:SetAbsOrigin(GetGroundPosition(top_point, top_monkey))
  top_monkey:FaceTowards(center)
  top_monkey:RemoveNoDraw()
  top_monkey:SetBaseDamageMax(caster:GetBaseDamageMax())
  top_monkey:SetBaseDamageMin(caster:GetBaseDamageMin())
  top_monkey:RemoveModifierByName("modifier_monkey_clone_oaa_hidden")

  -- Create remaining monkeys
  local angle_degrees = 360/number
  for i=1, number-1 do
    -- Rotate a point around center for angle_degrees to get a new point
    local point = RotatePosition(center, QAngle(0,i*angle_degrees,0), top_point)
    if self.clones[ringNumber][i] == nil or self.clones[ringNumber][i]:IsNull() or not self.clones[ringNumber][i]:IsAlive() then
      print("[MONKEY KING WUKONG'S COMMAND] Monkey number "..i.."in ring "..ringNumber.." doesn't exist for some reason!")
      self.clones[ringNumber][i] = CreateUnitByName(unit_name, point, false, caster, caster:GetOwner(), caster:GetTeam())
      self.clones[ringNumber][i]:SetOwner(caster)
    end
    local monkey = self.clones[ringNumber][i]
    -- setting the origin is causing a wierd visual glitch I could not fix
    monkey:SetAbsOrigin(GetGroundPosition(point, monkey))
    monkey:FaceTowards(center)
    monkey:RemoveNoDraw()
    monkey:SetBaseDamageMax(caster:GetBaseDamageMax())
    monkey:SetBaseDamageMin(caster:GetBaseDamageMin())
    monkey:RemoveModifierByName("modifier_monkey_clone_oaa_hidden")
  end
end

function monkey_king_wukongs_command_oaa:RemoveMonkeys(caster)
  local unit_name = "npc_dota_monkey_clone_oaa"
  -- Find all monkeys belonging to the caster on the map and hide them
  local allied_units = FindUnitsInRadius(caster:GetTeamNumber(), Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, bit.bor(DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD), FIND_ANY_ORDER, false)
  for _,unit in pairs(allied_units) do
    if unit:GetUnitName() == unit_name then
      if IsServer() then
        local handle = ParticleManager:CreateParticle("particles/units/heroes/hero_monkey_king/monkey_king_fur_army_destroy.vpcf", PATTACH_ABSORIGIN, caster)
        ParticleManager:SetParticleControl(handle, 0, unit:GetAbsOrigin())
        -- for some weid reason calling DestroyParticle(... , false) do destroy the particle immediatly
        -- thanks volvo
        Timers:CreateTimer(3,function()
          ParticleManager:DestroyParticle(handle, false)
          ParticleManager:ReleaseParticleIndex(handle)
        end)
      end
      unit:AddNoDraw()
      unit:SetAbsOrigin(Vector(-10000,-10000,-10000))
      unit:AddNewModifier(caster, self, "modifier_monkey_clone_oaa_hidden", {})
    end
  end

  -- Sounds
  StopSoundOn("Hero_MonkeyKing.FurArmy", caster)
  EmitSoundOn("Hero_MonkeyKing.FurArmy.End", caster)
end

function monkey_king_wukongs_command_oaa:ProcsMagicStick()
  return true
end

-- Rubick creates lag when he steals and casts a spell
function monkey_king_wukongs_command_oaa:IsStealable()
  return false
end

---------------------------------------------------------------------------------------------------

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

  if IsServer() then
    caster.monkeys_thinker = self
    -- Ring particle
    self.particleHandler = ParticleManager:CreateParticle("particles/units/heroes/hero_monkey_king/monkey_king_furarmy_ring.vpcf", PATTACH_ABSORIGIN, caster)
    ParticleManager:SetParticleControl(self.particleHandler, 0, self:GetParent():GetOrigin())
    ParticleManager:SetParticleControl(self.particleHandler, 1, Vector(self:GetAuraRadius(),0,0))
  end
  -- Start checking caster for the buff
  self:StartIntervalThink(0.1)
end

function modifier_wukongs_command_oaa_thinker:OnIntervalThink()
  local caster = self:GetCaster()
  if not caster:HasModifier("modifier_wukongs_command_oaa_buff") then
    self:StartIntervalThink(-1)
    self:SetDuration(0.01, false)
  end
end

function modifier_wukongs_command_oaa_thinker:OnDeath(event)
  if IsServer() then
    if event.unit == self:GetCaster() then
      self:StartIntervalThink(-1)
      self:SetDuration(0.01, false)
    end
  end
end

function modifier_wukongs_command_oaa_thinker:OnDestroy()
  if IsServer() then
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    ability:RemoveMonkeys(caster)

    ParticleManager:DestroyParticle(self.particleHandler, false);
    ParticleManager:ReleaseParticleIndex(self.particleHandler)
    self.particleHandler = nil
  end
end

---------------------------------------------------------------------------------------------------

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

---------------------------------------------------------------------------------------------------

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

  if IsServer() then
    parent:SetNeverMoveToClearSpace(true)

    -- animation stances
    parent:AddNewModifier(caster, self:GetAbility(), "modifier_monkey_clone_oaa_idle_effect", {})
    AddAnimationTranslate(parent, "attack_normal_range")
  end
end

function modifier_monkey_clone_oaa:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_FIXED_ATTACK_RATE,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
    MODIFIER_EVENT_ON_ATTACK_START
  }
  return funcs
end

function modifier_monkey_clone_oaa:GetStatusEffectName()
  return "particles/status_fx/status_effect_monkey_king_fur_army.vpcf"
end

function modifier_monkey_clone_oaa:GetModifierFixedAttackRate(params)
  local ability = self:GetAbility()
  return ability:GetSpecialValueFor("attack_interval")
end

function modifier_monkey_clone_oaa:OnAttackLanded(keys)
  if IsServer() then
    local parent = self:GetParent()
    if parent == keys.attacker then
      local castHandle = ParticleManager:CreateParticle("particles/units/heroes/hero_monkey_king/monkey_king_fur_army_attack.vpcf", PATTACH_ABSORIGIN, parent)

      Timers:CreateTimer(2, function()
        ParticleManager:DestroyParticle(castHandle, false)
        ParticleManager:ReleaseParticleIndex(castHandle)
      end)
    end
  end
end

function modifier_monkey_clone_oaa:OnAttackStart(keys)
  if IsServer() then
    local parent = self:GetParent()
    if parent == keys.attacker then
      local ability = self:GetAbility()
      local attack_interval = ability:GetSpecialValueFor("attack_interval")
	    local attack_backswing = 0.2
      parent:AddNewModifier(self:GetCaster(), ability, "modifier_monkey_clone_oaa_status_effect", {duration = attack_backswing + attack_interval})
      parent:RemoveModifierByName("modifier_monkey_clone_oaa_idle_effect")
    end
  end
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

---------------------------------------------------------------------------------------------------

modifier_monkey_clone_oaa_status_effect = class(ModifierBaseClass)

function modifier_monkey_clone_oaa_status_effect:IsHidden()
  return true
end

function modifier_monkey_clone_oaa_status_effect:IsPurgable()
  return false
end

function modifier_monkey_clone_oaa_status_effect:GetStatusEffectName()
  return "particles/status_fx/status_effect_monkey_king_spring_slow.vpcf"
end

function modifier_monkey_clone_oaa_status_effect:StatusEffectPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA
end

if IsServer() then
  function modifier_monkey_clone_oaa_status_effect:OnDestroy()
    self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_monkey_clone_oaa_idle_effect", {})
  end
end

---------------------------------------------------------------------------------------------------

modifier_monkey_clone_oaa_idle_effect = class(ModifierBaseClass)

function modifier_monkey_clone_oaa_idle_effect:IsHidden()
  return true
end

function modifier_monkey_clone_oaa_idle_effect:IsPurgable()
  return false
end

function modifier_monkey_clone_oaa_idle_effect:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS
  }
  return funcs
end

function modifier_monkey_clone_oaa_idle_effect:GetActivityTranslationModifiers()
  return "fur_army_soldier"
end

---------------------------------------------------------------------------------------------------

modifier_monkey_clone_oaa_hidden = class(ModifierBaseClass)

function modifier_monkey_clone_oaa_hidden:IsHidden()
  return true
end

function modifier_monkey_clone_oaa_hidden:IsDebuff()
  return false
end

function modifier_monkey_clone_oaa_hidden:IsPurgable()
  return false
end

function modifier_monkey_clone_oaa_hidden:CheckState()
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
    [MODIFIER_STATE_BLIND] = true,
    [MODIFIER_STATE_DISARMED] = true,
    [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
  }
  return state
end
