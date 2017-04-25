-----------------------------------Test cases----------------------------------------
-- Check, that in case an application is in FULL HMILevel
-- and SDL receives BasicCommunication.OnEventChanged("DEACTIVATE_HMI","isActive":true)
-- from HMI, SDL must send OnHMIStatus (“HMILevel: BACKGROUND, audioStreamingState: NOT_AUDIBLE”) to such application.
-- Precondition:
-- -- 1. SDL is started
-- -- 2. HMI is started
-- -- 3. App is registered
-- -- 4. App is in "FULL" HMI Level
-- Steps:
-- -- 1. Connect mobile
-- -- 2. Activate Carplay/GAL
-- Expected result
-- -- 1. Connect mobile
-- -- 2. SDL receives BasicCommunication.OnEventChanged("eventName":"DEACTIVATE_HMI","isActive":true) from HMI.
-- -- -- SDL sends OnHMIStatus (“HMILevel: BACKGROUND, audioStreamingState: NOT_AUDIBLE”))
-- Postcondition
-- -- 1.UnregisterApp
-- -- 2.StopSDL
-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

--------------------------------------- Local Variables--------------------------------------
local app_name = config.application1.registerAppInterfaceParams.appName

--------------------------------------Preconditions------------------------------------------
common_steps:PreconditionSteps("Precondition",7)

-----------------------------------------------Steps------------------------------------------
function Test:Verify_App_Change_To_BACKGROUND_Incase_HmiLevel_Is_FULL_And_DeactiveHmi_Is_True()
  self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",
    { isActive = true, eventName="DEACTIVATE_HMI" })
  self.mobileSession:ExpectNotification("OnHMIStatus",
	  { hmiLevel="BACKGROUND", audioStreamingState="NOT_AUDIBLE", systemContext = "MAIN" })
end

-------------------------------------------Postcondition-------------------------------------
common_steps:UnregisterApp("Postcondition_UnRegisterApp", app_name)
common_steps:StopSDL("Postcondition_StopSDL")
