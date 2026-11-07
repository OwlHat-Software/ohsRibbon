{ Ribbon sizing rules, free of any UI dependency (RB-020, RB-NFR-101). }
unit ohsribbon.model.sizing;

{$mode objfpc}{$H+}

interface

uses
  Types;

const
  // A column of medium or small items holds at most this many rows.
  cRibbonRowsPerColumn = 3;
  // The reduction level at which a group is shown as a single dropdown.
  cRibbonLevelCollapsed = 3;

type
  // Ordered from widest to narrowest.
  TRibbonItemSize = (risLarge, risMedium, risSmall);
  TRibbonItemSizes = array of TRibbonItemSize;

  TRibbonGroupDesc = record
    Preferred: TRibbonItemSizes;
    Minimum: TRibbonItemSizes;
    CanCollapse: Boolean;
  end;
  TRibbonGroupDescs = array of TRibbonGroupDesc;

  // One reduction: Group goes to Level.
  TRibbonScaleStep = record
    Group: Integer;
    Level: Integer;
  end;
  TRibbonScaleSteps = array of TRibbonScaleStep;

  { TRibbonScaler - finds the first step at which the groups fit, from measured
    widths. A width is remembered per step, so widening only returns to a step
    known to fit and the search cannot oscillate. }

  TRibbonScaler = class
  private
    FCurrent: Integer;
    FWidths: array of Double;
    function GetStepCount: Integer;
  public
    // Forget all measurements and go back to no reduction.
    procedure Reset(aStepCount: Integer);
    // Report the measured width at the current step. True when the step changed.
    function Feed(aContentWidth, aAvailableWidth: Double): Boolean;
    property Current: Integer read FCurrent;
    property StepCount: Integer read GetStepCount;
  end;

// The size of an item at aLevel: one size narrower per level, never below aMinimum.
function ReducedSize(aPreferred, aMinimum: TRibbonItemSize; aLevel: Integer): TRibbonItemSize;
// The sizes of all items of a group at aLevel.
function ReducedSizes(const aPreferred, aMinimum: TRibbonItemSizes; aLevel: Integer): TRibbonItemSizes;
// The column index per item: a large item has its own column, other items stack.
function PackColumns(const aSizes: TRibbonItemSizes): TIntegerDynArray;
// All useful reductions: per level, from the last group to the first.
function BuildScaleSteps(const aGroups: TRibbonGroupDescs): TRibbonScaleSteps;
// The level of each group after the first aStepCount steps.
function LevelsAtStep(const aSteps: TRibbonScaleSteps; aGroupCount, aStepCount: Integer): TIntegerDynArray;

implementation

function ReducedSize(aPreferred, aMinimum: TRibbonItemSize; aLevel: Integer): TRibbonItemSize;
var
  lSize, lMinimum: Integer;
begin
  lMinimum:=Ord(aMinimum);
  if lMinimum<Ord(aPreferred) then
    lMinimum:=Ord(aPreferred);
  lSize:=Ord(aPreferred)+aLevel;
  if lSize>lMinimum then
    lSize:=lMinimum;
  Result:=TRibbonItemSize(lSize);
end;

function ReducedSizes(const aPreferred, aMinimum: TRibbonItemSizes; aLevel: Integer): TRibbonItemSizes;
var
  i: Integer;
begin
  Result:=nil;
  SetLength(Result,Length(aPreferred));
  for i:=0 to High(aPreferred) do
    Result[i]:=ReducedSize(aPreferred[i],aMinimum[i],aLevel);
end;

function PackColumns(const aSizes: TRibbonItemSizes): TIntegerDynArray;
var
  i, lColumn, lRows: Integer;
begin
  Result:=nil;
  SetLength(Result,Length(aSizes));
  lColumn:=-1;
  lRows:=cRibbonRowsPerColumn; // forces a new column for the first stacked item
  for i:=0 to High(aSizes) do
    if aSizes[i]=risLarge then
    begin
      Inc(lColumn);
      Result[i]:=lColumn;
      lRows:=cRibbonRowsPerColumn;
    end
    else
    begin
      if lRows>=cRibbonRowsPerColumn then
      begin
        Inc(lColumn);
        lRows:=0;
      end;
      Result[i]:=lColumn;
      Inc(lRows);
    end;
end;

function BuildScaleSteps(const aGroups: TRibbonGroupDescs): TRibbonScaleSteps;

  function LevelChangesGroup(const aGroup: TRibbonGroupDesc; aLevel: Integer): Boolean;
  var
    i: Integer;
  begin
    for i:=0 to High(aGroup.Preferred) do
      if ReducedSize(aGroup.Preferred[i],aGroup.Minimum[i],aLevel)
        <>ReducedSize(aGroup.Preferred[i],aGroup.Minimum[i],aLevel-1) then
        Exit(True);
    Result:=False;
  end;

var
  lLevel, lGroup, lCount: Integer;
begin
  Result:=nil;
  lCount:=0;
  for lLevel:=1 to cRibbonLevelCollapsed do
    for lGroup:=High(aGroups) downto 0 do
    begin
      if lLevel=cRibbonLevelCollapsed then
      begin
        if not aGroups[lGroup].CanCollapse then
          Continue;
      end
      else if not LevelChangesGroup(aGroups[lGroup],lLevel) then
        Continue;
      SetLength(Result,lCount+1);
      Result[lCount].Group:=lGroup;
      Result[lCount].Level:=lLevel;
      Inc(lCount);
    end;
end;

function LevelsAtStep(const aSteps: TRibbonScaleSteps; aGroupCount, aStepCount: Integer): TIntegerDynArray;
var
  i: Integer;
begin
  Result:=nil;
  SetLength(Result,aGroupCount);
  for i:=0 to aGroupCount-1 do
    Result[i]:=0;
  for i:=0 to aStepCount-1 do
    if (i<=High(aSteps)) and (aSteps[i].Group<aGroupCount) then
      Result[aSteps[i].Group]:=aSteps[i].Level;
end;

{ TRibbonScaler }

function TRibbonScaler.GetStepCount: Integer;
begin
  Result:=Length(FWidths)-1;
end;

procedure TRibbonScaler.Reset(aStepCount: Integer);
var
  i: Integer;
begin
  SetLength(FWidths,aStepCount+1);
  for i:=0 to High(FWidths) do
    FWidths[i]:=-1;
  FCurrent:=0;
end;

function TRibbonScaler.Feed(aContentWidth, aAvailableWidth: Double): Boolean;
begin
  Result:=False;
  if Length(FWidths)=0 then
    Exit;
  FWidths[FCurrent]:=aContentWidth;
  if (aContentWidth>aAvailableWidth) and (FCurrent<StepCount) then
  begin
    Inc(FCurrent);
    Result:=True;
  end
  else if (FCurrent>0) and (FWidths[FCurrent-1]>=0) and (FWidths[FCurrent-1]<=aAvailableWidth) then
  begin
    Dec(FCurrent);
    Result:=True;
  end;
end;

end.
