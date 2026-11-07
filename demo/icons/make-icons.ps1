# Draws the demo icons: original, simple shapes on a tile. Run from this folder.
Add-Type -AssemblyName System.Drawing

function New-Icon([string]$Name, [string]$Tile, [scriptblock]$Draw) {
  $bmp = New-Object System.Drawing.Bitmap 32, 32
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = 'AntiAlias'
  $g.Clear([System.Drawing.Color]::Transparent)
  $brush = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml($Tile))
  $g.FillRectangle($brush, 2, 2, 28, 28)
  $white = [System.Drawing.Brushes]::White
  $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::White), 2.5
  & $Draw $g $white $pen
  $bmp.Save((Join-Path $PSScriptRoot "$Name.png"), [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bmp.Dispose()
}

New-Icon 'paste'   '#33658a' { param($g,$w,$p) $g.FillRectangle($w,9,8,14,17); $g.DrawLine($p,12,6,20,6) }
New-Icon 'cut'     '#33658a' { param($g,$w,$p) $g.DrawLine($p,9,7,23,25); $g.DrawLine($p,23,7,9,25) }
New-Icon 'copy'    '#33658a' { param($g,$w,$p) $g.DrawRectangle($p,8,7,11,13); $g.FillRectangle($w,13,12,11,13) }
New-Icon 'bold'    '#55606b' { param($g,$w,$p) $g.FillRectangle($w,11,7,4,18); $g.FillRectangle($w,11,7,10,4); $g.FillRectangle($w,11,14,10,4); $g.FillRectangle($w,11,21,10,4) }
New-Icon 'italic'  '#55606b' { param($g,$w,$p) $g.DrawLine($p,19,7,13,25); $g.DrawLine($p,14,7,23,7); $g.DrawLine($p,9,25,18,25) }
New-Icon 'under'   '#55606b' { param($g,$w,$p) $g.DrawArc($p,10,3,12,18,0,180); $g.DrawLine($p,8,26,24,26) }
New-Icon 'left'    '#55606b' { param($g,$w,$p) foreach ($y in 9,14,19,24) { $g.DrawLine($p,7,$y,$(if ($y%2) {25} else {18}),$y) } }
New-Icon 'center'  '#55606b' { param($g,$w,$p) foreach ($y in 9,14,19,24) { $i = $(if ($y%2) {0} else {4}); $g.DrawLine($p,7+$i,$y,25-$i,$y) } }
New-Icon 'picture' '#3d7a5a' { param($g,$w,$p) $g.DrawRectangle($p,6,8,20,16); $g.FillEllipse($w,10,11,5,5); $g.FillPolygon($w,@((New-Object Drawing.Point 8,23),(New-Object Drawing.Point 15,16),(New-Object Drawing.Point 19,20),(New-Object Drawing.Point 21,18),(New-Object Drawing.Point 25,23))) }
New-Icon 'table'   '#3d7a5a' { param($g,$w,$p) $g.DrawRectangle($p,6,7,20,18); $g.DrawLine($p,6,13,26,13); $g.DrawLine($p,6,19,26,19); $g.DrawLine($p,16,7,16,25) }
New-Icon 'shape'   '#3d7a5a' { param($g,$w,$p) $g.FillEllipse($w,7,7,13,13); $g.DrawRectangle($p,14,14,11,11) }
New-Icon 'style1'  '#8a5a33' { param($g,$w,$p) $g.FillRectangle($w,7,8,18,4); $g.FillRectangle($w,7,15,12,3); $g.FillRectangle($w,7,21,15,3) }
New-Icon 'style2'  '#8a5a33' { param($g,$w,$p) $g.FillEllipse($w,8,8,16,16) }
New-Icon 'style3'  '#8a5a33' { param($g,$w,$p) $g.DrawRectangle($p,8,8,16,16) }
New-Icon 'crop'    '#8a5a33' { param($g,$w,$p) $g.DrawLine($p,11,5,11,22); $g.DrawLine($p,6,10,22,10); $g.DrawLine($p,21,10,21,27); $g.DrawLine($p,11,22,27,22) }
New-Icon 'save'    '#55606b' { param($g,$w,$p) $g.FillRectangle($w,7,7,18,18); $g.DrawLine($p,12,10,20,10) }
New-Icon 'undo'    '#55606b' { param($g,$w,$p) $g.DrawArc($p,9,9,15,14,-90,250); $g.FillPolygon($w,@((New-Object Drawing.Point 7,10),(New-Object Drawing.Point 15,5),(New-Object Drawing.Point 15,14))) }
New-Icon 'find'    '#55606b' { param($g,$w,$p) $g.DrawEllipse($p,8,7,12,12); $g.DrawLine($p,18,18,25,25) }
New-Icon 'replace' '#55606b' { param($g,$w,$p) $g.DrawLine($p,8,11,24,11); $g.DrawLine($p,18,6,24,11); $g.DrawLine($p,24,21,8,21); $g.DrawLine($p,14,26,8,21) }
