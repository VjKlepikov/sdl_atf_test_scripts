---------------------------------------------------------------------------------------------
-- Requirement summary:
-- APPLINK-19314	[GeneralResultCodes]DISALLOWED: RPC is omitted in the PolicyTable group(s) assigned to the application
-- APPLINK-16839 [Policies] HMI Levels the request is allowed to be processed in (multiple functional groups)

-- Description:
-- Check that SDL verifies every App's request before processing it using appropriate group of permissions.

-- Precondition
-- App policies includes Base-4 and another group: SendLocationOnly

-- Steps: 
-- 1. Send RPCs of Base-4: PutFile
-- 2. Send RPCs of "SendLocationOnly" group: SendLocation
-- 3. Send RPCs not from both: SubscribeVehicleData

-- Expected result:
-- 1. Allowed
-- 2. Allowed.
-- 3. Disallowed.

-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

-------------------------------------------Preconditions-------------------------------------
common_steps:AddNewTestCasesGroup("Preconditions")

common_steps:BackupFile("Preconditions_Back_Up_sdl_preloaded_pt", "sdl_preloaded_pt.json")

function Test:Preconditions_Update_sdl_preloaded_pt()
  local parent_item = {"policy_table", "app_policies"}
  local added_json_items ={}
  added_json_items[const.default_app.appID] = {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = {"Base-4", "SendLocationOnly"}}
  common_functions:AddItemsIntoJsonFile( 
      config.pathToSDL .. "sdl_preloaded_pt.json", parent_item, added_json_items)
end

common_steps:PreconditionSteps("PreconditionSteps", 7)

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