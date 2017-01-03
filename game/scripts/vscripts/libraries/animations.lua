ANIMATIONS_VERSION = "1.00"

--[[
  Lua-controlled Animations Library by BMD

  Installation
  -"require" this file inside your code in order to gain access to the StartAnmiation and EndAnimation global.
  -Additionally, ensure that this file is placed in the vscripts/libraries path and that the vscripts/libraries/modifiers/modifier_animation.lua, modifier_animation_translate.lua, modifier_animation_translate_permanent.lua, and modifier_animation_freeze.lua files exist and are in the correct path

  Usage
  -Animations can be started for any unit and are provided as a table of information to the StartAnimation call
  -Repeated calls to StartAnimation for a single unit will cancel any running animation and begin the new animation
  -EndAnimation can be called in order to cancel a running animation
  -Animations are specified by a table which has as potential parameters:
    -duration: The duration to play the animation.  The animation will be cancelled regardless of how far along it is at the end fo the duration.
    -activity: An activity code which will be used as the base activity for the animation i.e. DOTA_ACT_RUN, DOTA_ACT_ATTACK, etc.
    -rate: An optional (will be 1.0 if unspecified) animation rate to be used when playing this animation.
    -translate: An optional translate activity modifier string which can be used to modify the animation sequence.
      Example: For ACT_DOTA_RUN+haste, this should be "haste"
    -translate2: A second optional translate activity modifier string which can be used to modify the animation sequence further.
      Example: For ACT_DOTA_ATTACK+sven_warcry+sven_shield, this should be "sven_warcry" or "sven_shield" while the translate property is the other translate modifier
  -A permanent activity translate can be applied to a unit by calling AddAnimationTranslate for that unit.  This allows for a permanent "injured" or "aggressive" animation stance.
  -Permanent activity translate modifiers can be removed with RemoveAnimationTranslate.
  -Animations can be frozen in place at any time by calling FreezeAnimation(unit[, duration]).  Leaving the duration off will cause the animation to be frozen until UnfreezeAnimation is called.
  -Animations can be unfrozen at any time by calling UnfreezeAnimation(unit)

  Notes
  -Animations can only play for valid activities/sequences possessed by the model the unit is using.
  -Sequences requiring 3+ activity modifier translates (i.e "stun+fear+loadout" or similar) are not possible currently in this library.
  -Calling EndAnimation and attempting to StartAnimation a new animation for the same unit withing ~2 server frames of the animation end will likely fail to play the new animation.  
    Calling StartAnimation directly without ending the previous animation will automatically add in this delay and cancel the previous animation.
  -The maximum animation rate which can be used is 12.75, and animation rates can only exist at a 0.05 resolution (i.e. 1.0, 1.05, 1.1 and not 1.06)
  -StartAnimation and EndAnimation functions can also be accessed through GameRules as GameRules.StartAnimation and GameRules.EndAnimation for use in scoped lua files (triggers, vscript ai, etc)
  -This library requires that the "libraries/timers.lua" be present in your vscripts directory.

  Examples:
  --Start a running animation at 2.5 rate for 2.5 seconds
    StartAnimation(unit, {duration=2.5, activity=ACT_DOTA_RUN, rate=2.5})

  --End a running animation
    EndAnimation(unit)

  --Start a running + hasted animation at .8 rate for 5 seconds
    StartAnimation(unit, {duration=5, activity=ACT_DOTA_RUN, rate=0.8, translate="haste"})

  --Start a shield-bash animation for sven with variable rate
    StartAnimation(unit, {duration=1.5, activity=ACT_DOTA_ATTACK, rate=RandomFloat(.5, 1.5), translate="sven_warcry", translate2="sven_shield"})

  --Start a permanent injured translate modifier
    AddAnimationTranslate(unit, "injured")

  --Remove a permanent activity translate modifier
    RemoveAnimationTranslate(unit)

  --Freeze an animation for 4 seconds
    FreezeAnimation(unit, 4)

  --Unfreeze an animation
    UnfreezeAnimation(unit)

]]

LinkLuaModifier( "modifier_animation", "libraries/modifiers/modifier_animation.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_animation_translate", "libraries/modifiers/modifier_animation_translate.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_animation_translate_permanent", "libraries/modifiers/modifier_animation_translate_permanent.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_animation_freeze", "libraries/modifiers/modifier_animation_freeze.lua", LUA_MODIFIER_MOTION_NONE )

require('libraries/timers')

local _ANIMATION_TRANSLATE_TO_CODE = {
  abysm= 13,
  admirals_prow= 307,
  agedspirit= 3,
  aggressive= 4,
  agrressive= 163,
  am_blink= 182,
  ancestors_edge= 144,
  ancestors_pauldron= 145,
  ancestors_vambrace= 146,
  ancestral_scepter= 67,
  ancient_armor= 6,
  anvil= 7,
  arcana= 8,
  armaments_set= 20,
  axes= 188,
  backstab= 41,
  backstroke_gesture= 283,
  backward= 335,
  ball_lightning= 231,
  batter_up= 43,
  bazooka= 284,
  belly_flop= 180,
  berserkers_blood= 35,
  black= 44,
  black_hole= 194,
  bladebiter= 147,
  blood_chaser= 134,
  bolt= 233,
  bot= 47,
  brain_sap= 185,
  broodmother_spin= 50,
  burning_fiend= 148,
  burrow= 229,
  burrowed= 51,
  cat_dancer_gesture= 285,
  cauldron= 29,
  charge= 97,
  charge_attack= 98,
  chase= 246,
  chasm= 57,
  chemical_rage= 2,
  chicken_gesture= 258,
  come_get_it= 39,
  corpse_dress= 104,
  corpse_dresstop= 103,
  corpse_scarf= 105,
  cryAnimationExportNode= 341,
  crystal_nova= 193,
  culling_blade= 184,
  dagger_twirl= 143,
  dark_wraith= 174,
  darkness= 213,
  dc_sb_charge= 107,
  dc_sb_charge_attack= 108,
  dc_sb_charge_finish= 109,
  dc_sb_ultimate= 110,
  deadwinter_soul= 96,
  death_protest= 94,
  demon_drain= 116,
  desolation= 55,
  digger= 176,
  dismember= 218,
  divine_sorrow= 117,
  divine_sorrow_loadout= 118,
  divine_sorrow_loadout_spawn= 119,
  divine_sorrow_sunstrike= 120,
  dizzying_punch= 343,
  dog_of_duty= 342,
  dogofduty= 340,
  dominator= 254,
  dryad_tree= 311,
  dualwield= 14,
  duel_kill= 121,
  earthshock= 235,
  emp= 259,
  enchant_totem= 313,
  ["end"]= 243,
  eyeoffetizu= 34,
  f2p_doom= 131,
  face_me= 286,
  faces_hakama= 111,
  faces_mask= 113,
  faces_wraps= 112,
  fast= 10,
  faster= 11,
  fastest= 12,
  fear= 125,
  fiends_grip= 186,
  fiery_soul= 149,
  finger= 200,
  firefly= 190,
  fish_slap= 123,
  fishstick= 339,
  fissure= 195,
  flying= 36,
  focusfire= 124,
  forcestaff_enemy= 122,
  forcestaff_friendly= 15,
  forward= 336,
  fountain= 49,
  freezing_field= 191,
  frost_arrow= 37,
  frostbite= 192,
  frostiron_raider= 150,
  frostivus= 54,
  ftp_dendi_back= 126,
  gale= 236,
  get_burned= 288,
  giddy_up_gesture= 289,
  glacier= 101,
  glory= 345,
  good_day_sir= 40,
  great_safari= 267,
  greevil_black_hole= 58,
  greevil_blade_fury= 59,
  greevil_bloodlust= 60,
  greevil_cold_snap= 61,
  greevil_decrepify= 62,
  greevil_diabolic_edict= 63,
  greevil_echo_slam= 64,
  greevil_fatal_bonds= 65,
  greevil_ice_wall= 66,
  greevil_laguna_blade= 68,
  greevil_leech_seed= 69,
  greevil_magic_missile= 70,
  greevil_maledict= 71,
  greevil_miniboss_black_brain_sap= 72,
  greevil_miniboss_black_nightmare= 73,
  greevil_miniboss_blue_cold_feet= 74,
  greevil_miniboss_blue_ice_vortex= 75,
  greevil_miniboss_green_living_armor= 76,
  greevil_miniboss_green_overgrowth= 77,
  greevil_miniboss_orange_dragon_slave= 78,
  greevil_miniboss_orange_lightstrike_array= 79,
  greevil_miniboss_purple_plague_ward= 80,
  greevil_miniboss_purple_venomous_gale= 81,
  greevil_miniboss_red_earthshock= 82,
  greevil_miniboss_red_overpower= 83,
  greevil_miniboss_white_purification= 84,
  greevil_miniboss_yellow_ion_shell= 85,
  greevil_miniboss_yellow_surge= 86,
  greevil_natures_attendants= 87,
  greevil_phantom_strike= 88,
  greevil_poison_nova= 89,
  greevil_purification= 90,
  greevil_shadow_strike= 91,
  greevil_shadow_wave= 92,
  groove_gesture= 305,
  ground_pound= 128,
  guardian_angel= 215,
  guitar= 290,
  hang_loose_gesture= 291,
  happy_dance= 293,
  harlequin= 129,
  haste= 45,
  hook= 220,
  horn= 292,
  immortal= 28,
  impale= 201,
  impatient_maiden= 100,
  impetus= 138,
  injured= 5,
  ["injured rare"]= 247,
  injured_aggressive= 130,
  instagib= 21,
  iron= 255,
  iron_surge= 99,
  item_style_2= 133,
  jump_gesture= 294,
  laguna= 202,
  leap= 206,
  level_1= 140,
  level_2= 141,
  level_3= 142,
  life_drain= 219,
  loadout= 0,
  loda= 173,
  lodestar= 114,
  loser= 295,
  lsa= 203,
  lucentyr= 158,
  lute= 296,
  lyreleis_breeze= 159,
  mace= 160,
  mag_power_gesture= 298,
  magic_ends_here= 297,
  mana_drain= 204,
  mana_void= 183,
  manias_mask= 135,
  manta= 38,
  mask_lord= 299,
  masquerade= 25,
  meld= 162,
  melee= 334,
  miniboss= 164,
  moon_griffon= 166,
  moonfall= 165,
  moth= 53,
  nihility= 95,
  obeisance_of_the_keeper= 151,
  obsidian_helmet= 132,
  odachi= 32,
  offhand_basher= 42,
  omnislash= 198,
  overpower1= 167,
  overpower2= 168,
  overpower3= 169,
  overpower4= 170,
  overpower5= 171,
  overpower6= 172,
  pegleg= 248,
  phantom_attack= 16,
  pinfold= 175,
  plague_ward= 237,
  poison_nova= 238,
  portrait_fogheart= 177,
  poundnpoint= 300,
  powershot= 242,
  punch= 136,
  purification= 216,
  pyre= 26,
  qop_blink= 221,
  ravage= 225,
  red_moon= 30,
  reincarnate= 115,
  remnant= 232,
  repel= 217,
  requiem= 207,
  roar= 187,
  robot_gesture= 301,
  roshan= 181,
  salvaged_sword= 152,
  sandking_rubyspire_burrowstrike= 52,
  sb_bracers= 251,
  sb_helmet= 250,
  sb_shoulder= 252,
  sb_spear= 253,
  scream= 222,
  serene_honor= 153,
  shadow_strike= 223,
  shadowraze= 208,
  shake_moneymaker= 179,
  sharp_blade= 303,
  shinobi= 27,
  shinobi_mask= 154,
  shinobi_tail= 23,
  shrapnel= 230,
  silent_ripper= 178,
  slam= 196,
  slasher_chest= 262,
  slasher_mask= 263,
  slasher_offhand= 261,
  slasher_weapon= 260,
  sm_armor= 264,
  sm_head= 56,
  sm_shoulder= 265,
  snipe= 226,
  snowangel= 17,
  snowball= 102,
  sonic_wave= 224,
  sparrowhawk_bow= 269,
  sparrowhawk_cape= 270,
  sparrowhawk_hood= 272,
  sparrowhawk_quiver= 271,
  sparrowhawk_shoulder= 273,
  spin= 199,
  split_shot= 1,
  sprint= 275,
  sprout= 209,
  staff_swing= 304,
  stalker_exo= 93,
  start= 249,
  stinger= 280,
  stolen_charge= 227,
  stolen_firefly= 189,
  strike= 228,
  sugarrush= 276,
  suicide_squad= 18,
  summon= 210,
  sven_shield= 256,
  sven_warcry= 257,
  swag_gesture= 287,
  swordonshoulder= 155,
  taunt_fullbody= 19,
  taunt_killtaunt= 139,
  taunt_quickdraw_gesture= 268,
  taunt_roll_gesture= 302,
  techies_arcana= 9,
  telebolt= 306,
  teleport= 211,
  thirst= 137,
  tidebringer= 24,
  tidehunter_boat= 22,
  tidehunter_toss_fish= 312,
  tidehunter_yippy= 347,
  timelord_head= 309,
  tinker_rollermaw= 161,
  torment= 279,
  totem= 197,
  transition= 278,
  trapper= 314,
  tree= 310,
  trickortreat= 277,
  triumphant_timelord= 127,
  turbulent_teleport= 308,
  twinblade_attack= 315,
  twinblade_attack_b= 316,
  twinblade_attack_c= 317,
  twinblade_attack_d= 318,
  twinblade_attack_injured= 319,
  twinblade_death= 320,
  twinblade_idle= 321,
  twinblade_idle_injured= 322,
  twinblade_idle_rare= 323,
  twinblade_injured_attack_b= 324,
  twinblade_jinada= 325,
  twinblade_jinada_injured= 326,
  twinblade_shuriken_toss= 327,
  twinblade_shuriken_toss_injured= 328,
  twinblade_spawn= 329,
  twinblade_stun= 330,
  twinblade_track= 331,
  twinblade_track_injured= 332,
  twinblade_victory= 333,
  twister= 274,
  unbroken= 106,
  vendetta= 337,
  viper_strike= 239,
  viridi_set= 338,
  void= 214,
  vortex= 234,
  wall= 240,
  ward= 241,
  wardstaff= 344,
  wave= 205,
  web= 48,
  whalehook= 156,
  whats_that= 281,
  when_nature_attacks= 31,
  white= 346,
  windrun= 244,
  windy= 245,
  winterblight= 157,
  witchdoctor_jig= 282,
  with_item= 46,
  wolfhound= 266,
  wraith_spin= 33,
  wrath= 212,

  rampant= 348,
  overload= 349,

  surge=350,
  es_prosperity=351,
  Espada_pistola=352,
  overload_injured=353,
  ss_fortune=354,
  liquid_fire=355,
  jakiro_icemelt=356,
  jakiro_roar=357,

  chakram=358,
  doppelwalk=359,
  enrage=360,
  fast_run=361,
  overpower=362,
  overwhelmingodds=363,
  pregame=364,
  shadow_dance=365,
  shukuchi=366,
  strength=367,
  twinblade_run=368,
  twinblade_run_injured=369,
  windwalk=370,  

}

function StartAnimation(unit, table)
  local duration = table.duration
  local activity = table.activity
  local translate = table.translate
  local translate2 = table.translate2
  local rate = table.rate or 1.0

  rate = math.floor(math.max(0,math.min(255/20, rate)) * 20 + .5)

  local stacks = activity + bit.lshift(rate,11)

  if translate ~= nil then
    if _ANIMATION_TRANSLATE_TO_CODE[translate] == nil then
      print("[ANIMATIONS.lua] ERROR, no translate-code found for '" .. translate .. "'.  This translate may be misspelled or need to be added to the enum manually.")
      return
    end
    stacks = stacks + bit.lshift(_ANIMATION_TRANSLATE_TO_CODE[translate],19)
  end

  if translate2 ~= nil and _ANIMATION_TRANSLATE_TO_CODE[translate2] == nil then
    print("[ANIMATIONS.lua] ERROR, no translate-code found for '" .. translate2 .. "'.  This translate may be misspelled or need to be added to the enum manually.")
    return
  end

  if unit:HasModifier("modifier_animation") or (unit._animationEnd ~= nil and unit._animationEnd + .067 > GameRules:GetGameTime()) then
    EndAnimation(unit)
    Timers:CreateTimer(.066, function() 
      if translate2 ~= nil then
        unit:AddNewModifier(unit, nil, "modifier_animation_translate", {duration=duration, translate=translate2})
        unit:SetModifierStackCount("modifier_animation_translate", unit, _ANIMATION_TRANSLATE_TO_CODE[translate2])
      end

      unit._animationEnd = GameRules:GetGameTime() + duration
      unit:AddNewModifier(unit, nil, "modifier_animation", {duration=duration, translate=translate})
      unit:SetModifierStackCount("modifier_animation", unit, stacks)
    end)
  else
    if translate2 ~= nil then
      unit:AddNewModifier(unit, nil, "modifier_animation_translate", {duration=duration, translate=translate2})
      unit:SetModifierStackCount("modifier_animation_translate", unit, _ANIMATION_TRANSLATE_TO_CODE[translate2])
    end

    unit._animationEnd = GameRules:GetGameTime() + duration
    unit:AddNewModifier(unit, nil, "modifier_animation", {duration=duration, translate=translate})
    unit:SetModifierStackCount("modifier_animation", unit, stacks)
  end
end

function FreezeAnimation(unit, duration)
  if duration then
    unit:AddNewModifier(unit, nil, "modifier_animation_freeze", {duration=duration})
  else
    unit:AddNewModifier(unit, nil, "modifier_animation_freeze", {})
  end
end

function UnfreezeAnimation(unit)
  unit:RemoveModifierByName("modifier_animation_freeze")
end

function EndAnimation(unit)
  unit._animationEnd = GameRules:GetGameTime()
  unit:RemoveModifierByName("modifier_animation")
  unit:RemoveModifierByName("modifier_animation_translate")
end

function AddAnimationTranslate(unit, translate)
  if translate == nil or _ANIMATION_TRANSLATE_TO_CODE[translate] == nil then
    print("[ANIMATIONS.lua] ERROR, no translate-code found for '" .. translate .. "'.  This translate may be misspelled or need to be added to the enum manually.")
    return
  end

  unit:AddNewModifier(unit, nil, "modifier_animation_translate_permanent", {duration=duration, translate=translate})
  unit:SetModifierStackCount("modifier_animation_translate_permanent", unit, _ANIMATION_TRANSLATE_TO_CODE[translate])
end

function RemoveAnimationTranslate(unit)
  unit:RemoveModifierByName("modifier_animation_translate_permanent")
end

GameRules.StartAnimation = StartAnimation
GameRules.EndAnimation = EndAnimation
GameRules.AddAnimationTranslate = AddAnimationTranslate
GameRules.RemoveAnimationTranslate = RemoveAnimationTranslate