unit utest.model.keytips;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Types, fpcunit, testregistry, ohsribbon.model.keytips;

type
  TTestKeyTips = class(TTestCase)
  private
    function Strs(const aValues: array of string): TStringDynArray;
  published
    procedure TestFirstLetter;
    procedure TestLaterWordBeforeOtherLetters;
    procedure TestPresetWins;
    procedure TestDuplicatePresetFallsBack;
    procedure TestNoLettersGetsDigit;
    procedure TestManyStayUniqueAndPrefixFree;
    procedure TestMatch;
  end;

implementation

function TTestKeyTips.Strs(const aValues: array of string): TStringDynArray;
var
  i: Integer;
begin
  Result:=nil;
  SetLength(Result,Length(aValues));
  for i:=0 to High(aValues) do
    Result[i]:=aValues[i];
end;

procedure TTestKeyTips.TestFirstLetter;
var
  t: TStringDynArray;
begin
  t:=AssignKeyTips(Strs(['Home','Insert']),nil);
  AssertEquals('H',t[0]);
  AssertEquals('I',t[1]);
end;

procedure TTestKeyTips.TestLaterWordBeforeOtherLetters;
var
  t: TStringDynArray;
begin
  t:=AssignKeyTips(Strs(['Paste','Page Width']),nil);
  AssertEquals('P',t[0]);
  AssertEquals('W',t[1]);
end;

procedure TTestKeyTips.TestPresetWins;
var
  t: TStringDynArray;
begin
  t:=AssignKeyTips(Strs(['Home','Help']),Strs(['','h']));
  AssertEquals('H',t[1]);
  AssertEquals('O',t[0]);
end;

procedure TTestKeyTips.TestDuplicatePresetFallsBack;
var
  t: TStringDynArray;
begin
  t:=AssignKeyTips(Strs(['Open','Save']),Strs(['X','X']));
  AssertEquals('X',t[0]);
  AssertEquals('S',t[1]);
end;

procedure TTestKeyTips.TestNoLettersGetsDigit;
var
  t: TStringDynArray;
begin
  t:=AssignKeyTips(Strs(['--']),nil);
  AssertEquals('1',t[0]);
end;

procedure TTestKeyTips.TestManyStayUniqueAndPrefixFree;
var
  c, t: TStringDynArray;
  i, k: Integer;
begin
  c:=nil;
  SetLength(c,120);
  for i:=0 to High(c) do
    c[i]:='Same';
  t:=AssignKeyTips(c,nil);
  for i:=0 to High(t) do
    for k:=0 to High(t) do
      if i<>k then
        AssertFalse(t[i]+' is a prefix of '+t[k],Copy(t[k],1,Length(t[i]))=t[i]);
end;

procedure TTestKeyTips.TestMatch;
var
  t: TStringDynArray;
  i: Integer;
begin
  t:=Strs(['H','ZA','ZB']);
  AssertTrue(MatchKeyTip(t,'h',i)=ktmExact);
  AssertEquals(0,i);
  AssertTrue(MatchKeyTip(t,'Z',i)=ktmPartial);
  AssertEquals(-1,i);
  AssertTrue(MatchKeyTip(t,'ZB',i)=ktmExact);
  AssertEquals(2,i);
  AssertTrue(MatchKeyTip(t,'Q',i)=ktmNone);
end;

initialization
  RegisterTest(TTestKeyTips);
end.
