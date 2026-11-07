unit utest.ui.titlebar;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, TCCSS, FCL.Events, Fresnel.Events, Fresnel.Classes, Fresnel.DOM, Fresnel.Controls,
  ohsribbon.ui.titlebar;

type
  TFakeFrame = class(TRibbonWindowFrame)
  protected
    function GetActive: Boolean; override;
    function GetMaximized: Boolean; override;
    function GetHot: TTitleBarHit; override;
    function GetPressed: TTitleBarHit; override;
  public
    IsActive, IsMaximized: Boolean;
    SystemHasMenu: Boolean;
    HotButton, PressedButton: TTitleBarHit;
    Minimizes, Toggles, Closes, Moves, Menus: Integer;
    MoveDeltaX, MoveDeltaY: TFresnelLength;
    procedure Minimize; override;
    procedure ToggleMaximize; override;
    procedure Close; override;
    procedure BeginMove(aDeltaX, aDeltaY: TFresnelLength); override;
    function ShowMenu: Boolean; override;
  end;

  TTestTitleBar = class(TCustomTestFresnelCSS)
  private
    FBar: TRibbonTitleBar;
    FFrame: TFakeFrame;
    procedure Build;
    procedure Settle;
    function ButtonOf(aHit: TTitleBarButton): TFresnelElement;
    procedure Mouse(aX, aY: Integer; aButton: TMouseButton; aShift: TShiftState = []);
    procedure MouseEvent(aX, aY: Integer; aEventID: TEventID);
    procedure ClickAt(aX, aY: Integer);
  published
    procedure TestCaption;
    procedure TestHitTest;
    procedure TestHitTestOutsideBar;
    procedure TestButtons;
    procedure TestWithoutFrame;
    procedure TestDragCaptionMoves;
    procedure TestDoubleClickCaptionMaximizes;
    procedure TestRightClickShowsMenu;
    procedure TestIcon;
    procedure TestSystemMenuNeedsNoOwnMenu;
    procedure TestOwnMenuWithoutSystemMenu;
    procedure TestFrameState;
    procedure TestMaximizeGlyph;
  end;

implementation

function TFakeFrame.GetActive: Boolean;
begin
  Result:=IsActive;
end;

function TFakeFrame.GetMaximized: Boolean;
begin
  Result:=IsMaximized;
end;

function TFakeFrame.GetHot: TTitleBarHit;
begin
  Result:=HotButton;
end;

function TFakeFrame.GetPressed: TTitleBarHit;
begin
  Result:=PressedButton;
end;

procedure TFakeFrame.Minimize;
begin
  Inc(Minimizes);
end;

procedure TFakeFrame.ToggleMaximize;
begin
  Inc(Toggles);
end;

procedure TFakeFrame.Close;
begin
  Inc(Closes);
end;

procedure TFakeFrame.BeginMove(aDeltaX, aDeltaY: TFresnelLength);
begin
  Inc(Moves);
  MoveDeltaX:=aDeltaX;
  MoveDeltaY:=aDeltaY;
end;

function TFakeFrame.ShowMenu: Boolean;
begin
  Inc(Menus);
  Result:=SystemHasMenu;
end;

procedure TTestTitleBar.Build;
begin
  Viewport.Width:=800;
  Viewport.Height:=400;
  FBar:=TRibbonTitleBar.Create(Viewport);
  FBar.Parent:=CreateBody;
  FBar.Caption:='Title';
  FFrame:=TFakeFrame.Create;
  FFrame.IsActive:=True;
  FFrame.SystemHasMenu:=True;
  FFrame.HotButton:=tbhClient;
  FFrame.PressedButton:=tbhClient;
  FBar.Frame:=FFrame;
  Settle;
end;

procedure TTestTitleBar.Settle;
var
  i: Integer;
begin
  for i:=1 to 5 do
    Viewport.ApplyCSS;
end;

function TTestTitleBar.ButtonOf(aHit: TTitleBarButton): TFresnelElement;
begin
  // Icon, title, then the three buttons in order.
  Result:=FBar.Nodes[2+Ord(aHit)-Ord(tbhMinimize)];
end;

procedure TTestTitleBar.Mouse(aX, aY: Integer; aButton: TMouseButton; aShift: TShiftState);
var
  lInit: TFresnelMouseEventInit;
begin
  lInit:=Default(TFresnelMouseEventInit);
  lInit.ViewportPos.X:=aX;
  lInit.ViewportPos.Y:=aY;
  lInit.PagePos:=lInit.ViewportPos;
  lInit.Button:=aButton;
  lInit.Shiftstate:=aShift;
  Viewport.WSMouseXY(lInit,evtMouseDown);
end;

procedure TTestTitleBar.MouseEvent(aX, aY: Integer; aEventID: TEventID);
var
  lInit: TFresnelMouseEventInit;
begin
  lInit:=Default(TFresnelMouseEventInit);
  lInit.ViewportPos.X:=aX;
  lInit.ViewportPos.Y:=aY;
  lInit.PagePos:=lInit.ViewportPos;
  lInit.Button:=mbLeft;
  Viewport.WSMouseXY(lInit,aEventID);
end;

procedure TTestTitleBar.ClickAt(aX, aY: Integer);
var
  lInit: TFresnelMouseEventInit;
begin
  Mouse(aX,aY,mbLeft);
  lInit:=Default(TFresnelMouseEventInit);
  lInit.ViewportPos.X:=aX;
  lInit.ViewportPos.Y:=aY;
  lInit.PagePos:=lInit.ViewportPos;
  lInit.Button:=mbLeft;
  Viewport.WSMouseXY(lInit,evtMouseUp);
end;

procedure TTestTitleBar.TestCaption;
begin
  Build;
  AssertEquals('Title',FBar.Caption);
  FBar.Caption:='Other';
  AssertEquals('Other',FBar.Caption);
end;

procedure TTestTitleBar.TestHitTest;
begin
  Build;
  AssertTrue('close',FBar.HitTest(780,16)=tbhClose);
  AssertTrue('maximize',FBar.HitTest(730,16)=tbhMaximize);
  AssertTrue('minimize',FBar.HitTest(680,16)=tbhMinimize);
  AssertTrue('caption',FBar.HitTest(400,16)=tbhCaption);
  AssertTrue('icon',FBar.HitTest(10,16)=tbhIcon);
end;

procedure TTestTitleBar.TestHitTestOutsideBar;
begin
  Build;
  AssertTrue(FBar.HitTest(400,200)=tbhClient);
end;

procedure TTestTitleBar.TestButtons;
begin
  Build;
  ClickAt(680,16);
  AssertEquals('minimize',1,FFrame.Minimizes);
  ClickAt(730,16);
  AssertEquals('maximize',1,FFrame.Toggles);
  ClickAt(780,16);
  AssertEquals('close',1,FFrame.Closes);
end;

procedure TTestTitleBar.TestWithoutFrame;
begin
  Build;
  FBar.Frame:=nil;
  ClickAt(780,16);
  Mouse(400,16,mbLeft);
  AssertNull(FBar.Frame);
end;

procedure TTestTitleBar.TestDragCaptionMoves;
begin
  Build;
  Mouse(400,16,mbLeft);
  AssertEquals('a press alone does not move',0,FFrame.Moves);
  MouseEvent(402,17,evtMouseMove);
  AssertEquals('nor does a shaky hand',0,FFrame.Moves);
  MouseEvent(450,20,evtMouseMove);
  AssertEquals('moving does',1,FFrame.Moves);
  AssertTrue('from where it was pressed',(FFrame.MoveDeltaX=50) and (FFrame.MoveDeltaY=4));
  MouseEvent(460,20,evtMouseMove);
  AssertEquals('once',1,FFrame.Moves);
  MouseEvent(460,20,evtMouseUp);
  // A plain click, and a press on a button or below the bar, do not move the window.
  Mouse(400,16,mbLeft);
  MouseEvent(400,16,evtMouseUp);
  MouseEvent(450,16,evtMouseMove);
  Mouse(780,16,mbLeft);
  MouseEvent(450,16,evtMouseMove);
  MouseEvent(450,16,evtMouseUp);
  Mouse(400,200,mbLeft);
  MouseEvent(450,200,evtMouseMove);
  MouseEvent(450,200,evtMouseUp);
  AssertEquals(1,FFrame.Moves);
end;

procedure TTestTitleBar.TestDoubleClickCaptionMaximizes;
begin
  Build;
  Mouse(400,16,mbLeft,[ssDouble]);
  AssertEquals(1,FFrame.Toggles);
  AssertEquals(0,FFrame.Moves);
end;

procedure TTestTitleBar.TestRightClickShowsMenu;
begin
  Build;
  Mouse(400,16,mbRight);
  AssertEquals(1,FFrame.Menus);
  AssertEquals(0,FFrame.Moves);
end;

procedure TTestTitleBar.TestIcon;
begin
  Build;
  Mouse(10,16,mbLeft);
  AssertEquals('click opens the menu',1,FFrame.Menus);
  Mouse(10,16,mbLeft,[ssDouble]);
  AssertEquals('double click closes',1,FFrame.Closes);
  AssertEquals(0,FFrame.Moves);
end;

procedure TTestTitleBar.TestSystemMenuNeedsNoOwnMenu;
begin
  Build;
  Mouse(400,16,mbRight);
  AssertNull(FBar.Menu);
end;

procedure TTestTitleBar.TestOwnMenuWithoutSystemMenu;
begin
  Build;
  FFrame.SystemHasMenu:=False;
  Mouse(400,16,mbRight);
  AssertNotNull('opened',FBar.Menu);
  AssertEquals('restore, minimize, maximize, line, close',5,FBar.Menu.Items.Count);
  AssertFalse('restore needs a maximized window',FBar.Menu.Items[0].Enabled);
  AssertTrue(FBar.Menu.Items[2].Enabled);
  FBar.Menu.Items[1].Click;
  AssertEquals('minimize',1,FFrame.Minimizes);
  FBar.Menu.Items[2].Click;
  AssertEquals('maximize',1,FFrame.Toggles);
  FBar.Menu.Items[4].Click;
  AssertEquals('close',1,FFrame.Closes);
  FFrame.IsMaximized:=True;
  Mouse(10,16,mbLeft);
  AssertTrue('state is read each time',FBar.Menu.Items[0].Enabled);
  AssertFalse(FBar.Menu.Items[2].Enabled);
end;

procedure TTestTitleBar.TestFrameState;
begin
  Build;
  AssertFalse(FBar.HasCSSClass('titlebar-inactive'));
  FFrame.IsActive:=False;
  FFrame.HotButton:=tbhClose;
  FFrame.PressedButton:=tbhMinimize;
  FBar.FrameChanged;
  AssertTrue(FBar.HasCSSClass('titlebar-inactive'));
  AssertTrue(ButtonOf(tbhClose).HasCSSClass('titlebar-hot'));
  AssertFalse(ButtonOf(tbhMaximize).HasCSSClass('titlebar-hot'));
  AssertTrue(ButtonOf(tbhMinimize).HasCSSClass('titlebar-down'));
  FFrame.IsActive:=True;
  FFrame.HotButton:=tbhClient;
  FBar.FrameChanged;
  AssertFalse(FBar.HasCSSClass('titlebar-inactive'));
  AssertFalse(ButtonOf(tbhClose).HasCSSClass('titlebar-hot'));
end;

procedure TTestTitleBar.TestMaximizeGlyph;
begin
  Build;
  AssertEquals('box',1,ButtonOf(tbhMaximize).NodeCount);
  FFrame.IsMaximized:=True;
  FBar.FrameChanged;
  Settle;
  AssertEquals('restore',2,ButtonOf(tbhMaximize).NodeCount);
  FFrame.IsMaximized:=False;
  FBar.FrameChanged;
  Settle;
  AssertEquals('box again',1,ButtonOf(tbhMaximize).NodeCount);
  // Still a working button after its glyphs were replaced.
  AssertTrue(FBar.HitTest(730,16)=tbhMaximize);
end;

initialization
  RegisterTest(TTestTitleBar);
end.
