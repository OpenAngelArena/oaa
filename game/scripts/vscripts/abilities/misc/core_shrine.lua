LinkLuaModifier( "modifier_core_shrine_effect", "abilities/misc/core_shrine.lua", LUA_MODIFIER_MOTION_NONE )

---------------------------------------------------------------------------------------------------

modifier_core_shrine_effect = class(ModifierBaseClass)

function modifier_core_shrine_effect:OnCreated()
  if IsServer() then
    if self:GetAbility():IsCooldownReady() then
      if self:GetAbility():GetName() == "core_guy_score_limit" then
        --print('Setting stack to 1')
        self:SetStackCount(1)
      else
        --print('Setting stack to 2')
        self:SetStackCount(2)
      end
    else
      --print('Setting stack to 0')
      self:SetStackCount(0)
    end
  end
end

modifier_core_shrine_effect.OnRefresh = modifier_core_shrine_effect.OnCreated

function modifier_core_shrine_effect:GetEffectName()
  local stackCount = self:GetStackCount()
  --print(stackCount)
  if stackCount == 0 then
    return
  end
  if stackCount == 1 then
    return "particles/misc/aqua_oaa_rays.vpcf"
  elseif stackCount == 2 then
    return "particles/misc/ruby_oaa_rays.vpcf"
  end
end

---------------------------------------------------------------------------------------------------

modifier_core_shrine = class(ModifierBaseClass)

function modifier_core_shrine:IsHidden()
  return true
end

function modifier_core_shrine:IsPurgable()
  return false
end

function modifier_core_shrine:OnCreated()
  self.ordered_heroes = {}
  if IsServer() then
    self:GetAbility():StartCooldown(self:GetAbility():GetCooldown())
    self:SetStackCount(LIMIT_INCREASE_STARTING_COOLDOWN)
    self:StartIntervalThink(0.1)
  end
end

modifier_core_shrine.OnRefresh = modifier_core_shrine.OnCreated

function modifier_core_shrine:OnIntervalThink()
  local parent = self:GetParent() -- shrine
  local ability = self:GetAbility()
  if not ability then
    self:StartIntervalThink(-1)
    return
  end

  -- Particle
  if ability:IsCooldownReady() then
    if not self.effectMod then
      self.effectMod = parent:AddNewModifier(parent, ability, "modifier_core_shrine_effect", {})
    end
  else
    self.effectMod = nil
    parent:RemoveModifierByName("modifier_core_shrine_effect")
  end

  -- Periodically check if some hero reached the shrine
  for _, hero in pairs(self.ordered_heroes) do
    if hero then
      -- Check hero's last target
      if hero.hero_last_target == parent then
        local distance = (hero:GetAbsOrigin() - parent:GetAbsOrigin()):Length2D()
        -- Check if hero reached the shrine
        if distance < 200 then
          self:CoreShrineActivate()
          break
        end
      else
        self.ordered_heroes[hero:entindex()] = nil
      end
    end
  end
end

function modifier_core_shrine:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ORDER,
  }
end

function modifier_core_shrine:CheckState()
  return {
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_INVULNERABLE] = true,
  }
end

if IsServer() then
  function modifier_core_shrine:OnOrder(params)
    local parent = self:GetParent() -- shrine entity
    local hOrderedUnit = params.unit
    local hTargetUnit = params.target
    local nOrderType = params.order_type

    if nOrderType ~= DOTA_UNIT_ORDER_MOVE_TO_TARGET then
      --if hOrderedUnit then
        --hOrderedUnit.hero_last_target = nil
      --end
      return
    end

    if not hOrderedUnit or not hOrderedUnit:IsRealHero() or hOrderedUnit:GetTeamNumber() ~= parent:GetTeamNumber() then
      return
    end

    hOrderedUnit.hero_last_target = hTargetUnit

    if not hTargetUnit or hTargetUnit ~= parent then
      return
    end

    local distance = (hOrderedUnit:GetAbsOrigin() - parent:GetAbsOrigin()):Length2D()

    -- Check if hero is near the shrine, then activate immediately
    -- if not periodically check distance of all the heroes that clicked on the shrine
    if distance < 200 then
      self:CoreShrineActivate()
    else
      --table.insert(self.ordered_heroes, hOrderedUnit)
      self.ordered_heroes[hOrderedUnit:entindex()] = hOrderedUnit
    end
  end

  function modifier_core_shrine:CoreShrineActivate()
    self.ordered_heroes = {}
    local ability = self:GetAbility()
    if not ability then
      return
    end
    if ability:IsCooldownReady() then
      ability:CastAbility()
    else
      -- Call Grendel if ordered unit is near the shrine
      Grendel:GoNearTeam(self:GetParent():GetTeamNumber())
    end
  end
end
