{ Puts a TRibbonTitleBar in place of the title bar of the system, on Windows and on Linux with GTK3.

  In both cases the system keeps doing what it can, such as the shadow, resizing and snapping:

  - On Windows the window keeps its normal styles and its frame on the left, right and bottom. Only the
    caption goes. The bar is reported as a real caption and real caption buttons, so Windows handles the
    mouse there, including Snap Layouts on the maximize button.
  - With GTK3 the window gets an empty title bar widget. That makes GTK draw the shadow and the resize
    borders itself, on X11 and Wayland, and leaves the top of the window to the bar.

  Keep this unit out of programs that do not want it: it links the windowing backend. }
unit ohsribbon.ui.titlebar.native;

{$mode objfpc}{$H+}

interface

uses
  ohsribbon.ui.titlebar;

{ Call this once, before the form is shown for the first time. Elsewhere than on these platforms the bar
  hides itself, leaving the title bar of the system, and the result is False. }
function InstallTitleBar(aBar: TRibbonTitleBar): Boolean;

implementation

uses
  SysUtils, Fresnel.Classes, Fresnel.Forms
  {$IFDEF MSWINDOWS}, Windows, Fresnel.Win32{$ENDIF}
  {$IFDEF LINUX}, LazGtk3, LazGdk3, LazGObject2, LazGLib2, Fresnel.Gtk3{$ENDIF};

{$IFDEF MSWINDOWS}
type
  TWin32Frame = class(TRibbonWindowFrame)
  private
    FWindow: HWND;
    FOldProc: WNDPROC;
    FHot: TTitleBarHit;
    FPressed: TTitleBarHit;
    function CallOld(aMsg: UINT; aWParam: WPARAM; aLParam: LPARAM): LRESULT;
    function TopBorder: Integer;
    function CalcSize(aWParam: WPARAM; aLParam: LPARAM): LRESULT;
    function NCHitTest(aLParam: LPARAM): LRESULT;
    procedure SetButtonState(aHot, aPressed: TTitleBarHit);
    procedure Press(aHit: TTitleBarHit);
    procedure ShowMenuAt(aLParam: LPARAM);
  protected
    function GetActive: Boolean; override;
    function GetMaximized: Boolean; override;
    function GetHot: TTitleBarHit; override;
    function GetPressed: TTitleBarHit; override;
  public
    constructor Create(aWindow: HWND);
    destructor Destroy; override;
    function Handle(aMsg: UINT; aWParam: WPARAM; aLParam: LPARAM): LRESULT;
    procedure Minimize; override;
    procedure ToggleMaximize; override;
    procedure Close; override;
    procedure BeginMove(aDeltaX, aDeltaY: TFresnelLength); override;
    function ShowMenu: Boolean; override;
  end;

const
  cHitCodes: array[TTitleBarHit] of LRESULT =
    (HTCLIENT, HTCAPTION, HTSYSMENU, HTMINBUTTON, HTMAXBUTTON, HTCLOSE);
  cFrameProp = 'ohsRibbonTitleBarFrame';
  // Not in the Windows unit of FPC 3.2.
  cSM_CXPADDEDBORDER = 92;
  cWM_NCMOUSELEAVE = $02A2;
  cTME_LEAVE = 2;
  cTME_NONCLIENT = $10;

function FrameProc(aWindow: HWND; aMsg: UINT; aWParam: WPARAM; aLParam: LPARAM): LRESULT; stdcall;
begin
  Result:=TWin32Frame(GetPropA(aWindow,cFrameProp)).Handle(aMsg,aWParam,aLParam);
end;

function IsButton(aHit: TTitleBarHit): Boolean;
begin
  Result:=aHit in [Low(TTitleBarButton)..High(TTitleBarButton)];
end;

function HitOfCode(aCode: WPARAM): TTitleBarHit;
var
  h: TTitleBarHit;
begin
  for h:=Low(TTitleBarHit) to High(TTitleBarHit) do
    if WPARAM(cHitCodes[h])=aCode then
      Exit(h);
  Result:=tbhClient;
end;

constructor TWin32Frame.Create(aWindow: HWND);
begin
  FWindow:=aWindow;
  FHot:=tbhClient;
  FPressed:=tbhClient;
  SetPropA(FWindow,cFrameProp,THandle(Pointer(Self)));
  FOldProc:=WNDPROC(SetWindowLongPtr(FWindow,GWLP_WNDPROC,LONG_PTR(@FrameProc)));
  // Makes Windows ask for the client area again, now without the caption.
  SetWindowPos(FWindow,0,0,0,0,0,SWP_FRAMECHANGED or SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_NOACTIVATE);
end;

destructor TWin32Frame.Destroy;
begin
  SetWindowLongPtr(FWindow,GWLP_WNDPROC,LONG_PTR(FOldProc));
  RemovePropA(FWindow,cFrameProp);
  inherited Destroy;
end;

function TWin32Frame.GetActive: Boolean;
begin
  Result:=GetForegroundWindow=FWindow;
end;

function TWin32Frame.GetMaximized: Boolean;
begin
  Result:=IsZoomed(FWindow);
end;

function TWin32Frame.GetHot: TTitleBarHit;
begin
  Result:=FHot;
end;

function TWin32Frame.GetPressed: TTitleBarHit;
begin
  Result:=FPressed;
end;

function TWin32Frame.CallOld(aMsg: UINT; aWParam: WPARAM; aLParam: LPARAM): LRESULT;
begin
  Result:=CallWindowProc(FOldProc,FWindow,aMsg,aWParam,aLParam);
end;

function TWin32Frame.TopBorder: Integer;
begin
  Result:=GetSystemMetrics(SM_CYFRAME)+GetSystemMetrics(cSM_CXPADDEDBORDER);
end;

function TWin32Frame.CalcSize(aWParam: WPARAM; aLParam: LPARAM): LRESULT;
var
  lRect: PRect;
  lTop: LongInt;
begin
  // Both versions of the message start with the proposed window rectangle.
  lRect:=PRect(aLParam);
  lTop:=lRect^.Top;
  Result:=CallOld(WM_NCCALCSIZE,aWParam,aLParam);
  lRect^.Top:=lTop;
  // A maximized window sticks out of the screen by its border.
  if Maximized then
    Inc(lRect^.Top,TopBorder);
end;

function TWin32Frame.NCHitTest(aLParam: LPARAM): LRESULT;
var
  lPoint: TPoint;
  lClient: TRect;
  lCorner: Integer;
begin
  Result:=CallOld(WM_NCHITTEST,0,aLParam);
  // The frame that is left: the sides and the bottom.
  if (Result=HTLEFT) or (Result=HTRIGHT) or (Result=HTBOTTOM)
    or (Result=HTBOTTOMLEFT) or (Result=HTBOTTOMRIGHT) then
    Exit;
  lPoint.X:=SmallInt(LoWord(aLParam));
  lPoint.Y:=SmallInt(HiWord(aLParam));
  ScreenToClient(FWindow,lPoint);
  // The top border is inside the client area now, so it has to be found here.
  if (lPoint.Y<GetSystemMetrics(SM_CYFRAME)) and not Maximized then
  begin
    GetClientRect(FWindow,lClient);
    lCorner:=GetSystemMetrics(SM_CXSIZEFRAME)*2;
    if lPoint.X<lCorner then
      Exit(HTTOPLEFT);
    if lPoint.X>=lClient.Right-lCorner then
      Exit(HTTOPRIGHT);
    Exit(HTTOP);
  end;
  Result:=cHitCodes[Bar.HitTest(lPoint.X,lPoint.Y)];
end;

procedure TWin32Frame.SetButtonState(aHot, aPressed: TTitleBarHit);
begin
  if (aHot=FHot) and (aPressed=FPressed) then
    Exit;
  FHot:=aHot;
  FPressed:=aPressed;
  Changed;
end;

procedure TWin32Frame.Press(aHit: TTitleBarHit);
begin
  case aHit of
    tbhMinimize: Minimize;
    tbhMaximize: ToggleMaximize;
    tbhClose: Close;
  end;
end;

procedure TWin32Frame.Minimize;
begin
  PostMessage(FWindow,WM_SYSCOMMAND,SC_MINIMIZE,0);
end;

procedure TWin32Frame.ToggleMaximize;
begin
  if Maximized then
    PostMessage(FWindow,WM_SYSCOMMAND,SC_RESTORE,0)
  else
    PostMessage(FWindow,WM_SYSCOMMAND,SC_MAXIMIZE,0);
end;

procedure TWin32Frame.Close;
begin
  PostMessage(FWindow,WM_SYSCOMMAND,SC_CLOSE,0);
end;

procedure TWin32Frame.BeginMove(aDeltaX, aDeltaY: TFresnelLength);
begin
  if (aDeltaX=0) or (aDeltaY=0) then ;
  // Windows does this: the bar is reported as a caption.
end;

function TWin32Frame.ShowMenu: Boolean;
var
  lPoint: TPoint;
begin
  Result:=True;
  lPoint.X:=0;
  lPoint.Y:=GetSystemMetrics(SM_CYCAPTION);
  ClientToScreen(FWindow,lPoint);
  ShowMenuAt(LPARAM(Word(lPoint.X)) or (LPARAM(Word(lPoint.Y)) shl 16));
end;

procedure TWin32Frame.ShowMenuAt(aLParam: LPARAM);

  procedure Enable(aMenu: HMENU; aCommand: UINT; aOn: Boolean);
  const
    cStates: array[Boolean] of UINT = (MF_GRAYED, MF_ENABLED);
  begin
    EnableMenuItem(aMenu,aCommand,MF_BYCOMMAND or cStates[aOn]);
  end;

var
  lMenu: HMENU;
  lCommand: LongBool;
begin
  lMenu:=GetSystemMenu(FWindow,False);
  // Windows only keeps these up to date for the menu it opens itself.
  Enable(lMenu,SC_RESTORE,Maximized);
  Enable(lMenu,SC_MOVE,not Maximized);
  Enable(lMenu,SC_SIZE,not Maximized);
  Enable(lMenu,SC_MINIMIZE,True);
  Enable(lMenu,SC_MAXIMIZE,not Maximized);
  lCommand:=TrackPopupMenu(lMenu,TPM_RETURNCMD or TPM_RIGHTBUTTON,
    SmallInt(LoWord(aLParam)),SmallInt(HiWord(aLParam)),0,FWindow,nil);
  if Integer(lCommand)<>0 then
    PostMessage(FWindow,WM_SYSCOMMAND,WPARAM(Integer(lCommand)),0);
end;

function TWin32Frame.Handle(aMsg: UINT; aWParam: WPARAM; aLParam: LPARAM): LRESULT;
var
  lHit: TTitleBarHit;
  lTrack: TTrackMouseEvent;
begin
  case aMsg of
    WM_SYSCOMMAND:
      // Alt+Space. Windows places its menu in a caption that is not there, and does not open it.
      if ((aWParam and $FFF0)=SC_KEYMENU) and (aLParam=32) then
      begin
        ShowMenu;
        Exit(0);
      end;
    WM_NCCALCSIZE:
      Exit(CalcSize(aWParam,aLParam));
    WM_NCHITTEST:
      Exit(NCHitTest(aLParam));
    WM_NCMOUSEMOVE:
      begin
        lHit:=HitOfCode(aWParam);
        if IsButton(lHit) then
        begin
          FillChar(lTrack,SizeOf(lTrack),0);
          lTrack.cbSize:=SizeOf(lTrack);
          lTrack.dwFlags:=cTME_LEAVE or cTME_NONCLIENT;
          lTrack.hwndTrack:=FWindow;
          TrackMouseEvent(lTrack);
          if lHit<>FPressed then
            SetButtonState(lHit,tbhClient)
          else
            SetButtonState(lHit,FPressed);
        end
        else
          SetButtonState(tbhClient,tbhClient);
      end;
    cWM_NCMOUSELEAVE:
      SetButtonState(tbhClient,tbhClient);
    WM_NCLBUTTONDOWN, WM_NCLBUTTONDBLCLK:
      begin
        lHit:=HitOfCode(aWParam);
        // Windows would draw and run its own caption buttons here.
        if IsButton(lHit) then
        begin
          SetButtonState(lHit,lHit);
          Exit(0);
        end;
      end;
    WM_NCRBUTTONUP:
      if (aWParam=HTCAPTION) or (aWParam=HTSYSMENU) then
      begin
        ShowMenuAt(aLParam);
        Exit(0);
      end;
    WM_NCLBUTTONUP:
      begin
        lHit:=HitOfCode(aWParam);
        if IsButton(lHit) then
        begin
          if lHit=FPressed then
            Press(lHit);
          SetButtonState(lHit,tbhClient);
          Exit(0);
        end;
      end;
  end;
  Result:=CallOld(aMsg,aWParam,aLParam);
  if (aMsg=WM_SIZE) or (aMsg=WM_ACTIVATE) then
    Changed;
end;

function InstallFrame(aForm: TFresnelCustomForm; aBar: TRibbonTitleBar): Boolean;
begin
  Result:=aForm.WSForm is TWin32WSForm;
  if Result then
    aBar.Frame:=TWin32Frame.Create(TWin32WSForm(aForm.WSForm).Window);
end;
{$ENDIF}

{$IFDEF LINUX}
type
  TGtk3Frame = class(TRibbonWindowFrame)
  private
    FWindow: PGtkWindow;
  protected
    function GetActive: Boolean; override;
    function GetMaximized: Boolean; override;
  public
    constructor Create(aWindow: PGtkWindow);
    destructor Destroy; override;
    procedure Minimize; override;
    procedure ToggleMaximize; override;
    procedure Close; override;
    procedure BeginMove(aDeltaX, aDeltaY: TFresnelLength); override;
    function ShowMenu: Boolean; override;
  end;

function IsWayland: Boolean;
begin
  Result:=g_type_name_from_instance(PGTypeInstance(gdk_display_get_default()))='GdkWaylandDisplay';
end;

function FrameWindowState(aWidget: PGtkWidget; aEvent: PGdkEvent; aData: gpointer): gboolean; cdecl;
begin
  Result:=False;
  if (aWidget=nil) or (aEvent=nil) then ;
  TGtk3Frame(aData).Changed;
end;

procedure FrameWindowActive(aObject: PGObject; aSpec: PGParamSpec; aData: gpointer); cdecl;
begin
  if (aObject=nil) or (aSpec=nil) then ;
  TGtk3Frame(aData).Changed;
end;

procedure FrameWindowDestroy(aWidget: PGtkWidget; aData: gpointer); cdecl;
begin
  if aWidget=nil then ;
  TGtk3Frame(aData).FWindow:=nil;
end;

constructor TGtk3Frame.Create(aWindow: PGtkWindow);
begin
  FWindow:=aWindow;
  // Never shown: the title bar of the window is empty, and the rest of what GTK draws around it stays.
  gtk_window_set_titlebar(FWindow,PGtkWidget(gtk_fixed_new()));
  g_signal_connect_data(FWindow,'window-state-event',TGCallback(@FrameWindowState),Self,nil,G_CONNECT_DEFAULT);
  // Not in the window state on every window manager, and GTK updates is-active after that state.
  g_signal_connect_data(FWindow,'notify::is-active',TGCallback(@FrameWindowActive),Self,nil,G_CONNECT_DEFAULT);
  g_signal_connect_data(FWindow,'destroy',TGCallback(@FrameWindowDestroy),Self,nil,G_CONNECT_DEFAULT);
end;

destructor TGtk3Frame.Destroy;
begin
  if FWindow<>nil then
    g_signal_handlers_disconnect_matched(PGObject(FWindow),[G_SIGNAL_MATCH_DATA],0,0,nil,nil,Self);
  inherited Destroy;
end;

function TGtk3Frame.GetActive: Boolean;
begin
  Result:=(FWindow<>nil) and gtk_window_is_active(FWindow);
end;

function TGtk3Frame.GetMaximized: Boolean;
begin
  Result:=(FWindow<>nil) and gtk_window_is_maximized(FWindow);
end;

procedure TGtk3Frame.Minimize;
begin
  if FWindow<>nil then
    gtk_window_iconify(FWindow);
end;

procedure TGtk3Frame.ToggleMaximize;
begin
  if FWindow=nil then
    Exit;
  if Maximized then
    gtk_window_unmaximize(FWindow)
  else
    gtk_window_maximize(FWindow);
end;

procedure TGtk3Frame.Close;
begin
  if FWindow<>nil then
    gtk_window_close(FWindow);
end;

procedure TGtk3Frame.BeginMove(aDeltaX, aDeltaY: TFresnelLength);
var
  lEvent: PGdkEvent;
  lX, lY: gdouble;
begin
  if FWindow=nil then
    Exit;
  lEvent:=gtk_get_current_event();
  if lEvent=nil then
    Exit;
  if gdk_event_get_root_coords(lEvent,@lX,@lY) then
    // Where the mouse was pressed, so that the window keeps its place under the mouse.
    gtk_window_begin_move_drag(FWindow,1,Round(lX-aDeltaX),Round(lY-aDeltaY),gtk_get_current_event_time());
  gdk_event_free(lEvent);
end;

function TGtk3Frame.ShowMenu: Boolean;
var
  lEvent: PGdkEvent;
begin
  Result:=False;
  if (FWindow=nil) or IsWayland then
    Exit;
  lEvent:=gtk_get_current_event();
  if lEvent=nil then
    Exit;
  // Not every window manager has this menu. X11 can check that. Wayland only sends the request and
  // reports success, also when nothing opens, so there the bar always opens its own.
  Result:=gdk_window_show_window_menu(gtk_widget_get_window(PGtkWidget(FWindow)),lEvent);
  gdk_event_free(lEvent);
end;

function InstallFrame(aForm: TFresnelCustomForm; aBar: TRibbonTitleBar): Boolean;
begin
  Result:=aForm.WSForm is TGtk3WSForm;
  if Result then
    aBar.Frame:=TGtk3Frame.Create(TGtk3WSForm(aForm.WSForm).Window);
end;
{$ENDIF}

{$IF NOT (DEFINED(MSWINDOWS) OR DEFINED(LINUX))}
function InstallFrame(aForm: TFresnelCustomForm; aBar: TRibbonTitleBar): Boolean;
begin
  Result:=False;
  if (aForm=nil) or (aBar=nil) then ;
end;
{$ENDIF}

function InstallTitleBar(aBar: TRibbonTitleBar): Boolean;
begin
  Result:=(aBar.Viewport is TFresnelCustomForm)
    and InstallFrame(TFresnelCustomForm(aBar.Viewport),aBar);
  if not Result then
    aBar.AddCSSClass('titlebar-hidden');
end;

end.
