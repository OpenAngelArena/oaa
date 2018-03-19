/* global FindDotaHudElement, $, GameEvents */
'use strict';

interface ScepterUpgradeEvtArgs
{
  IsRightSide : boolean;
  IsUpgrade : boolean;
  Level : string;
}

function UpdateTalentBranchOption(talentSideRoot: Panel, isRightSide: boolean, isUpgrade: boolean)
{
  if (talentSideRoot == null){
    $.Msg('ScepterUpgrade - Root not found')
    return;
  }

  if(talentSideRoot.BHasClass('BranchChosen'))
  {
    $.Msg('ScepterUpgrade - Branch chosen by player')
    return;
  }

  let label = talentSideRoot.FindChildrenWithClassTraverse('StatBonusLabel')[0];
  if(isUpgrade) {
    label.style.textShadow = '0px 0px 1px 1.3 #EC780E24';
    label.style.color = '#E7D29188';
  }
  else {
    label.style.textShadow = '1px 1px 2px 2.0 #00000066';
    label.style.color = '#676E70';
  }

  let scepterImage = talentSideRoot.FindChildTraverse('scepterUpgrade');
  if(scepterImage === null)
  {
    scepterImage = $.CreatePanel('Panel', talentSideRoot, 'scepterUpgrade');
  }
  scepterImage.style.minHeight = '22px';
  scepterImage.style.minWidth = '22px';
  scepterImage.style.backgroundColor = 'transparent';
  scepterImage.style.backgroundSize = '100% 100%';
  scepterImage.style.backgroundImage = "url('s2r://panorama/images/spellicons/aghsicon_psd.vtex')";
  scepterImage.style.verticalAlign = 'center';
  scepterImage.style.horizontalAlign = isRightSide? 'right' : 'left';
  scepterImage.style.opacity = isUpgrade? '0.2' : '0';
}

function UpdateTalentTreeBranch(level: number, isRightSide: boolean, isUpgrade: boolean)
{
  let root = FindDotaHudElement('StatPipContainer');
  let talentTreeRowIds= ['undefined', 'StatRow10', 'StatRow15', 'StatRow20', 'StatRow25'];
  if( (root.BHasClass('RightBranchSelected') && isRightSide) ||
    (root.BHasClass('LeftBranchSelected') && !isRightSide) || level < 1 || level > 4){
      $.Msg('ScepterUpgrade - side is already selected or out of range')
      return;
    }
  let talentTreeLvl = root.FindChildTraverse(talentTreeRowIds[level]);

  let treeBranchClass = isRightSide? 'RightBranchPip' : 'LeftBranchPip';
  talentTreeLvl.FindChildrenWithClassTraverse(treeBranchClass)[0].style.opacity = isUpgrade? '1' : '0';
}

function FindTalentSideRootPanel(level : number, isRightSide : boolean) : Panel
{
  $.Msg('UpgradeOption' + level.toString());
  let upgradeTalentRoot = FindDotaHudElement('StatBranchColumn').FindChildTraverse('UpgradeOption' + level.toString());
  let upgradeNumber = isRightSide? (level -1)*2 + 1 : (level -1)*2 + 2;
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

GameEvents.Subscribe('oaa_scepter_upgrade', (args: ScepterUpgradeEvtArgs) => {
  let lvlMap : { [index:string] : number } = { '10' : 1, '15' : 2, '20' : 3, '25' : 4  };

  UpdateTalentBranchOption(FindTalentSideRootPanel(lvlMap[args.Level], args.IsRightSide), args.IsRightSide, args.IsUpgrade);
  UpdateTalentTreeBranch(lvlMap[args.Level], args.IsRightSide, args.IsUpgrade);
});
