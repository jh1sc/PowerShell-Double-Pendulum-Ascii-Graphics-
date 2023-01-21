Add-Type -AssemblyName  Microsoft.VisualBasic, PresentationCore, PresentationFramework, System.Drawing, System.Windows.Forms, WindowsBase, WindowsFormsIntegration, System
$ErrorActionPreference = 'SilentlyContinue'

#Console Setup
[int]$nScreenWidth = 240
[int]$nScreenHeight = 122
[string[]]$screen = @(" " * $nScreenWidth) * $nScreenHeight

$host.UI.RawUI.WindowSize = New-Object Management.Automation.Host.Size(($nScreenWidth), ($nScreenHeight))
$host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size(($nScreenWidth),($nScreenHeight))

Function Pixel 
{
    param
    (
        [Parameter(Mandatory = $true)]
        [int]$x,
        [Parameter(Mandatory = $true)]
        [int]$y,
        [Parameter(Mandatory = $true)]
        [char]$c
    )
    $x = [math]::round($x + $nScreenWidth/2)
    $y = [math]::round($y + $nScreenHeight/2)
    if($x -gt $nScreenWidth -or $y -gt $nScreenHeight -or $x -lt 0 -or $y -lt 0){return}
    $screen[$y] = $screen[$y].Substring(0,$x) + $c + $screen[$y].Substring($x+1)
}

function 2dLine 
{
    param 
    (
        [float]$x1,
        [float]$y1,
        [float]$x2,
        [float]$y2,
        [char]$c
    )
    if( $c -eq $null){$c = GetSlopeChar $x1 $y1 $x2 $y2}
    $x1 = [math]::round($x1)
    $x2 = [math]::round($x2)
    $y1 = [math]::round($y1)
    $y2 = [math]::round($y2)

    #2d line drawer
    $dx = $x2 - $x1
	$dy = $y2 - $y1
	$dx = [math]::abs($dx)
	$dy = [math]::abs($dy)
	$sx = $x1 - $x2
	$sy = $y1 - $y2
	if ($x1 -lt $x2) {$sx = 1} else {$sx = -1}
	if ($y1 -lt $y2) {$sy = 1} else {$sy = -1}
	$err = $dx - $dy
	while ($true) {
        Pixel $x1 $y1 $c
		if (($x1 -eq $x2) -and ($y1 -eq $y2)) {break}
		$e2 = 2 * $err
		if ($e2 -gt -$dy) {$err = $err - $dy; $x1 = $x1 + $sx}
		if ($e2 -lt $dx) {$err = $err + $dx; $y1 = $y1 + $sy}
	}
}
function GetSlopeChar([double] $x1, [double] $y1, [double] $x2, [double] $y2) {
  if ($x2 -lt $x1) {[double]$temp = $x1;$x1 = $x2;$x2 = $temp}
  if ($y2 -lt $y1) {[double]$temp = $y1;$y1 = $y2;$y2 = $temp}
  $angle = [Math]::Atan2(($y2 - $y1), ($x2 - $x1))
  $angle = $angle * 180 / [Math]::PI
  $angle = $angle % 360
  switch ($angle) {
    {$_ -ge 337.5 -or $_ -lt 22.5} {return "-"}
    {$_ -ge 22.5 -and $_ -lt 67.5} {return "/"}
    {$_ -ge 67.5 -and $_ -lt 112.5} {return "|"}
    {$_ -ge 112.5 -and $_ -lt 157.5} {return "\"}
    {$_ -ge 157.5 -and $_ -lt 202.5} {return "-"}
    {$_ -ge 202.5 -and $_ -lt 247.5} {return "/"}
    {$_ -ge 247.5 -and $_ -lt 292.5} {return "|"}
    {$_ -ge 292.5 -and $_ -lt 337.5} {return "\"}
  }
}



function ASKS {
    param ([string]$Char)
    $signature = 
@"
	[DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)]
	public static extern short GetAsyncKeyState(int virtualKeyCode);
"@
$GetAsyncKeyState = Add-Type -MemberDefinition $signature -Name "Win32GetAsyncKeyState" -Namespace Win32Functions -PassThru
return $GetAsyncKeyState::GetAsyncKeyState([System.Windows.Forms.Keys]::$Char)
}

function Get-CursorPosition
{
        $mousepos = [System.Windows.Forms.Cursor]::Position
        $mx = [int]($mousepos.x * ($host.UI.RawUI.BufferSize.Width / [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width))
        $my = [int]($mousepos.y * ($host.UI.RawUI.BufferSize.Height / [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height))
        return $mx, $my
}

function Draw-Circle {
    param (
        [double]$Radius,
        [float]$CenterPositionx,
        [float]$CenterPositiony,
        [int]$Resolution,
        [char]$c
    )
    for ($i = 0; $i -le $Resolution; $i++) {
        $angle = ($i / $Resolution) * (2 * [Math]::PI)
        $x = $CenterPositionx + ($Radius * [Math]::Cos($angle))
        $y = $CenterPositiony + ($Radius * [Math]::Sin($angle))
        Pixel $x $y $c
    }
}


$l1 = 20
$l2 = 25
$m1 = 2
$m2 = 3
$g = -9.81
$dt = 0.021
$theta1 = [Math]::PI / 2
$theta2 = [Math]::PI / 4
$omega1 = 0
$omega2 = 0

cls
while ($true)
{
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $screen = @(" " * $nScreenWidth) * $nScreenHeight


    $dtheta1 = $omega1
    $dtheta2 = $omega2
    $domega1 = ((-$g * ($m1 + $m2) * [Math]::Sin($theta1)) - ($m2 * $g * [Math]::Sin($theta1 - 2 * $theta2)) - (2 * [Math]::Sin($theta1 - $theta2) * $m2 * ( [Math]::Pow($omega2,2) * $l2 + [Math]::Pow($omega1,2) * $l1 * [Math]::Cos($theta1 - $theta2)))) / ($l1 * ($m1 + $m2 - ($m2 * [Math]::Cos(2 * $theta1 - 2 * $theta2))));
    $domega2 = ((2 * [Math]::Sin($theta1 - $theta2)) * ([Math]::Pow($omega1,2) * $l1 * ($m1 + $m2) + $g * ($m1 + $m2) * [Math]::Cos($theta1) + [Math]::Pow($omega2,2) * $l2 * $m2 * [Math]::Cos($theta1 - $theta2))) / ($l2 * ($m1 + $m2 - ($m2 * [Math]::Cos(2 * $theta1 - 2 * $theta2))));
    $theta1 = $theta1 + $dtheta1 * $dt
    $theta2 = $theta2 + $dtheta2 * $dt
    $omega1 = $omega1 + $domega1 * $dt
    $omega2 = $omega2 + $domega2 * $dt
    $x1 = $l1 * [Math]::Sin($theta1);
    $y1 = -$l1 * [Math]::Cos($theta1);
    $x2 = $x1 + $l2 * [Math]::Sin($theta2);
    $y2 = $y1 - $l2 * [Math]::Cos($theta2);

   2dLine 0 0 $x1 $y1 "*"
   2dLine $x1 $y1 $x2 $y2 "*"
   Draw-Circle $m2 $x2 $y2 (36) "#"
   Draw-Circle $m1 $x1 $y1 (36) "#"
   Pixel 0 0 "@"
   Pixel $x1 $y1 "@"
   Pixel $x1 $y1 "@"
   
  
    if (ASKS("W")) {
        $l1 += 0.1
    }
    if (ASKS("S")) {
        $l1 -= 0.1
    }  
    if (ASKS("Q")) {
        $l2 += 0.1
    }
    if (ASKS("A")) {
        $l2 -= 0.1
    }  


    $screen[0] = $screen[0].Substring(0,0) + "TimeStep: $dt" + $screen[0].Substring(0)
    $screen[1] = $screen[1].Substring(0,0) + "Rod1Length: $l1 - Rod2Length: $l2" + $screen[1].Substring(0)
    $sw.Stop()
	$tks = $sw.ElapsedTicks
 	$fps = [math]::Round(10000000/$tks)
    $dt = $fps/770
    [system.console]::title = "Made by: Jh1sc - FPS: $fps"
    [console]::setcursorposition(0,0)
    write-output ($screen -join "`n")
}
