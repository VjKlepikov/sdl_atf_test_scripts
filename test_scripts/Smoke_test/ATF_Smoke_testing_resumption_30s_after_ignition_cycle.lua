---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-15574]: [HMILevel Resumption] Assign "default_hmi" first - independently on app's HMILevel resumption status
-- [APPLINK-15606]: [HMILevel Resumption] Conditions to resume app to FULL in the next ignition cycle.

-- Description:
-- SDL Must Not perform hmiLevel Resumption when App is connecting
--  more than 30 seconds after Ignition On

-- Preconditions:
-- 1. App is registered and activated

-- Steps:
-- 1. Perform IgnitionOff, IgnitionOn cycle
-- 2. Wait 31 seconds before adding Mobile Session
-- 3. Register App and check default hmiLevel is set
-- 4. Wait 5 seconds and check there is no BC.ActivateApp

-- Expected result:
-- SDL -> HMI: BasicCommunication.OnAppRegistered
-- SDL -> Mob: RegisterAppInterface with success = true, resultCode = "SUCCESS"
-- SDL -> HMI: Send BasicCommunication.UpdateAppList
-- SDL -> Mob: hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"
---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')

const.default_app.isMediaApplication = true

---------------------------------------------------------------------------------------------
--[[ Local Funcitons ]]

--[[ @SendNotificationSuspend: the function send BC.OnExitAllApplications(SUSPEND)
--    and expects HMI Notification BC.OnSDLPersistenceComplete. This ensures data
--    is stored for data resumption after IGNITION OFF
--]]
local function SendNotificationSuspend(self)
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
end

---------------------------------------------------------------------------------------------
--[[ Preconditions ]]
common_steps:PreconditionSteps("Precondition", const.precondition.ACTIVATE_APP)

---------------------------------------------------------------------------------------------
--[[ Test There is no hmiLevel Resumption 30s after Ignition ON ]]
function Test:TestStep_SendNotificationSuspend()
  SendNotificationSuspend(self)
end
common_steps:IgnitionOff("TestStep_IgnitionOff")
common_steps:IgnitionOn("TestStep_IgnitionOn")

function Test:TestStep_Wait_31s()
  common_functions:UserPrint(const.color.green,
    "Wait 31s before adding Mobile Session and registering app")
  common_functions:DelayedExp(31000)
end

common_steps:AddMobileSession("TestStep_AddMobileSession")

function Test:TestStep_Register_App_and_check_no_resumption()
  local correlation_id = self.mobileSession:SendRPC("RegisterAppInterface", const.default_app)
  
  -- Delay expectation: ActivateApp comes ~ 3s after RegisterAppInterface
  common_functions:DelayedExp(5000)
 
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")

  self.mobileSession:ExpectResponse(correlation_id, {
    success = true, resultCode = "SUCCESS"
  })

  EXPECT_HMICALL("BasicCommunication.ActivateApp")
  :Times(0)

  EXPECT_HMICALL("BasicCommunication.UpdateAppList")
  :Do(function(_, data)
    self.hmiConnection:SendResponse(data.id, "BasicCommunication.UpdateAppList", "SUCCESS", {})
  end)

  EXPECT_NOTIFICATION("OnHMIStatus", {
    hmiLevel = "NONE",
    systemContext = "MAIN",
    audioStreamingState = "NOT_AUDIBLE"
  })
end

---------------------------------------------------------------------------------------------
--[[ Postconditions ]]
common_steps:StopSDL("Postcondition_StopSDL")
