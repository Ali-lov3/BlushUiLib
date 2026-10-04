local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local CoreGui = game:GetService("CoreGui")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local Library = { Flags = {}, Setters = {} }
local Flags = Library.Flags
local Setters = Library.Setters
local Closers = {}
local AccentHooks = {}
local CardAlpha = 0.35

local State = {
	Pages = {},
	NavItems = {},
	Panels = {},
	Entries = {},
	Sections = 0,
}

local Lucide
pcall(function()
	Lucide = loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/icons.lua"))()
end)

local function ResolveIcon(Name)
	if type(Name) == "number" then return "rbxassetid://" .. Name end
	if type(Name) == "string" then
		if string.match(Name, "^rbxassetid://") then return Name end
		if string.match(Name, "^%d+$") then return "rbxassetid://" .. Name end
		local Key = string.lower(Name)
		if type(Lucide) == "function" then
			local Ok, Data = pcall(Lucide, Key)
			if Ok and type(Data) == "table" then
				local Id = Data.id or Data.Id or Data[1]
				local Size = Data.imageRectSize or Data.ImageRectSize or Data[2]
				local Offset = Data.imageRectOffset or Data.imageRectPosition or Data.ImageRectOffset or Data[3]
				if Id then return "rbxassetid://" .. tostring(Id), Offset, Size end
			end
		elseif type(Lucide) == "table" then
			for _, Set in { Lucide["48px"], Lucide["256px"], Lucide } do
				if type(Set) == "table" then
					local Data = Set[Key]
					if type(Data) == "table" and Data[1] then
						return "rbxassetid://" .. tostring(Data[1]), Data[3], Data[2]
					end
				end
			end
		end
	end
	return "rbxassetid://0"
end

local function ToVector2(Value)
	if typeof(Value) == "Vector2" then return Value end
	if type(Value) == "table" then return Vector2.new(Value[1] or Value.X or 0, Value[2] or Value.Y or 0) end
	return Vector2.new(0, 0)
end

local function ApplyIcon(Object, Name)
	if not Name then return end
	local Image, Offset, Size = ResolveIcon(Name)
	Object.Image = Image
	if Offset then Object.ImageRectOffset = ToVector2(Offset) end
	if Size then Object.ImageRectSize = ToVector2(Size) end
end

local function LoadImage(Source, FileName)
	if Source == nil or Source == "" then return nil end
	if type(Source) == "number" then return "rbxassetid://" .. Source end
	if string.match(Source, "^rbxassetid://") or string.match(Source, "^rbxthumb://") then return Source end
	if string.match(Source, "^%d+$") then return "rbxassetid://" .. Source end
	local Custom = getcustomasset or getsynasset
	if not Custom then return nil end
	local Ok, Result = pcall(function()
		if string.match(Source, "^https?://") then
			writefile(FileName, game:HttpGet(Source))
			return Custom(FileName)
		end
		return Custom(Source)
	end)
	if Ok and Result then return Result end
	return nil
end

local Theme = {
	Window = Color3.fromRGB(13, 13, 13),
	Sidebar = Color3.fromRGB(14, 14, 14),
	Card = Color3.fromRGB(20, 20, 20),
	Input = Color3.fromRGB(27, 27, 27),
	Box = Color3.fromRGB(36, 36, 36),
	Stroke = Color3.fromRGB(48, 48, 48),
	Text = Color3.fromRGB(238, 238, 238),
	Dim = Color3.fromRGB(150, 150, 150),
	White = Color3.fromRGB(255, 255, 255),
	Black = Color3.fromRGB(14, 14, 14),
	Red = Color3.fromRGB(255, 80, 80),
	Muted = Color3.fromRGB(88, 88, 88),
	Bar = Color3.fromRGB(17, 17, 17),
	Accent = Color3.fromRGB(255, 255, 255),
}

local RobotoFamily = Font.fromEnum(Enum.Font.Roboto).Family
local Fonts = {
	Regular = Font.new(RobotoFamily, Enum.FontWeight.Regular),
	Medium = Font.new(RobotoFamily, Enum.FontWeight.Medium),
	Bold = Font.new(RobotoFamily, Enum.FontWeight.Bold),
}

Flags.Accent = Theme.Accent

local function Contrast(Color)
	local Luma = 0.299 * Color.R + 0.587 * Color.G + 0.114 * Color.B
	return Luma > 0.55 and Theme.Black or Theme.White
end

local function OnAccent(Callback)
	table.insert(AccentHooks, Callback)
	Callback()
end

local function SetAccent(Color)
	Theme.Accent = Color
	Flags.Accent = Color
	for _, Hook in AccentHooks do
		Hook()
	end
end

local function Make(Class, Props, Parent)
	local Object = Instance.new(Class)
	if Object:IsA("GuiObject") then
		Object.BorderSizePixel = 0
	end
	if Object:IsA("TextLabel") or Object:IsA("TextButton") or Object:IsA("TextBox") then
		Object.BackgroundTransparency = 1
		Object.FontFace = Fonts.Medium
		Object.TextSize = 15
		Object.TextColor3 = Theme.Text
		Object.TextXAlignment = Enum.TextXAlignment.Left
		Object.TextYAlignment = Enum.TextYAlignment.Center
	end
	if Object:IsA("TextLabel") or Object:IsA("TextButton") then
		Object.Text = ""
	end
	if Object:IsA("TextButton") then
		Object.AutoButtonColor = false
	end
	if Object:IsA("ImageLabel") then
		Object.BackgroundTransparency = 1
	end
	for Key, Value in Props do
		Object[Key] = Value
	end
	Object.Parent = Parent
	return Object
end

local function Corner(Parent, Radius)
	return Make("UICorner", { CornerRadius = UDim.new(0, Radius) }, Parent)
end

local function Stroke(Parent, Color, Transparency, Thickness)
	return Make("UIStroke", {
		Color = Color,
		Transparency = Transparency or 0,
		Thickness = Thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, Parent)
end

local function Icon(Parent, Name, Size, Color)
	local Image = Make("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(Size, Size),
		ImageColor3 = Color or Theme.Text,
	}, Parent)
	ApplyIcon(Image, Name)
	return Image
end

local function Shadow(Parent)
	return Make("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 76, 1, 76),
		Image = "rbxassetid://6014261993",
		ImageColor3 = Color3.fromRGB(255, 255, 255),
		ImageTransparency = 0.85,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49, 49, 450, 450),
		ZIndex = 0,
	}, Parent)
end

local function IsPress(Input)
	return Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch
end

local function IsMove(Input)
	return Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch
end

local Notifier = {
	Logs = {},
	Unread = 0,
	Active = {},
	Counter = 0,
	Kinds = {
		info = { Icon = "info", Alt = "info" },
		success = { Icon = "check-circle", Alt = "circle-check", Color = Color3.fromRGB(52, 168, 120) },
		warning = { Icon = "alert-triangle", Alt = "triangle-alert", Color = Color3.fromRGB(245, 166, 35) },
		error = { Icon = "x-circle", Alt = "circle-x", Color = Color3.fromRGB(255, 80, 80) },
	},
}

function Notifier.Style(Kind)
	local Entry = Notifier.Kinds[Kind] or Notifier.Kinds.info
	return Entry.Icon, Entry.Color or Theme.Accent
end

function Notifier.MakeIcon(Parent, Kind, Size)
	local Name, Color = Notifier.Style(Kind)
	local Image = Icon(Parent, Name, Size, Color)
	if Image.Image == "rbxassetid://0" then
		local Alt = (Notifier.Kinds[Kind] or Notifier.Kinds.info).Alt
		if Alt then ApplyIcon(Image, Alt) end
	end
	return Image, Color
end

function Notifier.Init(Gui)
	Notifier.Holder = Make("Frame", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.fromOffset(260, 400),
		BackgroundTransparency = 1,
		ZIndex = 500,
	}, Gui)
	Make("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
	}, Notifier.Holder)
end

function Notifier.Push(Title, Text, Duration, Kind)
	Duration = Duration or 4
	Kind = Notifier.Kinds[Kind] and Kind or "info"
	Title = tostring(Title)
	Text = tostring(Text)
	table.insert(Notifier.Logs, 1, { Title = Title, Text = Text, Kind = Kind, Time = os.date("%H:%M:%S") })
	if #Notifier.Logs > 50 then table.remove(Notifier.Logs) end
	Notifier.Unread += 1
	if Notifier.Changed then Notifier.Changed() end
	if not Notifier.Holder then return end

	Notifier.Counter += 1
	local _, Color = Notifier.Style(Kind)
	local Wrapper = Make("Frame", {
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundTransparency = 1,
		LayoutOrder = Notifier.Counter,
		ZIndex = 500,
	}, Notifier.Holder)
	local Toast = Make("Frame", {
		Position = UDim2.new(1, 40, 0, 0),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(18, 18, 18),
		ZIndex = 501,
	}, Wrapper)
	Corner(Toast, 10)
	Stroke(Toast, Theme.Stroke, 0.25, 1)
	local Tint = Make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color,
		ZIndex = 502,
	}, Toast)
	Corner(Tint, 10)
	Make("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.82),
			NumberSequenceKeypoint.new(0.6, 1),
			NumberSequenceKeypoint.new(1, 1),
		}),
	}, Tint)
	local Badge = Make("Frame", {
		Position = UDim2.fromOffset(12, 14),
		Size = UDim2.fromOffset(28, 28),
		BackgroundColor3 = Color,
		BackgroundTransparency = 0.82,
		ZIndex = 503,
	}, Toast)
	Corner(Badge, 8)
	local KindIcon = Notifier.MakeIcon(Badge, Kind, 16)
	KindIcon.Position = UDim2.fromScale(0.5, 0.5)
	KindIcon.ZIndex = 504
	Make("TextLabel", {
		Position = UDim2.fromOffset(48, 8),
		Size = UDim2.new(1, -70, 0, 18),
		Text = Title,
		FontFace = Fonts.Bold,
		TextSize = 13,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 503,
	}, Toast)
	Make("TextLabel", {
		Position = UDim2.fromOffset(48, 26),
		Size = UDim2.new(1, -60, 0, 18),
		Text = Text,
		TextColor3 = Theme.Dim,
		TextSize = 12,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 503,
	}, Toast)
	local CloseIcon = Icon(Toast, "x", 12, Theme.Dim)
	CloseIcon.Position = UDim2.new(1, -15, 0, 15)
	CloseIcon.ZIndex = 503
	local Progress = Make("Frame", {
		Position = UDim2.new(0, 12, 1, -5),
		Size = UDim2.new(1, -24, 0, 2),
		BackgroundColor3 = Color,
		BackgroundTransparency = 0.35,
		ZIndex = 503,
	}, Toast)
	Corner(Progress, 1)
	local Click = Make("TextButton", { Size = UDim2.fromScale(1, 1), ZIndex = 505 }, Toast)

	local Gone = false
	local function Dismiss()
		if Gone then return end
		Gone = true
		for Index, Fn in Notifier.Active do
			if Fn == Dismiss then
				table.remove(Notifier.Active, Index)
				break
			end
		end
		TweenService:Create(Toast, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(1, 40, 0, 0),
		}):Play()
		task.delay(0.25, function()
			Wrapper:Destroy()
		end)
	end

	table.insert(Notifier.Active, Dismiss)
	if #Notifier.Active > 5 then Notifier.Active[1]() end
	Click.MouseButton1Click:Connect(Dismiss)
	TweenService:Create(Toast, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 0, 0, 0),
	}):Play()
	TweenService:Create(Progress, TweenInfo.new(Duration, Enum.EasingStyle.Linear), {
		Size = UDim2.new(0, 0, 0, 2),
	}):Play()
	task.delay(Duration, Dismiss)
end

local function Rescale()
	local Camera = workspace.CurrentCamera
	if not Camera or not State.Scale then return end
	local View = Camera.ViewportSize
	State.Scale.Scale = math.clamp(math.min(View.X / State.Fit.X, View.Y / State.Fit.Y) * (Flags.UIScale or 1), 0.2, 2)
end

local function Drag(Handle, Target)
	local Dragging, Start, Origin = false, nil, nil
	Handle.InputBegan:Connect(function(Input)
		if IsPress(Input) then
			Dragging = true
			Start = Input.Position
			Origin = Target.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(Input)
		if Dragging and IsMove(Input) then
			local Delta = (Input.Position - Start) / State.Scale.Scale
			Target.Position = UDim2.fromOffset(Origin.X.Offset + Delta.X, Origin.Y.Offset + Delta.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(Input)
		if IsPress(Input) then
			Dragging = false
		end
	end)
end

local function SetVisible(Value)
	State.Windows.Visible = Value
	if not Value then
		for _, Close in Closers do Close() end
	end
end

local Picker = {}

function Picker.Build()
	local Width, Height = 220, 274
	local Blocker = Make("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.fromOffset(20000, 20000),
		ZIndex = 200,
		Visible = false,
	}, State.Windows)
	local Frame = Make("Frame", {
		Size = UDim2.fromOffset(Width, Height),
		BackgroundColor3 = Color3.fromRGB(20, 20, 20),
		ZIndex = 201,
		Visible = false,
		Active = true,
	}, State.Windows)
	Corner(Frame, 10)
	Stroke(Frame, Theme.Stroke, 0.2, 1)

	local SV = Make("Frame", {
		Position = UDim2.fromOffset(12, 12),
		Size = UDim2.fromOffset(196, 150),
		BackgroundColor3 = Color3.new(1, 0, 0),
		ZIndex = 202,
	}, Frame)
	Corner(SV, 6)
	local WhiteLayer = Make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 203,
	}, SV)
	Corner(WhiteLayer, 6)
	Make("UIGradient", { Transparency = NumberSequence.new(0, 1) }, WhiteLayer)
	local BlackLayer = Make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		ZIndex = 204,
	}, SV)
	Corner(BlackLayer, 6)
	Make("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }, BlackLayer)
	local Cursor = Make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1,
		ZIndex = 205,
	}, SV)
	Corner(Cursor, 7)
	Stroke(Cursor, Theme.White, 0, 2)

	local Hue = Make("Frame", {
		Position = UDim2.fromOffset(12, 172),
		Size = UDim2.fromOffset(196, 14),
		BackgroundColor3 = Theme.White,
		ZIndex = 202,
	}, Frame)
	Corner(Hue, 7)
	local HueKeys = {}
	for I = 0, 6 do
		table.insert(HueKeys, ColorSequenceKeypoint.new(I / 6, Color3.fromHSV(math.min(I / 6, 0.9999), 1, 1)))
	end
	HueKeys[#HueKeys] = ColorSequenceKeypoint.new(1, Color3.fromHSV(0, 1, 1))
	Make("UIGradient", { Color = ColorSequence.new(HueKeys) }, Hue)
	local HueKnob = Make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(16, 16),
		BackgroundColor3 = Theme.White,
		ZIndex = 203,
	}, Hue)
	Corner(HueKnob, 8)
	Stroke(HueKnob, Color3.fromRGB(30, 30, 30), 0.2, 2)

	local HexField = Make("Frame", {
		Position = UDim2.fromOffset(12, 196),
		Size = UDim2.fromOffset(110, 28),
		BackgroundColor3 = Theme.Input,
		ZIndex = 202,
	}, Frame)
	Corner(HexField, 6)
	local HexBox = Make("TextBox", {
		Size = UDim2.fromScale(1, 1),
		Text = "#FFFFFF",
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 14,
		ZIndex = 203,
	}, HexField)
	local Preview = Make("Frame", {
		Position = UDim2.fromOffset(130, 196),
		Size = UDim2.fromOffset(78, 28),
		BackgroundColor3 = Theme.White,
		ZIndex = 202,
	}, Frame)
	Corner(Preview, 6)

	local RgbBoxes = {}
	for I, Name in { "R", "G", "B" } do
		local Field = Make("Frame", {
			Position = UDim2.fromOffset(12 + (I - 1) * 68, 234),
			Size = UDim2.fromOffset(60, 28),
			BackgroundColor3 = Theme.Input,
			ZIndex = 202,
		}, Frame)
		Corner(Field, 6)
		Make("TextLabel", {
			Position = UDim2.fromOffset(8, 0),
			Size = UDim2.new(0, 14, 1, 0),
			Text = Name,
			TextColor3 = Theme.Dim,
			TextSize = 12,
			ZIndex = 203,
		}, Field)
		RgbBoxes[I] = Make("TextBox", {
			Position = UDim2.fromOffset(22, 0),
			Size = UDim2.new(1, -28, 1, 0),
			Text = "255",
			ClearTextOnFocus = false,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextSize = 14,
			ZIndex = 203,
		}, Field)
	end

	local H, S, V = 0, 0, 1
	local Current, Mode

	local function Apply()
		local Color = Color3.fromHSV(H, S, V)
		SV.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
		Cursor.Position = UDim2.fromScale(S, 1 - V)
		HueKnob.Position = UDim2.fromScale(H, 0.5)
		Preview.BackgroundColor3 = Color
		HexBox.Text = "#" .. string.upper(Color:ToHex())
		RgbBoxes[1].Text = tostring(math.round(Color.R * 255))
		RgbBoxes[2].Text = tostring(math.round(Color.G * 255))
		RgbBoxes[3].Text = tostring(math.round(Color.B * 255))
		if Current then
			Current.Swatch.BackgroundColor3 = Color
			Flags[Current.Flag] = Color
			if Current.OnChange then Current.OnChange(Color) end
		end
	end

	local function SetColor(Color)
		H, S, V = Color:ToHSV()
		Apply()
	end

	function Picker.Close()
		Frame.Visible = false
		Blocker.Visible = false
		Current = nil
	end

	function Picker.IsOpenFor(Swatch)
		return Frame.Visible and Current ~= nil and Current.Swatch == Swatch
	end

	function Picker.Open(Swatch, FlagName, OnChange)
		Current = { Swatch = Swatch, Flag = FlagName, OnChange = OnChange }
		SetColor(Flags[FlagName] or Swatch.BackgroundColor3)
		local Camera = workspace.CurrentCamera
		local View = Camera and Camera.ViewportSize or Vector2.new(1280, 720)
		local Factor = State.Scale.Scale
		local X = Swatch.AbsolutePosition.X + Swatch.AbsoluteSize.X - Width * Factor
		local Y = Swatch.AbsolutePosition.Y + Swatch.AbsoluteSize.Y + 6 * Factor
		X = math.clamp(X, 8, math.max(8, View.X - Width * Factor - 8))
		if Y + Height * Factor > View.Y - 8 then
			Y = Swatch.AbsolutePosition.Y - Height * Factor - 6 * Factor
		end
		Y = math.clamp(Y, 8, math.max(8, View.Y - Height * Factor - 8))
		local Local = (Vector2.new(X, Y) - State.Root.AbsolutePosition) / Factor
		Frame.Position = UDim2.fromOffset(Local.X, Local.Y)
		Blocker.Visible = true
		Frame.Visible = true
	end

	local function FromSV(Input)
		S = math.clamp((Input.Position.X - SV.AbsolutePosition.X) / SV.AbsoluteSize.X, 0, 1)
		V = 1 - math.clamp((Input.Position.Y - SV.AbsolutePosition.Y) / SV.AbsoluteSize.Y, 0, 1)
		Apply()
	end
	local function FromHue(Input)
		H = math.clamp((Input.Position.X - Hue.AbsolutePosition.X) / Hue.AbsoluteSize.X, 0, 1)
		Apply()
	end

	SV.InputBegan:Connect(function(Input)
		if IsPress(Input) then
			Mode = "sv"
			FromSV(Input)
		end
	end)
	Hue.InputBegan:Connect(function(Input)
		if IsPress(Input) then
			Mode = "hue"
			FromHue(Input)
		end
	end)
	UserInputService.InputChanged:Connect(function(Input)
		if Mode and IsMove(Input) then
			if Mode == "sv" then FromSV(Input) else FromHue(Input) end
		end
	end)
	UserInputService.InputEnded:Connect(function(Input)
		if IsPress(Input) then Mode = nil end
	end)

	HexBox.FocusLost:Connect(function()
		local Text = string.gsub(HexBox.Text, "#", "")
		local Ok, Color = pcall(Color3.fromHex, Text)
		if Ok and Color then
			SetColor(Color)
		else
			Apply()
		end
	end)
	for _, Box in RgbBoxes do
		Box.FocusLost:Connect(function()
			local R = tonumber(RgbBoxes[1].Text)
			local G = tonumber(RgbBoxes[2].Text)
			local B = tonumber(RgbBoxes[3].Text)
			if R and G and B then
				SetColor(Color3.fromRGB(math.clamp(R, 0, 255), math.clamp(G, 0, 255), math.clamp(B, 0, 255)))
			else
				Apply()
			end
		end)
	end

	Blocker.MouseButton1Click:Connect(Picker.Close)
	table.insert(Closers, Picker.Close)
end

local function Checkbox(Parent, Order, Spec)
	local Flag = Spec.Flag or Spec.Name
	local Faint = Spec.Disabled or Spec.Color
	local Row = Make("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, LayoutOrder = Order }, Parent)
	local Box = Make("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(20, 20),
		BackgroundColor3 = Theme.Box,
		BackgroundTransparency = Faint and 0.55 or 0,
	}, Row)
	Corner(Box, 5)
	local Check = Icon(Box, "check", 16, Theme.Black)
	Check.Position = UDim2.fromScale(0.5, 0.5)
	local Left = Make("Frame", {
		Position = UDim2.fromOffset(30, 0),
		Size = UDim2.new(1, -30, 1, 0),
		BackgroundTransparency = 1,
	}, Row)
	Make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 9),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, Left)
	Make("TextLabel", {
		Size = UDim2.fromOffset(0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = Spec.Name,
		TextColor3 = Spec.Disabled and Theme.Muted or Spec.Color or Theme.Text,
		LayoutOrder = 1,
	}, Left)
	if Spec.Badge then
		local Badge = Make("Frame", {
			Size = UDim2.fromOffset(39, 20),
			BackgroundColor3 = Theme.Box,
			LayoutOrder = 2,
		}, Left)
		Corner(Badge, 5)
		Stroke(Badge, Theme.Stroke, 0.2, 1)
		Make("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			Text = Spec.Badge,
			FontFace = Fonts.Bold,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Center,
		}, Badge)
	end
	if Spec.Hint then
		Make("TextLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			Text = Spec.Hint,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextColor3 = Theme.Dim,
			TextSize = 14,
		}, Row)
	end
	if Spec.Key then
		local Chip = Make("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -32, 0.5, 0),
			Size = UDim2.fromOffset(22, 18),
			BackgroundColor3 = Theme.Box,
		}, Row)
		Corner(Chip, 5)
		Make("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			Text = Spec.Key,
			TextColor3 = Theme.Dim,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Center,
		}, Chip)
	end
	if Spec.ColorPicker then
		local Swatch = Make("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(24, 22),
			BackgroundTransparency = 0,
			BackgroundColor3 = Spec.ColorPicker,
		}, Row)
		Corner(Swatch, 5)
		local ColorFlag = Spec.ColorFlag or (Flag .. "Color")
		Flags[ColorFlag] = Spec.ColorPicker
		if Spec.Save ~= false then
			Setters[ColorFlag] = function(Color)
				if typeof(Color) ~= "Color3" then return end
				Swatch.BackgroundColor3 = Color
				Flags[ColorFlag] = Color
				if Spec.ColorCallback then Spec.ColorCallback(Color) end
			end
		end
		Swatch.MouseButton1Click:Connect(function()
			if Picker.IsOpenFor(Swatch) then
				Picker.Close()
			else
				Picker.Open(Swatch, ColorFlag, Spec.ColorCallback)
			end
		end)
	end
	local On = false
	local Object = { Row = Row }
	function Object.Set(Value)
		On = Value and true or false
		Flags[Flag] = On
		Box.BackgroundColor3 = On and Theme.Accent or Theme.Box
		Check.Visible = On
		if Spec.Callback then Spec.Callback(On) end
	end
	OnAccent(function()
		Check.ImageColor3 = Contrast(Theme.Accent)
		if On then Box.BackgroundColor3 = Theme.Accent end
	end)
	if Spec.Save ~= false then Setters[Flag] = Object.Set end
	if not Spec.Disabled then
		local Button = Make("TextButton", { Size = UDim2.new(1, Spec.ColorPicker and -70 or 0, 1, 0) }, Row)
		Button.MouseButton1Click:Connect(function()
			Object.Set(not On)
		end)
	end
	Object.Set(Spec.Default and true or false)
	return Object
end

local function Slider(Parent, Order, Spec)
	local Flag = Spec.Flag or Spec.Name
	local Min, Max, Step = Spec.Min or 0, Spec.Max or 100, Spec.Step or 1
	local Format = Spec.Format or function(Value) return tostring(Value) end
	local Row = Make("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, LayoutOrder = Order }, Parent)
	Make("TextLabel", { Size = UDim2.new(1, 0, 0, 20), Text = Spec.Name }, Row)
	local Value = Make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 20),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = Theme.Dim,
		TextSize = 14,
	}, Row)
	local Track = Make("Frame", {
		Position = UDim2.fromOffset(0, 30),
		Size = UDim2.new(1, 0, 0, 5),
		BackgroundColor3 = Color3.fromRGB(42, 42, 42),
	}, Row)
	Corner(Track, 3)
	local Fill = Make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Theme.Accent }, Track)
	Corner(Fill, 3)
	local Knob = Make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = Theme.Accent,
	}, Track)
	Corner(Knob, 7)
	OnAccent(function()
		Fill.BackgroundColor3 = Theme.Accent
		Knob.BackgroundColor3 = Theme.Accent
	end)
	local Hit = Make("TextButton", { Position = UDim2.new(0, -6, 0, 18), Size = UDim2.new(1, 12, 0, 26) }, Row)
	local function Set(Input)
		Input = tonumber(Input)
		if not Input then return end
		Input = math.clamp(Input, Min, Max)
		Input = math.floor(Input / Step + 0.5) * Step
		Input = tonumber(string.format("%.4f", Input))
		local Alpha = (Input - Min) / (Max - Min)
		Fill.Size = UDim2.fromScale(Alpha, 1)
		Knob.Position = UDim2.fromScale(Alpha, 0.5)
		Value.Text = Format(Input)
		Flags[Flag] = Input
		if Spec.Callback then Spec.Callback(Input) end
	end
	if Spec.Save ~= false then Setters[Flag] = Set end
	local Dragging = false
	local function FromInput(Input)
		local Alpha = math.clamp((Input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
		Set(Min + (Max - Min) * Alpha)
	end
	Hit.InputBegan:Connect(function(Input)
		if IsPress(Input) then
			Dragging = true
			FromInput(Input)
		end
	end)
	UserInputService.InputChanged:Connect(function(Input)
		if Dragging and IsMove(Input) then
			FromInput(Input)
		end
	end)
	UserInputService.InputEnded:Connect(function(Input)
		if Dragging and IsPress(Input) then
			Dragging = false
			if Spec.Commit then Spec.Commit(Flags[Flag]) end
		end
	end)
	Set(Spec.Default or Min)
	return { Row = Row, Set = Set }
end

local function Dropdown(Parent, Order, Spec)
	local Flag = Spec.Flag or Spec.Name
	local Z = Spec.Z or 100
	local Multi = Spec.Multi
	local Searchable = Spec.Search
	local Holder = Make("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = Order,
	}, Parent)
	Make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, Holder)
	Make("TextLabel", { Size = UDim2.new(1, 0, 0, 18), Text = Spec.Name, LayoutOrder = 1 }, Holder)
	local Field = Make("TextButton", {
		Size = UDim2.new(1, 0, 0, 33),
		BackgroundTransparency = 0,
		BackgroundColor3 = Theme.Input,
		LayoutOrder = 2,
	}, Holder)
	Corner(Field, 6)
	local Display = Make("TextLabel", {
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -40, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, Field)
	local Arrow = Icon(Field, "chevron-down", 20, Theme.Dim)
	Arrow.Position = UDim2.new(1, -20, 0.5, 0)

	local Shell, List, QueryBox, EmptyLabel
	if Searchable then
		Shell = Make("Frame", {
			Position = UDim2.new(0, 0, 1, 4),
			Size = UDim2.new(1, 0, 0, 138),
			BackgroundColor3 = Color3.fromRGB(22, 22, 22),
			Active = true,
			Visible = false,
			ZIndex = Z,
		}, Field)
		Corner(Shell, 6)
		Stroke(Shell, Theme.Stroke, 0, 1)
		local QueryField = Make("Frame", {
			Position = UDim2.fromOffset(6, 6),
			Size = UDim2.new(1, -12, 0, 26),
			BackgroundColor3 = Theme.Input,
			ZIndex = Z + 1,
		}, Shell)
		Corner(QueryField, 5)
		local QueryIcon = Icon(QueryField, "search", 14, Theme.Dim)
		QueryIcon.Position = UDim2.fromOffset(14, 13)
		QueryIcon.ZIndex = Z + 2
		QueryBox = Make("TextBox", {
			Position = UDim2.fromOffset(28, 0),
			Size = UDim2.new(1, -34, 1, 0),
			Text = "",
			PlaceholderText = "search...",
			PlaceholderColor3 = Theme.Dim,
			ClearTextOnFocus = false,
			TextSize = 13,
			ZIndex = Z + 2,
		}, QueryField)
		EmptyLabel = Make("TextLabel", {
			Position = UDim2.fromOffset(0, 38),
			Size = UDim2.new(1, 0, 0, 30),
			Text = "No results",
			TextColor3 = Theme.Dim,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Center,
			Visible = false,
			ZIndex = Z + 1,
		}, Shell)
		List = Make("ScrollingFrame", {
			Position = UDim2.fromOffset(0, 38),
			Size = UDim2.new(1, 0, 1, -38),
			BackgroundTransparency = 1,
			ScrollBarThickness = 2,
			CanvasSize = UDim2.new(),
			ZIndex = Z + 1,
		}, Shell)
	else
		List = Make("ScrollingFrame", {
			Position = UDim2.new(0, 0, 1, 4),
			Size = UDim2.new(1, 0, 0, 100),
			BackgroundTransparency = 0,
			BackgroundColor3 = Color3.fromRGB(22, 22, 22),
			ScrollBarThickness = 2,
			CanvasSize = UDim2.new(),
			Visible = false,
			ZIndex = Z,
		}, Field)
		Corner(List, 6)
		Stroke(List, Theme.Stroke, 0, 1)
		Shell = List
	end
	Make("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }, List)
	Make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, List)

	local Blocker = Make("TextButton", { Size = UDim2.fromScale(1, 1), ZIndex = Z - 1, Visible = false }, State.Gui)
	local function Close()
		Shell.Visible = false
		Blocker.Visible = false
		if QueryBox then QueryBox:ReleaseFocus() end
		TweenService:Create(Arrow, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Rotation = 0 }):Play()
	end
	table.insert(Closers, Close)
	Blocker.MouseButton1Click:Connect(Close)

	local Selected
	if Multi then
		Selected = {}
		if type(Spec.Default) == "table" then
			for Key, Value in Spec.Default do Selected[Key] = Value end
		end
	else
		Selected = Spec.Default
	end

	local Names, Painters = {}, {}
	local function Refresh()
		if Multi then
			local Parts = {}
			for _, Name in Names do
				if Selected[Name] then table.insert(Parts, Name) end
			end
			Display.Text = #Parts > 0 and table.concat(Parts, ", ") or "None"
		else
			Display.Text = (Selected ~= nil and Selected ~= "") and tostring(Selected) or "None"
		end
		Flags[Flag] = Selected
		for _, Paint in Painters do Paint() end
	end

	local function Build()
		for _, Child in List:GetChildren() do
			if Child:IsA("TextButton") then Child:Destroy() end
		end
		Painters = {}
		Names = type(Spec.Options) == "function" and Spec.Options() or Spec.Options
		local Query = QueryBox and string.lower(QueryBox.Text) or ""
		local Shown = 0
		for Index, Name in Names do
			if Query == "" or string.find(string.lower(Name), Query, 1, true) then
				Shown += 1
				local Option = Make("TextButton", {
					Size = UDim2.new(1, 0, 0, 30),
					Text = Name,
					LayoutOrder = Index,
					ZIndex = Z + 1,
				}, List)
				Make("UIPadding", { PaddingLeft = UDim.new(0, 10) }, Option)
				local Tick = Icon(Option, "check", 16, Theme.White)
				Tick.Position = UDim2.new(1, -18, 0.5, 0)
				Tick.ZIndex = Z + 2
				table.insert(Painters, function()
					local On = Multi and Selected[Name] or (not Multi and Selected == Name)
					Tick.Visible = On and true or false
					Tick.ImageColor3 = Theme.Accent
					Option.TextColor3 = On and Theme.Accent or Theme.Dim
				end)
				Option.MouseButton1Click:Connect(function()
					if Multi then
						Selected[Name] = not Selected[Name]
					else
						Selected = Name
						Close()
					end
					Refresh()
					if Spec.Callback then Spec.Callback(Selected) end
				end)
			end
		end
		local Height = Shown * 30 + 8
		List.CanvasSize = UDim2.fromOffset(0, Height)
		if Searchable then
			EmptyLabel.Visible = Shown == 0
			Shell.Size = UDim2.new(1, 0, 0, math.min(math.max(Height, 38), 158) + 38)
		else
			List.Size = UDim2.new(1, 0, 0, math.min(Height, 158))
		end
		Refresh()
	end
	Build()
	OnAccent(Refresh)

	if QueryBox then
		QueryBox:GetPropertyChangedSignal("Text"):Connect(Build)
	end

	Field.MouseButton1Click:Connect(function()
		if Shell.Visible then
			Close()
			return
		end
		if QueryBox then QueryBox.Text = "" end
		Build()
		Shell.Visible = true
		Blocker.Visible = true
		TweenService:Create(Arrow, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Rotation = 180 }):Play()
		if QueryBox then QueryBox:CaptureFocus() end
	end)

	local function Set(Value)
		if Multi then
			Selected = {}
			if type(Value) == "table" then
				for Key, Item in Value do Selected[Key] = Item end
			end
		else
			Selected = Value
		end
		Refresh()
		if Spec.Callback then Spec.Callback(Selected) end
	end
	if Spec.Save ~= false then Setters[Flag] = Set end
	return { Row = Holder, Shell = Shell, Set = Set, Rebuild = Build, Close = Close }
end

local function TextInput(Parent, Order, Spec)
	local Flag = Spec.Flag or Spec.Name
	local Numeric = Spec.Numeric
	local Default = Spec.Default ~= nil and tostring(Spec.Default) or ""
	local Holder = Make("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = Order,
	}, Parent)
	Make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, Holder)
	Make("TextLabel", { Size = UDim2.new(1, 0, 0, 18), Text = Spec.Name, LayoutOrder = 1 }, Holder)
	local Field = Make("Frame", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = Theme.Input,
		LayoutOrder = 2,
	}, Holder)
	Corner(Field, 6)
	local Box = Make("TextBox", {
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -20, 1, 0),
		Text = Default,
		PlaceholderText = Spec.Placeholder or "",
		ClearTextOnFocus = false,
		PlaceholderColor3 = Theme.Dim,
	}, Field)
	Flags[Flag] = Numeric and tonumber(Default) or Default
	local function Set(Value)
		if Numeric then
			local Number = tonumber(Value)
			if not Number then return end
			Box.Text = tostring(Number)
			Flags[Flag] = Number
		else
			Box.Text = tostring(Value)
			Flags[Flag] = Box.Text
		end
		if Spec.Callback then Spec.Callback(Flags[Flag]) end
	end
	if Spec.Save ~= false then Setters[Flag] = Set end
	Box.FocusLost:Connect(function()
		if Numeric then
			local Number = tonumber(Box.Text)
			if Number then
				Flags[Flag] = Number
			else
				Box.Text = tostring(Flags[Flag])
			end
		else
			Flags[Flag] = Box.Text
		end
		if Spec.Callback then Spec.Callback(Flags[Flag]) end
	end)
	return { Row = Holder, Box = Box, Set = Set }
end

local function ColorPicker(Parent, Order, Spec)
	local Flag = Spec.Flag or Spec.Name
	local Default = Spec.Default or Theme.White
	local Row = Make("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, LayoutOrder = Order }, Parent)
	Make("TextLabel", { Size = UDim2.new(1, -40, 1, 0), Text = Spec.Name }, Row)
	local Swatch = Make("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(24, 22),
		BackgroundTransparency = 0,
		BackgroundColor3 = Default,
	}, Row)
	Corner(Swatch, 5)
	Flags[Flag] = Default
	local function Set(Color)
		if typeof(Color) ~= "Color3" then return end
		Swatch.BackgroundColor3 = Color
		Flags[Flag] = Color
		if Spec.Callback then Spec.Callback(Color) end
	end
	if Spec.Save ~= false then Setters[Flag] = Set end
	Swatch.MouseButton1Click:Connect(function()
		if Picker.IsOpenFor(Swatch) then
			Picker.Close()
		else
			Picker.Open(Swatch, Flag, Spec.Callback)
		end
	end)
	return { Row = Row, Set = Set }
end

local function Divider(Parent, Order, Text)
	local Row = Make("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = Order }, Parent)
	local Width = TextService:GetTextSize(Text, 14, Enum.Font.Roboto, Vector2.new(1000, 100)).X
	local Gap = Width / 2 + 10
	Make("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.new(0.5, -Gap, 0, 1),
		BackgroundColor3 = Theme.Stroke,
		BackgroundTransparency = 0.3,
	}, Row)
	Make("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.new(0.5, -Gap, 0, 1),
		BackgroundColor3 = Theme.Stroke,
		BackgroundTransparency = 0.3,
	}, Row)
	Make("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		Text = Text,
		TextColor3 = Theme.Dim,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Center,
	}, Row)
	return { Row = Row }
end

local function Label(Parent, Order, Text, Options)
	Options = Options or {}
	local Object = Make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = Text,
		TextColor3 = Options.Color or Theme.Dim,
		TextSize = Options.Size or 14,
		FontFace = Options.Bold and Fonts.Bold or Fonts.Medium,
		TextWrapped = true,
		RichText = Options.RichText or false,
		TextXAlignment = Options.Align or Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		LayoutOrder = Order,
	}, Parent)
	return Object
end

local function ButtonRow(Parent, Order, Text, Callback)
	local Button = Make("TextButton", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundTransparency = 0,
		BackgroundColor3 = Theme.Input,
		Text = Text,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 14,
		LayoutOrder = Order,
	}, Parent)
	Corner(Button, 6)
	Button.MouseEnter:Connect(function() Button.BackgroundColor3 = Theme.Box end)
	Button.MouseLeave:Connect(function() Button.BackgroundColor3 = Theme.Input end)
	if Callback then Button.MouseButton1Click:Connect(Callback) end
	return Button
end

local function Card(Parent, Order, Title, IconName, PadTop)
	local Frame = Make("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Card,
		BackgroundTransparency = CardAlpha,
		LayoutOrder = Order,
	}, Parent)
	Corner(Frame, 10)
	Make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, Frame)
	local Body = Make("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
	}, Frame)
	Make("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		PaddingTop = UDim.new(0, PadTop or 10),
		PaddingBottom = UDim.new(0, 13),
	}, Body)
	Make("UIListLayout", { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder }, Body)
	if Title then
		local Header = Make("TextButton", { Size = UDim2.new(1, 0, 0, 44), LayoutOrder = 0 }, Frame)
		local HeaderIcon = Icon(Header, IconName or "sparkles", 20, Theme.Text)
		HeaderIcon.Position = UDim2.fromOffset(24, 22)
		Make("TextLabel", {
			Position = UDim2.fromOffset(43, 0),
			Size = UDim2.new(1, -90, 1, 0),
			Text = Title,
			FontFace = Fonts.Bold,
			TextSize = 16,
		}, Header)
		local Chevron = Icon(Header, "chevron-down", 20, Theme.Dim)
		Chevron.Position = UDim2.new(1, -23, 0.5, 0)
		Make("Frame", {
			Position = UDim2.new(0, 13, 1, -1),
			Size = UDim2.new(1, -25, 0, 1),
			BackgroundColor3 = Theme.Stroke,
			BackgroundTransparency = 0.4,
		}, Header)
		Header.MouseButton1Click:Connect(function()
			Body.Visible = not Body.Visible
			TweenService:Create(Chevron, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Rotation = Body.Visible and 0 or 180,
			}):Play()
		end)
	end
	return Frame, Body
end

local NavTween = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function PaintNav(Key)
	for Name, Item in State.NavItems do
		local On = Name == Key
		local Shift = UDim2.fromOffset(On and 4 or 0, 0)
		TweenService:Create(Item.Label, NavTween, {
			TextColor3 = On and Theme.Accent or Theme.Dim,
			Position = Item.LabelBase + Shift,
		}):Play()
		TweenService:Create(Item.Icon, NavTween, {
			ImageColor3 = On and Theme.Accent or Theme.Dim,
			Position = Item.IconBase + Shift,
		}):Play()
		Item.Fill.BackgroundColor3 = Theme.Accent
		TweenService:Create(Item.Fill, NavTween, { BackgroundTransparency = On and 0.9 or 1 }):Play()
	end
end

local function Navigate(Key)
	local Animate = State.CurrentKey ~= nil and State.CurrentKey ~= Key
	State.CurrentKey = Key
	PaintNav(Key)
	local Parts = string.split(Key, "/")
	State.CrumbA.Text = Parts[1]
	State.CrumbB.Text = Parts[2] or ""
	State.CrumbArrow.Visible = Parts[2] ~= nil
	if Animate then
		for _, Crumb in { State.CrumbA, State.CrumbB } do
			Crumb.TextTransparency = 1
			TweenService:Create(Crumb, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()
		end
	end
	for Name, Page in State.Pages do
		local On = Name == Key
		if On and Animate and not Page.Visible then
			Page.Visible = true
			local Index = 0
			for _, Child in Page:GetChildren() do
				if Child:IsA("GuiObject") then
					local Home = Child:GetAttribute("Home")
					if not Home then
						Home = Child.Position
						Child:SetAttribute("Home", Home)
					end
					Child.Position = Home + UDim2.fromOffset(0, 22)
					TweenService:Create(Child, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false, Index * 0.06), {
						Position = Home,
					}):Play()
					Index += 1
				end
			end
		else
			Page.Visible = On
		end
	end
	for _, Close in Closers do Close() end
end

OnAccent(function()
	if State.CurrentKey then PaintNav(State.CurrentKey) end
end)

local function NavItem(Parent, Order, Key, IconName, Text)
	local Button = Make("TextButton", { Size = UDim2.new(1, 0, 0, 36), LayoutOrder = Order }, Parent)
	local Fill = Make("Frame", {
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -20, 1, 0),
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 1,
	}, Button)
	Corner(Fill, 8)
	local IconBase = UDim2.new(0, 36, 0.5, 0)
	local LabelBase = UDim2.fromOffset(57, 0)
	local ItemIcon = Icon(Button, IconName, 22, Theme.Dim)
	ItemIcon.Position = IconBase
	local NavLabel = Make("TextLabel", {
		Position = LabelBase,
		Size = UDim2.new(1, -80, 1, 0),
		Text = Text,
		TextColor3 = Theme.Dim,
		TextSize = 16,
	}, Button)
	State.NavItems[Key] = {
		Label = NavLabel,
		Icon = ItemIcon,
		Fill = Fill,
		IconBase = IconBase,
		LabelBase = LabelBase,
	}
	Button.MouseButton1Click:Connect(function() Navigate(Key) end)
	return Button
end

local function NewColumn(Page, X, Width)
	local Column = Make("Frame", {
		Position = UDim2.fromOffset(X, 62),
		Size = UDim2.fromOffset(Width, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, Page)
	Make("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, Column)
	return Column
end

local function AddEntry(Name, Path, Run)
	table.insert(State.Entries, { Name = Name, Path = Path, Run = Run })
end

local function Wrap(Element, Flag)
	local Object = { Row = Element.Row, Flag = Flag, Box = Element.Box, Shell = Element.Shell }
	function Object:Set(Value)
		Element.Set(Value)
	end
	function Object:Get()
		return Flags[Flag]
	end
	if Element.Rebuild then
		function Object:Rebuild()
			Element.Rebuild()
		end
	end
	return Object
end

local Container = {}
Container.__index = Container

local function NewContainer(Body, Tab)
	return setmetatable({ Body = Body, Tab = Tab, Count = 0 }, Container)
end

function Container:Next(Name)
	self.Count += 1
	if Name then AddEntry(Name, self.Tab.Path, self.Tab.Open) end
	return self.Count
end

function Container:AddToggle(Spec)
	return Wrap(Checkbox(self.Body, self:Next(Spec.Name), Spec), Spec.Flag or Spec.Name)
end

function Container:AddSlider(Spec)
	return Wrap(Slider(self.Body, self:Next(Spec.Name), Spec), Spec.Flag or Spec.Name)
end

function Container:AddDropdown(Spec)
	return Wrap(Dropdown(self.Body, self:Next(Spec.Name), Spec), Spec.Flag or Spec.Name)
end

function Container:AddColorPicker(Spec)
	return Wrap(ColorPicker(self.Body, self:Next(Spec.Name), Spec), Spec.Flag or Spec.Name)
end

function Container:AddTextbox(Spec)
	return Wrap(TextInput(self.Body, self:Next(Spec.Name), Spec), Spec.Flag or Spec.Name)
end

function Container:AddButton(Spec)
	local Button = ButtonRow(self.Body, self:Next(Spec.Name), Spec.Name, Spec.Callback)
	return { Row = Button }
end

function Container:AddLabel(Text, Options)
	local Object = Label(self.Body, self:Next(), Text, Options)
	local Handle = { Row = Object }
	function Handle:Set(Value)
		Object.Text = Value
	end
	return Handle
end

function Container:AddDivider(Text)
	return Divider(self.Body, self:Next(), Text or "")
end

local TabClass = {}
TabClass.__index = TabClass

function TabClass:GetColumn(Index)
	local Column = self.Columns[Index]
	if not Column then
		Column = NewColumn(self.Page, Index == 1 and 12 or 355, Index == 1 and 330 or 342)
		self.Columns[Index] = Column
		self.Counts[Index] = 0
	end
	self.Counts[Index] += 1
	return Column, self.Counts[Index]
end

function TabClass:CreateCard(Spec)
	Spec = Spec or {}
	local Column, Order = self:GetColumn(Spec.Column or 1)
	local _, Body = Card(Column, Order, Spec.Title or "Card", Spec.Icon)
	return NewContainer(Body, self)
end

function TabClass:CreateTabCard(Spec)
	Spec = Spec or {}
	local Column, Order = self:GetColumn(Spec.Column or 1)
	local _, Body = Card(Column, Order, nil, nil, 4)
	local Bar = Make("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, LayoutOrder = 0 }, Body)
	Make("Frame", {
		Position = UDim2.new(0, 8, 1, -1),
		Size = UDim2.new(1, -8, 0, 1),
		BackgroundColor3 = Theme.Stroke,
		BackgroundTransparency = 0.4,
	}, Bar)
	local List = Make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, Bar)
	Make("UIPadding", { PaddingLeft = UDim.new(0, 8) }, List)
	Make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 25),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, List)

	local Pages, Buttons = {}, {}
	local Current
	local function Select(Name, Animate)
		if Animate and Current == Name then return end
		Current = Name
		local Info = TweenInfo.new(Animate and 0.28 or 0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		for Other, Page in Pages do
			local On = Other == Name
			Buttons[Other].Line.BackgroundColor3 = Theme.Accent
			TweenService:Create(Buttons[Other].Line, Info, { Size = UDim2.new(On and 1 or 0, 0, 0, 2) }):Play()
			TweenService:Create(Buttons[Other].Button, Info, { TextColor3 = On and Theme.Accent or Theme.Dim }):Play()
			if On then
				if not Page.Visible then
					Page.GroupTransparency = Animate and 1 or 0
					Page.Visible = true
					if Animate then
						TweenService:Create(Page, Info, { GroupTransparency = 0 }):Play()
					end
				end
			else
				Page.Visible = false
			end
		end
	end

	local Result = {}
	for Index, Name in Spec.Tabs or { "Tab" } do
		local Button = Make("TextButton", {
			Size = UDim2.fromOffset(0, 38),
			AutomaticSize = Enum.AutomaticSize.X,
			Text = Name,
			FontFace = Fonts.Bold,
			TextSize = 15,
			TextColor3 = Theme.Dim,
			LayoutOrder = Index,
		}, List)
		local Line = Make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 1, -2),
			Size = UDim2.new(0, 0, 0, 2),
			BackgroundColor3 = Theme.Accent,
			ZIndex = 2,
		}, Button)
		Buttons[Name] = { Button = Button, Line = Line }
		local Page = Make("CanvasGroup", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 1,
			Visible = false,
		}, Body)
		Make("UIListLayout", { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder }, Page)
		Make("UIPadding", {
			PaddingTop = UDim.new(0, 6),
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
		}, Page)
		Pages[Name] = Page
		Result[Name] = NewContainer(Page, self)
		Button.MouseButton1Click:Connect(function() Select(Name, true) end)
	end
	Select((Spec.Tabs or { "Tab" })[1])
	OnAccent(function()
		if Current then Select(Current) end
	end)
	return Result
end

local SectionClass = {}
SectionClass.__index = SectionClass

function SectionClass:CreateTab(Name, IconName)
	local Key = self.Name .. "/" .. Name
	self.Tabs += 1
	NavItem(self.Body, self.Tabs, Key, IconName or "sparkles", Name)
	local Page = Make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false }, State.Content)
	State.Pages[Key] = Page
	local Tab = setmetatable({
		Key = Key,
		Page = Page,
		Columns = {},
		Counts = {},
		Path = self.Name .. " / " .. Name,
	}, TabClass)
	Tab.Open = function()
		self.SetOpen(true)
		Navigate(Key)
	end
	AddEntry(Name, Tab.Path, Tab.Open)
	if not State.CurrentKey then Navigate(Key) end
	return Tab
end

local function CreatePanel(Title, IconName, Width, Spacing)
	local Dim = Make("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		ZIndex = 149,
		Visible = false,
	}, State.Main)
	Corner(Dim, 14)
	local Frame = Make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(Width, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(18, 18, 18),
		Active = true,
		Visible = false,
	}, State.Main)
	Corner(Frame, 12)
	Stroke(Frame, Theme.Stroke, 0.3, 1)
	Make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, Frame)

	local Header = Make("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, LayoutOrder = 0 }, Frame)
	local HeaderIcon = Icon(Header, IconName, 20, Theme.Text)
	HeaderIcon.Position = UDim2.fromOffset(24, 22)
	Make("TextLabel", {
		Position = UDim2.fromOffset(43, 0),
		Size = UDim2.new(1, -90, 1, 0),
		Text = Title,
		FontFace = Fonts.Bold,
		TextSize = 16,
	}, Header)
	Make("Frame", {
		Position = UDim2.new(0, 13, 1, -1),
		Size = UDim2.new(1, -26, 0, 1),
		BackgroundColor3 = Theme.Stroke,
		BackgroundTransparency = 0.4,
	}, Header)
	local CloseButton = Make("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -24, 0.5, 0),
		Size = UDim2.fromOffset(26, 26),
	}, Header)
	local CloseIcon = Icon(CloseButton, "x", 18, Theme.Dim)
	CloseIcon.Position = UDim2.fromScale(0.5, 0.5)

	local Body = Make("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
	}, Frame)
	Make("UIPadding", {
		PaddingLeft = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 14),
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 14),
	}, Body)
	Make("UIListLayout", { Padding = UDim.new(0, Spacing), SortOrder = Enum.SortOrder.LayoutOrder }, Body)

	local Panel = { Frame = Frame, Body = Body }

	function Panel.Close()
		Frame.Visible = false
		Dim.Visible = false
		if Panel.OnClose then Panel.OnClose() end
	end

	function Panel.Open()
		for _, Other in State.Panels do
			if Other ~= Panel then Other.Close() end
		end
		if Panel.OnOpen then Panel.OnOpen() end
		Dim.Visible = true
		Frame.Visible = true
	end

	function Panel.Toggle()
		if Frame.Visible then Panel.Close() else Panel.Open() end
	end

	function Panel.Finalize(Skip)
		Frame.ZIndex = 150
		for _, Object in Frame:GetDescendants() do
			if Object:IsA("GuiObject") and not (Skip and (Object == Skip or Object:IsDescendantOf(Skip))) then
				Object.ZIndex += 150
			end
		end
	end

	table.insert(State.Panels, Panel)
	table.insert(Closers, Panel.Close)
	Dim.MouseButton1Click:Connect(Panel.Close)
	CloseButton.MouseButton1Click:Connect(Panel.Close)
	return Panel
end

local function TopButton(IconName, Order)
	local Button = Make("TextButton", {
		Size = UDim2.fromOffset(38, 38),
		BackgroundTransparency = State.HasBackground and 0.15 or 0,
		BackgroundColor3 = Theme.Input,
		LayoutOrder = Order,
	}, State.TopBar)
	Corner(Button, 10)
	local Glyph = Icon(Button, IconName, 18, Theme.Dim)
	Glyph.Position = UDim2.fromScale(0.5, 0.5)
	Button.MouseEnter:Connect(function() Glyph.ImageColor3 = Theme.White end)
	Button.MouseLeave:Connect(function() Glyph.ImageColor3 = Theme.Dim end)
	return Button
end

local function Encode(Value)
	if typeof(Value) == "Color3" then
		return { __color = { Value.R, Value.G, Value.B } }
	end
	if type(Value) == "table" then
		local List = {}
		for Key, On in Value do
			if On == true then table.insert(List, tostring(Key)) end
		end
		table.sort(List)
		return { __set = List }
	end
	return Value
end

local function Decode(Value)
	if type(Value) == "table" then
		if Value.__color then
			local Color = Value.__color
			return Color3.new(Color[1], Color[2], Color[3])
		end
		if Value.__set then
			local Map = {}
			for _, Key in Value.__set do Map[Key] = true end
			return Map
		end
	end
	return Value
end

local function Serialize()
	local Keys = {}
	for Flag in Setters do table.insert(Keys, Flag) end
	table.sort(Keys)
	local List = {}
	for _, Flag in Keys do
		local Value = Flags[Flag]
		if Value ~= nil then table.insert(List, { Flag, Encode(Value) }) end
	end
	return HttpService:JSONEncode(List)
end

function Library:Notify(Title, Text, Duration, Kind)
	Notifier.Push(Title, Text, Duration, Kind)
end

local Window = {}
Window.__index = Window

function Library:CreateWindow(Options)
	Options = Options or {}
	local Title = Options.Title or "Window"
	local Anonymous = Options.Anonymous == true
	local ToggleKey = Options.ToggleKey or Enum.KeyCode.RightShift
	State.Title = Title
	State.ConfigFolder = Options.ConfigFolder or Title
	State.Touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	State.Fit = State.Touch and Vector2.new(1000, 760) or Vector2.new(1180, 860)

	local AssetPrefix = string.gsub(string.lower(Title), "[^%w]", "")
	local BackgroundImage = LoadImage(Options.Background, AssetPrefix .. "_background.png")
	State.HasBackground = BackgroundImage ~= nil
	local Avatar = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150"
	local Logo = LoadImage(Options.Logo, AssetPrefix .. "_logo.png") or Avatar

	local Host = (gethui and gethui()) or CoreGui
	local Existing = Host:FindFirstChild(Title)
	if Existing then Existing:Destroy() end

	local Gui = Instance.new("ScreenGui")
	Gui.Name = Title
	Gui.ResetOnSpawn = false
	Gui.IgnoreGuiInset = true
	Gui.DisplayOrder = 999
	Gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	local Parented = pcall(function()
		Gui.Parent = Host
	end)
	if not Parented or not Gui.Parent then
		Gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end
	State.Gui = Gui
	Notifier.Init(Gui)

	local Root = Make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
	}, Gui)
	State.Root = Root
	State.Scale = Make("UIScale", {}, Root)
	State.Windows = Make("Frame", { Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1 }, Root)

	local function WatchCamera()
		local Camera = workspace.CurrentCamera
		if Camera then
			Camera:GetPropertyChangedSignal("ViewportSize"):Connect(Rescale)
		end
		Rescale()
	end
	WatchCamera()
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(WatchCamera)

	Picker.Build()

	local Main = Make("Frame", {
		Position = UDim2.fromOffset(-462, -337),
		Size = UDim2.fromOffset(925, 675),
		BackgroundColor3 = Theme.Window,
	}, State.Windows)
	Corner(Main, 14)
	Shadow(Main)
	Stroke(Main, Theme.Stroke, 0.6, 1)
	State.Main = Main

	if BackgroundImage then
		local Background = Make("ImageLabel", {
			Size = UDim2.fromScale(1, 1),
			Image = BackgroundImage,
			ScaleType = Enum.ScaleType.Crop,
			ImageTransparency = 0.4,
			ImageColor3 = Color3.fromRGB(170, 170, 170),
		}, Main)
		Corner(Background, 14)
	end

	local Handle = Make("TextButton", { Size = UDim2.new(1, 0, 0, 60) }, Main)
	Drag(Handle, Main)

	local Sidebar = Make("Frame", {
		Size = UDim2.fromOffset(215, 675),
		BackgroundColor3 = Theme.Sidebar,
	}, Main)
	Corner(Sidebar, 14)
	Make("Frame", {
		Position = UDim2.fromOffset(195, 0),
		Size = UDim2.fromOffset(20, 675),
		BackgroundColor3 = Theme.Sidebar,
	}, Sidebar)

	local HeaderLogo = Make("ImageLabel", {
		Position = UDim2.fromOffset(17, 16),
		Size = UDim2.fromOffset(45, 45),
		Image = Logo,
		BackgroundTransparency = 0,
		BackgroundColor3 = Theme.Box,
	}, Sidebar)
	Corner(HeaderLogo, 23)
	Make("TextLabel", {
		Position = UDim2.fromOffset(75, Options.Version and 16 or 27),
		Size = UDim2.fromOffset(130, 22),
		Text = Title,
		FontFace = Fonts.Bold,
		TextSize = 18,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, Sidebar)
	if Options.Version then
		Make("TextLabel", {
			Position = UDim2.fromOffset(75, 40),
			Size = UDim2.fromOffset(130, 18),
			Text = Options.Version,
			TextColor3 = Theme.Dim,
			TextSize = 13,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, Sidebar)
	end

	State.Nav = Make("Frame", {
		Position = UDim2.fromOffset(0, 84),
		Size = UDim2.new(1, 0, 0, 490),
		BackgroundTransparency = 1,
	}, Sidebar)
	Make("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, State.Nav)

	Make("Frame", {
		Position = UDim2.fromOffset(15, 592),
		Size = UDim2.fromOffset(185, 1),
		BackgroundColor3 = Theme.Stroke,
		BackgroundTransparency = 0.4,
	}, Sidebar)
	local UserAvatar = Make("ImageLabel", {
		Position = UDim2.fromOffset(17, 614),
		Size = UDim2.fromOffset(45, 45),
		Image = Avatar,
		BackgroundTransparency = 0,
		BackgroundColor3 = Theme.Box,
	}, Sidebar)
	Corner(UserAvatar, 23)
	local UserName = LocalPlayer.Name
	local Shown = Anonymous and (string.sub(UserName, 1, 2) .. string.rep("*", math.max(#UserName - 2, 5))) or UserName
	Make("TextLabel", {
		Position = UDim2.fromOffset(75, 609),
		Size = UDim2.fromOffset(120, 22),
		Text = Shown,
		FontFace = Fonts.Bold,
		TextSize = 14,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, Sidebar)
	Make("TextLabel", {
		Position = UDim2.fromOffset(75, 636),
		Size = UDim2.fromOffset(130, 18),
		Text = Title,
		TextColor3 = Theme.Dim,
		TextSize = 14,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, Sidebar)

	State.Content = Make("Frame", {
		Position = UDim2.fromOffset(215, 0),
		Size = UDim2.fromOffset(710, 675),
		BackgroundTransparency = 1,
	}, Main)

	local Crumb = Make("Frame", {
		Position = UDim2.fromOffset(12, 14),
		Size = UDim2.fromOffset(0, 36),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
	}, State.Content)
	Make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, Crumb)
	State.CrumbA = Make("TextLabel", {
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		FontFace = Fonts.Bold,
		TextSize = 20,
		LayoutOrder = 1,
	}, Crumb)
	State.CrumbArrow = Make("Frame", { Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1, LayoutOrder = 2 }, Crumb)
	local CrumbIcon = Icon(State.CrumbArrow, "chevron-right", 20, Theme.Dim)
	CrumbIcon.Position = UDim2.fromScale(0.5, 0.5)
	State.CrumbB = Make("TextLabel", {
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		FontFace = Fonts.Bold,
		TextSize = 20,
		TextColor3 = Color3.fromRGB(190, 190, 190),
		LayoutOrder = 3,
	}, Crumb)

	State.TopBar = Make("Frame", {
		Position = UDim2.fromOffset(12, 12),
		Size = UDim2.fromOffset(685, 38),
		BackgroundTransparency = 1,
	}, State.Content)
	Make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, State.TopBar)

	local Bar = Make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, -49),
		Size = UDim2.fromOffset(0, 38),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Theme.Bar,
	}, Main)
	Corner(Bar, 10)
	Stroke(Bar, Theme.Stroke, 0.5, 1)
	Make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, Bar)
	State.Watermark = Bar

	local BarOrder = 0
	local function BarNext()
		BarOrder += 1
		return BarOrder
	end
	local function BarLabel(Text, Bold, Width)
		local Item = Make("TextLabel", {
			Size = UDim2.fromOffset(Width or 0, 38),
			AutomaticSize = Width and Enum.AutomaticSize.None or Enum.AutomaticSize.X,
			Text = Text,
			FontFace = Bold and Fonts.Bold or Fonts.Medium,
			TextColor3 = Bold and Theme.White or Theme.Dim,
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Center,
			LayoutOrder = BarNext(),
		}, Bar)
		if not Width then
			Make("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }, Item)
		end
		return Item
	end
	local function BarSeparator()
		Make("Frame", {
			Size = UDim2.fromOffset(1, 16),
			BackgroundColor3 = Theme.Stroke,
			LayoutOrder = BarNext(),
		}, Bar)
	end

	local BarLogoHolder = Make("Frame", {
		Size = UDim2.fromOffset(34, 38),
		BackgroundTransparency = 1,
		LayoutOrder = BarNext(),
	}, Bar)
	local BarLogo = Make("ImageLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(22, 22),
		Image = Logo,
	}, BarLogoHolder)
	Corner(BarLogo, 11)
	BarLabel(Title, true)
	if Options.Version then
		BarSeparator()
		BarLabel(Options.Version)
	end
	BarSeparator()
	local FpsLabel = BarLabel("0 fps", false, 80)
	BarSeparator()
	local PingLabel = BarLabel("0 ms", false, 80)
	BarSeparator()
	local TimeLabel = BarLabel(os.date("%H:%M"))

	local Frames, Last = 0, os.clock()
	RunService.RenderStepped:Connect(function()
		Frames += 1
		local Now = os.clock()
		if Now - Last >= 0.5 then
			FpsLabel.Text = math.floor(Frames / (Now - Last)) .. " fps"
			pcall(function()
				PingLabel.Text = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) .. " ms"
			end)
			TimeLabel.Text = os.date("%H:%M")
			Frames, Last = 0, Now
		end
	end)

	local ToggleSize = State.Touch and 48 or 62
	local Toggle = Make("TextButton", {
		Position = State.Touch and UDim2.new(0, 14, 0.5, -24) or UDim2.fromOffset(32, 55),
		Size = UDim2.fromOffset(ToggleSize, ToggleSize),
		BackgroundTransparency = 0,
		BackgroundColor3 = Theme.Box,
		ZIndex = 5,
	}, Gui)
	Corner(Toggle, ToggleSize / 2)
	local ToggleImage = Make("ImageLabel", {
		Size = UDim2.fromScale(1, 1),
		Image = Logo,
		ZIndex = 6,
	}, Toggle)
	Corner(ToggleImage, ToggleSize / 2)

	local ToggleDrag, ToggleMoved, ToggleStart, ToggleOrigin = false, false, nil, nil
	Toggle.InputBegan:Connect(function(Input)
		if IsPress(Input) then
			ToggleDrag = true
			ToggleMoved = false
			ToggleStart = Input.Position
			ToggleOrigin = Toggle.AbsolutePosition
		end
	end)
	UserInputService.InputChanged:Connect(function(Input)
		if ToggleDrag and IsMove(Input) then
			local Delta = Input.Position - ToggleStart
			if Delta.Magnitude > 6 then ToggleMoved = true end
			if ToggleMoved then
				Toggle.Position = UDim2.fromOffset(ToggleOrigin.X + Delta.X, ToggleOrigin.Y + Delta.Y)
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(Input)
		if ToggleDrag and IsPress(Input) then
			ToggleDrag = false
			if not ToggleMoved then
				SetVisible(not State.Windows.Visible)
			end
		end
	end)
	UserInputService.InputBegan:Connect(function(Input, Processed)
		if not Processed and Input.KeyCode == ToggleKey then
			SetVisible(not State.Windows.Visible)
		end
	end)

	return setmetatable({ Gui = Gui, Flags = Flags }, Window)
end

function Window:CreateSection(Name)
	State.Sections += 1
	local Base = (State.Sections - 1) * 3
	if State.Sections > 1 then
		Make("Frame", { Size = UDim2.new(1, 0, 0, 11), BackgroundTransparency = 1, LayoutOrder = Base }, State.Nav)
	end
	local Header = Make("TextButton", { Size = UDim2.new(1, 0, 0, 32), LayoutOrder = Base + 1 }, State.Nav)
	Make("TextLabel", {
		Position = UDim2.fromOffset(26, 0),
		Size = UDim2.new(1, -60, 1, 0),
		Text = Name,
		TextColor3 = Theme.Dim,
		TextSize = 14,
	}, Header)
	local Chevron = Icon(Header, "chevron-down", 18, Theme.Dim)
	Chevron.Position = UDim2.new(1, -31, 0.5, 0)
	local Body = Make("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = Base + 2,
	}, State.Nav)
	Make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, Body)

	local Section = setmetatable({ Name = Name, Body = Body, Tabs = 0 }, SectionClass)
	Section.SetOpen = function(Open)
		Body.Visible = Open
		TweenService:Create(Chevron, NavTween, { Rotation = Open and 0 or -90 }):Play()
	end
	Header.MouseButton1Click:Connect(function()
		Section.SetOpen(not Body.Visible)
	end)
	return Section
end

function Window:Notify(Title, Text, Duration, Kind)
	Notifier.Push(Title, Text, Duration, Kind)
end

function Window:SetVisible(Value)
	SetVisible(Value)
end

function Window:Destroy()
	if State.Gui then State.Gui:Destroy() end
end

function Window:SettingManager()
	local Button = TopButton("settings", 0)
	local Panel = CreatePanel("Appearance", "settings", 300, 10)
	Panel.OnClose = Picker.Close

	ColorPicker(Panel.Body, 1, {
		Name = "Accent color",
		Flag = "Accent",
		Default = Theme.Accent,
		Callback = SetAccent,
	})
	Checkbox(Panel.Body, 2, {
		Name = "Show watermark",
		Flag = "ShowWatermark",
		Default = true,
		Callback = function(Value)
			if State.Watermark then State.Watermark.Visible = Value end
		end,
	})
	Slider(Panel.Body, 3, {
		Name = "UI scale",
		Flag = "UIScale",
		Min = 0.5,
		Max = 1.5,
		Default = 1,
		Step = 0.05,
		Format = function(Value) return string.format("%.2fx", Value) end,
		Commit = Rescale,
		Save = false,
	})
	Label(Panel.Body, 4, "Scale is applied when you release the slider", { Size = 13 })
	Panel.Finalize()

	Button.MouseButton1Click:Connect(Panel.Toggle)
	for _, Name in { "Appearance", "Accent color", "Show watermark", "UI scale" } do
		AddEntry(Name, "Appearance", Panel.Open)
	end
end

function Window:NotificationManager()
	local Button = TopButton("bell", 1)
	local Badge = Make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -4, 0, 4),
		Size = UDim2.fromOffset(16, 16),
		BackgroundColor3 = Theme.Red,
		Visible = false,
		ZIndex = 2,
	}, Button)
	Corner(Badge, 8)
	local BadgeText = Make("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		FontFace = Fonts.Bold,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 3,
	}, Badge)

	local Panel = CreatePanel("Notifications", "bell", 340, 10)
	local ListHolder = Make("Frame", {
		Size = UDim2.new(1, 0, 0, 260),
		BackgroundColor3 = Color3.fromRGB(14, 14, 14),
		LayoutOrder = 1,
	}, Panel.Body)
	Corner(ListHolder, 8)
	local Empty = Make("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		Text = "No notifications",
		TextColor3 = Theme.Dim,
		TextXAlignment = Enum.TextXAlignment.Center,
	}, ListHolder)
	local List = Make("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ScrollBarThickness = 2,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, ListHolder)
	Make("UIPadding", {
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
		PaddingTop = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 6),
	}, List)
	Make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, List)
	local Clear = ButtonRow(Panel.Body, 2, "Clear logs")
	Clear.TextColor3 = Theme.Red
	Panel.Finalize()

	local function Refresh()
		for _, Child in List:GetChildren() do
			if Child:IsA("Frame") then Child:Destroy() end
		end
		Empty.Visible = #Notifier.Logs == 0
		for Index, Entry in Notifier.Logs do
			local Row = Make("Frame", {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = Theme.Input,
				LayoutOrder = Index,
			}, List)
			Corner(Row, 8)
			Make("UIPadding", {
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
				PaddingTop = UDim.new(0, 7),
				PaddingBottom = UDim.new(0, 8),
			}, Row)
			Make("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, Row)
			local Top = Make("Frame", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, LayoutOrder = 1 }, Row)
			local RowIcon = Notifier.MakeIcon(Top, Entry.Kind, 14)
			RowIcon.Position = UDim2.fromOffset(7, 9)
			Make("TextLabel", {
				Position = UDim2.fromOffset(22, 0),
				Size = UDim2.new(1, -92, 1, 0),
				Text = Entry.Title,
				FontFace = Fonts.Bold,
				TextSize = 14,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}, Top)
			Make("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				Text = Entry.Time,
				TextColor3 = Theme.Dim,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Right,
			}, Top)
			Make("TextLabel", {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Text = Entry.Text,
				TextColor3 = Theme.Dim,
				TextSize = 13,
				TextWrapped = true,
				TextYAlignment = Enum.TextYAlignment.Top,
				LayoutOrder = 2,
			}, Row)
			Row.ZIndex = 152
			for _, Object in Row:GetDescendants() do
				if Object:IsA("GuiObject") then
					Object.ZIndex = 153
				end
			end
		end
	end

	local function UpdateBadge()
		Badge.Visible = Notifier.Unread > 0
		BadgeText.Text = Notifier.Unread > 9 and "9+" or tostring(Notifier.Unread)
	end

	Notifier.Changed = function()
		if Panel.Frame.Visible then
			Notifier.Unread = 0
			Refresh()
		end
		UpdateBadge()
	end

	Panel.OnOpen = function()
		Notifier.Unread = 0
		UpdateBadge()
		Refresh()
	end

	Button.MouseButton1Click:Connect(Panel.Toggle)
	Clear.MouseButton1Click:Connect(function()
		Notifier.Logs = {}
		Notifier.Unread = 0
		UpdateBadge()
		Refresh()
	end)

	AddEntry("Notifications", "Notifications", Panel.Open)
	AddEntry("Clear logs", "Notifications", Panel.Open)
	UpdateBadge()
	Refresh()
end

function Window:ConfigManagerSystem()
	local Folder = State.ConfigFolder
	local SettingsPath = Folder .. "/settings.txt"
	local FS = (writefile and readfile and isfile and isfolder and makefolder and listfiles and delfile) and true or false

	if FS then
		pcall(function()
			if not isfolder(Folder) then makefolder(Folder) end
		end)
	end

	local Settings = { autoload = "", autosave = false }
	if FS then
		pcall(function()
			if isfile(SettingsPath) then
				local Data = HttpService:JSONDecode(readfile(SettingsPath))
				if type(Data) == "table" then
					if type(Data.autoload) == "string" then Settings.autoload = Data.autoload end
					Settings.autosave = Data.autosave == true
				end
			end
		end)
	end

	local function SaveSettings()
		if FS then pcall(writefile, SettingsPath, HttpService:JSONEncode(Settings)) end
	end

	local Status, AutoLabel, NameBox, Configs
	local CurrentConfig, LastSaved, Ready = "", "", false

	local function Notify(Text)
		if Status then Status.Text = Text end
		if Text == "" then return end
		local Lower = string.lower(Text)
		local Kind = "success"
		if string.find(Lower, "could not", 1, true) or string.find(Lower, "failed", 1, true) or string.find(Lower, "no file", 1, true) then
			Kind = "error"
		elseif string.find(Lower, "enter", 1, true) or string.find(Lower, "select", 1, true) or string.find(Lower, "exists", 1, true)
			or string.find(Lower, "no autoload", 1, true) or string.find(Lower, "first", 1, true) or string.find(Lower, "no longer", 1, true) then
			Kind = "warning"
		elseif string.find(Lower, "off", 1, true) then
			Kind = "info"
		end
		Notifier.Push("Config", Text, 4, Kind)
	end

	local function CleanName(Text)
		Text = (string.gsub(tostring(Text or ""), "[^%w _%-%.]", ""))
		return string.match(Text, "^%s*(.-)%s*$")
	end

	local function ConfigPath(Name)
		return Folder .. "/" .. Name .. ".json"
	end

	local function ConfigExists(Name)
		local Ok, Result = pcall(isfile, ConfigPath(Name))
		return Ok and Result == true
	end

	local function ListConfigs()
		local Names = {}
		if not FS then return Names end
		local Ok, Files = pcall(listfiles, Folder)
		if Ok and type(Files) == "table" then
			for _, Path in Files do
				local Name = string.match((string.gsub(Path, "\\", "/")), "([^/]+)%.json$")
				if Name then table.insert(Names, Name) end
			end
		end
		table.sort(Names, function(A, B) return string.lower(A) < string.lower(B) end)
		return Names
	end

	local function WriteConfig(Name)
		local Text = Serialize()
		if pcall(writefile, ConfigPath(Name), Text) then
			CurrentConfig = Name
			LastSaved = Text
			return true
		end
		return false
	end

	local function LoadConfig(Name)
		local Ok, Data = pcall(function()
			return HttpService:JSONDecode(readfile(ConfigPath(Name)))
		end)
		if not Ok or type(Data) ~= "table" then return false end
		Picker.Close()
		for _, Pair in Data do
			if type(Pair) == "table" and type(Pair[1]) == "string" then
				local Setter = Setters[Pair[1]]
				if Setter then pcall(Setter, Decode(Pair[2])) end
			end
		end
		Rescale()
		CurrentConfig = Name
		LastSaved = Serialize()
		return true
	end

	local function SelectedConfig()
		local Name = Flags.ConfigSelected
		if type(Name) == "string" and Name ~= "" then return Name end
		return nil
	end

	local function RefreshAutoLabel()
		local Name = Settings.autoload ~= "" and Settings.autoload or "none"
		AutoLabel.Text = 'Autoload: <font color="rgb(236,236,236)"><b>' .. Name .. "</b></font>"
	end

	local function Guard()
		if FS then return true end
		Notify("Executor has no file functions")
		return false
	end

	local Actions = {}

	function Actions.Save()
		if not Guard() then return end
		local Name = CleanName(NameBox.Text)
		if Name == "" then Notify("Enter a config name") return end
		if ConfigExists(Name) then Notify(Name .. " exists, use Overwrite") return end
		if WriteConfig(Name) then
			Configs.Set(Name)
			Notify("Saved " .. Name)
		else
			Notify("Could not save " .. Name)
		end
	end

	function Actions.Load()
		if not Guard() then return end
		local Name = SelectedConfig()
		if not Name then Notify("Select a config") return end
		if LoadConfig(Name) then
			Notify("Loaded " .. Name)
		else
			Notify("Could not load " .. Name)
		end
	end

	function Actions.Overwrite()
		if not Guard() then return end
		local Name = SelectedConfig()
		if not Name then Notify("Select a config") return end
		if not ConfigExists(Name) then Notify(Name .. " no longer exists") return end
		if WriteConfig(Name) then
			Notify("Overwrote " .. Name)
		else
			Notify("Could not overwrite " .. Name)
		end
	end

	function Actions.Delete()
		if not Guard() then return end
		local Name = SelectedConfig()
		if not Name then Notify("Select a config") return end
		if not pcall(delfile, ConfigPath(Name)) then Notify("Could not delete " .. Name) return end
		if Settings.autoload == Name then
			Settings.autoload = ""
			SaveSettings()
			RefreshAutoLabel()
		end
		if CurrentConfig == Name then CurrentConfig = "" end
		Configs.Set("")
		Notify("Deleted " .. Name)
	end

	function Actions.SetAutoload()
		if not Guard() then return end
		local Name = SelectedConfig()
		if not Name then Notify("Select a config") return end
		Settings.autoload = Name
		SaveSettings()
		RefreshAutoLabel()
		Notify("Autoload set: " .. Name)
	end

	function Actions.RemoveAutoload()
		if not Guard() then return end
		if Settings.autoload == "" then Notify("No autoload set") return end
		Settings.autoload = ""
		SaveSettings()
		RefreshAutoLabel()
		Notify("Autoload removed")
	end

	local Button = TopButton("folder", 2)
	local Panel = CreatePanel("Config manager", "folder", 340, 8)

	NameBox = TextInput(Panel.Body, 1, {
		Name = "Config name",
		Flag = "ConfigName",
		Placeholder = "my config",
		Save = false,
	}).Box

	Configs = Dropdown(Panel.Body, 2, {
		Name = "Configs",
		Flag = "ConfigSelected",
		Options = ListConfigs,
		Default = "",
		Search = true,
		Z = 400,
		Save = false,
	})

	local Grid = Make("Frame", { Size = UDim2.new(1, 0, 0, 112), BackgroundTransparency = 1, LayoutOrder = 3 }, Panel.Body)
	Make("UIGridLayout", {
		CellSize = UDim2.new(0.5, -4, 0, 32),
		CellPadding = UDim2.fromOffset(8, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, Grid)

	local function GridButton(Order, Text, Callback, Color)
		local Item = ButtonRow(Grid, Order, Text, Callback)
		if Color then Item.TextColor3 = Color end
		return Item
	end

	GridButton(1, "Save", Actions.Save)
	GridButton(2, "Load", Actions.Load)
	GridButton(3, "Overwrite", Actions.Overwrite)
	GridButton(4, "Delete", Actions.Delete, Theme.Red)
	GridButton(5, "Set autoload", Actions.SetAutoload)
	GridButton(6, "Remove autoload", Actions.RemoveAutoload)

	AutoLabel = Make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 20),
		Text = "",
		TextColor3 = Theme.Dim,
		TextSize = 14,
		RichText = true,
		LayoutOrder = 4,
	}, Panel.Body)

	Checkbox(Panel.Body, 5, {
		Name = "Auto save",
		Flag = "ConfigAutoSave",
		Default = Settings.autosave,
		Save = false,
		Callback = function(Value)
			Settings.autosave = Value
			if not Ready then return end
			SaveSettings()
			if not Value then
				Notify("Auto save off")
			elseif CurrentConfig == "" then
				Notify("Load or save a config first")
			else
				Notify("Auto save on: " .. CurrentConfig)
			end
		end,
	})

	Status = Make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 18),
		Text = FS and "" or "Executor has no file functions",
		TextColor3 = Theme.Dim,
		TextSize = 13,
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = 6,
	}, Panel.Body)

	Panel.Finalize(Configs.Shell)
	Panel.OnOpen = RefreshAutoLabel
	Panel.OnClose = Configs.Close
	Button.MouseButton1Click:Connect(Panel.Toggle)
	AddEntry("Config manager", "Config manager", Panel.Open)
	RefreshAutoLabel()

	task.spawn(function()
		while State.Gui and State.Gui.Parent do
			task.wait(3)
			if FS and Settings.autosave and CurrentConfig ~= "" then
				local Text = Serialize()
				if Text ~= LastSaved and pcall(writefile, ConfigPath(CurrentConfig), Text) then
					LastSaved = Text
				end
			end
		end
	end)

	task.defer(function()
		if FS and Settings.autoload ~= "" then
			if LoadConfig(Settings.autoload) then
				Configs.Set(Settings.autoload)
				Notify("Autoloaded " .. Settings.autoload)
			else
				Notify("Autoload failed: " .. Settings.autoload)
			end
		end
		Ready = true
	end)
end

function Window:SearchManager()
	local ClosedWidth, OpenWidth = 38, 220
	local Search = Make("Frame", {
		Size = UDim2.fromOffset(ClosedWidth, 38),
		BackgroundColor3 = Theme.Input,
		BackgroundTransparency = State.HasBackground and 0.15 or 0,
		ClipsDescendants = true,
		LayoutOrder = 3,
	}, State.TopBar)
	Corner(Search, 10)
	local SearchIcon = Icon(Search, "search", 18, Theme.Dim)
	SearchIcon.Position = UDim2.fromOffset(19, 19)
	local Toggle = Make("TextButton", { Size = UDim2.fromOffset(38, 38), ZIndex = 3 }, Search)
	local Box = Make("TextBox", {
		Position = UDim2.fromOffset(40, 0),
		Size = UDim2.new(1, -48, 1, 0),
		Text = "",
		PlaceholderText = "search...",
		PlaceholderColor3 = Theme.Dim,
		ClearTextOnFocus = false,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Visible = false,
	}, Search)

	local SuggestWidth = 240
	local Suggest = Make("Frame", {
		Position = UDim2.fromOffset(697 - SuggestWidth, 56),
		Size = UDim2.fromOffset(SuggestWidth, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(22, 22, 22),
		ZIndex = 60,
		Visible = false,
	}, State.Content)
	Corner(Suggest, 8)
	Stroke(Suggest, Theme.Stroke, 0.2, 1)
	Make("UIPadding", {
		PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 4),
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 4),
	}, Suggest)
	Make("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, Suggest)

	local IsOpen = false
	local Results = {}

	local function ClearSuggest()
		for _, Child in Suggest:GetChildren() do
			if Child:IsA("TextButton") then Child:Destroy() end
		end
		Results = {}
		Suggest.Visible = false
	end

	local function SetOpen(Value)
		if IsOpen == Value then return end
		IsOpen = Value
		TweenService:Create(Search, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(Value and OpenWidth or ClosedWidth, 38),
		}):Play()
		SearchIcon.ImageColor3 = Value and Theme.White or Theme.Dim
		if Value then
			Box.Visible = true
			Box:CaptureFocus()
		else
			Box:ReleaseFocus()
			Box.Text = ""
			Box.Visible = false
			ClearSuggest()
		end
	end

	table.insert(Closers, function() SetOpen(false) end)

	local function Pick(Entry)
		SetOpen(false)
		Entry.Run()
	end

	local function Update()
		ClearSuggest()
		local Query = string.lower(string.match(Box.Text, "^%s*(.-)%s*$"))
		if Query == "" then return end
		local Starts, Contains = {}, {}
		for _, Entry in State.Entries do
			local Index = string.find(string.lower(Entry.Name), Query, 1, true)
			if Index == 1 then
				table.insert(Starts, Entry)
			elseif Index then
				table.insert(Contains, Entry)
			end
		end
		for _, Entry in Contains do table.insert(Starts, Entry) end
		for Index = 1, math.min(#Starts, 5) do
			local Entry = Starts[Index]
			Results[Index] = Entry
			local Row = Make("TextButton", {
				Size = UDim2.new(1, 0, 0, 32),
				BackgroundColor3 = Theme.Box,
				BackgroundTransparency = 1,
				LayoutOrder = Index,
				ZIndex = 61,
			}, Suggest)
			Corner(Row, 6)
			Make("TextLabel", {
				Position = UDim2.fromOffset(10, 0),
				Size = UDim2.new(0.55, -10, 1, 0),
				Text = Entry.Name,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 62,
			}, Row)
			Make("TextLabel", {
				Position = UDim2.fromScale(0.55, 0),
				Size = UDim2.new(0.45, -10, 1, 0),
				Text = Entry.Path,
				TextColor3 = Theme.Dim,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 62,
			}, Row)
			Row.MouseEnter:Connect(function() Row.BackgroundTransparency = 0 end)
			Row.MouseLeave:Connect(function() Row.BackgroundTransparency = 1 end)
			Row.MouseButton1Click:Connect(function() Pick(Entry) end)
		end
		Suggest.Visible = #Results > 0
	end

	Box:GetPropertyChangedSignal("Text"):Connect(Update)
	Box.FocusLost:Connect(function(Enter)
		if Enter and Results[1] then
			Pick(Results[1])
			return
		end
		task.delay(0.2, function()
			if IsOpen and not Box:IsFocused() and Box.Text == "" then
				SetOpen(false)
			end
		end)
	end)
	Toggle.MouseButton1Click:Connect(function()
		SetOpen(not IsOpen)
	end)
	Toggle.MouseEnter:Connect(function()
		if not IsOpen then SearchIcon.ImageColor3 = Theme.White end
	end)
	Toggle.MouseLeave:Connect(function()
		if not IsOpen then SearchIcon.ImageColor3 = Theme.Dim end
	end)
end

return Library
