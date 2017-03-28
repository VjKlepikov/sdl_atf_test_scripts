---------------------------------------------------------------------------------------------
-- Requirement summary:
-- APPLINK-19314 [GeneralResultCodes]DISALLOWED: RPC is omitted in the PolicyTable group(s) assigned to the application
-- APPLINK-16839 [Policies] HMI Levels the request is allowed to be processed in (multiple functional groups)

-- Description:
-- Check that SDL verifies every App's request before processing it using appropriate group of permissions.

-- Precondition
-- 1. App policies includes Base-4
--    Base-4 includes 6 RPCs:
--      PutFile: hmi_levels = "NONE"
--      SendLocation: hmi_levels = "NONE"
--      GetWayPoints: hmi_levels = "NONE"
--      SetAppIcon: hmi_levels = "FULL"
--      ListFiles: hmi_levels = "FULL"
--      SubscribeVehicleData: hmi_levels = "FULL"
-- 2. Register app (HMI level = NONE)

-- Steps: 
-- 1. Send RPC PutFile
-- 2. Send RPC SendLocation
-- 3. Send RPC GetWayPoints
-- 4. Send RPC SetAppIcon
-- 5. Send RPC ListFiles
-- 6. Send RPC SubscribeVehicleData

-- Expected result:
-- 1. Allowed
-- 2. Allowed.
-- 3. Allowed.
-- 4. Disallowed
-- 5. Disallowed.
-- 6. Disallowed.

-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

-----------------------------------Common Variables------------------------------------------
local json_file = config.pathToSDL .. "sdl_preloaded_pt.json"


-------------------------------------------Preconditions-------------------------------------
common_steps:AddNewTestCasesGroup("Preconditions")

common_steps:BackupFile("Preconditions_Back_Up_sdl_preloaded_pt", "sdl_preloaded_pt.json")

function Test:Preconditions_Update_Group_Base_4_In_LPT()
  local parent_item = {"policy_table", "functional_groupings", "Base-4", "rpcs"}
  local added_json_items = {
    PutFile = {
      hmi_levels = { 
        "NONE"}},
    SendLocation = {
      hmi_levels = { 
        "NONE"}},
    GetWayPoints = {
      hmi_levels = { 
        "NONE"}},
    SetAppIcon = {
      hmi_levels = { 
        "FULL"}},
    ListFiles = {
      hmi_levels = { 
        "FULL"}},
    SubscribeVehicleData = {
      hmi_levels = { 
        "FULL"}}}
  common_functions:AddItemsIntoJsonFile(json_file, parent_item, added_json_items)
end

function Test:Preconditions_Add_App_Policy_with_Base_4_Group()
  local parent_item = {"policy_table", "app_policies"}
  local added_json_items = {}
  added_json_items[const.default_app.appID] = {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = {"Base-4"}}
  common_functions:AddItemsIntoJsonFile(json_file, parent_item, added_json_items)
end

common_steps:PreconditionSteps("PreconditionSteps", const.precondition.REGISTER_APP)

--------------------------------------------Test----------------------------------------------
common_steps:AddNewTestCasesGroup("Tests")


function Test:PutFile_Allowed()
  local cid = self.mobileSession:SendRPC("PutFile", {
    syncFileName = "sync_file_name",
    fileType = "GRAPHIC_PNG",
    persistentFile = false,
    systemFile = false
    }, "files/icon.png")
  EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
end

function Test:SendLocation_Allowed()
  local cid = self.mobileSession:SendRPC("SendLocation", {
    longitudeDegrees = 1, latitudeDegrees = 1})
  EXPECT_HMICALL("Navigation.SendLocation")
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
end

function Test:GetWayPoints_Allowed()
	local cid = self.mobileSession:SendRPC("GetWayPoints", {wayPointType = "ALL"})
	EXPECT_HMICALL("Navigation.GetWayPoints", {wayPointType = "ALL"})
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
			coordinate =
			{
				latitudeDegrees = 1.1,
				longitudeDegrees = 1.1
			}})
	end)
	EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
end

function Test:SetAppIcon_Disallowed()
  local cid = self.mobileSession:SendRPC("SetAppIcon", {syncFileName = "sync_file_name"})
  EXPECT_RESPONSE(cid, {success = false, resultCode = "DISALLOWED"})
end

function Test:ListFiles_Disallowed()
  local cid = self.mobileSession:SendRPC("ListFiles", {})
  EXPECT_RESPONSE(cid, {success = false, resultCode = "DISALLOWED"})
end

function Test:SubscribeVehicleData_Disallowed()
  local cid = self.mobileSession:SendRPC("SubscribeVehicleData", {gps = true})
  EXPECT_RESPONSE(cid, {
    success = false, 
    resultCode = "DISALLOWED",
    info = "'gps' is disallowed by policies",
    gps = {
      dataType = "VEHICLEDATA_GPS",
      resultCode = "DISALLOWED"}})
  EXPECT_NOTIFICATION("OnHashChange")
  :Times(0)
  -- delay because of Times(0) waiting
  common_functions:DelayedExp(2000)
end

-------------------------------------------Postconditions-------------------------------------
common_steps:AddNewTestCasesGroup("Postconditions")

common_steps:RestoreIniFile("Postconditions_Restore_PreloadedPT", "sdl_preloaded_pt.json")

common_steps:StopSDL("Postconditions_StopSDL")
