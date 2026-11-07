{ A title bar drawn by the application: icon, title and minimize, maximize and close buttons.

  This unit is the element and knows no platform. A TRibbonWindowFrame connects it to the window;
  ohsribbon.ui.titlebar.native has the frames for Windows and Linux. Without a frame the bar only draws.

  The look is CSS: every colour is a --titlebar-* variable, see cTitleBarCSS. }
unit ohsribbon.ui.titlebar;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpCSSTree, fpCSSResParser, Fresnel.Classes, Fresnel.DOM, Fresnel.Controls, Fresnel.Events, Fresnel.Menus, FCL.Events;

type
  // What is under the mouse.
  TTitleBarHit = (tbhClient, tbhCaption, tbhIcon, tbhMinimize, tbhMaximize, tbhClose);
  TTitleBarButton = tbhMinimize..tbhClose;

  TRibbonTitleBar = class;

  { Connects a title bar to its window. }
  TRibbonWindowFrame = class
  private
    FBar: TRibbonTitleBar;
  protected
    // Tell the bar that the state of the window changed.
    procedure Changed;
    function GetActive: Boolean; virtual; abstract;
    function GetMaximized: Boolean; virtual; abstract;
    // Only for a frame that follows the mouse itself; otherwise CSS :hover does this.
    function GetHot: TTitleBarHit; virtual;
    function GetPressed: TTitleBarHit; virtual;
  public
    procedure Minimize; virtual; abstract;
    procedure ToggleMaximize; virtual; abstract;
    procedure Close; virtual; abstract;
    // Start moving the window with the left mouse button that is down now. The mouse has already
    // come this far from where it was pressed, which the window has to catch up with.
    procedure BeginMove(aDeltaX, aDeltaY: TFresnelLength); virtual; abstract;
    // Open the window menu of the system. False if it has none; the bar then opens its own.
    function ShowMenu: Boolean; virtual; abstract;
    property Bar: TRibbonTitleBar read FBar;
    property Active: Boolean read GetActive;
    property Maximized: Boolean read GetMaximized;
    property Hot: TTitleBarHit read GetHot;
    property Pressed: TTitleBarHit read GetPressed;
  end;

  { TRibbonTitleBar }

  TRibbonTitleBar = class(TDiv)
  private
    class var FTypeID: TCSSNumericalID;
    class constructor InitTypeID;
  private
    FFrame: TRibbonWindowFrame;
    FIcon: TDiv;
    FTitle: TLabel;
    FButtons: array[TTitleBarButton] of TDiv;
    // Pressed on the caption, and not moved far enough yet to start moving the window.
    FMoveArmed: Boolean;
    FMoveStartX, FMoveStartY: TFresnelLength;
    FMovePointer: TFreHandle;
    FMenu: TPopupMenu;
    FMenuRestore, FMenuMinimize, FMenuMaximize, FMenuClose: TMenuItem;
    function GetCaption: string;
    procedure SetCaption(const aValue: string);
    procedure SetFrame(aValue: TRibbonWindowFrame);
    function AddGlyph(aParent: TFresnelElement; const aClass: string): TDiv;
    procedure ShowMaximizeGlyph(aMaximized: Boolean);
    procedure DisarmMove;
    function AddMenuItem(const aCaption: string): TMenuItem;
    procedure OpenMenu(aX, aY: TFresnelLength);
    procedure MenuClick(Sender: TObject);
    procedure HandleMouseDown(aEvent: TAbstractEvent);
    procedure HandleMouseMove(aEvent: TAbstractEvent);
    procedure HandleMouseUp(aEvent: TAbstractEvent);
    procedure HandleButtonClick(aEvent: TAbstractEvent);
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    class function CSSTypeID: TCSSNumericalID; override;
    class function CSSTypeName: TCSSString; override;
    class function GetCSSTypeStyle: TCSSString; override;
    // What is at this point of the viewport.
    function HitTest(aX, aY: TFresnelLength): TTitleBarHit;
    // Show the state of the frame.
    procedure FrameChanged;
    property Caption: string read GetCaption write SetCaption;
    // The bar owns its frame.
    property Frame: TRibbonWindowFrame read FFrame write SetFrame;
    property Icon: TDiv read FIcon;
    // The menu for a system without one. Nil until it was needed.
    property Menu: TPopupMenu read FMenu;
  end;

implementation

resourcestring
  rsTitleBarRestore = 'Restore';
  rsTitleBarMinimize = 'Minimize';
  rsTitleBarMaximize = 'Maximize';
  rsTitleBarClose = 'Close';

const
  // How far the mouse moves with the button down before that is a move and not a click, in pixels.
  cMoveThreshold = 4;

  cTitleBarCSS =
    'ribbontitlebar { --titlebar-bg: #33658a; --titlebar-text: #ffffff; --titlebar-hover: #4a7ca1;'
    +' --titlebar-pressed: #5b8bae; --titlebar-inactive: #7d8c98; --titlebar-inactive-text: #ffffff;'
    +' --titlebar-close-hover: #c42b2b; --titlebar-close-pressed: #a82424;'
    +' display: flex; flex-direction: row; align-items: center; flex-shrink: 0; height: 32px;'
    +' background-color: var(--titlebar-bg); color: var(--titlebar-text); font-size: 12px; }'
    +' @media (prefers-color-scheme: dark) { ribbontitlebar { --titlebar-bg: #1b1b1c;'
    +' --titlebar-text: #e6e6e6; --titlebar-hover: #3d3d40; --titlebar-pressed: #4a4a4e;'
    +' --titlebar-inactive: #2b2b2c; --titlebar-inactive-text: #a6a6a6; } }'
    +' ribbontitlebar.titlebar-inactive { background-color: var(--titlebar-inactive);'
    +' color: var(--titlebar-inactive-text); }'
    +' ribbontitlebar.titlebar-hidden { display: none; }'
    +' .titlebar-icon { flex-shrink: 0; align-self: stretch; width: 34px; display: flex;'
    +' align-items: center; justify-content: center; }'
    +' .titlebar-logo { width: 14px; height: 14px; border-radius: 3px; background-color: var(--titlebar-text); }'
    +' .titlebar-title { flex-grow: 1; min-width: 0; white-space: nowrap; overflow: hidden; }'
    +' .titlebar-button { position: relative; flex-shrink: 0; width: 46px; height: 32px; }'
    +' .titlebar-button:hover, .titlebar-button.titlebar-hot { background-color: var(--titlebar-hover); }'
    +' .titlebar-button:active, .titlebar-button.titlebar-down { background-color: var(--titlebar-pressed); }'
    +' .titlebar-button.titlebar-close:hover, .titlebar-button.titlebar-close.titlebar-hot'
    +' { background-color: var(--titlebar-close-hover); }'
    +' .titlebar-button.titlebar-close:active, .titlebar-button.titlebar-close.titlebar-down'
    +' { background-color: var(--titlebar-close-pressed); }'
    +' .titlebar-glyph { position: absolute; }'
    +' .titlebar-line { left: 18px; top: 16px; width: 10px; height: 1px; background-color: var(--titlebar-text); }'
    +' .titlebar-box { left: 18px; top: 11px; width: 10px; height: 10px; box-sizing: border-box;'
    +' border: 1px solid var(--titlebar-text); }'
    +' .titlebar-back { left: 20px; top: 11px; width: 8px; height: 8px; box-sizing: border-box;'
    +' border-top: 1px solid var(--titlebar-text); border-right: 1px solid var(--titlebar-text); }'
    +' .titlebar-front { left: 18px; top: 13px; width: 8px; height: 8px; box-sizing: border-box;'
    +' border: 1px solid var(--titlebar-text); }'
    +' .titlebar-cross1, .titlebar-cross2 { left: 17px; top: 16px; width: 12px; height: 1px;'
    +' background-color: var(--titlebar-text); }'
    +' .titlebar-cross1 { transform: rotate(45deg); }'
    +' .titlebar-cross2 { transform: rotate(-45deg); }';

procedure SetClass(aElement: TFresnelElement; const aClass: string; aOn: Boolean);
begin
  if aOn=aElement.HasCSSClass(aClass) then
    Exit;
  if aOn then
    aElement.AddCSSClass(aClass)
  else
    aElement.RemoveCSSClass(aClass);
end;

{ TRibbonWindowFrame }

procedure TRibbonWindowFrame.Changed;
begin
  if FBar<>nil then
    FBar.FrameChanged;
end;

function TRibbonWindowFrame.GetHot: TTitleBarHit;
begin
  Result:=tbhClient;
end;

function TRibbonWindowFrame.GetPressed: TTitleBarHit;
begin
  Result:=tbhClient;
end;

{ TRibbonTitleBar }

class constructor TRibbonTitleBar.InitTypeID;
begin
  FTypeID:=CSSRegistry.AddType(CSSTypeName).Index;
end;

constructor TRibbonTitleBar.Create(aOwner: TComponent);
var
  lLogo: TDiv;
  b: TTitleBarButton;
begin
  inherited Create(aOwner);
  FIcon:=TDiv.Create(Self);
  FIcon.AddCSSClass('titlebar-icon');
  FIcon.Parent:=Self;
  lLogo:=TDiv.Create(Self);
  lLogo.AddCSSClass('titlebar-logo');
  lLogo.Parent:=FIcon;
  FTitle:=TLabel.Create(Self);
  FTitle.AddCSSClass('titlebar-title');
  FTitle.Parent:=Self;
  for b:=Low(TTitleBarButton) to High(TTitleBarButton) do
  begin
    FButtons[b]:=TDiv.Create(Self);
    FButtons[b].AddCSSClass('titlebar-button');
    FButtons[b].Parent:=Self;
    FButtons[b].AddEventListener(evtClick,@HandleButtonClick);
  end;
  AddGlyph(FButtons[tbhMinimize],'titlebar-line');
  ShowMaximizeGlyph(False);
  FButtons[tbhClose].AddCSSClass('titlebar-close');
  AddGlyph(FButtons[tbhClose],'titlebar-cross1');
  AddGlyph(FButtons[tbhClose],'titlebar-cross2');
  AddEventListener(evtMouseDown,@HandleMouseDown);
  AddEventListener(evtMouseMove,@HandleMouseMove);
  AddEventListener(evtMouseUp,@HandleMouseUp);
end;

destructor TRibbonTitleBar.Destroy;
begin
  FreeAndNil(FFrame);
  inherited Destroy;
end;

class function TRibbonTitleBar.CSSTypeID: TCSSNumericalID;
begin
  Result:=FTypeID;
end;

class function TRibbonTitleBar.CSSTypeName: TCSSString;
begin
  Result:='ribbontitlebar';
end;

class function TRibbonTitleBar.GetCSSTypeStyle: TCSSString;
begin
  Result:=cTitleBarCSS;
end;

function TRibbonTitleBar.GetCaption: string;
begin
  Result:=FTitle.Caption;
end;

procedure TRibbonTitleBar.SetCaption(const aValue: string);
begin
  FTitle.Caption:=aValue;
end;

procedure TRibbonTitleBar.SetFrame(aValue: TRibbonWindowFrame);
begin
  if FFrame=aValue then
    Exit;
  FreeAndNil(FFrame);
  FFrame:=aValue;
  if FFrame<>nil then
  begin
    FFrame.FBar:=Self;
    FrameChanged;
  end;
end;

function TRibbonTitleBar.AddGlyph(aParent: TFresnelElement; const aClass: string): TDiv;
begin
  Result:=TDiv.Create(Self);
  Result.AddCSSClass('titlebar-glyph');
  Result.AddCSSClass(aClass);
  Result.Parent:=aParent;
end;

procedure TRibbonTitleBar.ShowMaximizeGlyph(aMaximized: Boolean);
var
  lButton: TDiv;
begin
  lButton:=FButtons[tbhMaximize];
  if (lButton.NodeCount>0) and (aMaximized=(lButton.NodeCount=2)) then
    Exit;
  while lButton.NodeCount>0 do
    lButton.Nodes[0].Free;
  if aMaximized then
  begin
    AddGlyph(lButton,'titlebar-back');
    AddGlyph(lButton,'titlebar-front');
  end
  else
    AddGlyph(lButton,'titlebar-box');
end;

function TRibbonTitleBar.HitTest(aX, aY: TFresnelLength): TTitleBarHit;
var
  lElement: TFresnelElement;
  b: TTitleBarButton;
begin
  Result:=tbhClient;
  if Viewport=nil then
    Exit;
  lElement:=Viewport.GetElementAt(aX,aY);
  while lElement<>nil do
  begin
    for b:=Low(TTitleBarButton) to High(TTitleBarButton) do
      if lElement=FButtons[b] then
        Exit(b);
    if lElement=FIcon then
      Exit(tbhIcon);
    if lElement=Self then
      Exit(tbhCaption);
    lElement:=lElement.Parent;
  end;
end;

procedure TRibbonTitleBar.FrameChanged;
var
  b: TTitleBarButton;
begin
  if FFrame=nil then
    Exit;
  SetClass(Self,'titlebar-inactive',not FFrame.Active);
  for b:=Low(TTitleBarButton) to High(TTitleBarButton) do
  begin
    SetClass(FButtons[b],'titlebar-hot',FFrame.Hot=b);
    SetClass(FButtons[b],'titlebar-down',FFrame.Pressed=b);
  end;
  ShowMaximizeGlyph(FFrame.Maximized);
end;

procedure TRibbonTitleBar.HandleMouseDown(aEvent: TAbstractEvent);
var
  lEvent: TFresnelMouseEvent;
  lDouble: Boolean;
begin
  if (FFrame=nil) or not (aEvent is TFresnelMouseEvent) then
    Exit;
  lEvent:=TFresnelMouseEvent(aEvent);
  lDouble:=ssDouble in lEvent.ShiftState;
  case HitTest(lEvent.ViewportX,lEvent.ViewportY) of
    tbhCaption:
      if lEvent.Button=mbRight then
        OpenMenu(lEvent.ViewportX,lEvent.ViewportY)
      else if lEvent.Button=mbLeft then
        if lDouble then
          FFrame.ToggleMaximize
        else
        begin
          // Not moving yet: that would take the mouse away, and a double click with it.
          FMoveArmed:=True;
          FMoveStartX:=lEvent.ViewportX;
          FMoveStartY:=lEvent.ViewportY;
          FMovePointer:=nil;
          if lEvent is TFresnelPointerEvent then
            FMovePointer:=TFresnelPointerEvent(lEvent).PointerId;
          // A fast mouse is off the bar before the first move event.
          if FMovePointer<>nil then
            SetPointerCapture(FMovePointer);
        end;
    tbhIcon:
      if lEvent.Button=mbRight then
        OpenMenu(lEvent.ViewportX,lEvent.ViewportY)
      else if lEvent.Button=mbLeft then
        if lDouble then
          FFrame.Close
        else
          OpenMenu(lEvent.ViewportX,lEvent.ViewportY);
  end;
end;

function TRibbonTitleBar.AddMenuItem(const aCaption: string): TMenuItem;
begin
  Result:=TMenuItem.Create(FMenu);
  Result.Caption:=aCaption;
  Result.OnClick:=@MenuClick;
  FMenu.Items.Add(Result);
end;

procedure TRibbonTitleBar.OpenMenu(aX, aY: TFresnelLength);
begin
  if FFrame.ShowMenu then
    Exit;
  if FMenu=nil then
  begin
    FMenu:=TPopupMenu.Create(Self);
    FMenuRestore:=AddMenuItem(rsTitleBarRestore);
    FMenuMinimize:=AddMenuItem(rsTitleBarMinimize);
    FMenuMaximize:=AddMenuItem(rsTitleBarMaximize);
    AddMenuItem('-'); // a line
    FMenuClose:=AddMenuItem(rsTitleBarClose);
  end;
  FMenuRestore.Enabled:=FFrame.Maximized;
  FMenuMaximize.Enabled:=not FFrame.Maximized;
  FMenu.PopUp(Viewport,aX,aY);
end;

procedure TRibbonTitleBar.MenuClick(Sender: TObject);
begin
  if FFrame=nil then
    Exit;
  if Sender=FMenuMinimize then
    FFrame.Minimize
  else if (Sender=FMenuRestore) or (Sender=FMenuMaximize) then
    FFrame.ToggleMaximize
  else if Sender=FMenuClose then
    FFrame.Close;
end;

procedure TRibbonTitleBar.DisarmMove;
begin
  if not FMoveArmed then
    Exit;
  FMoveArmed:=False;
  if FMovePointer<>nil then
    ReleasePointerCapture(FMovePointer);
end;

procedure TRibbonTitleBar.HandleMouseMove(aEvent: TAbstractEvent);
var
  lEvent: TFresnelMouseEvent;
begin
  if (not FMoveArmed) or (FFrame=nil) or not (aEvent is TFresnelMouseEvent) then
    Exit;
  lEvent:=TFresnelMouseEvent(aEvent);
  if (Abs(lEvent.ViewportX-FMoveStartX)<cMoveThreshold)
    and (Abs(lEvent.ViewportY-FMoveStartY)<cMoveThreshold) then
    Exit;
  DisarmMove;
  FFrame.BeginMove(lEvent.ViewportX-FMoveStartX,lEvent.ViewportY-FMoveStartY);
end;

procedure TRibbonTitleBar.HandleMouseUp(aEvent: TAbstractEvent);
begin
  if aEvent=nil then ;
  DisarmMove;
end;

procedure TRibbonTitleBar.HandleButtonClick(aEvent: TAbstractEvent);
begin
  if FFrame=nil then
    Exit;
  if aEvent.Sender=FButtons[tbhMinimize] then
    FFrame.Minimize
  else if aEvent.Sender=FButtons[tbhMaximize] then
    FFrame.ToggleMaximize
  else if aEvent.Sender=FButtons[tbhClose] then
    FFrame.Close;
end;

end.
