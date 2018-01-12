declare function FindDotaHudElement(param1: string): Panel;

interface StateChangeEvtArgs
{
  newState : number;
}
interface GlyphScanEvtArgs
{
  cooldown : number;
  maxCooldown : number;
}

class GlyphScanContainer {
  // Instance variables
  root : Panel
  GlyphIcon: ImagePanel;
  GlyphCooldown: Panel;
  RadarIcon: ImagePanel;
  RadarCooldown: Panel;

  // constructor
  constructor() {
    this.root = FindDotaHudElement('GlyphScanContainer');

    this.GlyphIcon =  <ImagePanel>this.root.FindChildTraverse('GlyphButton');

    this.RadarIcon = <ImagePanel>this.root.FindChildTraverse('RadarIcon');
  }

  Initialize()
  {
    this.InitializeCooldownOverlays()
    controller.StartGlyphCooldown(0);
    controller.StartRadarCooldown(0);
  }

  SetGlyphIcon(isActive : boolean)
  {
    if(isActive)
    {
      this.GlyphIcon.style.backgroundImage ='url("file://{resources}/images/hud/reborn/poop_ward.png")';
    }
    else
    {
      this.GlyphIcon.style.backgroundImage ='url("file://{resources}/images/hud/reborn/poop_ward_inactive.png")';
    }
  }

  SetRadarIcon(isActive : boolean)
  {
    if(isActive)
    {
      this.RadarIcon.style.backgroundImage ='url("s2r://panorama/images/hud/reborn/icon_scan_on_psd.vtex")';
    }
    else
    {
      this.RadarIcon.style.backgroundImage ='url("s2r://panorama/images/hud/reborn/icon_scan_off_psd.vtex")';
    }
  }

  InitializeCooldownOverlays()
  {
    // disable default Dota cover because it starts the game with style changed by script that we can't override
    let vanilaRadarCD = this.root.FindChildTraverse('CooldownCover');
    vanilaRadarCD.visible = false;
    vanilaRadarCD.style.opacity = "0";

    let radarCD =  this.root.FindChildTraverse('OAARadarCooldown');
    if(radarCD == null)
    {
      radarCD = $('#OAARadarCooldown');
      radarCD.SetParent(vanilaRadarCD.GetParent())
    }
    this.RadarCooldown = radarCD;

    let vanilaGlyphCD = this.root.FindChildTraverse('GlyphCooldown');
    vanilaGlyphCD.visible = false;
    vanilaGlyphCD.style.opacity = "0";

    let glyphCD =  this.root.FindChildTraverse('OAAGlyphCooldown');
    if(glyphCD == null)
    {
      glyphCD = $('#OAAGlyphCooldown');
      glyphCD.SetParent(vanilaGlyphCD.GetParent())
    }
    this.GlyphCooldown = glyphCD;


    radarCD = $.GetContextPanel().FindChildTraverse('OAARadarCooldown');
    if(radarCD != null) radarCD.DeleteAsync(1)
    glyphCD = $.GetContextPanel().FindChildTraverse('OAAGlyphCooldown');
    if(glyphCD != null) glyphCD.DeleteAsync(1)
  }

  StartPanelCooldown(panel: Panel, duration: number )
  {
    panel.style.visibility = 'visible';

    $.Msg('StartingCooldown for ' + panel.id );
    panel.style.opacity = "1";
    panel.style.transitionDuration = duration + "s ";
    panel.style.clip = "radial(50% 50%, 0deg, 0deg)";

    //Schedule hiding of the panel
    $.Schedule(duration, function() {
      $.Msg('FinishCooldown for ' + panel.id );
      panel.style.transitionDuration = 0 + "s ";
      panel.style.clip = "radial(50% 50%, 0deg, -360deg)";
      panel.style.visibility = 'collapse';
      panel.style.opacity = "0";
    });
  }

  StartGlyphCooldown(duration: number)
  {
    let scope = this;
    this.SetGlyphIcon(false);
    this.StartPanelCooldown(this.GlyphCooldown, duration)
    $.Schedule(duration, function() {
      scope.SetGlyphIcon(true);
    });
  }

  StartRadarCooldown(duration: number)
  {
    let scope = this;
    this.SetRadarIcon(false);
    this.StartPanelCooldown(this.RadarCooldown, duration)
    $.Schedule(duration, function() {
      scope.SetRadarIcon(true);
    });
  }
}

let controller = new GlyphScanContainer();

if(Game.GameStateIsBefore(DOTA_GameState.DOTA_GAMERULES_STATE_GAME_IN_PROGRESS))
{
  GameEvents.Subscribe('oaa_state_change', (args: StateChangeEvtArgs) => {
    controller.Initialize();
    // Initial Dota Radar Cooldown
  });
  GameEvents.Subscribe('glyph_scan_cooldown', (args: GlyphScanEvtArgs) => {
    $.Msg('Panorama Recieve SCAN');
    controller.StartRadarCooldown(args.maxCooldown);
  });
  GameEvents.Subscribe('glyph_ward_cooldown', (args: GlyphScanEvtArgs) => {
    $.Msg('Panorama Recieve GLYPH');
    controller.StartGlyphCooldown(args.maxCooldown);
  });
}
else
{
  controller.Initialize();
  GameEvents.Subscribe('glyph_scan_cooldown', (args: GlyphScanEvtArgs) => {
    $.Msg('Panorama Recieve SCAN');
    controller.StartRadarCooldown(args.maxCooldown);
  });
  GameEvents.Subscribe('glyph_ward_cooldown', (args: GlyphScanEvtArgs) => {
    $.Msg('Panorama Recieve GLYPH');
    controller.StartGlyphCooldown(args.maxCooldown);
  });
  //controller.StartGlyphCooldown(30);
  //controller.StartRadarCooldown(30);
}


