/*
    Typescript definition file of the DotA 2 Panorama API.

    This file contains information on the Panel hierarchy and how it should be used. This file can be used
    just as reference, or when writing Typescript to compile into Panorama JS.

    To use this file with typescript for Panorama, install typescript and put this file at the project root.

    Any javascript compiled from this typescript should be Panorama-compatible and run in Panorama.
    Issues or bugs in the definitions can be reported by making an issue on GitHub:
    https://github.com/ModDota/API.
*/

interface Panel {
  paneltype: string;
  rememberchildfocus: boolean;
  style: VCSSStyleDeclaration;

  scrolloffset_x: number;
  scrolloffset_y: number;

  actualxoffset: number;
  actualyoffset: number;

  actuallayoutwidth: number;
  actuallayoutheight: number;

  desiredlayoutwidth: number;
  desiredlayoutheight: number;

  contentwidth: number;
  contentheight: number;

  layoutfile: string;
  id: string;

  selectionpos_x: Object;
  selectionpos_y: Object;

  tabindex: Object;

  hittestchildren: boolean;
  hittest: boolean;
  inputnamespace: string;
  defaultfocus: string;

  checked: boolean;
  enabled: boolean;
  visible: boolean;

  AddClass(name: string): void;
  RemoveClass(name: string): void;
  BHasClass(name: string): boolean;
  SetHasClass(name: string, active: boolean): void;
  ToggleClass(name: string): void;
  SwitchClass(name: string, replacement: string): void;

  ClearPanelEvent(): void;

  SetDraggable(): void;
  IsDraggable(): boolean;

  GetChildCount(): number;
  GetChild(index: number): Panel;
  GetChildIndex(child: Panel): number;
  Children(): Panel[];

  FindChildrenWithClassTraverse(classname: string): Panel[];

  GetParent(): Panel;
  SetParent(parent: Panel): void;

  FindChild(childid: string): Panel;
  FindChildTraverse(childid: string): Panel;
  FindChildInLayoutFile(childid: string): Panel; // ??? needs layout file param?

  RemoveAndDeleteChildren(): void;

  MoveChildBefore(child: Panel, beforeChild: Panel): void;
  MoveChildAfter(child: Panel, afterChild: Panel): void;

  GetPositionWithinWindow(): {x: number, y: number};
  ApplyStyles(): void; // ???????
  ClearPropertyFromCode(): void;

  DeleteAsync(time: number): void;

  BIsTransparent(): boolean;
  BAcceptsInput(): boolean;
  BAcceptsFocus(): boolean;
  SetFocus(): void; // ??
  UpdateFocusInContext(): void; // ??

  BHasHoverStyle(): boolean;
  SetAcceptsFocus(value: boolean): void; // ??
  SetDisableFocusOnMouseDown(value: boolean): void; // ??
  BHasKeyFocus(): boolean;
  SetScrollParentToFitWhenFocused(value: boolean): void; // ??
  BScrollParentToFitWhenFocussed(): boolean;

  IsSelected(): boolean;
  BHasDescendantKeyFocus(): boolean;

  BLoadLayout(path: string, bool1: boolean, bool2: boolean): boolean;
  BLoadLayoutFromString(layout: string): boolean;
  BLoadLayoutFromStringAsync(layout: string, callback: () => void): boolean;
  BLoadLayoutAsync(path: string, callback: () => void): boolean;
  BLoadLayoutSnippet(snippetname: string): boolean;
  BCreateChildren(html: string): boolean;

  SetTopOfInputContext(): void; // ????
  SetDialogVariable(name: string, value: any): void;
  SetDialogVariableInt(name: string, value: number): void;

  ScrollToTop(): void;
  ScrollToBottom(): void;
  ScrollToLeftEdge(): void;
  ScrollTORightEdge(): void;

  ScrollParentTOMakePanelFit(): void;
  BCanSeeInParentScroll(): boolean;

  GetAttributeInt(name: string, defaultvalue: number): number;
  GetAttributeString(name: string, defaultvalue: number): string;
  GetAttributeUInt32(name: string, defaultvalue: number): number;
  SetAttributeInt(name: string, value: number): void;
  SetAttributeString(name: string, value: string): void;
  SetAttributeUInt32(name: string, value: number): void;

  SetInputNamespace(naespace: string): void; // ??

  RegisterForReadyEvents(callback: (event: object) => void): void; // ????

  BReadyForDisplay(): boolean;
  SetReadyForDisplay(value: boolean): void; // ???
  SetPanelEvent(event: PanelEvent, handler: () => void): void;

  RunScriptInPanelContext(script: string): void;
}

interface VCSSStyleDeclaration extends CSSStyleDeclaration {
  x: string;
  y: string;
  contrast: string;
  hueRotation: string;
  brightness: string;
}

interface LabelPanel extends Panel {
  text: string;
  html: boolean;
}

declare const enum PanelEvent {
  ON_LEFT_CLICK = "onactivate",
  ON_RIGHT_CLICK = "oncontextmenu",
  ON_MOUSE_OVER = "onmouseover",
  ON_MOUSE_OUT = "onmouseout",
  ON_ESCAPE_PRESS = "oncancel"
}

declare const enum ScalingFunction {
  NONE = "none",
  STRETCH = "stretch", // the default
  STRETCH_X = "stretchx",
  STRETCH_Y = "stretchy",
  STRETCH_TO_FIT_PRESERVE_ASPECT = "stretch-to-fit-preserve-aspect",
  STRETCH_TO_FIT_X_PRESERVE_ASPECT = "stretch-to-fit-x-preserve-aspect",
  STRETCH_TO_FIT_Y_PRESERVE_ASPECT = "stretch-to-fit-y-preserve-aspect",
  STRETCH_TO_COVER_PRESERVE_ASPECT = "stretch-to-cover-preserve-aspect"
}

interface ImagePanel extends Panel {
  /**
   * Sets the image of this Image.
   * Example: image.SetImage("s2r://panorama/images/hud/hudv2_iconglyph.png")
   */
  SetImage(path: string): void;
  SetScaling(scale: ScalingFunction): void;
}

interface AbilityImage extends ImagePanel {
  abilityname: string;
  contextEntityIndex: number;
}

interface ItemImage extends ImagePanel {
  itemname: string;
  contextEntityIndex: number;
}

interface ContextMenuScriptPanel extends Panel {
  GetContentsPanel(): Panel;
}

interface ScenePanel extends Panel {
  FireEntityInput(entityID: string, inputName: string, value: string): void;
  PlayEntitySoundEvent(arg1: any, arg2: any): number;
  SetUnit(unitName: string, environment: string): void;
  GetPanoramaSurfacePanel(): Panel;
}

//Only put single string literals in here, it'll be merged with the main one
interface DollarStatic {
  CreatePanel(type: "Label", root: Panel, name: string): LabelPanel;
  CreatePanel(type: "Image", root: Panel, name: string): ImagePanel;
  CreatePanel(type: "DOTAAbilityImage", root: Panel, name: string): AbilityImage;
  CreatePanel(type: "DOTAItemImage", root: Panel, name: string): ItemImage;
  CreatePanel(type: "Image", root: Panel, name: string): ImagePanel;
  CreatePanel(type: "ContextMenuScript", root: Panel, name: String): ContextMenuScriptPanel;
  CreatePanel(type: "DOTAScenePanel", root: Panel, name: String): ScenePanel;
}
