--!strict
const StarterGui 	   = game:GetService("StarterGui")
const Players		   = game:GetService("Players")
const Debris 		   = game:GetService("Debris")
const UserInputService = game:GetService("UserInputService")
	
const DEBUG_MODE 			   = false
const SCREEN_GUI_LIFETIME 	   = 0.1
const CHARACTERS_PER_SECOND    = 4.5 * 10 ^ 6
const TEXT_BOX_CHARACTER_LIMIT = 2 * 10 ^ 5

local function debugPrint(...)
	if not DEBUG_MODE then return end
	print(...)
end

local function calculateApproximateTime(textLength: number)
	return textLength / CHARACTERS_PER_SECOND
end

local function toggleCoreGui(enabled: boolean)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, enabled)
end

local function freezeTextBox(textBox: TextBox, isFrozen: boolean)
	textBox.ClearTextOnFocus = not isFrozen
	textBox.TextEditable = not isFrozen
end

local function createContainter()
	local player = Players.LocalPlayer :: Player
	
	local screenGui = Instance.new("ScreenGui")
	screenGui.Enabled = DEBUG_MODE
	screenGui.Parent = player.PlayerGui
	
	local textBox = Instance.new("TextBox", screenGui)
	return screenGui, textBox
end

local function manualWriteTextToTextBox(virtualInput: VirtualInput, textBox: TextBox, text: string)
	textBox.Text = ""
	textBox:CaptureFocus()
	
	toggleCoreGui(false) -- Makes sure CoreGui's don't interfere with the VirtualInput
	virtualInput:SendTextInput(text)
	
	repeat
		task.wait()
	until #textBox.Text >= #text
	
	toggleCoreGui(true)
end

local function selectTextBox(textBox: TextBox, cursorPosition: number)
	textBox.SelectionStart = 1
	textBox.CursorPosition = cursorPosition
end

local function simulateMouseClick(virtualInput: VirtualInput)
	virtualInput:SendMouseButton(Vector2.zero, Enum.UserInputType.MouseButton1, true)
	virtualInput:SendMouseButton(Vector2.zero, Enum.UserInputType.MouseButton1, false)
end

local function simulateCopyToClipboardHotkey(virtualInput: VirtualInput)
	virtualInput:SendKey(true, Enum.KeyCode.LeftControl, false)
	virtualInput:SendKey(true, Enum.KeyCode.C, false)

	virtualInput:SendKey(false, Enum.KeyCode.LeftControl, false)
	virtualInput:SendKey(false, Enum.KeyCode.C, false)
end

local function writeTextToTextBox(virtualInput: VirtualInput, textBox: TextBox, text: string)
	const isOverTextBoxCharLimit = (#text >= TEXT_BOX_CHARACTER_LIMIT)
	freezeTextBox(textBox, false)
	
	if not isOverTextBoxCharLimit then
		textBox.Text = text
	end
	
	if isOverTextBoxCharLimit then
		const success, response = pcall(manualWriteTextToTextBox, virtualInput, textBox, text)
		
		if not success then
			(textBox.Parent :: ScreenGui):Destroy()
			
			warn(response)
			return
		end
	end
	
	freezeTextBox(textBox, true)
end

-- Yields until process is finished.
return function(text: string)
	assert(UserInputService.KeyboardEnabled, "User is not on PC; copy will fail")
	
	if not text or text == "" then 
		return
	end
	
	if DEBUG_MODE and #text >= TEXT_BOX_CHARACTER_LIMIT then
		debugPrint(`Takes approximately: {math.round(calculateApproximateTime(#text))}s`)
		task.wait(0.1)
	end
	
	local container, containerTextBox = createContainter()
	local virtualInput = UserInputService:CreateVirtualInput() :: VirtualInput
	
	local startTime = os.clock()
	
	writeTextToTextBox(virtualInput, containerTextBox, text)
	debugPrint(`Elapsed time: {os.clock() - startTime}s`)
	assert(#containerTextBox.Text ~= 0, "Textbox was assigned no text; copy will fail.")
	
	containerTextBox:CaptureFocus()
	selectTextBox(containerTextBox, #text + 1)
	assert(containerTextBox.CursorPosition ~= -1 and containerTextBox.SelectionStart ~= -1, "TextBox has no active selection; copy will fail.")
	
	const success, response = pcall(simulateCopyToClipboardHotkey, virtualInput)
	if not success then
		container:Destroy()
		
		warn(response)
		return
	end
	
	const success, response = pcall(simulateMouseClick, virtualInput)
	if not success then
		container:Destroy()
		
		warn(response)
		return
	end
	
	debugPrint(`TextBox text length: {#containerTextBox.Text}`)
	debugPrint(`TextBox IsFocused: {containerTextBox:IsFocused()}`)
	debugPrint(`TextBox SelectionStart: {containerTextBox.SelectionStart}`)
	debugPrint(`TextBox CursorPosition: {containerTextBox.CursorPosition}`)
	
	Debris:AddItem(container, SCREEN_GUI_LIFETIME)
end