---------------------------------------------------------------------------------------------
-- Requirement summary:
--  APPLINK-23742 [HeartBeat] SDL must start heartbeat only after first Heartbeat request from mobile app
--  APPLINK-17232 [HeartBeat]: SDL must close only session in case mobile app does not answer on Heartbeat_request

-- Description:
--  In case 
--  mobile app sends first HeartBeat request by itself over control service to SDL
--  SDL must:
--  respond HeartBeat_ACK over control service to mobile app
--  start HeartBeat timeout (defined at .ini file)
--  In case 
--  SDL has one connection with app 
--  and app does not respond on Heartbeat request from SDL
--  SDL must
--  close session with this app

-- Preconditions:
-- 1. HeartBeatTimeout = 5000 and MaxSupportedProtocolVersion = 3 in smartDeviceLink.ini
-- 2. SDL is started

-- Steps:
-- 1. Register App with HB config: App sends HB message to SDL but not answer HB from SDL
-- 2. Wait for 15 seconds

-- Expected result:
-- 1. App (with protocol version = 3) is registered.
-- 2. App is disconnected by HB timeout
----- SDL -> HMI: BasicCommunication.OnAppUnregistered
----- SDL -> App: EndService

-----------------------------------General Settings for Configuration------------------------
require('user_modules/all_common_modules')

-------------------------------------- Preconditions ----------------------------------------
common_steps:AddNewTestCasesGroup("Preconditions")
config.heartbeatTimeout = 7000
config.defaultProtocolVersion = 3
common_steps:BackupFile("Precondition_Backup_Ini_File", "smartDeviceLink.ini")
common_steps:SetValuesInIniFile("Precondition_Update_HeartBeatTimeout_Is_5000", 
    "%p?HeartBeatTimeout%s? = %s-[%d]-%s-\n", "HeartBeatTimeout", 5000)
common_steps:SetValuesInIniFile("Precondition_Update_MaxSupportedProtocolVersion_Is_3", 
    "%p?MaxSupportedProtocolVersion%s? = %s-[%d]-%s-\n", "MaxSupportedProtocolVersion", 3)
common_steps:PreconditionSteps("Precondition", const.precondition.CONNECT_MOBILE)

------------------------------------------- Tests --------------------------------------------
common_steps:AddNewTestCasesGroup("Tests")
function Test:StartSession_And_RegisterApp_App_Not_Send_HB_To_SDL()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  --configure HB
  self.mobileSession.sendHeartbeatToSDL = false -- does not send HB here, will send by script below
  self.mobileSession.answerHeartBeatFromSDL = false -- does not answer HB from SDL
  self.mobileSession.ignoreSDLHeartBeatACK = false -- does not ignore HB ACK from SDL
  self.mobileSession:StartRPC()
  :Do(function()
    const.default_app.majorVersion = 3
    local cid = self.mobileSession:SendRPC("RegisterAppInterface", const.default_app)
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
    :Do(function(_, data)
      self.hmi_app_id = data.params.application.appID
    end)
    self.mobileSession:ExpectResponse(cid, {success = true, resultCode = "SUCCESS"})
    :Do(function()
      -- Send HB message
      self.mobileSession.correlationId = self.mobileSession.correlationId + 1
      local msg = {
        serviceType = 0,
        frameInfo = 0,
        frameType = 0,
        sessionId = 1,
        rpcCorrelationId = self.mobileSession.correlationId
      }
      self.mobileSession:Send(msg)
    end)
    self.mobileSession:ExpectNotification("OnHMIStatus", {
      systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
  end)
end

function Test:Wait_15_Seconds_To_Verify_App_Is_Unregister()
  common_functions:UserPrint(const.color.green, "Please wait in 15 seconds!")
  common_functions:DelayedExp(15000)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {
    appID = self.hmi_app_id, unexpectedDisconnect = true})
  local event = events.Event()
  event.matches = function(_, data)
    return data.frameType == 0 and
      data.sessionId == self.mobileSession.sessionId and
      data.frameInfo == 4
  end
  self.mobileSession:ExpectEvent(event, "EndService")
end

-----------------------------------Postcondition-------------------------------
common_steps:AddNewTestCasesGroup("Postconditions")
common_steps:RestoreIniFile("Postcondition_Restore_Ini_File", "smartDeviceLink.ini")
common_steps:StopSDL("Postcondition_StopSDL")
