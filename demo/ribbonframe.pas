{ Replaces the caption of a Win32 window by a title bar the application draws itself.

  The window keeps its normal styles and its frame on the left, right and bottom, so Windows still does
  the shadow, the sizing borders, snapping and the animations. Only the caption is removed from the
  non-client area. The application says what is under the mouse through OnHitTest, and Windows then treats
  those parts as a real caption and real caption buttons. }
unit ribbonframe;

{$mode objfpc}{$H+}

interface

uses
  Windows;

type
  TFrameHit = (fhClient, fhCaption, fhIcon, fhMinimize, fhMaximize, fhClose);
  TFrameButton = fhMinimize..fhClose;

  TFrameHitEvent = function(aX, aY: Integer): TFrameHit of object;
  TFrameChangeEvent = procedure of object;

  TWindowFrame = class
  private
    FWindow: HWND;
    FOldProc: WNDPROC;
    FHot: TFrameHit;
    FPressed: TFrameHit;
    FOnHitTest: TFrameHitEvent;
    FOnChange: TFrameChangeEvent;
    function GetActive: Boolean;
    function GetMaximized: Boolean;
    function CallOld(aMsg: UINT; aWParam: WPARAM; aLParam: LPARAM): LRESULT;
    function TopBorder: Integer;
    function CalcSize(aWParam: WPARAM; aLParam: LPARAM): LRESULT;
    function HitTest(aLParam: LPARAM): LRESULT;
    procedure SetButtonState(aHot, aPressed: TFrameHit);
    procedure Press(aHit: TFrameHit);
    procedure ShowSystemMenu(aLParam: LPARAM);
  public
    constructor Create(aWindow: HWND);
    destructor Destroy; override;
    procedure SetTitle(const aTitle: string);
    function Handle(aMsg: UINT; aWParam: WPARAM; aLParam: LPARAM): LRESULT;
    property Active: Boolean read GetActive;
    property Maximized: Boolean read GetMaximized;
    property Hot: TFrameHit read FHot;
    property Pressed: TFrameHit read FPressed;
    property OnHitTest: TFrameHitEvent read FOnHitTest write FOnHitTest;
    property OnChange: TFrameChangeEvent read FOnChange write FOnChange;
  end;

implementation

const
  cHitCodes: array[TFrameHit] of LRESULT =
    (HTCLIENT, HTCAPTION, HTSYSMENU, HTMINBUTTON, HTMAXBUTTON, HTCLOSE);
  // Not in the Windows unit of FPC 3.2.
  cSM_CXPADDEDBORDER = 92;
  cWM_NCMOUSELEAVE = $02A2;
  cTME_LEAVE = 2;
  cTME_NONCLIENT = $10;

var
  // The demo has one window.
  Frame: TWindowFrame;

function FrameProc(aWindow: HWND; aMsg: UINT; aWParam: WPARAM; aLParam: LPARAM): LRESULT; stdcall;
begin
  if aWindow=0 then ;
  Result:=Frame.Handle(aMsg,aWParam,aLParam);
end;

function IsButton(aHit: TFrameHit): Boolean;
begin
  Result:=aHit in [Low(TFrameButton)..High(TFrameButton)];
end;

function HitOfCode(aCode: WPARAM): TFrameHit;
var
  h: TFrameHit;
begin
  for h:=Low(TFrameHit) to High(TFrameHit) do
    if WPARAM(cHitCodes[h])=aCode then
      Exit(h);
  Result:=fhClient;
end;

constructor TWindowFrame.Create(aWindow: HWND);
begin
  FWindow:=aWindow;
  FHot:=fhClient;
  FPressed:=fhClient;
  Frame:=Self;
  FOldProc:=WNDPROC(SetWindowLongPtr(FWindow,GWLP_WNDPROC,LONG_PTR(@FrameProc)));
  // Makes Windows ask for the client area again, now without the caption.
  SetWindowPos(FWindow,0,0,0,0,0,SWP_FRAMECHANGED or SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_NOACTIVATE);
end;

destructor TWindowFrame.Destroy;
begin
  SetWindowLongPtr(FWindow,GWLP_WNDPROC,LONG_PTR(FOldProc));
  inherited Destroy;
end;

procedure TWindowFrame.SetTitle(const aTitle: string);
begin
  SetWindowTextW(FWindow,PWideChar(UTF8Decode(aTitle)));
end;

function TWindowFrame.GetActive: Boolean;
begin
  Result:=GetForegroundWindow=FWindow;
end;

function TWindowFrame.GetMaximized: Boolean;
begin
  Result:=IsZoomed(FWindow);
end;

function TWindowFrame.CallOld(aMsg: UINT; aWParam: WPARAM; aLParam: LPARAM): LRESULT;
begin
  Result:=CallWindowProc(FOldProc,FWindow,aMsg,aWParam,aLParam);
end;

function TWindowFrame.TopBorder: Integer;
begin
  Result:=GetSystemMetrics(SM_CYFRAME)+GetSystemMetrics(cSM_CXPADDEDBORDER);
end;

function TWindowFrame.CalcSize(aWParam: WPARAM; aLParam: LPARAM): LRESULT;
var
  lRect: PRect;
  lTop: LongInt;
begin
  // Both forms of the message start with the proposed window rectangle.
  lRect:=PRect(aLParam);
  lTop:=lRect^.Top;
  Result:=CallOld(WM_NCCALCSIZE,aWParam,aLParam);
  lRect^.Top:=lTop;
  // A maximized window sticks out of the screen by its border.
  if Maximized then
    Inc(lRect^.Top,TopBorder);
end;

function TWindowFrame.HitTest(aLParam: LPARAM): LRESULT;
var
  lPoint: TPoint;
  lClient: TRect;
  lHit: TFrameHit;
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
  lHit:=fhClient;
  if Assigned(FOnHitTest) then
    lHit:=FOnHitTest(lPoint.X,lPoint.Y);
  Result:=cHitCodes[lHit];
end;

procedure TWindowFrame.SetButtonState(aHot, aPressed: TFrameHit);
begin
  if (aHot=FHot) and (aPressed=FPressed) then
    Exit;
  FHot:=aHot;
  FPressed:=aPressed;
  if Assigned(FOnChange) then
    FOnChange();
end;

procedure TWindowFrame.Press(aHit: TFrameHit);
begin
  case aHit of
    fhMinimize:
      PostMessage(FWindow,WM_SYSCOMMAND,SC_MINIMIZE,0);
    fhMaximize:
      if Maximized then
        PostMessage(FWindow,WM_SYSCOMMAND,SC_RESTORE,0)
      else
        PostMessage(FWindow,WM_SYSCOMMAND,SC_MAXIMIZE,0);
    fhClose:
      PostMessage(FWindow,WM_SYSCOMMAND,SC_CLOSE,0);
  end;
end;

procedure TWindowFrame.ShowSystemMenu(aLParam: LPARAM);

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

function TWindowFrame.Handle(aMsg: UINT; aWParam: WPARAM; aLParam: LPARAM): LRESULT;
var
  lHit: TFrameHit;
  lTrack: TTrackMouseEvent;
  lPoint: TPoint;
begin
  case aMsg of
    WM_SYSCOMMAND:
      // Alt+Space. Windows places its menu in a caption that is not there, and does not open it.
      if ((aWParam and $FFF0)=SC_KEYMENU) and (aLParam=32) then
      begin
        lPoint.X:=0;
        lPoint.Y:=GetSystemMetrics(SM_CYCAPTION);
        ClientToScreen(FWindow,lPoint);
        ShowSystemMenu(LPARAM(Word(lPoint.X)) or (LPARAM(Word(lPoint.Y)) shl 16));
        Exit(0);
      end;
    WM_NCCALCSIZE:
      Exit(CalcSize(aWParam,aLParam));
    WM_NCHITTEST:
      Exit(HitTest(aLParam));
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
            SetButtonState(lHit,fhClient)
          else
            SetButtonState(lHit,FPressed);
        end
        else
          SetButtonState(fhClient,fhClient);
      end;
    cWM_NCMOUSELEAVE:
      SetButtonState(fhClient,fhClient);
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
        ShowSystemMenu(aLParam);
        Exit(0);
      end;
    WM_NCLBUTTONUP:
      begin
        lHit:=HitOfCode(aWParam);
        if IsButton(lHit) then
        begin
          if lHit=FPressed then
            Press(lHit);
          SetButtonState(lHit,fhClient);
          Exit(0);
        end;
      end;
  end;
  Result:=CallOld(aMsg,aWParam,aLParam);
  if (aMsg=WM_SIZE) or (aMsg=WM_ACTIVATE) then
    if Assigned(FOnChange) then
      FOnChange();
end;

end.
