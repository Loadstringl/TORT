--[[
    TORT — Blade Ball Edition (v5)
    - Auto Parry, Spam, ESP, Visuals, AI, Rewards
    - Mobile + PC Support
    - Original: Argon Hub X / TORT by AgentX771

    v5 changes (Auto Parry rework + Auto Spam gating + dead toggles)
    - Auto Parry is now time-to-impact based: it fires when the ball that is
      locked on to you will reach you inside a small reaction window instead of
      a huge fixed distance, so it parries on time instead of 100+ studs early.
    - Auto Parry no longer blocks for 1 second and no longer leaks a
      GetAttributeChangedSignal connection every frame, so it can re-parry
      while the ball keeps coming.
    - Auto Spam only fires when the ball is locked on you, is actually flying
      towards you and is inside its impact window, with a hard KPS limit.
    - New Combat controls: Parry Window, Auto Spam Window, Auto Spam KPS.
    - Wired up toggles that did nothing: AI TORT, Improve Auto Spam,
      Random Parry Accuracy, Auto Block Spams, Anti Block Spams, the
      Detections master switch and the Custom Reward dropdown.
    - Animation Fix now really replays the grab/parry animation (ported from
      Angeli) instead of a dead Parries counter that never incremented.

    v4 changes (Auto / Manual Spam gating)
    - Auto Spam used to be dead code and Manual Spam fired at any ball on screen,
      so the script constantly spammed parry. Both now only fire when the ball is
      actually locked on to you (ball "target" attribute) and inside your radius.
    - New helper ballTargetsMe() reads the ball target (Name / tostring / DisplayName)
      and spamDetectionRadius() reuses the Angeli ping + speed maths.
    - New Combat controls: "Spam Only When Targeted" toggle, "Spam Radius x",
      "Manual Spam KPS" and "Manual Spam Distance" sliders. Detection and ping
      based fire delay are respected again.
    - Mobile Manual Spam: HOLD now checks the target lock before starting, adds a
      1.5s watchdog and a global touch-release listener so it can no longer get
      stuck spamming forever.

    v3 changes
    - Parry hook rewritten to the Angeli build: the remote is captured with its
      real 8 argument signature, the "PRY" token function is fished out of the
      garbage collector and the token is re-derived from GetServerTimeNow on
      every parry. Curve CFrame, screen positions and mouse location are sent
      exactly like the working build does.
    - Auto Parry now runs the Angeli loop (ping/speed divisor, curve detection,
      tornado + aerodynamic guards, detection gating).
    - Fixed a crash that stopped Auto Parry: cooldownProtection/AutoAbility were
      referenced before they existed, so the parry callback died with
      "attempt to call a nil value" whenever a ball targeted you.
    - New touch friendly Mobile Manual Spam UI (floating button + PARRY / HOLD
      SPAM / MANUAL / AUTO PARRY buttons). Opens automatically on mobile.
    - Added Random Target and Forcefield Detection toggles.

    v2 fixes
    - Remote hook now walks the whole tree: Blade Ball nests its remotes inside
      folders, so the old code never hooked anything and Auto Parry never fired.
    - Parry remote is picked by name and replayed; if none is found it falls back
      to pressing the block key / mouse instead of a broken VirtualInputManager call.
    - ESP is built in (the old version downloaded a file that no longer exists).
    - Wired up toggles that did nothing: Player Safety, Anti Phantom Attack,
      Death Slash / Time Hole / Auto Telekinesis detection, Manual Spam,
      Improve Accuracy, Bypass Limits, Player Trail, Hit Effect.
    - Camera is read live, so respawning no longer breaks View Ball / hit sound.
    - Protection toggle no longer stacks hooks every time it is switched on.
--]]

if getgenv().TORT_Loaded then return end
getgenv().TORT_Loaded = true

-- ================================================================
-- PART 1: NOTIFICATION LIBRARY (TORTAlerts)
-- ================================================================
local TORTAlerts = (function()
    local TweenService = game:GetService('TweenService')
    local RightDistance, BotDistance, TextDistance, Duration = 6, 3, 20, 2
    local TextColor = Color3.new(1, 1, 1)
    local BackgroundColor = Color3.fromRGB(32, 34, 37)
    local ActiveColor = Color3.fromRGB(52, 152, 219)
    local ICONS = {
        Info    = "rbxassetid://4057220511",
        Error   = "rbxassetid://4057319805",
        Success = "rbxassetid://95331859717848",
        Warn    = "rbxassetid://5849784138"
    }
    local Slide  = TweenInfo.new(0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
    local SlideY = TweenInfo.new(0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local Notifications, IDs = {}, {}

    local Dummy
    do
        Dummy = Instance.new('ImageLabel')
        Dummy.Name = 'TORTAlert'
        Dummy.Image = "rbxassetid://3570695787"
        Dummy.ScaleType = Enum.ScaleType.Slice
        Dummy.SliceScale = 0.12
        Dummy.SliceCenter = Rect.new(100, 100, 100, 100)
        Dummy.Size = UDim2.new(0, 340, 0, 70)
        Dummy.AnchorPoint = Vector2.new(0, 1)
        Dummy.Position = UDim2.new(1, 0, 1, -30)
        Dummy.BorderSizePixel = 0
        Dummy.BackgroundTransparency = 1
        local Underline = Dummy:Clone()
        Underline.Name = 'Underline'
        Underline.Parent = Dummy
        Underline.AnchorPoint = Vector2.new(0.5, 1)
        Underline.Position = UDim2.new(0.5, 0, 1, 0)
        Underline.Size = UDim2.new(0, 0, 0.06, 0)
        Underline.Rotation = 180
        Underline.ImageRectSize = Vector2.new(200, 120)
    end

    local function DarkerColor(Color, DecreaseValue)
        local H, S, V = Color:ToHSV()
        V = V - DecreaseValue
        if V < 0 then V = 0 end
        return Color3.fromHSV(H, S, V)
    end

    local function M_ToastAlert(Parent, Settings)
        local TitleText       = Settings.Title
        local TextText        = Settings.Text or 'None'
        local IconImage       = Settings.Icon
        local LocalDuration   = Settings.Duration or Duration
        local LocalTextColor  = Settings.TextColor or TextColor
        local LocalBackColor  = Settings.BackgroundColor or BackgroundColor
        local Online = Notifications[Parent] or {}
        Notifications[Parent] = Online
        local Alert = Dummy:Clone()
        local Underline = Alert.Underline
        Alert.Parent = Parent
        Online[#Online + 1] = Alert
        local StartID = #Online
        IDs[Alert] = StartID
        Alert.ImageColor3 = LocalBackColor
        Underline.ImageColor3 = LocalTextColor
        local StartXOffset = TextDistance
        local Icon
        if IconImage then
            Icon = Instance.new('ImageLabel', Alert)
            Icon.BackgroundTransparency = 1
            Icon.Image = IconImage
            Icon.Position = UDim2.new(0, TextDistance, 0.5, 0)
            Icon.AnchorPoint = Vector2.new(0, 0.5)
            local Size = Alert.Size.Y.Offset - Icon.Position.X.Offset * 2
            Icon.Size = UDim2.new(0, Size, 0, Size)
            StartXOffset = TextDistance * 2 + Size
        end
        local Title
        local XSize = Alert.Size.X.Offset - StartXOffset - TextDistance / 2
        if TitleText then
            Title = Instance.new('TextLabel', Alert)
            Title.BackgroundTransparency = 1
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.Text = TitleText
            Title.TextColor3 = LocalTextColor
            Title.TextSize = Settings.TitleSize or 13
            Title.Size = UDim2.new(0, XSize, 0, Title.TextSize)
            Title.Position = UDim2.new(0, StartXOffset, 0, TextDistance - 5)
        end
        local Text = Instance.new('TextLabel', Alert)
        Text.BackgroundTransparency = 1
        Text.TextXAlignment = Enum.TextXAlignment.Left
        Text.TextYAlignment = Enum.TextYAlignment.Top
        Text.TextWrapped = true
        Text.TextSize = Settings.TextSize or 10
        Text.TextColor3 = LocalTextColor
        Text.AnchorPoint = Vector2.new(0, 0)
        Text.Text = TextText
        if Title then
            local y = -(Text.TextSize + TextDistance)
            Text.Size = UDim2.new(0, XSize, 0, Alert.AbsoluteSize.Y + y - TextDistance)
            Text.Position = UDim2.new(0, StartXOffset, 1, y)
        else
            Text.TextYAlignment = Enum.TextYAlignment.Center
            Text.Size = UDim2.new(0, XSize, 1, -(TextDistance * 2))
            Text.AnchorPoint = Vector2.new(0, 0.5)
            Text.Position = UDim2.new(0, StartXOffset, 0.5, 0)
        end
        if Icon then Icon.ImageColor3 = DarkerColor(LocalTextColor, 0.2) end
        if Settings.Sound then Settings.Sound:Play() end
        Alert.Position = UDim2.new(1, Alert.Size.X.Offset + RightDistance, 1, 0)
        TweenService:Create(Alert, Slide, {
            Position = UDim2.new(1, -Alert.Size.X.Offset - RightDistance, 1,
                StartID * -(Alert.Size.Y.Offset + BotDistance))
        }):Play()
        Alert.Changed:Connect(function(Field)
            if Field == 'ImageTransparency' then
                Underline.ImageTransparency = Alert.ImageTransparency
                Text.TextTransparency = Alert.ImageTransparency
                if Title then Title.TextTransparency = Alert.ImageTransparency end
                if Icon  then Icon.ImageTransparency  = Alert.ImageTransparency end
            end
        end)
        local Tween = TweenService:Create(
            Underline,
            TweenInfo.new(LocalDuration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
            {Size = UDim2.new(0.97, 0, Underline.Size.Y.Scale, 0)}
        )
        Tween:Play()
        task.spawn(function()
            Tween.Completed:Wait()
            TweenService:Create(Underline, Slide,
                {Size = UDim2.new(0, 0, Underline.Size.Y.Scale, 0)}):Play()
            TweenService:Create(Alert, Slide, {
                Size = UDim2.new(0, Alert.Size.X.Offset / 1.03, 0, Alert.Size.Y.Offset / 1.03),
                ImageTransparency = 0.1
            }):Play()
            task.wait(0.5)
            local SlideOff = TweenService:Create(Alert, Slide, {
                Position = UDim2.new(1, Alert.Size.X.Offset + RightDistance, 1, Alert.Position.Y.Offset)
            })
            SlideOff:Play()
            SlideOff.Completed:Wait()
            local CurrentId = IDs[Alert]
            IDs[Alert] = nil
            table.remove(Online, CurrentId)
            for ID, Target in next, Online do
                IDs[Target] = ID
                TweenService:Create(Target, SlideY, {
                    Position = UDim2.new(1, -Target.Size.X.Offset - RightDistance, 1,
                        ID * -(Target.Size.Y.Offset + BotDistance))
                }):Play()
            end
            Alert:Destroy()
        end)
    end

    return {
        ToastAlert = M_ToastAlert,
        Info = function(Parent, Title, Message, Dur)
            return M_ToastAlert(Parent, {
                Text = Message, Title = Title, TextColor = ActiveColor,
                BackgroundColor = BackgroundColor, Duration = Dur, Icon = ICONS.Info
            })
        end,
        Warn = function(Parent, Title, Message, Dur)
            return M_ToastAlert(Parent, {
                Text = Message, Title = Title, BackgroundColor = BackgroundColor,
                TextColor = Color3.fromRGB(241, 196, 15), Duration = Dur, Icon = ICONS.Warn
            })
        end,
        Success = function(Parent, Title, Message, Dur)
            return M_ToastAlert(Parent, {
                Text = Message, Title = Title, BackgroundColor = BackgroundColor,
                TextColor = Color3.fromRGB(46, 204, 113), Duration = Dur, Icon = ICONS.Success
            })
        end,
        Error = function(Parent, Title, Message, Dur)
            return M_ToastAlert(Parent, {
                Text = Message, Title = Title, BackgroundColor = BackgroundColor,
                TextColor = Color3.fromRGB(231, 76, 60), Duration = Dur, Icon = ICONS.Error
            })
        end,
    }
end)()

local LibraryNotify = {}
do
    local notifyGui
    local function ensureGui()
        local parent = (gethui and gethui()) or game:GetService("CoreGui")
        if notifyGui and notifyGui.Parent then return notifyGui end
        for _, v in ipairs(parent:GetChildren()) do
            if v:IsA("ScreenGui") and v.Name == "TORTNotify" then
                notifyGui = v
                return notifyGui
            end
        end
        notifyGui = Instance.new("ScreenGui")
        notifyGui.Name = "TORTNotify"
        notifyGui.ResetOnSpawn = false
        notifyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        notifyGui.Parent = parent
        return notifyGui
    end
    function LibraryNotify:MakeNotify(cfg)
        cfg = cfg or {}
        local gui = ensureGui()
        local title = cfg.Title or "TORT"
        local msg = cfg.Content or cfg.Description or ""
        local dur = cfg.Delay or 5
        local desc = (cfg.Description or ""):lower()
        if desc:find("warn") or desc:find("error") or desc:find("unsupport") or desc:find("invalid") then
            TORTAlerts.Warn(gui, title, msg, dur)
        else
            TORTAlerts.Info(gui, title, msg, dur)
        end
    end
end

-- ================================================================
-- PART 2: UI LIBRARY (argon2.txt, intact)
-- ================================================================
local Library = (function()
    local Library = {}
    Library.Flags = {}
    Library.Items = {}
    Library.AccentObjects = {}
    Library.NotificationArea = nil
    Library.ToggleKey = Enum.KeyCode.LeftControl
    Library.IsVisible = true
    Library.DragFrame = nil
    Library.MainFrame = nil
    Library.PreviewSound = nil

    local UserInputService = cloneref(game:GetService("UserInputService"))
    local TweenService     = cloneref(game:GetService("TweenService"))
    local Players          = cloneref(game:GetService("Players"))
    local CoreGui          = cloneref(game:GetService("CoreGui"))
    local HttpService      = cloneref(game:GetService("HttpService"))

    local FolderName   = "-tort-"
    local AutoloadFile = FolderName .. "/autoload.txt"
    local FontAsset    = "rbxassetid://12187364147"
    local CustomFontRegular = Font.new(FontAsset, Enum.FontWeight.Regular)
    local CustomFontMedium  = Font.new(FontAsset, Enum.FontWeight.Medium)
    local CustomFontBold    = Font.new(FontAsset, Enum.FontWeight.Bold)

    local Theme = {
        Background   = Color3.fromRGB(13, 13, 15),
        Sidebar      = Color3.fromRGB(18, 18, 20),
        Groupbox     = Color3.fromRGB(22, 22, 25),
        Element      = Color3.fromRGB(28, 28, 32),
        ElementHover = Color3.fromRGB(38, 38, 44),
        Outline      = Color3.fromRGB(45, 45, 50),
        Accent       = Color3.fromRGB(99, 102, 241),
        Text         = Color3.fromRGB(245, 245, 245),
        SubText      = Color3.fromRGB(160, 160, 170)
    }
    local PredefinedThemes = {
        ["Indigo"]   = Color3.fromRGB(99, 102, 241),
        ["Crimson"]  = Color3.fromRGB(255, 0, 0),
        ["Emerald"]  = Color3.fromRGB(16, 185, 129),
        ["Amethyst"] = Color3.fromRGB(168, 85, 247),
        ["Sunset"]   = Color3.fromRGB(249, 115, 22),
    }

    local function CreateTween(instance, properties, duration, style, dir)
        duration = duration or 0.25
        style = style or Enum.EasingStyle.Quint
        dir = dir or Enum.EasingDirection.Out
        local tweenInfo = TweenInfo.new(duration, style, dir)
        local tween = TweenService:Create(instance, tweenInfo, properties)
        tween:Play()
        return tween
    end

    local function AddUICorner(parent, radius)
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, radius or 6)
        corner.Parent = parent
        return corner
    end

    local function AddUIStroke(parent, color, thickness, transparency)
        local stroke = Instance.new("UIStroke")
        stroke.Color = color or Theme.Outline
        stroke.Thickness = thickness or 1
        stroke.Transparency = transparency or 0
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = parent
        return stroke
    end

    local function ApplyClickAnimation(element)
        local scale = Instance.new("UIScale")
        scale.Parent = element
        element.MouseEnter:Connect(function() CreateTween(scale, {Scale = 1.02}, 0.2) end)
        element.MouseLeave:Connect(function() CreateTween(scale, {Scale = 1}, 0.2) end)
        element.MouseButton1Down:Connect(function() CreateTween(scale, {Scale = 0.95}, 0.15) end)
        element.MouseButton1Up:Connect(function() CreateTween(scale, {Scale = 1.02}, 0.2) end)
    end

    function Library:GetConfigs()
        local list = {}
        if isfolder(FolderName) then
            for _, file in ipairs(listfiles(FolderName)) do
                if file:match("%.json$") then
                    local name = file:match("([^/\\]+)%.json$")
                    if name then table.insert(list, name) end
                end
            end
        end
        return list
    end

    local function SafeWriteFile(name, data)
        if not isfolder(FolderName) then makefolder(FolderName) end
        local SerializedData = {}
        for k, v in pairs(data) do
            if typeof(v) == "Color3" then
                SerializedData[k] = {R = v.R, G = v.G, B = v.B, Type = "Color3"}
            elseif typeof(v) == "EnumItem" then
                SerializedData[k] = {Name = v.Name, EnumType = tostring(v.EnumType), Type = "Enum"}
            elseif type(v) ~= "table" and typeof(v) ~= "Instance" then
                SerializedData[k] = v
            end
        end
        writefile(FolderName .. "/" .. name .. ".json", HttpService:JSONEncode(SerializedData))
    end

    local function SafeReadFile(name)
        if not isfolder(FolderName) then return nil end
        if not isfile(FolderName .. "/" .. name .. ".json") then return nil end
        local success, result = pcall(function()
            return HttpService:JSONDecode(readfile(FolderName .. "/" .. name .. ".json"))
        end)
        if not success then return nil end
        local ParsedData = {}
        for k, v in pairs(result) do
            if type(v) == "table" and v.Type == "Color3" then
                ParsedData[k] = Color3.new(v.R, v.G, v.B)
            elseif type(v) == "table" and v.Type == "Enum" then
                ParsedData[k] = Enum.KeyCode[v.Name] or v.Name
            else
                ParsedData[k] = v
            end
        end
        return ParsedData
    end

    function Library:SaveConfig(name)
        SafeWriteFile(name, Library.Flags)
        if Library.Items["ConfigDropdown"] then
            Library.Items["ConfigDropdown"].Refresh(Library:GetConfigs(), name)
        end
    end
    function Library:LoadConfig(name)
        local data = SafeReadFile(name)
        if data then
            for flag, value in pairs(data) do
                if Library.Items[flag] and Library.Items[flag].Set then
                    pcall(function() Library.Items[flag].Set(value) end)
                else
                    Library.Flags[flag] = value
                end
            end
        end
    end
    function Library:DeleteConfig(name)
        local path = FolderName .. "/" .. name .. ".json"
        if isfile(path) then
            delfile(path)
            if Library.Items["ConfigDropdown"] then
                Library.Items["ConfigDropdown"].Refresh(Library:GetConfigs(), "")
            end
        end
    end
    function Library:SetAutoload(name)
        if not isfolder(FolderName) then makefolder(FolderName) end
        writefile(AutoloadFile, name)
    end
    function Library:RemoveAutoload()
        if isfile(AutoloadFile) then delfile(AutoloadFile) end
    end
    function Library:GetAutoload()
        if isfile(AutoloadFile) then return readfile(AutoloadFile) end
        return nil
    end

    function Library:UpdateTheme(newAccent)
        Theme.Accent = newAccent
        for _, obj in pairs(Library.AccentObjects) do
            if obj:IsA("Frame") or obj:IsA("TextButton") or obj:IsA("ScrollingFrame") then
                if obj.Name == "AccentBg" then
                    CreateTween(obj, {BackgroundColor3 = newAccent}, 0.3)
                elseif obj.Name == "TabBtn" and obj:GetAttribute("IsActive") then
                    CreateTween(obj, {BackgroundColor3 = newAccent}, 0.3)
                end
            end
            if obj:IsA("TextLabel") or obj:IsA("TextBox") or obj:IsA("TextButton") then
                if obj.Name == "AccentText" then
                    CreateTween(obj, {TextColor3 = newAccent}, 0.3)
                end
            end
            if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
                if obj.Name == "AccentImage" or obj.Name == "Glow" then
                    CreateTween(obj, {ImageColor3 = newAccent}, 0.3)
                end
            end
            if obj:IsA("UIStroke") then
                if obj.Name == "AccentStroke" then
                    CreateTween(obj, {Color = newAccent}, 0.3)
                end
            end
        end
    end

    local function MakeDraggable(topbar, object)
        local dragging, dragInput, dragStart, startPos
        topbar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = object.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        topbar.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                local scaleObj = object:FindFirstChildOfClass("UIScale")
                local scaleFactor = scaleObj and scaleObj.Scale or 1
                object.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + (delta.X / scaleFactor),
                    startPos.Y.Scale, startPos.Y.Offset + (delta.Y / scaleFactor))
            end
        end)
    end

    local Characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local function RandomString(Length)
        local Result = ""
        for _ = 1, Length do
            local Index = math.random(1, #Characters)
            Result = Result .. Characters:sub(Index, Index)
        end
        return Result
    end

    function Library:CreateWindow(args)
        args = type(args) == "table" and args or {Title = args}
        local titleText = args.Title or "TORT"
        local usingImage = args.UsingImage or false
        local windowIcon = args.WindowIcon or ""
        local themeChoice = args.Theme or "Indigo"
        local useAccentColor = args.UseAccentColor
        if useAccentColor == nil then useAccentColor = true end
        if PredefinedThemes[themeChoice] then Theme.Accent = PredefinedThemes[themeChoice] end

        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = RandomString(math.random(100, 200))
        ScreenGui.ResetOnSpawn = false
        ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        ScreenGui.Parent = gethui() or CoreGui

        local FloatingToggle
        if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
            FloatingToggle = Instance.new("TextButton")
            FloatingToggle.Name = "FloatingToggle"
            FloatingToggle.Size = UDim2.new(0, 44, 0, 44)
            FloatingToggle.Position = UDim2.new(0, 30, 0, 30)
            FloatingToggle.BackgroundColor3 = Theme.Groupbox
            FloatingToggle.Text = "T"
            FloatingToggle.FontFace = CustomFontBold
            FloatingToggle.TextColor3 = Theme.Accent
            FloatingToggle.TextSize = 20
            FloatingToggle.AutoButtonColor = false
            FloatingToggle.ZIndex = 99999
            FloatingToggle.Parent = ScreenGui
            AddUICorner(FloatingToggle, 8)
            AddUIStroke(FloatingToggle, Theme.Outline, 1)
            MakeDraggable(FloatingToggle, FloatingToggle)
            ApplyClickAnimation(FloatingToggle)
        end

        local DragFrame = Instance.new("Frame")
        DragFrame.Name = "DragFrame"
        DragFrame.Size = UDim2.new(0, 620, 0, 400)
        DragFrame.Position = UDim2.new(0.5, -310, 0.5, -200)
        DragFrame.BackgroundTransparency = 1
        DragFrame.Active = true
        DragFrame.ZIndex = 1
        DragFrame.Parent = ScreenGui
        MakeDraggable(DragFrame, DragFrame)
        Library.DragFrame = DragFrame

        local UIScale = Instance.new("UIScale")
        UIScale.Parent = DragFrame
        local TargetScale = 1
        local function UpdateAutoScale()
            if not workspace.CurrentCamera then return end
            local vs = workspace.CurrentCamera.ViewportSize
            local uiWidth = DragFrame.Size.X.Offset
            local uiHeight = DragFrame.Size.Y.Offset
            local scaleX = (vs.X * 0.90) / uiWidth
            local scaleY = (vs.Y * 0.90) / uiHeight
            TargetScale = math.clamp(math.min(scaleX, scaleY), 0.2, 1.1)
            if Library.IsVisible then UIScale.Scale = TargetScale end
        end
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateAutoScale)
        UpdateAutoScale()

        local cornerRadius = 20
        local MainFrame = Instance.new("CanvasGroup")
        MainFrame.Name = "MainFrame"
        MainFrame.Size = UDim2.new(1, 0, 1, 0)
        MainFrame.BackgroundColor3 = Theme.Background
        MainFrame.BorderSizePixel = 0
        MainFrame.ZIndex = 2
        MainFrame.Parent = DragFrame
        AddUICorner(MainFrame, cornerRadius)
        Library.MainFrame = MainFrame

        local OutlineFrame = Instance.new("Frame")
        OutlineFrame.Size = UDim2.new(1, 0, 1, 0)
        OutlineFrame.BackgroundTransparency = 1
        OutlineFrame.ZIndex = 99
        OutlineFrame.Parent = DragFrame
        AddUICorner(OutlineFrame, cornerRadius)
        AddUIStroke(OutlineFrame, Theme.Outline, 1)

        getgenv().ToggleUIVisibility = function()
            Library.IsVisible = not Library.IsVisible
            if Library.IsVisible then
                DragFrame.Visible = true
                CreateTween(MainFrame, {GroupTransparency = 0}, 0.35, Enum.EasingStyle.Quint)
                CreateTween(OutlineFrame, {BackgroundTransparency = 1}, 0.35)
                CreateTween(UIScale, {Scale = TargetScale}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            else
                CreateTween(MainFrame, {GroupTransparency = 1}, 0.25, Enum.EasingStyle.Quint)
                local scaleTween = CreateTween(UIScale, {Scale = TargetScale * 0.92}, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
                scaleTween.Completed:Connect(function()
                    if not Library.IsVisible then DragFrame.Visible = false end
                end)
            end
        end

        if FloatingToggle then
            FloatingToggle.MouseButton1Click:Connect(ToggleUIVisibility)
        end

        local Sidebar = Instance.new("Frame")
        Sidebar.Size = UDim2.new(0, 65, 1, 0)
        Sidebar.BackgroundColor3 = Theme.Sidebar
        Sidebar.BorderSizePixel = 0
        Sidebar.ZIndex = 5
        Sidebar.Parent = MainFrame

        local SidebarLine = Instance.new("Frame")
        SidebarLine.Size = UDim2.new(0, 1, 1, 0)
        SidebarLine.Position = UDim2.new(1, 0, 0, 0)
        SidebarLine.BackgroundColor3 = Theme.Outline
        SidebarLine.BorderSizePixel = 0
        SidebarLine.ZIndex = 6
        SidebarLine.Parent = Sidebar

        if usingImage then
            local TitleIcon = Instance.new("ImageLabel")
            TitleIcon.Size = UDim2.new(0, 28, 0, 28)
            TitleIcon.Position = UDim2.new(0.5, -14, 0, 15)
            TitleIcon.BackgroundTransparency = 1
            TitleIcon.Image = windowIcon
            TitleIcon.ZIndex = 6
            TitleIcon.Parent = Sidebar
            if useAccentColor then
                TitleIcon.ImageColor3 = Theme.Accent
                TitleIcon.Name = "AccentImage"
                table.insert(Library.AccentObjects, TitleIcon)
            else
                TitleIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
            end
        else
            local Title = Instance.new("TextLabel")
            Title.Size = UDim2.new(1, 0, 0, 60)
            Title.BackgroundTransparency = 1
            Title.FontFace = CustomFontBold
            Title.Text = titleText
            Title.RichText = true
            Title.TextSize = 14
            Title.ZIndex = 6
            Title.Parent = Sidebar
            if useAccentColor then
                Title.TextColor3 = Theme.Accent
                Title.Name = "AccentText"
                table.insert(Library.AccentObjects, Title)
            else
                Title.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
        end

        local TabContainer = Instance.new("ScrollingFrame")
        TabContainer.Size = UDim2.new(1, 0, 1, -130)
        TabContainer.Position = UDim2.new(0, 0, 0, 60)
        TabContainer.BackgroundTransparency = 1
        TabContainer.ScrollBarThickness = 0
        TabContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
        TabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
        TabContainer.ZIndex = 6
        TabContainer.Parent = Sidebar
        local TabListLayout = Instance.new("UIListLayout")
        TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        TabListLayout.Padding = UDim.new(0, 8)
        TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        TabListLayout.Parent = TabContainer

        local BottomTabContainer = Instance.new("Frame")
        BottomTabContainer.Size = UDim2.new(1, 0, 0, 60)
        BottomTabContainer.Position = UDim2.new(0, 0, 1, -60)
        BottomTabContainer.BackgroundTransparency = 1
        BottomTabContainer.ZIndex = 6
        BottomTabContainer.Parent = Sidebar
        local BottomListLayout = Instance.new("UIListLayout")
        BottomListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        BottomListLayout.Padding = UDim.new(0, 8)
        BottomListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        BottomListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        BottomListLayout.Parent = BottomTabContainer

        local Pages = Instance.new("Frame")
        Pages.Size = UDim2.new(1, -65, 1, 0)
        Pages.Position = UDim2.new(0, 65, 0, 0)
        Pages.BackgroundTransparency = 1
        Pages.ZIndex = 3
        Pages.Parent = MainFrame

        Library.NotificationArea = Instance.new("Frame")
        Library.NotificationArea.Size = UDim2.new(0, 260, 1, -20)
        Library.NotificationArea.Position = UDim2.new(1, -270, 0, 10)
        Library.NotificationArea.BackgroundTransparency = 1
        Library.NotificationArea.ZIndex = 999
        Library.NotificationArea.Parent = ScreenGui
        local NotifLayout = Instance.new("UIListLayout")
        NotifLayout.SortOrder = Enum.SortOrder.LayoutOrder
        NotifLayout.Padding = UDim.new(0, 8)
        NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        NotifLayout.Parent = Library.NotificationArea

        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if input.KeyCode == Library.ToggleKey then
                if UserInputService:GetFocusedTextBox() == nil then
                    ToggleUIVisibility()
                end
            end
        end)

        local Window = {Tabs = {}, CurrentTab = nil}

        function Window:CreateTab(name, iconId, isBottom)
            local TabBtn = Instance.new("TextButton")
            TabBtn.Name = "TabBtn"
            TabBtn.Size = UDim2.new(0, 42, 0, 42)
            TabBtn.BackgroundColor3 = Theme.Groupbox
            TabBtn.BackgroundTransparency = 1
            TabBtn.Text = ""
            TabBtn.AutoButtonColor = false
            TabBtn.ZIndex = 7
            TabBtn.Parent = isBottom and BottomTabContainer or TabContainer
            TabBtn:SetAttribute("IsActive", false)
            AddUICorner(TabBtn, 10)
            table.insert(Library.AccentObjects, TabBtn)
            local TabScale = Instance.new("UIScale")
            TabScale.Parent = TabBtn

            local Icon
            if iconId then
                Icon = Instance.new("ImageLabel")
                Icon.Size = UDim2.new(0, 22, 0, 22)
                Icon.Position = UDim2.new(0.5, -11, 0.5, -11)
                Icon.BackgroundTransparency = 1
                Icon.Image = iconId
                Icon.ImageColor3 = Theme.SubText
                Icon.ZIndex = 7
                Icon.Parent = TabBtn
            else
                TabBtn.Text = string.sub(name, 1, 1)
                TabBtn.FontFace = CustomFontBold
                TabBtn.TextColor3 = Theme.SubText
                TabBtn.TextSize = 16
            end

            local Page = Instance.new("ScrollingFrame")
            Page.Size = UDim2.new(1, -24, 1, -24)
            Page.Position = UDim2.new(0, 12, 0, 12)
            Page.BackgroundTransparency = 1
            Page.ScrollBarThickness = 3
            Page.ScrollBarImageColor3 = Theme.Outline
            Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
            Page.CanvasSize = UDim2.new(0, 0, 0, 0)
            Page.ZIndex = 5
            Page.Visible = false
            Page.Parent = Pages

            local PageGroup = Instance.new("Frame")
            PageGroup.Size = UDim2.new(1, 0, 1, 0)
            PageGroup.BackgroundTransparency = 1
            PageGroup.AutomaticSize = Enum.AutomaticSize.Y
            PageGroup.Parent = Page

            local LeftCol = Instance.new("Frame")
            LeftCol.Size = UDim2.new(0.5, -6, 0, 0)
            LeftCol.Position = UDim2.new(0, 0, 0, 0)
            LeftCol.BackgroundTransparency = 1
            LeftCol.AutomaticSize = Enum.AutomaticSize.Y
            LeftCol.ZIndex = 6
            LeftCol.Parent = PageGroup

            local RightCol = Instance.new("Frame")
            RightCol.Size = UDim2.new(0.5, -6, 0, 0)
            RightCol.Position = UDim2.new(0.5, 6, 0, 0)
            RightCol.BackgroundTransparency = 1
            RightCol.AutomaticSize = Enum.AutomaticSize.Y
            RightCol.ZIndex = 6
            RightCol.Parent = PageGroup

            local LL = Instance.new("UIListLayout")
            LL.SortOrder = Enum.SortOrder.LayoutOrder
            LL.Padding = UDim.new(0, 12)
            LL.Parent = LeftCol

            local RL = Instance.new("UIListLayout")
            RL.SortOrder = Enum.SortOrder.LayoutOrder
            RL.Padding = UDim.new(0, 12)
            RL.Parent = RightCol

            local function SetTabActive(isActive)
                TabBtn:SetAttribute("IsActive", isActive)
                if isActive then
                    CreateTween(TabScale, {Scale = 0.9}, 0.1).Completed:Connect(function()
                        CreateTween(TabScale, {Scale = 1}, 0.2)
                    end)
                    CreateTween(TabBtn, {BackgroundTransparency = 0, BackgroundColor3 = Theme.Accent}, 0.3)
                    if Icon then
                        CreateTween(Icon, {ImageColor3 = Theme.Text}, 0.3)
                    else
                        CreateTween(TabBtn, {TextColor3 = Theme.Text}, 0.3)
                    end
                    Page.Visible = true
                else
                    CreateTween(TabBtn, {BackgroundTransparency = 1, BackgroundColor3 = Theme.Groupbox}, 0.3)
                    if Icon then
                        CreateTween(Icon, {ImageColor3 = Theme.SubText}, 0.3)
                    else
                        CreateTween(TabBtn, {TextColor3 = Theme.SubText}, 0.3)
                    end
                    Page.Visible = false
                end
            end

            TabBtn.MouseEnter:Connect(function()
                if not TabBtn:GetAttribute("IsActive") then
                    CreateTween(TabBtn, {BackgroundTransparency = 0.5}, 0.2)
                    if Icon then CreateTween(Icon, {ImageColor3 = Theme.Text}, 0.2) end
                end
            end)
            TabBtn.MouseLeave:Connect(function()
                if not TabBtn:GetAttribute("IsActive") then
                    CreateTween(TabBtn, {BackgroundTransparency = 1}, 0.2)
                    if Icon then CreateTween(Icon, {ImageColor3 = Theme.SubText}, 0.2) end
                end
            end)
            TabBtn.MouseButton1Click:Connect(function()
                if Window.CurrentTab == Page then return end
                if Window.CurrentTab then Window.CurrentTab.SetTabActive(false) end
                Window.CurrentTab = {Btn = TabBtn, Page = Page, SetTabActive = SetTabActive}
                SetTabActive(true)
            end)
            if not Window.CurrentTab then
                Window.CurrentTab = {Btn = TabBtn, Page = Page, SetTabActive = SetTabActive}
                SetTabActive(true)
            end

            local TabElements = {}
            function TabElements:CreateGroupbox(name, side)
                side = side or "Left"
                local ParentCol = side:lower() == "right" and RightCol or LeftCol
                local Groupbox = Instance.new("Frame")
                Groupbox.Name = name .. "Groupbox"
                Groupbox.Size = UDim2.new(1, 0, 0, 0)
                Groupbox.BackgroundColor3 = Theme.Groupbox
                Groupbox.AutomaticSize = Enum.AutomaticSize.Y
                Groupbox.BorderSizePixel = 0
                Groupbox.ZIndex = 7
                Groupbox.Parent = ParentCol
                AddUICorner(Groupbox, 24)
                AddUIStroke(Groupbox, Theme.Outline, 1)

                local GroupboxPadding = Instance.new("UIPadding")
                GroupboxPadding.PaddingTop = UDim.new(0, 4)
                GroupboxPadding.PaddingBottom = UDim.new(0, 14)
                GroupboxPadding.PaddingLeft = UDim.new(0, 2)
                GroupboxPadding.PaddingRight = UDim.new(0, 2)
                GroupboxPadding.Parent = Groupbox

                local TitleLabel = Instance.new("TextLabel")
                TitleLabel.Size = UDim2.new(1, -24, 0, 36)
                TitleLabel.Position = UDim2.new(0, 14, 0, 4)
                TitleLabel.BackgroundTransparency = 1
                TitleLabel.Text = string.upper(name)
                TitleLabel.FontFace = CustomFontBold
                TitleLabel.TextColor3 = Theme.Text
                TitleLabel.TextSize = 12
                TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
                TitleLabel.ZIndex = 8
                TitleLabel.Parent = Groupbox

                local TitleLine = Instance.new("Frame")
                TitleLine.Size = UDim2.new(1, -28, 0, 2)
                TitleLine.Position = UDim2.new(0, 14, 0, 34)
                TitleLine.BackgroundColor3 = Theme.Outline
                TitleLine.BackgroundTransparency = 0.4
                TitleLine.BorderSizePixel = 0
                TitleLine.ZIndex = 8
                TitleLine.Parent = Groupbox
                AddUICorner(TitleLine, 999)

                local ElementContainer = Instance.new("Frame")
                ElementContainer.Size = UDim2.new(1, -28, 0, 0)
                ElementContainer.Position = UDim2.new(0, 14, 0, 46)
                ElementContainer.BackgroundTransparency = 1
                ElementContainer.AutomaticSize = Enum.AutomaticSize.Y
                ElementContainer.ZIndex = 8
                ElementContainer.Parent = Groupbox
                local ElementLayout = Instance.new("UIListLayout")
                ElementLayout.SortOrder = Enum.SortOrder.LayoutOrder
                ElementLayout.Padding = UDim.new(0, 10)
                ElementLayout.Parent = ElementContainer

                local Elements = {}
                function Elements:CreateSection(args)
                    args = type(args) == "table" and args or {Name = args}
                    local name = args.Name or "Section"
                    local SectionFrame = Instance.new("Frame")
                    SectionFrame.Size = UDim2.new(1, 0, 0, 26)
                    SectionFrame.BackgroundTransparency = 1
                    SectionFrame.ZIndex = 8
                    SectionFrame.Parent = ElementContainer
                    local SectionTitle = Instance.new("TextLabel")
                    SectionTitle.Size = UDim2.new(1, 0, 0, 16)
                    SectionTitle.Position = UDim2.new(0, 0, 0, 6)
                    SectionTitle.BackgroundTransparency = 1
                    SectionTitle.Text = name
                    SectionTitle.FontFace = CustomFontBold
                    SectionTitle.TextColor3 = Theme.Accent
                    SectionTitle.TextSize = 12
                    SectionTitle.Name = "AccentText"
                    SectionTitle.ZIndex = 9
                    SectionTitle.Parent = SectionFrame
                    table.insert(Library.AccentObjects, SectionTitle)
                end

                function Elements:CreateLabel(args)
                    args = type(args) == "table" and args or {Name = args}
                    local name = args.Name or "Label"
                    local LabelFrame = Instance.new("Frame")
                    LabelFrame.Size = UDim2.new(1, 0, 0, 18)
                    LabelFrame.BackgroundTransparency = 1
                    LabelFrame.ZIndex = 8
                    LabelFrame.Parent = ElementContainer
                    local LabelText = Instance.new("TextLabel")
                    LabelText.Size = UDim2.new(1, 0, 1, 0)
                    LabelText.BackgroundTransparency = 1
                    LabelText.Text = name
                    LabelText.FontFace = CustomFontRegular
                    LabelText.TextColor3 = Theme.SubText
                    LabelText.TextSize = 12
                    LabelText.TextXAlignment = Enum.TextXAlignment.Left
                    LabelText.ZIndex = 9
                    LabelText.Parent = LabelFrame
                    return {SetText = function(self, newText) LabelText.Text = newText end}
                end

                function Elements:CreateButton(args)
                    args = type(args) == "table" and args or {Name = args}
                    local name = args.Name or "Button"
                    local callback = type(args.Callback) == "function" and args.Callback or function() end
                    local BtnFrame = Instance.new("TextButton")
                    BtnFrame.Size = UDim2.new(1, 0, 0, 32)
                    BtnFrame.BackgroundColor3 = Theme.Element
                    BtnFrame.Text = ""
                    BtnFrame.AutoButtonColor = false
                    BtnFrame.ZIndex = 8
                    BtnFrame.Parent = ElementContainer
                    AddUICorner(BtnFrame, 6)
                    local Stroke = AddUIStroke(BtnFrame, Theme.Outline, 1)
                    local BtnTitle = Instance.new("TextLabel")
                    BtnTitle.Size = UDim2.new(1, 0, 1, 0)
                    BtnTitle.BackgroundTransparency = 1
                    BtnTitle.Text = name
                    BtnTitle.FontFace = CustomFontMedium
                    BtnTitle.TextColor3 = Theme.Text
                    BtnTitle.TextSize = 12
                    BtnTitle.ZIndex = 9
                    BtnTitle.Parent = BtnFrame
                    ApplyClickAnimation(BtnFrame)
                    BtnFrame.MouseEnter:Connect(function()
                        CreateTween(BtnFrame, {BackgroundColor3 = Theme.ElementHover}, 0.2)
                        CreateTween(Stroke, {Color = Theme.SubText}, 0.2)
                    end)
                    BtnFrame.MouseLeave:Connect(function()
                        CreateTween(BtnFrame, {BackgroundColor3 = Theme.Element}, 0.2)
                        CreateTween(Stroke, {Color = Theme.Outline}, 0.2)
                    end)
                    BtnFrame.MouseButton1Click:Connect(callback)
                end

                function Elements:CreateKeybind(args)
                    args = type(args) == "table" and args or {Name = args}
                    local name = args.Name or "Keybind"
                    local default = args.Default or Enum.KeyCode.Unknown
                    local flag = args.Flag or string.gsub(name, "%s+", "")
                    local callback = type(args.Callback) == "function" and args.Callback or function() end
                    Library.Flags[flag] = default

                    local KeybindFrame = Instance.new("Frame")
                    KeybindFrame.Size = UDim2.new(1, 0, 0, 32)
                    KeybindFrame.BackgroundColor3 = Theme.Element
                    KeybindFrame.ZIndex = 8
                    KeybindFrame.Parent = ElementContainer
                    AddUICorner(KeybindFrame, 6)
                    AddUIStroke(KeybindFrame, Theme.Outline, 1)

                    local TitleLabel = Instance.new("TextLabel")
                    TitleLabel.Size = UDim2.new(1, -70, 1, 0)
                    TitleLabel.Position = UDim2.new(0, 10, 0, 0)
                    TitleLabel.BackgroundTransparency = 1
                    TitleLabel.Text = name
                    TitleLabel.FontFace = CustomFontMedium
                    TitleLabel.TextColor3 = Theme.Text
                    TitleLabel.TextSize = 12
                    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
                    TitleLabel.ZIndex = 9
                    TitleLabel.Parent = KeybindFrame

                    local BindBtn = Instance.new("TextButton")
                    BindBtn.Size = UDim2.new(0, 60, 0, 20)
                    BindBtn.Position = UDim2.new(1, -70, 0.5, -10)
                    BindBtn.BackgroundColor3 = Theme.Background
                    BindBtn.Text = typeof(default) == "EnumItem" and default.Name or "None"
                    BindBtn.FontFace = CustomFontMedium
                    BindBtn.TextSize = 11
                    BindBtn.TextColor3 = Theme.SubText
                    BindBtn.ZIndex = 9
                    BindBtn.Parent = KeybindFrame
                    AddUICorner(BindBtn, 4)
                    AddUIStroke(BindBtn, Theme.Outline, 1)
                    ApplyClickAnimation(BindBtn)

                    local currentKey = typeof(default) == "EnumItem" and default or nil
                    local listening = false
                    BindBtn.MouseButton1Click:Connect(function()
                        listening = true
                        BindBtn.Text = "..."
                        CreateTween(BindBtn, {TextColor3 = Theme.Accent}, 0.2)
                    end)
                    UserInputService.InputBegan:Connect(function(input)
                        if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                            if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
                                currentKey = nil
                                BindBtn.Text = "None"
                            else
                                currentKey = input.KeyCode
                                BindBtn.Text = currentKey.Name
                                Library.Flags[flag] = currentKey
                            end
                            CreateTween(BindBtn, {TextColor3 = Theme.SubText}, 0.2)
                            listening = false
                            callback(currentKey)
                        elseif not listening and currentKey and input.KeyCode == currentKey then
                            if UserInputService:GetFocusedTextBox() == nil then callback(currentKey) end
                        end
                    end)
                    Library.Items[flag] = {
                        Type = "Keybind",
                        Set = function(val)
                            currentKey = typeof(val) == "EnumItem" and val or nil
                            Library.Flags[flag] = currentKey
                            BindBtn.Text = currentKey and currentKey.Name or "None"
                            callback(currentKey)
                        end
                    }
                end

                function Elements:CreateToggle(args)
                    args = type(args) == "table" and args or {Name = args}
                    local name = args.Name or "Toggle"
                    local default = args.Default or false
                    local flag = args.Flag or string.gsub(name, "%s+", "")
                    local defaultBind = args.Keybind
                    local callback = type(args.Callback) == "function" and args.Callback or function() end
                    if Library.Flags[flag] ~= nil then default = Library.Flags[flag] end
                    Library.Flags[flag] = default

                    local ToggleFrame = Instance.new("TextButton")
                    ToggleFrame.Size = UDim2.new(1, 0, 0, 32)
                    ToggleFrame.BackgroundColor3 = Theme.Element
                    ToggleFrame.Text = ""
                    ToggleFrame.AutoButtonColor = false
                    ToggleFrame.ZIndex = 8
                    ToggleFrame.Parent = ElementContainer
                    AddUICorner(ToggleFrame, 6)
                    AddUIStroke(ToggleFrame, Theme.Outline, 1)

                    local TitleLabel = Instance.new("TextLabel")
                    TitleLabel.Size = UDim2.new(1, -90, 1, 0)
                    TitleLabel.Position = UDim2.new(0, 10, 0, 0)
                    TitleLabel.BackgroundTransparency = 1
                    TitleLabel.Text = name
                    TitleLabel.FontFace = CustomFontMedium
                    TitleLabel.TextColor3 = Theme.Text
                    TitleLabel.TextSize = 12
                    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
                    TitleLabel.ZIndex = 9
                    TitleLabel.Parent = ToggleFrame

                    local TogglePill = Instance.new("Frame")
                    TogglePill.Size = UDim2.new(0, 34, 0, 18)
                    TogglePill.Position = UDim2.new(1, -44, 0.5, -9)
                    TogglePill.BackgroundColor3 = default and Theme.Accent or Theme.Background
                    TogglePill.ZIndex = 9
                    TogglePill.Parent = ToggleFrame
                    if default then
                        TogglePill.Name = "AccentBg"
                        table.insert(Library.AccentObjects, TogglePill)
                    end
                    AddUICorner(TogglePill, 9)
                    local PillStroke = AddUIStroke(TogglePill, Theme.Outline, 1)
                    if default then PillStroke.Transparency = 1 end

                    local ToggleCircle = Instance.new("Frame")
                    ToggleCircle.Size = UDim2.new(0, 12, 0, 12)
                    ToggleCircle.Position = default and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
                    ToggleCircle.BackgroundColor3 = default and Color3.new(1, 1, 1) or Theme.SubText
                    ToggleCircle.ZIndex = 10
                    ToggleCircle.Parent = TogglePill
                    AddUICorner(ToggleCircle, 6)

                    local function SetState(state)
                        Library.Flags[flag] = state
                        if state then
                            TogglePill.Name = "AccentBg"
                            table.insert(Library.AccentObjects, TogglePill)
                            CreateTween(TogglePill, {BackgroundColor3 = Theme.Accent}, 0.3)
                            CreateTween(PillStroke, {Transparency = 1}, 0.3)
                            CreateTween(ToggleCircle, {Position = UDim2.new(1, -15, 0.5, -6), BackgroundColor3 = Color3.new(1, 1, 1)}, 0.3, Enum.EasingStyle.Back)
                        else
                            TogglePill.Name = "TogglePill"
                            CreateTween(TogglePill, {BackgroundColor3 = Theme.Background}, 0.3)
                            CreateTween(PillStroke, {Transparency = 0}, 0.3)
                            CreateTween(ToggleCircle, {Position = UDim2.new(0, 3, 0.5, -6), BackgroundColor3 = Theme.SubText}, 0.3, Enum.EasingStyle.Back)
                        end
                        callback(state)
                    end
                    ToggleFrame.MouseButton1Click:Connect(function()
                        SetState(not Library.Flags[flag])
                    end)

                    if defaultBind ~= nil then
                        local BindBtn = Instance.new("TextButton")
                        BindBtn.Size = UDim2.new(0, 40, 0, 18)
                        BindBtn.Position = UDim2.new(1, -94, 0.5, -9)
                        BindBtn.BackgroundColor3 = Theme.Background
                        BindBtn.Text = typeof(defaultBind) == "EnumItem" and defaultBind.Name or "None"
                        BindBtn.FontFace = CustomFontMedium
                        BindBtn.TextSize = 10
                        BindBtn.TextColor3 = Theme.SubText
                        BindBtn.ZIndex = 9
                        BindBtn.Parent = ToggleFrame
                        AddUICorner(BindBtn, 4)
                        AddUIStroke(BindBtn, Theme.Outline, 1)
                        local currentKey = typeof(defaultBind) == "EnumItem" and defaultBind or nil
                        local listening = false
                        BindBtn.MouseButton1Click:Connect(function()
                            listening = true
                            BindBtn.Text = "..."
                        end)
                        UserInputService.InputBegan:Connect(function(input)
                            if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                                if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
                                    currentKey = nil
                                    BindBtn.Text = "None"
                                else
                                    currentKey = input.KeyCode
                                    BindBtn.Text = currentKey.Name
                                    Library.Flags[flag .. "_Bind"] = currentKey
                                end
                                listening = false
                            elseif not listening and currentKey and input.KeyCode == currentKey then
                                if UserInputService:GetFocusedTextBox() == nil then
                                    SetState(not Library.Flags[flag])
                                end
                            end
                        end)
                    end
                    Library.Items[flag] = {Type = "Toggle", Set = SetState}
                    if default then callback(default) end
                end

                function Elements:CreateSlider(args)
                    args = type(args) == "table" and args or {Name = args}
                    local name = args.Name or "Slider"
                    local min = args.Min or 0
                    local max = args.Max or 100
                    local default = args.Default or min
                    local increment = args.Increment or 1
                    local flag = args.Flag or string.gsub(name, "%s+", "")
                    local callback = type(args.Callback) == "function" and args.Callback or function() end
                    if Library.Flags[flag] ~= nil then default = Library.Flags[flag] end
                    local valMin = math.clamp(default or min, min, max)
                    Library.Flags[flag] = valMin

                    local SliderFrame = Instance.new("Frame")
                    SliderFrame.Size = UDim2.new(1, 0, 0, 48)
                    SliderFrame.BackgroundColor3 = Theme.Element
                    SliderFrame.ZIndex = 8
                    SliderFrame.Parent = ElementContainer
                    AddUICorner(SliderFrame, 6)
                    AddUIStroke(SliderFrame, Theme.Outline, 1)

                    local TitleLabel = Instance.new("TextLabel")
                    TitleLabel.Size = UDim2.new(1, -20, 0, 20)
                    TitleLabel.Position = UDim2.new(0, 10, 0, 6)
                    TitleLabel.BackgroundTransparency = 1
                    TitleLabel.Text = name
                    TitleLabel.FontFace = CustomFontMedium
                    TitleLabel.TextColor3 = Theme.Text
                    TitleLabel.TextSize = 12
                    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
                    TitleLabel.ZIndex = 9
                    TitleLabel.Parent = SliderFrame

                    local ValueLabel = Instance.new("TextLabel")
                    ValueLabel.Size = UDim2.new(1, -20, 0, 20)
                    ValueLabel.Position = UDim2.new(0, 10, 0, 6)
                    ValueLabel.BackgroundTransparency = 1
                    ValueLabel.FontFace = CustomFontBold
                    ValueLabel.TextColor3 = Theme.SubText
                    ValueLabel.TextSize = 11
                    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
                    ValueLabel.ZIndex = 9
                    ValueLabel.Parent = SliderFrame

                    local Track = Instance.new("TextButton")
                    Track.Size = UDim2.new(1, -20, 0, 4)
                    Track.Position = UDim2.new(0, 10, 0, 34)
                    Track.BackgroundColor3 = Theme.Background
                    Track.Text = ""
                    Track.AutoButtonColor = false
                    Track.ZIndex = 9
                    Track.Parent = SliderFrame
                    AddUICorner(Track, 2)
                    AddUIStroke(Track, Theme.Outline, 1)

                    local Fill = Instance.new("Frame")
                    Fill.Name = "AccentBg"
                    Fill.BackgroundColor3 = Theme.Accent
                    Fill.ZIndex = 10
                    Fill.Parent = Track
                    table.insert(Library.AccentObjects, Fill)
                    AddUICorner(Fill, 2)

                    local knob = Instance.new("Frame")
                    knob.Size = UDim2.new(0, 12, 0, 12)
                    knob.AnchorPoint = Vector2.new(0.5, 0.5)
                    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    knob.ZIndex = 11
                    knob.Parent = Fill
                    AddUICorner(knob, 6)

                    local function UpdateVisuals()
                        local p1 = (valMin - min) / (max - min)
                        CreateTween(Fill, {Size = UDim2.new(p1, 0, 1, 0)}, 0.1)
                        CreateTween(knob, {Position = UDim2.new(1, 0, 0.5, 0)}, 0.1)
                        ValueLabel.Text = tostring(valMin)
                        Library.Flags[flag] = valMin
                        callback(valMin)
                    end
                    UpdateVisuals()

                    local isDragging = false
                    local function ProcessInput(input)
                        local rel = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                        local raw = min + ((max - min) * rel)
                        local snapped = math.clamp(math.floor(raw / increment + 0.5) * increment, min, max)
                        valMin = snapped
                        UpdateVisuals()
                    end
                    Track.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            isDragging = true
                            ProcessInput(input)
                        end
                    end)
                    UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            isDragging = false
                        end
                    end)
                    UserInputService.InputChanged:Connect(function(input)
                        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                            ProcessInput(input)
                        end
                    end)
                    Library.Items[flag] = {
                        Type = "Slider",
                        Set = function(val)
                            valMin = math.clamp(math.floor(val / increment + 0.5) * increment, min, max)
                            UpdateVisuals()
                        end
                    }
                end

                function Elements:CreateDropdown(args)
                    args = type(args) == "table" and args or {Name = args}
                    local name = args.Name or "Dropdown"
                    local options = args.Options or {}
                    local flag = args.Flag or string.gsub(name, "%s+", "")
                    local default = args.Default or options[1]
                    local callback = type(args.Callback) == "function" and args.Callback or function() end
                    if Library.Flags[flag] ~= nil then default = Library.Flags[flag] end

                    local DropdownFrame = Instance.new("Frame")
                    DropdownFrame.Size = UDim2.new(1, 0, 0, 48)
                    DropdownFrame.BackgroundColor3 = Theme.Element
                    DropdownFrame.ClipsDescendants = true
                    DropdownFrame.ZIndex = 8
                    DropdownFrame.Parent = ElementContainer
                    AddUICorner(DropdownFrame, 6)
                    AddUIStroke(DropdownFrame, Theme.Outline, 1)

                    local TitleLabel = Instance.new("TextLabel")
                    TitleLabel.Size = UDim2.new(1, -20, 0, 20)
                    TitleLabel.Position = UDim2.new(0, 10, 0, 4)
                    TitleLabel.BackgroundTransparency = 1
                    TitleLabel.Text = name
                    TitleLabel.FontFace = CustomFontMedium
                    TitleLabel.TextColor3 = Theme.Text
                    TitleLabel.TextSize = 12
                    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
                    TitleLabel.ZIndex = 9
                    TitleLabel.Parent = DropdownFrame

                    local MainBtn = Instance.new("TextButton")
                    MainBtn.Size = UDim2.new(1, -20, 0, 20)
                    MainBtn.Position = UDim2.new(0, 10, 0, 24)
                    MainBtn.BackgroundColor3 = Theme.Background
                    MainBtn.Text = tostring(default)
                    MainBtn.FontFace = CustomFontMedium
                    MainBtn.TextColor3 = Theme.SubText
                    MainBtn.TextSize = 11
                    MainBtn.TextXAlignment = Enum.TextXAlignment.Left
                    MainBtn.AutoButtonColor = false
                    MainBtn.ZIndex = 9
                    MainBtn.Parent = DropdownFrame
                    AddUICorner(MainBtn, 4)
                    AddUIStroke(MainBtn, Theme.Outline, 1)

                    local ListContainer = Instance.new("ScrollingFrame")
                    ListContainer.Size = UDim2.new(1, -20, 0, 0)
                    ListContainer.Position = UDim2.new(0, 10, 0, 50)
                    ListContainer.BackgroundTransparency = 1
                    ListContainer.ScrollBarThickness = 2
                    ListContainer.ScrollBarImageColor3 = Theme.Outline
                    ListContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
                    ListContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
                    ListContainer.ZIndex = 9
                    ListContainer.Parent = DropdownFrame
                    local ListLayout = Instance.new("UIListLayout")
                    ListLayout.Padding = UDim.new(0, 4)
                    ListLayout.Parent = ListContainer

                    local isOpen = false
                    local selected = default

                    local function populate()
                        for _, c in ipairs(ListContainer:GetChildren()) do
                            if c:IsA("TextButton") then c:Destroy() end
                        end
                        for _, v in ipairs(options) do
                            local opt = Instance.new("TextButton")
                            opt.Size = UDim2.new(1, -4, 0, 24)
                            opt.BackgroundColor3 = (selected == v) and Theme.Accent or Theme.Background
                            opt.BackgroundTransparency = (selected == v) and 0.8 or 1
                            opt.Text = tostring(v)
                            opt.FontFace = CustomFontMedium
                            opt.TextColor3 = (selected == v) and Theme.Text or Theme.SubText
                            opt.TextSize = 11
                            opt.TextXAlignment = Enum.TextXAlignment.Left
                            opt.AutoButtonColor = false
                            opt.Parent = ListContainer
                            AddUICorner(opt, 4)
                            opt.MouseButton1Click:Connect(function()
                                selected = v
                                Library.Flags[flag] = v
                                MainBtn.Text = tostring(v)
                                isOpen = false
                                CreateTween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 48)}, 0.35, Enum.EasingStyle.Quint)
                                populate()
                                callback(v)
                            end)
                        end
                    end

                    MainBtn.MouseButton1Click:Connect(function()
                        isOpen = not isOpen
                        if isOpen then
                            local listHeight = math.clamp(ListLayout.AbsoluteContentSize.Y, 0, 140)
                            ListContainer.Size = UDim2.new(1, -20, 0, listHeight)
                            CreateTween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 48 + listHeight + 10)}, 0.35, Enum.EasingStyle.Quint)
                            populate()
                        else
                            CreateTween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 48)}, 0.35, Enum.EasingStyle.Quint)
                        end
                    end)
                    populate()
                    Library.Flags[flag] = selected
                    if default then callback(selected) end
                    Library.Items[flag] = {
                        Type = "Dropdown",
                        Set = function(val)
                            selected = val
                            MainBtn.Text = tostring(val)
                            populate()
                            callback(val)
                        end
                    }
                end

                function Elements:CreateTextbox(args)
                    args = type(args) == "table" and args or {Name = args}
                    local name = args.Name or "Textbox"
                    local default = args.Default or ""
                    local flag = args.Flag or string.gsub(name, "%s+", "")
                    local callback = type(args.Callback) == "function" and args.Callback or function() end
                    if Library.Flags[flag] ~= nil then default = Library.Flags[flag] end
                    Library.Flags[flag] = default

                    local TextboxFrame = Instance.new("Frame")
                    TextboxFrame.Size = UDim2.new(1, 0, 0, 48)
                    TextboxFrame.BackgroundColor3 = Theme.Element
                    TextboxFrame.ZIndex = 8
                    TextboxFrame.Parent = ElementContainer
                    AddUICorner(TextboxFrame, 6)
                    AddUIStroke(TextboxFrame, Theme.Outline, 1)

                    local TitleLabel = Instance.new("TextLabel")
                    TitleLabel.Size = UDim2.new(1, -20, 0, 20)
                    TitleLabel.Position = UDim2.new(0, 10, 0, 4)
                    TitleLabel.BackgroundTransparency = 1
                    TitleLabel.Text = name
                    TitleLabel.FontFace = CustomFontMedium
                    TitleLabel.TextColor3 = Theme.Text
                    TitleLabel.TextSize = 12
                    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
                    TitleLabel.ZIndex = 9
                    TitleLabel.Parent = TextboxFrame

                    local InputBox = Instance.new("TextBox")
                    InputBox.Size = UDim2.new(1, -20, 0, 20)
                    InputBox.Position = UDim2.new(0, 10, 0, 24)
                    InputBox.BackgroundColor3 = Theme.Background
                    InputBox.Text = tostring(default)
                    InputBox.FontFace = CustomFontMedium
                    InputBox.TextColor3 = Theme.SubText
                    InputBox.TextSize = 11
                    InputBox.ClearTextOnFocus = false
                    InputBox.ZIndex = 9
                    InputBox.Parent = TextboxFrame
                    AddUICorner(InputBox, 4)
                    local BoxStroke = AddUIStroke(InputBox, Theme.Outline, 1)
                    InputBox.Focused:Connect(function() CreateTween(BoxStroke, {Color = Theme.Accent}, 0.3) end)
                    InputBox.FocusLost:Connect(function()
                        CreateTween(BoxStroke, {Color = Theme.Outline}, 0.3)
                        Library.Flags[flag] = InputBox.Text
                        callback(InputBox.Text)
                    end)
                    Library.Items[flag] = {
                        Type = "Textbox",
                        Set = function(val)
                            Library.Flags[flag] = val
                            InputBox.Text = tostring(val)
                            callback(val)
                        end
                    }
                end

                return Elements
            end
            return TabElements
        end
        return Window
    end
    return Library
end)()

-- Compatibility shim: old ArgonRise API -> new argon2 API
do
    function Library.__init()
        local win = Library:CreateWindow({Title = "TORT FREE", Theme = "Indigo", UseAccentColor = true})
        local api = {}
        function api.create_tab(name)
            local tab = win:CreateTab(name)
            local groups = {}
            local function getGroup(section)
                local key = (section == "right") and "right" or "left"
                if not groups[key] then
                    groups[key] = tab:CreateGroupbox(" ", key == "right" and "Right" or "Left")
                end
                return groups[key]
            end
            return {
                create_title     = function(t) getGroup(t.section):CreateSection(t.name or "") end,
                create_button    = function(t) getGroup(t.section):CreateButton({Name = t.name, Callback = t.callback}) end,
                create_toggle    = function(t) getGroup(t.section):CreateToggle({Name = t.name, Flag = t.flag, Default = t.enabled, Callback = t.callback}) end,
                create_slider    = function(t) getGroup(t.section):CreateSlider({Name = t.name, Flag = t.flag, Default = t.value, Min = t.minimum_value, Max = t.maximum_value, Callback = t.callback}) end,
                create_dropdown  = function(t) getGroup(t.section):CreateDropdown({Name = t.name, Flag = t.flag, Options = t.options, Default = t.option, Callback = t.callback}) end,
                create_textbox   = function(t) getGroup(t.section):CreateTextbox({Name = t.name, Flag = t.flag, Default = t.value, Callback = t.callback}) end,
                create_line      = function(t) end,
                create_paragraph = function(t) getGroup(t.section):CreateLabel({Name = (t.name or "") .. " " .. (t.title or "")}) end,
                create_image     = function(t) end,
            }
        end
        return api
    end
end

-- ================================================================
-- PART 3: MAIN SCRIPT (Fixed for Blade Ball)
-- ================================================================

-- ============================================================
-- 0. SERVICES
-- ============================================================
local Services = {
    CoreGui = game:GetService("CoreGui"),
    HttpService = game:GetService("HttpService"),
    Players = game:GetService("Players"),
    MarketplaceService = game:GetService("MarketplaceService"),
    AnalyticsService = game:GetService("RbxAnalyticsService"),
    Lighting = game:GetService("Lighting"),
    RunService = game:GetService("RunService"),
}

local LocalPlayer = Services.Players.LocalPlayer
local Camera = workspace.CurrentCamera
local IsMobile = game:GetService("UserInputService").TouchEnabled and not game:GetService("UserInputService").MouseEnabled

-- ============================================================
-- 1. ESP LINES (optional, loaded via HttpGet)
-- ============================================================

-- ============================================================
-- 1. ESP LINES (built in - the old version fetched a file that no longer exists)
-- ============================================================
local ESPLines = {
    Enabled = false, ShowBox = false, ShowName = false,
    ShowHealth = false, ShowTracer = false, ShowDistance = false, BoxType = "2D"
}
do
    local ESP = ESPLines
    local ESPGui
    local ESPFrames = {}
    local ESPPlayers = game:GetService("Players")
    local ESPLocalPlayer = ESPPlayers.LocalPlayer
    local ESPRunService = game:GetService("RunService")
    local ESP_FAR = Color3.fromRGB(0, 255, 128)
    local ESP_MID = Color3.fromRGB(255, 220, 0)
    local ESP_NEAR = Color3.fromRGB(255, 70, 70)

    local function ensureGui()
        if ESPGui and ESPGui.Parent then return ESPGui end
        local parent = (gethui and gethui()) or game:GetService("CoreGui")
        local existing = parent:FindFirstChild("TORT_ESP")
        if existing then ESPGui = existing; return ESPGui end
        ESPGui = Instance.new("ScreenGui")
        ESPGui.Name = "TORT_ESP"
        ESPGui.ResetOnSpawn = false
        ESPGui.IgnoreGuiInset = true
        ESPGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        ESPGui.Parent = parent
        return ESPGui
    end

    local function newObject(className, parent)
        local object = Instance.new(className)
        object.BorderSizePixel = 0
        object.Parent = parent
        return object
    end

    local function newLabel(parent)
        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.BorderSizePixel = 0
        label.Font = Enum.Font.GothamBold
        label.TextSize = 13
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextStrokeTransparency = 0
        label.TextStrokeColor3 = Color3.new(0, 0, 0)
        label.Visible = false
        label.Parent = parent
        return label
    end

    local function createESP(player)
        local gui = ensureGui()
        local esp = {Corners = {}}
        esp.Box = newObject("Frame", gui)
        esp.Box.BackgroundTransparency = 1
        esp.Box.Visible = false
        esp.Stroke = Instance.new("UIStroke")
        esp.Stroke.Color = Color3.new(1, 1, 1)
        esp.Stroke.Thickness = 1
        esp.Stroke.Parent = esp.Box
        for index = 1, 8 do
            local corner = newObject("Frame", esp.Box)
            corner.BackgroundColor3 = Color3.new(1, 1, 1)
            corner.Visible = false
            esp.Corners[index] = corner
        end
        esp.HealthBar = newObject("Frame", gui)
        esp.HealthBar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        esp.HealthBar.Visible = false
        esp.HealthFill = newObject("Frame", esp.HealthBar)
        esp.HealthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 128)
        esp.HealthFill.AnchorPoint = Vector2.new(0, 1)
        esp.NameLabel = newLabel(gui)
        esp.NameLabel.Text = player.Name
        esp.DistanceLabel = newLabel(gui)
        esp.DistanceLabel.Font = Enum.Font.Gotham
        esp.DistanceLabel.TextSize = 12
        esp.DistanceLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
        esp.Tracer = newObject("Frame", gui)
        esp.Tracer.AnchorPoint = Vector2.new(0.5, 0.5)
        esp.Tracer.Visible = false
        return esp
    end

    local function destroyESP(player)
        local esp = ESPFrames[player]
        if not esp then return end
        ESPFrames[player] = nil
        for _, object in ipairs({esp.Box, esp.HealthBar, esp.NameLabel, esp.DistanceLabel, esp.Tracer}) do
            if object then object:Destroy() end
        end
    end

    local function hideESP(esp)
        esp.Box.Visible = false
        esp.HealthBar.Visible = false
        esp.NameLabel.Visible = false
        esp.DistanceLabel.Visible = false
        esp.Tracer.Visible = false
        for _, corner in ipairs(esp.Corners) do corner.Visible = false end
    end

    local function setCorner(corner, x, y, width, height)
        corner.Position = UDim2.fromOffset(x, y)
        corner.Size = UDim2.fromOffset(width, height)
    end

    local function renderESP()
        if not ESP.Enabled then
            for _, esp in pairs(ESPFrames) do hideESP(esp) end
            return
        end
        local camera = workspace.CurrentCamera
        if not camera then return end
        local viewport = camera.ViewportSize
        local alive = {}
        for _, player in ipairs(ESPPlayers:GetPlayers()) do
            if player ~= ESPLocalPlayer then
                local character = player.Character
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                local root = character and character:FindFirstChild("HumanoidRootPart")
                if humanoid and root and humanoid.Health > 0 then
                    local head = character:FindFirstChild("Head")
                    local topWorld = (head and head.Position or root.Position) + Vector3.new(0, 0.9, 0)
                    local bottomWorld = root.Position - Vector3.new(0, 3, 0)
                    local topPoint, topVisible = camera:WorldToViewportPoint(topWorld)
                    local bottomPoint, bottomVisible = camera:WorldToViewportPoint(bottomWorld)
                    if topVisible or bottomVisible then
                        local height = math.max(math.abs(topPoint.Y - bottomPoint.Y), 18)
                        local width = math.max(height * 0.6, 12)
                        local left = topPoint.X - width / 2
                        local top = math.min(topPoint.Y, bottomPoint.Y)
                        local distance = (root.Position - camera.CFrame.Position).Magnitude
                        local color = ESP_FAR
                        if distance <= 60 then
                            color = ESP_NEAR
                        elseif distance <= 140 then
                            color = ESP_MID
                        end

                        local esp = ESPFrames[player]
                        if not esp then
                            esp = createESP(player)
                            ESPFrames[player] = esp
                        end
                        alive[player] = true

                        esp.Box.Position = UDim2.fromOffset(left, top)
                        esp.Box.Size = UDim2.fromOffset(width, height)
                        esp.Box.Visible = ESP.ShowBox
                        esp.Stroke.Enabled = ESP.ShowBox and ESP.BoxType ~= "Corner Box Esp"
                        esp.Stroke.Color = color

                        local thickness = 2
                        local cornerWidth = math.max(math.floor(width * 0.3), 6)
                        local cornerHeight = math.max(math.floor(height * 0.15), 6)
                        for _, corner in ipairs(esp.Corners) do
                            corner.BackgroundColor3 = color
                            corner.Visible = ESP.ShowBox and ESP.BoxType == "Corner Box Esp"
                        end
                        setCorner(esp.Corners[1], 0, 0, cornerWidth, thickness)
                        setCorner(esp.Corners[2], 0, 0, thickness, cornerHeight)
                        setCorner(esp.Corners[3], width - cornerWidth, 0, cornerWidth, thickness)
                        setCorner(esp.Corners[4], width - thickness, 0, thickness, cornerHeight)
                        setCorner(esp.Corners[5], 0, height - thickness, cornerWidth, thickness)
                        setCorner(esp.Corners[6], 0, height - cornerHeight, thickness, cornerHeight)
                        setCorner(esp.Corners[7], width - cornerWidth, height - thickness, cornerWidth, thickness)
                        setCorner(esp.Corners[8], width - thickness, height - cornerHeight, thickness, cornerHeight)

                        if ESP.ShowHealth then
                            local ratio = 0
                            if humanoid.MaxHealth > 0 then
                                ratio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                            end
                            esp.HealthBar.Visible = true
                            esp.HealthBar.Position = UDim2.fromOffset(left - 7, top)
                            esp.HealthBar.Size = UDim2.fromOffset(4, height)
                            esp.HealthFill.Size = UDim2.new(1, 0, ratio, 0)
                            esp.HealthFill.BackgroundColor3 = Color3.fromRGB(
                                math.floor(255 * (1 - ratio)), math.floor(255 * ratio), 40)
                        else
                            esp.HealthBar.Visible = false
                        end

                        if ESP.ShowName then
                            esp.NameLabel.Visible = true
                            esp.NameLabel.Text = player.Name
                            esp.NameLabel.Position = UDim2.fromOffset(left - 40, top - 17)
                            esp.NameLabel.Size = UDim2.fromOffset(width + 80, 16)
                            esp.NameLabel.TextColor3 = color
                        else
                            esp.NameLabel.Visible = false
                        end

                        if ESP.ShowDistance then
                            esp.DistanceLabel.Visible = true
                            esp.DistanceLabel.Text = string.format("[%d studs]", math.floor(distance))
                            esp.DistanceLabel.Position = UDim2.fromOffset(left - 40, top + height + 2)
                            esp.DistanceLabel.Size = UDim2.fromOffset(width + 80, 14)
                        else
                            esp.DistanceLabel.Visible = false
                        end

                        if ESP.ShowTracer then
                            local fromX, fromY = viewport.X / 2, viewport.Y
                            local toX, toY = left + width / 2, top + height
                            local deltaX, deltaY = toX - fromX, toY - fromY
                            local length = math.sqrt(deltaX * deltaX + deltaY * deltaY)
                            esp.Tracer.Visible = true
                            esp.Tracer.BackgroundColor3 = color
                            esp.Tracer.Position = UDim2.fromOffset((fromX + toX) / 2, (fromY + toY) / 2)
                            esp.Tracer.Size = UDim2.fromOffset(length, 1)
                            esp.Tracer.Rotation = math.deg(math.atan2(deltaY, deltaX))
                        else
                            esp.Tracer.Visible = false
                        end
                    end
                end
            end
        end
        for player, esp in pairs(ESPFrames) do
            if not alive[player] then hideESP(esp) end
        end
    end

    ESPPlayers.PlayerRemoving:Connect(destroyESP)
    ESPRunService.RenderStepped:Connect(renderESP)
end

-- ============================================================
-- 2. GLOBAL HELPERS
-- ============================================================
local GetClosestPlayer, GetBall, GetBallFromPlayerPos

function GetClosestPlayer()
    local closestDistance = math.huge
    local closestTarget = nil
    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil end
    for _, v in pairs(workspace:FindFirstChild("Alive") and workspace.Alive:GetChildren() or {}) do
        if v:FindFirstChild("HumanoidRootPart") and v ~= myChar then
            local distance = (myChar.HumanoidRootPart.Position - v.HumanoidRootPart.Position).Magnitude
            if distance < closestDistance then
                closestDistance = distance
                closestTarget = v
            end
        end
    end
    return closestTarget
end

function GetBall()
    for _, v in pairs(workspace.Balls:GetChildren()) do
        if v:IsA("Part") then return v end
    end
    return nil
end

function GetBallFromPlayerPos(Ball)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return math.huge end
    return (Ball.Position - char.HumanoidRootPart.Position).Magnitude
end

local function getSpeed(part)
    if part:IsA("BasePart") then
        local speed = part.Velocity.Magnitude
        if speed > 1 then return part, speed end
        return nil, nil
    end
    return nil, nil
end

-- ============================================================
-- 3. BLADE BALL SPECIFIC REMOTE HANDLING
-- ============================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local net
pcall(function()
    net = ReplicatedStorage:WaitForChild("Packages")["_Index"]["sleitnick_net@0.1.0"].net
end)

-- ============================================================
-- 4. AUTO REWARDS
-- ============================================================
local auto_rewards_enabled = false
local reward_interval = 60
local reward_choice = "All"

-- 'Custom Reward' dropdown (All / Daily / Tasks) used to have an empty
-- callback, so the choice did nothing.
local function reward_wants(kind)
    return reward_choice == "All" or reward_choice == kind
end

local function claim_rewards()
    pcall(function()
        if ReplicatedStorage:FindFirstChild("Remote") and ReplicatedStorage.Remote:FindFirstChild("RemoteEvent") then
            local event = ReplicatedStorage.Remote.RemoteEvent:FindFirstChild('ClaimLoginReward')
            if event then event:FireServer() end
        end
    end)
    task.defer(function()
        if not reward_wants("Daily") then return end
        for day = 1, 30 do
            task.wait()
            pcall(function()
                if ReplicatedStorage.Remote:FindFirstChild("RemoteFunction") then
                    ReplicatedStorage.Remote.RemoteFunction:InvokeServer('ClaimNewDailyLoginReward', day)
                end
            end)
            for _, wheel in ipairs({"SummerWheel", "CyborgWheel", "SynthWheel"}) do
                pcall(function()
                    local processRoll = net and net:FindFirstChild("RE/" .. wheel .. "/ProcessRoll")
                    if processRoll then processRoll:FireServer() end
                end)
            end
            pcall(function()
                if net and net:FindFirstChild("RE/ProcessTournamentRoll") then net["RE/ProcessTournamentRoll"]:FireServer() end
                if net and net:FindFirstChild("RE/RolledReturnCrate") then net["RE/RolledReturnCrate"]:FireServer() end
                if net and net:FindFirstChild("RE/ProcessLTMRoll") then net["RE/ProcessLTMRoll"]:FireServer() end
            end)
        end
    end)
    task.defer(function()
        if not reward_wants("Daily") then return end
        for reward = 1, 6 do
            pcall(function()
                if net and net:FindFirstChild("RF/ClaimPlaytimeReward") then net["RF/ClaimPlaytimeReward"]:InvokeServer(reward) end
            end)
            pcall(function()
                if net and net:FindFirstChild("RE/ClaimSeasonPlaytimeReward") then net["RE/ClaimSeasonPlaytimeReward"]:FireServer(reward) end
            end)
            pcall(function()
                if ReplicatedStorage.Remote:FindFirstChild("RemoteFunction") then ReplicatedStorage.Remote.RemoteFunction:InvokeServer('SpinWheel') end
            end)
            pcall(function()
                if net and net:FindFirstChild("RE/SpinFinished") then net["RE/SpinFinished"]:FireServer() end
            end)
        end
    end)
    task.defer(function()
        if not reward_wants("Tasks") then return end
        for reward = 1, 5 do
            pcall(function()
                if net and net:FindFirstChild("RF/RedeemQuestsType") then net["RF/RedeemQuestsType"]:InvokeServer('SummerClashEvent', 'Daily', reward) end
            end)
        end
    end)
    task.defer(function()
        if not reward_wants("Daily") then return end
        for reward = 1, 4 do
            pcall(function()
                if net and net:FindFirstChild("RE/SummerWheel/ClaimStreakReward") then net["RE/SummerWheel/ClaimStreakReward"]:FireServer(reward) end
            end)
        end
    end)
end

task.defer(function()
    while task.wait(reward_interval) do
        pcall(function() if auto_rewards_enabled then claim_rewards() end end)
    end
end)

-- ============================================================
-- 5. REMOTE HOOKING & PARRY SYSTEM
-- ============================================================
local hookSupport = hookmetamethod and true
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Mouse = LocalPlayer:GetMouse()

local revertedRemotes = {}
local originalMetatables = {}
local DirectionMode = "Camera"
local EnableAntiCurve = false
local EnableAutoCurve = false

local function GetClosestPlayerLocal()
    local closest, distance = nil, math.huge
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            local d = (v.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            if d < distance then closest = v; distance = d end
        end
    end
    return closest
end

local function GetDirection()
    local Camera = workspace.CurrentCamera or Camera
    if EnableAntiCurve then
        return (Camera.CFrame * CFrame.new(0, 0, -500)).Position
    elseif EnableAutoCurve then
        local t = GetClosestPlayerLocal()
        if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
            local d = (t.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position)
            return d.Unit + Vector3.new(0, math.sin(tick() * 5) * 0.2, 0)
        end
    elseif DirectionMode == "Camera" then return Camera.CFrame.LookVector
    elseif DirectionMode == "Mouse" then return (Mouse.Hit.Position - LocalPlayer.Character.HumanoidRootPart.Position).Unit
    elseif DirectionMode == "Players" then
        local target = GetClosestPlayerLocal()
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            return (target.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Unit
        end
    elseif DirectionMode == "Normal" then return Vector3.new(0, 0, -1)
    elseif DirectionMode == "Up" then return Vector3.new(0, 1, 0)
    elseif DirectionMode == "Down" then return Vector3.new(0, -1, 0)
    elseif DirectionMode == "Left" then return -Camera.CFrame.RightVector
    elseif DirectionMode == "Right" then return Camera.CFrame.RightVector
    elseif DirectionMode == "Behind" then return -Camera.CFrame.LookVector
    elseif DirectionMode == "Random" then return Vector3.new(math.random(-10, 10), math.random(-10, 10), math.random(-10, 10)).Unit
    elseif DirectionMode == "FrontLeft" then return (Camera.CFrame.LookVector - Camera.CFrame.RightVector).Unit
    elseif DirectionMode == "FrontRight" then return (Camera.CFrame.LookVector + Camera.CFrame.RightVector).Unit
    elseif DirectionMode == "BackLeft" then return (-Camera.CFrame.LookVector - Camera.CFrame.RightVector).Unit
    elseif DirectionMode == "BackRight" then return (-Camera.CFrame.LookVector + Camera.CFrame.RightVector).Unit
    elseif DirectionMode == "SkywardSpiral" then return (Camera.CFrame.LookVector + Vector3.new(0, math.sin(tick() * 5), 0)).Unit
    elseif DirectionMode == "Zigzag" then return (Camera.CFrame.LookVector + Camera.CFrame.RightVector * math.sin(tick() * 10)).Unit
    elseif DirectionMode == "Spin" then
        local angle = math.rad(tick() * 360 % 360)
        return Vector3.new(math.cos(angle), 0, math.sin(angle)).Unit
    elseif DirectionMode == "Bounce" then return (Camera.CFrame.LookVector + Vector3.new(0, math.abs(math.sin(tick() * 5)) * 2, 0)).Unit
    elseif DirectionMode == "Wave" then return (Camera.CFrame.LookVector + Vector3.new(math.sin(tick() * 5), 0, 0)).Unit
    elseif DirectionMode == "Orbit" then
        local angle = tick() * 2
        return (Camera.CFrame.LookVector + Vector3.new(math.cos(angle), 0, math.sin(angle))).Unit
    elseif DirectionMode == "Chaos" then
        return (Camera.CFrame.LookVector + Vector3.new(math.random(-100, 100)/100, math.random(-100, 100)/100, math.random(-100, 100)/100)).Unit
    elseif DirectionMode == "TargetFeet" then
        local t = GetClosestPlayerLocal()
        if t and t.Character then
            local part = t.Character:FindFirstChild("LeftFoot") or t.Character:FindFirstChild("HumanoidRootPart")
            if part then return (part.Position - LocalPlayer.Character.HumanoidRootPart.Position).Unit end
        end
    elseif DirectionMode == "TargetHead" then
        local t = GetClosestPlayerLocal()
        if t and t.Character then
            local part = t.Character:FindFirstChild("Head")
            if part then return (part.Position - LocalPlayer.Character.HumanoidRootPart.Position).Unit end
        end
    elseif DirectionMode == "DiagonalUp" then return (Camera.CFrame.LookVector + Vector3.new(0.5, 0.5, 0)).Unit
    elseif DirectionMode == "DiagonalDown" then return (Camera.CFrame.LookVector + Vector3.new(-0.5, -0.5, 0)).Unit
    elseif DirectionMode == "FlipReverse" then return (Camera.CFrame.LookVector * -1).Unit
    elseif DirectionMode == "CurveLeft" then return (Camera.CFrame.LookVector + -Camera.CFrame.RightVector * 0.5).Unit
    elseif DirectionMode == "CurveRight" then return (Camera.CFrame.LookVector + Camera.CFrame.RightVector * 0.5).Unit
    elseif DirectionMode == "Whirlwind" then
        local angle = math.rad(tick() * 720 % 360)
        return (Camera.CFrame.LookVector + Vector3.new(math.cos(angle), math.sin(angle), 0)).Unit
    elseif DirectionMode == "TeleportStyle" then return Vector3.new(0, 100, 0)
    elseif DirectionMode == "SlideAngle" then return (Camera.CFrame.LookVector + Vector3.new(1, -0.2, 0)).Unit
    elseif DirectionMode == "Drift" then return (Camera.CFrame.LookVector + Camera.CFrame.RightVector * math.cos(tick() * 2)).Unit
    end
    return Camera.CFrame.LookVector
end

-- ============================================================
-- 5.1 REMOTE HOOK (ported from Angeli)
-- ============================================================
-- Blade Ball hides its remotes inside folders, so we walk the whole tree.
-- The parry remote takes 8 arguments:
--   FireServer(uid, name, tokenize(name), 0.5, curveCFrame, screenPositions, mouseLocation, false)
_G.config = _G.config or {}
if _G.config.accuracy == nil then _G.config.accuracy = 100 end
if _G.config.curve_method == nil then _G.config.curve_method = "Camera" end
if _G.config.random_target == nil then _G.config.random_target = false end
if _G.config.manual_spam_kps == nil then _G.config.manual_spam_kps = 25 end

local Stats = game:GetService("Stats")

local _reverted = revertedRemotes
local _original = originalMetatables

local function _is_valid(args)
    return #args == 8 and type(args[2]) == "string" and type(args[3]) == "string"
        and type(args[4]) == "number" and typeof(args[5]) == "CFrame"
        and type(args[6]) == "table" and type(args[7]) == "table"
        and type(args[8]) == "boolean"
end

local _getRawMeta = getrawmetatable or (debug and debug.getmetatable)
local _setReadonly = setreadonly
local _isReadonly = isreadonly

local _hook = function(remote)
    if _reverted[remote] then return end
    if type(_getRawMeta) ~= "function" then return end
    local okMeta, meta = pcall(_getRawMeta, remote)
    if not okMeta or type(meta) ~= "table" then return end
    if _original[meta] then return end
    _original[meta] = true
    -- Guard: some executors expose a locked metatable and calling setreadonly
    -- on it (or without support) throws hard and kills the client. Keep every
    -- metatable operation pcalled, and bail out quietly if we cannot hook.
    local wasReadonly = false
    if type(_isReadonly) == "function" then
        local okReadonly, ro = pcall(_isReadonly, meta)
        wasReadonly = okReadonly and ro and true or false
    end
    if wasReadonly and type(_setReadonly) == "function" then
        pcall(_setReadonly, meta, false)
    end
    local _old = meta.__index
    meta.__index = function(self, key)
        if (key == 'FireServer' and self:IsA('RemoteEvent'))
        or (key == 'InvokeServer' and self:IsA('RemoteFunction')) then
            return function(_, ...)
                local _arguments = {...}
                local okValid, valid = pcall(_is_valid, _arguments)
                if okValid and valid and not _reverted[self] then
                    _reverted[self] = _arguments
                end
                return _old(self, key)(_, table.unpack(_arguments))
            end
        end
        return _old(self, key)
    end
    if wasReadonly and type(_setReadonly) == "function" then
        pcall(_setReadonly, meta, true)
    end
end

pcall(function()
    local replicatedStorage = game:GetService("ReplicatedStorage")
    local descendants = replicatedStorage:GetDescendants()
    if type(descendants) == "table" then
        for _, remote in pairs(descendants) do
            if remote and typeof(remote) == "Instance" then
                if remote:IsA('RemoteEvent') or remote:IsA('RemoteFunction') then
                    pcall(_hook, remote)
                end
            end
        end
    end
    replicatedStorage.DescendantAdded:Connect(function(child)
        if not child or typeof(child) ~= "Instance" then return end
        if child:IsA('RemoteEvent') or child:IsA('RemoteFunction') then
            pcall(_hook, child)
        end
    end)
end)

local function findToken()
    if not getgc then return nil end
    local okGc, gc = pcall(getgc, true)
    if not okGc or type(gc) ~= "table" then return nil end
    for _, value in pairs(gc) do
        if type(value) == 'function' then
            local okSource, source = pcall(function()
                return debug.info(value, 's')
            end)
            if okSource and source and tostring(source):find('PRY', 1, true) then
                local okUpvalues, upvalues = pcall(function()
                    return debug.getupvalues(value)
                end)
                if okUpvalues and type(upvalues) == "table" then
                    for _, upvalue in pairs(upvalues) do
                        if type(upvalue) == 'function' then return upvalue end
                    end
                end
            end
        end
    end
    return nil
end

local _token = findToken()

task.spawn(function()
    local tries = 0
    while not _token and tries < 40 do
        tries = tries + 1
        task.wait(1)
        if not _token then _token = findToken() end
    end
end)

local function _tokenize(remoteUid)
    if not _token then return nil end
    local time = tostring(math.floor(workspace:GetServerTimeNow() * 100))
    local okKey, key = pcall(_token, remoteUid, 'TIME')
    if not okKey or type(key) ~= "string" or #key == 0 then return nil end
    local characters = table.create(#time)
    for index = 1, #time do
        characters[index] = string.char(bit32.bxor(
            (string.byte(time, index) + index) % 256,
            string.byte(key, (index - 1) % #key + 1)
        ))
    end
    return table.concat(characters)
end

-- Fallback when the remote could not be captured: press the block key / mouse.
local function fireParryInput()
    local key = getgenv().TORT_ParryKey or Enum.KeyCode.F
    if keypress and keyrelease then
        local ok = pcall(function()
            keypress(key)
            task.wait(0.03)
            keyrelease(key)
        end)
        if ok then return true end
    end
    if mouse1press and mouse1release then
        local ok = pcall(function()
            mouse1press()
            task.wait(0.03)
            mouse1release()
        end)
        if ok then return true end
    end
    if mouse1click then
        local ok = pcall(mouse1click)
        if ok then return true end
    end
    return false
end

local _PARRY_PATCH = { ready = true }

function _PARRY_PATCH.fire(curveCFrame, screenPositions, mouseLocation)
    if not _token or next(_reverted) == nil then
        return fireParryInput()
    end
    if not curveCFrame then
        local camera = workspace.CurrentCamera
        curveCFrame = camera and camera.CFrame
    end
    if not curveCFrame then return false end
    local fired = false
    for remote, originalArgs in pairs(_reverted) do
        if type(originalArgs) == "table" and originalArgs[1] ~= nil then
            local token = _tokenize(originalArgs[2])
            local okFire = pcall(function()
                remote:FireServer(
                    originalArgs[1],
                    originalArgs[2],
                    token,
                    0.5,
                    curveCFrame,
                    screenPositions,
                    mouseLocation,
                    false
                )
            end)
            if okFire then fired = true end
        end
    end
    return fired
end

-- ------------------------------------------------------------
-- Ball helpers (same maths as Angeli)
-- ------------------------------------------------------------
local BallHelper = {}
BallHelper.ball = {
    properties = {
        aerodynamic_time = tick(),
        last_warping = tick(),
        lerp_radians = 0,
        curving = tick(),
    }
}

local CurrentTarget
local recentlyPickedTargets = {}

local function pickRandomTarget()
    local alive = workspace:FindFirstChild("Alive")
    if not alive then return nil end
    local function collect(fresh)
        local players = {}
        for _, character in ipairs(alive:GetChildren()) do
            if character.Name ~= LocalPlayer.Name and character.PrimaryPart
            and not (fresh and recentlyPickedTargets[character.Name]) then
                table.insert(players, character)
            end
        end
        return players
    end
    local livingPlayers = collect(true)
    if #livingPlayers == 0 then
        recentlyPickedTargets = {}
        livingPlayers = collect(false)
    end
    if #livingPlayers == 0 then return nil end
    local target = livingPlayers[math.random(1, #livingPlayers)]
    recentlyPickedTargets[target.Name] = true
    CurrentTarget = target
    return target
end

local function selectTargetByMouse()
    local alive = workspace:FindFirstChild("Alive")
    local camera = workspace.CurrentCamera
    if not alive or not camera then return nil end
    local livingPlayers = {}
    for _, character in ipairs(alive:GetChildren()) do
        if character.Name ~= LocalPlayer.Name and character.PrimaryPart then
            table.insert(livingPlayers, character)
        end
    end
    if #livingPlayers == 0 then return nil end
    local okMouse, mousePosition = pcall(function()
        return UserInputService:GetMouseLocation()
    end)
    if not okMouse or not mousePosition then return nil end
    local ray = camera:ScreenPointToRay(mousePosition.X, mousePosition.Y)
    local rayDirection = ray.Direction
    local bestTarget, bestDot = nil, -math.huge
    for _, character in ipairs(livingPlayers) do
        local toCharacter = (character.PrimaryPart.Position - camera.CFrame.Position).Unit
        local dot = rayDirection:Dot(toCharacter)
        if dot > bestDot then
            bestDot = dot
            bestTarget = character
        end
    end
    CurrentTarget = bestTarget
    return bestTarget
end

function BallHelper.get_ball()
    local container = workspace:FindFirstChild("Balls")
    if not container then return nil end
    for _, ball in ipairs(container:GetChildren()) do
        if ball:GetAttribute("realBall") then return ball end
    end
end

function BallHelper.get_balls()
    local balls = {}
    local container = workspace:FindFirstChild("Balls")
    if not container then return balls end
    for _, ball in ipairs(container:GetChildren()) do
        if ball:GetAttribute("realBall") then table.insert(balls, ball) end
    end
    return balls
end

local function linearPredict(a, b, t)
    return a + (b - a) * t
end

function BallHelper.ball_curved()
    local props = BallHelper.ball.properties
    local ball = BallHelper.get_ball()
    if not ball then return false end
    local character = LocalPlayer.Character
    if not character or not character.PrimaryPart then return false end
    local zoomies = ball:FindFirstChild("zoomies")
    if not zoomies then return false end
    local velocity = zoomies.VectorVelocity
    local speed = velocity.Magnitude
    if speed <= 0 then return false end
    local velUnit = velocity.Unit
    local toMe = (character.PrimaryPart.Position - ball.Position).Unit
    local dotProduct = toMe:Dot(velUnit)
    local speedFactor = math.min(speed / 100, 40)
    local accelDir = (velUnit - velocity).Unit
    local crossDot = toMe:Dot(accelDir)
    local dotDifference = dotProduct - crossDot
    local distance = (character.PrimaryPart.Position - ball.Position).Magnitude
    local pingMs = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    local pingThreshold = 0.5 - (pingMs / 1000)
    local timeToImpact = distance / speed - (pingMs / 1000)
    local minDistance = 15 - math.min(distance / 1000, 15) + speedFactor
    local clampedDot = math.clamp(dotProduct, -1, 1)
    local angleRad = math.rad(math.asin(clampedDot))

    props.lerp_radians = linearPredict(props.lerp_radians, angleRad, 0.8)

    if speed > 100 and timeToImpact > pingMs / 10 then
        minDistance = math.max(minDistance - 15, 15)
    end
    if distance < minDistance then return false end
    if dotDifference < pingThreshold then return true end
    if props.lerp_radians < 0.018 then props.last_warping = tick() end
    if (tick() - props.last_warping) < (timeToImpact / 1.5) then return true end
    if (tick() - props.curving) < (timeToImpact / 1.5) then return true end
    return dotProduct < pingThreshold
end

local function ballForParry()
    return BallHelper.get_ball()
end

local function collectScreenPositions()
    local screenPositions = {}
    local camera = workspace.CurrentCamera
    if not camera then return screenPositions end
    local alive = workspace:FindFirstChild("Alive")
    if not alive then return screenPositions end
    for _, character in ipairs(alive:GetChildren()) do
        if character.PrimaryPart then
            local ok, screenPoint = pcall(function()
                return camera:WorldToScreenPoint(character.PrimaryPart.Position)
            end)
            if ok then screenPositions[character.Name] = screenPoint end
        end
    end
    return screenPositions
end

local function currentMouseLocation()
    local okMouse, mousePosition = pcall(function()
        return UserInputService:GetMouseLocation()
    end)
    if okMouse and mousePosition then return {mousePosition.X, mousePosition.Y} end
    local camera = workspace.CurrentCamera
    if camera then return {camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2} end
    return {0, 0}
end

local function getCurveCFrame()
    local camera = workspace.CurrentCamera
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return camera and camera.CFrame or nil end
    if _G.config.random_target then
        local target = CurrentTarget or pickRandomTarget()
        if target and target.PrimaryPart then
            return CFrame.new(hrp.Position, target.PrimaryPart.Position + Vector3.new(0, 1.75, 0))
        end
    end
    local direction = GetDirection()
    if not direction or direction.Magnitude < 0.01 then
        return camera and camera.CFrame or nil
    end
    return CFrame.new(hrp.Position, hrp.Position + direction)
end

local lastParryFire = -math.huge

-- How often ParryFunction may fire. Anti Block Spams slows it down so the
-- client never hammers the parry remote (looks far less bot-like).
local function parryFireGap()
    if getgenv().AntiBlockSpams then return 0.09 end
    return 0.02
end

-- Parries fired in the last ~0.5s. Auto Spam / Animation Fix use it to tell a
-- real parry trade apart from "nothing is happening".
local Parries = 0

-- ------------------------------------------------------------
-- Animation Fix (ported from Angeli): replays the grab/parry animation so the
-- character does not look frozen while parry is being spammed. The old build
-- gated this on a Parries counter that was never incremented, so it never ran.
-- ------------------------------------------------------------
local fixSwordAPI = nil
local fixAnimCache = {}
local fixDefaultAnim = nil
local fixLastPlayed = 0

local function fixFallbackAnimation()
    if fixDefaultAnim then return fixDefaultAnim end
    if not fixSwordAPI then return nil end
    local collection = fixSwordAPI:FindFirstChild("Collection")
    local default = collection and collection:FindFirstChild("Default")
    fixDefaultAnim = default and default:FindFirstChild("GrabParry")
    return fixDefaultAnim
end

-- Resolving the sword animation uses an Invoke that can yield, so it runs on a
-- background thread and only writes into the cache. ParryFunction itself never
-- yields (it is called from a PreSimulation callback).
local function prewarmFixAnimation()
    if not fixSwordAPI then return end
    local char = LocalPlayer.Character
    local sword = char and char:GetAttribute("CurrentlyEquippedSword")
    if not sword or fixAnimCache[sword] ~= nil then return end
    fixAnimCache[sword] = fixFallbackAnimation() or false
    local collection = fixSwordAPI:FindFirstChild("Collection")
    local ok, swordData = pcall(function()
        return ReplicatedStorage.Shared.ReplicatedInstances.Swords.GetSword:Invoke(sword)
    end)
    if ok and type(swordData) == "table" and collection then
        for _, obj in pairs(collection:GetChildren()) do
            if obj.Name == swordData.AnimationType then
                local anim = obj:FindFirstChild("GrabParry") or obj:FindFirstChild("Grab")
                if anim then fixAnimCache[sword] = anim; return end
            end
        end
    end
end

local function getFixParryAnimation()
    local char = LocalPlayer.Character
    local sword = char and char:GetAttribute("CurrentlyEquippedSword")
    local anim = sword and fixAnimCache[sword]
    if anim then return anim end
    return fixFallbackAnimation()
end

local function playParryFix()
    if not getgenv().AnimationFix then return end
    if (os.clock() - fixLastPlayed) < 0.1 then return end
    fixLastPlayed = os.clock()
    pcall(function()
        local char = LocalPlayer.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
        if not animator then return end
        local animation = getFixParryAnimation()
        if not animation then return end
        for _, track in pairs(animator:GetPlayingAnimationTracks()) do
            local name = track.Name
            if name == "GrabParry" or name == "Grab" or name == "SuccessParry" or name == "Success" then
                track:Stop(track:GetAttribute("StopFadeTime") or 0.1)
            end
        end
        local grabTrack = animator:LoadAnimation(animation)
        grabTrack:Play(
            grabTrack:GetAttribute("PlayFadeTime") or 0,
            grabTrack:GetAttribute("PlayWeight") or 1,
            grabTrack:GetAttribute("PlaySpeed") or 1
        )
    end)
end

-- Load the sword API in the background, then keep the parry animation cache
-- warm for the sword the player is currently holding.
task.spawn(function()
    pcall(function()
        local shared = ReplicatedStorage:WaitForChild("Shared", 5)
        if shared then fixSwordAPI = shared:WaitForChild("SwordAPI", 5) end
    end)
    while true do
        pcall(prewarmFixAnimation)
        task.wait(1)
    end
end)

local function ParryFunction()
    local now = os.clock()
    if now - lastParryFire < parryFireGap() then return false end
    lastParryFire = now
    Parries = Parries + 1
    task.delay(0.5, function() if Parries > 0 then Parries = Parries - 1 end end)
    playParryFix()
    if _G.config.random_target and not CurrentTarget then pickRandomTarget() end
    local ok, fired = pcall(function()
        return _PARRY_PATCH.fire(getCurveCFrame(), collectScreenPositions(), currentMouseLocation())
    end)
    return (ok and fired) and true or false
end

function BallHelper.parry()
    return ParryFunction()
end

function BallHelper.closest_player_by_mouse()
    if _G.config.random_target then
        return CurrentTarget or pickRandomTarget()
    end
    return selectTargetByMouse()
end

-- ------------------------------------------------------------
-- Detection state (same remotes as Angeli)
-- ------------------------------------------------------------
local Det = {
    Infinity_Active = false,
    DeathSlash_Active = false,
    TimeHole_Active = false,
    Pull_Active = false,
    Slashes_Active = false,
    Slashes_Count = 0,
    Forcefield_Active = false,
}

pcall(function()
    ReplicatedStorage.Remotes.InfinityBall.OnClientEvent:Connect(function(_, state)
        Det.Infinity_Active = state or false
    end)
end)
pcall(function()
    ReplicatedStorage.Remotes.DeathBall.OnClientEvent:Connect(function(_, state)
        Det.DeathSlash_Active = state or false
    end)
end)
pcall(function()
    ReplicatedStorage.Remotes.PlrPulled.OnClientEvent:Connect(function(a, b)
        if type(a) == "boolean" then Det.Pull_Active = a
        elseif type(b) == "boolean" then Det.Pull_Active = b
        else
            Det.Pull_Active = true
            task.delay(1.5, function() Det.Pull_Active = false end)
        end
    end)
end)
pcall(function()
    ReplicatedStorage.Remotes.PlrPulsed.OnClientEvent:Connect(function(a, b)
        if type(a) == "boolean" then Det.Pull_Active = a
        elseif type(b) == "boolean" then Det.Pull_Active = b
        else
            Det.Pull_Active = true
            task.delay(1.5, function() Det.Pull_Active = false end)
        end
    end)
end)

local DetNet = ReplicatedStorage:FindFirstChild("Packages")
DetNet = DetNet and DetNet:FindFirstChild("_Index")
DetNet = DetNet and DetNet:FindFirstChild("sleitnick_net@0.1.0")
DetNet = DetNet and DetNet:FindFirstChild("net")

if DetNet then
    pcall(function()
        local activate = DetNet:FindFirstChild("RE/TimeHoleActivate")
        local deactivate = DetNet:FindFirstChild("RE/TimeHoleDeactivate")
        if activate then activate.OnClientEvent:Connect(function() Det.TimeHole_Active = true end) end
        if deactivate then deactivate.OnClientEvent:Connect(function() Det.TimeHole_Active = false end) end
    end)
    pcall(function()
        local activate = DetNet:FindFirstChild("RE/SlashesOfFuryActivate")
        local ended = DetNet:FindFirstChild("RE/SlashesOfFuryEnd")
        local parry = DetNet:FindFirstChild("RE/SlashesOfFuryParry")
        local caught = DetNet:FindFirstChild("RE/SlashesOfFuryCatch")
        if activate then activate.OnClientEvent:Connect(function()
            Det.Slashes_Active = true
            Det.Slashes_Count = 0
        end) end
        if ended then ended.OnClientEvent:Connect(function()
            Det.Slashes_Active = false
            Det.Slashes_Count = 0
        end) end
        if parry then parry.OnClientEvent:Connect(function() Det.Slashes_Count = Det.Slashes_Count + 1 end) end
        if caught then caught.OnClientEvent:Connect(function()
            task.spawn(function()
                while Det.Slashes_Active and Det.Slashes_Count < 36 do
                    ParryFunction()
                    task.wait(0.05)
                end
            end)
        end) end
    end)
end

pcall(function()
    local function watchForcefield(character)
        character.AttributeChanged:Connect(function(attribute)
            if attribute == "PassiveLock_ForceField" then
                Det.Forcefield_Active = character:GetAttribute("PassiveLock_ForceField") == true
            end
        end)
    end
    if LocalPlayer.Character then watchForcefield(LocalPlayer.Character) end
    LocalPlayer.CharacterAdded:Connect(function(character)
        Det.Forcefield_Active = false
        watchForcefield(character)
    end)
end)
-- ============================================================
local function get_character() return LocalPlayer.Character end
local function get_humanoid_root_part()
    local char = get_character()
    return char and char:FindFirstChild("HumanoidRootPart")
end
local function get_humanoid()
    local char = get_character()
    return char and char:FindFirstChild("Humanoid")
end
local function get_ball()
    for _, ball in pairs(workspace.Balls:GetChildren()) do
        if ball:GetAttribute("realBall") then return ball end
    end
end

-- ============================================================
-- 7. AI PLAY
-- ============================================================
local AiPlay = false
local AiPlayType = "Normal"
local AiPlaySpeed = 200

local function ai_play()
    if not AiPlay then
        local humanoid = get_humanoid()
        if humanoid then humanoid.WalkSpeed = 36 end
        return
    end
    local player = LocalPlayer
    local character = player.Character
    if not character or (workspace:FindFirstChild("Dead") and workspace.Dead:FindFirstChild(player.Name)) then return end
    local ball = get_ball()
    local humanoidRootPart = get_humanoid_root_part()
    local humanoid = get_humanoid()
    if not ball or not humanoidRootPart or not humanoid then return end
    if AiPlayType == "Hacker" then humanoid.WalkSpeed = AiPlaySpeed else humanoid.WalkSpeed = 36 end
    local ballPosition = ball.Position
    local playerPosition = humanoidRootPart.Position
    local distanceFromBall = (ballPosition - playerPosition).Magnitude

    local function is_path_clear(destination)
        local direction = (destination - playerPosition).Unit
        local ray = Ray.new(playerPosition, direction * 5)
        local part = workspace:FindPartOnRay(ray, character)
        return not part
    end

    if AiPlayType == "Normal" then
        if distanceFromBall < 60 then
            local directionAwayFromBall = (playerPosition - ballPosition).Unit
            local targetPosition = playerPosition + directionAwayFromBall * math.random(24, 36)
            if is_path_clear(targetPosition) then humanoid:MoveTo(targetPosition) end
        elseif math.random(1, 100) <= 6 then
            local offset = Vector3.new(math.random(-14, 14), 0, math.random(-14, 14))
            local targetPosition = playerPosition + offset
            if is_path_clear(targetPosition) then humanoid:MoveTo(targetPosition) end
        end
    elseif AiPlayType == "Advanced" then
        if distanceFromBall < 80 then
            local chase = (ballPosition - playerPosition).Unit
            local offset = Vector3.new(math.random(-6, 6), 0, math.random(-6, 6))
            local targetPosition = playerPosition + chase * 30 + offset
            if is_path_clear(targetPosition) then humanoid:MoveTo(targetPosition) end
        elseif math.random(1, 100) <= 12 then
            local offset = Vector3.new(math.random(-24, 24), 0, math.random(-24, 24))
            local targetPosition = playerPosition + offset
            if is_path_clear(targetPosition) then humanoid:MoveTo(targetPosition) end
        end
    elseif AiPlayType == "Hacker" then
        if distanceFromBall < 200 then
            local targetPosition = ballPosition + Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
            if is_path_clear(targetPosition) then humanoid:MoveTo(targetPosition) end
        end
        for _, enemy in pairs(workspace:FindFirstChild("Alive") and workspace.Alive:GetChildren() or {}) do
            if enemy:IsA("Model") and enemy ~= character and enemy:FindFirstChild("HumanoidRootPart") then
                local enemyHRP = enemy.HumanoidRootPart
                local distance = (enemyHRP.Position - ballPosition).Magnitude
                if distance <= 15 then
                    humanoidRootPart.CFrame = CFrame.new(enemyHRP.Position + Vector3.new(math.random(-3, 3), 0, math.random(-3, 3)))
                    break
                end
            end
        end
    end
end

RunService.RenderStepped:Connect(function() ai_play() end)

-- ============================================================
-- 8. AUTO WALK / PLAYER SAFETY / TELEPORT / JUMP / FOCUS
-- ============================================================
local AutoWalk, PlayerSaftey, RandomTeleports, AutoDoubleJump, ClosestPlayer_var
local AutoWalkDistanceX, AutoWalkDistanceZ = 10, 10
local PlayerSaftey_Distance = 10
local TeleportDistanceX, TeleportDistanceZ = 10, 10

spawn(function()
    while task.wait() do
        if AutoWalk then
            pcall(function()
                local player = LocalPlayer
                local character = player.Character
                if character and character.Parent and character.Parent.Name ~= "Dead" then
                    local targetPosition
                    for _, v in pairs(workspace.Balls:GetChildren()) do
                        if v:IsA("Part") then
                            local part, speed = getSpeed(v)
                            if part and speed and speed > 5 then
                                targetPosition = part.Position + Vector3.new(AutoWalkDistanceX, 0, AutoWalkDistanceZ)
                                break
                            end
                        end
                    end
                    if not targetPosition then
                        for _, p in pairs(workspace:FindFirstChild("Alive") and workspace.Alive:GetChildren() or {}) do
                            if p ~= character and p:FindFirstChild("HumanoidRootPart") then
                                targetPosition = p.HumanoidRootPart.Position + Vector3.new(AutoWalkDistanceX, 0, AutoWalkDistanceZ)
                                break
                            end
                        end
                    end
                    if targetPosition then
                        local hum = character:FindFirstChildOfClass("Humanoid")
                        if hum then hum:MoveTo(targetPosition) end
                    end
                end
            end)
        end
        if PlayerSaftey then
            pcall(function()
                local character = LocalPlayer.Character
                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                if hrp and humanoid then
                    local closest = GetClosestPlayer()
                    local target = closest and closest:FindFirstChild("HumanoidRootPart")
                    if target then
                        local offset = hrp.Position - target.Position
                        local distance = offset.Magnitude
                        if distance > 0.01 and distance < PlayerSaftey_Distance then
                            humanoid:MoveTo(hrp.Position + offset.Unit * (PlayerSaftey_Distance + 5))
                        end
                    end
                end
            end)
        end
        if AutoDoubleJump then
            local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                if humanoid:GetState() == Enum.HumanoidStateType.Freefall or humanoid:GetState() == Enum.HumanoidStateType.Jumping then
                    task.wait(0.1)
                else
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    task.wait(0.3)
                end
            end
        end
        if ClosestPlayer_var then
            pcall(function()
                local character = LocalPlayer.Character
                if character and character.Parent.Name ~= "Dead" then
                    local cp = GetClosestPlayer()
                    if cp and cp:FindFirstChild("Head") then
                        Camera.CFrame = CFrame.new(Camera.CFrame.Position, cp.Head.Position)
                    end
                end
            end)
        end
        if RandomTeleports then
            pcall(function()
                local character = LocalPlayer.Character
                if character and character.Parent.Name ~= "Dead" then
                    for _, v in pairs(workspace.Balls:GetChildren()) do
                        if v:IsA("Part") then
                            local part, speed = getSpeed(v)
                            if part and speed then
                                character.HumanoidRootPart.CFrame = part.CFrame * CFrame.new(TeleportDistanceX, 0, TeleportDistanceZ)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- ============================================================
-- 9. BLADE BALL REMOTES (reconnect to game)
-- ============================================================
local Balls = workspace:WaitForChild('Balls')
local Runtime = workspace:FindFirstChild("Runtime")
local Debris = game:GetService('Debris')
local ContextActionService = game:GetService('ContextActionService')
local Phantom = false
local Parried = false
local LobbyAP_Speed_Divisor_Multiplier = 1.1
local Infinity = false
local Training_Parried = false
local Grab_Parry = nil

local function BlockMovement() return Enum.ContextActionResult.Sink end

pcall(function()
    ReplicatedStorage.Remotes.InfinityBall.OnClientEvent:Connect(function(a, b)
        Infinity = b and true or false
    end)
end)

-- Remember which key the game has block bound to (used by the input fallback).
getgenv().TORT_ParryKey = getgenv().TORT_ParryKey or Enum.KeyCode.F

pcall(function()
    if type(getconnections) ~= "function" then return end
    local hotbar = LocalPlayer:WaitForChild("PlayerGui", 5)
    hotbar = hotbar and hotbar:WaitForChild("Hotbar", 5)
    if not hotbar then return end
    local blockButton = hotbar:FindFirstChild("Block")
    if not blockButton then return end
    local okConn, connections = pcall(getconnections, blockButton.Activated)
    if not okConn or type(connections) ~= "table" then return end
    for _, connection in pairs(connections) do
        if connection and typeof(connection) == "table" and connection.Function and type(iscclosure) == "function" and not iscclosure(connection.Function) then
            local okUpvalues, upvalues = pcall(getupvalues, connection.Function)
            if okUpvalues and type(upvalues) == "table" then
                for _, value in pairs(upvalues) do
                    if type(value) == "function" and type(getupvalue) == "function" then
                        local okKey, result = pcall(function()
                            return getupvalue(getupvalue(value, 2), 17)
                        end)
                        if okKey and typeof(result) == "EnumItem" then
                            getgenv().TORT_ParryKey = result
                            break
                        end
                    end
                end
            end
        end
    end
end)

-- ============================================================
-- 10. AUTO PARRY / SPAM / LOBBY AP
-- ============================================================
local Connections_Manager = {}

-- Forward declarations (defined further down, used by the auto parry loop)
local cooldownProtection, AutoAbility

-- Is the ball locked on to us? Blade Ball stores the target as the player name,
-- but some builds use tostring(player) or the display name.
local function ballTargetsMe(ball)
    if not ball then return false end
    local target = ball:GetAttribute("target")
    if target == nil then return false end
    return target == LocalPlayer.Name
        or target == tostring(LocalPlayer)
        or target == LocalPlayer.DisplayName
end

-- Detection radius used by Auto Spam (same maths as Angeli).
local function spamDetectionRadius(speed)
    local pingMs = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    return math.clamp(pingMs / 10, 1, 16) + math.min(speed / 6, 95)
end

-- ------------------------------------------------------------
-- Ball approach maths (shared by Auto Parry, Auto Spam, Manual Spam)
-- closing > 0 means the ball is flying towards us, timeToImpact is how long
-- until it reaches us (math.huge when it is not closing in).
-- ------------------------------------------------------------
local function ballApproachInfo(ball, hrp)
    if not ball or not hrp then return nil end
    local zoomies = ball:FindFirstChild("zoomies")
    if not zoomies then return nil end
    local velocity = zoomies.VectorVelocity
    local speed = velocity.Magnitude
    local toMe = hrp.Position - ball.Position
    local distance = toMe.Magnitude
    if distance < 0.01 then distance = 0.01 end
    local closing = velocity:Dot(toMe / distance)
    local timeToImpact = math.huge
    if speed > 0.01 and closing > 0.01 then
        timeToImpact = distance / closing
    end
    return speed, distance, closing, timeToImpact
end

local function parryPingSeconds()
    return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
end

-- Seconds before impact at which Auto Parry fires. Higher = parries earlier.
local function parryReactionWindow(speed)
    local window = tonumber(getgenv().AutoParryWindow) or 0.15
    window = window + parryPingSeconds() * 0.5
    if getgenv().ImproveAccuracy and getgenv().AITORT ~= false then
        window = window + math.min((speed or 0) * 0.0004, 0.06)
    end
    if getgenv().RandomParryAccuracy then
        window = window * (0.85 + math.random() * 0.3)
    end
    if getgenv().bypass_limits_Enabled then window = math.max(window, 5) end
    return window
end

-- Detections shared by Auto Parry and Auto Spam. Returns true when a detection
-- says "do not parry right now".
local function parryBlockedByDetection(flags, character)
    if flags.InfinityDetection and Det.Infinity_Active then return true end
    if flags.DeathSlashDetection and Det.DeathSlash_Active then return true end
    if flags.TimeHoleDetection and Det.TimeHole_Active then return true end
    if flags.AutoTelekinesis and Det.Pull_Active then return true end
    if flags.SlashOfFuryDetection and Det.Slashes_Active then return true end
    if flags.ForcefieldDetection and Det.Forcefield_Active then return true end
    if character and character.PrimaryPart and character.PrimaryPart:FindFirstChild("SingularityCape") then
        return true
    end
    return false
end

local AutoParryLastFire = 0

local function StartAutoParry()
    if Connections_Manager['Auto Parry'] then return end
    Connections_Manager['Auto Parry'] = RunService.PreSimulation:Connect(function()
        if _G.triggerbot then return end
        local character = LocalPlayer.Character
        local hrp = character and character.PrimaryPart
        if not hrp then return end
        local flags = getgenv()
        local props = BallHelper.ball.properties

        -- Pick the incoming ball that will reach us first.
        local bestBall, bestTTI, bestSpeed, bestDistance, bestClosing
        for _, ball in ipairs(BallHelper.get_balls()) do
            if ball:FindFirstChild("zoomies") then
                local mine = ballTargetsMe(ball)
                local strayBlock = (not mine) and flags.AutoBlockSpams
                if mine or strayBlock then
                    local speed, distance, closing, tti = ballApproachInfo(ball, hrp)
                    if speed and tti < (bestTTI or math.huge) then
                        bestBall, bestTTI, bestSpeed, bestDistance, bestClosing = ball, tti, speed, distance, closing
                    end
                end
            end
        end
        if not bestBall then return end

        if parryBlockedByDetection(flags, character) then return end

        -- Tornado / Aerodynamic Slash guard (ball spins, parry would be wasted).
        if bestBall:FindFirstChild("AeroDynamicSlashVFX") then
            Debris:AddItem(bestBall.AeroDynamicSlashVFX, 0)
            props.aerodynamic_time = tick()
        end
        if Runtime and Runtime:FindFirstChild("Tornado") then
            local tornadoTime = Runtime.Tornado:GetAttribute("TornadoTime") or 1
            if (tick() - props.aerodynamic_time) < tornadoTime + 0.314159 then return end
        end

        local targetsMe = ballTargetsMe(bestBall)
        if not targetsMe then
            -- Auto Block Spams: the ball is going to someone else, but it is
            -- about to clip straight through us, so block it. Only accept fast
            -- balls that are genuinely about to hit us, so we stop "randomly"
            -- swinging at balls that were never aimed at us.
            if not bestClosing or bestClosing <= 0.01 then return end
            if (bestDistance or math.huge) > 12 then return end
            if (bestSpeed or 0) < 40 then return end
        else
            local window = parryReactionWindow(bestSpeed)
            if BallHelper.ball_curved() then window = window * 1.5 + 0.08 end
            if bestTTI > window then return end
        end

        local gap = 0.05
        if flags.AntiBlockSpams then gap = 0.09 end
        if os.clock() - AutoParryLastFire < gap then return end
        AutoParryLastFire = os.clock()

        if flags.CooldownProtection and cooldownProtection and cooldownProtection() then return end
        if flags.AutoAbility and AutoAbility and AutoAbility() then return end

        Parried = true
        ParryFunction()
    end)
end

local AutoSpamLastFire = 0

local function StartAutoSpam()
    if Connections_Manager['Auto Spam'] then return end
    Connections_Manager['Auto Spam'] = RunService.PreSimulation:Connect(function()
        local flags = getgenv()
        local character = LocalPlayer.Character
        local hrp = character and character.PrimaryPart
        if not hrp then return end

        local ball = BallHelper.get_ball()
        if not ball then return end

        local target = ball:GetAttribute("target")
        if not target then return end
        if target ~= LocalPlayer.Name and flags.SpamTargetOnly ~= false then return end

        local speed, distance, closing, tti = ballApproachInfo(ball, hrp)
        if not speed or speed <= 0 then return end
        if distance > 300 then return end
        -- The whole point: only spam while the ball is actually coming at us.
        if not closing or closing <= 0.01 then return end
        if character:GetAttribute("Pulsed") then return end

        local pingSec = parryPingSeconds()
        local kps = math.clamp(tonumber(flags.AutoSpamKPS) or 20, 1, 60)
        -- Already parrying a lot (ball is bouncing on us)? Back off instead of
        -- piling even more parries on top, which is what looked like "spam".
        if Parries >= 6 then kps = math.min(kps, 12) end
        if os.clock() - AutoSpamLastFire < math.max(1 / kps, pingSec) then return end

        local window = tonumber(flags.AutoSpamWindow) or 0.35
        window = window + pingSec
        if flags.ImproveAutoSpam and flags.AITORT ~= false then window = window + 0.1 end
        if BallHelper.ball_curved() then window = window * 1.4 end
        if flags.bypass_limits_Enabled then window = math.max(window, 5) end
        if tti > window then return end

        if parryBlockedByDetection(flags, character) then return end

        AutoSpamLastFire = os.clock()
        ParryFunction()
    end)
end

-- Manual Spam: the key/hold driven parry. Still gated on the ball being locked
-- on us (or at least close and approaching) so holding the key cannot fire at
-- an empty arena.
local function StartManualSpam()
    if Connections_Manager['Manual Spam'] then return end
    getgenv().ManualSpamKey = getgenv().ManualSpamKey or Enum.KeyCode.E
    local lastManualFire = 0
    Connections_Manager['Manual Spam'] = RunService.PreSimulation:Connect(function()
        local flags = getgenv()
        if not flags.ManualSpamActive then return end

        local kps = math.clamp(tonumber(flags.ManualSpamKPS) or 25, 1, 100)
        if os.clock() - lastManualFire < 1 / kps then return end

        local character = LocalPlayer.Character
        local hrp = character and character.PrimaryPart
        if not hrp then return end

        local ball = BallHelper.get_ball()
        if not ball then return end

        if flags.ManualSpamTargetOnly ~= false then
            if not ballTargetsMe(ball) then return end
            local limit = tonumber(flags.ManualSpamDistance) or 60
            if (hrp.Position - ball.Position).Magnitude > limit then return end
        elseif flags.ManualSpamNeedsBall ~= false then
            local speed, distance = ballApproachInfo(ball, hrp)
            if not speed then return end
            if distance > spamDetectionRadius(speed) then return end
        end

        lastManualFire = os.clock()
        ParryFunction()
    end)
end

-- ============================================================
-- 10.1 MOBILE MANUAL SPAM UI (touch friendly floating panel)
-- ============================================================
local MobileSpam = {gui = nil, holding = false}

local function mobileParent()
    return (gethui and gethui()) or game:GetService("CoreGui")
end

local function mobileCorner(object, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = object
    return corner
end

local function mobileButton(parent, text, y, height, color)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -14, 0, height)
    button.Position = UDim2.new(0, 7, 0, y)
    button.BackgroundColor3 = color
    button.BorderSizePixel = 0
    button.AutoButtonColor = true
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Text = text
    button.Parent = parent
    mobileCorner(button, 8)
    return button
end

local function isTouch(input)
    return input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1
end

local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPosition
    handle.InputBegan:Connect(function(input)
        if not isTouch(input) then return end
        dragging = true
        dragStart = input.Position
        startPosition = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end)
    handle.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.Touch
        and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPosition.X.Scale, startPosition.X.Offset + delta.X,
            startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
    end)
end

function MobileSpam.create()
    if MobileSpam.gui and MobileSpam.gui.Parent then return MobileSpam.gui end

    local gui = Instance.new("ScreenGui")
    gui.Name = "TORT_MobileSpam"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = mobileParent()
    MobileSpam.gui = gui

    local accent = Color3.fromRGB(99, 102, 241)
    local idle = Color3.fromRGB(45, 45, 52)
    local good = Color3.fromRGB(34, 197, 94)

    local opener = Instance.new("TextButton")
    opener.Name = "Opener"
    opener.Size = UDim2.new(0, 54, 0, 54)
    opener.Position = UDim2.new(0, 14, 0.4, 0)
    opener.BackgroundColor3 = accent
    opener.BorderSizePixel = 0
    opener.Font = Enum.Font.GothamBold
    opener.TextSize = 11
    opener.TextColor3 = Color3.fromRGB(255, 255, 255)
    opener.Text = "TORT\nSPAM"
    opener.Parent = gui
    mobileCorner(opener, 27)

    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.new(0, 176, 0, 248)
    panel.Position = UDim2.new(0, 78, 0.34, 0)
    panel.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
    panel.BackgroundTransparency = 0.08
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Active = true
    panel.Parent = gui
    mobileCorner(panel, 12)
    local panelStroke = Instance.new("UIStroke")
    panelStroke.Color = accent
    panelStroke.Thickness = 1
    panelStroke.Parent = panel

    local titleBar = Instance.new("TextLabel")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, -14, 0, 22)
    titleBar.Position = UDim2.new(0, 7, 0, 4)
    titleBar.BackgroundTransparency = 1
    titleBar.Font = Enum.Font.GothamBold
    titleBar.TextSize = 12
    titleBar.TextColor3 = Color3.fromRGB(245, 245, 245)
    titleBar.TextXAlignment = Enum.TextXAlignment.Left
    titleBar.Text = "TORT MANUAL SPAM  (drag)"
    titleBar.Parent = panel
    makeDraggable(panel, titleBar)

    local parryButton = mobileButton(panel, "PARRY", 30, 44, accent)
    local holdButton = mobileButton(panel, "HOLD SPAM", 80, 44, idle)
    local manualButton = mobileButton(panel, "MANUAL: OFF", 130, 34, idle)
    local autoButton = mobileButton(panel, "AUTO PARRY: ON", 170, 34, good)
    local lockButton = mobileButton(panel, "SPAM: TARGETED", 210, 30, good)

    local function stopHolding()
        MobileSpam.holding = false
        holdButton.BackgroundColor3 = idle
    end

    local function refreshManual()
        local active = getgenv().ManualSpamActive and true or false
        manualButton.Text = active and "MANUAL: ON" or "MANUAL: OFF"
        manualButton.BackgroundColor3 = active and good or idle
    end

    local function refreshAuto()
        local active = Connections_Manager['Auto Parry'] ~= nil
        autoButton.Text = active and "AUTO PARRY: ON" or "AUTO PARRY: OFF"
        autoButton.BackgroundColor3 = active and good or idle
    end

    opener.InputBegan:Connect(function(input)
        if not isTouch(input) then return end
        panel.Visible = not panel.Visible
        if panel.Visible then
            refreshManual()
            refreshAuto()
        else
            stopHolding()
        end
    end)

    parryButton.InputBegan:Connect(function(input)
        if not isTouch(input) then return end
        ParryFunction()
    end)

    holdButton.InputBegan:Connect(function(input)
        if not isTouch(input) then return end
        if not getgenv().ManualSpamTargetOnly then
            local ball = BallHelper.get_ball()
            if not ballTargetsMe(ball) then
                LibraryNotify:MakeNotify({Title = "TORT FREE:", Description = "Hold Spam", Content = "Ball is not locked on you.", Time = 0.5, Delay = 3})
                return
            end
        end
        MobileSpam.holding = true
        holdButton.BackgroundColor3 = accent
        task.spawn(function()
            local lastRelease = os.clock()
            while MobileSpam.holding do
                ParryFunction()
                task.wait(0.03)
                if os.clock() - lastRelease > 1.5 then
                    -- no touch updates for 1.5s: assume the finger was lifted
                    stopHolding()
                    break
                end
                lastRelease = os.clock()
            end
        end)
    end)
    holdButton.InputEnded:Connect(stopHolding)

    local holdReleaseConnection = UserInputService.InputEnded:Connect(function(input)
        if MobileSpam.holding and isTouch(input) then stopHolding() end
    end)

    manualButton.InputBegan:Connect(function(input)
        if not isTouch(input) then return end
        getgenv().ManualSpamEnabled = true
        getgenv().ManualSpamKey = getgenv().ManualSpamKey or Enum.KeyCode.E
        StartManualSpam()
        getgenv().ManualSpamActive = not getgenv().ManualSpamActive
        refreshManual()
        LibraryNotify:MakeNotify({
            Title = "TORT FREE:",
            Description = "Manual Spam",
            Content = getgenv().ManualSpamActive and "Manual spam ON." or "Manual spam OFF.",
            Time = 0.5,
            Delay = 5
        })
    end)

    autoButton.InputBegan:Connect(function(input)
        if not isTouch(input) then return end
        if Connections_Manager['Auto Parry'] then
            Connections_Manager['Auto Parry']:Disconnect()
            Connections_Manager['Auto Parry'] = nil
        else
            StartAutoParry()
        end
        refreshAuto()
    end)

    lockButton.InputBegan:Connect(function(input)
        if not isTouch(input) then return end
        local targetedOnly = not (getgenv().ManualSpamTargetOnly ~= false)
        getgenv().ManualSpamTargetOnly = not targetedOnly
        getgenv().SpamTargetOnly = not targetedOnly
        lockButton.Text = targetedOnly and "SPAM: ANY BALL" or "SPAM: TARGETED"
        lockButton.BackgroundColor3 = targetedOnly and idle or good
    end)

    MobileSpam.connections = {holdReleaseConnection}

    return gui
end

function MobileSpam.destroy()
    MobileSpam.holding = false
    if MobileSpam.connections then
        for _, connection in ipairs(MobileSpam.connections) do
            pcall(function() connection:Disconnect() end)
        end
        MobileSpam.connections = nil
    end
    if MobileSpam.gui then
        MobileSpam.gui:Destroy()
        MobileSpam.gui = nil
    end
end

function MobileSpam.show()
    MobileSpam.create()
    local gui = MobileSpam.gui
    if not gui then return end
    local panel = gui:FindFirstChild("Panel")
    if panel then panel.Visible = true end
end

getgenv().MobileSpam = MobileSpam

local function StartLobbyAP()
    Connections_Manager['Lobby AP'] = RunService.Heartbeat:Connect(function()
        local training = workspace:FindFirstChild("TrainingBalls")
        if not training then return end
        for _, b in ipairs(training:GetChildren()) do
            if b:GetAttribute("realBall") then
                local Zoomies = b:FindFirstChild('zoomies')
                if Zoomies then
                    local Ball_Target = b:GetAttribute('target')
                    local char = LocalPlayer.Character
                    if Ball_Target == tostring(LocalPlayer) and char and char.PrimaryPart then
                        local Speed = Zoomies.VectorVelocity.Magnitude
                        local Distance = (char.PrimaryPart.Position - b.Position).Magnitude
                        local Ping = game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue() / 10
                        local cappedSpeedDiff = math.min(math.max(Speed - 9.5, 0), 650)
                        local base = 2.4 + cappedSpeedDiff * 0.002
                        local lobbyMultiplier = LobbyAP_Speed_Divisor_Multiplier
                        if getgenv().LobbyAPRandomParryAccuracyEnabled then
                            lobbyMultiplier = lobbyMultiplier * (0.7 + (math.random(1, 100) - 1) * (0.35 / 99))
                        end
                        local acc = Ping + math.max(Speed / (base * lobbyMultiplier), 9.5)
                        if getgenv().bypass_limits_Enabled then acc = math.max(acc, 999) end
                        if Distance <= acc then
                            ParryFunction()
                            Training_Parried = true
                        end
                    end
                end
            end
        end
    end)
end

-- ============================================================
-- 11. DETECTION: SLASH OF FURY / PHANTOM / TORNADO
-- ============================================================
Balls.ChildAdded:Connect(function(Value)
    Value.ChildAdded:Connect(function(Child)
        if getgenv().SlashOfFuryDetection and Child.Name == 'ComboCounter' then
            local Sof_Label = Child:FindFirstChildOfClass('TextLabel')
            if Sof_Label then
                repeat
                    local Slashes_Counter = tonumber(Sof_Label.Text)
                    if Slashes_Counter and Slashes_Counter < 32 then
                        ParryFunction()
                    end
                    task.wait()
                until not Sof_Label.Parent or not Sof_Label
            end
        end
    end)
end)

-- Death Slash / Time Hole / Auto Telekinesis detection.
-- These toggles used to change a variable nobody read, so they did nothing.
local VFX_DETECTIONS = {
    {Key = "DeathSlashDetection", Patterns = {"deathslash", "death_slash", "deathslashattack"}},
    {Key = "TimeHoleDetection", Patterns = {"timehole", "time_hole"}},
    {Key = "AutoTelekinesis", Patterns = {"telekinesis", "telekinesisvfx"}},
}

task.spawn(function()
    while task.wait(0.05) do
        local anyEnabled = false
        for _, detection in ipairs(VFX_DETECTIONS) do
            if getgenv()[detection.Key] then anyEnabled = true; break end
        end
        if anyEnabled then
            pcall(function()
                local folders = {}
                if Runtime then table.insert(folders, Runtime) end
                local balls = workspace:FindFirstChild("Balls")
                if balls then table.insert(folders, balls) end
                local character = LocalPlayer.Character
                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                for _, detection in ipairs(VFX_DETECTIONS) do
                    if getgenv()[detection.Key] then
                        local matched = false
                        for _, folder in ipairs(folders) do
                            for _, object in ipairs(folder:GetDescendants()) do
                                local name = string.lower(object.Name)
                                for _, pattern in ipairs(detection.Patterns) do
                                    if string.find(name, pattern, 1, true) then matched = true; break end
                                end
                                if matched then break end
                            end
                            if matched then break end
                        end
                        if matched and hrp then
                            local ball = ballForParry()
                            local closeEnough = ball and (ball.Position - hrp.Position).Magnitude <= 120
                            if closeEnough or (ball and ball:GetAttribute("target") == tostring(LocalPlayer)) then
                                ParryFunction()
                            end
                        end
                    end
                end
            end)
        end
    end
end)

if Runtime then
    Runtime.ChildAdded:Connect(function(Object)
        local Name = Object.Name
        if getgenv().PhantomV2Detection then
            if Name == "maxTransmission" or Name == "transmissionpart" then
                local Weld = Object:FindFirstChildWhichIsA("WeldConstraint")
                if Weld then
                    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                    if Character and Weld.Part1 == Character.HumanoidRootPart then
                        local CurrentBall = nil
                        for _, b in ipairs(Balls:GetChildren()) do
                            if b:FindFirstChild("ff") then CurrentBall = b; break end
                        end
                        Weld:Destroy()
                        if CurrentBall then
                            local FocusConnection
                            FocusConnection = RunService.RenderStepped:Connect(function()
                                local Highlighted = CurrentBall:GetAttribute("highlighted")
                                if Highlighted == true then
                                    LocalPlayer.Character.Humanoid.WalkSpeed = 36
                                    local hrp = Character:FindFirstChild("HumanoidRootPart")
                                    if hrp then
                                        local PlayerToBall = (CurrentBall.Position - hrp.Position).Unit
                                        LocalPlayer.Character.Humanoid:Move(PlayerToBall, false)
                                    end
                                elseif Highlighted == false then
                                    FocusConnection:Disconnect()
                                    LocalPlayer.Character.Humanoid.WalkSpeed = 10
                                    LocalPlayer.Character.Humanoid:Move(Vector3.new(0, 0, 0), false)
                                    task.delay(3, function() LocalPlayer.Character.Humanoid.WalkSpeed = 36 end)
                                    CurrentBall = nil
                                end
                            end)
                            task.delay(3, function()
                                if FocusConnection and FocusConnection.Connected then
                                    FocusConnection:Disconnect()
                                    LocalPlayer.Character.Humanoid:Move(Vector3.new(0, 0, 0), false)
                                    LocalPlayer.Character.Humanoid.WalkSpeed = 36
                                    CurrentBall = nil
                                end
                            end)
                        end
                    end
                end
            end
        end
    end)
end

-- ============================================================
-- 12. COOLDOWN PROTECTION / AUTO ABILITY
-- ============================================================
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local Hotbar = playerGui:WaitForChild("Hotbar")
local ParryCD = Hotbar.Block.UIGradient
local AbilityCD = Hotbar.Ability.UIGradient

local function isCooldownInEffect1(u) return u.Offset.Y < 0.4 end
local function isCooldownInEffect2(u) return u.Offset.Y == 0.5 end

cooldownProtection = function()
    if isCooldownInEffect1(ParryCD) then
        ReplicatedStorage.Remotes.AbilityButtonPress:Fire()
        return true
    end
    return false
end

AutoAbility = function()
    if isCooldownInEffect2(AbilityCD) then
        local abilities = LocalPlayer.Character:FindFirstChild("Abilities")
        if abilities then
            for _, name in ipairs({"Raging Deflection", "Rapture", "Calming Deflection", "Aerodynamic Slash", "Fracture", "Death Slash"}) do
                local ability = abilities:FindFirstChild(name)
                if ability and ability.Enabled then
                    Parried = true
                    ReplicatedStorage.Remotes.AbilityButtonPress:Fire()
                    task.wait(2.432)
                    ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("DeathSlashShootActivation"):FireServer(true)
                    return true
                end
            end
        end
    end
    return false
end

-- ============================================================
-- 13. VISUALIZER / TRAILS / VIEW BALL / ROTATE / FOLLOW
-- ============================================================
local sphere
local currentSize = Vector3.new(5, 5, 5)

local function getBall()
    for _, ball in workspace.Balls:GetChildren() do
        if ball:GetAttribute("realBall") then return ball end
    end
end

local function createSphere()
    if sphere and sphere.Parent then return end
    sphere = Instance.new("Part")
    sphere.Shape = Enum.PartType.Ball
    sphere.Anchored = true
    sphere.CanCollide = false
    sphere.Material = Enum.Material.ForceField
    sphere.Color = Color3.fromRGB(0, 255, 0)
    sphere.Transparency = 0.5
    sphere.Size = currentSize
    sphere.Name = "VisualizerSphere"
    sphere.Parent = workspace
end

local function removeSphere()
    if sphere then sphere:Destroy(); sphere = nil end
end

local function updateSphere()
    local ball = getBall()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if sphere and ball and hrp then
        local distance = (hrp.Position - ball.Position).Magnitude
        local targetScale = math.clamp(35 - distance, 5, 30)
        currentSize = currentSize:Lerp(Vector3.new(targetScale, targetScale, targetScale), 0.1)
        sphere.Size = currentSize
        sphere.Position = hrp.Position
        if distance > 20 then sphere.Color = Color3.fromRGB(0, 255, 0)
        elseif distance > 10 then sphere.Color = Color3.fromRGB(255, 255, 0)
        else sphere.Color = Color3.fromRGB(255, 0, 0) end
    end
end

RunService.RenderStepped:Connect(function()
    if getgenv().VisualizerBallEnabled then
        pcall(createSphere)
        pcall(updateSphere)
    end
end)

local ball_Trail_Enabled = false
local player_Trail_Enabled = false

RunService.Heartbeat:Connect(function()
    if player_Trail_Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local rootPart = LocalPlayer.Character.PrimaryPart or LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not rootPart:FindFirstChild("TORT_fx") then
            local trail = game:GetObjects("rbxassetid://17483658369")[1]
            trail.Name = "TORT_fx"
            local A0 = Instance.new("Attachment"); A0.Position = Vector3.new(0, -2.411, 0); A0.Parent = rootPart
            local A1 = Instance.new("Attachment"); A1.Position = Vector3.new(0, 2.504, 0); A1.Parent = rootPart
            trail.Attachment0 = A0; trail.Attachment1 = A1; trail.Parent = rootPart
        end
    elseif LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local rootPart = LocalPlayer.Character.PrimaryPart or LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local existingTrail = rootPart:FindFirstChild("TORT_fx")
        if existingTrail then existingTrail:Destroy() end
        for _, att in ipairs(rootPart:GetChildren()) do
            if att:IsA("Attachment") then att:Destroy() end
        end
    end
    if ball_Trail_Enabled then
        for _, ball in workspace:FindFirstChild("Balls"):GetChildren() do
            if ball:GetAttribute("realBall") and not ball:FindFirstChild("TORT_fx") then
                local trail = game:GetObjects("rbxassetid://17483658369")[1]
                trail.Name = "TORT_fx"
                local A0 = Instance.new("Attachment"); A0.Position = Vector3.new(0, -2.411, 0); A0.Parent = ball
                local A1 = Instance.new("Attachment"); A1.Position = Vector3.new(0, 2.504, 0); A1.Parent = ball
                trail.Attachment0 = A0; trail.Attachment1 = A1; trail.Parent = ball
            end
        end
    else
        for _, ball in workspace:FindFirstChild("Balls"):GetChildren() do
            if ball:GetAttribute("realBall") then
                local existingTrail = ball:FindFirstChild("TORT_fx")
                if existingTrail then existingTrail:Destroy() end
                for _, att in ipairs(ball:GetChildren()) do
                    if att:IsA("Attachment") then att:Destroy() end
                end
            end
        end
    end
end)

-- Ball Velocity Display
local BallVelocity = false

local function get_ball2()
    local container = workspace:FindFirstChild("Balls")
    if container then
        for _, ball in ipairs(container:GetChildren()) do
            if not ball.Anchored then return ball end
        end
    end
end

local function create_ball_velocity_display(ball)
    local existingDisplay = ball:FindFirstChild("BallVelocityDisplay")
    if existingDisplay then return existingDisplay.TextLabel end
    local gui = Instance.new("BillboardGui")
    gui.Name = "BallVelocityDisplay"
    gui.Adornee = ball
    gui.Size = UDim2.new(0, 200, 0, 50)
    gui.StudsOffset = Vector3.new(0, 5, 0)
    gui.AlwaysOnTop = true
    gui.Parent = ball
    local t = Instance.new("TextLabel")
    t.Name = "TextLabel"
    t.Size = UDim2.new(1, 0, 1, 0)
    t.BackgroundTransparency = 1
    t.TextScaled = true
    t.TextColor3 = Color3.new(1, 1, 1)
    t.Font = Enum.Font.Arcade
    t.TextSize = 18
    t.Text = ""
    t.Parent = gui
    return t
end

local lastBall
local lastVelocityText
RunService.RenderStepped:Connect(function()
    if not BallVelocity then
        if lastBall and lastBall:FindFirstChild("BallVelocityDisplay") then lastBall.BallVelocityDisplay:Destroy() end
        lastBall, lastVelocityText = nil, nil
        return
    end
    local ball = get_ball2()
    if ball ~= lastBall then
        if lastBall and lastBall:FindFirstChild("BallVelocityDisplay") then lastBall.BallVelocityDisplay:Destroy() end
        lastBall = ball
        lastVelocityText = ball and create_ball_velocity_display(ball) or nil
    end
    if lastBall and lastVelocityText and lastBall.Parent then
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local velocity = lastBall.AssemblyLinearVelocity or lastBall.Velocity
            local distance = (lastBall.Position - hrp.Position).Magnitude
            lastVelocityText.Text = string.format("Ball Velocity: %.2f", velocity.Magnitude)
            if distance > 70 then lastVelocityText.TextColor3 = Color3.fromRGB(0, 255, 0)
            elseif distance > 30 then lastVelocityText.TextColor3 = Color3.fromRGB(255, 255, 0)
            else lastVelocityText.TextColor3 = Color3.fromRGB(255, 0, 0) end
        end
    end
end)

-- View Ball / Rotate
local function resetCamera()
    local camera = workspace.CurrentCamera
    if camera then camera.CameraType = Enum.CameraType.Custom end
end

local function startViewBallLoop()
    if _G.viewConnection then _G.viewConnection:Disconnect(); _G.viewConnection = nil end
    _G.viewConnection = RunService.RenderStepped:Connect(function()
        local ball = getBall()
        local camera = workspace.CurrentCamera
        if not camera then return end
        if (_G.AgentX77 or getgenv().ViewBall) and ball then
            camera.CameraType = Enum.CameraType.Scriptable
            local targetPosition = ball.Position + Vector3.new(0, 5, 15)
            camera.CFrame = CFrame.new(camera.CFrame.Position:Lerp(targetPosition, 0.05), ball.Position)
        else
            resetCamera()
        end
    end)
end

local function rotateCharacter()
    while getgenv().RotateTowardsBall do
        task.wait()
        local char = LocalPlayer.Character
        local ball = getBall()
        if ball and char and char:FindFirstChild("HumanoidRootPart") and char.PrimaryPart then
            local direction = (ball.Position - char.HumanoidRootPart.Position).Unit
            local targetCFrame = CFrame.new(char.HumanoidRootPart.Position, char.HumanoidRootPart.Position + direction)
            char:SetPrimaryPartCFrame(char.PrimaryPart.CFrame:Lerp(targetCFrame, 0.2))
        end
    end
end

-- Follow Ball
spawn(function()
    local plr = LocalPlayer
    local Ball = workspace:WaitForChild("Balls")
    local DeadFolder = workspace:FindFirstChild("Dead")
    local currentTween = nil
    getgenv().FollowSpeed = getgenv().FollowSpeed or 10
    getgenv().FollowDistance = getgenv().FollowDistance or 50
    while true do
        wait(0.001)
        if getgenv().FB then
            if DeadFolder and DeadFolder:FindFirstChild(plr.Name) then
                if currentTween then currentTween:Pause(); currentTween = nil end
            else
                local ball = Ball:FindFirstChildOfClass("Part")
                local char = plr.Character
                if ball and char and char.PrimaryPart then
                    local distance = (char.PrimaryPart.Position - ball.Position).magnitude
                    if distance <= tonumber(getgenv().FollowDistance) then
                        if currentTween then currentTween:Pause() end
                        local tweenInfo = TweenInfo.new(tonumber(getgenv().FollowSpeed), Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
                        currentTween = TweenService:Create(char.PrimaryPart, tweenInfo, {CFrame = ball.CFrame})
                        currentTween:Play()
                    end
                end
            end
        else
            if currentTween then currentTween:Pause(); currentTween = nil end
        end
    end
end)

-- ============================================================
-- 14. HIT SOUND / EFFECT
-- ============================================================
local soundIDs = {
    Disabled = '', DC_15X = 'rbxassetid://936447863',
    Neverlose = 'rbxassetid://8679627751',
    Minecraft = 'rbxassetid://8766809464',
    MinecraftHit2 = 'rbxassetid://8458185621',
    ["Teamfortress Bonk"] = 'rbxassetid://8255306220',
    ["Teamfortress Bell"] = 'rbxassetid://2868331684',
    ["Excalibur"] = 'rbxassetid://153613030',
    ["Masamune"] = 'rbxassetid://99803221089826',
    ["Muramasa"] = 'rbxassetid://98608144972892',
    ["Soul Edge"] = 'rbxassetid://130037857404629',
    ["Ragnarok"] = 'rbxassetid://82442955130305',
    ["Dark Repulser"] = 'rbxassetid://16008606789',
    ["Elucidator"] = 'rbxassetid://78618347958652',
    ["Dragon Slayer"] = 'rbxassetid://78833978912349',
}

local TORT_Data = nil
local hit_Sound = nil

function initializate(name)
    TORT_Data = Instance.new('Folder', game:GetService('CoreGui'))
    TORT_Data.Name = name
    hit_Sound = Instance.new('Sound', TORT_Data)
    hit_Sound.Volume = 5
end

function setHitSound(soundId) hit_Sound.SoundId = soundId end

RunService.RenderStepped:Connect(function()
    if hit_Sound and LocalPlayer.Character and LocalPlayer.Character.Head then
        local currentCamera = workspace.CurrentCamera
        local dist = (currentCamera and currentCamera.CFrame.Position or Vector3.new() - LocalPlayer.Character.Head.Position).Magnitude
        if dist < 0.1 then dist = 0.1 end
        local newVolume = 5 / (dist * 0.3)
        if newVolume < 0.1 then newVolume = 0.1 elseif newVolume > 5 then newVolume = 5 end
        hit_Sound.Volume = newVolume
    end
end)

ReplicatedStorage.Remotes.ParrySuccess.OnClientEvent:Connect(function()
    if getgenv().hit_sound_Enabled and hit_Sound then hit_Sound:Play() end
    if getgenv().hit_effect_Enabled then
        local ball = getBall()
        if ball then
            local hit_effect = game:GetObjects("rbxassetid://17407244385")[1]
            hit_effect.Parent = ball
            hit_effect:Emit(3)
            task.delay(5, function() pcall(function() hit_effect:Destroy() end) end)
        end
    end
end)

initializate('TORT_Data')

-- ============================================================
-- 15. AUTO BUY CRATES
-- ============================================================
spawn(function()
    while true do
        wait(0.01)
        if getgenv().ASC then
            pcall(function()
                ReplicatedStorage.Remote.RemoteFunction:InvokeServer("PromptPurchaseCrate", workspace.Spawn.Crates.NormalSwordCrate)
            end)
        end
    end
end)
spawn(function()
    while true do
        wait(0.01)
        if getgenv().AEC then
            pcall(function()
                ReplicatedStorage.Remote.RemoteFunction:InvokeServer("PromptPurchaseCrate", workspace.Spawn.Crates.NormalExplosionCrate)
            end)
        end
    end
end)

-- ============================================================
-- 16. ANTI-AFK / NIGHT MODE / REMOVE FOG
-- ============================================================
local afkRunning = false
local afkToggle = false

local function startAntiAFK()
    if afkRunning then return end
    afkRunning = true
    task.spawn(function()
        while afkToggle do
            for i = 900, 1, -1 do
                if not afkToggle then break end
                task.wait(1)
            end
            if not afkToggle then break end
            for j = 1, 5 do
                local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.FloorMaterial ~= Enum.Material.Air then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
                task.wait(0.5)
            end
        end
        afkRunning = false
    end)
end

task.defer(function()
    while task.wait(1) do
        if getgenv().night_mode_Enabled then
            TweenService:Create(game:GetService("Lighting"), TweenInfo.new(3), {ClockTime = 3.9}):Play()
        else
            TweenService:Create(game:GetService("Lighting"), TweenInfo.new(3), {ClockTime = 13.5}):Play()
        end
    end
end)

local function applySettings()
    if getgenv().remove_fog_Enabled then
        Services.Lighting.FogEnd = 1e10
        Services.Lighting.FogStart = 1e10
        Services.Lighting.FogColor = Color3.new(0, 0, 0)
    end
end
applySettings()
LocalPlayer.CharacterAdded:Connect(function() task.wait(1); applySettings() end)

-- ============================================================
-- 17. BUG REPORT / JOB ID
-- ============================================================
local reportCount = 0
local originalName = "TORT"
local currentName = originalName
local problemDescription = ""
local frequencySelection = ""

local function getExploitName()
    return (identifyexecutor and identifyexecutor())
        or (syn and syn.get_executor and syn.get_executor())
        or (secure_load and "SecureLoad")
        or (KRNL_LOADED and "KRNL")
        or (islclosure and "Unknown Executor") or "Unknown"
end

local TeleportService = game:GetService("TeleportService")
local currentJobId = game.JobId
local inputJobId = ""
local originalMaterials = {}
local originalDecalsTextures = {}
local antiLagActive = false

-- ================================================================
-- UI BUILD (moved here to ensure it loads BEFORE any blocking code)
-- ================================================================
local TORTLib = Library.__init()
local HomeTab      = TORTLib.create_tab('Home')
local MainTab      = TORTLib.create_tab('Main')
local CombatTab    = TORTLib.create_tab('Combat')
local ShopTab      = TORTLib.create_tab('Shop')
local SettingsTab  = TORTLib.create_tab('Settings')

-- ===== HOME =====
HomeTab.create_title({name = 'Discord', section = 'left'})
HomeTab.create_button({
    name = 'Join Discord', section = 'left',
    callback = function()
        local req = (syn and syn.request) or (http and http.request) or http_request
        local opened = false
        local JoinDiscord = "https://discord.gg/Q7gk2drGpD"
        if req then
            local success, response = pcall(function()
                return req({
                    Url = 'http://127.0.0.1:6463/rpc?v=1', Method = 'POST',
                    Headers = {['Content-Type'] = 'application/json', ['Origin'] = 'https://discord.com'},
                    Body = Services.HttpService:JSONEncode({cmd = 'INVITE_BROWSER', nonce = Services.HttpService:GenerateGUID(false), args = {code = 'Q7gk2drGpD'}})
                })
            end)
            if success and response and response.StatusCode == 200 then opened = true end
        end
        if not opened then
            if setclipboard then
                setclipboard(JoinDiscord)
                LibraryNotify:MakeNotify({Title = "TORT FREE:", Description = "Clipboard", Content = "Link copied to your clipboard.", Time = 0.5, Delay = 5})
            else
                LibraryNotify:MakeNotify({Title = "TORT FREE:", Description = "UnSupport", Content = "Clipboard unsupported. Link: " .. JoinDiscord, Time = 0.5, Delay = 5})
            end
        else
            LibraryNotify:MakeNotify({Title = "TORT FREE:", Description = "Discord PC", Content = "Discord is running on your device.", Time = 0.5, Delay = 15})
        end
    end
})

HomeTab.create_title({name = 'TORT Security', section = 'right'})
HomeTab.create_toggle({
    name = 'Protection - TORT', flag = 'auto_update', section = 'right', enabled = false,
    callback = function(state)
        if state then
            local hm, gnm = hookmetamethod, getnamecallmethod
            if hm and gnm and not getgenv().TORT_KickHook then
                local ok, old = pcall(function()
                    local o
                    o = hm(game, "__namecall", newcclosure(function(self, ...)
                        local okNm, nm = pcall(gnm)
                        if okNm and nm and string.lower(tostring(nm)) == "kick" then
                            pcall(function()
                                LibraryNotify:MakeNotify({Title = "TORT FREE:", Description = "Protection", Content = "Blocked Kick attempt.", Time = 0.5, Delay = 5})
                            end)
                            return
                        end
                        return o(self, ...)
                    end))
                    return o
                end)
                if ok and old then getgenv().TORT_KickHook = old end
            end
            pcall(function() LibraryNotify:MakeNotify({Title = "TORT FREE:", Description = "Protection", Content = "The Protections have been Activated.", Time = 0.5, Delay = 5}) end)
        else
            pcall(function() LibraryNotify:MakeNotify({Title = "TORT FREE:", Description = "Protection", Content = "WARNING: Protection - TORT FREE has been Disabled.", Time = 0.5, Delay = 5}) end)
        end
    end
})

-- ===== MAIN =====
MainTab.create_title({name = 'ESP Lines', section = 'left'})
MainTab.create_toggle({name = 'ESP Enabled', flag = 'esp_enabled', section = 'left', enabled = false, callback = function(s) ESPLines.Enabled = s end})
MainTab.create_line({section = "left"})
MainTab.create_toggle({name = 'ESP Show Box', flag = 'esp_show_box', section = 'left', enabled = false, callback = function(s) ESPLines.ShowBox = s end})
MainTab.create_toggle({name = 'ESP Show Name', flag = 'esp_show_name', section = 'left', enabled = false, callback = function(s) ESPLines.ShowName = s end})
MainTab.create_toggle({name = 'ESP Show Health', flag = 'esp_show_health', section = 'left', enabled = false, callback = function(s) ESPLines.ShowHealth = s end})
MainTab.create_toggle({name = 'ESP Show Tracer', flag = 'esp_show_tracer', section = 'left', enabled = false, callback = function(s) ESPLines.ShowTracer = s end})
MainTab.create_toggle({name = 'ESP Show Distance', flag = 'esp_show_distance', section = 'left', enabled = false, callback = function(s) ESPLines.ShowDistance = s end})

MainTab.create_title({name = 'ESP Settings', section = 'left'})
MainTab.create_dropdown({
    name = 'ESP Settings', flag = 'esp_settings', section = 'left', option = '2D',
    options = {'Corner Box Esp', '2D'},
    callback = function(v) ESPLines.BoxType = v end
})

MainTab.create_title({name = 'Auto Rewards', section = 'left'})
MainTab.create_toggle({
    name = 'Auto Rewards', flag = 'auto_rewards', section = 'left', enabled = false,
    callback = function(s) auto_rewards_enabled = s end
})
MainTab.create_line({section = "left"})
MainTab.create_textbox({
    name = 'Claim Speed', flag = 'claim_speed', section = 'left', value = '60',
    callback = function(v) reward_interval = tonumber(v) or 60 end
})
MainTab.create_dropdown({
    name = 'Custom Reward', flag = 'custom_reward', section = 'left', option = 'All',
    options = {'All', 'Daily', 'Tasks'},
    callback = function(v) reward_choice = v or 'All' end
})

MainTab.create_title({name = 'AI Options', section = 'right'})
MainTab.create_toggle({name = 'Auto Walk', flag = 'auto_walk', section = 'right', enabled = false, callback = function(s) AutoWalk = s end})
MainTab.create_toggle({name = 'Player Safety', flag = 'player_safety', section = 'right', enabled = false, callback = function(s) PlayerSaftey = s end})
MainTab.create_toggle({name = 'Random Teleports', flag = 'random_teleports', section = 'right', enabled = false, callback = function(s) RandomTeleports = s end})
MainTab.create_toggle({name = 'Auto Jump', flag = 'auto_jump', section = 'right', enabled = false, callback = function(s) AutoDoubleJump = s end})
MainTab.create_toggle({name = 'Closest Player Focus', flag = 'closest_player_focus', section = 'right', enabled = false, callback = function(s) ClosestPlayer_var = s end})
MainTab.create_toggle({name = 'AI Player', flag = 'ai_player', section = 'right', enabled = false, callback = function(s) AiPlay = s end})

MainTab.create_title({name = 'Player Options', section = 'right'})
MainTab.create_slider({name = 'Auto Walk X', flag = 'auto_walk_x_slider', section = 'right', value = 10, minimum_value = 0, maximum_value = 50, callback = function(v) AutoWalkDistanceX = v end})
MainTab.create_slider({name = 'Auto Walk Z', flag = 'auto_walk_z_slider', section = 'right', value = 10, minimum_value = 0, maximum_value = 50, callback = function(v) AutoWalkDistanceZ = v end})
MainTab.create_slider({name = 'Player Safety', flag = 'player_safety_slider', section = 'right', value = 10, minimum_value = 0, maximum_value = 50, callback = function(v) PlayerSaftey_Distance = v end})
MainTab.create_slider({name = 'Teleport X', flag = 'teleport_x_slider', section = 'right', value = 10, minimum_value = 0, maximum_value = 50, callback = function(v) TeleportDistanceX = v end})
MainTab.create_slider({name = 'Teleport Z', flag = 'teleport_z_slider', section = 'right', value = 10, minimum_value = 0, maximum_value = 50, callback = function(v) TeleportDistanceZ = v end})
MainTab.create_dropdown({
    name = 'AI Modes', flag = 'ai_modes_dropdown', section = 'right', option = 'Normal',
    options = {'Normal', 'Advanced', 'Hacker'},
    callback = function(v) AiPlayType = v; local h = get_humanoid(); if h then if not AiPlay or v ~= "Hacker" then h.WalkSpeed = 36 end end end
})
MainTab.create_slider({name = 'Hacker Speed', flag = 'hacker_speed_slider', section = 'right', value = 200, minimum_value = 36, maximum_value = 500, callback = function(v) AiPlaySpeed = v end})

MainTab.create_title({name = 'VIP Tag', section = 'right'})
MainTab.create_button({
    name = 'Get VIP Tag', section = 'right',
    callback = function()
        local StarterGui = game:GetService("StarterGui")
        local TextChatService = game:GetService("TextChatService")
        local lp = LocalPlayer
        local vipTag = "<font color='#FFFF00'>[VIP]</font> " .. lp.Name
        if TextChatService.ChatVersion == Enum.ChatVersion.LegacyChatService then
            lp.Chatted:Connect(function(msg)
                StarterGui:SetCore("ChatMakeSystemMessage", {Text = vipTag .. ": " .. msg, Color = Color3.new(1, 1, 1), Font = Enum.Font.SourceSansBold, TextSize = 18})
            end)
        else
            TextChatService.OnIncomingMessage = function(message)
                if message.TextSource then
                    local sender = Players:GetPlayerByUserId(message.TextSource.UserId)
                    if sender == lp then message.PrefixText = vipTag end
                end
            end
        end
        LibraryNotify:MakeNotify({Title = "TORT FREE:", Description = "VIP Tag", Content = "You have received the VIP badge.", Time = 0.5, Delay = 5})
    end
})

-- ===== COMBAT =====
CombatTab.create_title({name = 'Auto Parry', section = 'left'})
CombatTab.create_toggle({
    name = 'Auto Parry', flag = 'auto_parry', section = 'left', enabled = true,
    callback = function(value)
        if value then StartAutoParry()
        else if Connections_Manager['Auto Parry'] then Connections_Manager['Auto Parry']:Disconnect(); Connections_Manager['Auto Parry'] = nil end end
    end
})

CombatTab.create_toggle({
    name = 'Auto Spam', flag = 'auto_spam', section = 'left', enabled = true,
    callback = function(value)
        if value then StartAutoSpam()
        else if Connections_Manager['Auto Spam'] then Connections_Manager['Auto Spam']:Disconnect(); Connections_Manager['Auto Spam'] = nil end end
    end
})

CombatTab.create_toggle({
    name = 'Random Parry Accuracy', flag = 'random_parry_accuracy', section = 'left', enabled = false,
    callback = function(v) getgenv().RandomParryAccuracy = v end
})

CombatTab.create_toggle({
    name = 'Animation Fix', flag = 'animation_fix', section = 'left', enabled = false,
    callback = function(value) getgenv().AnimationFix = value end
})

CombatTab.create_line({section = "left"})
CombatTab.create_dropdown({
    name = 'Direction Ball', flag = 'direction_ball', section = 'left', option = 'Camera',
    options = {
        'Camera', 'Mouse', 'Players', 'Normal',
        'Up', 'Down', 'Left', 'Right', 'Behind',
        'Random', 'FrontLeft', 'FrontRight', 'BackLeft',
        'BackRight', 'SkywardSpiral', 'Zigzag', 'Spin',
        'Bounce', 'Wave', 'Orbit', 'Chaos', 'TargetFeet',
        'TargetHead', 'DiagonalUp', 'DiagonalDown',
        'FlipReverse', 'CurveLeft', 'CurveRight',
        'Whirlwind', 'TeleportStyle', 'SlideAngle', 'Drift'
    },
    callback = function(v) DirectionMode = v end
})
CombatTab.create_slider({
    name = 'Parry Window', flag = 'parry_window', section = 'left',
    value = 0.15, minimum_value = 0.05, maximum_value = 0.6,
    callback = function(v) getgenv().AutoParryWindow = v end
})
CombatTab.create_slider({
    name = 'Auto Spam Window', flag = 'auto_spam_window', section = 'left',
    value = 0.35, minimum_value = 0.1, maximum_value = 1,
    callback = function(v) getgenv().AutoSpamWindow = v end
})
CombatTab.create_slider({
    name = 'Auto Spam KPS', flag = 'auto_spam_kps', section = 'left',
    value = 20, minimum_value = 5, maximum_value = 60,
    callback = function(v) getgenv().AutoSpamKPS = v end
})
CombatTab.create_toggle({
    name = 'Spam Only When Targeted', flag = 'spam_target_only', section = 'left', enabled = true,
    callback = function(state)
        getgenv().SpamTargetOnly = state
        getgenv().ManualSpamTargetOnly = state
    end
})
CombatTab.create_slider({
    name = 'Manual Spam KPS', flag = 'manual_spam_kps', section = 'left',
    value = 25, minimum_value = 1, maximum_value = 100,
    callback = function(v) getgenv().ManualSpamKPS = v end
})
CombatTab.create_slider({
    name = 'Manual Spam Distance', flag = 'manual_spam_distance', section = 'left',
    value = 60, minimum_value = 10, maximum_value = 300,
    callback = function(v) getgenv().ManualSpamDistance = v end
})
CombatTab.create_toggle({
    name = 'Mobile Spam UI', flag = 'mobile_spam_ui', section = 'left', enabled = false,
    callback = function(state)
        if state then MobileSpam.create() else MobileSpam.destroy() end
    end
})
CombatTab.create_toggle({
    name = 'Manual Spam', flag = 'manual_spam', section = 'left', enabled = false,
    callback = function(state)
        getgenv().ManualSpamEnabled = state
        getgenv().ManualSpamKey = getgenv().ManualSpamKey or Enum.KeyCode.E
        if state then
            StartManualSpam()
            if IsMobile then MobileSpam.show() end
            if not Connections_Manager['Manual Spam Key'] then
                Connections_Manager['Manual Spam Key'] = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then return end
                    if input.KeyCode == getgenv().ManualSpamKey then
                        getgenv().ManualSpamActive = not getgenv().ManualSpamActive
                        LibraryNotify:MakeNotify({Title = "TORT FREE:", Description = "Manual Spam", Content = getgenv().ManualSpamActive and "Manual spam ON." or "Manual spam OFF.", Time = 0.5, Delay = 5})
                    end
                end)
            end
            LibraryNotify:MakeNotify({Title = "TORT FREE:", Description = "Manual Spam", Content = "Manual spam activated. Press E to toggle.", Time = 0.5, Delay = 5})
        else
            getgenv().ManualSpamActive = false
            if Connections_Manager['Manual Spam Key'] then Connections_Manager['Manual Spam Key']:Disconnect(); Connections_Manager['Manual Spam Key'] = nil end
            if Connections_Manager['Manual Spam'] then Connections_Manager['Manual Spam']:Disconnect(); Connections_Manager['Manual Spam'] = nil end
            LibraryNotify:MakeNotify({Title = "TORT FREE:", Description = "Manual Spam", Content = "Manual spam disabled.", Time = 0.5, Delay = 5})
        end
    end
})

CombatTab.create_title({name = 'Ball Options', section = 'right'})
CombatTab.create_toggle({
    name = 'Visualizer', flag = 'visualizer_ball', section = 'right', enabled = false,
    callback = function(state) getgenv().VisualizerBallEnabled = state; if not state then removeSphere() end end
})
CombatTab.create_toggle({
    name = 'Ball Statistics', flag = 'ball_statistics', section = 'right', enabled = false,
    callback = function(state) BallVelocity = state end
})
CombatTab.create_toggle({
    name = 'Random Target', flag = 'random_target', section = 'right', enabled = false,
    callback = function(state) _G.config.random_target = state end
})
CombatTab.create_toggle({
    name = 'View Ball', flag = 'view_ball', section = 'right', enabled = false,
    callback = function(state)
        pcall(function()
            _G.AgentX77 = state
            getgenv().ViewBall = state
            if state then startViewBallLoop()
            else
                if _G.viewConnection then _G.viewConnection:Disconnect(); _G.viewConnection = nil end
                resetCamera()
            end
        end)
    end
})
CombatTab.create_toggle({
    name = 'Ball Rotation', flag = 'ball_rotation', section = 'right', enabled = false,
    callback = function(value)
        pcall(function()
            getgenv().RotateTowardsBall = value
            if value then task.spawn(rotateCharacter) end
        end)
    end
})
CombatTab.create_toggle({
    name = 'Trial Ball', flag = 'trial_ball', section = 'right', enabled = false,
    callback = function(state) ball_Trail_Enabled = state end
})
CombatTab.create_toggle({
    name = 'Player Trail', flag = 'player_trail', section = 'right', enabled = false,
    callback = function(state) player_Trail_Enabled = state end
})
CombatTab.create_line({section = "right"})
CombatTab.create_toggle({name = 'Follow Ball', flag = 'follow_ball', section = 'right', enabled = false, callback = function(state) getgenv().FB = state end})
CombatTab.create_slider({name = 'Follow Speed', flag = 'follow_speed', section = 'right', value = 10, minimum_value = 0, maximum_value = 50, callback = function(v) getgenv().FollowSpeed = v end})
CombatTab.create_slider({name = 'Follow Distance', flag = 'follow_distance', section = 'right', value = 10, minimum_value = 0, maximum_value = 50, callback = function(v) getgenv().FollowDistance = v end})

CombatTab.create_title({name = 'Swords Options', section = 'right'})
CombatTab.create_toggle({
    name = 'Enable Hit Sound', flag = 'enable_hit_sound', section = 'right', enabled = true,
    callback = function(state) getgenv().hit_sound_Enabled = state end
})
CombatTab.create_toggle({
    name = 'Enable Hit Effect', flag = 'enable_hit_effect', section = 'right', enabled = false,
    callback = function(state) getgenv().hit_effect_Enabled = state end
})
CombatTab.create_dropdown({
    name = 'Sound Effects', flag = 'sound_effects', section = 'right', option = 'Disabled',
    options = {"Disabled", 'DC_15X', 'Minecraft', 'MinecraftHit2', 'Teamfortress Bonk', 'Teamfortress Bell', 'Excalibur', 'Masamune', 'Muramasa', 'Soul Edge', 'Ragnarok', 'Dark Repulser', 'Elucidator', 'Dragon Slayer'},
    callback = function(v) setHitSound(soundIDs[v] or '') end
})
CombatTab.create_textbox({
    name = 'Volume', flag = 'volume', section = 'right', value = '5',
    callback = function(v) if tonumber(v) and hit_Sound then hit_Sound.Volume = tonumber(v) end end
})

CombatTab.create_title({name = 'AI Options', section = 'left'})
CombatTab.create_toggle({name = 'AI TORT', flag = 'ai_tort', section = 'left', enabled = true, callback = function(state) getgenv().AITORT = state end})
CombatTab.create_line({section = "left"})
CombatTab.create_toggle({name = 'Improve Accuracy', flag = 'ai_auto_parry', section = 'left', enabled = true, callback = function(state) getgenv().ImproveAccuracy = state end})
CombatTab.create_toggle({name = 'Improve Auto Spam', flag = 'ai_auto_spam', section = 'left', enabled = true, callback = function(state) getgenv().ImproveAutoSpam = state end})

CombatTab.create_title({name = 'Detections', section = 'left'})
-- Master switch. It used to only set a local, so turning it off changed
-- nothing; now it pushes the state into every individual detection flag.
local DETECTION_FLAG_MAP = {
    {'Toggle_InfinityDetection', 'InfinityDetection'},
    {'Toggle_DeathSlashDetection', 'DeathSlashDetection'},
    {'Toggle_TimeHoleDetection', 'TimeHoleDetection'},
    {'Toggle_AutoTelekinesis', 'AutoTelekinesis'},
    {'Toggle_Forcefield', 'ForcefieldDetection'},
    {'Toggle_SlashOfFuryDetection', 'SlashOfFuryDetection'},
    {'Toggle_AntiPhantom', 'PhantomV2Detection'},
    {'Toggle_CooldownProtection', 'CooldownProtection'},
    {'auto_ability', 'AutoAbility'},
}
CombatTab.create_toggle({
    name = 'Detections', flag = 'Toggle_Detections', section = 'left', enabled = true,
    callback = function(state)
        Detections = state
        for _, entry in ipairs(DETECTION_FLAG_MAP) do
            local wanted = Library.Flags[entry[1]]
            getgenv()[entry[2]] = (state and wanted ~= false) and true or false
        end
    end
})
CombatTab.create_line({section = "left"})
CombatTab.create_toggle({
    name = 'Infinity Detection', flag = 'Toggle_InfinityDetection', section = 'left', enabled = true,
    callback = function(value) getgenv().InfinityDetection = Detections and value or false end
})
CombatTab.create_toggle({
    name = 'Death Slash Detection', flag = 'Toggle_DeathSlashDetection', section = 'left', enabled = true,
    callback = function(state) getgenv().DeathSlashDetection = Detections and state or false end
})
CombatTab.create_toggle({
    name = 'Time Hole Detection', flag = 'Toggle_TimeHoleDetection', section = 'left', enabled = true,
    callback = function(state) getgenv().TimeHoleDetection = Detections and state or false end
})
CombatTab.create_toggle({
    name = 'Auto Telekinesis Block', flag = 'Toggle_AutoTelekinesis', section = 'left', enabled = true,
    callback = function(state) getgenv().AutoTelekinesis = Detections and state or false end
})
CombatTab.create_toggle({
    name = 'Forcefield Detection', flag = 'Toggle_Forcefield', section = 'left', enabled = true,
    callback = function(state) getgenv().ForcefieldDetection = Detections and state or false end
})
CombatTab.create_toggle({
    name = 'Slash of Fury Detection', flag = 'Toggle_SlashOfFuryDetection', section = 'left', enabled = true,
    callback = function(state) getgenv().SlashOfFuryDetection = Detections and state or false end
})
CombatTab.create_toggle({
    name = 'Anti Phantom Attack', flag = 'Toggle_AntiPhantom', section = 'left', enabled = false,
    callback = function(value) getgenv().PhantomV2Detection = Detections and value or false end
})
CombatTab.create_toggle({
    name = 'Cooldown Protection', flag = 'Toggle_CooldownProtection', section = 'left', enabled = true,
    callback = function(state) getgenv().CooldownProtection = Detections and state or false end
})
CombatTab.create_toggle({
    name = 'Auto Ability', flag = 'auto_ability', section = 'left', enabled = true,
    callback = function(state) getgenv().AutoAbility = Detections and state or false end
})

CombatTab.create_title({name = 'Auto/Anti Options', section = 'right'})
CombatTab.create_toggle({name = 'Auto Curve', flag = 'auto_curve', section = 'right', enabled = false, callback = function(state) EnableAutoCurve = state end})
CombatTab.create_toggle({name = 'Auto Block Spams', flag = 'auto_block_spams', section = 'right', enabled = true, callback = function(state) getgenv().AutoBlockSpams = state end})
CombatTab.create_line({section = "right"})
CombatTab.create_toggle({name = 'Anti Curve', flag = 'anti_curve', section = 'right', enabled = false, callback = function(state) EnableAntiCurve = state end})
CombatTab.create_toggle({name = 'Anti Block Spams', flag = 'anti_block_spams', section = 'right', enabled = true, callback = function(state) getgenv().AntiBlockSpams = state end})

CombatTab.create_title({name = 'Auto Parry Lobby', section = 'right'})
CombatTab.create_toggle({
    name = 'Auto Parry', flag = 'auto_parry_lobby', section = 'right', enabled = false,
    callback = function(value)
        if value then StartLobbyAP()
        else if Connections_Manager['Lobby AP'] then Connections_Manager['Lobby AP']:Disconnect(); Connections_Manager['Lobby AP'] = nil end end
    end
})
CombatTab.create_slider({
    name = 'Auto Parry Distance', flag = 'auto_parry_distance_lobby', section = 'right',
    value = 100, minimum_value = 1, maximum_value = 100,
    callback = function(v) LobbyAP_Speed_Divisor_Multiplier = 0.7 + (v - 1) * (0.35 / 99) end
})
CombatTab.create_toggle({
    name = 'Ramdom Parry Accuracy', flag = 'random_parry_accuracy_lobby', section = 'right', enabled = false,
    callback = function(value) getgenv().LobbyAPRandomParryAccuracyEnabled = value end
})

-- ===== SHOP =====
ShopTab.create_title({name = 'Auto Crates', section = 'left'})
ShopTab.create_toggle({
    name = 'Auto Buy Swords', flag = 'auto_buy_swords', section = 'left', enabled = false,
    callback = function(state) getgenv().ASC = state end
})
ShopTab.create_toggle({
    name = 'Auto Buy Explosions', flag = 'auto_buy_explosions', section = 'left', enabled = false,
    callback = function(state) getgenv().AEC = state end
})
ShopTab.create_title({name = 'Create', section = 'right'})
ShopTab.create_button({
    name = "Buy Sword Box", section = "right",
    callback = function()
        ReplicatedStorage.Remote.RemoteFunction:InvokeServer("PromptPurchaseCrate", workspace.Spawn.Crates.NormalSwordCrate)
    end
})
ShopTab.create_button({
    name = "Buy Explosion Box", section = "right",
    callback = function()
        ReplicatedStorage.Remote.RemoteFunction:InvokeServer("PromptPurchaseCrate", workspace.Spawn.Crates.NormalExplosionCrate)
    end
})

-- ===== SETTINGS =====
SettingsTab.create_title({name = 'Product', section = 'left'})
SettingsTab.create_paragraph({name = "ToggleUI:", title = "Left-Ctrl", section = "left"})
SettingsTab.create_line({section = "left"})
SettingsTab.create_toggle({
    name = 'Bypass Limits', flag = 'bypass_limits', section = 'left', enabled = true,
    callback = function(value) getgenv().bypass_limits_Enabled = value end
})
SettingsTab.create_toggle({
    name = 'Anti Detected', flag = 'anti_detected', section = 'left', enabled = true,
    callback = function(value)
        if value then
            local target = Services.CoreGui:FindFirstChild(originalName)
            if target then
                local newName = "\\" .. Services.HttpService:GenerateGUID(false):gsub("-", ""):sub(1, 12)
                target.Name = newName
                currentName = newName
            end
        else
            currentName = originalName
        end
    end
})
SettingsTab.create_button({
    name = 'Exit TORT', section = 'left',
    callback = function()
        if Connections_Manager['Auto Parry'] then Connections_Manager['Auto Parry']:Disconnect() end
        if Connections_Manager['Auto Spam'] then Connections_Manager['Auto Spam']:Disconnect() end
        if Connections_Manager['Lobby AP'] then Connections_Manager['Lobby AP']:Disconnect() end
        if Connections_Manager['Animation Fix'] then Connections_Manager['Animation Fix']:Disconnect() end
        if Connections_Manager['Manual Spam'] then Connections_Manager['Manual Spam']:Disconnect(); Connections_Manager['Manual Spam'] = nil end
        if Connections_Manager['Manual Spam Key'] then Connections_Manager['Manual Spam Key']:Disconnect(); Connections_Manager['Manual Spam Key'] = nil end
        getgenv().ManualSpamActive = false
        MobileSpam.destroy()
        getgenv().TORT_Loaded = false
        for _, v in ipairs(Services.CoreGui:GetChildren()) do
            if v.Name == "TORTNotify" then v:Destroy() end
        end
        LibraryNotify:MakeNotify({Title = "TORT FREE:", Description = "Exit", Content = "Thank you for using TORT.", Time = 0.5, Delay = 5})
    end
})

SettingsTab.create_title({name = 'Report Bugs', section = 'right'})
SettingsTab.create_textbox({
    name = 'Report Bugs', flag = 'report_bugs', section = 'right', value = 'Describe your problem',
    callback = function(value) problemDescription = value end
})
SettingsTab.create_line({section = "right"})
SettingsTab.create_dropdown({
    name = 'How Often', flag = 'how_often', section = 'right', option = '',
    options = {'Just passing by today', 'It happens sometimes', 'It always happens'},
    callback = function(value) frequencySelection = value end
})
SettingsTab.create_button({
    name = 'Submit Report', section = 'right',
    callback = function()
        if problemDescription == "" or problemDescription == "Describe your problem" then
            LibraryNotify:MakeNotify({Title = "TORT FREE:", Description = "Report Bugs", Content = "Please describe your problem.", Time = 0.5, Delay = 5})
            return
        end
        if frequencySelection == "" then
            LibraryNotify:MakeNotify({Title = "TORT FREE:", Description = "Report Bugs", Content = "Please select how often the error occurs.", Time = 0.5, Delay = 5})
            return
        end
        reportCount = reportCount + 1
        LibraryNotify:MakeNotify({Title = "TORT FREE:", Description = "Report Bugs", Content = "Bug report submitted successfully.", Time = 0.5, Delay = 5})
    end
})

SettingsTab.create_title({name = 'Job ID', section = 'left'})
SettingsTab.create_textbox({
    name = 'Job ID', flag = 'job_id', section = 'left', value = '',
    callback = function(value) inputJobId = value end
})
SettingsTab.create_line({section = "left"})
SettingsTab.create_button({
    name = 'Teleport Job ID', section = 'left',
    callback = function()
        if inputJobId ~= "" then
            LibraryNotify:MakeNotify({Title = "TORT FREE:", Description = "Job ID", Content = "Teleporting", Time = 0.5, Delay = 5})
            task.wait(0.5)
            TeleportService:TeleportToPlaceInstance(game.PlaceId, inputJobId, LocalPlayer)
        else
            LibraryNotify:MakeNotify({Title = "TORT FREE:", Description = "Job ID", Content = "Invalid Job ID.", Time = 0.5, Delay = 5})
        end
    end
})
SettingsTab.create_button({
    name = 'Copy Job ID', section = 'left',
    callback = function()
        setclipboard(currentJobId)
        LibraryNotify:MakeNotify({Title = "TORT FREE:", Description = "Job ID", Content = "Job ID Copied to your clipboard.", Time = 0.5, Delay = 5})
    end
})

SettingsTab.create_title({name = 'Others', section = 'right'})
SettingsTab.create_toggle({
    name = 'Anti AFK', flag = 'anti_afk', section = 'right', enabled = false,
    callback = function(value) afkToggle = value; if value then startAntiAFK() end end
})
SettingsTab.create_line({section = "right"})
SettingsTab.create_toggle({
    name = 'Anti Lag', flag = 'anti_lag', section = 'right', enabled = false,
    callback = function(state)
        antiLagActive = state
        if state then
            for _, O in ipairs(workspace:GetDescendants()) do
                if O:IsA("BasePart") and not (O:FindFirstAncestorWhichIsA("Model") and O:FindFirstAncestorWhichIsA("Model"):FindFirstChild("Humanoid")) then
                    originalMaterials[O] = O.Material
                    O.Material = Enum.Material.SmoothPlastic
                    O.Reflectance = 0
                elseif O:IsA("Decal") or O:IsA("Texture") then
                    table.insert(originalDecalsTextures, {Object = O, Parent = O.Parent})
                    O.Parent = nil
                elseif O:IsA("ParticleEmitter") or O:IsA("Smoke") or O:IsA("Fire") or O:IsA("Sparkles") then
                    O.Enabled = false
                end
            end
        else
            for O, material in pairs(originalMaterials) do
                if O and O:IsA("BasePart") then O.Material = material end
            end
            for _, data in pairs(originalDecalsTextures) do
                if data.Object and data.Parent then data.Object.Parent = data.Parent end
            end
            originalMaterials = {}
            originalDecalsTextures = {}
        end
    end
})
SettingsTab.create_toggle({
    name = 'Night Mode', flag = 'night_mode', section = 'right', enabled = false,
    callback = function(value) getgenv().night_mode_Enabled = value end
})
SettingsTab.create_toggle({
    name = 'Remove Fog', flag = 'remove_fog', section = 'right', enabled = false,
    callback = function(value) getgenv().remove_fog_Enabled = value end
})
SettingsTab.create_slider({
    name = 'FPS Unlock (144-1000)', flag = 'fps_unlock', section = 'right',
    value = 999, minimum_value = 144, maximum_value = 1000,
    callback = function(v) if setfpscap then setfpscap(v) end end
})
SettingsTab.create_line({section = "right"})
SettingsTab.create_button({
    name = 'Reset Settings', section = 'right',
    callback = function()
        for _, v in next, {
            "TORT", "TORT_Hub", "TORT_Client", "TORT_Scripts", "TORT_Data",
            "TORTHub", "TORTX", "TORT-Lib", "TORT_Utils", "TORT_Lib",
            "TORTScripts", "TORT Script", "TORT Folder", "TORTFiles",
            "TORTClient", "TORTModule", "TORTInject", "TORTExecutor"
        } do pcall(delfolder, v) end
        LibraryNotify:MakeNotify({Title = "TORT FREE:", Description = "Settings", Content = "Settings have been success deleted.", Time = 0.5, Delay = 5})
    end
})

-- ================================================================
-- EVENTS (Blade Ball)
-- ================================================================
pcall(function()
    ReplicatedStorage.Remotes.ParrySuccess.OnClientEvent:Connect(function()
        if getgenv().hit_sound_Enabled then hit_Sound:Play() end
    end)
end)

pcall(function()
    ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent:Connect(function(_, root)
        if root.Parent and root.Parent ~= LocalPlayer.Character then
            if root.Parent.Parent ~= workspace.Alive then return end
        end
        local Ball = nil
        for _, b in ipairs(Balls:GetChildren()) do
            if b:GetAttribute("realBall") then Ball = b; break end
        end
        if not Ball then return end
        if not Grab_Parry then return end
        Grab_Parry:Stop()
    end)
end)

workspace.Balls.ChildAdded:Connect(function() Parried = false end)
workspace.Balls.ChildRemoved:Connect(function()
    Parries = 0
    Parried = false
    if Connections_Manager['Target Change'] then
        Connections_Manager['Target Change']:Disconnect()
        Connections_Manager['Target Change'] = nil
    end
end)

pcall(function()
    ReplicatedStorage.Remotes.Phantom.OnClientEvent:Connect(function(a, b)
        if b.Name == tostring(LocalPlayer) then Phantom = true else Phantom = false end
    end)
end)

workspace.Balls.ChildRemoved:Connect(function() Phantom = false end)

-- ================================================================
-- DONE
-- ================================================================
task.delay(2, function()
    LibraryNotify:MakeNotify({
        Title = "TORT FREE",
        Description = "Loaded",
        Content = "TORT FREE loaded successfully for Blade Ball. " .. (IsMobile and "Mobile" or "PC") .. " mode.",
        Time = 0.5,
        Delay = 5
    })
end)

return true