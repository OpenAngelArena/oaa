/* global FindDotaHudElement, GameEvents, $, DOTA_GameState, Game */
'use strict';

interface StateChangeEvtArgs
{
  newState : DOTA_GameState;
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
  GlyphTooltip: Panel;
  RadarTooltip: Panel;

  GlyphCDRemain: number;
  RadarCDRemain: number;

  // constructor
  constructor() {
    this.root = FindDotaHudElement('GlyphScanContainer');

    $.GetContextPanel().RemoveAndDeleteChildren();
    let panel = $.CreatePanel('Panel', $.GetContextPanel(), '');
    panel.BLoadLayoutSnippet('CustomGlyphRadarContainerSnippet');


    this.RadarCooldown = $('#OAARadarCooldown');
    this.GlyphCooldown = $('#OAAGlyphCooldown');

    this.RadarIcon = <ImagePanel>this.root.FindChildTraverse('RadarIcon');
    this.GlyphIcon = <ImagePanel>this.root.FindChildTraverse('GlyphButton');

    this.GlyphCooldown.style.clip = 'radial(50% 50%, 0deg, 0deg)';
    this.RadarCooldown.style.clip = 'radial(50% 50%, 0deg, 0deg)';

    this.CreateTooltips();

    this.StartGlyphCooldown(0.1);
    this.StartRadarCooldown(0.1);

    $.Schedule(0.2, () => {
      this.SetRadarIcon(false);
      this.SetGlyphIcon(true);
    });

    // First Cooldown
    (<LabelPanel>this.GlyphTooltip.FindChildTraverse('cooldown_duration')).text = this.NumberToTime(120);
  }

  Initialize()
  {
    this.DisableDotaGlyphAndRadar();
    this.UpdateCooldowns();
    this.StartRadarCooldown(210);

    GameEvents.Subscribe('glyph_scan_cooldown', (args: GlyphScanEvtArgs) => {
      this.StartRadarCooldown(args.maxCooldown);
    });
    GameEvents.Subscribe('glyph_ward_cooldown', (args: GlyphScanEvtArgs) => {
      this.StartGlyphCooldown(args.maxCooldown);
    });

  }

  CreateTooltips()
  {
    this.CreateGlyphTooltip();
    this.CreateRadarTooltip();
  }

  UpdateCooldowns()
  {
    $.Schedule(1, ()=>{
      if(this.GlyphCDRemain > 0)
      {
        this.GlyphCDRemain--;
      }
      if(this.RadarCDRemain > 0)
      {
        this.RadarCDRemain--;
      }

      this.GlyphTooltip.SetHasClass('IsCooldownReady', this.GlyphCDRemain <= 0);
      this.RadarTooltip.SetHasClass('IsCooldownReady', this.RadarCDRemain <= 0);

      this.GlyphTooltip.FindChildTraverse('cooldown_timer_label').SetDialogVariable('cooldown_time', this.NumberToTime(this.GlyphCDRemain));
      this.RadarTooltip.FindChildTraverse('cooldown_timer_label').SetDialogVariable('cooldown_time', this.NumberToTime(this.RadarCDRemain));

      this.UpdateCooldowns();
    })
  }

  NumberToTime (seconds: number) : string
  {
    let date = new Date(0);
    date.setSeconds(seconds);
    return date.toUTCString().substr(21, 4);
  }

  CreateGlyphTooltip ()
  {
    this.GlyphTooltip = $.CreatePanel('Panel', $.GetContextPanel(), '');
    this.GlyphTooltip.BLoadLayoutSnippet('DotaCustomTooltipGlyph');

    this.root.FindChildTraverse('glyph').SetPanelEvent(PanelEvent.ON_MOUSE_OVER , ()=>{
      this.GlyphTooltip.SetHasClass('Hidden', false);
      FindDotaHudElement('DOTAHUDGlyphTooltip').visible = false;
    })

    this.root.FindChildTraverse('glyph').SetPanelEvent(PanelEvent.ON_MOUSE_OUT  , ()=>{
      this.GlyphTooltip.SetHasClass('Hidden', true);
      FindDotaHudElement('DOTAHUDRadarTooltip').visible = false;
    })
  }

  CreateRadarTooltip()
  {
    this.RadarTooltip = $.CreatePanel('Panel', $.GetContextPanel(), '');
    this.RadarTooltip.BLoadLayoutSnippet('DotaCustomTooltipScan');

    this.root.FindChildTraverse('RadarButton').SetPanelEvent(PanelEvent.ON_MOUSE_OVER, ()=>{ this.RadarTooltip.SetHasClass('Hidden', false)})
    this.root.FindChildTraverse('RadarButton').SetPanelEvent(PanelEvent.ON_MOUSE_OUT, ()=>{ this.RadarTooltip.SetHasClass('Hidden', true)})
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

  DisableDotaGlyphAndRadar()
  {
    // disable default Dota cover because it starts the game with style changed by script that we can't override
    let vanilaRadarCD = this.root.FindChildTraverse('CooldownCover');
    vanilaRadarCD.visible = false;
    vanilaRadarCD.style.opacity = '0';

    let vanilaGlyphCD = this.root.FindChildTraverse('GlyphCooldown');
    vanilaGlyphCD.visible = false;
    vanilaGlyphCD.style.opacity = '0';
  }

  StartPanelCooldown(panel: Panel, duration: number, SetIcon: (IsActive: boolean) => void )
  {
    $.Msg('StartingCooldown for ' + panel.id );
    SetIcon(false);
    panel.style.visibility = 'visible'
    panel.style.opacity = '1';
    panel.style.transitionDuration = duration + 's ';
    panel.style.clip = 'radial(50% 50%, 0deg, 0deg)';

    // Schedule hiding of the panel
    $.Schedule(duration, function() {
      $.Msg('FinishCooldown for ' + panel.id );
      panel.style.opacity = '0';
      panel.style.transitionDuration = 0.1 + 's ';
      panel.style.clip = 'radial(50% 50%, 0deg, -359deg)';
      SetIcon(true);
    });
  }

  StartGlyphCooldown(duration: number)
  {
    this.GlyphCDRemain = duration;
    (<LabelPanel>this.GlyphTooltip.FindChildTraverse('cooldown_duration')).text = this.NumberToTime(duration);
    this.StartPanelCooldown(this.GlyphCooldown, duration, (IsActive: boolean) => {
      this.SetGlyphIcon(IsActive);
    });
  }

  StartRadarCooldown(duration: number)
  {
    this.RadarCDRemain = duration;
    (<LabelPanel>this.RadarTooltip.FindChildTraverse('cooldown_duration')).text = this.NumberToTime(duration);
    this.StartPanelCooldown(this.RadarCooldown, duration, (IsActive: boolean) => {
      this.SetRadarIcon(IsActive);
    });
  }
}

let controller = new GlyphScanContainer();
if(!Game.GameStateIsBefore(DOTA_GameState.DOTA_GAMERULES_STATE_GAME_IN_PROGRESS))
{
  controller.Initialize();
}
else
{
  let eventHandler = GameEvents.Subscribe('oaa_state_change', (args: StateChangeEvtArgs) => {
    if(args.newState >=  DOTA_GameState.DOTA_GAMERULES_STATE_GAME_IN_PROGRESS)
    {
      controller.Initialize();
      $.Msg(args.newState);
      GameEvents.Unsubscribe(eventHandler);
    }
  });
}
