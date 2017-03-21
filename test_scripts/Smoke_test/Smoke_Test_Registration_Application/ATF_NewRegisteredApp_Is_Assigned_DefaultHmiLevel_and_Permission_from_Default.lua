---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-19072]: [PolicyTableUpdate] OnStatusUpdate(UPDATE_NEEDED) on new PTU request

-- Description: PoliciesManager must notify HMI via SDL.OnStatusUpdate(UPDATE_NEEDED)
-- on any PTU trigger. Ford-specific and EXTERNAL_PROPRIETARY exception:
-- No notification should be sent on user requested PTU from HMI (via SDL.UpdateSDL request).

-- Precondition:
-- 1. App is configured to do not reply for OnSystemRequest.
-- 2. Device is consented

-- Steps:
-- 1. Register new App

-- Expected behaviour
-- 1. App receives OnHMIStatus with "default_hmi" value from table "application", id=default
-- 2. App receives OnPermissionChange notification with default permissionItem
-- 3. SDL sends to HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
-- 4. SDL sends to the App OnSystemRequest

-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')

------------------------------ Variables and Common Functions -------------------------------
app = common_functions:CreateRegisterAppParameters(
  {appID = "2", appName = "NAVIGATION", isMediaApplication = false, appHMIType = {"NAVIGATION"}}
)
preloaded_file = config.pathToSDL .. "sdl_preloaded_pt.json"
copied_preload_file = config.pathToSDL .. "update_sdl_preloaded_pt.json"
parent_item = {"policy_table","app_policies","default","default_hmi"}
default_hmi = common_functions:GetParameterValueInJsonFile(preloaded_file, parent_item)

------------------------------------ Precondition -------------------------------------------

function Test:Delete_Policy_Table()
  common_functions:DeletePolicyTable()
end

function Test:Create_PTU_file()
  os.execute(" cp " .. preloaded_file .. " " .. copied_preload_file)
  local parent_item = {"policy_table","module_config"}
  local removed_json_items = {"preloaded_pt", "preloaded_date"}
  common_functions:RemoveItemsFromJsonFile(copied_preload_file, parent_item, removed_json_items)
end

common_steps:PreconditionSteps("PreconditionSteps", 7)

testCasesForPolicyTable:updatePolicy(copied_preload_file, _, "PreconditionSteps_UpdatePolicy")

---------------------------------------- Steps ----------------------------------------------
function Test:StartNewSession()
  self.mobileSession1 = mobile_session.MobileSession( self, self.mobileConnection)
  self.mobileSession1:StartService(7)
end

function Test:Register_NewApp_And_Verify_SDL_Send_Correct_Params_to_HMI()
  local cid = self.mobileSession1:SendRPC("RegisterAppInterface", app)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = {appName = app.appName}})
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})
  self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", { requestType = "PROPRIETARY",
      fileName = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate" })
  EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
  self.mobileSession1:ExpectResponse(cid, {success = true, resultCode = "SUCCESS"})
  self.mobileSession1:ExpectNotification("OnHMIStatus", {hmiLevel = default_hmi, audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  self.mobileSession1:ExpectNotification("OnPermissionsChange", arrayRegisterNewApp)
end

-------------------------------------------Postconditions-------------------------------------
common_steps:StopSDL("Postcondition_StopSDL")
