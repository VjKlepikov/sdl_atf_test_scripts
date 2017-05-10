---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-16420]: In case RegisterAppInterface_request comes to SDL with correct structure and data and successfully registered on SDL, SDL must:
-- 1. notify HMI with OnAppRegistered notification about application registering
-- 2. respond with resultCode "SUCCESS" and success:"true" value to mobile application.

-- Description: Check that is able to register App after connection was closed

-- Preconditions:
-- 1. App is registered

-- Steps:
-- 1. Close App (close mobile connection)
-- 2. Start App again

-- Expected result:
-- 1. App is unregistered
-- 2. App is started and successfully registered

---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')

---------------------------------------------------------------------------------------------
--[[ Preconditions ]]
common_steps:AddNewTestCasesGroup("Preconditions")
common_steps:PreconditionSteps("Preconditions", const.precondition.REGISTER_APP)

---------------------------------------------------------------------------------------------
--[[ Test ]]
common_steps:AddNewTestCasesGroup("Test")
common_steps:CloseMobileSession("Close Mobile Connection", mobileConnection)
common_steps:AddMobileConnection("Add Mobile Connection")
common_steps:AddMobileSession("Add Mobile Session")
function Test:RegisterAppAgain()
  common_functions:StoreApplicationData("mobileSession", const.default_app_name, const.default_app, _, self)
  local corIdRai = self.mobileSession:SendRPC("RegisterAppInterface", const.default_app)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = {appName = const.default_app_name}})
  self.mobileSession:ExpectResponse(corIdRai, {success = true, resultCode = "SUCCESS"})
  self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
end

---------------------------------------------------------------------------------------------
--[[ Postconditions ]]
common_steps:AddNewTestCasesGroup("Postconditions")
common_steps:UnregisterApp("Postconditions_UnregisterApp", const.default_app_name)
function Test:Postconditions_StopSDL()
  StopSDL()
end
