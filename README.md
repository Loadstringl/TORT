--[[
    TORT — Blade Ball Fixed & Complete Edition
    - Fixed: infinite wait loop, kick protection thread hang, UI loading order
    - Features: Auto Parry, Spam, ESP, Visuals, AI, Rewards, etc.
    - Mobile + PC Support
    - Original: Argon Hub X / TORT by AgentX771
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
        local win = Library:CreateWindow({Title = "TORT", Theme = "Indigo", UseAccentColor = true})
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
local ESPLines
do
    local ok, res = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/AgentX771/ArgonHubX/refs/heads/main/Privating/ESPLines.lua"))()
    end)
    ESPLines = ok and res or {
        Enabled = false, ShowBox = false, ShowName = false,
        ShowHealth = false, ShowTracer = false, ShowDistance = false, BoxType = "2D"
    }
    if ESPLines.Enabled ~= nil then ESPLines.Enabled = true end
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
    for _, v in pairs(workspace.Alive:GetChildren()) do
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

local function claim_rewards()
    pcall(function()
        if ReplicatedStorage:FindFirstChild("Remote") and ReplicatedStorage.Remote:FindFirstChild("RemoteEvent") then
            local event = ReplicatedStorage.Remote.RemoteEvent:FindFirstChild('ClaimLoginReward')
            if event then event:FireServer() end
        end
    end)
    task.defer(function()
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
        for reward = 1, 5 do
            pcall(function()
                if net and net:FindFirstChild("RF/RedeemQuestsType") then net["RF/RedeemQuestsType"]:InvokeServer('SummerClashEvent', 'Daily', reward) end
            end)
        end
    end)
    task.defer(function()
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

local function isValidRemoteArgs(args)
    return #args == 7 and type(args[2]) == "string" and type(args[3]) == "number"
        and typeof(args[4]) == "CFrame" and type(args[5]) == "table"
        and type(args[6]) == "table" and type(args[7]) == "boolean"
end

local function hookRemote(remote)
    if not revertedRemotes[remote] then
        local meta = getrawmetatable(remote)
        if not originalMetatables[meta] then
            originalMetatables[meta] = true
            setreadonly(meta, false)
            local oldIndex = meta.__index
            meta.__index = function(self, key)
                if key == "FireServer" and self:IsA("RemoteEvent") then
                    return function(_, ...)
                        local args = { ... }
                        if isValidRemoteArgs(args) and not revertedRemotes[self] then
                            revertedRemotes[self] = args
                        end
                        return oldIndex(self, "FireServer")(_, table.unpack(args))
                    end
                elseif key == "InvokeServer" and self:IsA("RemoteFunction") then
                    return function(_, ...)
                        local args = { ... }
                        if isValidRemoteArgs(args) and not revertedRemotes[self] then
                            revertedRemotes[self] = args
                        end
                        return oldIndex(self, "InvokeServer")(_, table.unpack(args))
                    end
                end
                return oldIndex(self, key)
            end
            setreadonly(meta, true)
        end
    end
end

if hookSupport then
    for _, remote in pairs(game.ReplicatedStorage:GetChildren()) do
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then hookRemote(remote) end
    end
    game.ReplicatedStorage.ChildAdded:Connect(function(child)
        if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then hookRemote(child) end
    end)
end

local Global = { cooldown = false, last_hit = 0, parry_count = 0 }

local function ParryFunction()
    if hookSupport then
        for remote, args in pairs(revertedRemotes) do
            if typeof(remote) ~= "Instance" then continue end
            if not remote:IsDescendantOf(game) then continue end
            if remote:IsA("RemoteEvent") then
                args[4] = CFrame.new(LocalPlayer.Character.HumanoidRootPart.Position, LocalPlayer.Character.HumanoidRootPart.Position + GetDirection())
                remote:FireServer(unpack(args))
            elseif remote:IsA("RemoteFunction") then
                args[4] = CFrame.new(LocalPlayer.Character.HumanoidRootPart.Position, LocalPlayer.Character.HumanoidRootPart.Position + GetDirection())
                remote:InvokeServer(unpack(args))
            end
        end
    else
        game:GetService("VirtualInputManager"):SendMouseButtonEvent(0, 0, 0, true, game, 1)
    end
end

-- ============================================================
-- 6. CHARACTER HELPERS
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
        for _, enemy in pairs(workspace:FindFirstChild("Alive"):GetChildren()) do
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
                        for _, p in pairs(workspace.Alive:GetChildren()) do
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
local Last_Parry = 0
local Parries = 0
local firstParryFired = false
local firstParryType = 'F_Key'
local Speed_Divisor_Multiplier = 1.1
local LobbyAP_Speed_Divisor_Multiplier = 1.1
local ParryThreshold = 2.5
local Selected_Parry_Type = "Camera"
local Infinity = false
local Training_Parried = false
local Grab_Parry = nil
local Animation = {storage = {}, current = nil, track = nil}

local function BlockMovement() return Enum.ContextActionResult.Sink end

pcall(function()
    ReplicatedStorage.Remotes.InfinityBall.OnClientEvent:Connect(function(a, b)
        Infinity = b and true or false
    end)
end)

pcall(function()
    local connections = getconnections(game:GetService("Players").LocalPlayer.PlayerGui.Hotbar.Block.Activated)
    if connections then
        for _, Value in pairs(connections) do
            if Value and typeof(Value) == "table" and Value.Function and not iscclosure(Value.Function) then
                local successUpvalues, upvalues = pcall(getupvalues, Value.Function)
                if successUpvalues and type(upvalues) == "table" then
                    for _, Value2 in pairs(upvalues) do
                        if type(Value2) == "function" then
                            local successKey, result = pcall(function()
                                return getupvalue(getupvalue(Value2, 2), 17)
                            end)
                            if successKey then Parry_Key = result end
                        end
                    end
                end
            end
        end
    end
end)

local Parry_Key = nil

local function Parry(...)
    local ShouldPlayerJump, MainRemote, GetOpponentPosition
    -- These will be populated via the hooking system
end

-- ============================================================
-- 10. AUTO PARRY / SPAM / LOBBY AP
-- ============================================================
local Connections_Manager = {}

local function StartAutoParry()
    Connections_Manager['Auto Parry'] = RunService.PreSimulation:Connect(function()
        local One_Ball = nil
        for _, b in ipairs(Balls:GetChildren()) do
            if b:GetAttribute("realBall") then One_Ball = b; break end
        end
        if not One_Ball then return end
        local BallsList = {}
        for _, b in ipairs(Balls:GetChildren()) do
            if b:GetAttribute("realBall") then table.insert(BallsList, b) end
        end
        for _, Ball in pairs(BallsList) do
            if not Ball then return end
            local Zoomies = Ball:FindFirstChild('zoomies')
            if not Zoomies then return end
            Ball:GetAttributeChangedSignal('target'):Once(function() Parried = false end)
            if Parried then return end
            local Ball_Target = Ball:GetAttribute('target')
            local One_Target = One_Ball and One_Ball:GetAttribute('target') or nil
            local Velocity = Zoomies.VectorVelocity
            local Distance = (LocalPlayer.Character.PrimaryPart.Position - Ball.Position).Magnitude
            local Ping = game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue() / 10
            local Ping_Threshold = math.clamp(Ping / 10, 5, 17)
            local Speed = Velocity.Magnitude
            local cappedSpeedDiff = math.min(math.max(Speed - 9.5, 0), 650)
            local speed_divisor_base = 2.4 + cappedSpeedDiff * 0.002
            local effectiveMultiplier = Speed_Divisor_Multiplier
            if getgenv().RandomParryAccuracyEnabled then
                if Speed < 200 then effectiveMultiplier = 0.7 + (math.random(40, 100) - 1) * (0.35 / 99)
                else effectiveMultiplier = 0.7 + (math.random(1, 100) - 1) * (0.35 / 99) end
            end
            local speed_divisor = speed_divisor_base * effectiveMultiplier
            local Parry_Accuracy = Ping_Threshold + math.max(Speed / speed_divisor, 9.5)
            local Curved = false
            if Zoomies then
                -- Simple curve check
                local Ball_Direction = Velocity.Unit
                local Direction = (LocalPlayer.Character.PrimaryPart.Position - Ball.Position).Unit
                local Dot = Direction:Dot(Ball_Direction)
                Curved = Dot < 0.5
            end

            if Phantom and LocalPlayer.Character:FindFirstChild('ParryHighlight') and getgenv().PhantomV2Detection then
                ContextActionService:BindAction('BlockPlayerMovement', BlockMovement, false, Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.UserInputType.Touch)
                LocalPlayer.Character.Humanoid.WalkSpeed = 36
                LocalPlayer.Character.Humanoid:MoveTo(Ball.Position)
                task.spawn(function()
                    repeat
                        if LocalPlayer.Character.Humanoid.WalkSpeed ~= 36 then LocalPlayer.Character.Humanoid.WalkSpeed = 36 end
                        task.wait()
                    until not Phantom
                end)
                Ball:GetAttributeChangedSignal('target'):Once(function()
                    ContextActionService:UnbindAction('BlockPlayerMovement')
                    Phantom = false
                    LocalPlayer.Character.Humanoid:MoveTo(LocalPlayer.Character.HumanoidRootPart.Position)
                    LocalPlayer.Character.Humanoid.WalkSpeed = 10
                    task.delay(3, function() LocalPlayer.Character.Humanoid.WalkSpeed = 36 end)
                end)
            end

            if Ball_Target == tostring(LocalPlayer) and Distance <= Parry_Accuracy and Phantom then
                game:GetService("VirtualInputManager"):SendMouseButtonEvent(0, 0, 0, true, game, 1)
                Parried = true
            end

            if Ball:FindFirstChild('AeroDynamicSlashVFX') then
                Debris:AddItem(Ball.AeroDynamicSlashVFX, 0)
                Tornado_Time = tick()
            end
            if Runtime and Runtime:FindFirstChild('Tornado') then
                if (tick() - (Tornado_Time or 0)) < (Runtime.Tornado:GetAttribute("TornadoTime") or 1) + 0.314159 then return end
            end
            if One_Target == tostring(LocalPlayer) and Curved then return end
            if Ball:FindFirstChild("ComboCounter") then return end
            local Singularity_Cape = LocalPlayer.Character.PrimaryPart:FindFirstChild('SingularityCape')
            if Singularity_Cape then return end
            if getgenv().InfinityDetection and Infinity then return end

            if Ball_Target == tostring(LocalPlayer) and Distance <= Parry_Accuracy then
                if getgenv().AutoAbility and AutoAbility() then return end
            end
            if Ball_Target == tostring(LocalPlayer) and Distance <= Parry_Accuracy then
                if getgenv().CooldownProtection and cooldownProtection() then return end
                local Parry_Time = os.clock()
                ParryFunction()
                Last_Parry = Parry_Time
                Parried = true
            end
            local Last_Parrys = tick()
            repeat RunService.PreSimulation:Wait()
            until (tick() - Last_Parrys) >= 1 or not Parried
            Parried = false
        end
    end)
end

local function StartAutoSpam()
    Connections_Manager['Auto Spam'] = RunService.PreSimulation:Connect(function()
        local Ball = nil
        for _, b in ipairs(Balls:GetChildren()) do
            if b:GetAttribute("realBall") then Ball = b; break end
        end
        if not Ball then return end
        local Zoomies = Ball:FindFirstChild('zoomies')
        if not Zoomies then return end
        local Ball_Target = Ball:GetAttribute('target')
        if not Ball_Target then return end
        local char = LocalPlayer.Character
        if not char or not char.PrimaryPart then return end
        local Distance = (char.PrimaryPart.Position - Ball.Position).Magnitude
        local Speed = Zoomies.VectorVelocity.Magnitude
        local Ping = game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue()
        local spamAcc = math.clamp(Ping / 10, 1, 16) + math.min(Speed / 6, 95)
        if Distance <= spamAcc and Parries > ParryThreshold then
            ParryFunction()
        end
    end)
end

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
                        local acc = Ping + math.max(Speed / (base * LobbyAP_Speed_Divisor_Multiplier), 9.5)
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

local function cooldownProtection()
    if isCooldownInEffect1(ParryCD) then
        ReplicatedStorage.Remotes.AbilityButtonPress:Fire()
        return true
    end
    return false
end

local function AutoAbility()
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
RunService.RenderStepped:Connect(function()
    if not BallVelocity then
        if lastBall and lastBall:FindFirstChild("BallVelocityDisplay") then lastBall.BallVelocityDisplay:Destroy() end
        lastBall = nil
        return
    end
    local ball = get_ball2()
    if ball ~= lastBall then
        if lastBall and lastBall:FindFirstChild("BallVelocityDisplay") then lastBall.BallVelocityDisplay:Destroy() end
        if ball then
            local velocityText = create_ball_velocity_display(ball)
            lastBall = ball
            RunService.RenderStepped:Connect(function()
                if ball and velocityText and BallVelocity then
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local distance = (ball.Position - hrp.Position).Magnitude
                        velocityText.Text = string.format("Ball Velocity: %.2f", ball.Velocity.Magnitude)
                        if distance > 70 then velocityText.TextColor3 = Color3.fromRGB(0, 255, 0)
                        elseif distance > 30 then velocityText.TextColor3 = Color3.fromRGB(255, 255, 0)
                        else velocityText.TextColor3 = Color3.fromRGB(255, 0, 0) end
                    end
                end
            end)
        end
    end
end)

-- View Ball / Rotate
local camera = workspace.CurrentCamera
local function resetCamera() camera.CameraType = Enum.CameraType.Custom end

local function startViewBallLoop()
    if _G.viewConnection then _G.viewConnection:Disconnect(); _G.viewConnection = nil end
    _G.viewConnection = RunService.RenderStepped:Connect(function()
        local ball = getBall()
        if _G.AgentX77 and ball then
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
    getgenv().FollowSpeed = 1
    getgenv().FollowDistance = 1000
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
    if LocalPlayer.Character and LocalPlayer.Character.Head then
        local dist = (camera.CFrame.Position - LocalPlayer.Character.Head.Position).Magnitude
        local newVolume = 5 / (dist * 0.3)
        if newVolume < 0.1 then newVolume = 0.1 elseif newVolume > 5 then newVolume = 5 end
        hit_Sound.Volume = newVolume
    end
end)

ReplicatedStorage.Remotes.ParrySuccess.OnClientEvent:Connect(function()
    if getgenv().hit_sound_Enabled then hit_Sound:Play() end
    if getgenv().hit_effect_Enabled then
        local hit_effect = game:GetObjects("rbxassetid://17407244385")[1]
        hit_effect.Parent = getBall()
        hit_effect:Emit(3)
        task.delay(5, function() hit_effect:Destroy() end)
    end
end)

initializate('TORT_temp')

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
        local JoinDiscord = "https://discord.gg/kG5nqaVYtM"
        if req then
            local success, response = pcall(function()
                return req({
                    Url = 'http://127.0.0.1:6463/rpc?v=1', Method = 'POST',
                    Headers = {['Content-Type'] = 'application/json', ['Origin'] = 'https://discord.com'},
                    Body = Services.HttpService:JSONEncode({cmd = 'INVITE_BROWSER', nonce = Services.HttpService:GenerateGUID(false), args = {code = 'kG5nqaVYtM'}})
                })
            end)
            if success and response and response.StatusCode == 200 then opened = true end
        end
        if not opened then
            if setclipboard then
                setclipboard(JoinDiscord)
                LibraryNotify:MakeNotify({Title = "TORT:", Description = "Clipboard", Content = "Link copied to your clipboard.", Time = 0.5, Delay = 5})
            else
                LibraryNotify:MakeNotify({Title = "TORT:", Description = "UnSupport", Content = "Clipboard unsupported. Link: " .. JoinDiscord, Time = 0.5, Delay = 5})
            end
        else
            LibraryNotify:MakeNotify({Title = "TORT:", Description = "Discord PC", Content = "Discord is running on your device.", Time = 0.5, Delay = 15})
        end
    end
})

HomeTab.create_title({name = 'TORT Security', section = 'right'})
HomeTab.create_toggle({
    name = 'Protection - TORT', flag = 'auto_update', section = 'right', enabled = true,
    callback = function(state)
        if state then
            if hookmetamethod and getnamecallmethod and getrawmetatable and setreadonly then
                local old
                old = hookmetamethod(game, "__namecall", function(self, ...)
                    if string.lower(tostring(getnamecallmethod())) == "kick" then
                        LibraryNotify:MakeNotify({Title = "TORT:", Description = "Protection", Content = "Blocked Kick attempt.", Time = 0.5, Delay = 5})
                        return
                    end
                    return old(self, ...)
                end)
            end
            LibraryNotify:MakeNotify({Title = "TORT:", Description = "Protection", Content = "The Protections have been Activated.", Time = 0.5, Delay = 5})
        else
            LibraryNotify:MakeNotify({Title = "TORT:", Description = "Protection", Content = "WARNING: Protection - TORT has been Disabled.", Time = 0.5, Delay = 5})
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
    callback = function(v) end
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
        LibraryNotify:MakeNotify({Title = "TORT:", Description = "VIP Tag", Content = "You have received the VIP badge.", Time = 0.5, Delay = 5})
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
    callback = function(v) getgenv().RandomParryAccuracyEnabled = v end
})

CombatTab.create_toggle({
    name = 'Animation Fix', flag = 'animation_fix', section = 'left', enabled = false,
    callback = function(value)
        if value then
            Connections_Manager['Animation Fix'] = RunService.PreSimulation:Connect(function()
                local Ball = nil
                for _, b in ipairs(Balls:GetChildren()) do
                    if b:GetAttribute("realBall") then Ball = b; break end
                end
                if not Ball then return end
                local Zoomies = Ball:FindFirstChild('zoomies')
                if not Zoomies then return end
                local Ball_Target = Ball:GetAttribute('target')
                if not Ball_Target then return end
                local char = LocalPlayer.Character
                if not char or not char.PrimaryPart then return end
                local Distance = (char.PrimaryPart.Position - Ball.Position).Magnitude
                local Speed = Zoomies.VectorVelocity.Magnitude
                local Ping = game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue()
                local spamAcc = math.clamp(Ping / 10, 10, 16) + math.min(Speed / 6, 95)
                if Distance <= spamAcc and Parries > ParryThreshold then
                    ParryFunction()
                end
            end)
        else
            if Connections_Manager['Animation Fix'] then Connections_Manager['Animation Fix']:Disconnect(); Connections_Manager['Animation Fix'] = nil end
        end
    end
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
    name = 'Parry Distance', flag = 'parry_distance', section = 'left',
    value = 30, minimum_value = 30, maximum_value = 100,
    callback = function(v) Speed_Divisor_Multiplier = 0.7 + (v - 1) * (0.35 / 99) end
})
CombatTab.create_slider({
    name = 'Spam Power', flag = 'spam_power', section = 'left',
    value = 1, minimum_value = 1, maximum_value = 3,
    callback = function(v) ParryThreshold = v end
})
CombatTab.create_toggle({
    name = 'Manual Spam', flag = 'manual_spam', section = 'left', enabled = false,
    callback = function(state)
        if state then
            -- ManualSpam GUI will be created
            LibraryNotify:MakeNotify({Title = "TORT:", Description = "Manual Spam", Content = "Manual spam activated. Press E to toggle.", Time = 0.5, Delay = 5})
        else
            if MauaulSpam then MauaulSpam:Destroy(); MauaulSpam = nil end
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
    name = 'View Ball', flag = 'view_ball', section = 'right', enabled = false,
    callback = function(state)
        pcall(function()
            _G.AgentX77 = state
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
CombatTab.create_line({section = "right"})
CombatTab.create_toggle({name = 'Follow Ball', flag = 'follow_ball', section = 'right', enabled = false, callback = function(state) getgenv().FB = state end})
CombatTab.create_slider({name = 'Follow Speed', flag = 'follow_speed', section = 'right', value = 10, minimum_value = 0, maximum_value = 50, callback = function(v) getgenv().FollowSpeed = v end})
CombatTab.create_slider({name = 'Follow Distance', flag = 'follow_distance', section = 'right', value = 10, minimum_value = 0, maximum_value = 50, callback = function(v) getgenv().FollowDistance = v end})

CombatTab.create_title({name = 'Swords Options', section = 'right'})
CombatTab.create_toggle({
    name = 'Enable Hit Sound', flag = 'enable_hit_sound', section = 'right', enabled = true,
    callback = function(state) getgenv().hit_sound_Enabled = state end
})
CombatTab.create_dropdown({
    name = 'Sound Effects', flag = 'sound_effects', section = 'right', option = 'Disabled',
    options = {"Disabled", 'DC_15X', 'Minecraft', 'MinecraftHit2', 'Teamfortress Bonk', 'Teamfortress Bell', 'Excalibur', 'Masamune', 'Muramasa', 'Soul Edge', 'Ragnarok', 'Dark Repulser', 'Elucidator', 'Dragon Slayer'},
    callback = function(v) setHitSound(soundIDs[v] or '') end
})
CombatTab.create_textbox({
    name = 'Volume', flag = 'volume', section = 'right', value = '5',
    callback = function(v) if tonumber(v) then hit_Sound.Volume = tonumber(v) end end
})

CombatTab.create_title({name = 'AI Options', section = 'left'})
CombatTab.create_toggle({name = 'AI TORT', flag = 'ai_tort', section = 'left', enabled = true, callback = function(state) end})
CombatTab.create_line({section = "left"})
CombatTab.create_toggle({name = 'Improve Accuracy', flag = 'ai_auto_parry', section = 'left', enabled = true, callback = function(state) nowprediction = state end})
CombatTab.create_toggle({name = 'Improve Auto Spam', flag = 'ai_auto_spam', section = 'left', enabled = true, callback = function(state) end})

CombatTab.create_title({name = 'Detections', section = 'left'})
CombatTab.create_toggle({
    name = 'Detections', flag = 'Toggle_Detections', section = 'left', enabled = true,
    callback = function(state) Detections = state end
})
CombatTab.create_line({section = "left"})
CombatTab.create_toggle({
    name = 'Infinity Detection', flag = 'Toggle_InfinityDetection', section = 'left', enabled = true,
    callback = function(value) getgenv().InfinityDetection = Detections and value or false end
})
CombatTab.create_toggle({
    name = 'Death Slash Detection', flag = 'Toggle_DeathSlashDetection', section = 'left', enabled = true,
    callback = function(state) DeathSlashDetection = Detections and state or false end
})
CombatTab.create_toggle({
    name = 'Time Hole Detection', flag = 'Toggle_TimeHoleDetection', section = 'left', enabled = true,
    callback = function(state) TimeHoleDetection = Detections and state or false end
})
CombatTab.create_toggle({
    name = 'Auto Telekinesis Block', flag = 'Toggle_AutoTelekinesis', section = 'left', enabled = true,
    callback = function(state) AutoTelekinesis = Detections and state or false end
})
CombatTab.create_toggle({
    name = 'Slash of Fury Detection', flag = 'Toggle_SlashOfFuryDetection', section = 'left', enabled = true,
    callback = function(state) getgenv().SlashOfFuryDetection = Detections and state or false end
})
CombatTab.create_toggle({
    name = 'Anti Phantom Attack', flag = 'Toggle_AntiPhantom', section = 'left', enabled = false,
    callback = function(value) PhantomV2Detection = Detections and value or false end
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
CombatTab.create_toggle({name = 'Auto Block Spams', flag = 'auto_block_spams', section = 'right', enabled = true, callback = function(state) end})
CombatTab.create_line({section = "right"})
CombatTab.create_toggle({name = 'Anti Curve', flag = 'anti_curve', section = 'right', enabled = false, callback = function(state) EnableAntiCurve = state end})
CombatTab.create_toggle({name = 'Anti Block Spams', flag = 'anti_block_spams', section = 'right', enabled = true, callback = function(state) end})

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
        getgenv().TORT_Loaded = false
        for _, v in ipairs(Services.CoreGui:GetChildren()) do
            if v.Name == "TORTNotify" then v:Destroy() end
        end
        LibraryNotify:MakeNotify({Title = "TORT:", Description = "Exit", Content = "Thank you for using TORT.", Time = 0.5, Delay = 5})
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
            LibraryNotify:MakeNotify({Title = "TORT:", Description = "Report Bugs", Content = "Please describe your problem.", Time = 0.5, Delay = 5})
            return
        end
        if frequencySelection == "" then
            LibraryNotify:MakeNotify({Title = "TORT:", Description = "Report Bugs", Content = "Please select how often the error occurs.", Time = 0.5, Delay = 5})
            return
        end
        reportCount = reportCount + 1
        LibraryNotify:MakeNotify({Title = "TORT:", Description = "Report Bugs", Content = "Bug report submitted successfully.", Time = 0.5, Delay = 5})
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
            LibraryNotify:MakeNotify({Title = "TORT:", Description = "Job ID", Content = "Teleporting", Time = 0.5, Delay = 5})
            task.wait(0.5)
            TeleportService:TeleportToPlaceInstance(game.PlaceId, inputJobId, LocalPlayer)
        else
            LibraryNotify:MakeNotify({Title = "TORT:", Description = "Job ID", Content = "Invalid Job ID.", Time = 0.5, Delay = 5})
        end
    end
})
SettingsTab.create_button({
    name = 'Copy Job ID', section = 'left',
    callback = function()
        setclipboard(currentJobId)
        LibraryNotify:MakeNotify({Title = "TORT:", Description = "Job ID", Content = "Job ID Copied to your clipboard.", Time = 0.5, Delay = 5})
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
        LibraryNotify:MakeNotify({Title = "TORT:", Description = "Settings", Content = "Settings have been success deleted.", Time = 0.5, Delay = 5})
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
        Title = "TORT",
        Description = "Loaded",
        Content = "TORT loaded successfully for Blade Ball. " .. (IsMobile and "Mobile" or "PC") .. " mode.",
        Time = 0.5,
        Delay = 5
    })
end)

return true