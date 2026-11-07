{ KeyTip assignment and matching, free of any UI dependency (RB-040, RB-NFR-101). }
unit ohsribbon.model.keytips;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Types;

type
  TKeyTipMatch = (ktmNone, ktmPartial, ktmExact);

// A unique, prefix-free key per caption. A preset that is not empty and not yet
// taken wins. Otherwise: first letter of a word, any letter, a digit, then Z.. + key.
function AssignKeyTips(const aCaptions, aPresets: TStringDynArray): TStringDynArray;
// How aTyped matches aTips. aIndex is the tip on an exact match, otherwise -1.
function MatchKeyTip(const aTips: TStringDynArray; const aTyped: string; out aIndex: Integer): TKeyTipMatch;

implementation

const
  // Never assigned on its own: overflow tips are one or more Z, then one other key.
  cOverflowPrefix = 'Z';
  cOverflowKeys = 'ABCDEFGHIJKLMNOPQRSTUVWXY123456789';

function AssignKeyTips(const aCaptions, aPresets: TStringDynArray): TStringDynArray;
var
  lUsed: TStringDynArray;
  lTips: TStringDynArray;
  lUsedCount, lOverflow: Integer;

  function Taken(const aTip: string): Boolean;
  var
    i: Integer;
  begin
    for i:=0 to lUsedCount-1 do
      if lUsed[i]=aTip then
        Exit(True);
    Result:=False;
  end;

  procedure Take(aIndex: Integer; const aTip: string);
  begin
    lTips[aIndex]:=aTip;
    if lUsedCount>=Length(lUsed) then
      SetLength(lUsed,lUsedCount+16);
    lUsed[lUsedCount]:=aTip;
    Inc(lUsedCount);
  end;

  function TryKey(aIndex: Integer; aKey: Char): Boolean;
  begin
    Result:=(aKey in ['A'..'Z','0'..'9']) and (aKey<>cOverflowPrefix) and not Taken(aKey);
    if Result then
      Take(aIndex,aKey);
  end;

  procedure AssignFromCaption(aIndex: Integer);
  var
    lCaption: string;
    k: Integer;
  begin
    lCaption:=UpperCase(aCaptions[aIndex]);
    for k:=1 to Length(lCaption) do
      if ((k=1) or (lCaption[k-1]=' ')) and TryKey(aIndex,lCaption[k]) then
        Exit;
    for k:=1 to Length(lCaption) do
      if TryKey(aIndex,lCaption[k]) then
        Exit;
    for k:=1 to 9 do
      if TryKey(aIndex,Chr(Ord('0')+k)) then
        Exit;
    Take(aIndex,StringOfChar(cOverflowPrefix,lOverflow div Length(cOverflowKeys)+1)
      +cOverflowKeys[lOverflow mod Length(cOverflowKeys)+1]);
    Inc(lOverflow);
  end;

var
  i: Integer;
  lPreset: string;
begin
  lTips:=nil;
  lUsed:=nil;
  lUsedCount:=0;
  lOverflow:=0;
  SetLength(lTips,Length(aCaptions));
  for i:=0 to High(aCaptions) do
    if i<=High(aPresets) then
    begin
      lPreset:=UpperCase(aPresets[i]);
      if (lPreset<>'') and not Taken(lPreset) then
        Take(i,lPreset);
    end;
  for i:=0 to High(aCaptions) do
    if lTips[i]='' then
      AssignFromCaption(i);
  Result:=lTips;
end;

function MatchKeyTip(const aTips: TStringDynArray; const aTyped: string; out aIndex: Integer): TKeyTipMatch;
var
  i: Integer;
  lTyped: string;
begin
  aIndex:=-1;
  Result:=ktmNone;
  lTyped:=UpperCase(aTyped);
  if lTyped='' then
    Exit;
  for i:=0 to High(aTips) do
    if aTips[i]=lTyped then
    begin
      aIndex:=i;
      Exit(ktmExact);
    end
    else if Copy(aTips[i],1,Length(lTyped))=lTyped then
      Result:=ktmPartial;
end;

end.
