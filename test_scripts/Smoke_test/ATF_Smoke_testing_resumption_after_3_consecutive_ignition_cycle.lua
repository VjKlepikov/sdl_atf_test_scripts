---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-15634]: [Data Resumption]: Data resumption on IGNITION OFF
-- [APPLINK-15606]: [HMILevel Resumption]: Conditions to resume app to FULL in the next ignition cycle

-- Description:
-- SDL Must perform Data Resumption on the third Ignition On
--  after disconnect on Ignition Off

-- Preconditions:
-- 1. App is registered and activated
-- 2. App adds 1 command

-- Steps:
-- 1. Perform IgnitionOff -> IgnitionOn two times
-- 2. Register App and check Data Resumption

-- Expected result:
-- SDL -> HMI: BasicCommunication.OnAppRegistered
-- SDL -> Mob: RegisterAppInterface with success = true, resultCode = "SUCCESS"
-- SDL -> HMI: Send UI.AddCommand
-- SDL -> Mob: hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"
---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')

const.default_app.appHMIType = { "MEDIA" }
const.default_app.isMediaApplication = true

---------------------------------------------------------------------------------------------
--[[ Local Functions ]]

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

function Test:Precondition_AddCommand()
  self.icmdID = 1
  self.hmi_app_id = common_functions:GetHmiAppId(const.default_app_name, self)

  local cid = self.mobileSession:SendRPC("AddCommand", {
    cmdID = self.icmdID,
    menuParams = { menuName = "Play" .. tostring(self.icmdID) }
  })

  EXPECT_HMICALL("UI.AddCommand", {
    appID = self.hmi_app_id,
    cmdID = self.icmdID,
    menuParams = { menuName = "Play" .. tostring(self.icmdID) }
  })
  :Do(function(_, data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  self.mobileSession:ExpectNotification("OnHashChange")
  :Do(function(_, data)
    self.currentHashID = data.payload.hashID
  end)

  self.mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

---------------------------------------------------------------------------------------------
--[[ Test There is Data Resumption on the third Ignition ON ]]
function Test:TestStep_First_NotificationSuspend()
  SendNotificationSuspend(self)
end
common_steps:IgnitionOff("TestStep_First_IgnitionOff")
common_steps:IgnitionOn("TestStep_Second_IgnitionOn")
function Test:TestStep_Second_NotificationSuspend()
  SendNotificationSuspend(self)
end
common_steps:IgnitionOff("TestStep_Second_IgnitionOff")
common_steps:IgnitionOn("TestStep_Third_IgnitionOn")

common_steps:AddMobileSession("TestStep_AddMobileSession")

function Test:TestStep_Register_App_and_check_Data_resumption()
  const.default_app.hashID = self.currentHashID
  local correlation_id = self.mobileSession:SendRPC("RegisterAppInterface", const.default_app)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")

  self.mobileSession:ExpectResponse(correlation_id, {
    success = true, resultCode = "SUCCESS"
  })

  self.mobileSession:ExpectNotification("OnHMIStatus", {
    hmiLevel = "NONE",
    audioStreamingState = "NOT_AUDIBLE",
    systemContext = "MAIN"
  })

  EXPECT_HMICALL("UI.AddCommand", {
    appID = self.hmi_app_id,
    cmdID = self.icmdID,
    menuParams = { menuName = "Play" .. tostring(self.icmdID) }
  })

  EXPECT_HMICALL("BasicCommunication.ActivateApp")
  :Times(0)
  common_functions:DelayedExp(10000)
end

---------------------------------------------------------------------------------------------
--[[ Postconditions ]]
common_steps:StopSDL("Postcondition_StopSDL")
