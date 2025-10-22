#Requires AutoHotkey v2.0
#SingleInstance Force

; ======================================================================
; --- Global Variables ---
; ======================================================================
global overlay := ""
global overlayTimeout := 10000 ; 10 seconds
global g_hBrush := 0 ; Global handle for our button color brush
global g_buttons := [] ; Array to keep track of buttons

; ======================================================================
; --- Event Handling & Messages ---
; ======================================================================
OnExit(Cleanup) ; Ensure Cleanup always runs when the script exits
OnMessage(0x135, CustomizeButtonColor) ; Set up global handler for button color

; ======================================================================
; --- Hotkey Definition ---
; ======================================================================
Hotkey("F12", ShowOverlay)

; ======================================================================
; --- Main Function to Show the Menu ---
; ======================================================================
ShowOverlay(*) {
    global overlay, overlayTimeout, g_hBrush, g_buttons

    if IsObject(overlay) {
        overlay.Destroy()
        return
    }

    g_buttons := [] ; Clear the button list

    overlay := Gui("+AlwaysOnTop -Caption +ToolWindow +LastFound")
    overlay.BackColor := "202020"
    overlay.SetFont("s12", "Segoe UI")

    if !g_hBrush {
        g_hBrush := DllCall("CreateSolidBrush", "UInt", 0x330000, "Ptr") ; Dark blue
    }

    overlay.OnEvent("Close", Cleanup)

    overlay.Add("Text", "Center w280 h30 cWhite", "🎮 Stream Control")
    
    AddButton("Close Menu", (*) => DestroyOverlay())
    AddButton("Close Active Window (Alt+F4)", CloseWindow)
    AddButton("End Stream", EndStream)
    AddButton("Launch Playnite", StartPlaynite)
    AddButton("Move Mouse Cursor", MoveCursorAway)
    AddButton("Switch Window (Alt+Tab)", AltTab)
    AddButton("Restart PC", RebootPC)
    AddButton("Shut Down PC", ShutdownPC)

    x_pos := (A_ScreenWidth - 300) // 2
    overlay.Show("x" . x_pos . " y20") 
    
    MouseMove(A_ScreenWidth, 0, 0)

    SetTimer(DestroyOverlay, -overlayTimeout)
}

; --- Function to Clean Up Resources ---
Cleanup(*) {
    global g_hBrush
    if g_hBrush {
        DllCall("DeleteObject", "Ptr", g_hBrush)
        g_hBrush := 0
    }
    ExitApp()
}

; --- Function to Destroy the Menu ---
DestroyOverlay(*) {
    global overlay
    if IsObject(overlay) {
        overlay.Destroy()
        overlay := ""
    }
}

; ======================================================================
; --- Helper Functions ---
; ======================================================================

; --- Handles Button Coloring ---
CustomizeButtonColor(wParam, lParam, msg, hwnd) {
    global overlay, g_hBrush
    if !IsObject(overlay) || (hwnd != overlay.Hwnd)
        return
    DllCall("SetTextColor", "Ptr", wParam, "UInt", 0xFFFFFF)
    DllCall("SetBkMode", "Ptr", wParam, "Int", 1)
    return g_hBrush
}

; --- Creates Buttons and Adds Them to Our List ---
AddButton(text, callback) {
    global overlay, g_buttons
    btn := overlay.Add("Button", "w280 h40", text)
    btn.OnEvent("Click", callback)
    g_buttons.Push(btn)
}

; ======================================================================
; --- BUTTON FUNCTIONS ---
; ======================================================================

CloseWindow(*) {
    DestroyOverlay()
    ToolTip("Closing window...")
    Sleep(200)
    Send("!{F4}")
    SetTimer(() => ToolTip(""), -2000)
}

EndStream(*) {
    DestroyOverlay()
    ToolTip("Attempting to stop Sunshine session...")
    try {
        RunWait('curl -X POST http://localhost:47990/api/stop', , "Hide")
        ToolTip("Session stopped via API.")
    } catch {
        ToolTip("Failed to stop session via API.")
    }
    SetTimer(() => ToolTip(""), -3000)
}

StartPlaynite(*) {
    DestroyOverlay()
    ToolTip("Launching Playnite Fullscreen...")
    try {
        Run('"C:\Playnite\Playnite.FullscreenApp.exe"')
        SetTimer(() => ToolTip(""), -2000)
    } catch {
        MsgBox("Could not start Playnite from C:\Playnite\Playnite.FullscreenApp.exe", "Error", "IconExclamation")
    }
}

MoveCursorAway(*) {
    DestroyOverlay()
    MouseMove(A_ScreenWidth, 0, 0)
    ToolTip("Mouse cursor moved")
    SetTimer(() => ToolTip(""), -2000)
}

AltTab(*) {
    ToolTip("Alt+Tab...")
    DestroyOverlay()
    Sleep(100)
    Send("{Alt down}{Tab}")
    SetTimer(ReleaseAltKey, -8000)
}

ReleaseAltKey() {
    Send("{Alt up}")
    ToolTip("")
}

RebootPC(*) {
    DestroyOverlay()
    Shutdown(6)
}

ShutdownPC(*) {
    DestroyOverlay()
    Shutdown(5)
}
