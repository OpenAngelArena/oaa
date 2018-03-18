/* global $, GameEvents, DOMException */
'use strict';
var ScepterUtils = /** @class */ (function () {
  function ScepterUtils () {
  }
  ScepterUtils.FindDotaHudElement = function (id) {
    return ScepterUtils.GetDotaHud().FindChildTraverse(id);
  };
  ScepterUtils.GetDotaHud = function () {
    var p = $.GetContextPanel();
    while (p !== null && p.id !== 'Hud') {
      p = p.GetParent();
    }
    if (p === null) {
      throw new DOMException('Could not find Hud root as parent of panel with id: ' + $.GetContextPanel().id);
    } else {
      return p;
    }
  };
  return ScepterUtils;
}());
function UpdateTalentBranchOption (talentSideRoot, isRightSide, isUpgrade) {
  if (talentSideRoot == null) {
    $.Msg('ScepterUpgrade - Root not found');
    return;
  }
  if (talentSideRoot.BHasClass('BranchChosen')) {
    $.Msg('ScepterUpgrade - Branch chosen by player');
    return;
  }
  var label = talentSideRoot.FindChildrenWithClassTraverse('StatBonusLabel')[0];
  if (isUpgrade) {
    label.style.textShadow = '0px 0px 1px 1.3 #EC780E24';
    label.style.color = '#E7D29188';
  } else {
    label.style.textShadow = '1px 1px 2px 2.0 #00000066';
    label.style.color = '#676E70';
  }
  var scepterImage = talentSideRoot.FindChildTraverse('scepterUpgrade');
  if (scepterImage === null) {
    scepterImage = $.CreatePanel('Panel', talentSideRoot, 'scepterUpgrade');
  }
  scepterImage.style.minHeight = '22px';
  scepterImage.style.minWidth = '22px';
  scepterImage.style.backgroundColor = 'transparent';
  scepterImage.style.backgroundSize = '100% 100%';
  scepterImage.style.backgroundImage = "url('s2r://panorama/images/spellicons/aghsicon_psd.vtex')";
  scepterImage.style.verticalAlign = 'center';
  scepterImage.style.horizontalAlign = isRightSide ? 'right' : 'left';
  scepterImage.style.opacity = isUpgrade ? '0.2' : '0';
}
function UpdateTalentTreeBranch (level, isRightSide, isUpgrade) {
  var root = ScepterUtils.FindDotaHudElement('StatPipContainer');
  var talentTreeRowIds = ['undefined', 'StatRow10', 'StatRow15', 'StatRow20', 'StatRow25'];
  if ((root.BHasClass('RightBranchSelected') && isRightSide) ||
        (root.BHasClass('LeftBranchSelected') && !isRightSide) || level < 1 || level > 4) {
    $.Msg('ScepterUpgrade - side is already selected or out of range');
    return;
  }
  var talentTreeLvl = root.FindChildTraverse(talentTreeRowIds[level]);
  var treeBranchClass = isRightSide ? 'RightBranchPip' : 'LeftBranchPip';
  talentTreeLvl.FindChildrenWithClassTraverse(treeBranchClass)[0].style.opacity = isUpgrade ? '1' : '0';
}
function FindTalentSideRootPanel (level, isRightSide) {
  $.Msg('UpgradeOption' + level.toString());
  var upgradeTalentRoot = ScepterUtils.FindDotaHudElement('StatBranchColumn').FindChildTraverse('UpgradeOption' + level.toString());
  var upgradeNumber = isRightSide ? (level - 1) * 2 + 1 : (level - 1) * 2 + 2;
  $.Msg('Upgrade' + upgradeNumber.toString());
  return upgradeTalentRoot.FindChildTraverse('Upgrade' + upgradeNumber.toString());
}
// For Testing on script reload
// let args = new ScepterUpgradeEvtArgs();
// args.IsRightSide = true;
// args.IsUpgrade = true;
// args.Level = '15';
// let lvlMap : { [index:string] : number } = { '10' : 1, '15' : 2, '20' : 3, '25' : 4  };
// UpdateTalentBranchOption(FindTalentSideRootPanel(lvlMap[args.Level], args.IsRightSide), args.IsRightSide, args.IsUpgrade);
// UpdateTalentTreeBranch(lvlMap[args.Level], args.IsRightSide, args.IsUpgrade);
GameEvents.Subscribe('oaa_scepter_upgrade', function (args) {
  var lvlMap = { '10': 1, '15': 2, '20': 3, '25': 4 };
  UpdateTalentBranchOption(FindTalentSideRootPanel(lvlMap[args.Level], args.IsRightSide), args.IsRightSide, args.IsUpgrade);
  UpdateTalentTreeBranch(lvlMap[args.Level], args.IsRightSide, args.IsUpgrade);
});
