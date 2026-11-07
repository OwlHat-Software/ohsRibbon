program ribbondemo;

{$mode objfpc}{$H+}
{$apptype console}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF} // the timers use threads
  Fresnel, // initializes the widgetset
  Fresnel.App, ribbonform;

begin
  FresnelApplication.Initialize;
  FresnelApplication.CreateFormNew(TMainForm,MainForm);
  FresnelApplication.Run;
end.
