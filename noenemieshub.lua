local starterGUI = game:GetService("StarterGui")

starterGUI:SetCore("SendNotification", {
	Title = "NoEnemiesHub",
	Text = "Hook remote executed (visualizer included).",
	Icon = "rbxassetid://135351041318579",
	Duration = 10,
	Button1 = "OK",
})

loadstring(game:HttpGet("https://github.com/Loadstringl/TORT/raw/refs/heads/main/ne_hook.lua?t=" .. os.time()))()
