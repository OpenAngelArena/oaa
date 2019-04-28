
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
  var heroNamePanel = FindDotaHudElement("HeroInspectHeroName");
  var info = FindDotaHudElement("HeroInspectInfo");
  var port = info.FindChildTraverse('HeroPortrait');
	if (heroNamePanel && heroNamePanel.text=='SOHEI') {
    port.style.backgroundImage = 'url("file://{images}/heroes/selection/npc_dota_hero_sohei.png")';
    port.style.backgroundSize= '100% 100%';

    var abilities = info.GetParent().FindChildTraverse('HeroAbilities');
    CreateAbilityPanel(abilities, 'sohei_dash')
    CreateAbilityPanel(abilities, 'sohei_wholeness_of_body')
    CreateAbilityPanel(abilities, 'sohei_palm_of_life')
    var lastAbility = CreateAbilityPanel(abilities, 'sohei_flurry_of_blows')

    var talents =abilities.GetChild(0);
    talents.SetPanelEvent('onmouseover' , function(){
      var tooltipManager = FindDotaHudElement("Tooltips");
      var altTooltip = tooltipManager.FindChildTraverse('DOTAHUDStatBrnachTooltipAlt');
      altTooltip.SetHasClass('visible', true);
      SetTalentsSohei()
    });
    talents.SetPanelEvent('onmouseout' , function(){
      var tooltipManager = FindDotaHudElement("Tooltips");
      var altTooltip = tooltipManager.FindChildTraverse('DOTAHUDStatBrnachTooltipAlt');
      altTooltip.SetHasClass('visible', false);
    });
    FindDotaHudElement("HeroInspectInfo");

    abilities.MoveChildAfter(talents, lastAbility)
  }
  else if(heroNamePanel && heroNamePanel.text=='CHATTERJEE') {
    port.style.backgroundImage = 'url("file://{images}/heroes/selection/npc_dota_hero_electrician.png")';
    port.style.backgroundSize= '100% 100%';

    var abilities = info.GetParent().FindChildTraverse('HeroAbilities');
    CreateAbilityPanel(abilities, 'electrician_static_grip')
    CreateAbilityPanel(abilities, 'electrician_electric_shield')
    CreateAbilityPanel(abilities, 'electrician_energy_absorption')
    var lastAbility = CreateAbilityPanel(abilities, 'electrician_cleansing_shock')

    var talents =abilities.GetChild(0);
    talents.SetPanelEvent('onmouseover' , function(){
      var tooltipManager = FindDotaHudElement("Tooltips");
      var altTooltip = tooltipManager.FindChildTraverse('DOTAHUDStatBrnachTooltipAlt');
      altTooltip.SetHasClass('visible', true);
      SetTalentsElectrician()
    });
    talents.SetPanelEvent('onmouseout' , function(){
      var tooltipManager = FindDotaHudElement("Tooltips");
      var altTooltip = tooltipManager.FindChildTraverse('DOTAHUDStatBrnachTooltipAlt');
      altTooltip.SetHasClass('visible', false);
    });

    abilities.MoveChildAfter(talents, lastAbility)
  }
}

function SetTalentsSohei()
{
  var tooltipManager = FindDotaHudElement("Tooltips");
  var talentTooltip = tooltipManager.FindChildTraverse('DOTAHUDStatBrnachTooltipAlt');
  talentTooltip.SetDialogVariable('name_1', $.Localize("#Dota_tooltip_ability_special_bonus_sohei_stun"))
  talentTooltip.SetDialogVariable('name_2', $.Localize("#Dota_tooltip_ability_special_bonus_cleave_25"))
  talentTooltip.SetDialogVariable('name_3', $.Localize("#Dota_tooltip_ability_special_bonus_strength_20"))
  talentTooltip.SetDialogVariable('name_4', $.Localize("#Dota_tooltip_ability_special_bonus_sohei_wholeness_knockback"))
  talentTooltip.SetDialogVariable('name_5', $.Localize("#Dota_tooltip_ability_special_bonus_sohei_wholeness_allycast"))
  talentTooltip.SetDialogVariable('name_6', $.Localize("#Dota_tooltip_ability_special_bonus_movement_speed_60"))
  talentTooltip.SetDialogVariable('name_7', $.Localize("#Dota_tooltip_ability_special_bonus_sohei_dash_recharge").replace("%value%", "3"))
  talentTooltip.SetDialogVariable('name_8', $.Localize("#Dota_tooltip_ability_special_bonus_sohei_fob_radius").replace("%value%", "200"))
}
function SetTalentsElectrician()
{
  var tooltipManager = FindDotaHudElement("Tooltips");
  var talentTooltip = tooltipManager.FindChildTraverse('DOTAHUDStatBrnachTooltipAlt');
  talentTooltip.SetDialogVariable('name_1', $.Localize("#Dota_tooltip_ability_special_bonus_mp_regen_6"))
  talentTooltip.SetDialogVariable('name_2', $.Localize("#Dota_tooltip_ability_special_bonus_hp_regen_10"))
  talentTooltip.SetDialogVariable('name_3', $.Localize("#Dota_tooltip_ability_special_bonus_movement_speed_30"))
  talentTooltip.SetDialogVariable('name_4', $.Localize("#Dota_tooltip_ability_special_bonus_cast_range_250"))
  talentTooltip.SetDialogVariable('name_5', $.Localize("#Dota_tooltip_ability_special_bonus_electrician_absorption_hero_mana_restore").replace("%value%", "2"))
  talentTooltip.SetDialogVariable('name_6', $.Localize("#Dota_tooltip_ability_special_bonus_mp_800"))
  talentTooltip.SetDialogVariable('name_7', $.Localize("#Dota_tooltip_ability_special_bonus_electrician_shock_autoself"))
  talentTooltip.SetDialogVariable('name_8', $.Localize("#Dota_tooltip_ability_special_bonus_hp_1000"))
}

GameEvents.Subscribe( "dota_player_hero_selection_dirty", OnUpdateHeroSelection );

var tooltipManager = FindDotaHudElement("Tooltips");
var altTooltip = tooltipManager.FindChildTraverse('DOTAHUDStatBrnachTooltipAlt');
if(altTooltip==null)
{
  FindDotaHudElement('DOTAHUDStatBrnachTooltipAlt').SetParent(FindDotaHudElement("Tooltips"))
}
FindDotaHudElement('PreGame').FindChildTraverse('Header').style.visibility = 'visible'

$.Msg("PlayerID " + Players.GetPlayerSelectedHero(Players.GetLocalPlayer()))

