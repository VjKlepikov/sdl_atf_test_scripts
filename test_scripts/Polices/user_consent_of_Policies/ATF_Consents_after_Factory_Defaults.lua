---------------------------------------------------------------------------------------------
-- Requirement summary: 
-- [APPLINK-23496]: [Policies] FACTORY_DEFAULTS
--
-- Description: 
-- On FACTORY_DEFAULTS, Policy Manager must clear all user consent records 
--
-- Preconditions:
-- 1. SDL and HMI are running
-- 2. App is registered and activated
-- 3. User consent is sent for app's permission via "OnAppPermissionConsent"
--
-- Steps:
-- 1. HMI -> SDL: OnExitAllApplications (reason: "FACTORY_DEFAULTS")
-- 2. SDL -> App: OnAppInterfaceUnregistered (reason: "FACTORY_DEFAULTS")
--
-- Expected result:
-- 1. Policies Manager clears all user consent records

---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')
local testCasesForPolicySDLErrorsStops = require('user_modules/shared_testcases_genivi/testCasesForPolicySDLErrorsStops')

--[[ Local variables]]
local system_files_path = common_functions:GetValueFromIniFile("SystemFilesPath")
local snapshot_file = common_functions:GetValueFromIniFile("PathToSnapshot")
local snapshot_path = system_files_path .. "/" .. snapshot_file
local hmi_app_id, id_group_1
config.ExitOnCrash = false

--[[ Preconditions ]]
common_steps:AddNewTestCasesGroup("Preconditions")

-- Remove existed snapshot file
os.execute( "rm -f " .. snapshot_path)

common_functions:BackupFile("sdl_preloaded_pt.json")

function Test.Preconditions_Add_appID_To_sdl_preloaded_pt()
  local sdl_preloaded_pt = config.pathToSDL .. "sdl_preloaded_pt.json"
  local parent_item = {"policy_table", "app_policies"}
  local json_items_to_add = {}
  json_items_to_add[const.default_app.appID] = {
    keep_context = true,
    steal_focus = true,
    priority = "NORMAL",
    default_hmi = "NONE",
    groups = {"Base-4", "Notifications"}
  }
  common_functions:AddItemsIntoJsonFile(sdl_preloaded_pt, parent_item, json_items_to_add)
end

common_steps:PreconditionSteps("Preconditions", const.precondition.ACTIVATE_APP)

function Test:Preconditions_GetListOfPermissions_Before_User_Consent()
  hmi_app_id = common_functions:GetHmiAppId(const.default_app.appName, self)
  local request_id = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", {appID = hmi_app_id}) 
  EXPECT_HMIRESPONSE(request_id,{
    result = {
      code = 0, 
      method = "SDL.GetListOfPermissions", 
      allowedFunctions = {{name = "Notifications"}},
      externalConsentStatus = {}
    }
  })
  :ValidIf(function(_,data)
    if data.result.allowedFunctions[1].allowed ~= nil then
      self.FailTestCase("allowedFunctions's 'allowed' value is not empty.")
    end
    return true
  end)
  :Do(function(_,data)
    id_group_1 = data.result.allowedFunctions[1].id
  end)
end

function Test:Preconditions_User_Consent()
  self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
    appID = hmi_app_id, 
    consentedFunctions = {{name = "Notifications", id = id_group_1, allowed = true}},
    externalConsentStatus = {{entityType = 115, entityID = 14, status = "ON"}},
    source = "GUI"
  })
  EXPECT_NOTIFICATION("OnPermissionsChange")
  -- delay to make sure Policy Table is already updated
  common_functions:DelayedExp(2000)
end

function Test:Preconditions_GetListOfPermissions_After_User_Consent()
  local request_id = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", {appID = hmi_app_id}) 
  EXPECT_HMIRESPONSE(request_id,{
    result = {
      code = 0, 
      method = "SDL.GetListOfPermissions", 
      allowedFunctions = {{name = "Notifications", id = id_group_1, allowed = true}},
      externalConsentStatus = {{entityType = 115, entityID = 14, status = "ON"}}
    }
  })
end

function Test:Preconditions_Verify_User_Consent_Records_Exist_In_Snapshot()
  -- check Snapshot file exists
  if not common_functions:IsFileExist(snapshot_path) then
    self:FailTestCase("Snapshot file does not exist.")
  end
  -- check appID exists in "user_consent_records"
  local path_to_user_consent_records = {"policy_table", "device_data", config.deviceMAC, "user_consent_records"}
  local user_consent_records = common_functions:GetItemsFromJsonFile(snapshot_path, path_to_user_consent_records)
  if user_consent_records[const.default_app.appID] == nil then
    self:FailTestCase("The 'user_consent_records' of appID " .. const.default_app.appID .. " does not exist in Snapshot.")
  end
end

---------------------------------------------------------------------------------------------
--[[ Test ]]
common_steps:AddNewTestCasesGroup("Test")

function Test:OnExitAllApplications_FACTORY_DEFAULTS()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", 
    {reason = "FACTORY_DEFAULTS"})
  EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", {reason = "FACTORY_DEFAULTS"})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = false})
end

function Test.Wait_For_OnSDlClose_Updated_In_Log()
  common_functions:DelayedExp(1000)
end

function Test:OnSDLClose()
  -- Replace for EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose") because of ATF limitation:
  local result = testCasesForPolicySDLErrorsStops.ReadSpecificMessage("BasicCommunication.OnSDLClose")
  if not result then
    self:FailTestCase("'BasicCommunication.OnSDLClose' is not observed in SmartDeviceLinkCore.log")
  end
end

common_steps:PreconditionSteps("Restart_Steps", const.precondition.ACTIVATE_APP)

function Test:GetListOfPermissions_After_FACTORY_DEFAULTS()
  hmi_app_id = common_functions:GetHmiAppId(const.default_app.appName, self)
  local request_id = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", {appID = hmi_app_id}) 
  EXPECT_HMIRESPONSE(request_id,{
    result = {
      code = 0, 
      method = "SDL.GetListOfPermissions", 
      allowedFunctions = {{name = "Notifications"}},
      externalConsentStatus = {}
    }
  })
  :ValidIf(function(_,data)
    if data.result.allowedFunctions[1].allowed ~= nil then
      self.FailTestCase("allowedFunctions's 'allowed' value is not empty.")
    end
    return true
  end)
end

function Test:Trigger_PTU_Process_To_Refresh_Snapshot()
  local cid = self.hmiConnection:SendRequest("SDL.UpdateSDL")
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  EXPECT_HMIRESPONSE(cid,{result = {code = 0, method = "SDL.UpdateSDL", result = "UPDATE_NEEDED" }})
  -- delay to wait for Snapshot
  common_functions:DelayedExp(2000)
end

function Test:Verify_User_Consent_Records_Not_Exist_In_Snapshot()
  -- check Snapshot file exists
  if not common_functions:IsFileExist(snapshot_path) then
    self:FailTestCase("Snapshot file does not exist.")
  end
  -- check appID does not exist in "user_consent_records"
  local path_to_user_consent_records = {"policy_table", "device_data", config.deviceMAC, "user_consent_records"}
  local user_consent_records = common_functions:GetItemsFromJsonFile(snapshot_path, path_to_user_consent_records)
  if user_consent_records[const.default_app.appID] ~= nil then
    self:FailTestCase("The 'user_consent_records' of appID " .. const.default_app.appID .. " exists in Snapshot.")
  end
end

---------------------------------------------------------------------------------------------
--[[ Postconditions ]]
common_steps:AddNewTestCasesGroup("Postconditions")

common_steps:UnregisterApp("Postconditions_UnregisterApp", const.default_app.appName)
common_steps:RestoreIniFile("Postconditions_Restore_PreloadedPT", "sdl_preloaded_pt.json")
common_steps:StopSDL("Postconditions_StopSDL")
