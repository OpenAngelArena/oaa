LinkLuaModifier("modifier_bottle_regeneration", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bottle_texture_tracker", "items/bottle.lua", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

local special_bottles = {
  --comments with names indicate a person having access to that icon but another one being currently active



  -- TP master, and Lord of the Lotus Orb

  [43305444] = 6, -- baumi



  -- contributors

  --Yzanas
  [7131038] = 1, -- chrisinajar
  [109151532] = 1, -- Chronophylos
  [60408038] = 1, -- Trildar
  [141335296] = 1, -- SquawkyArctangent
  [56309069] = 1, -- imaGecko
  [116407282] = 1, -- Haganeko
  [123791730] = 1, -- Warpdragon
  [98536810] = 1, -- Honeth
  [53917791] = 1, -- Minnakht
  [103179022] = 1, -- Allan vbhg
  [114538910] = 1, -- Apisal
  [53999591] = 1, -- carlosrpg



  -- golden tournament winners

  [124585666] = 2, --DerpySoccerBall
  [75435056] = 2, --Chogex
  [136897804] = 2, --JumperJay
  [57898114] = 2, --KGBurger
  [89367798] = 2, --Naeil



  -- special people

  [110318967] = 7, -- timo
  [34314091] = 8, -- frej
  [370166341] = 9, -- Melon
  [117027938] = 10, -- Yzanas



  -- twitch donators 3

  --steam: Steamcommunity.com/id/amidable_money81 - twitch: Frazzlefrancis provided steam link didn't work
  --chrisinajar
  [370630108] = 3, --steam: http://steamcommunity.com/profiles/76561198330895836 - twitch: angerywalrus
  [144242481] = 3, --steam: http://steamcommunity.com/profiles/76561198104508209 - twitch: B0bbyxy
  [105264015] = 3, --steam: http://steamcommunity.com/profiles/76561198065529743 - twitch: B4mnb1
  [106103567] = 3, --steam: http://steamcommunity.com/profiles/76561198066369295 - twitch: Baumis_Son
  [67294300] = 3, --steam: http://steamcommunity.com/profiles/76561198027560028 - twitch: behemoth2090
  [103945969] = 3, --steam: http://steamcommunity.com/profiles/76561198064211697 - twitch: BillyNaing
  [91113421] = 3, --steam: http://steamcommunity.com/profiles/76561198051379149 - twitch: blackleopard32
  [86550648] = 3, --steam: http://steamcommunity.com/profiles/76561198046816376 - twitch: BobsGuns
  [157206779] = 3, --steam: http://steamcommunity.com/profiles/76561198117472507 - twitch: Bonellon
  [106937130] = 3, --steam: http://steamcommunity.com/profiles/76561198067202858 - twitch: BorgonsSoul
  [82853587] = 3, --steam: http://steamcommunity.com/profiles/76561198043119315 - twitch: Cabsonlero
  [118437975] = 3, --steam: http://steamcommunity.com/profiles/76561198078703703 - twitch: Carl_Golem
  [81272777] = 3, --steam: http://steamcommunity.com/profiles/76561198041538505 - twitch: ChipKarape
  [58659208] = 3, --steam: http://steamcommunity.com/profiles/76561198018924936 - twitch: D34thscythe
  [75111160] = 3, --steam: http://steamcommunity.com/profiles/76561198035376888 - twitch: da1wizard
  [88602082] = 3, --steam: http://steamcommunity.com/profiles/76561198048867810 - twitch: Dark_Lord_Xana
  [61476137] = 3, --steam: http://steamcommunity.com/profiles/76561198021741865 - twitch: DarkNightHawk
  [157684926] = 3, --steam: http://steamcommunity.com/profiles/76561198117950654 - twitch: deathgamer22
  [81825448] = 3, --steam: http://steamcommunity.com/profiles/76561198042091176 - twitch: Dgenaraition
  [38504326] = 3, --steam: http://steamcommunity.com/profiles/76561197998770054 - twitch: DJ_Boras
  [82051827] = 3, --steam: http://steamcommunity.com/profiles/76561198042317555 - twitch: FilipTomek
  [108384611] = 3, --steam: http://steamcommunity.com/profiles/76561198068650339 - twitch: FoxDeath
  [178432042] = 3, --steam: http://steamcommunity.com/profiles/76561198138697770 - twitch: Foxy_Goat
  [159410103] = 3, --steam: http://steamcommunity.com/profiles/76561198119675831 - twitch: Geogorna
  [126497930] = 3, --steam: http://steamcommunity.com/profiles/76561198086763658 - twitch: GuessWh0Is
  [61767281] = 3, --steam: http://steamcommunity.com/profiles/76561198022033009 - twitch: hideandseekNL
  [175214300] = 3, --steam: http://steamcommunity.com/profiles/76561198135480028 - twitch: Honzuly
  [182794460] = 3, --steam: http://steamcommunity.com/profiles/76561198143060188 - twitch: IcedGrape
  [125462488] = 3, --steam: http://steamcommunity.com/profiles/76561198085728216 - twitch: IchLord
  [100799600] = 3, --steam: http://steamcommunity.com/profiles/76561198061065328 - twitch: IOtvirakLORDYI
  [99002406] = 3, --steam: http://steamcommunity.com/profiles/76561198059268134 - twitch: itwasntme967
  [363583181] = 3, --steam: http://steamcommunity.com/profiles/76561198323848909 - twitch: johndoetarzan
  [92707138] = 3, --steam: http://steamcommunity.com/profiles/76561198052972866 - twitch: kaptinbob
  [151781095] = 3, --steam: http://steamcommunity.com/profiles/76561198112046823 - twitch: lalaluka
  [123774170] = 3, --steam: http://steamcommunity.com/profiles/76561198084039898 - twitch: Lycanthrope
  [53672108] = 3, --steam: http://steamcommunity.com/profiles/76561198013937836 - twitch: miupiupi
  [238908827] = 3, --steam: http://steamcommunity.com/profiles/76561198199174555 - twitch: mostedwardo
  [390939459] = 3, --steam: http://steamcommunity.com/profiles/76561198351205187 - twitch: Mr__Pootis
  [411130071] = 3, --steam: http://steamcommunity.com/profiles/76561198371395799 - twitch: Mr__Pootis
  [98290859] = 3, --steam: http://steamcommunity.com/profiles/76561198058556587 - twitch: Mr__Pootis
  [229756357] = 3, --steam: http://steamcommunity.com/profiles/76561198190022085 - twitch: Mr__Pootis
  [176011727] = 3, --steam: http://steamcommunity.com/profiles/76561198136277455 - twitch: Mr__Pootis
  [80573658] = 3, --steam: http://steamcommunity.com/profiles/76561198040839386 - twitch: Mr__Pootis
  [155554188] = 3, --steam: http://steamcommunity.com/profiles/76561198115819916 - twitch: mrmogothe3rd
  [71512781] = 3, --steam: http://steamcommunity.com/profiles/76561198031778509 - twitch: NickEs
  [177815169] = 3, --steam: http://steamcommunity.com/profiles/76561198138080897 - twitch: nightmare_911
  [11504025] = 3, --steam: http://steamcommunity.com/profiles/76561197971769753 - twitch: olshallcroft
  [161930154] = 3, --steam: http://steamcommunity.com/profiles/76561198122195882 - twitch: padii123
  [143620119] = 3, --steam: http://steamcommunity.com/profiles/76561198103885847 - twitch: plsChaos
  [177336980] = 3, --steam: http://steamcommunity.com/profiles/76561198137602708 - twitch: Rafyrt
  [140895778] = 3, --steam: http://steamcommunity.com/profiles/76561198101161506 - twitch: rcsongor
  [322464456] = 3, --steam: http://steamcommunity.com/profiles/76561198282730184 - twitch: Russian
  [103677415] = 3, --steam: http://steamcommunity.com/profiles/76561198063943143 - twitch: Sahnetortelini
  [77939025] = 3, --steam: http://steamcommunity.com/profiles/76561198038204753 - twitch: Savojin
  [64922640] = 3, --steam: http://steamcommunity.com/profiles/76561198025188368 - twitch: ShmenI
  [135986481] = 3, --steam: http://steamcommunity.com/profiles/76561198096252209 - twitch: snoopy360tbc
  [99802330] = 3, --steam: http://steamcommunity.com/profiles/76561198060068058 - twitch: SohrabXch
  [181914067] = 3, --steam: http://steamcommunity.com/profiles/76561198142179795 - twitch: Soundkidz
  [80374433] = 3, --steam: http://steamcommunity.com/profiles/76561198040640161 - twitch: SquareG66
  [123018754] = 3, --steam: http://steamcommunity.com/profiles/76561198083284482 - twitch: the_funkalizer
  [162267134] = 3, --steam: http://steamcommunity.com/profiles/76561198122532862 - twitch: the_lightnin
  [196954061] = 3, --steam: http://steamcommunity.com/profiles/76561198157219789 - twitch: TheOnly1Matt
  [148245960] = 3, --steam: http://steamcommunity.com/profiles/76561198108511688 - twitch: -not in donation list, profile given by baumi



  -- twitch donators 20

  --KarmaticNeutral
  [259101879] = 4, --steam: http://steamcommunity.com/profiles/76561198219367607 - twitch: Chives donated 2x10 with same profile link and different message
  [144379677] = 4, --steam: http://steamcommunity.com/profiles/76561198104645405 - twitch: 99LuftBalloons
  [106881079] = 4, --steam: http://steamcommunity.com/profiles/76561198067146807 - twitch: Alsher7
  [113199503] = 4, --steam: http://steamcommunity.com/profiles/76561198073465231 - twitch: BananaCharge
  [82995898] = 4, --steam: http://steamcommunity.com/profiles/76561198043261626 - twitch: bobAKAbill
  [75237487] = 4, --steam: http://steamcommunity.com/profiles/76561198035503215 - twitch: CalmStormRed
  [102208419] = 4, --steam: http://steamcommunity.com/profiles/76561198062474147 - twitch: CreepySniper
  [98653735] = 4, --steam: http://steamcommunity.com/profiles/76561198058919463 - twitch: CynicalDemon
  [99112333] = 4, --steam: http://steamcommunity.com/profiles/76561198059378061 - twitch: DazRoger
  [177718580] = 4, --steam: http://steamcommunity.com/profiles/76561198137984308 - twitch: FabianOtten
  [83370901] = 4, --steam: http://steamcommunity.com/profiles/76561198043636629 - twitch: flizzard95
  [115235030] = 4, --steam: http://steamcommunity.com/profiles/76561198075500758 - twitch: foorjee
  [86398357] = 4, --steam: http://steamcommunity.com/profiles/76561198046664085 - twitch: Kage40k
  [89530957] = 4, --steam: http://steamcommunity.com/profiles/76561198049796685 - twitch: LionMercen
  [396954966] = 4, --steam: http://steamcommunity.com/profiles/76561198357220694 - twitch: mcguyerm
  [82850232] = 4, --steam: http://steamcommunity.com/profiles/76561198043115960 - twitch: OomMini
  [38349285] = 4, --steam: http://steamcommunity.com/profiles/76561197998615013 - twitch: screwy
  [169940994] = 4, --steam: http://steamcommunity.com/profiles/76561198130206722 - twitch: SilverLicas
  [84453930] = 4, --steam: http://steamcommunity.com/profiles/76561198044719658 - twitch: Sir_Samuel_Vimes
  [83886066] = 4, --steam: http://steamcommunity.com/profiles/76561198044151794 - twitch: Stanno0
  [269146136] = 4, --steam: http://steamcommunity.com/profiles/76561198229411864 - twitch: ThatMusicWriter
  [74822878] = 4, --steam: http://steamcommunity.com/profiles/76561198035088606 - twitch: UrusMerek



  -- twitch donators 50

}

local bonusNames = {
  'custom/bottles/bottle_contributor',
  'custom/bottles/bottle_tournament',
  'custom/bottles/bottle_03',
  'custom/bottles/bottle_20',
  'custom/bottles/bottle_50', --5
  'custom/bottles/bottle_baumi',
  'custom/bottles/bottle_timo',
  'custom/bottles/bottle_frej',
  'custom/bottles/bottle_melon',
  'custom/bottles/bottle_yzanas' --10
}

--------------------------------------------------------------------------------

item_infinite_bottle = class(ItemBaseClass)

function item_infinite_bottle:GetIntrinsicModifierName()
  return "modifier_bottle_texture_tracker"
end

function item_infinite_bottle:OnSpellStart()
  local restore_time = self:GetSpecialValueFor("restore_time")
  local caster = self:GetCaster()

  EmitSoundOnClient("Bottle.Drink", caster:GetPlayerOwner())

  caster:AddNewModifier(caster, self, "modifier_bottle_regeneration", { duration = restore_time })

  if self:GetCurrentCharges() - 1 <= 0 then
    caster:RemoveItem(self)
  else
    self:SetCurrentCharges(self:GetCurrentCharges() - 1)
  end
end

function item_infinite_bottle:GetAbilityTextureName()
  if self.bonus then
    return self.bonus
  end
  if self.mod and not self.mod:IsNull() then
    local stacks = self.mod:GetStackCount()
    if stacks > 0 then
      self.bonus = bonusNames[self.mod:GetStackCount()]
      return self.bonus
    end
  end
  return "item_bottle"
end

--------------------------------------------------------------------------------

Debug:EnableDebugging()

modifier_bottle_texture_tracker = class(ModifierBaseClass)

function modifier_bottle_texture_tracker:OnCreated()
  local parent = self:GetParent()
  local item = self:GetAbility()
  item.mod = self

  if IsServer() then
    local playerID = parent:GetPlayerOwnerID()
    local steamid = PlayerResource:GetSteamAccountID(playerID)
    local playerName = PlayerResource:GetPlayerName(playerID)
    DebugPrint("Steam ID of " .. playerName .. ": " .. steamid)

    self:SetStackCount(special_bottles[steamid] or 0)
  end
end

function modifier_bottle_texture_tracker:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_bottle_texture_tracker:IsHidden()
  return true
end
