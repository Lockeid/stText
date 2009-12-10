--== Settings  ==--
local f = CreateFrame("Frame",nil,UIParent)
f:RegisterEvent"VARIABLES_LOADED"
-- Colors 
local pClass = select(2, UnitClass("player"))
local CColor ={ RAID_CLASS_COLORS[pClass].r, RAID_CLASS_COLORS[pClass].g, RAID_CLASS_COLORS[pClass].b }
local db = stSettings
local color
if db.ColorClass then
	color = CColor
else
	color = db.Color
end

--== Utils ==--
local function Hex(r, g, b)
	if type(r) == "table" then
		if r.r then r, g, b = r.r, r.g, r.b else r, g, b = unpack(r) end
	end
	return string.format("|cff%02x%02x%02x", r*255, g*255, b*255)
end
local colorCode = Hex(color)

local function MemFormat(v)
    if (v > 1024) then
        return string.format("%.2f"..colorCode.." MiB", v / 1024)
    else
        return string.format("%.2f"..colorCode.." KiB", v)
    end
end

local function ColorGradient(perc, ...)
	if (perc > 1) then
		local r, g, b = select(select('#', ...) - 2, ...)
		return r, g, b
	elseif (perc < 0) then
		local r, g, b = ...
		return r, g, b
	end
	
	local num = select('#', ...) / 3

	local segment, relperc = math.modf(perc*(num-1))
	local r1, g1, b1, r2, g2, b2 = select((segment*3)+1, ...)

	return r1 + (r2-r1)*relperc, g1 + (g2-g1)*relperc, b1 + (b2-b1)*relperc
end

local function updateItem(slotName) -- Get the decimal durability of an item
		local slotId = GetInventorySlotInfo(slotName)
		local itemLink = GetInventoryItemLink("player", slotId)
		if not itemLink then
			return -1
		end
		local durability, maximum = GetInventoryItemDurability(slotId)
		 if not durability or (maximum == 0) then
			return -1
		end
		return (durability / maximum)
	end
	
local function getItemName(slotName) -- Get the item link with rarity coloring
		local slotId = GetInventorySlotInfo(slotName)
	
		local itemLink = GetInventoryItemLink("player", slotId)
		if not itemLink then
			return -1
		end
		return (itemLink)
	end
	
local function getSlotDuraColor(durability) -- Get the hex color based on durability
		local r,g
		if(durability/100 > 0.5) then
			r = 2 - (2*(durability/100))
			g = 1
		else
			r = 1
			g = 2*(durability/100)
		end
		return string.format("|cff%02x%02x%02x", r*255, g*255, 0)
	end

f:SetScript("OnEvent",function()
--== Clock ==--
if(db.Clock) then
	local clock, ctext,bg = stCore:CreateText("Clock")
	
	local c_total = 0
	local c_delay = 1
	
	local UpdateClock = function(self,elapsed)
		c_total = c_total + elapsed
		if c_total > c_delay then
			c_total = 0
			local time = db.Time_Format == 24 and date(colorCode.."%H|r".."."..colorCode.."%M|r") or date(colorCode.."%I|r".."."..colorCode.."%M|r%p")
			ctext:SetText(time)
		end
	end

	clock:SetScript("OnUpdate",UpdateClock)
end
--== Framerate ==--
if(db.FPS) then
	local fframe, ftext, bg = stCore:CreateText("FPS")
	
		local f_total = 0
	local f_delay = 5
	
	local UpdateFPS = function(self,elapsed)
		f_total = f_total + elapsed
		if f_total > f_delay then
			f_total = 0
			local fps = floor(GetFramerate())
			ftext:SetText(fps..colorCode.." fps|r")
		end
	end
	
	fframe:SetScript("OnUpdate", UpdateFPS)
	
	local fps = floor(GetFramerate())
	ftext:SetText(fps..colorCode.." fps|r")
	
end

--== Location ==--
if(db.Location) then
	local loc_f, loc_t, bg = stCore:CreateText("Location")
	
		loc_f:RegisterEvent'PLAYER_ENTERING_WORLD'
	loc_f:RegisterEvent'ZONE_CHANGED'
	loc_f:RegisterEvent'ZONE_CHANGED_INDOORS'
	loc_f:RegisterEvent'ZONE_CHANGED_NEW_AREA'
	loc_f:RegisterEvent'WORLD_MAP_UPDATE'
	
	local function UpdateLoc(self,event,...)
		local subZoneText = GetMinimapZoneText()
		local x, y = GetPlayerMapPosition('player')
		local coords = string.format(colorCode..' %.0f|r.'..colorCode..'%.0f',x*100,y*100)
		loc_t:SetText(subZoneText..colorCode..coords.."|r")
	end
	
	local loc_total = 0
	local loc_delay = 1
	
	loc_f:SetScript("OnUpdate",function(self,elapsed) 
		loc_total = loc_total + elapsed
		if loc_total > loc_delay then
			loc_total = 0
			UpdateLoc()
		end
	end)	
	loc_f:SetScript("OnEvent",UpdateLoc)
end

--== Latency ==--
if(db.Latency) then
	local lat_f, lat_text, bg = stCore:CreateText("Latency")
	
	
	local lat_total = 0
	local lat_delay = 2
	
	local UpdateLatency = function(self,elapsed)
		lat_total = lat_total + elapsed
		if lat_total > lat_delay then
			lat_total = 0
			lag = select(3, GetNetStats())
			lat_text:SetText(lag..colorCode.."ms|r")
		end
	end
	lat_f:SetScript("OnUpdate",UpdateLatency)
end
	
				
--== Memory ==--
if(db.Memory) then
	local mem_f, mem_text, bg  = stCore:CreateText("Memory")
	local ismoving, movable = false, false
	
	mem_f.Slash = function()
		if bg:IsShown() then 
			bg:Hide() 
			--mem_f:SetMovable"false"
			movable = false
			print("|cff00efffstText: |rMemory module locked")
		else 
			bg:Show()
			--mem_f:SetMovable()
			movable = true
			print("|cff00efffstText: |rMemory module unlocked")
		end
	end
	
	local tip = CreateFrame("Button","st_MemoryButton",mem_f)
	tip:SetAllPoints()
	
	tip:SetScript("OnMouseDown",function(self) if(movable) then  if (IsAltKeyDown()) then mem_f:ClearAllPoints(); mem_f:StartMoving(); ismoving = true; GameTooltip:Hide()  end end end)
	tip:SetScript("OnMouseUp",function(self) mem_f:StopMovingOrSizing(); ismoving = false; stTextDB.Memory = {mem_f:GetPoint()} end)
	
	local mem_total = 0
	local mem_delay = 5
	
	local UpdateMem = function(self, elapsed)
		mem_total = mem_total + elapsed
		if mem_total > mem_delay then
			mem_total = 0
			local total = 0	
			UpdateAddOnMemoryUsage()
  			for i = 1, GetNumAddOns(), 1 do
        			if GetAddOnMemoryUsage(i) > 0 then
            				memory = GetAddOnMemoryUsage(i)
            				total = total + memory
        			end
    			end
    			mem_text:SetText(MemFormat(total))
    		end
    	end
    	
    	mem_f:SetScript("OnUpdate",UpdateMem)
    	
    	tip:SetScript("OnEnter", function(self) if not ismoving and not InCombatLockdown() then
   		local showBelow = select(2, self:GetCenter()) > UIParent:GetHeight()/2
		GameTooltip:SetOwner( self, "ANCHOR_NONE" )
		GameTooltip:SetPoint( showBelow and "TOP" or "BOTTOM", self, showBelow and "BOTTOM" or "TOP" )
    		collectgarbage()
   		local memory, i, addons, total, entry, total

        
   		GameTooltip:AddLine(date("%A, %d %B, %Y"), 1, 1, 1)
    		GameTooltip:AddLine(" ")
    		GameTooltip:AddDoubleLine(". . . . . . . . . . .", ". . . . . . . . . . .", 1, 1, 1, 1, 1, 1)
  		GameTooltip:AddLine(" ")
  		GameTooltip:AddLine("Top 50 AddOns:", color.r, color.g, color.b)
   		GameTooltip:AddLine(" ")

   		addons = {}
   		local number = 0
		total = 0
   		UpdateAddOnMemoryUsage()
    		for i = 1, GetNumAddOns(), 1 do
       			if GetAddOnMemoryUsage(i) > 0 then
         			memory = GetAddOnMemoryUsage(i)
          			entry = {name = GetAddOnInfo(i), memory = memory}
           			table.insert(addons, entry)
            			total = total + memory
       			end
    		end
    
    		table.sort(addons, function(a, b) return a.memory > b.memory end)
    

  		 for _,entry in pairs(addons) do
			if number < 50 then
				local cr, cg, cb = ColorGradient((entry.memory / 800), 0, 1, 0, 1, 1, 0, 1, 0, 0)
				GameTooltip:AddDoubleLine(entry.name, MemFormat(entry.memory), 1, 1, 1, cr, cg, cb)
				number = number + 1
			end
		end
    		local cr, cg, cb = ColorGradient((entry.memory / 800), 0, 1, 0, 1, 1, 0, 1, 0, 0) 
    		GameTooltip:AddLine(" ")
    		GameTooltip:AddDoubleLine(". . . . . . . . . . .", ". . . . . . . . . . .", 1, 1, 1, 1, 1, 1)
    		GameTooltip:AddLine(" ")
    		GameTooltip:AddDoubleLine("Total", MemFormat(total), color.r, color.g, color.b, cr, cg, cb)
    		GameTooltip:AddDoubleLine("..with Blizzard", MemFormat(collectgarbage("count")), color.r, color.g, color.b, cr, cg, cb)
    		GameTooltip:Show()
    	end
	end)

	tip:SetScript("OnLeave", function()  GameTooltip:Hide() end)

			

end




--== Durability ==--
if(db.Durability) then
	-- Local variables
	local dura_f, dura_text, bg = stCore:CreateText("Durability")
	local dura_ismoving, dura_movable = false, false
	local dura_tip = CreateFrame("Button","st_DuraButton",dura_f)
	
	local d_total = 0
	local dura_delay = 1
	local itemslots = {
		"HeadSlot",
		"ShoulderSlot",
		"ChestSlot",
		"WristSlot",
		"HandsSlot",
		"WaistSlot",
		"LegsSlot",
		"FeetSlot",
		"MainHandSlot",
		"SecondaryHandSlot",
		"RangedSlot",
	}
	


	dura_tip:SetAllPoints()
	dura_tip:SetScript("OnMouseDown",function(self) if(dura_movable) then  if (IsAltKeyDown()) then dura_f:ClearAllPoints(); dura_f:StartMoving(); dura_ismoving = true; GameTooltip:Hide()  end end end)
	dura_tip:SetScript("OnMouseUp",function(self) dura_f:StopMovingOrSizing(); dura_ismoving = false; stTextDB.Durability = {dura_f:GetPoint()} end)
	dura_tip:SetScript("OnLeave", function()  GameTooltip:Hide() end)
	
	-- Durability function
	local UpdateDurability = function(self,elapsed)
		d_total = d_total + elapsed
		if d_total > dura_delay then
			d_total = 0
			
			local durabilityValue = 1
			local itemCounter = 0
			local durability = -1
			
			for _, slotName in ipairs(itemslots) do
				durability = updateItem(slotName)
				if durability >= 0 then
					durabilityValue = min(durabilityValue, durability)
					itemCounter = itemCounter + 1
				end
			end

			if itemCounter == 0 then 
				durability = 1
			end

			local itemDuraColor = getSlotDuraColor(floor(durabilityValue * 100))
			local itemDura = format("%s%i", itemDuraColor, floor(durabilityValue * 100))
			dura_text:SetText(itemDura..colorCode.."%|r")
		end
	end
	
	dura_f:SetScript("OnUpdate",UpdateDurability)
	
	-- Durability tooltip
    	dura_tip:SetScript("OnEnter", function(self) if not dura_ismoving and not InCombatLockdown() then
   		local showBelow = select(2, self:GetCenter()) > UIParent:GetHeight()/2
		GameTooltip:SetOwner( self, "ANCHOR_NONE" )
		GameTooltip:SetPoint( showBelow and "TOP" or "BOTTOM", self, showBelow and "BOTTOM" or "TOP" )
		
		GameTooltip:AddDoubleLine("Item Name","Durability", color.r, color.g, color.b)
		GameTooltip:AddDoubleLine(". . . . . . . . . . .", ". . . . . . . . . . .", 1, 1, 1, 1, 1, 1)
		GameTooltip:AddLine(" ")
		for _, slotName in ipairs(itemslots) do
		
			-- Make sure slot has an item
			itemSlotName = getItemName(slotName)
			if (itemSlotName ~= -1) then
				itemDura = floor(updateItem(slotName)*100)
				itemDuraColor = getSlotDuraColor(itemDura)
				if (itemDura <0) or (itemDura > 100) then
					itemDuraString = " "
				else
					itemDuraString = format("%s%i%%", itemDuraColor, itemDura) -- color the dura
				end
				GameTooltip:AddDoubleLine(itemSlotName, itemDuraString) -- print the line
			end
		end
    		GameTooltip:Show()
    	end
    	end)

	-- Durability support functions
	
	-- Slash commands
	dura_f.Slash = function()
		if bg:IsShown() then 
			bg:Hide()
			--dura_f:EnableMouse("false")
			--dura_f:SetMovable"false"
			dura_movable = false
			print("|cff00efffstText: |rDurability module locked")
		else 
			bg:Show()
			--dura_f:EnableMouse()
			--dura_f:SetMovable()
			dura_movable = true
			print("|cff00efffstText: |rDurability module locked")
		end
	end
end


end)


