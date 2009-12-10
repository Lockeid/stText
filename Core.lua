local dummy  = CreateFrame("Frame", "stCore",UIParent)
local db = stSettings
local defpoint = {"CENTER",UIParent,"CENTER",0,0}
dummy:SetScript("OnEvent",function() 
	stTextDB = stTextDB or {} 
end)
dummy:RegisterEvent"VARIABLES_LOADED"
local stHelp = "|cff00efffstText: |rType /stt module_name to unlock it, available modules are :"


function stCore.SlashHandler(name)
	if _G["stText_"..name] then
		local f = _G["stText_"..name]
--	 	Custom slash commands
		if f.Slash then 
			f:Slash()
--		Normal slash commands	
		else
			if f.bg:IsShown() then
				f.bg:Hide()
				f:EnableMouse"false"
				print("|cff00efffstText: |r"..name.." module locked")
			else
				f.bg:Show()
				f:EnableMouse"true"
				print("|cff00efffstText: |r"..name.." module unlocked")
			end
		end
	else
		print(stHelp)
		for k in pairs(stTextDB) do
			if _G["stText_"..k] then
				print("-|cff00efff"..k)
			end
		end
	end
end
function stCore:CreateText(name)
	local f = CreateFrame("Frame","stText_"..name,UIParent)

	stTextDB[name] = stTextDB[name] or {"CENTER"}; 
	f:ClearAllPoints();
	f:SetPoint(unpack(stTextDB[name]))
	f:SetMovable(true)
	local size
	if db[name.."_Size"] then size = db[name.."_Size"] else size = db.Size end
	f:SetHeight(size+3)
	f:SetWidth(100)
	
	
	f:SetScript("OnMouseDown",function(self)  if (IsAltKeyDown()) then self:ClearAllPoints(); self:StartMoving() end end)
	f:SetScript("OnMouseUp",function(self) self:StopMovingOrSizing(); stTextDB[name] = {self:GetPoint()} end)
	
	f.bg = f:CreateTexture(nil,"OVERLAY")
	f.bg:SetAllPoints(f)
	f.bg:SetTexture(0,0,0,.75)
	f.bg:Hide()
	
	local text = f:CreateFontString(nil,"ARTWORK")
	text:SetPoint(db.Justify,f)
	text:SetFont("Fonts\\ARIALN.ttf", size, db.Outline)
	
	return f, text, f.bg
end
SLASH_STTEXT1 = "/sttext"
SLASH_STTEXT2 = "/stt"
SlashCmdList["STTEXT"] = stCore.SlashHandler