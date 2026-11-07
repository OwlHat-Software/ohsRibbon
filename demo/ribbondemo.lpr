program ribbondemo;

{$mode objfpc}{$H+}
{$apptype console}

uses
  Fresnel, // initializes the widgetset
  Fresnel.App, ribbonform;

begin
  FresnelApplication.Initialize;
  FresnelApplication.CreateFormNew(TMainForm,MainForm);
  FresnelApplication.Run;
end.
