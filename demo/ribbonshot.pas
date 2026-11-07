unit ribbonshot;

{ Draws a Fresnel form into a PNG file for the scripted checks of the demo. Fresnel's
  own capture is not available in its FPC 3.2 Skia renderer. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FPImage, FPWritePNG, Fresnel.Classes, Fresnel.DOM, Fresnel.Forms
  {$IFDEF FresnelSkia}
  ,
  {$IF FPC_FULLVERSION < 30301}
  Fresnel.SkiaFPC32
  {$ELSE}
  Fresnel.SkiaRenderer, System.Skia
  {$ENDIF}
  {$ENDIF}
  ;

procedure SaveFormToPNG(aForm: TFresnelCustomForm; const aFileName: string);

implementation

{$IFNDEF FresnelSkia}
procedure SaveFormToPNG(aForm: TFresnelCustomForm; const aFileName: string);
begin
  raise Exception.Create('PNG output needs the Skia renderer');
end;
{$ELSE}
procedure SaveFormToPNG(aForm: TFresnelCustomForm; const aFileName: string);
var
  lRenderer: TFresnelSkiaRenderer;
  lWidth, lHeight, x, y, lOffset: Integer;
  lPixels: array of Byte;
  lSurface: ISkSurface;
  lOldCanvas: ISkCanvas;
  lImage: TFPMemoryImage;
  lWriter: TFPWriterPNG;
  lColor: TFPColor;
begin
  if not (aForm.Renderer is TFresnelSkiaRenderer) then
    raise Exception.Create('PNG output needs the Skia renderer');
  lRenderer:=TFresnelSkiaRenderer(aForm.Renderer);
  lWidth:=Round(aForm.Width);
  lHeight:=Round(aForm.Height);
  if (lWidth<=0) or (lHeight<=0) then
    raise Exception.Create('The form has no size yet');
  lPixels:=nil;
  SetLength(lPixels,lWidth*lHeight*4);
  lSurface:=TSkSurface.MakeRasterDirect(TSkImageInfo.Create(lWidth,lHeight),@lPixels[0],lWidth*4);
  lOldCanvas:=lRenderer.Canvas;
  try
    lRenderer.Canvas:=lSurface.Canvas;
    lSurface.Canvas.Clear($FFFFFFFF);
    lRenderer.Draw(aForm);
  finally
    lRenderer.Canvas:=lOldCanvas;
  end;
  lImage:=TFPMemoryImage.Create(lWidth,lHeight);
  lWriter:=TFPWriterPNG.Create;
  try
    lImage.UsePalette:=False;
    for y:=0 to lHeight-1 do
      for x:=0 to lWidth-1 do
      begin
        lOffset:=(y*lWidth+x)*4;
        lColor.Blue:=lPixels[lOffset]*257;
        lColor.Green:=lPixels[lOffset+1]*257;
        lColor.Red:=lPixels[lOffset+2]*257;
        lColor.Alpha:=$FFFF;
        lImage.Colors[x,y]:=lColor;
      end;
    lImage.SaveToFile(aFileName,lWriter);
  finally
    lWriter.Free;
    lImage.Free;
  end;
end;
{$ENDIF}

end.
