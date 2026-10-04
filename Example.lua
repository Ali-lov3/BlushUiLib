local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Ali-lov3/BlushUiLib/refs/heads/main/Source.lua"))()

local Players = game:GetService("Players")

local Window = Library:CreateWindow({
	Title = "blush.",
	Logo = "11318961749",
	ConfigFolder = "blush",
	Background = "10149736886",
	Anonymous = true,
})

local Section = Window:CreateSection("Example")
local Tab = Section:CreateTab("Example", "sparkles")

local Left = Tab:CreateCard({ Title = "Example", Icon = "sparkles", Column = 1 })
local Right = Tab:CreateCard({ Title = "Example", Icon = "sparkles", Column = 2 })
local Tabs = Tab:CreateTabCard({ Column = 2, Tabs = { "Example" } })

local Hint, Conditional

Left:AddToggle({
	Name = "Example Toggle Hint",
	Flag = "ExampleHint",
	Default = true,
	Hint = "MB2",
})

Left:AddToggle({
	Name = "Example Toggle",
	Flag = "ExampleToggle",
	Default = true,
})

Left:AddToggle({
	Name = "Example Toggle Badge",
	Flag = "ExampleBadge",
	Default = true,
	Badge = "NEW",
	Callback = function(Value)
		if Hint then Hint.Row.Visible = Value end
		if Conditional then Conditional.Row.Visible = Value end
	end,
})

Left:AddToggle({
	Name = "Example Toggle Colored",
	Flag = "ExampleColored",
	Color = Color3.fromRGB(255, 80, 80),
})

Left:AddToggle({
	Name = "Example Toggle Disabled",
	Flag = "ExampleDisabled",
	Disabled = true,
})

Left:AddSlider({
	Name = "Example Slider",
	Flag = "ExampleSlider",
	Min = 10,
	Max = 500,
	Default = 194,
	Step = 1,
	Format = function(Value) return Value .. "px" end,
})

Left:AddSlider({
	Name = "Example Slider Decimal",
	Flag = "ExampleDecimal",
	Min = 0,
	Max = 1,
	Default = 0.35,
	Step = 0.01,
	Format = function(Value) return string.format("%.2f", Value) end,
})

Left:AddDropdown({
	Name = "Example Dropdown",
	Flag = "ExampleDropdown",
	Options = { "Option 1", "Option 2", "Option 3", "Option 4" },
	Default = "Option 1",
})

Left:AddDropdown({
	Name = "Example Multi Dropdown",
	Flag = "ExampleMulti",
	Options = { "Option 1", "Option 2", "Option 3", "Option 4" },
	Default = { ["Option 1"] = true, ["Option 2"] = true },
	Multi = true,
})

Hint = Left:AddLabel("Example Label, shown only while Example Toggle Badge is on")

Conditional = Left:AddSlider({
	Name = "Example Conditional Slider",
	Flag = "ExampleConditional",
	Min = 0,
	Max = 100,
	Default = 80,
	Step = 1,
	Format = function(Value) return Value .. "%" end,
})

Hint.Row.Visible = Library.Flags.ExampleBadge
Conditional.Row.Visible = Library.Flags.ExampleBadge

Right:AddToggle({
	Name = "Example Colorpicker",
	Flag = "ExampleColorToggle",
	Default = true,
	ColorPicker = Color3.fromRGB(59, 130, 246),
})

Right:AddColorPicker({
	Name = "Example Colorpicker Only",
	Flag = "ExampleColorOnly",
	Default = Color3.fromRGB(255, 85, 140),
})

Right:AddSlider({
	Name = "Example Slider 2",
	Flag = "ExampleSlider2",
	Min = 0,
	Max = 115,
	Default = 60,
	Step = 1,
})

Right:AddDivider("Example Divider")

Right:AddDropdown({
	Name = "Example Search Dropdown",
	Flag = "ExampleSearch",
	Options = function()
		local Names = {}
		for _, Player in Players:GetPlayers() do
			table.insert(Names, Player.Name)
		end
		return Names
	end,
	Default = Players.LocalPlayer.Name,
	Search = true,
})

Right:AddTextbox({
	Name = "Example Textbox",
	Flag = "ExampleText",
	Default = "Example",
})

Right:AddTextbox({
	Name = "Example Number Input",
	Flag = "ExampleNumber",
	Default = 500,
	Numeric = true,
})

local Samples = {
	{ "Example Info", "This is an example info notification", "info" },
	{ "Example Success", "This is an example success notification", "success" },
	{ "Example Warning", "This is an example warning notification", "warning" },
	{ "Example Error", "This is an example error notification", "error" },
}
local SampleIndex = 0

Right:AddButton({
	Name = "Example Button",
	Callback = function()
		SampleIndex = SampleIndex % #Samples + 1
		local Sample = Samples[SampleIndex]
		Library:Notify(Sample[1], Sample[2], 4, Sample[3])
	end,
})

Tabs.Example:AddToggle({
	Name = "Example Toggle Tab",
	Flag = "ExampleTabToggle",
})

Tabs.Example:AddSlider({
	Name = "Example Slider Tab",
	Flag = "ExampleTabSlider",
	Min = 0,
	Max = 500,
	Default = 60,
	Step = 1,
	Format = function(Value) return Value .. "ms" end,
})

Window:ConfigManagerSystem()
Window:SettingManager()
Window:SearchManager()
Window:NotificationManager()

Library:Notify("blush.", "Loaded. Press RightShift to toggle the menu.", 5)
