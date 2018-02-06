LinkLuaModifier("modifier_ardm", "modifiers/modifier_ardm.lua", LUA_MODIFIER_MOTION_NONE )

modifier_ardm = class(ModifierBaseClass)

-- START IF SERVER
if IsServer() then

function modifier_ardm:ReplaceHero ()
  -- this is not the total gold, this is only the gold on the hero...
  local parent = self:GetParent()
  local playerId = parent:GetPlayerID()
  local currentDotaGold = PlayerResource:GetGold(playerId)

  local items = {}
  -- Reset cooldown for items
  for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
    local item = parent:GetItemInSlot(i)
    items[i] = item
  end

  Debug:EnableDebugging()
  local heroXp = parent:GetCurrentXP()
  local heroLevel = parent:GetLevel()
  DebugPrint('Hero was level ' .. heroLevel .. ' with xp ' .. heroXp)

  PlayerResource:ReplaceHeroWith(playerId, self.hero, currentDotaGold, 0)
  local newHero = PlayerResource:GetSelectedHeroEntity(playerId)

  while newHero:GetLevel() < heroLevel do
    newHero:HeroLevelUp(false)
    local level = newHero:GetLevel()
    AbilityLevels:CheckAbilityLevels({
      level = level,
      player = PlayerResource:GetPlayer(playerId):entindex(),
      selectedEntity = parent:entindex()
    })
    HeroProgression:ReduceStatGain(newHero, level)
    HeroProgression:ProcessAbilityPointGain(newHero, level)
  end

  newHero:AddExperience(heroXp, DOTA_ModifyXP_Unspecified, false, true)

  for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
    local item = newHero:GetItemInSlot(i)
    if item then
      newHero:RemoveItem(item)
    end
  end

  for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
    local item = items[i]
    if item then
      newHero:AddItem(item)
    end
  end

  UTIL_Remove(parent)
end

function modifier_ardm:DeclareFunctions ()
  return {
    MODIFIER_EVENT_ON_RESPAWN
  }
end

function modifier_ardm:OnRespawn()
  if self.hero then
    -- run next frame
    Timer:CreateTimer(partial(self.ReplaceHero, self))
  end
end

-- END IF SERVER
end

function modifier_ardm:IsHidden()
  return true
end
function modifier_ardm:IsDebuff()
  return false
end
function modifier_ardm:IsPurgable()
  return false
end
function modifier_ardm:IsPurgeException()
  return false
end
function modifier_ardm:IsPermanent()
  return true
end
function modifier_ardm:RemoveOnDeath()
  return false
end
