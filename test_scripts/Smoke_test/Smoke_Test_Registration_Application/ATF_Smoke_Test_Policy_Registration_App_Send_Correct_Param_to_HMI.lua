---------------------------------------------------------------------------------------------
-- TC: Check that SDL:
-- -- Adds new appIDs to local policy table
-- -- Sends onHMIStatus with default hmi level
-- -- Sends OnPermissionChange with PRCs from default
-- Precondition: App is configured to do not reply for OnSystemRequest
-- Steps:
-- -- 1. Register App
-- Expected behaviour
-- -- 1. App receives OnHMIStatus with "default_hmi" value from table "application", id=default
-- -- 2. App receives OnPermissionChange notification with default permissionItem
-- -- 3. SDL sends to HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
-- -- 4. SDL sends to the App OnSystemRequest

-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

------------------------------------ Precondition -------------------------------------------
function Test:Delete_Policy_Table()
  common_functions:DeletePolicyTable()
end
common_steps:PreconditionSteps("PreconditionSteps", 5)

---------------------------------------- Steps ----------------------------------------------
function Test:Verify_SDL_Send_Correct_Params_to_HMI()
  common_functions:DelayedExp(3000)
  local app_name = config.application1.registerAppInterfaceParams.appName
  local app_id = config.application1.registerAppInterfaceParams.appID
  local cid = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = {appName = app_name}})
  self.mobileSession:ExpectResponse(cid, {success = true, resultCode = "SUCCESS"})
  self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  self.mobileSession:ExpectNotification("OnPermissionsChange", arrayRegisterNewApp)
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})
  self.mobileSession:ExpectNotification("OnSystemRequest")
end

-------------------------------------------Postconditions-------------------------------------
common_steps:StopSDL("Postcondition_StopSDL")

