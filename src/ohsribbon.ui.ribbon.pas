{ The ribbon control on Fresnel (RB-001 to RB-050).

  The tree is built from code:

    Ribbon:=TRibbon.Create(Self);
    Ribbon.Parent:=Body;
    Tab:=Ribbon.AddTab('Home');
    Group:=Tab.AddGroup('Clipboard');
    Group.AddButton('Paste',risLarge,@PasteClick);

  The look is CSS: every colour is a --ribbon-* variable, see cRibbonCSS. }
unit ohsribbon.ui.ribbon;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Math, Types, fpCSSTree, fpCSSResParser,
  Fresnel.Classes, Fresnel.DOM, Fresnel.Controls, Fresnel.Images, Fresnel.Events,
  FCL.Events, Fresnel.Overlay, Fresnel.Menus,
  ohsribbon.model.sizing, ohsribbon.model.keytips;

const
  cRibbonHiddenClass     = 'ribbon-hidden';
  cRibbonActiveClass     = 'ribbon-active';
  cRibbonCheckedClass    = 'ribbon-checked';
  cRibbonPopupClass      = 'ribbon-popup';
  cRibbonLargeClass      = 'ribbon-large';
  cRibbonMediumClass     = 'ribbon-medium';
  cRibbonSmallClass      = 'ribbon-small';
  cRibbonKeyTipClass     = 'ribbon-keytip';
  cRibbonContextualClass = 'ribbon-contextual';

type
  TRibbon = class;
  TRibbonTab = class;
  TRibbonGroup = class;
  TRibbonGallery = class;

  TRibbonItemKind = (
    rikButton,   // fires OnClick
    rikToggle,   // flips Checked, then fires OnClick
    rikDropdown  // opens DropdownMenu or DropdownContent, then fires OnClick
  );

  { TRibbonItem - a ribbon button in any size or kind. }

  TRibbonItem = class(TTextButton)
  private
    class var FTypeID: TCSSNumericalID;
    class constructor InitTypeID;
  private
    FRibbon: TRibbon;
    FText: string;
    FKind: TRibbonItemKind;
    FChecked: Boolean;
    FDisplaySize: TRibbonItemSize;
    FPreferredSize: TRibbonItemSize;
    FMinimumSize: TRibbonItemSize;
    FDropdownMenu: TPopupMenu;
    FDropdownContent: TFresnelElement;
    FKeyTip: string;
    FOnDropdown: TNotifyEvent;
    procedure SetText(const aValue: string);
    procedure SetChecked(aValue: Boolean);
    procedure SetKind(aValue: TRibbonItemKind);
    procedure UpdateDisplay;
  protected
    procedure Notification(aComponent: TComponent; aOperation: TOperation); override;
    function ClosesPopupsOnClick: Boolean; virtual;
  public
    constructor CreateFor(aRibbon: TRibbon); virtual;
    class function CSSTypeID: TCSSNumericalID; override;
    class function CSSTypeName: TCSSString; override;
    class function GetCSSTypeStyle: TCSSString; override;
    procedure Click; override;
    // Show this item at aSize, regardless of its preferred size.
    procedure SetDisplaySize(aSize: TRibbonItemSize);
    // Open the dropdown as if the arrow was clicked.
    procedure OpenDropdown;
    property Caption: string read FText write SetText;
    property Kind: TRibbonItemKind read FKind write SetKind;
    property Checked: Boolean read FChecked write SetChecked;
    property DisplaySize: TRibbonItemSize read FDisplaySize;
    property PreferredSize: TRibbonItemSize read FPreferredSize write FPreferredSize;
    // The narrowest size adaptive sizing may use; default risSmall.
    property MinimumSize: TRibbonItemSize read FMinimumSize write FMinimumSize;
    property DropdownMenu: TPopupMenu read FDropdownMenu write FDropdownMenu;
    // An element shown in a popup. It is not owned; it is detached when the popup closes.
    property DropdownContent: TFresnelElement read FDropdownContent write FDropdownContent;
    // Fixed KeyTip; empty lets the ribbon choose one.
    property KeyTip: string read FKeyTip write FKeyTip;
    property OnDropdown: TNotifyEvent read FOnDropdown write FOnDropdown;
    property Ribbon: TRibbon read FRibbon;
  end;

  { TRibbonSplitButton - a button with a separate dropdown arrow. }

  TRibbonSplitButton = class(TDiv)
  private
    FMain: TRibbonItem;
    FArrow: TRibbonItem;
  public
    constructor CreateFor(aRibbon: TRibbon);
    procedure SetDisplaySize(aSize: TRibbonItemSize);
    // The part that fires OnClick.
    property Main: TRibbonItem read FMain;
    // The part that opens the dropdown: set its DropdownMenu or DropdownContent.
    property Arrow: TRibbonItem read FArrow;
  end;

  { TRibbonGalleryCell - one choice in a gallery. }

  TRibbonGalleryCell = class(TRibbonItem)
  private
    FGallery: TRibbonGallery;
    FIndex: Integer;
  public
    procedure Click; override;
  end;

  TRibbonGallerySelectEvent = procedure(Sender: TRibbonGallery; aIndex: Integer) of object;

  { TRibbonGallery - a row of choices with paging and an expanded view (RB-030). }

  TRibbonGallery = class(TDiv)
  private
    FRibbon: TRibbon;
    FCellHost: TDiv;
    FCells: TFPList;
    FUp, FDown, FMore: TRibbonItem;
    FColumns: Integer;
    FVisibleCount: Integer;
    FTop: Integer;
    FSelectedIndex: Integer;
    FPopup: TDiv;
    FOnSelect: TRibbonGallerySelectEvent;
    function GetCount: Integer;
    function GetCell(aIndex: Integer): TRibbonGalleryCell;
    procedure SetColumns(aValue: Integer);
    procedure SetSelectedIndex(aValue: Integer);
    procedure UpdateCells;
    procedure UpClick(aEvent: TAbstractEvent);
    procedure DownClick(aEvent: TAbstractEvent);
    procedure MoreDropdown(Sender: TObject);
    procedure PopupClosed(Sender: TObject);
  public
    constructor CreateFor(aRibbon: TRibbon);
    destructor Destroy; override;
    function AddItem(const aCaption: string; aImage: TImageData = nil): Integer;
    procedure SetDisplaySize(aSize: TRibbonItemSize);
    procedure PageUp;
    procedure PageDown;
    // The expanded view: a popup with all choices.
    procedure OpenExpanded;
    property Count: Integer read GetCount;
    property Cells[aIndex: Integer]: TRibbonGalleryCell read GetCell;
    // The number of choices in the row at full size.
    property Columns: Integer read FColumns write SetColumns;
    property VisibleCount: Integer read FVisibleCount;
    property TopIndex: Integer read FTop;
    property SelectedIndex: Integer read FSelectedIndex write SetSelectedIndex;
    property OnSelect: TRibbonGallerySelectEvent read FOnSelect write FOnSelect;
    property MoreButton: TRibbonItem read FMore;
  end;

  { TRibbonGroup - a captioned set of items; adaptive sizing reduces it per level. }

  TRibbonGroup = class(TDiv)
  private
    FTab: TRibbonTab;
    FRibbon: TRibbon;
    FItems: TFPList;
    FPreferred: array of TRibbonItemSize;
    FMinimum: array of TRibbonItemSize;
    FColumns: TFPList;
    FBody: TDiv;
    FFooter: TDiv;
    FCaptionLabel: TLabel;
    FLauncher: TRibbonItem;
    FCollapsedButton: TRibbonItem;
    FCaption: string;
    FCanCollapse: Boolean;
    FLevel: Integer;
    FBuiltLevel: Integer;
    FPopup: TOverlay;
    function GetItem(aIndex: Integer): TFresnelElement;
    function GetItemCount: Integer;
    function GetOnDialogLauncher: TFresnelEventHandler;
    procedure SetOnDialogLauncher(aValue: TFresnelEventHandler);
    procedure SetCaption(const aValue: string);
    procedure AddElement(aElement: TFresnelElement; aPreferred, aMinimum: TRibbonItemSize);
    procedure ArrangeBody(aLevel: Integer);
    procedure CollapsedDropdown(Sender: TObject);
    procedure PopupClosed(Sender: TObject);
    function GetCollapsed: Boolean;
    procedure TakeCollapsedIcon;
  public
    constructor CreateFor(aTab: TRibbonTab; const aCaption: string);
    destructor Destroy; override;
    function AddButton(const aCaption: string; aSize: TRibbonItemSize = risLarge;
      aOnClick: TFresnelEventHandler = nil): TRibbonItem;
    function AddToggle(const aCaption: string; aSize: TRibbonItemSize = risSmall;
      aOnClick: TFresnelEventHandler = nil): TRibbonItem;
    function AddDropdown(const aCaption: string; aSize: TRibbonItemSize = risLarge;
      aMenu: TPopupMenu = nil): TRibbonItem;
    function AddSplitButton(const aCaption: string; aSize: TRibbonItemSize = risLarge;
      aOnClick: TFresnelEventHandler = nil; aMenu: TPopupMenu = nil): TRibbonSplitButton;
    function AddGallery(aColumns: Integer = 4): TRibbonGallery;
    // Any Fresnel element, such as a combo box. It keeps its size at every level.
    procedure AddControl(aControl: TFresnelElement);
    // Re-apply the level, after a change in the items.
    procedure ApplyLevel(aLevel: Integer);
    property Caption: string read FCaption write SetCaption;
    property ItemCount: Integer read GetItemCount;
    property Items[aIndex: Integer]: TFresnelElement read GetItem;
    // When False the group never turns into a single dropdown.
    property CanCollapse: Boolean read FCanCollapse write FCanCollapse;
    property Level: Integer read FLevel;
    property Collapsed: Boolean read GetCollapsed;
    property CollapsedButton: TRibbonItem read FCollapsedButton;
    property Body: TDiv read FBody;
    // Assigning shows the small launcher arrow in the group caption (RB-008).
    property OnDialogLauncher: TFresnelEventHandler read GetOnDialogLauncher write SetOnDialogLauncher;
  end;

  { TRibbonTabHeader - the clickable caption of a tab. }

  TRibbonTabHeader = class(TTextButton)
  private
    class var FTypeID: TCSSNumericalID;
    class constructor InitTypeID;
  private
    FTab: TRibbonTab;
    FIgnoreClick: Boolean;
    FKeyTip: string;
    procedure DoubleClicked(aEvent: TAbstractEvent);
  public
    class function CSSTypeID: TCSSNumericalID; override;
    class function CSSTypeName: TCSSString; override;
    class function GetCSSTypeStyle: TCSSString; override;
    procedure Click; override;
    property Tab: TRibbonTab read FTab;
    property KeyTip: string read FKeyTip write FKeyTip;
  end;

  { TRibbonTab - a page of groups. }

  TRibbonTab = class(TDiv)
  private
    FRibbon: TRibbon;
    FHeader: TRibbonTabHeader;
    FGroups: TFPList;
    FContextName: string;
    FScaler: TRibbonScaler;
    FSteps: TRibbonScaleSteps;
    FLayoutDirty: Boolean;
    FLevelsDirty: Boolean;
    function GetCaption: string;
    function GetGroup(aIndex: Integer): TRibbonGroup;
    function GetGroupCount: Integer;
    procedure SetCaption(const aValue: string);
    procedure PrepareLayout;
    procedure ApplyLevels;
    function FeedScaler(aAvailable: TFresnelLength): Boolean;
    function GetTabVisible: Boolean;
  public
    constructor CreateFor(aRibbon: TRibbon; const aCaption, aContextName: string);
    destructor Destroy; override;
    function AddGroup(const aCaption: string): TRibbonGroup;
    // Forget the measured widths and start from full size.
    procedure InvalidateLayout;
    property Caption: string read GetCaption write SetCaption;
    property GroupCount: Integer read GetGroupCount;
    property Groups[aIndex: Integer]: TRibbonGroup read GetGroup;
    property Header: TRibbonTabHeader read FHeader;
    // Not empty for a contextual tab.
    property ContextName: string read FContextName;
    property TabVisible: Boolean read GetTabVisible;
    // The current scaling step; 0 is full size.
    function ScaleStep: Integer;
  end;

  TKeyTipState = (ktsOff, ktsWaitForLayout, ktsShowBadges, ktsOn);

  { TRibbon - the ribbon. }

  TRibbon = class(TFresnelElement)
  private
    class var FTypeID: TCSSNumericalID;
    class constructor InitTypeID;
  private
    FTitleRow: TDiv;
    FQuickAccess: TDiv;
    FQuickItems: TFPList;
    FContextBar: TDiv;
    FContextLabels: TStringList;
    FVisibleContexts: TStringList;
    FStrip: TDiv;
    FAppButton: TRibbonItem;
    FTabRow: TDiv;
    FCollapseButton: TRibbonItem;
    FPanel: TDiv;
    FTabs: TFPList;
    FActiveTab: TRibbonTab;
    FCollapsed: Boolean;
    FPanelPopup: TOverlay;
    FOnTabChanged: TNotifyEvent;
    // KeyTips
    FKeyTipKey: string;
    FKeyViewport: TFresnelViewport;
    FKeyState: TKeyTipState;
    FKeyLevel: Integer;
    FKeyElements: array of TFresnelElement;
    FKeyTips: TStringDynArray;
    FKeyTyped: string;
    FBadges: TFPList;
    FBadgeOverlays: TFPList;
    FAltArmed: Boolean;
    function GetTab(aIndex: Integer): TRibbonTab;
    function GetTabCount: Integer;
    function GetApplicationMenu: TPopupMenu;
    function GetApplicationCaption: string;
    function GetPanelOpen: Boolean;
    function GetKeyTipsActive: Boolean;
    function GetQuickItem(aIndex: Integer): TRibbonItem;
    function GetQuickItemCount: Integer;
    function GetBadge(aIndex: Integer): TLabel;
    function GetBadgeCount: Integer;
    procedure SetActiveTab(aValue: TRibbonTab);
    procedure SetApplicationCaption(const aValue: string);
    procedure SetApplicationMenu(aValue: TPopupMenu);
    procedure SetCollapsed(aValue: Boolean);
    procedure UpdateTitleRow;
    procedure UpdatePanelVisibility;
    procedure EnsureFirstActive;
    procedure OpenPanelPopup;
    procedure PanelPopupClosed(Sender: TObject);
    procedure CollapseClick(aEvent: TAbstractEvent);
    function Layer: TOverlayLayer;
    function CheckScale: Boolean;
    // KeyTips
    procedure InstallKeyListeners;
    procedure RemoveKeyListeners;
    procedure HandleKeyDown(aEvent: TAbstractEvent);
    procedure HandleKeyUp(aEvent: TAbstractEvent);
    procedure HandleMouseDown(aEvent: TAbstractEvent);
    procedure CollectKeyLevel(aLevel: Integer);
    procedure AddKeyElement(aElement: TFresnelElement);
    procedure ShowBadges;
    procedure RemoveBadges;
    procedure EnterKeyLevel(aLevel: Integer);
    procedure ActivateKeyElement(aElement: TFresnelElement);
  protected
    procedure Notification(aComponent: TComponent; aOperation: TOperation); override;
    procedure ItemActivated;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    class function CSSTypeID: TCSSNumericalID; override;
    class function CSSTypeName: TCSSString; override;
    class function GetCSSTypeStyle: TCSSString; override;
    procedure UpdateManagedNodes; override;
    procedure ComputeCSSLayoutFinished; override;
    function AddTab(const aCaption: string): TRibbonTab;
    // A tab that only shows while its context is shown (RB-031).
    function AddContextualTab(const aContextName, aCaption: string): TRibbonTab;
    procedure SetContextVisible(const aContextName: string; aVisible: Boolean);
    function IsContextVisible(const aContextName: string): Boolean;
    // Add a small button to the quick access toolbar (RB-006).
    function AddQuickButton(const aCaption: string; aOnClick: TFresnelEventHandler = nil): TRibbonItem;
    // Show the KeyTip badges (RB-040).
    procedure ShowKeyTips;
    procedure HideKeyTips;
    // Press one KeyTip key. True when it was a part of a KeyTip.
    function PressKeyTip(const aKey: string): Boolean;
    property TabCount: Integer read GetTabCount;
    property Tabs[aIndex: Integer]: TRibbonTab read GetTab;
    property ActiveTab: TRibbonTab read FActiveTab write SetActiveTab;
    property ApplicationButton: TRibbonItem read FAppButton;
    property ApplicationCaption: string read GetApplicationCaption write SetApplicationCaption;
    property ApplicationMenu: TPopupMenu read GetApplicationMenu write SetApplicationMenu;
    property QuickItemCount: Integer read GetQuickItemCount;
    property QuickItems[aIndex: Integer]: TRibbonItem read GetQuickItem;
    // A collapsed ribbon shows only the tab row (RB-007).
    property Collapsed: Boolean read FCollapsed write SetCollapsed;
    // True while a collapsed ribbon shows its panel on demand.
    property PanelOpen: Boolean read GetPanelOpen;
    property Panel: TDiv read FPanel;
    // The key that starts KeyTips next to Alt.
    property KeyTipKey: string read FKeyTipKey write FKeyTipKey;
    property KeyTipsActive: Boolean read GetKeyTipsActive;
    property KeyTipLevel: Integer read FKeyLevel;
    property BadgeCount: Integer read GetBadgeCount;
    property Badges[aIndex: Integer]: TLabel read GetBadge;
    property OnTabChanged: TNotifyEvent read FOnTabChanged write FOnTabChanged;
  end;

implementation

resourcestring
  rsRibbonApplicationButton = 'File';

const
  // UTF-8 of the arrows; source files stay ASCII.
  cArrowDown  = #$E2#$96#$BE; // U+25BE
  cArrowUp    = #$E2#$96#$B4; // U+25B4
  cLauncher   = #$E2#$86#$98; // U+2198

  cRibbonVariablesLight =
    '--ribbon-surface: #f5f5f5; --ribbon-panel: #fbfbfb; --ribbon-border: #d4d4d4;'
    +' --ribbon-text: #1f1f1f; --ribbon-muted: #616161; --ribbon-hover: #e4e4e4;'
    +' --ribbon-pressed: #d0d0d0; --ribbon-accent: #33658a; --ribbon-on-accent: #ffffff;'
    +' --ribbon-checked: #d5e3ee; --ribbon-context: #8a5a33;'
    +' --ribbon-keytip: #3a3a3a; --ribbon-on-keytip: #ffffff;';
  cRibbonVariablesDark =
    '--ribbon-surface: #252526; --ribbon-panel: #2e2e30; --ribbon-border: #454548;'
    +' --ribbon-text: #e6e6e6; --ribbon-muted: #a6a6a6; --ribbon-hover: #3d3d40;'
    +' --ribbon-pressed: #4a4a4e; --ribbon-accent: #5d93bb; --ribbon-on-accent: #101010;'
    +' --ribbon-checked: #2f4a5e; --ribbon-context: #c79468;'
    +' --ribbon-keytip: #e6e6e6; --ribbon-on-keytip: #1f1f1f;';

  cRibbonCSS =
    'ribbon, .ribbon-popup { '+cRibbonVariablesLight+' }'
    +' @media (prefers-color-scheme: dark) { ribbon, .ribbon-popup { '+cRibbonVariablesDark+' } }'
    +' ribbon { display: flex; flex-direction: column; flex-shrink: 0; min-width: 0; font-size: 12px;'
    +' color: var(--ribbon-text); background-color: var(--ribbon-surface); }'
    +' .ribbon-titlebar { display: flex; flex-direction: row; align-items: center; padding: 2px 6px; gap: 2px; }'
    +' .ribbon-quickaccess { display: flex; flex-direction: row; gap: 2px; }'
    +' .ribbon-contextbar { display: flex; flex-direction: row; gap: 6px; margin-left: 12px; }'
    +' .ribbon-context-label { padding: 2px 8px; font-weight: bold; color: var(--ribbon-context); }'
    +' .ribbon-tabstrip { display: flex; flex-direction: row; align-items: stretch;'
    +' border-bottom: 1px solid var(--ribbon-border); }'
    +' .ribbon-tabrow { display: flex; flex-direction: row; flex-grow: 1; flex-shrink: 1; min-width: 0; overflow-x: hidden; }'
    +' ribbontabheader { display: flex; align-items: center; flex-shrink: 0; padding: 5px 12px;'
    +' color: var(--ribbon-text); border-bottom: 2px solid transparent; cursor: default; }'
    +' ribbontabheader:hover { background-color: var(--ribbon-hover); }'
    +' ribbontabheader.ribbon-active { color: var(--ribbon-accent); font-weight: bold;'
    +' border-bottom: 2px solid var(--ribbon-accent); }'
    +' ribbontabheader.ribbon-contextual { color: var(--ribbon-context); }'
    +' ribbontabheader.ribbon-contextual.ribbon-active { border-bottom: 2px solid var(--ribbon-context); }'
    +' .ribbon-panel { display: block; box-sizing: border-box; width: 100%; min-width: 0; padding: 4px; overflow-x: hidden;'
    +' background-color: var(--ribbon-panel); border-bottom: 1px solid var(--ribbon-border); }'
    +' .ribbon-tab { display: flex; flex-direction: row; align-items: stretch; }'
    +' .ribbon-group { display: flex; flex-direction: column; flex-shrink: 0; min-height: 88px; padding: 0 4px;'
    +' border-right: 1px solid var(--ribbon-border); }'
    +' .ribbon-group-body { display: flex; flex-direction: row; align-items: flex-start; gap: 2px; height: 70px; }'
    +' .ribbon-group-footer { display: flex; flex-direction: row; align-items: center; justify-content: center;'
    +' height: 18px; color: var(--ribbon-muted); font-size: 11px; }'
    +' .ribbon-column { display: flex; flex-direction: column; align-items: stretch; }'
    +' ribbonbutton { display: flex; flex-shrink: 0; box-sizing: border-box; align-items: center;'
    +' color: var(--ribbon-text); border-radius: 3px; cursor: default; user-select: none; gap: 4px; }'
    +' ribbonbutton:hover { background-color: var(--ribbon-hover); }'
    +' ribbonbutton.pressed { background-color: var(--ribbon-pressed); }'
    +' ribbonbutton:disabled { opacity: 0.45; }'
    +' ribbonbutton.ribbon-checked { background-color: var(--ribbon-checked); }'
    +' ribbonbutton img { width: 16px; height: 16px; flex-shrink: 0; }'
    +' ribbonbutton.ribbon-large { min-width: 46px; height: 70px; padding: 4px 6px; justify-content: flex-start; }'
    +' ribbonbutton.ribbon-large img { width: 32px; height: 32px; }'
    +' ribbonbutton.ribbon-medium { height: 23px; padding: 2px 6px; }'
    +' ribbonbutton.ribbon-small { height: 23px; min-width: 24px; padding: 2px 4px; justify-content: center; }'
    +' ribbonbutton.ribbon-group-collapsed { height: 88px; justify-content: center; }'
    +' .ribbon-split { display: flex; flex-direction: row; flex-shrink: 0; }'
    +' .ribbon-split-large { flex-direction: column; }'
    +' .ribbon-split-large ribbonbutton.ribbon-large { height: 52px; }'
    +' .ribbon-split-large ribbonbutton.ribbon-medium { height: 18px; padding: 0; justify-content: center; }'
    +' .ribbon-split ribbonbutton.ribbon-medium.ribbon-split-arrow { padding: 0 3px; }'
    +' ribbonbutton.ribbon-launcher { margin-left: 4px; padding: 0 3px; height: 14px; font-size: 10px; }'
    +' ribbonbutton.ribbon-appbutton { padding: 5px 14px; color: var(--ribbon-on-accent);'
    +' background-color: var(--ribbon-accent); border-radius: 0; }'
    +' ribbonbutton.ribbon-appbutton:hover { background-color: var(--ribbon-context); }'
    +' ribbonbutton.ribbon-collapse { padding: 0 8px; border-radius: 0; }'
    +' .ribbon-gallery { display: flex; flex-direction: row; flex-shrink: 0; height: 70px;'
    +' border: 1px solid var(--ribbon-border); box-sizing: border-box; }'
    +' .ribbon-gallery-cells { display: flex; flex-direction: row; flex-shrink: 0; }'
    +' .ribbon-gallery-nav { display: flex; flex-direction: column; flex-shrink: 0;'
    +' border-left: 1px solid var(--ribbon-border); }'
    +' ribbonbutton.ribbon-gallery-navbutton { height: 22px; min-width: 16px; padding: 0 2px; border-radius: 0; justify-content: center; }'
    +' ribbonbutton.ribbon-gallery-cell { width: 58px; min-width: 58px; height: 68px; padding: 4px 2px; border-radius: 0; }'
    +' ribbonbutton.ribbon-gallery-selected { background-color: var(--ribbon-checked); }'
    +' .ribbon-popup { color: var(--ribbon-text); background-color: var(--ribbon-panel); font-size: 12px;'
    +' border: 1px solid var(--ribbon-border); }'
    +' .ribbon-group-body.ribbon-popup { height: auto; padding: 4px; }'
    +' .ribbon-panel.ribbon-popup { padding: 4px; }'
    +' .ribbon-gallery-popup { display: flex; flex-direction: row; flex-wrap: wrap; width: 244px; padding: 2px; }'
    +' .ribbon-keytip { padding: 0 4px; font-size: 11px; color: var(--ribbon-on-keytip);'
    +' background-color: var(--ribbon-keytip); border-radius: 2px; }'
    +' .ribbon-spacer { flex-grow: 1; }'
    +' .ribbon-hidden { display: none; }';

function NewDiv(aOwner: TComponent; aParent: TFresnelElement; const aClass: string): TDiv;
begin
  Result:=TDiv.Create(aOwner);
  Result.AddCSSClass(aClass);
  if aParent<>nil then
    Result.Parent:=aParent;
end;

// The border box of aElement in viewport coordinates.
function ViewportRect(aElement: TFresnelElement): TFresnelRect;
var
  lPoint: TFresnelPoint;
  lBox: TFresnelRect;
begin
  lBox:=aElement.UsedBorderBox;
  lPoint:=aElement.Viewport.PaddingBoxToViewport(aElement,0,0);
  Result.Left:=lPoint.X;
  Result.Top:=lPoint.Y;
  Result.Right:=lPoint.X+lBox.Width;
  Result.Bottom:=lPoint.Y+lBox.Height;
end;

procedure SetClass(aElement: TFresnelElement; const aClass: string; aOn: Boolean);
begin
  if aOn then
  begin
    if not aElement.HasCSSClass(aClass) then
      aElement.AddCSSClass(aClass);
  end
  else if aElement.HasCSSClass(aClass) then
    aElement.RemoveCSSClass(aClass);
end;

{ TRibbonItem }

class constructor TRibbonItem.InitTypeID;
begin
  FTypeID:=CSSRegistry.AddType(CSSTypeName).Index;
end;

constructor TRibbonItem.CreateFor(aRibbon: TRibbon);
begin
  inherited Create(aRibbon);
  FRibbon:=aRibbon;
  CanFocus:=False; // the ribbon leaves the focus in the document
  FPreferredSize:=risLarge;
  FMinimumSize:=risSmall;
  FDisplaySize:=risLarge;
  SetDisplaySize(risMedium);
end;

class function TRibbonItem.CSSTypeID: TCSSNumericalID;
begin
  Result:=FTypeID;
end;

class function TRibbonItem.CSSTypeName: TCSSString;
begin
  Result:='ribbonbutton';
end;

class function TRibbonItem.GetCSSTypeStyle: TCSSString;
begin
  Result:=''; // all in cRibbonCSS
end;

procedure TRibbonItem.Notification(aComponent: TComponent; aOperation: TOperation);
begin
  inherited Notification(aComponent,aOperation);
  if aOperation=opRemove then
  begin
    if aComponent=FDropdownMenu then
      FDropdownMenu:=nil;
    if aComponent=FDropdownContent then
      FDropdownContent:=nil;
  end;
end;

function TRibbonItem.ClosesPopupsOnClick: Boolean;
begin
  Result:=FKind<>rikDropdown;
end;

procedure TRibbonItem.SetText(const aValue: string);
begin
  if FText=aValue then
    Exit;
  FText:=aValue;
  UpdateDisplay;
end;

procedure TRibbonItem.SetChecked(aValue: Boolean);
begin
  if FChecked=aValue then
    Exit;
  FChecked:=aValue;
  SetClass(Self,cRibbonCheckedClass,FChecked);
  DomChanged;
end;

procedure TRibbonItem.SetKind(aValue: TRibbonItemKind);
begin
  if FKind=aValue then
    Exit;
  FKind:=aValue;
  UpdateDisplay;
end;

procedure TRibbonItem.UpdateDisplay;
var
  lText: string;
  lIconOnly: Boolean;
begin
  lIconOnly:=HaveImage and ((FDisplaySize=risSmall) or (FText=''));
  lText:=FText;
  if FKind=rikDropdown then
    if lIconOnly or (lText='') then
    begin
      lText:=cArrowDown;
      lIconOnly:=False;
    end
    else
      lText:=lText+' '+cArrowDown;
  if lIconOnly then
    lText:='';
  inherited Caption:=lText;
end;

procedure TRibbonItem.SetDisplaySize(aSize: TRibbonItemSize);
begin
  if aSize<>FDisplaySize then
  begin
    FDisplaySize:=aSize;
    SetClass(Self,cRibbonLargeClass,aSize=risLarge);
    SetClass(Self,cRibbonMediumClass,aSize=risMedium);
    SetClass(Self,cRibbonSmallClass,aSize=risSmall);
    if aSize=risLarge then
      IconPosition:=ipTop
    else
      IconPosition:=ipLeft;
  end;
  UpdateDisplay;
end;

procedure TRibbonItem.OpenDropdown;
var
  lRect: TFresnelRect;
begin
  if Viewport=nil then
    Exit;
  if Assigned(FOnDropdown) then
    FOnDropdown(Self)
  else if FDropdownMenu<>nil then
  begin
    lRect:=ViewportRect(Self);
    FDropdownMenu.PopUp(Viewport,lRect.Left,lRect.Bottom);
  end
  else if FDropdownContent<>nil then
  begin
    SetClass(FDropdownContent,cRibbonPopupClass,True);
    TOverlayLayer.GetLayer(Viewport).Open(FDropdownContent,ViewportRect(Self));
  end;
end;

procedure TRibbonItem.Click;
begin
  if not Enabled then
    Exit;
  if FKind=rikToggle then
    Checked:=not Checked;
  if FKind=rikDropdown then
    OpenDropdown;
  inherited Click;
  if ClosesPopupsOnClick and (FRibbon<>nil) then
    FRibbon.ItemActivated;
end;

{ TRibbonSplitButton }

constructor TRibbonSplitButton.CreateFor(aRibbon: TRibbon);
begin
  inherited Create(aRibbon);
  AddCSSClass('ribbon-split');
  FMain:=TRibbonItem.CreateFor(aRibbon);
  FMain.Parent:=Self;
  FArrow:=TRibbonItem.CreateFor(aRibbon);
  FArrow.Kind:=rikDropdown;
  FArrow.AddCSSClass('ribbon-split-arrow');
  FArrow.Parent:=Self;
end;

procedure TRibbonSplitButton.SetDisplaySize(aSize: TRibbonItemSize);
begin
  SetClass(Self,'ribbon-split-large',aSize=risLarge);
  FMain.SetDisplaySize(aSize);
  FArrow.SetDisplaySize(risMedium);
end;

{ TRibbonGalleryCell }

procedure TRibbonGalleryCell.Click;
begin
  if not Enabled then
    Exit;
  if FGallery<>nil then
    FGallery.SelectedIndex:=FIndex;
  inherited Click;
  if (FGallery<>nil) and Assigned(FGallery.FOnSelect) then
    FGallery.FOnSelect(FGallery,FIndex);
end;

{ TRibbonGallery }

constructor TRibbonGallery.CreateFor(aRibbon: TRibbon);

  function NavButton(aHost: TDiv; const aCaption: string): TRibbonItem;
  begin
    Result:=TRibbonItem.CreateFor(aRibbon);
    Result.AddCSSClass('ribbon-gallery-navbutton');
    Result.Caption:=aCaption;
    Result.SetDisplaySize(risSmall);
    Result.Parent:=aHost;
  end;

var
  lNav: TDiv;
begin
  inherited Create(aRibbon);
  FRibbon:=aRibbon;
  FCells:=TFPList.Create;
  FColumns:=4;
  FVisibleCount:=4;
  FSelectedIndex:=-1;
  AddCSSClass('ribbon-gallery');
  FCellHost:=NewDiv(aRibbon,Self,'ribbon-gallery-cells');
  lNav:=NewDiv(aRibbon,Self,'ribbon-gallery-nav');
  FUp:=NavButton(lNav,cArrowUp);
  FUp.OnClick:=@UpClick;
  FDown:=NavButton(lNav,cArrowDown);
  FDown.OnClick:=@DownClick;
  FMore:=NavButton(lNav,'');
  FMore.Kind:=rikDropdown;
  FMore.OnDropdown:=@MoreDropdown;
end;

destructor TRibbonGallery.Destroy;
begin
  FreeAndNil(FCells);
  inherited Destroy;
end;

function TRibbonGallery.GetCount: Integer;
begin
  Result:=FCells.Count;
end;

function TRibbonGallery.GetCell(aIndex: Integer): TRibbonGalleryCell;
begin
  Result:=TRibbonGalleryCell(FCells[aIndex]);
end;

procedure TRibbonGallery.SetColumns(aValue: Integer);
begin
  FColumns:=Max(1,aValue);
  FVisibleCount:=FColumns;
  UpdateCells;
end;

procedure TRibbonGallery.SetSelectedIndex(aValue: Integer);
begin
  if aValue>=Count then
    aValue:=-1;
  FSelectedIndex:=aValue;
  UpdateCells;
end;

function TRibbonGallery.AddItem(const aCaption: string; aImage: TImageData): Integer;
var
  lCell: TRibbonGalleryCell;
begin
  lCell:=TRibbonGalleryCell.CreateFor(FRibbon);
  lCell.FGallery:=Self;
  lCell.FIndex:=FCells.Count;
  lCell.AddCSSClass('ribbon-gallery-cell');
  if aImage<>nil then
    lCell.Image:=aImage;
  lCell.Caption:=aCaption;
  lCell.SetDisplaySize(risLarge);
  lCell.Parent:=FCellHost;
  Result:=FCells.Add(lCell);
  UpdateCells;
end;

procedure TRibbonGallery.UpdateCells;
var
  i: Integer;
begin
  if FTop>Count-FVisibleCount then
    FTop:=Max(0,Count-FVisibleCount);
  for i:=0 to Count-1 do
  begin
    SetClass(Cells[i],cRibbonHiddenClass,(i<FTop) or (i>=FTop+FVisibleCount));
    SetClass(Cells[i],'ribbon-gallery-selected',i=FSelectedIndex);
  end;
  FUp.Enabled:=FTop>0;
  FDown.Enabled:=FTop+FVisibleCount<Count;
  DomChanged;
end;

procedure TRibbonGallery.SetDisplaySize(aSize: TRibbonItemSize);
begin
  case aSize of
    risLarge: FVisibleCount:=FColumns;
    risMedium: FVisibleCount:=Max(1,(FColumns+1) div 2);
    risSmall: FVisibleCount:=1;
  end;
  UpdateCells;
end;

procedure TRibbonGallery.PageUp;
begin
  FTop:=Max(0,FTop-FVisibleCount);
  UpdateCells;
end;

procedure TRibbonGallery.PageDown;
begin
  FTop:=FTop+FVisibleCount;
  UpdateCells;
end;

procedure TRibbonGallery.UpClick(aEvent: TAbstractEvent);
begin
  if aEvent=nil then ;
  PageUp;
end;

procedure TRibbonGallery.DownClick(aEvent: TAbstractEvent);
begin
  if aEvent=nil then ;
  PageDown;
end;

procedure TRibbonGallery.MoreDropdown(Sender: TObject);
begin
  if Sender=nil then ;
  OpenExpanded;
end;

procedure TRibbonGallery.OpenExpanded;
var
  i: Integer;
  lCell, lCopy: TRibbonGalleryCell;
  lOverlay: TOverlay;
begin
  if Viewport=nil then
    Exit;
  FreeAndNil(FPopup);
  FPopup:=NewDiv(FRibbon,nil,'ribbon-gallery-popup');
  FPopup.AddCSSClass(cRibbonPopupClass);
  for i:=0 to Count-1 do
  begin
    lCell:=Cells[i];
    lCopy:=TRibbonGalleryCell.CreateFor(FRibbon);
    lCopy.FGallery:=Self;
    lCopy.FIndex:=i;
    lCopy.AddCSSClass('ribbon-gallery-cell');
    if lCell.HaveImage then
      lCopy.Image:=lCell.Image;
    lCopy.Caption:=lCell.Caption;
    lCopy.SetDisplaySize(risLarge);
    SetClass(lCopy,'ribbon-gallery-selected',i=FSelectedIndex);
    lCopy.Parent:=FPopup;
  end;
  lOverlay:=TOverlayLayer.GetLayer(Viewport).Open(FPopup,ViewportRect(Self));
  lOverlay.OnClose:=@PopupClosed;
end;

procedure TRibbonGallery.PopupClosed(Sender: TObject);
begin
  // FPopup may hold the clicked cell, so it is freed by the next OpenExpanded.
  if Sender=nil then ;
end;

{ TRibbonGroup }

constructor TRibbonGroup.CreateFor(aTab: TRibbonTab; const aCaption: string);
begin
  inherited Create(aTab.FRibbon);
  FTab:=aTab;
  FRibbon:=aTab.FRibbon;
  FItems:=TFPList.Create;
  FColumns:=TFPList.Create;
  FCanCollapse:=True;
  FBuiltLevel:=-1;
  AddCSSClass('ribbon-group');

  FCollapsedButton:=TRibbonItem.CreateFor(FRibbon);
  FCollapsedButton.Kind:=rikDropdown;
  FCollapsedButton.OnDropdown:=@CollapsedDropdown;
  FCollapsedButton.SetDisplaySize(risLarge);
  FCollapsedButton.AddCSSClass('ribbon-group-collapsed');
  FCollapsedButton.AddCSSClass(cRibbonHiddenClass);
  FCollapsedButton.Parent:=Self;

  FBody:=NewDiv(FRibbon,Self,'ribbon-group-body');
  FFooter:=NewDiv(FRibbon,Self,'ribbon-group-footer');
  FCaptionLabel:=TLabel.Create(FRibbon);
  FCaptionLabel.Parent:=FFooter;
  Caption:=aCaption;
end;

destructor TRibbonGroup.Destroy;
begin
  FreeAndNil(FItems);
  FreeAndNil(FColumns);
  inherited Destroy;
end;

function TRibbonGroup.GetItem(aIndex: Integer): TFresnelElement;
begin
  Result:=TFresnelElement(FItems[aIndex]);
end;

function TRibbonGroup.GetItemCount: Integer;
begin
  Result:=FItems.Count;
end;

function TRibbonGroup.GetCollapsed: Boolean;
begin
  Result:=FLevel>=cRibbonLevelCollapsed;
end;

function TRibbonGroup.GetOnDialogLauncher: TFresnelEventHandler;
begin
  Result:=nil;
  if FLauncher<>nil then
    Result:=FLauncher.OnClick;
end;

procedure TRibbonGroup.SetOnDialogLauncher(aValue: TFresnelEventHandler);
begin
  if FLauncher=nil then
  begin
    FLauncher:=TRibbonItem.CreateFor(FRibbon);
    FLauncher.AddCSSClass('ribbon-launcher');
    FLauncher.Caption:=cLauncher;
    FLauncher.Parent:=FFooter;
  end;
  FLauncher.OnClick:=aValue;
end;

procedure TRibbonGroup.SetCaption(const aValue: string);
begin
  FCaption:=aValue;
  FCaptionLabel.Caption:=aValue;
  FCollapsedButton.Caption:=aValue;
end;

procedure TRibbonGroup.AddElement(aElement: TFresnelElement; aPreferred, aMinimum: TRibbonItemSize);
var
  lCount: Integer;
begin
  FItems.Add(aElement);
  lCount:=FItems.Count;
  SetLength(FPreferred,lCount);
  SetLength(FMinimum,lCount);
  FPreferred[lCount-1]:=aPreferred;
  FMinimum[lCount-1]:=aMinimum;
  FBuiltLevel:=-1;
  FTab.InvalidateLayout;
end;

function TRibbonGroup.AddButton(const aCaption: string; aSize: TRibbonItemSize;
  aOnClick: TFresnelEventHandler): TRibbonItem;
begin
  Result:=TRibbonItem.CreateFor(FRibbon);
  Result.Caption:=aCaption;
  Result.PreferredSize:=aSize;
  if aOnClick<>nil then
    Result.OnClick:=aOnClick;
  AddElement(Result,aSize,risSmall);
end;

function TRibbonGroup.AddToggle(const aCaption: string; aSize: TRibbonItemSize;
  aOnClick: TFresnelEventHandler): TRibbonItem;
begin
  Result:=AddButton(aCaption,aSize,aOnClick);
  Result.Kind:=rikToggle;
end;

function TRibbonGroup.AddDropdown(const aCaption: string; aSize: TRibbonItemSize;
  aMenu: TPopupMenu): TRibbonItem;
begin
  Result:=AddButton(aCaption,aSize);
  Result.Kind:=rikDropdown;
  Result.DropdownMenu:=aMenu;
end;

function TRibbonGroup.AddSplitButton(const aCaption: string; aSize: TRibbonItemSize;
  aOnClick: TFresnelEventHandler; aMenu: TPopupMenu): TRibbonSplitButton;
begin
  Result:=TRibbonSplitButton.CreateFor(FRibbon);
  Result.Main.Caption:=aCaption;
  Result.Main.PreferredSize:=aSize;
  if aOnClick<>nil then
    Result.Main.OnClick:=aOnClick;
  Result.Arrow.DropdownMenu:=aMenu;
  AddElement(Result,aSize,risSmall);
end;

function TRibbonGroup.AddGallery(aColumns: Integer): TRibbonGallery;
begin
  Result:=TRibbonGallery.CreateFor(FRibbon);
  Result.Columns:=aColumns;
  AddElement(Result,risLarge,risSmall);
end;

procedure TRibbonGroup.AddControl(aControl: TFresnelElement);
begin
  AddElement(aControl,risMedium,risMedium);
end;

procedure TRibbonGroup.ArrangeBody(aLevel: Integer);
var
  i: Integer;
  lSizes: TRibbonItemSizes;
  lPreferred, lMinimum: TRibbonItemSizes;
  lColumnOf: TIntegerDynArray;
  lColumn: TDiv;
  lElement: TFresnelElement;
begin
  lPreferred:=nil;
  lMinimum:=nil;
  SetLength(lPreferred,Length(FPreferred));
  SetLength(lMinimum,Length(FMinimum));
  for i:=0 to High(FPreferred) do
  begin
    lPreferred[i]:=FPreferred[i];
    lMinimum[i]:=FMinimum[i];
  end;
  lSizes:=ReducedSizes(lPreferred,lMinimum,aLevel);
  lColumnOf:=PackColumns(lSizes);
  for i:=0 to FColumns.Count-1 do
    TDiv(FColumns[i]).Parent:=nil;
  for i:=0 to FItems.Count-1 do
  begin
    while FColumns.Count<=lColumnOf[i] do
      FColumns.Add(NewDiv(FRibbon,nil,'ribbon-column'));
    lColumn:=TDiv(FColumns[lColumnOf[i]]);
    if lColumn.Parent=nil then
      lColumn.Parent:=FBody;
    lElement:=Items[i];
    lElement.Parent:=lColumn;
    if lElement is TRibbonItem then
      TRibbonItem(lElement).SetDisplaySize(lSizes[i])
    else if lElement is TRibbonSplitButton then
      TRibbonSplitButton(lElement).SetDisplaySize(lSizes[i])
    else if lElement is TRibbonGallery then
      TRibbonGallery(lElement).SetDisplaySize(lSizes[i]);
  end;
end;

procedure TRibbonGroup.TakeCollapsedIcon;
var
  i: Integer;
  lItem: TRibbonItem;
begin
  if FCollapsedButton.HaveImage then
    Exit;
  for i:=0 to ItemCount-1 do
  begin
    lItem:=nil;
    if Items[i] is TRibbonSplitButton then
      lItem:=TRibbonSplitButton(Items[i]).Main
    else if Items[i] is TRibbonItem then
      lItem:=TRibbonItem(Items[i]);
    if (lItem<>nil) and lItem.HaveImage then
    begin
      FCollapsedButton.Image:=lItem.Image;
      FCollapsedButton.UpdateDisplay;
      Exit;
    end;
  end;
end;

procedure TRibbonGroup.ApplyLevel(aLevel: Integer);
begin
  FLevel:=aLevel;
  if (FPopup<>nil) or ((FBuiltLevel=aLevel) and (FBuiltLevel>=0)) then
    Exit;
  FBuiltLevel:=aLevel;
  if aLevel<cRibbonLevelCollapsed then
    ArrangeBody(aLevel)
  else
  begin
    TakeCollapsedIcon;
    ArrangeBody(0); // the popup shows the group at full size
  end;
  SetClass(FBody,cRibbonHiddenClass,aLevel>=cRibbonLevelCollapsed);
  SetClass(FFooter,cRibbonHiddenClass,aLevel>=cRibbonLevelCollapsed);
  SetClass(FCollapsedButton,cRibbonHiddenClass,aLevel<cRibbonLevelCollapsed);
end;

procedure TRibbonGroup.CollapsedDropdown(Sender: TObject);
begin
  if (Sender=nil) or (Viewport=nil) or (FPopup<>nil) or not Collapsed then
    Exit;
  SetClass(FBody,cRibbonHiddenClass,False);
  SetClass(FBody,cRibbonPopupClass,True);
  FPopup:=TOverlayLayer.GetLayer(Viewport).Open(FBody,ViewportRect(FCollapsedButton));
  FPopup.OnClose:=@PopupClosed;
end;

procedure TRibbonGroup.PopupClosed(Sender: TObject);
begin
  if (Sender=nil) or (csDestroying in ComponentState) then
    Exit;
  FPopup:=nil;
  SetClass(FBody,cRibbonPopupClass,False);
  SetClass(FBody,cRibbonHiddenClass,FLevel>=cRibbonLevelCollapsed);
  FBody.Parent:=Self;
  // The footer comes after the body again.
  FFooter.Parent:=nil;
  FFooter.Parent:=Self;
  DomChanged;
end;

{ TRibbonTabHeader }

class constructor TRibbonTabHeader.InitTypeID;
begin
  FTypeID:=CSSRegistry.AddType(CSSTypeName).Index;
end;

class function TRibbonTabHeader.CSSTypeID: TCSSNumericalID;
begin
  Result:=FTypeID;
end;

class function TRibbonTabHeader.CSSTypeName: TCSSString;
begin
  Result:='ribbontabheader';
end;

class function TRibbonTabHeader.GetCSSTypeStyle: TCSSString;
begin
  Result:=''; // all in cRibbonCSS
end;

procedure TRibbonTabHeader.Click;
begin
  if not Enabled then
    Exit;
  // A double-click is down, up, click, down, dblclick, up, click: this is that last click.
  if FIgnoreClick then
  begin
    FIgnoreClick:=False;
    Exit;
  end;
  FTab.FRibbon.ActiveTab:=FTab;
  if FTab.FRibbon.Collapsed then
    FTab.FRibbon.OpenPanelPopup;
  inherited Click;
end;

procedure TRibbonTabHeader.DoubleClicked(aEvent: TAbstractEvent);
begin
  if aEvent=nil then ;
  FIgnoreClick:=True;
  FTab.FRibbon.Collapsed:=not FTab.FRibbon.Collapsed;
end;

{ TRibbonTab }

constructor TRibbonTab.CreateFor(aRibbon: TRibbon; const aCaption, aContextName: string);
begin
  inherited Create(aRibbon);
  FRibbon:=aRibbon;
  FContextName:=aContextName;
  FGroups:=TFPList.Create;
  FScaler:=TRibbonScaler.Create;
  FLayoutDirty:=True;
  AddCSSClass('ribbon-tab');
  AddCSSClass(cRibbonHiddenClass);
  FHeader:=TRibbonTabHeader.Create(aRibbon);
  FHeader.FTab:=Self;
  FHeader.CanFocus:=False;
  FHeader.AddEventListener(evtDblClick,@FHeader.DoubleClicked);
  Caption:=aCaption;
  FHeader.Parent:=aRibbon.FTabRow;
  Parent:=aRibbon.FPanel;
end;

destructor TRibbonTab.Destroy;
begin
  FreeAndNil(FGroups);
  FreeAndNil(FScaler);
  inherited Destroy;
end;

function TRibbonTab.GetCaption: string;
begin
  Result:=FHeader.Caption;
end;

procedure TRibbonTab.SetCaption(const aValue: string);
begin
  FHeader.Caption:=aValue;
end;

function TRibbonTab.GetGroup(aIndex: Integer): TRibbonGroup;
begin
  Result:=TRibbonGroup(FGroups[aIndex]);
end;

function TRibbonTab.GetGroupCount: Integer;
begin
  Result:=FGroups.Count;
end;

function TRibbonTab.GetTabVisible: Boolean;
begin
  Result:=(FContextName='') or FRibbon.IsContextVisible(FContextName);
end;

function TRibbonTab.ScaleStep: Integer;
begin
  Result:=FScaler.Current;
end;

function TRibbonTab.AddGroup(const aCaption: string): TRibbonGroup;
begin
  Result:=TRibbonGroup.CreateFor(Self,aCaption);
  Result.Parent:=Self;
  FGroups.Add(Result);
  InvalidateLayout;
end;

procedure TRibbonTab.InvalidateLayout;
begin
  FLayoutDirty:=True;
  DomChanged;
end;

procedure TRibbonTab.PrepareLayout;
var
  lDescs: TRibbonGroupDescs;
  i, k: Integer;
begin
  if not FLayoutDirty then
    Exit;
  FLayoutDirty:=False;
  lDescs:=nil;
  SetLength(lDescs,GroupCount);
  for i:=0 to GroupCount-1 do
  begin
    SetLength(lDescs[i].Preferred,Length(Groups[i].FPreferred));
    SetLength(lDescs[i].Minimum,Length(Groups[i].FMinimum));
    for k:=0 to High(Groups[i].FPreferred) do
    begin
      lDescs[i].Preferred[k]:=Groups[i].FPreferred[k];
      lDescs[i].Minimum[k]:=Groups[i].FMinimum[k];
    end;
    lDescs[i].CanCollapse:=Groups[i].CanCollapse;
  end;
  FSteps:=BuildScaleSteps(lDescs);
  FScaler.Reset(Length(FSteps));
  FLevelsDirty:=True;
end;

procedure TRibbonTab.ApplyLevels;
var
  lLevels: TIntegerDynArray;
  i: Integer;
begin
  if not FLevelsDirty then
    Exit;
  FLevelsDirty:=False;
  lLevels:=LevelsAtStep(FSteps,GroupCount,FScaler.Current);
  for i:=0 to GroupCount-1 do
    Groups[i].ApplyLevel(lLevels[i]);
end;

function TRibbonTab.FeedScaler(aAvailable: TFresnelLength): Boolean;
var
  lFirst, lLast: TFresnelRect;
  lWidth: TFresnelLength;
begin
  Result:=False;
  if GroupCount=0 then
    Exit;
  lFirst:=Groups[0].UsedBorderBox;
  lLast:=Groups[GroupCount-1].UsedBorderBox;
  lWidth:=lLast.Right-lFirst.Left;
  if IsNan(lWidth) or IsNan(aAvailable) or (aAvailable<=0) then
    Exit;
  Result:=FScaler.Feed(lWidth,aAvailable);
  if Result then
    FLevelsDirty:=True;
end;

{ TRibbon }

class constructor TRibbon.InitTypeID;
begin
  FTypeID:=CSSRegistry.AddType(CSSTypeName).Index;
end;

constructor TRibbon.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  FTabs:=TFPList.Create;
  FQuickItems:=TFPList.Create;
  FBadges:=TFPList.Create;
  FBadgeOverlays:=TFPList.Create;
  FContextLabels:=TStringList.Create;
  FVisibleContexts:=TStringList.Create;
  FKeyTipKey:='F6';

  FTitleRow:=NewDiv(Self,Self,'ribbon-titlebar');
  FTitleRow.AddCSSClass(cRibbonHiddenClass);
  FQuickAccess:=NewDiv(Self,FTitleRow,'ribbon-quickaccess');
  FContextBar:=NewDiv(Self,FTitleRow,'ribbon-contextbar');

  FStrip:=NewDiv(Self,Self,'ribbon-tabstrip');
  FAppButton:=TRibbonItem.CreateFor(Self);
  FAppButton.Kind:=rikDropdown;
  FAppButton.AddCSSClass('ribbon-appbutton');
  FAppButton.Caption:=rsRibbonApplicationButton;
  FAppButton.Parent:=FStrip;
  FTabRow:=NewDiv(Self,FStrip,'ribbon-tabrow');
  FCollapseButton:=TRibbonItem.CreateFor(Self);
  FCollapseButton.AddCSSClass('ribbon-collapse');
  FCollapseButton.Caption:=cArrowUp;
  FCollapseButton.OnClick:=@CollapseClick;
  FCollapseButton.Parent:=FStrip;

  FPanel:=NewDiv(Self,Self,'ribbon-panel');
end;

destructor TRibbon.Destroy;
begin
  RemoveKeyListeners;
  FreeAndNil(FBadgeOverlays);
  FreeAndNil(FBadges);
  FreeAndNil(FQuickItems);
  FreeAndNil(FTabs);
  FreeAndNil(FContextLabels);
  FreeAndNil(FVisibleContexts);
  inherited Destroy;
end;

class function TRibbon.CSSTypeID: TCSSNumericalID;
begin
  Result:=FTypeID;
end;

class function TRibbon.CSSTypeName: TCSSString;
begin
  Result:='ribbon';
end;

class function TRibbon.GetCSSTypeStyle: TCSSString;
begin
  Result:=cRibbonCSS;
end;

procedure TRibbon.Notification(aComponent: TComponent; aOperation: TOperation);
begin
  inherited Notification(aComponent,aOperation);
  if (aOperation=opRemove) and (aComponent=FKeyViewport) then
    FKeyViewport:=nil;
end;

function TRibbon.Layer: TOverlayLayer;
begin
  Result:=TOverlayLayer.GetLayer(Viewport);
end;

function TRibbon.GetTab(aIndex: Integer): TRibbonTab;
begin
  Result:=TRibbonTab(FTabs[aIndex]);
end;

function TRibbon.GetTabCount: Integer;
begin
  Result:=FTabs.Count;
end;

function TRibbon.GetQuickItem(aIndex: Integer): TRibbonItem;
begin
  Result:=TRibbonItem(FQuickItems[aIndex]);
end;

function TRibbon.GetQuickItemCount: Integer;
begin
  Result:=FQuickItems.Count;
end;

function TRibbon.GetBadge(aIndex: Integer): TLabel;
begin
  Result:=TLabel(FBadges[aIndex]);
end;

function TRibbon.GetBadgeCount: Integer;
begin
  Result:=FBadges.Count;
end;

function TRibbon.GetApplicationMenu: TPopupMenu;
begin
  Result:=FAppButton.DropdownMenu;
end;

procedure TRibbon.SetApplicationMenu(aValue: TPopupMenu);
begin
  FAppButton.DropdownMenu:=aValue;
end;

function TRibbon.GetApplicationCaption: string;
begin
  Result:=FAppButton.Caption;
end;

procedure TRibbon.SetApplicationCaption(const aValue: string);
begin
  FAppButton.Caption:=aValue;
end;

function TRibbon.GetPanelOpen: Boolean;
begin
  Result:=FPanelPopup<>nil;
end;

function TRibbon.GetKeyTipsActive: Boolean;
begin
  Result:=FKeyState<>ktsOff;
end;

function TRibbon.AddTab(const aCaption: string): TRibbonTab;
begin
  Result:=TRibbonTab.CreateFor(Self,aCaption,'');
  FTabs.Add(Result);
  EnsureFirstActive;
end;

function TRibbon.AddContextualTab(const aContextName, aCaption: string): TRibbonTab;
var
  lLabel: TLabel;
begin
  Result:=TRibbonTab.CreateFor(Self,aCaption,aContextName);
  FTabs.Add(Result);
  Result.Header.AddCSSClass(cRibbonContextualClass);
  SetClass(Result.Header,cRibbonHiddenClass,not IsContextVisible(aContextName));
  if FContextLabels.IndexOf(aContextName)<0 then
  begin
    lLabel:=TLabel.Create(Self);
    lLabel.AddCSSClass('ribbon-context-label');
    lLabel.Caption:=aContextName;
    SetClass(lLabel,cRibbonHiddenClass,not IsContextVisible(aContextName));
    lLabel.Parent:=FContextBar;
    FContextLabels.AddObject(aContextName,lLabel);
  end;
  EnsureFirstActive;
end;

function TRibbon.IsContextVisible(const aContextName: string): Boolean;
begin
  Result:=FVisibleContexts.IndexOf(aContextName)>=0;
end;

procedure TRibbon.SetContextVisible(const aContextName: string; aVisible: Boolean);
var
  i: Integer;
begin
  if aVisible=IsContextVisible(aContextName) then
    Exit;
  if aVisible then
    FVisibleContexts.Add(aContextName)
  else
    FVisibleContexts.Delete(FVisibleContexts.IndexOf(aContextName));
  for i:=0 to TabCount-1 do
    if Tabs[i].ContextName=aContextName then
      SetClass(Tabs[i].Header,cRibbonHiddenClass,not aVisible);
  i:=FContextLabels.IndexOf(aContextName);
  if i>=0 then
    SetClass(TLabel(FContextLabels.Objects[i]),cRibbonHiddenClass,not aVisible);
  if (FActiveTab<>nil) and not FActiveTab.TabVisible then
  begin
    FActiveTab:=nil;
    EnsureFirstActive;
  end;
  UpdateTitleRow;
  DomChanged;
end;

procedure TRibbon.EnsureFirstActive;
var
  i: Integer;
begin
  if FActiveTab<>nil then
    Exit;
  for i:=0 to TabCount-1 do
    if Tabs[i].TabVisible then
    begin
      SetActiveTab(Tabs[i]);
      Exit;
    end;
end;

procedure TRibbon.SetActiveTab(aValue: TRibbonTab);
var
  i: Integer;
begin
  if (aValue<>nil) and not aValue.TabVisible then
    Exit;
  if aValue=FActiveTab then
    Exit;
  FActiveTab:=aValue;
  for i:=0 to TabCount-1 do
  begin
    SetClass(Tabs[i],cRibbonHiddenClass,Tabs[i]<>aValue);
    SetClass(Tabs[i].Header,cRibbonActiveClass,Tabs[i]=aValue);
  end;
  DomChanged;
  if Assigned(FOnTabChanged) then
    FOnTabChanged(Self);
end;

function TRibbon.AddQuickButton(const aCaption: string; aOnClick: TFresnelEventHandler): TRibbonItem;
begin
  Result:=TRibbonItem.CreateFor(Self);
  Result.Caption:=aCaption;
  Result.SetDisplaySize(risSmall);
  if aOnClick<>nil then
    Result.OnClick:=aOnClick;
  Result.Parent:=FQuickAccess;
  FQuickItems.Add(Result);
  UpdateTitleRow;
end;

procedure TRibbon.UpdateTitleRow;
begin
  SetClass(FTitleRow,cRibbonHiddenClass,(FQuickItems.Count=0) and (FVisibleContexts.Count=0));
end;

procedure TRibbon.UpdatePanelVisibility;
begin
  SetClass(FPanel,cRibbonHiddenClass,FCollapsed and (FPanelPopup=nil));
  if FCollapsed then
    FCollapseButton.Caption:=cArrowDown
  else
    FCollapseButton.Caption:=cArrowUp;
end;

procedure TRibbon.SetCollapsed(aValue: Boolean);
begin
  if FCollapsed=aValue then
    Exit;
  FCollapsed:=aValue;
  if (FPanelPopup<>nil) and (Viewport<>nil) then
    Layer.Close(FPanelPopup);
  UpdatePanelVisibility;
  DomChanged;
end;

procedure TRibbon.CollapseClick(aEvent: TAbstractEvent);
begin
  if aEvent=nil then ;
  Collapsed:=not Collapsed;
end;

procedure TRibbon.OpenPanelPopup;
var
  lStrip: TFresnelRect;
begin
  if (FPanelPopup<>nil) or (Viewport=nil) then
    Exit;
  lStrip:=ViewportRect(FStrip);
  FPanel.Style:='width: '+IntToStr(Round(lStrip.Width))+'px;';
  SetClass(FPanel,cRibbonHiddenClass,False);
  SetClass(FPanel,cRibbonPopupClass,True);
  FPanelPopup:=Layer.Open(FPanel,lStrip);
  FPanelPopup.OnClose:=@PanelPopupClosed;
end;

procedure TRibbon.PanelPopupClosed(Sender: TObject);
begin
  if (Sender=nil) or (csDestroying in ComponentState) then
    Exit;
  FPanelPopup:=nil;
  FPanel.Style:='';
  SetClass(FPanel,cRibbonPopupClass,False);
  FPanel.Parent:=Self;
  UpdatePanelVisibility;
  DomChanged;
end;

procedure TRibbon.ItemActivated;
begin
  HideKeyTips;
  if (Viewport<>nil) and (Layer.OverlayCount>0) then
    Layer.CloseAll;
end;

function TRibbon.CheckScale: Boolean;
const
  cPanelPadding = 8; // left and right padding of .ribbon-panel
var
  lAvailable: TFresnelLength;
begin
  Result:=False;
  if (FActiveTab=nil) or (FCollapsed and (FPanelPopup=nil)) then
    Exit;
  // The ribbon itself: its panel can stay wider than the ribbon while its content does.
  if FPanelPopup<>nil then
    lAvailable:=FPanel.UsedBorderBox.Width
  else
    lAvailable:=UsedBorderBox.Width;
  if IsNan(lAvailable) then
    Exit;
  Result:=FActiveTab.FeedScaler(lAvailable-cPanelPadding);
end;

procedure TRibbon.UpdateManagedNodes;
var
  i: Integer;
begin
  inherited UpdateManagedNodes;
  if csDestroying in ComponentState then
    Exit;
  for i:=0 to QuickItemCount-1 do
    QuickItems[i].SetDisplaySize(risSmall);
  for i:=0 to TabCount-1 do
  begin
    Tabs[i].PrepareLayout;
    Tabs[i].ApplyLevels;
  end;
  if FKeyState=ktsShowBadges then
  begin
    FKeyState:=ktsOn;
    ShowBadges;
  end;
end;

procedure TRibbon.ComputeCSSLayoutFinished;
begin
  inherited ComputeCSSLayoutFinished;
  InstallKeyListeners;
  if CheckScale then
    DomChanged
  else if FKeyState=ktsWaitForLayout then
  begin
    // Geometry is final now; the badges are mounted before the next layout.
    FKeyState:=ktsShowBadges;
    DomChanged;
  end;
end;

{ TRibbon - KeyTips }

procedure TRibbon.InstallKeyListeners;
begin
  if (FKeyViewport<>nil) or (Viewport=nil) then
    Exit;
  FKeyViewport:=Viewport;
  FKeyViewport.FreeNotification(Self);
  FKeyViewport.AddEventListener(evtKeyDown,@HandleKeyDown);
  FKeyViewport.AddEventListener(evtKeyUp,@HandleKeyUp);
  FKeyViewport.AddEventListener(evtMouseDown,@HandleMouseDown);
end;

procedure TRibbon.RemoveKeyListeners;
begin
  if FKeyViewport=nil then
    Exit;
  if not (csDestroying in FKeyViewport.ComponentState) then
  begin
    FKeyViewport.RemoveEventListener(evtKeyDown,@HandleKeyDown);
    FKeyViewport.RemoveEventListener(evtKeyUp,@HandleKeyUp);
    FKeyViewport.RemoveEventListener(evtMouseDown,@HandleMouseDown);
    FKeyViewport.RemoveFreeNotification(Self);
  end;
  FKeyViewport:=nil;
end;

procedure TRibbon.HandleKeyDown(aEvent: TAbstractEvent);
var
  lEvent: TFresnelKeyEvent;
  lKey: string;
begin
  if not (aEvent is TFresnelKeyEvent) then
    Exit;
  lEvent:=TFresnelKeyEvent(aEvent);
  lKey:=lEvent.Key;
  if not KeyTipsActive then
  begin
    FAltArmed:=lKey='Alt';
    if SameText(lKey,FKeyTipKey) then
    begin
      ShowKeyTips;
      lEvent.PreventDefault;
    end;
    Exit;
  end;
  if lKey='Escape' then
  begin
    if FKeyLevel>1 then
      EnterKeyLevel(1)
    else
      HideKeyTips;
    lEvent.PreventDefault;
  end
  else if SameText(lKey,FKeyTipKey) or (lKey='Alt') then
  begin
    HideKeyTips;
    lEvent.PreventDefault;
  end
  else if Length(lKey)=1 then
  begin
    PressKeyTip(lKey);
    lEvent.PreventDefault;
  end;
end;

procedure TRibbon.HandleKeyUp(aEvent: TAbstractEvent);
begin
  if (aEvent is TFresnelKeyEvent) and FAltArmed and (TFresnelKeyEvent(aEvent).Key='Alt') then
  begin
    FAltArmed:=False;
    ShowKeyTips;
    TFresnelKeyEvent(aEvent).PreventDefault;
  end;
end;

procedure TRibbon.HandleMouseDown(aEvent: TAbstractEvent);
begin
  if aEvent=nil then ;
  HideKeyTips;
end;

procedure TRibbon.ShowKeyTips;
begin
  EnterKeyLevel(1);
end;

procedure TRibbon.HideKeyTips;
begin
  if FKeyState=ktsOff then
    Exit;
  FKeyState:=ktsOff;
  FKeyLevel:=0;
  FKeyTyped:='';
  FKeyElements:=nil;
  FKeyTips:=nil;
  RemoveBadges;
  DomChanged;
end;

procedure TRibbon.AddKeyElement(aElement: TFresnelElement);
var
  lCount: Integer;
begin
  if (aElement is TCustomButton) and not TCustomButton(aElement).Enabled then
    Exit;
  lCount:=Length(FKeyElements);
  SetLength(FKeyElements,lCount+1);
  FKeyElements[lCount]:=aElement;
end;

procedure TRibbon.CollectKeyLevel(aLevel: Integer);
var
  i, g, k: Integer;
  lGroup: TRibbonGroup;
  lElement: TFresnelElement;
begin
  FKeyElements:=nil;
  if aLevel=1 then
  begin
    AddKeyElement(FAppButton);
    for i:=0 to QuickItemCount-1 do
      AddKeyElement(QuickItems[i]);
    for i:=0 to TabCount-1 do
      if Tabs[i].TabVisible then
        AddKeyElement(Tabs[i].Header);
  end
  else if FActiveTab<>nil then
    for g:=0 to FActiveTab.GroupCount-1 do
    begin
      lGroup:=FActiveTab.Groups[g];
      if lGroup.Collapsed then
        AddKeyElement(lGroup.CollapsedButton)
      else
        for k:=0 to lGroup.ItemCount-1 do
        begin
          lElement:=lGroup.Items[k];
          if lElement is TRibbonItem then
            AddKeyElement(lElement)
          else if lElement is TRibbonSplitButton then
            AddKeyElement(TRibbonSplitButton(lElement).Main)
          else if lElement is TRibbonGallery then
            AddKeyElement(TRibbonGallery(lElement).MoreButton);
        end;
    end;
end;

procedure TRibbon.EnterKeyLevel(aLevel: Integer);
var
  lCaptions, lPresets: TStringDynArray;
  i: Integer;
  lElement: TFresnelElement;
begin
  RemoveBadges;
  CollectKeyLevel(aLevel);
  FKeyLevel:=aLevel;
  FKeyTyped:='';
  lCaptions:=nil;
  lPresets:=nil;
  SetLength(lCaptions,Length(FKeyElements));
  SetLength(lPresets,Length(FKeyElements));
  for i:=0 to High(FKeyElements) do
  begin
    lElement:=FKeyElements[i];
    if lElement is TRibbonItem then
    begin
      lCaptions[i]:=TRibbonItem(lElement).Caption;
      lPresets[i]:=TRibbonItem(lElement).KeyTip;
    end
    else if lElement is TRibbonTabHeader then
    begin
      lCaptions[i]:=TRibbonTabHeader(lElement).Caption;
      lPresets[i]:=TRibbonTabHeader(lElement).KeyTip;
    end;
  end;
  FKeyTips:=AssignKeyTips(lCaptions,lPresets);
  FKeyState:=ktsWaitForLayout;
  DomChanged;
end;

procedure TRibbon.ShowBadges;
var
  i: Integer;
  lBadge: TLabel;
  lBox: TFresnelRect;
  lPoint: TFresnelPoint;
begin
  if Viewport=nil then
    Exit;
  RemoveBadges;
  for i:=0 to High(FKeyElements) do
  begin
    lBadge:=TLabel.Create(Self);
    lBadge.AddCSSClass(cRibbonPopupClass);
    lBadge.AddCSSClass(cRibbonKeyTipClass);
    lBadge.Caption:=FKeyTips[i];
    FBadges.Add(lBadge);
    lBox:=FKeyElements[i].UsedBorderBox;
    lPoint:=Viewport.PaddingBoxToViewport(FKeyElements[i],lBox.Width/2-6,lBox.Height-10);
    FBadgeOverlays.Add(Layer.Open(lBadge,lPoint,[]));
  end;
end;

procedure TRibbon.RemoveBadges;
var
  i: Integer;
begin
  if (Viewport<>nil) and not (csDestroying in ComponentState) then
    for i:=FBadgeOverlays.Count-1 downto 0 do
      TOverlay(FBadgeOverlays[i]).Close;
  FBadgeOverlays.Clear;
  if not (csDestroying in ComponentState) then
    for i:=0 to FBadges.Count-1 do
      TLabel(FBadges[i]).Free;
  FBadges.Clear;
end;

procedure TRibbon.ActivateKeyElement(aElement: TFresnelElement);
begin
  if aElement is TRibbonTabHeader then
  begin
    ActiveTab:=TRibbonTabHeader(aElement).Tab;
    if Collapsed then
      OpenPanelPopup;
    EnterKeyLevel(2);
  end
  else if aElement is TRibbonItem then
  begin
    HideKeyTips;
    TRibbonItem(aElement).Click;
  end;
end;

function TRibbon.PressKeyTip(const aKey: string): Boolean;
var
  lIndex: Integer;
begin
  Result:=False;
  if not KeyTipsActive then
    Exit;
  FKeyTyped:=FKeyTyped+UpperCase(aKey);
  case MatchKeyTip(FKeyTips,FKeyTyped,lIndex) of
    ktmExact:
      begin
        Result:=True;
        ActivateKeyElement(FKeyElements[lIndex]);
      end;
    ktmPartial:
      Result:=True;
    ktmNone:
      FKeyTyped:='';
  end;
end;

end.
