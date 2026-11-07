unit utest.model.sizing;

{$mode objfpc}{$H+}

interface

uses
  Types, fpcunit, testregistry, ohsribbon.model.sizing;

type
  TTestSizing = class(TTestCase)
  private
    function Sizes(const aValues: array of TRibbonItemSize): TRibbonItemSizes;
    function Group(const aPreferred, aMinimum: array of TRibbonItemSize; aCanCollapse: Boolean): TRibbonGroupDesc;
    function Groups(const aOne: TRibbonGroupDesc): TRibbonGroupDescs;
    function Groups(const aOne, aTwo: TRibbonGroupDesc): TRibbonGroupDescs;
  published
    procedure TestReducedSizeStepsDown;
    procedure TestReducedSizeStopsAtMinimum;
    procedure TestPackLargeGetsOwnColumn;
    procedure TestPackStacksThree;
    procedure TestPackLargeInterruptsStack;
    procedure TestStepsGoFromLastGroup;
    procedure TestStepsSkipUselessLevels;
    procedure TestStepsRespectCanCollapse;
    procedure TestLevelsAtStep;
    procedure TestScalerReducesUntilFit;
    procedure TestScalerStopsAtLastStep;
    procedure TestScalerGrowsBack;
    procedure TestScalerDoesNotOscillate;
    procedure TestScalerResetForgets;
  end;

implementation

function TTestSizing.Sizes(const aValues: array of TRibbonItemSize): TRibbonItemSizes;
var
  i: Integer;
begin
  Result:=nil;
  SetLength(Result,Length(aValues));
  for i:=0 to High(aValues) do
    Result[i]:=aValues[i];
end;

function TTestSizing.Group(const aPreferred, aMinimum: array of TRibbonItemSize; aCanCollapse: Boolean): TRibbonGroupDesc;
begin
  Result.Preferred:=Sizes(aPreferred);
  Result.Minimum:=Sizes(aMinimum);
  Result.CanCollapse:=aCanCollapse;
end;

function TTestSizing.Groups(const aOne: TRibbonGroupDesc): TRibbonGroupDescs;
begin
  Result:=nil;
  SetLength(Result,1);
  Result[0]:=aOne;
end;

function TTestSizing.Groups(const aOne, aTwo: TRibbonGroupDesc): TRibbonGroupDescs;
begin
  Result:=nil;
  SetLength(Result,2);
  Result[0]:=aOne;
  Result[1]:=aTwo;
end;

procedure TTestSizing.TestReducedSizeStepsDown;
begin
  AssertTrue(ReducedSize(risLarge,risSmall,0)=risLarge);
  AssertTrue(ReducedSize(risLarge,risSmall,1)=risMedium);
  AssertTrue(ReducedSize(risLarge,risSmall,2)=risSmall);
end;

procedure TTestSizing.TestReducedSizeStopsAtMinimum;
begin
  AssertTrue(ReducedSize(risLarge,risMedium,2)=risMedium);
  AssertTrue(ReducedSize(risLarge,risLarge,3)=risLarge);
  AssertTrue('a minimum wider than preferred is ignored',ReducedSize(risSmall,risLarge,1)=risSmall);
end;

procedure TTestSizing.TestPackLargeGetsOwnColumn;
var
  c: TIntegerDynArray;
begin
  c:=PackColumns(Sizes([risLarge,risLarge]));
  AssertEquals(0,c[0]);
  AssertEquals(1,c[1]);
end;

procedure TTestSizing.TestPackStacksThree;
var
  c: TIntegerDynArray;
begin
  c:=PackColumns(Sizes([risSmall,risMedium,risSmall,risSmall]));
  AssertEquals(0,c[0]);
  AssertEquals(0,c[2]);
  AssertEquals(1,c[3]);
end;

procedure TTestSizing.TestPackLargeInterruptsStack;
var
  c: TIntegerDynArray;
begin
  c:=PackColumns(Sizes([risSmall,risLarge,risSmall]));
  AssertEquals(0,c[0]);
  AssertEquals(1,c[1]);
  AssertEquals(2,c[2]);
end;

procedure TTestSizing.TestStepsGoFromLastGroup;
var
  s: TRibbonScaleSteps;
begin
  s:=BuildScaleSteps(Groups(Group([risLarge],[risSmall],True),Group([risLarge],[risSmall],True)));
  AssertEquals(6,Length(s));
  AssertEquals(1,s[0].Group);
  AssertEquals(1,s[0].Level);
  AssertEquals(0,s[1].Group);
  AssertEquals(1,s[2].Group);
  AssertEquals(2,s[2].Level);
  AssertEquals(cRibbonLevelCollapsed,s[5].Level);
end;

procedure TTestSizing.TestStepsSkipUselessLevels;
var
  s: TRibbonScaleSteps;
begin
  s:=BuildScaleSteps(Groups(Group([risSmall],[risSmall],False)));
  AssertEquals(0,Length(s));
end;

procedure TTestSizing.TestStepsRespectCanCollapse;
var
  s: TRibbonScaleSteps;
begin
  s:=BuildScaleSteps(Groups(Group([risLarge],[risMedium],True)));
  AssertEquals(2,Length(s));
  AssertEquals(1,s[0].Level);
  AssertEquals(cRibbonLevelCollapsed,s[1].Level);
end;

procedure TTestSizing.TestLevelsAtStep;
var
  s: TRibbonScaleSteps;
  l: TIntegerDynArray;
begin
  s:=BuildScaleSteps(Groups(Group([risLarge],[risSmall],True),Group([risLarge],[risSmall],True)));
  l:=LevelsAtStep(s,2,3);
  AssertEquals(1,l[0]);
  AssertEquals(2,l[1]);
end;

procedure TTestSizing.TestScalerReducesUntilFit;
var
  c: TRibbonScaler;
begin
  c:=TRibbonScaler.Create;
  try
    c.Reset(3);
    AssertTrue(c.Feed(500,300));
    AssertTrue(c.Feed(400,300));
    AssertFalse(c.Feed(300,300));
    AssertEquals(2,c.Current);
  finally
    c.Free;
  end;
end;

procedure TTestSizing.TestScalerStopsAtLastStep;
var
  c: TRibbonScaler;
begin
  c:=TRibbonScaler.Create;
  try
    c.Reset(1);
    AssertTrue(c.Feed(500,100));
    AssertFalse(c.Feed(400,100));
    AssertEquals(1,c.Current);
  finally
    c.Free;
  end;
end;

procedure TTestSizing.TestScalerGrowsBack;
var
  c: TRibbonScaler;
begin
  c:=TRibbonScaler.Create;
  try
    c.Reset(2);
    c.Feed(500,300);
    c.Feed(400,300);
    c.Feed(300,300);
    AssertTrue(c.Feed(300,450));
    AssertEquals(1,c.Current);
    AssertFalse('500 is still too wide',c.Feed(400,450));
    AssertEquals(1,c.Current);
  finally
    c.Free;
  end;
end;

procedure TTestSizing.TestScalerDoesNotOscillate;
var
  c: TRibbonScaler;
  i: Integer;
begin
  c:=TRibbonScaler.Create;
  try
    c.Reset(1);
    c.Feed(500,300);
    for i:=1 to 5 do
    begin
      AssertFalse(c.Feed(250,300));
      AssertEquals(1,c.Current);
    end;
  finally
    c.Free;
  end;
end;

procedure TTestSizing.TestScalerResetForgets;
var
  c: TRibbonScaler;
begin
  c:=TRibbonScaler.Create;
  try
    c.Reset(2);
    c.Feed(500,300);
    c.Reset(2);
    AssertEquals(0,c.Current);
    AssertEquals(2,c.StepCount);
  finally
    c.Free;
  end;
end;

initialization
  RegisterTest(TTestSizing);
end.
