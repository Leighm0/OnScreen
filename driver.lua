-------------
-- Globals --
-------------
do
	OPC = {}
	RFP = {}
	g_debugMode = 0
	g_DbgPrint = nil
end

----------------------------------------------------------------------------
--Function Name : OnDriverInit
--Description   : Function invoked when a driver is loaded or being updated.
----------------------------------------------------------------------------
function OnDriverInit()
	C4:UpdateProperty("Driver Name", C4:GetDriverConfigInfo("name"))
	C4:UpdateProperty("Driver Version", C4:GetDriverConfigInfo("version"))
	C4:AllowExecute(true)
end

------------------------------------------------------------------------------------------------
--Function Name : OnDriverLateInit
--Description   : Function that serves as a callback into a project after the project is loaded.
------------------------------------------------------------------------------------------------
function OnDriverLateInit()
	ShowProxyInRoom(5001)
end

-----------------------------------------------------------------------------------------------------------------------------
--Function Name : OnDriverDestroyed
--Description   : Function called when a driver is deleted from a project, updated within a project or Director is shut down.
-----------------------------------------------------------------------------------------------------------------------------
function OnDriverDestroyed()
	if (g_DbgPrint ~= nil) then g_DbgPrint:Cancel() end
end

--------------------------------------------------------------------------------------------
--Function Name : OnSystemEvent
--Parameters    : data(table)
--Description   : A callback function that is sent to a driver when a system event is fired.
--------------------------------------------------------------------------------------------
function OnSystemEvent(data)
	if (eventname == 'OnPIP') then
		HideProxyInAllRooms(5001)
	end
end

----------------------------------------------------------------------------
--Function Name : OnPropertyChanged
--Parameters    : strProperty(str)
--Description   : Function called by Director when a property changes value.
----------------------------------------------------------------------------
function OnPropertyChanged(strProperty)
	Dbg("OnPropertyChanged: " .. strProperty .. " (" .. Properties[strProperty] .. ")")
	local propertyValue = Properties[strProperty]
	if (propertyValue == nil) then propertyValue = "" end
	local strProperty = string.upper(strProperty)
	strProperty = string.gsub(strProperty, "%s+", "_")
	local success, ret
	if (OPC and OPC[strProperty] and type(OPC[strProperty]) == "function") then
		success, ret = pcall(OPC[strProperty], propertyValue)
	end
	if (success == true) then
		return (ret)
	elseif (success == false) then
		print ("OnPropertyChanged Lua error: ", strProperty, ret)
	end
end

-------------------------------------------------------------------------
--Function Name : OPC.DEBUG_MODE
--Parameters    : strProperty(str)
--Description   : Function called when Debug Mode property changes value.
-------------------------------------------------------------------------
function OPC.DEBUG_MODE(strProperty)
	if (strProperty == "Off") then
		if (g_DbgPrint ~= nil) then g_DbgPrint:Cancel() end
		g_debugMode = 0
		print ("Debug Mode: Off")
	else
		g_debugMode = 1
		print ("Debug Mode: On for 8 hours")
		g_DbgPrint = C4:SetTimer(28800000, function(timer)
			C4:UpdateProperty("Debug Mode", "Off")
			timer:Cancel()
		end, false)
	end
end

-----------------------------------------------------------------
--Function Name : ReceivedFromProxy
--Parameters    : idBinding(int), strCommand(str), tParams(table)
--Description   : Function called when proxy command is called
-----------------------------------------------------------------
function ReceivedFromProxy(idBinding, strCommand, tParams)
	tParams = tParams or {}
	Dbg("ReceivedFromProxy: [" .. idBinding .. "] : " ..strCommand .. " (" ..  formatParams(tParams) .. ")")
	local strCommand = string.upper(strCommand)
	strCommand = string.gsub(strCommand, "%s+", "_")
	local success, ret
	if (RFP and RFP[strCommand] and type(RFP[strCommand]) == "function") then
		success, ret = pcall(RFP[strCommand], idBinding, tParams)
	end
	if (success == true) then
		return (ret)
	elseif (success == false) then
		print ("ReceivedFromProxy Lua error: ", strCommand, ret)
	end
end

------------------------------------------------------------------------------
--Function Name : RFP.SELECT
--Parameters    : idBinding(int), tParams(table)
--Description   : Function called when "SELECT" ReceivedFromProxy is received.
------------------------------------------------------------------------------
function RFP.SELECT(idBinding, tParams)
	C4:SendToDevice(tParams["Room"], "CONTROL4", {})
end

---------------------------------------------------------------------------
--Function Name : ShowProxyInRoom
--Parameters    : idBinding(int)
--Description   : Function called to show the UI experience button in room.
---------------------------------------------------------------------------
function ShowProxyInRoom(idBinding)
	idBinding = idBinding or 0
	if (idBinding == 0) then return end
	local id, name = next(C4:GetBoundConsumerDevices(C4:GetDeviceID(), idBinding))
	idRoom = C4:RoomGetId()
	C4:SendToDevice(idRoom, "SET_DEVICE_HIDDEN_STATE", {PROXY_GROUP = "OrderedWatchList", DEVICE_ID = id, IS_HIDDEN = false})
end

--------------------------------------------------------------------------------
--Function Name : HideProxyInAllRooms
--Parameters    : idBinding(int)
--Description   : Function called to hide the UI experience button in all rooms.
--------------------------------------------------------------------------------
function HideProxyInAllRooms(idBinding)
	idBinding = idBinding or 0
	if (idBinding == 0) then return end
	local id, name = next(C4:GetBoundConsumerDevices(C4:GetDeviceID(), idBinding))
	local roomdevs = C4:GetDevicesByC4iName("roomdevice.c4i")
	for roomid, roomname in pairs(C4:GetDevicesByC4iName("roomdevice.c4i") or {}) do
		C4:SendToDevice(roomid, "SET_DEVICE_HIDDEN_STATE", {PROXY_GROUP = "OrderedWatchList", DEVICE_ID = id, IS_HIDDEN = true})
		C4:SendToDevice(roomid, "SET_DEVICE_HIDDEN_STATE", {PROXY_GROUP = "OrderedListenList", DEVICE_ID = id, IS_HIDDEN = true})
	end
end

---------------------------------------------------------------------------------------------
--Function Name : Dbg
--Parameters    : strDebugText(str)
--Description   : Function called when debug information is to be printed/logged (if enabled)
---------------------------------------------------------------------------------------------
function Dbg(strDebugText)
    if (g_debugMode == 1) then print(strDebugText) end
end

---------------------------------------------------------
--Function Name : formatParams
--Parameters    : tParams(table)
--Description   : Function called to format table params.
---------------------------------------------------------
function formatParams(tParams)
	tParams = tParams or {}
	local out = {}
	for k,v in pairs(tParams) do
		if (type(v) == "string") then
			table.insert(out, k .. " = \"" .. v .. "\"")
		else
			table.insert(out, k .. " = " .. tostring(v))
		end
	end
	return "{" .. table.concat(out, ", ") .. "}"
end
