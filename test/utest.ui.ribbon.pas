unit utest.ui.ribbon;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, fpcunit, testregistry, TCCSS, FCL.Events, Fresnel.Events, Fresnel.Images,
  Fresnel.Classes, Fresnel.DOM, Fresnel.Controls, Fresnel.Overlay,
  ohsribbon.model.sizing, ohsribbon.ui.ribbon;

type
  { TFreeWatch - tells whether a component was freed. }

  TFreeWatch = class(TComponent)
  private
    FFreed: TFPList;
  protected
    procedure Notification(aComponent: TComponent; aOperation: TOperation); override;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    procedure Watch(aComponent: TComponent);
    function Freed(aComponent: TComponent): Boolean;
  end;

  TTestRibbon = class(TCustomTestFresnelCSS)
  private
    FRibbon: TRibbon;
    FClicks: Integer;
    FSelected: Integer;
    FTabChanges: Integer;
    FRemoveGroup: TRibbonGroup;
    FRemoveItem: TRibbonItem;
    procedure ItemClick(aEvent: TAbstractEvent);
    procedure RemoveOnClick(aEvent: TAbstractEvent);
    procedure GallerySelect(Sender: TRibbonGallery; aIndex: Integer);
    procedure TabChanged(Sender: TObject);
    procedure Build(aWidth: Integer);
    // Layout runs in passes; the ribbon needs several to reach a stable state.
    procedure Settle;
    function OverlayCount: Integer;
    function FillTab(aTab: TRibbonTab): TRibbonItem;
    function IconFile: string;
    function SendKey(const aKey: string): Boolean;
  published
    procedure TestFirstTabIsActive;
    procedure TestSwitchTab;
    procedure TestButtonClick;
    procedure TestDisabledButtonDoesNotClick;
    procedure TestToggle;
    procedure TestDropdownContentOpensPopup;
    procedure TestSplitArrowOpensAndMainClicks;
    procedure TestSmallItemsStackInColumns;
    procedure TestLargeItemHasOwnColumn;
    procedure TestQuickAccessShowsTitleRow;
    procedure TestNarrowWindowReduces;
    procedure TestWideWindowRestores;
    procedure TestNarrowestCollapsesGroups;
    procedure TestReducedGroupsFit;
    procedure TestCollapsedGroupPopupRoundTrip;
    procedure TestAddingItemResetsScale;
    procedure TestCollapsedRibbonHidesPanel;
    procedure TestCollapsedRibbonPanelOnDemand;
    procedure TestItemClickClosesPanelPopup;
    procedure TestContextualTabHiddenUntilShown;
    procedure TestHidingContextLeavesActiveTab;
    procedure TestGalleryPaging;
    procedure TestGallerySelect;
    procedure TestGalleryExpanded;
    procedure TestKeyTipsTopLevel;
    procedure TestKeyTipsEnterTabAndClick;
    procedure TestKeyTipsHide;
    procedure TestKeyTipsIgnoresUnknownKey;
    procedure TestKeyboardAltTapShowsKeyTips;
    procedure TestDoubleClickHeaderCollapsesWithoutPopup;
    procedure TestKeyTipsSkipDisabled;
    procedure TestIconItemsSurviveEveryWidth;
    procedure TestIconOnlyKeepsCaption;
    procedure TestKeyboardF6ShowsKeyTips;
    procedure TestKeyboardLetterAndEscape;
    procedure TestEscapeOutsideKeyTipsIsNotConsumed;
    // Removing (issue 00001)
    procedure TestRemoveItemKeepsSizesInStep;
    procedure TestRemoveGalleryClosesItsPopup;
    procedure TestRemoveGroupFreesEverything;
    procedure TestRemoveCollapsedGroupWithOpenPopup;
    procedure TestRemoveActiveTabActivatesNeighbour;
    procedure TestRemoveLastContextualTabDropsContext;
    procedure TestRemoveQuickItemHidesTitleRow;
    procedure TestRemoveItemFromItsOwnClick;
    procedure TestRemoveHidesKeyTips;
    procedure TestRemoveUnknownDoesNothing;
    procedure TestKeyTipsSkipHidden;
  end;

implementation

{ TFreeWatch }

constructor TFreeWatch.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  FFreed:=TFPList.Create;
end;

destructor TFreeWatch.Destroy;
begin
  FreeAndNil(FFreed);
  inherited Destroy;
end;

procedure TFreeWatch.Notification(aComponent: TComponent; aOperation: TOperation);
begin
  inherited Notification(aComponent,aOperation);
  if (aOperation=opRemove) and (FFreed<>nil) then
    FFreed.Add(aComponent);
end;

procedure TFreeWatch.Watch(aComponent: TComponent);
begin
  aComponent.FreeNotification(Self);
end;

function TFreeWatch.Freed(aComponent: TComponent): Boolean;
begin
  Result:=FFreed.IndexOf(aComponent)>=0;
end;

procedure TTestRibbon.ItemClick(aEvent: TAbstractEvent);
begin
  if aEvent=nil then ;
  Inc(FClicks);
end;

procedure TTestRibbon.RemoveOnClick(aEvent: TAbstractEvent);
begin
  if aEvent=nil then ;
  Inc(FClicks);
  FRemoveGroup.RemoveItem(FRemoveItem);
end;

procedure TTestRibbon.GallerySelect(Sender: TRibbonGallery; aIndex: Integer);
begin
  if Sender=nil then ;
  FSelected:=aIndex;
end;

procedure TTestRibbon.TabChanged(Sender: TObject);
begin
  if Sender=nil then ;
  Inc(FTabChanges);
end;

procedure TTestRibbon.Build(aWidth: Integer);
var
  lBody: TBody;
begin
  Viewport.Width:=aWidth;
  Viewport.Height:=400;
  lBody:=CreateBody;
  FRibbon:=TRibbon.Create(Viewport);
  FRibbon.Parent:=lBody;
  FClicks:=0;
  FSelected:=-1;
  FTabChanges:=0;
end;

procedure TTestRibbon.Settle;
var
  i: Integer;
begin
  for i:=1 to 60 do
    Viewport.ApplyCSS;
end;

function TTestRibbon.OverlayCount: Integer;
begin
  Result:=TOverlayLayer.GetLayer(Viewport).OverlayCount;
end;

function TTestRibbon.FillTab(aTab: TRibbonTab): TRibbonItem;
var
  g, i: Integer;
  lGroup: TRibbonGroup;
begin
  Result:=nil;
  for g:=1 to 4 do
  begin
    lGroup:=aTab.AddGroup('Group '+IntToStr(g));
    for i:=1 to 4 do
      if Result=nil then
        Result:=lGroup.AddButton('First',risLarge,@ItemClick)
      else
        lGroup.AddButton('Button '+IntToStr(i),risLarge,@ItemClick);
  end;
end;

procedure TTestRibbon.TestFirstTabIsActive;
var
  lOne, lTwo: TRibbonTab;
begin
  Build(1000);
  lOne:=FRibbon.AddTab('One');
  lTwo:=FRibbon.AddTab('Two');
  AssertSame(lOne,FRibbon.ActiveTab);
  AssertFalse(lOne.HasCSSClass(cRibbonHiddenClass));
  AssertTrue(lTwo.HasCSSClass(cRibbonHiddenClass));
  AssertTrue(lOne.Header.HasCSSClass(cRibbonActiveClass));
end;

procedure TTestRibbon.TestSwitchTab;
var
  lOne, lTwo: TRibbonTab;
begin
  Build(1000);
  lOne:=FRibbon.AddTab('One');
  lTwo:=FRibbon.AddTab('Two');
  FRibbon.OnTabChanged:=@TabChanged;
  lTwo.Header.Click;
  AssertSame(lTwo,FRibbon.ActiveTab);
  AssertEquals(1,FTabChanges);
  AssertTrue(lOne.HasCSSClass(cRibbonHiddenClass));
  AssertFalse(lTwo.HasCSSClass(cRibbonHiddenClass));
  AssertFalse(lOne.Header.HasCSSClass(cRibbonActiveClass));
end;

procedure TTestRibbon.TestButtonClick;
var
  lItem: TRibbonItem;
begin
  Build(1000);
  lItem:=FRibbon.AddTab('One').AddGroup('G').AddButton('B',risLarge,@ItemClick);
  lItem.Click;
  AssertEquals(1,FClicks);
end;

procedure TTestRibbon.TestDisabledButtonDoesNotClick;
var
  lItem: TRibbonItem;
begin
  Build(1000);
  lItem:=FRibbon.AddTab('One').AddGroup('G').AddToggle('B',risLarge,@ItemClick);
  lItem.Enabled:=False;
  lItem.Click;
  AssertEquals(0,FClicks);
  AssertFalse(lItem.Checked);
end;

procedure TTestRibbon.TestToggle;
var
  lItem: TRibbonItem;
begin
  Build(1000);
  lItem:=FRibbon.AddTab('One').AddGroup('G').AddToggle('B',risSmall,@ItemClick);
  lItem.Click;
  AssertTrue(lItem.Checked);
  AssertTrue(lItem.HasCSSClass(cRibbonCheckedClass));
  AssertEquals(1,FClicks);
  lItem.Click;
  AssertFalse(lItem.Checked);
  AssertFalse(lItem.HasCSSClass(cRibbonCheckedClass));
end;

procedure TTestRibbon.TestDropdownContentOpensPopup;
var
  lItem: TRibbonItem;
  lContent: TDiv;
begin
  Build(1000);
  lItem:=FRibbon.AddTab('One').AddGroup('G').AddDropdown('D');
  lContent:=TDiv.Create(Viewport);
  lItem.DropdownContent:=lContent;
  Settle;
  lItem.Click;
  AssertEquals(1,OverlayCount);
  AssertSame(lContent,TOverlayLayer.GetLayer(Viewport).Overlays[0].Content);
  AssertTrue(lContent.HasCSSClass(cRibbonPopupClass));
end;

procedure TTestRibbon.TestSplitArrowOpensAndMainClicks;
var
  lSplit: TRibbonSplitButton;
begin
  Build(1000);
  lSplit:=FRibbon.AddTab('One').AddGroup('G').AddSplitButton('S',risLarge,@ItemClick);
  lSplit.Arrow.DropdownContent:=TDiv.Create(Viewport);
  Settle;
  lSplit.Main.Click;
  AssertEquals(1,FClicks);
  AssertEquals(0,OverlayCount);
  lSplit.Arrow.Click;
  AssertEquals(1,FClicks);
  AssertEquals(1,OverlayCount);
end;

procedure TTestRibbon.TestSmallItemsStackInColumns;
var
  lGroup: TRibbonGroup;
  a, b, c, d: TRibbonItem;
begin
  Build(1000);
  lGroup:=FRibbon.AddTab('One').AddGroup('G');
  a:=lGroup.AddButton('A',risSmall);
  b:=lGroup.AddButton('B',risSmall);
  c:=lGroup.AddButton('C',risSmall);
  d:=lGroup.AddButton('D',risSmall);
  Settle;
  AssertNotNull(a.Parent);
  AssertSame(a.Parent,b.Parent);
  AssertSame(a.Parent,c.Parent);
  AssertTrue(a.Parent<>d.Parent);
  AssertTrue(a.DisplaySize=risSmall);
end;

procedure TTestRibbon.TestLargeItemHasOwnColumn;
var
  lGroup: TRibbonGroup;
  a, b: TRibbonItem;
begin
  Build(1000);
  lGroup:=FRibbon.AddTab('One').AddGroup('G');
  a:=lGroup.AddButton('A',risLarge);
  b:=lGroup.AddButton('B',risLarge);
  Settle;
  AssertTrue(a.Parent<>b.Parent);
  AssertTrue(a.HasCSSClass(cRibbonLargeClass));
end;

procedure TTestRibbon.TestQuickAccessShowsTitleRow;
var
  lItem: TRibbonItem;
begin
  Build(1000);
  lItem:=FRibbon.AddQuickButton('Save',@ItemClick);
  AssertEquals(1,FRibbon.QuickItemCount);
  AssertNotNull(lItem.Parent);
  AssertFalse(lItem.Parent.Parent.HasCSSClass(cRibbonHiddenClass));
  lItem.Click;
  AssertEquals(1,FClicks);
end;

procedure TTestRibbon.TestNarrowWindowReduces;
var
  lTab: TRibbonTab;
begin
  Build(3000);
  lTab:=FRibbon.AddTab('One');
  FillTab(lTab);
  Settle;
  AssertEquals('all fits at full size',0,lTab.ScaleStep);
  Viewport.Width:=500;
  Settle;
  AssertTrue('reduced',lTab.ScaleStep>0);
end;

procedure TTestRibbon.TestWideWindowRestores;
var
  lTab: TRibbonTab;
begin
  Build(500);
  lTab:=FRibbon.AddTab('One');
  FillTab(lTab);
  Settle;
  AssertTrue(lTab.ScaleStep>0);
  Viewport.Width:=3000;
  Settle;
  AssertEquals(0,lTab.ScaleStep);
  AssertEquals(0,lTab.Groups[0].Level);
end;

procedure TTestRibbon.TestNarrowestCollapsesGroups;
var
  lTab: TRibbonTab;
  lGroup: TRibbonGroup;
begin
  Build(120);
  lTab:=FRibbon.AddTab('One');
  FillTab(lTab);
  Settle;
  lGroup:=lTab.Groups[3];
  AssertTrue('last group collapsed',lGroup.Collapsed);
  AssertFalse(lGroup.CollapsedButton.HasCSSClass(cRibbonHiddenClass));
  AssertTrue(lGroup.Body.HasCSSClass(cRibbonHiddenClass));
end;

procedure TTestRibbon.TestReducedGroupsFit;
var
  lTab: TRibbonTab;
  lLast: TFresnelRect;
begin
  Build(3000);
  lTab:=FRibbon.AddTab('One');
  FillTab(lTab);
  Viewport.Width:=600;
  Settle;
  lLast:=lTab.Groups[3].UsedBorderBox;
  AssertTrue('right edge '+FloatToStr(lLast.Right)+' inside the panel',lLast.Right<=600);
end;

procedure TTestRibbon.TestCollapsedGroupPopupRoundTrip;
var
  lTab: TRibbonTab;
  lGroup: TRibbonGroup;
begin
  Build(120);
  lTab:=FRibbon.AddTab('One');
  FillTab(lTab);
  Settle;
  lGroup:=lTab.Groups[3];
  lGroup.CollapsedButton.Click;
  AssertEquals(1,OverlayCount);
  AssertFalse('shown in the popup',lGroup.Body.HasCSSClass(cRibbonHiddenClass));
  AssertTrue(lGroup.Body.HasCSSClass(cRibbonPopupClass));
  TOverlayLayer.GetLayer(Viewport).CloseAll;
  AssertEquals(0,OverlayCount);
  AssertSame(lGroup,lGroup.Body.Parent);
  AssertTrue(lGroup.Body.HasCSSClass(cRibbonHiddenClass));
  AssertFalse(lGroup.Body.HasCSSClass(cRibbonPopupClass));
end;

procedure TTestRibbon.TestAddingItemResetsScale;
var
  lTab: TRibbonTab;
  lItem: TRibbonItem;
begin
  Build(500);
  lTab:=FRibbon.AddTab('One');
  FillTab(lTab);
  Settle;
  AssertTrue(lTab.ScaleStep>0);
  Viewport.Width:=3000;
  lItem:=lTab.Groups[0].AddButton('New',risLarge);
  Settle;
  AssertEquals('the widths of the old content are forgotten',0,lTab.ScaleStep);
  AssertNotNull('the new item is placed',lItem.Parent);
end;

procedure TTestRibbon.TestCollapsedRibbonHidesPanel;
begin
  Build(1000);
  FillTab(FRibbon.AddTab('One'));
  Settle;
  FRibbon.Collapsed:=True;
  AssertTrue(FRibbon.Panel.HasCSSClass(cRibbonHiddenClass));
  FRibbon.Collapsed:=False;
  AssertFalse(FRibbon.Panel.HasCSSClass(cRibbonHiddenClass));
end;

procedure TTestRibbon.TestCollapsedRibbonPanelOnDemand;
var
  lTab: TRibbonTab;
begin
  Build(1000);
  lTab:=FRibbon.AddTab('One');
  FillTab(lTab);
  Settle;
  FRibbon.Collapsed:=True;
  Settle;
  lTab.Header.Click;
  AssertTrue(FRibbon.PanelOpen);
  AssertEquals(1,OverlayCount);
  AssertFalse(FRibbon.Panel.HasCSSClass(cRibbonHiddenClass));
  TOverlayLayer.GetLayer(Viewport).CloseAll;
  AssertFalse(FRibbon.PanelOpen);
  AssertSame(FRibbon,FRibbon.Panel.Parent);
  AssertTrue(FRibbon.Panel.HasCSSClass(cRibbonHiddenClass));
end;

procedure TTestRibbon.TestItemClickClosesPanelPopup;
var
  lTab: TRibbonTab;
  lItem: TRibbonItem;
begin
  Build(3000);
  lTab:=FRibbon.AddTab('One');
  lItem:=FillTab(lTab);
  Settle;
  FRibbon.Collapsed:=True;
  Settle;
  lTab.Header.Click;
  Settle;
  lItem.Click;
  AssertEquals(1,FClicks);
  AssertFalse(FRibbon.PanelOpen);
  AssertEquals(0,OverlayCount);
end;

procedure TTestRibbon.TestContextualTabHiddenUntilShown;
var
  lTab: TRibbonTab;
begin
  Build(1000);
  FRibbon.AddTab('One');
  lTab:=FRibbon.AddContextualTab('Picture','Format');
  AssertTrue(lTab.Header.HasCSSClass(cRibbonHiddenClass));
  AssertFalse(lTab.TabVisible);
  FRibbon.ActiveTab:=lTab;
  AssertTrue('a hidden tab cannot be active',FRibbon.ActiveTab<>lTab);
  FRibbon.SetContextVisible('Picture',True);
  AssertFalse(lTab.Header.HasCSSClass(cRibbonHiddenClass));
  FRibbon.ActiveTab:=lTab;
  AssertSame(lTab,FRibbon.ActiveTab);
end;

procedure TTestRibbon.TestHidingContextLeavesActiveTab;
var
  lOne, lTab: TRibbonTab;
begin
  Build(1000);
  lOne:=FRibbon.AddTab('One');
  lTab:=FRibbon.AddContextualTab('Picture','Format');
  FRibbon.SetContextVisible('Picture',True);
  FRibbon.ActiveTab:=lTab;
  FRibbon.SetContextVisible('Picture',False);
  AssertSame(lOne,FRibbon.ActiveTab);
  AssertFalse(lOne.HasCSSClass(cRibbonHiddenClass));
  AssertTrue(lTab.HasCSSClass(cRibbonHiddenClass));
end;

procedure TTestRibbon.TestGalleryPaging;
var
  lGallery: TRibbonGallery;
  i: Integer;
begin
  Build(1000);
  lGallery:=FRibbon.AddTab('One').AddGroup('G').AddGallery(3);
  for i:=1 to 7 do
    lGallery.AddItem('Item '+IntToStr(i));
  AssertFalse(lGallery.Cells[2].HasCSSClass(cRibbonHiddenClass));
  AssertTrue(lGallery.Cells[3].HasCSSClass(cRibbonHiddenClass));
  lGallery.PageDown;
  AssertEquals(3,lGallery.TopIndex);
  AssertTrue(lGallery.Cells[0].HasCSSClass(cRibbonHiddenClass));
  AssertFalse(lGallery.Cells[3].HasCSSClass(cRibbonHiddenClass));
  lGallery.PageDown;
  AssertEquals('stops with a full last page',4,lGallery.TopIndex);
  lGallery.PageUp;
  lGallery.PageUp;
  AssertEquals(0,lGallery.TopIndex);
end;

procedure TTestRibbon.TestGallerySelect;
var
  lGallery: TRibbonGallery;
begin
  Build(1000);
  lGallery:=FRibbon.AddTab('One').AddGroup('G').AddGallery(3);
  lGallery.AddItem('A');
  lGallery.AddItem('B');
  lGallery.OnSelect:=@GallerySelect;
  lGallery.Cells[1].Click;
  AssertEquals(1,lGallery.SelectedIndex);
  AssertEquals(1,FSelected);
  AssertTrue(lGallery.Cells[1].HasCSSClass('ribbon-gallery-selected'));
  AssertFalse(lGallery.Cells[0].HasCSSClass('ribbon-gallery-selected'));
end;

procedure TTestRibbon.TestGalleryExpanded;
var
  lGallery: TRibbonGallery;
  lPopup: TFresnelElement;
  i: Integer;
begin
  Build(1000);
  lGallery:=FRibbon.AddTab('One').AddGroup('G').AddGallery(2);
  for i:=1 to 5 do
    lGallery.AddItem('Item '+IntToStr(i));
  lGallery.OnSelect:=@GallerySelect;
  Settle;
  lGallery.MoreButton.Click;
  AssertEquals(1,OverlayCount);
  lPopup:=TOverlayLayer.GetLayer(Viewport).Overlays[0].Content;
  AssertEquals(5,lPopup.NodeCount);
  (lPopup.Nodes[4] as TRibbonGalleryCell).Click;
  AssertEquals(4,FSelected);
  AssertEquals(4,lGallery.SelectedIndex);
  AssertEquals('the choice closes the popup',0,OverlayCount);
  // Open again: the old popup is replaced without trouble.
  lGallery.MoreButton.Click;
  AssertEquals(1,OverlayCount);
end;

procedure TTestRibbon.TestKeyTipsTopLevel;
begin
  Build(1000);
  FRibbon.AddTab('Home');
  FRibbon.AddTab('Insert');
  FRibbon.AddQuickButton('Save');
  Settle;
  FRibbon.ShowKeyTips;
  Settle;
  AssertTrue(FRibbon.KeyTipsActive);
  AssertEquals(1,FRibbon.KeyTipLevel);
  AssertEquals('file, save, home, insert',4,FRibbon.BadgeCount);
  AssertEquals(4,OverlayCount);
  AssertEquals('H',FRibbon.Badges[2].Caption);
end;

procedure TTestRibbon.TestKeyTipsEnterTabAndClick;
var
  lTwo: TRibbonTab;
begin
  Build(3000);
  FRibbon.AddTab('Home');
  lTwo:=FRibbon.AddTab('Insert');
  lTwo.AddGroup('G').AddButton('Picture',risLarge,@ItemClick);
  Settle;
  FRibbon.ShowKeyTips;
  Settle;
  AssertTrue(FRibbon.PressKeyTip('i'));
  AssertSame(lTwo,FRibbon.ActiveTab);
  AssertEquals(2,FRibbon.KeyTipLevel);
  Settle;
  AssertEquals(1,FRibbon.BadgeCount);
  AssertEquals('P',FRibbon.Badges[0].Caption);
  AssertTrue(FRibbon.PressKeyTip('P'));
  AssertEquals(1,FClicks);
  AssertFalse(FRibbon.KeyTipsActive);
  AssertEquals(0,OverlayCount);
end;

procedure TTestRibbon.TestKeyTipsHide;
begin
  Build(1000);
  FRibbon.AddTab('Home');
  Settle;
  FRibbon.ShowKeyTips;
  Settle;
  FRibbon.HideKeyTips;
  AssertFalse(FRibbon.KeyTipsActive);
  AssertEquals(0,FRibbon.BadgeCount);
  AssertEquals(0,OverlayCount);
end;

procedure TTestRibbon.TestKeyTipsIgnoresUnknownKey;
begin
  Build(1000);
  FRibbon.AddTab('Home');
  Settle;
  FRibbon.ShowKeyTips;
  Settle;
  AssertFalse(FRibbon.PressKeyTip('Q'));
  AssertTrue(FRibbon.KeyTipsActive);
  AssertTrue('typing starts over',FRibbon.PressKeyTip('H'));
end;

function TTestRibbon.IconFile: string;
begin
  // out\<target>\ohsribbontests.exe, next to the icons build.cmd copies.
  Result:=ExtractFilePath(ParamStr(0))+'icons'+PathDelim+'paste.png';
end;

function TTestRibbon.SendKey(const aKey: string): Boolean;
var
  lInit: TFresnelKeyEventInit;
begin
  lInit:=Default(TFresnelKeyEventInit);
  lInit.Key:=aKey;
  Result:=Viewport.WSKey(lInit,evtKeyDown);
end;

procedure TTestRibbon.TestIconItemsSurviveEveryWidth;
var
  lTab: TRibbonTab;
  lImage: TImageData;
  g, i, lWidth: Integer;
  lGroup: TRibbonGroup;
begin
  // Regression: an icon item going small raised in TTextButton (FC-02) and aborted layout.
  AssertTrue('icon file '+IconFile,FileExists(IconFile));
  Build(3000);
  lImage:=TImageData.Create(Viewport);
  lImage.LoadFromFile(IconFile);
  lTab:=FRibbon.AddTab('One');
  for g:=1 to 3 do
  begin
    lGroup:=lTab.AddGroup('Group');
    for i:=1 to 3 do
      lGroup.AddButton('Button',risLarge).Image:=lImage;
  end;
  Settle;
  lWidth:=3000;
  while lWidth>=100 do
  begin
    Viewport.Width:=lWidth;
    Settle;
    lWidth:=lWidth-300;
  end;
  Viewport.Width:=40;
  Settle;
  AssertTrue('the ribbon stays inside the window',FRibbon.UsedBorderBox.Width<=40);
  AssertTrue('the panel stays inside the ribbon',FRibbon.Panel.UsedBorderBox.Width<=FRibbon.UsedBorderBox.Width);
  AssertTrue('narrowest collapses',lTab.Groups[2].Collapsed);
  Viewport.Width:=3000;
  Settle;
  AssertEquals('and comes back',0,lTab.ScaleStep);
  AssertTrue((lTab.Groups[0].Items[0] as TRibbonItem).DisplaySize=risLarge);
end;

procedure TTestRibbon.TestIconOnlyKeepsCaption;
var
  lImage: TImageData;
  lItem: TRibbonItem;

  function ShowsLabel: Boolean;
  var
    i: Integer;
  begin
    Result:=False;
    for i:=0 to lItem.NodeCount-1 do
      if lItem.Nodes[i] is TCustomLabel then
        Exit(True);
  end;

begin
  Build(1000);
  lImage:=TImageData.Create(Viewport);
  lImage.LoadFromFile(IconFile);
  lItem:=FRibbon.AddTab('One').AddGroup('G').AddButton('Bold',risSmall);
  lItem.Image:=lImage;
  Settle;
  AssertFalse('small shows only the icon',ShowsLabel);
  AssertEquals('Bold',lItem.Caption);
  lItem.SetDisplaySize(risMedium);
  Settle;
  AssertTrue('medium shows the caption again',ShowsLabel);
end;

procedure TTestRibbon.TestKeyboardF6ShowsKeyTips;
begin
  Build(1000);
  FRibbon.AddTab('Home');
  Settle;
  AssertTrue('F6 is consumed',SendKey('F6'));
  AssertTrue(FRibbon.KeyTipsActive);
  Settle;
  AssertEquals(2,FRibbon.BadgeCount);
  AssertTrue('F6 again closes',SendKey('F6'));
  AssertFalse(FRibbon.KeyTipsActive);
end;

procedure TTestRibbon.TestKeyboardLetterAndEscape;
var
  lTwo: TRibbonTab;
begin
  Build(3000);
  FRibbon.AddTab('Home');
  lTwo:=FRibbon.AddTab('Insert');
  lTwo.AddGroup('G').AddButton('Picture',risLarge,@ItemClick);
  Settle;
  SendKey('F6');
  Settle;
  AssertTrue(SendKey('i'));
  AssertSame(lTwo,FRibbon.ActiveTab);
  AssertEquals(2,FRibbon.KeyTipLevel);
  Settle;
  AssertTrue('Escape goes back a level',SendKey('Escape'));
  AssertEquals(1,FRibbon.KeyTipLevel);
  Settle;
  AssertTrue('Escape closes',SendKey('Escape'));
  AssertFalse(FRibbon.KeyTipsActive);
  AssertEquals(0,OverlayCount);
end;

procedure TTestRibbon.TestEscapeOutsideKeyTipsIsNotConsumed;
begin
  Build(1000);
  FRibbon.AddTab('Home');
  Settle;
  AssertFalse('the application keeps its own Escape',SendKey('Escape'));
  AssertFalse(SendKey('x'));
end;

procedure TTestRibbon.TestKeyTipsSkipDisabled;
var
  lGroup: TRibbonGroup;
begin
  Build(3000);
  lGroup:=FRibbon.AddTab('Home').AddGroup('G');
  lGroup.AddButton('Open',risLarge);
  lGroup.AddButton('Close',risLarge).Enabled:=False;
  Settle;
  FRibbon.ShowKeyTips;
  Settle;
  AssertTrue(FRibbon.PressKeyTip('H'));
  Settle;
  AssertEquals('only the enabled button',1,FRibbon.BadgeCount);
end;

procedure TTestRibbon.TestKeyboardAltTapShowsKeyTips;
var
  lInit: TFresnelKeyEventInit;
begin
  Build(1000);
  FRibbon.AddTab('Home');
  Settle;
  AssertFalse('Alt going down stays with the system',SendKey('Alt'));
  AssertFalse(FRibbon.KeyTipsActive);
  lInit:=Default(TFresnelKeyEventInit);
  lInit.Key:='Alt';
  AssertTrue('Alt coming up is consumed, so no system menu',Viewport.WSKey(lInit,evtKeyUp));
  AssertTrue(FRibbon.KeyTipsActive);
  Settle;
  AssertTrue('Alt again closes',SendKey('Alt'));
  AssertFalse(FRibbon.KeyTipsActive);
end;

procedure TTestRibbon.TestDoubleClickHeaderCollapsesWithoutPopup;
var
  lTab: TRibbonTab;
  lEvent: TAbstractEvent;
begin
  // Regression, as seen with a real mouse: click, dblclick, click left the panel open.
  Build(1000);
  lTab:=FRibbon.AddTab('Home');
  FillTab(lTab);
  Settle;
  lTab.Header.Click;
  lEvent:=lTab.Header.EventDispatcher.CreateEvent(lTab.Header,evtDblClick);
  try
    Viewport.TestBubble(lTab.Header,lEvent as TFresnelEvent);
  finally
    lEvent.Free;
  end;
  lTab.Header.Click;
  AssertTrue(FRibbon.Collapsed);
  AssertFalse(FRibbon.PanelOpen);
  // The next ordinary click works again.
  lTab.Header.Click;
  AssertTrue(FRibbon.PanelOpen);
end;

// Every element of the ribbon is owned by it, so a count back to the one before adding shows that
// removing freed everything, also what is outside the element tree. A group keeps the columns it
// once needed for reuse, so for items the tests watch the removed elements instead.

procedure TTestRibbon.TestRemoveItemKeepsSizesInStep;
var
  lGroup: TRibbonGroup;
  lA, lB, lC: TRibbonItem;
  lWatch: TFreeWatch;
begin
  Build(3000);
  lWatch:=TFreeWatch.Create(nil);
  try
    lGroup:=FRibbon.AddTab('One').AddGroup('G');
    lA:=lGroup.AddButton('A',risSmall);
    lB:=lGroup.AddButton('B',risLarge);
    lC:=lGroup.AddButton('C',risSmall);
    lWatch.Watch(lB);
    lWatch.Watch(lC);
    Settle;
    AssertTrue('the large one splits the small ones',lA.Parent<>lC.Parent);
    lGroup.RemoveItem(lB);
    AssertTrue(lWatch.Freed(lB));
    Settle;
    AssertEquals(2,lGroup.ItemCount);
    AssertSame(lA,lGroup.Items[0]);
    AssertSame(lC,lGroup.Items[1]);
    AssertEquals(-1,lGroup.IndexOfItem(lB));
    AssertSame('two small ones share a column again',lA.Parent,lC.Parent);
    lGroup.RemoveItemAt(1);
    AssertTrue(lWatch.Freed(lC));
    Settle;
    AssertEquals(1,lGroup.ItemCount);
  finally
    lWatch.Free;
  end;
end;

procedure TTestRibbon.TestRemoveGalleryClosesItsPopup;
var
  lGroup: TRibbonGroup;
  lGallery: TRibbonGallery;
  lSplit: TRibbonSplitButton;
  lArrow: TRibbonItem;
  lPopup: TFresnelElement;
  lWatch: TFreeWatch;
  i: Integer;
begin
  Build(3000);
  lWatch:=TFreeWatch.Create(nil);
  try
    lGroup:=FRibbon.AddTab('One').AddGroup('G');
    lSplit:=lGroup.AddSplitButton('Paste',risLarge,@ItemClick);
    lArrow:=lSplit.Arrow;
    lGallery:=lGroup.AddGallery(2);
    for i:=1 to 5 do
      lGallery.AddItem('Item '+IntToStr(i));
    Settle;
    lGallery.MoreButton.Click;
    AssertEquals(1,OverlayCount);
    lPopup:=TOverlayLayer.GetLayer(Viewport).Overlays[0].Content;
    lWatch.Watch(lGallery);
    lWatch.Watch(lPopup);
    lWatch.Watch(lSplit);
    lWatch.Watch(lArrow);
    lGroup.RemoveItem(lGallery);
    AssertEquals('the expanded view goes with it',0,OverlayCount);
    AssertTrue(lWatch.Freed(lGallery));
    AssertTrue('the expanded view is freed too',lWatch.Freed(lPopup));
    lGroup.RemoveItem(lSplit);
    AssertTrue(lWatch.Freed(lSplit));
    AssertTrue('the parts of a split button go with it',lWatch.Freed(lArrow));
    Settle;
    AssertEquals(0,lGroup.ItemCount);
  finally
    lWatch.Free;
  end;
end;

procedure TTestRibbon.TestRemoveGroupFreesEverything;
var
  lTab: TRibbonTab;
  lKeep, lGroup: TRibbonGroup;
  lCount, i: Integer;
begin
  Build(3000);
  lTab:=FRibbon.AddTab('One');
  lKeep:=lTab.AddGroup('Keep');
  lKeep.AddButton('A');
  Settle;
  lCount:=FRibbon.ComponentCount;
  lGroup:=lTab.AddGroup('Plugin');
  for i:=1 to 6 do
    lGroup.AddButton('Small '+IntToStr(i),risSmall);
  lGroup.OnDialogLauncher:=@ItemClick;
  // Wide, then narrow: the group builds columns at several levels.
  Settle;
  Viewport.Width:=150;
  Settle;
  Viewport.Width:=3000;
  Settle;
  lTab.RemoveGroup(lGroup);
  Settle;
  AssertEquals(1,lTab.GroupCount);
  AssertSame(lKeep,lTab.Groups[0]);
  AssertEquals(-1,lTab.IndexOfGroup(lGroup));
  AssertEquals(lCount,FRibbon.ComponentCount);
end;

procedure TTestRibbon.TestRemoveCollapsedGroupWithOpenPopup;
var
  lTab: TRibbonTab;
  lGroup: TRibbonGroup;
begin
  Build(120);
  lTab:=FRibbon.AddTab('One');
  FillTab(lTab);
  Settle;
  lGroup:=lTab.Groups[3];
  lGroup.CollapsedButton.Click;
  AssertEquals(1,OverlayCount);
  lTab.RemoveGroup(lGroup);
  AssertEquals(0,OverlayCount);
  Settle;
  AssertEquals(3,lTab.GroupCount);
end;

procedure TTestRibbon.TestRemoveActiveTabActivatesNeighbour;
var
  lOne, lTwo, lThree: TRibbonTab;
  lCount: Integer;
begin
  Build(1000);
  lCount:=FRibbon.ComponentCount;
  lOne:=FRibbon.AddTab('One');
  lTwo:=FRibbon.AddTab('Two');
  lThree:=FRibbon.AddTab('Three');
  FillTab(lTwo);
  FRibbon.ActiveTab:=lTwo;
  Settle;
  FRibbon.OnTabChanged:=@TabChanged;
  FRibbon.RemoveTab(lTwo);
  AssertSame('the right neighbour',lThree,FRibbon.ActiveTab);
  AssertEquals(1,FTabChanges);
  AssertFalse(lThree.HasCSSClass(cRibbonHiddenClass));
  AssertTrue(lThree.Header.HasCSSClass(cRibbonActiveClass));
  FRibbon.RemoveTab(lThree);
  AssertSame('the left one when there is none on the right',lOne,FRibbon.ActiveTab);
  FRibbon.RemoveTab(lOne);
  AssertNull(FRibbon.ActiveTab);
  AssertEquals(0,FRibbon.TabCount);
  Settle;
  AssertEquals(lCount,FRibbon.ComponentCount);
end;

procedure TTestRibbon.TestRemoveLastContextualTabDropsContext;
var
  lOne, lFormat, lLayout: TRibbonTab;
  lCount: Integer;
begin
  Build(1000);
  lOne:=FRibbon.AddTab('One');
  Settle;
  lCount:=FRibbon.ComponentCount;
  lFormat:=FRibbon.AddContextualTab('Picture','Format');
  lLayout:=FRibbon.AddContextualTab('Picture','Layout');
  FRibbon.SetContextVisible('Picture',True);
  FRibbon.ActiveTab:=lFormat;
  FRibbon.RemoveTab(lFormat);
  AssertSame(lLayout,FRibbon.ActiveTab);
  AssertTrue('a tab of the context is left',FRibbon.IsContextVisible('Picture'));
  FRibbon.RemoveTab(lLayout);
  AssertSame(lOne,FRibbon.ActiveTab);
  AssertFalse(FRibbon.IsContextVisible('Picture'));
  AssertTrue('nothing left for the title row',FRibbon.Nodes[0].HasCSSClass(cRibbonHiddenClass));
  Settle;
  AssertEquals(lCount,FRibbon.ComponentCount);
end;

procedure TTestRibbon.TestRemoveQuickItemHidesTitleRow;
var
  lSave, lUndo: TRibbonItem;
  lCount: Integer;
begin
  Build(1000);
  FRibbon.AddTab('One');
  Settle;
  lCount:=FRibbon.ComponentCount;
  lSave:=FRibbon.AddQuickButton('Save');
  lUndo:=FRibbon.AddQuickButton('Undo');
  FRibbon.RemoveQuickItem(lSave);
  AssertEquals(1,FRibbon.QuickItemCount);
  AssertSame(lUndo,FRibbon.QuickItems[0]);
  AssertFalse(FRibbon.Nodes[0].HasCSSClass(cRibbonHiddenClass));
  FRibbon.RemoveQuickItem(lUndo);
  AssertEquals(0,FRibbon.QuickItemCount);
  AssertTrue(FRibbon.Nodes[0].HasCSSClass(cRibbonHiddenClass));
  AssertEquals(lCount,FRibbon.ComponentCount);
end;

procedure TTestRibbon.TestRemoveItemFromItsOwnClick;
var
  lWatch: TFreeWatch;
begin
  Build(1000);
  lWatch:=TFreeWatch.Create(nil);
  try
    FRemoveGroup:=FRibbon.AddTab('One').AddGroup('G');
    FRemoveItem:=FRemoveGroup.AddToggle('Unload',risLarge,@RemoveOnClick);
    lWatch.Watch(FRemoveItem);
    Settle;
    FRemoveItem.Click;
    AssertEquals(1,FClicks);
    AssertEquals(0,FRemoveGroup.ItemCount);
    AssertTrue('freed once the click is over',lWatch.Freed(FRemoveItem));
    Settle;
  finally
    lWatch.Free;
  end;
end;

procedure TTestRibbon.TestRemoveHidesKeyTips;
var
  lGroup: TRibbonGroup;
  lItem: TRibbonItem;
begin
  Build(3000);
  lGroup:=FRibbon.AddTab('Home').AddGroup('G');
  lGroup.AddButton('Open',risLarge);
  lItem:=lGroup.AddButton('Close',risLarge);
  Settle;
  FRibbon.ShowKeyTips;
  Settle;
  AssertTrue(FRibbon.PressKeyTip('H'));
  Settle;
  AssertEquals(2,FRibbon.BadgeCount);
  lGroup.RemoveItem(lItem);
  AssertFalse(FRibbon.KeyTipsActive);
  AssertEquals(0,FRibbon.BadgeCount);
  AssertEquals(0,OverlayCount);
end;

procedure TTestRibbon.TestRemoveUnknownDoesNothing;
var
  lTab: TRibbonTab;
  lGroup: TRibbonGroup;
  lItem: TRibbonItem;
begin
  Build(1000);
  lTab:=FRibbon.AddTab('One');
  lGroup:=lTab.AddGroup('G');
  lItem:=lGroup.AddButton('A');
  lGroup.RemoveItem(nil);
  lTab.AddGroup('Other').RemoveItem(lItem);
  lTab.RemoveGroup(nil);
  FRibbon.RemoveTab(nil);
  FRibbon.RemoveQuickItem(lItem);
  AssertEquals(1,lGroup.ItemCount);
  AssertEquals(2,lTab.GroupCount);
  AssertEquals(1,FRibbon.TabCount);
end;

procedure TTestRibbon.TestKeyTipsSkipHidden;
var
  lGroup: TRibbonGroup;
begin
  Build(3000);
  lGroup:=FRibbon.AddTab('Home').AddGroup('G');
  lGroup.AddButton('Open',risLarge);
  lGroup.AddButton('Close',risLarge).AddCSSClass(cRibbonHiddenClass);
  FRibbon.AddTab('Hidden').Header.AddCSSClass(cRibbonHiddenClass);
  FRibbon.AddQuickButton('Save').AddCSSClass(cRibbonHiddenClass);
  Settle;
  FRibbon.ShowKeyTips;
  Settle;
  AssertEquals('file and home',2,FRibbon.BadgeCount);
  AssertTrue(FRibbon.PressKeyTip('H'));
  Settle;
  AssertEquals('only the shown button',1,FRibbon.BadgeCount);
end;

initialization
  RegisterTest(TTestRibbon);
end.
