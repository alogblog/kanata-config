#SingleInstance Off
Persistent

label := A_Args.Length > 0? A_Args[1] : "NAV"
if (label = "")
    label := "NAV"

; --- GUI 만들기 ---
myGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x08000000", "OSD_" label)
myGui.BackColor := "Black"
myGui.SetFont("s36 bold cYellow", "Consolas")
myGui.Add("Text", "BackgroundTrans", " " label " ")
myGui.Show("AutoSize Center NoActivate NA")

; --- 위치 계산 ---
WinGetPos(&gx, &gy, &gw, &gh, myGui)

centerX := (A_ScreenWidth - gw) // 2
centerY := (A_ScreenHeight - gh) // 2
gap := gh + 12 ; 창 높이만큼 띄우기, 12는 여백

if (label = "CAPS")
    ny := centerY - gap
else if (label = "KEYS")
    ny := centerY + gap
else ; NAV
    ny := centerY

myGui.Move(centerX, ny)
WinSetTransparent(180, myGui)