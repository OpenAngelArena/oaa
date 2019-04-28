

var heroNamePanel = FindDotaHudElement("HeroInspectHeroName");
var info = FindDotaHudElement("HeroInspectInfo");
var tooltipManager = FindDotaHudElement("Tooltips");
var abilities = info.GetParent().FindChildTraverse('HeroAbilities');

var altTooltip = tooltipManager.FindChildTraverse('DOTAHUDStatBranchTooltipAlt');
if(altTooltip==null)
{
  FindDotaHudElement('DOTAHUDStatBranchTooltipAlt').SetParent(tooltipManager);
  altTooltip = tooltipManager.FindChildTraverse('DOTAHUDStatBranchTooltipAlt');
}

function CreateAbilityPanel (parent, ability) {
  var id = 'Ability_' + ability;
  parent.BCreateChildren('<DOTAAbilityImage abilityname="' + ability + '" id="' + id + '" />');
  var icon = parent.FindChildTraverse(id)

  icon.SetPanelEvent('onmouseover', function () {
    $.DispatchEvent('DOTAShowAbilityTooltip', icon, ability);
  });
  icon.SetPanelEvent('onmouseout', function () {
    $.DispatchEvent('DOTAHideAbilityTooltip', icon);
  });
  return icon
}
function OnUpdateHeroSelection()
{
  var port = info.FindChildTraverse('HeroPortrait');
	if (heroNamePanel && heroNamePanel.text=='SOHEI') {
    port.style.backgroundImage = 'url("file://{images}/heroes/selection/npc_dota_hero_sohei.png")';
    port.style.backgroundSize= '100% 100%';

    CreateAbilityPanel(abilities, 'sohei_dash')
    CreateAbilityPanel(abilities, 'sohei_wholeness_of_body')
    CreateAbilityPanel(abilities, 'sohei_palm_of_life')
    var lastAbility = CreateAbilityPanel(abilities, 'sohei_flurry_of_blows')

    var talents =abilities.GetChild(0);
    talents.SetPanelEvent('onmouseover' , function(){
      altTooltip.SetHasClass('visible', true);
      SetTalentsSohei()
    });
    talents.SetPanelEvent('onmouseout' , function(){
      altTooltip.SetHasClass('visible', false);
    });

    abilities.MoveChildAfter(talents, lastAbility)
  }
  else if(heroNamePanel && heroNamePanel.text=='CHATTERJEE') {
    port.style.backgroundImage = 'url("file://{images}/heroes/selection/npc_dota_hero_electrician.png")';
    port.style.backgroundSize= '100% 100%';

    CreateAbilityPanel(abilities, 'electrician_static_grip')
    CreateAbilityPanel(abilities, 'electrician_electric_shield')
    CreateAbilityPanel(abilities, 'electrician_energy_absorption')
    var lastAbility = CreateAbilityPanel(abilities, 'electrician_cleansing_shock')

    var talents =abilities.GetChild(0);
    talents.SetPanelEvent('onmouseover' , function(){
      altTooltip.SetHasClass('visible', true);
      SetTalentsElectrician()
    });
    talents.SetPanelEvent('onmouseout' , function(){
      altTooltip.SetHasClass('visible', false);
    });

    abilities.MoveChildAfter(talents, lastAbility)
  }
}

function SetTalentsSohei()
{
  altTooltip.SetDialogVariable('name_1', $.Localize("#Dota_tooltip_ability_special_bonus_sohei_stun"))
  altTooltip.SetDialogVariable('name_2', $.Localize("#Dota_tooltip_ability_special_bonus_cleave_25"))
  altTooltip.SetDialogVariable('name_3', $.Localize("#Dota_tooltip_ability_special_bonus_strength_20"))
  altTooltip.SetDialogVariable('name_4', $.Localize("#Dota_tooltip_ability_special_bonus_sohei_wholeness_knockback"))
  altTooltip.SetDialogVariable('name_5', $.Localize("#Dota_tooltip_ability_special_bonus_sohei_wholeness_allycast"))
  altTooltip.SetDialogVariable('name_6', $.Localize("#Dota_tooltip_ability_special_bonus_movement_speed_60"))
  altTooltip.SetDialogVariable('name_7', $.Localize("#Dota_tooltip_ability_special_bonus_sohei_dash_recharge").replace("%value%", "3"))
  altTooltip.SetDialogVariable('name_8', $.Localize("#Dota_tooltip_ability_special_bonus_sohei_fob_radius").replace("%value%", "200"))
}
function SetTalentsElectrician()
{
  altTooltip.SetDialogVariable('name_1', $.Localize("#Dota_tooltip_ability_special_bonus_mp_regen_6"))
  altTooltip.SetDialogVariable('name_2', $.Localize("#Dota_tooltip_ability_special_bonus_hp_regen_10"))
  altTooltip.SetDialogVariable('name_3', $.Localize("#Dota_tooltip_ability_special_bonus_movement_speed_30"))
  altTooltip.SetDialogVariable('name_4', $.Localize("#Dota_tooltip_ability_special_bonus_cast_range_250"))
  altTooltip.SetDialogVariable('name_5', $.Localize("#Dota_tooltip_ability_special_bonus_electrician_absorption_hero_mana_restore").replace("%value%", "2"))
  altTooltip.SetDialogVariable('name_6', $.Localize("#Dota_tooltip_ability_special_bonus_mp_800"))
  altTooltip.SetDialogVariable('name_7', $.Localize("#Dota_tooltip_ability_special_bonus_electrician_shock_autoself"))
  altTooltip.SetDialogVariable('name_8', $.Localize("#Dota_tooltip_ability_special_bonus_hp_1000"))
}

// Subscribe hero pre select event
GameEvents.Subscribe( "dota_player_hero_selection_dirty", OnUpdateHeroSelection );

// Enable top bar
FindDotaHudElement('PreGame').FindChildTraverse('Header').style.visibility = 'visible'

// SetMinimap
var minimap = FindDotaHudElement('HeroPickMinimap');
minimap.style.backgroundImage='url("s2r://materials/overviews/oaa.tga")';
minimap.style.borderRadius ='20px';

for (var i = 0; i < minimap.GetChildCount(); i++) {
  var lastPanel = minimap.GetChild(i);
  lastPanel.style.visibility = 'collapse'
}
