{ The ohsRibbon demo. Switches for scripted checks:
    --capture=file.png  write a screenshot and exit
    --dark              dark look
    --width=n           window width
    --tab=n             start on tab n
    --context           show the contextual tab
    --collapse          collapse the ribbon
    --keytips           show the KeyTips
    --group=n           open collapsed group n of the active tab as a popup
    --press=keys        press KeyTip keys after --keytips
    --delay=ms          time between the scripted steps, for tests with real input }
unit ribbonform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Fresnel.DOM, Fresnel.Forms, Fresnel.Controls, Fresnel.Classes,
  Fresnel.Renderer, Fresnel.AnimationTimer, Fresnel.Menus, Fresnel.Images, FCL.Events,
  Fresnel.App, ohsribbon.model.sizing, ohsribbon.ui.ribbon, ribbonshot;

type
  TMainForm = class(TFresnelForm)
  private
    FRibbon: TRibbon;
    FStatus: TLabel;
    FTimer: TFresnelAnimationTimer;
    FTicks: Integer;
    FCaptureFile: string;
    FIconImage: TImageData;
    function Icon(const aName: string): TImageData;
    function NewMenu(const aCaptions: array of string): TPopupMenu;
    function AddIconButton(aGroup: TRibbonGroup; const aCaption, aIcon: string;
      aSize: TRibbonItemSize = risLarge): TRibbonItem;
    procedure BuildRibbon;
    procedure ItemClick(aEvent: TAbstractEvent);
    procedure MenuClick(Sender: TObject);
    procedure LauncherClick(aEvent: TAbstractEvent);
    procedure ContextClick(aEvent: TAbstractEvent);
    procedure DarkClick(aEvent: TAbstractEvent);
    procedure StyleSelect(Sender: TRibbonGallery; aIndex: Integer);
    procedure Tick(Sender: TObject);
    function SwitchValue(const aName: string; out aValue: string): Boolean;
  public
    constructor CreateNew(aOwner: TComponent); override;
    destructor Destroy; override;
    procedure Show; override;
  end;

var
  MainForm: TMainForm;

implementation

constructor TMainForm.CreateNew(aOwner: TComponent);
var
  lBody: TBody;
  lDocument: TDiv;
  lValue: string;
begin
  inherited CreateNew(aOwner);
  Caption:='ohsRibbon demo';
  FormWidth:=1000;
  FormHeight:=480;
  if SwitchValue('width',lValue) then
    FormWidth:=StrToInt(lValue);
  FIconImage:=TImageData.Create(Self);
  if SwitchValue('dark',lValue) then
    Application.ColorScheme:=fcsDark
  else
    Application.ColorScheme:=fcsLight;
  Stylesheet.Text:='body { display: flex; flex-direction: column; margin: 0; height: 100%; }'
    +' .document { flex-grow: 1; padding: 16px; }';
  lBody:=TBody.Create(Self);
  lBody.Parent:=Self;
  FRibbon:=TRibbon.Create(Self);
  FRibbon.Parent:=lBody;
  lDocument:=TDiv.Create(Self);
  lDocument.AddCSSClass('document');
  lDocument.Parent:=lBody;
  FStatus:=TLabel.Create(Self);
  FStatus.Caption:='Resize the window, or press Alt or F6 for KeyTips.';
  FStatus.Parent:=lDocument;
  BuildRibbon;
  SwitchValue('capture',FCaptureFile);
end;

destructor TMainForm.Destroy;
begin
  FreeAndNil(FTimer);
  inherited Destroy;
end;

function TMainForm.SwitchValue(const aName: string; out aValue: string): Boolean;
var
  i: Integer;
  lPrefix: string;
begin
  aValue:='';
  lPrefix:='--'+aName;
  for i:=1 to ParamCount do
    if ParamStr(i)=lPrefix then
      Exit(True)
    else if Copy(ParamStr(i),1,Length(lPrefix)+1)=lPrefix+'=' then
    begin
      aValue:=Copy(ParamStr(i),Length(lPrefix)+2,MaxInt);
      Exit(True);
    end;
  Result:=False;
end;

function TMainForm.Icon(const aName: string): TImageData;
var
  lPath: string;
begin
  Result:=nil;
  lPath:=ExtractFilePath(ParamStr(0))+'icons'+PathDelim+aName+'.png';
  if not FileExists(lPath) then
    Exit;
  FIconImage.LoadFromFile(lPath);
  Result:=FIconImage;
end;

function TMainForm.NewMenu(const aCaptions: array of string): TPopupMenu;
var
  i: Integer;
  lItem: TMenuItem;
begin
  Result:=TPopupMenu.Create(Self);
  for i:=0 to High(aCaptions) do
  begin
    lItem:=TMenuItem.Create(Result);
    lItem.Caption:=aCaptions[i];
    lItem.OnClick:=@MenuClick;
    Result.Items.Add(lItem);
  end;
end;

function TMainForm.AddIconButton(aGroup: TRibbonGroup; const aCaption, aIcon: string;
  aSize: TRibbonItemSize): TRibbonItem;
var
  lImage: TImageData;
begin
  Result:=aGroup.AddButton(aCaption,aSize,@ItemClick);
  lImage:=Icon(aIcon);
  if lImage<>nil then
    Result.Image:=lImage;
end;

procedure TMainForm.BuildRibbon;
var
  lTab: TRibbonTab;
  lGroup: TRibbonGroup;
  lItem: TRibbonItem;
  lSplit: TRibbonSplitButton;
  lGallery: TRibbonGallery;
  lImage: TImageData;
  i: Integer;
begin
  FRibbon.ApplicationMenu:=NewMenu(['New','Open','Save as','Print','Exit']);
  lItem:=FRibbon.AddQuickButton('Save',@ItemClick);
  lImage:=Icon('save');
  if lImage<>nil then
    lItem.Image:=lImage;
  lItem:=FRibbon.AddQuickButton('Undo',@ItemClick);
  lImage:=Icon('undo');
  if lImage<>nil then
    lItem.Image:=lImage;

  // Home: every kind of button.
  lTab:=FRibbon.AddTab('Home');
  lGroup:=lTab.AddGroup('Clipboard');
  lSplit:=lGroup.AddSplitButton('Paste',risLarge,@ItemClick,NewMenu(['Paste','Paste special','Paste as text']));
  lImage:=Icon('paste');
  if lImage<>nil then
    lSplit.Main.Image:=lImage;
  AddIconButton(lGroup,'Cut','cut',risMedium);
  AddIconButton(lGroup,'Copy','copy',risMedium);
  lGroup.OnDialogLauncher:=@LauncherClick;

  lGroup:=lTab.AddGroup('Font');
  for i:=0 to 2 do
  begin
    case i of
      0: lItem:=lGroup.AddToggle('Bold',risSmall,@ItemClick);
      1: lItem:=lGroup.AddToggle('Italic',risSmall,@ItemClick);
      2: lItem:=lGroup.AddToggle('Underline',risSmall,@ItemClick);
    end;
    case i of
      0: lImage:=Icon('bold');
      1: lImage:=Icon('italic');
      2: lImage:=Icon('under');
    end;
    if lImage<>nil then
      lItem.Image:=lImage;
  end;
  lItem:=lGroup.AddDropdown('Font size',risMedium,NewMenu(['10','12','14','18','24']));
  lItem:=lGroup.AddDropdown('Colour',risMedium,NewMenu(['Black','Red','Blue']));

  lGroup:=lTab.AddGroup('Paragraph');
  AddIconButton(lGroup,'Left','left',risMedium);
  AddIconButton(lGroup,'Centre','center',risMedium);
  lItem:=AddIconButton(lGroup,'Right','left',risMedium);
  lItem.Enabled:=False;

  lGroup:=lTab.AddGroup('Styles');
  lGallery:=lGroup.AddGallery(4);
  lGallery.AddItem('Normal',Icon('style1'));
  lGallery.AddItem('Accent',Icon('style2'));
  lGallery.AddItem('Frame',Icon('style3'));
  lGallery.AddItem('Plain',Icon('style1'));
  lGallery.AddItem('Quote',Icon('style2'));
  lGallery.AddItem('Note',Icon('style3'));
  lGallery.AddItem('Title',Icon('style1'));
  lGallery.AddItem('Footer',Icon('style2'));
  lGallery.SelectedIndex:=0;
  lGallery.OnSelect:=@StyleSelect;

  lGroup:=lTab.AddGroup('Editing');
  AddIconButton(lGroup,'Find','find');
  AddIconButton(lGroup,'Replace','replace');

  // Insert
  lTab:=FRibbon.AddTab('Insert');
  lGroup:=lTab.AddGroup('Illustrations');
  lItem:=AddIconButton(lGroup,'Picture','picture');
  lItem.OnClick:=@ContextClick;
  AddIconButton(lGroup,'Shape','shape');
  lGroup:=lTab.AddGroup('Tables');
  AddIconButton(lGroup,'Table','table');

  // View
  lTab:=FRibbon.AddTab('View');
  lGroup:=lTab.AddGroup('Look');
  lItem:=lGroup.AddToggle('Dark',risLarge,@DarkClick);
  lItem.Checked:=Application.ColorScheme=fcsDark;

  // Contextual: shown by Insert > Picture.
  lTab:=FRibbon.AddContextualTab('Picture tools','Format');
  lGroup:=lTab.AddGroup('Size');
  AddIconButton(lGroup,'Crop','crop');
  AddIconButton(lGroup,'Reset','undo');
end;

procedure TMainForm.ItemClick(aEvent: TAbstractEvent);
begin
  if (aEvent<>nil) and (aEvent.Sender is TRibbonItem) then
    FStatus.Caption:='Clicked: '+TRibbonItem(aEvent.Sender).Caption;
end;

procedure TMainForm.MenuClick(Sender: TObject);
begin
  if Sender is TMenuItem then
    FStatus.Caption:='Menu: '+TMenuItem(Sender).Caption;
end;

procedure TMainForm.LauncherClick(aEvent: TAbstractEvent);
begin
  if aEvent=nil then ;
  FStatus.Caption:='Clipboard dialog launcher';
end;

procedure TMainForm.ContextClick(aEvent: TAbstractEvent);
begin
  if aEvent=nil then ;
  FRibbon.SetContextVisible('Picture tools',not FRibbon.IsContextVisible('Picture tools'));
  FStatus.Caption:='Picture tools shown or hidden';
end;

procedure TMainForm.DarkClick(aEvent: TAbstractEvent);
begin
  if aEvent=nil then ;
  if Application.ColorScheme=fcsDark then
    Application.ColorScheme:=fcsLight
  else
    Application.ColorScheme:=fcsDark;
end;

procedure TMainForm.StyleSelect(Sender: TRibbonGallery; aIndex: Integer);
begin
  FStatus.Caption:='Style: '+Sender.Cells[aIndex].Caption;
end;

procedure TMainForm.Show;
var
  lValue: string;
begin
  inherited Show;
  if (FCaptureFile='') or (FTimer<>nil) then
    Exit;
  if SwitchValue('context',lValue) then
    FRibbon.SetContextVisible('Picture tools',True);
  if SwitchValue('tab',lValue) then
    FRibbon.ActiveTab:=FRibbon.Tabs[StrToInt(lValue)];
  if SwitchValue('collapse',lValue) then
    FRibbon.Collapsed:=True;
  FTimer:=TFresnelAnimationTimer.Create;
  FTimer.Interval:=700;
  if SwitchValue('delay',lValue) then
    FTimer.Interval:=StrToInt(lValue);
  FTimer.OnTick:=@Tick;
  FTimer.Enabled:=True;
end;

procedure TMainForm.Tick(Sender: TObject);
var
  lValue: string;
  i: Integer;
begin
  if Sender=nil then ;
  Inc(FTicks);
  if FTicks=1 then
  begin
    if SwitchValue('keytips',lValue) then
      FRibbon.ShowKeyTips;
    if SwitchValue('group',lValue) then
      FRibbon.ActiveTab.Groups[StrToInt(lValue)].CollapsedButton.Click;
    Exit;
  end;
  if FTicks=2 then
  begin
    if SwitchValue('press',lValue) then
      for i:=1 to Length(lValue) do
        FRibbon.PressKeyTip(lValue[i]);
    Exit;
  end;
  FTimer.Enabled:=False;
  try
    SaveFormToPNG(Self,FCaptureFile);
  except
    on E: Exception do
    begin
      // Never hang silently in a scripted check.
      Writeln('Capture failed: ',E.Message);
      ExitCode:=1;
    end;
  end;
  FresnelApplication.Terminate;
end;

end.
