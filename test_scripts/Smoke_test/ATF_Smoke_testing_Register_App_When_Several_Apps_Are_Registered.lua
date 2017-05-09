---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-16420]: In case RegisterAppInterface_request comes to SDL with correct structure and data and successfully registered on SDL, SDL must:
-- 1. notify HMI with OnAppRegistered notification about application registering
-- 2. respond with resultCode "SUCCESS" and success:"true" value to mobile application.

-- Description: Check that is able to register App if several Apps are registered

-- Preconditions:
-- 1. 2 apps are registered

-- Steps:
-- 1. Exit App 1
-- 2. Start App 1 again

-- Expected result:
-- 1. App 1 is unregistered, App 2 is still registered
-- 2. App 1 is registered, App 2 is still registered (checked by activate App 2)

---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')

--[[ Local variables]]
local app1 = common_functions:CreateRegisterAppParameters(
  {isMediaApplication = true, appHMIType = {"MEDIA"}, appID = "1", appName = "Application1"})
local app2 = common_functions:CreateRegisterAppParameters(
  {isMediaApplication = true, appHMIType = {"MEDIA"}, appID = "2", appName = "Application2"})

---------------------------------------------------------------------------------------------
--[[ Preconditions ]]
common_steps:AddNewTestCasesGroup("Preconditions")
common_steps:PreconditionSteps("Preconditions", const.precondition.CONNECT_MOBILE)
common_steps:AddMobileSession("Preconditions_AddMobileSession1", _, "mobileSession1")
common_steps:RegisterApplication("Preconditions_RegisterApp1", "mobileSession1", app1)
common_steps:AddMobileSession("Preconditions_AddMobileSession2", _, "mobileSession2")
common_steps:RegisterApplication("Preconditions_RegisterApp2", "mobileSession2", app2)

---------------------------------------------------------------------------------------------
--[[ Test ]]
common_steps:AddNewTestCasesGroup("Test")
common_steps:UnregisterApp("UnregisterApp1", app1.appName)
function Test:RegisterApp1Again()
  common_functions:StoreApplicationData("mobileSession1", app1.appName, app1, _, self)
  local corIdRai = self.mobileSession1:SendRPC("RegisterAppInterface", app1)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = {appName = app1.appName}})
  self.mobileSession1:ExpectResponse(corIdRai, {success = true, resultCode = "SUCCESS"})
  self.mobileSession1:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
end
common_steps:ActivateApplication("ActivateApp2", app2.appName)

---------------------------------------------------------------------------------------------
--[[ Postconditions ]]
common_steps:AddNewTestCasesGroup("Postconditions")
common_steps:UnregisterApp("Postconditions_UnregisterApp1", app1.appName)
common_steps:UnregisterApp("Postconditions_UnregisterApp2", app2.appName)
function Test:Postconditions_StopSDL()
  StopSDL()
end
