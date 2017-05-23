---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-29437] [Policies] [External UCS] SDL informs HMI about <externalConsentStatus> via GetListOfPermissions response
-- [APPLINK-29119] [HMI API] ExternalConsentStatus struct & EntityStatus enum
-- [APPLINK-18657] [HMI API] GetListOfPermissions request/response
-- [APPLINK-15510] [HMI RPC validation]: SDL behavior in case HMI sends invalid response AND SDL must use this response internally
--
-- Description:
-- Check that SDL sends to HMI empty array of <externalConsentStatus> via GetListOfPermissions response when
-- SDL invalidates notification OnAppPermissionConsent due to missing mandatory parameter entityType
--
-- Used preconditions
-- 1. SDL and HMI are running
-- 2. Application is registered and activated
-- 3. Application is assigned to functional groups: Base-4, user-consent groups: Location-1 and Notifications
--
-- Performed steps:
-- 1. HMI sends <externalConsentStatus> to SDL via OnAppPermissionConsent 
-- (mandatory parameter entityType is missed, rest of params present and within bounds, EntityStatus = 'ON')
-- 2. HMI sends to SDL GetListOfPermissions (appID)
--
-- Expected result:
-- 1. SDL doesn't receive updated Permission items and consent status
-- 2. SDL sends to HMI empty array <externalConsentStatus>

---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')

--[[ Local variables]]
local sdl_preloaded_pt_path = config.pathToSDL .. "sdl_preloaded_pt.json"
local hmi_app_id, id_group_1, id_group_2

--[[ Preconditions ]]
common_steps:AddNewTestCasesGroup("Preconditions")

common_functions:BackupFile("sdl_preloaded_pt.json")

function Test.Preconditions_Add_appID_To_sdl_preloaded_pt()
  local parent_item = {"policy_table", "app_policies"}
  local json_items_to_add = {}
  json_items_to_add[const.default_app.appID] = {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = {"Base-4", "Location-1", "Notifications"}
  }
  common_functions:AddItemsIntoJsonFile(sdl_preloaded_pt_path, parent_item, json_items_to_add)
end

common_steps:PreconditionSteps("Preconditions", const.precondition.ACTIVATE_APP)

function Test:Preconditions_GetListOfPermissions_before_OnAppPermissionConsent()
  hmi_app_id = common_functions:GetHmiAppId(const.default_app.appName, self)
  local request_id = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", {appID = hmi_app_id}) 
  EXPECT_HMIRESPONSE(request_id,{
    result = {
      code = 0, 
      method = "SDL.GetListOfPermissions", 
      allowedFunctions = {
        {name = "Location"},
        {name = "Notifications"}        
      },
      externalConsentStatus = {}
    }
  })
  :ValidIf(function(_,data)
    -- 'allowed' values should be empty
    if data.result.allowedFunctions[1].allowed ~= nil 
    or data.result.allowedFunctions[2].allowed ~= nil then
      self.FailTestCase("allowedFunctions's 'allowed' values are not empty.")
    else
      return true
    end
  end)
  :Do(function(_,data)
    id_group_1 = data.result.allowedFunctions[1].id
    id_group_2 = data.result.allowedFunctions[2].id
  end)
end

---------------------------------------------------------------------------------------------
--[[ Test ]]
common_steps:AddNewTestCasesGroup("Test")

function Test:OnAppPermissionConsent_without_entityType()
	self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
    appID = hmi_app_id, 
    consentedFunctions = {
        {name = "Location", id = id_group_1, allowed = true},
        {name = "Notifications", id = id_group_2, allowed = true},       
      },
    externalConsentStatus = {
        {entityID = 94, status = "ON"}
      },
    source = "GUI"
    })
    EXPECT_NOTIFICATION("OnPermissionsChange")
    :Times(0)
    -- delay to make sure database is already updated and wait for notification
    common_functions:DelayedExp(10000)
end

function Test:GetListofPermissions_without_entityType()
  local request_id = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", {appID = hmi_app_id})
  EXPECT_HMIRESPONSE(request_id,{
    result = {
      code = 0, 
      method = "SDL.GetListOfPermissions", 
      allowedFunctions = {
        {name = "Location", id = id_group_1},
        {name = "Notifications", id = id_group_2}        
      },
      externalConsentStatus = {}
    }
  })
  :ValidIf(function(_,data)
    -- 'allowed' values should be empty
    if data.result.allowedFunctions[1].allowed ~= nil 
    or data.result.allowedFunctions[2].allowed ~= nil then
      self.FailTestCase("allowedFunctions's 'allowed' values are not empty.")
    else
      return true
    end
  end)
end

---------------------------------------------------------------------------------------------
--[[ Postconditions ]]
common_steps:AddNewTestCasesGroup("Postconditions")

common_steps:UnregisterApp("Postconditions_UnregisterApp", const.default_app.appName)
common_steps:RestoreIniFile("Postconditions_Restore_PreloadedPT", "sdl_preloaded_pt.json")
common_steps:StopSDL("Postconditions_StopSDL")
