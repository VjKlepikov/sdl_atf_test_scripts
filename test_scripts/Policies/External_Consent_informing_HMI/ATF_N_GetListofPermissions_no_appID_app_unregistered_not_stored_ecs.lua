---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-29437] [Policies] [External UCS] SDL informs HMI about <externalConsentStatus> via GetListOfPermissions response
-- [APPLINK-29119] [HMI API] ExternalConsentStatus struct & EntityStatus enum
-- [APPLINK-18657] [HMI API] GetListOfPermissions request/response
--
-- Description:
-- Upon GetListOfPermissions_request, SDL must inform "externalConsentStatus" setting to HMI
--
-- Used preconditions
-- 1. SDL and HMI are running
-- 2. First application is registered and activated
-- 3. Fisrt application is assigned to functional groups: Base-4, user-consent groups: Location-1 and Notifications
-- 4. HMI sends empty <externalConsentStatus> to SDl via OnAppPermissionConsent
-- 5. Second application is registered then unregistered
--
-- Performed steps:
-- 1. HMI sends to SDL GetListOfPermissions (appID of the unregistered application)
--
-- Expected result:
-- 1. SDL invalidates the appID and cuts it off, the GetListOfPermissions request is treated as if sent without appID
-- 2. SDL sends to HMI empty <externalConsentStatus> array

---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')

--[[ Local variables]]
local sdl_preloaded_pt_path = config.pathToSDL .. "sdl_preloaded_pt.json"
local hmi_app_id, hmi_app_id2, id_group_1, id_group_2
local app_2 = config.application2.registerAppInterfaceParams

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

function Test:Preconditions_OnAppPermissionConsent_Empty_ecs()
	self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
    appID = hmi_app_id, 
    consentedFunctions = {
        {name = "Location", id = id_group_1, allowed = true},
        {name = "Notifications", id = id_group_2, allowed = true},       
      },
    source = "GUI"
  })
  EXPECT_NOTIFICATION("OnPermissionsChange")
  -- delay to make sure database is already updated
  common_functions:DelayedExp(2000)
end

common_steps:AddMobileSession("Preconditions_Add_Session_For_Second_App", "mobileConnection", "mobileSession2")
common_steps:RegisterApplication("Preconditions_Register_Second_App", "mobileSession2", app_2)
function Test:Preconditions_GetHmiAppId_SecondApp()
  hmi_app_id2 = common_functions:GetHmiAppId(app_2.appName, self)
end
common_steps:UnregisterApp("Preconditions_Unregister_Second_App", app_2.appName)

---------------------------------------------------------------------------------------------
--[[ Test ]]
common_steps:AddNewTestCasesGroup("Test")

function Test:GetListofPermissions_appID_Unregistered_App_Empty_ecs()
  local request_id = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", {appID = hmi_app_id2})
  EXPECT_HMIRESPONSE(request_id,{
    result = {
      code = 0, 
      method = "SDL.GetListOfPermissions", 
      allowedFunctions = {
        {name = "Location", id = id_group_1, allowed = true},
        {name = "Notifications", id = id_group_2, allowed = true}        
      },
      externalConsentStatus = {}
    }
  })
end

---------------------------------------------------------------------------------------------
--[[ Postconditions ]]
common_steps:AddNewTestCasesGroup("Postconditions")

common_steps:UnregisterApp("Postconditions_UnregisterApp", const.default_app.appName)
common_steps:RestoreIniFile("Postconditions_Restore_PreloadedPT", "sdl_preloaded_pt.json")
common_steps:StopSDL("Postconditions_StopSDL")
