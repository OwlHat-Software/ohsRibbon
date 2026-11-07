program ohsribbontests;

{$mode objfpc}{$H+}

uses
  Classes, consoletestrunner, Fresnel.CursorTimer, Fresnel.AnimationTimer,
  utest.model.sizing, utest.model.keytips, utest.ui.ribbon;

var
  Application: TTestRunner;
begin
  DefaultFormat:=fPlain;
  DefaultRunAllTests:=True;
  Application:=TTestRunner.Create(nil);
  Application.Initialize;
  Application.Run;
  Application.Free;
end.
