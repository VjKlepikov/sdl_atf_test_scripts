---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-15600]: [HMILevel Resumption]: SDL Must send BC.ActivateApp to HMI for the app resumed to FULLs
-- [APPLINK-15602]: [HMILevel Resumption]: SDL Must send OnHMIStatus(FULL) to the app resumed to FULL
-- [APPLINK-15683]: [Data Resumption]: SDL Must follow data resumption SUCCESS sequence
-- [APPLINK-23742]: [HeartBeat] SDL Must start heartbeat only after first Heartbeat request from mobile app
-- [APPLINK-15224]: [Unexpected Disconnect]: SDL Must send BasicCommunication.OnAppUnregistered
--  with "unexpectedDisconnect:true" in case of HeartBeat timeout

-- Description:
-- After HeartBeat Timeout SDL Must perform Data and hmiLevel Resumption upon App reconnection

-- Preconditions:
-- 1. App is registered and activated
-- 2. App sends HeartBeat message once to start SDL's HeartBeat Timeout Timer.
-- 3. App ignores HeartBeat ACKs from SDL and does not send HeartBeat messages to SDL
-- 4. App adds 1 sub menu, 1 command and 1 choice set

-- Steps:
-- 1. Wait for HeartBeat Timeout and App Unregister
--  SDL -> HMI: Send Notification OnAppUnregistered, unexpectedDisconnect = true
-- 2. Restart Mobile Session
-- 3. Register App and check Data and hmiLevel Resumption

-- Expected result:
-- SDL -> HMI: BasicCommunication.OnAppRegistered
-- SDL -> Mob: RegisterAppInterface with success = true, resultCode = "SUCCESS"
-- SDL -> HMI: Send UI.AddCommand
-- SDL -> HMI: Send UI.AddSubMenu
-- SDL -> HMI: Send VR.AddCommand
-- SDL -> HMI: Send BasicCommunication.ActivateApp
-- SDL -> Mob: hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"
---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')

config.heartbeatTimeout = 7000
config.defaultProtocolVersion = 3
config.application1.registerAppInterfaceParams.majorVersion = 3
config.application1.registerAppInterfaceParams.minorVersion = 1
config.application1.registerAppInterfaceParams.isMediaApplication = true
config.application1.registerAppInterfaceParams.appHMIType = { "DEFAULT" }

---------------------------------------------------------------------------------------------
--[[ Preconditions ]]
common_steps:PreconditionSteps("Precondition", 4)

function Test:Precondition_StartSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession.version = 3
  self.mobileSession.sendHeartbeatToSDL = true
  self.mobileSession.answerHeartBeatFromSDL = true
  self.mobileSession.ignoreSDLHeartBeatACK = true
  self.mobileSession:StartService(7)
end

function Test:Precondition_RegisterApp()
  local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface",
    config.application1.registerAppInterfaceParams)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
  :Do(function(_, data)
    self.hmi_app_id = data.params.application.appID
  end)

  self.mobileSession:ExpectResponse(CorIdRegister, {
    success = true, resultCode = "SUCCESS"
  })
  :Do(function()
    self.mobileSession.correlationId = self.mobileSession.correlationId + 1
    -- Define HeartBeat message
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
    systemContext = "MAIN",
    hmiLevel = "NONE",
    audioStreamingState = "NOT_AUDIBLE"
  })
end

function Test:Precondition_ActivateApp()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp",
    { appID = self.hmi_app_id })

  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_, data)
    if( data.result.isSDLAllowed ~= true ) then
      self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {
        allowed = true,
        source = "GUI",
        device = {
          id = config.deviceMAC,
          name = "127.0.0.1"
        }
      })

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
      :Do(function(_, data1)
        self.hmiConnection:SendResponse(data1.id,
          "BasicCommunication.ActivateApp", "SUCCESS", {})
      end)

      self.mobileSession:ExpectNotification("OnHMIStatus", {
        hmiLevel = "FULL",
        audioStreamingState = "AUDIBLE",
        systemContext = "MAIN"
      })
    end
  end)
end

function Test:Precondition_AddCommand()
  self.icmdID = 1
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

function Test:Precondition_AddSubMenu()
  self.imenuID = 2
  local cid = self.mobileSession:SendRPC("AddSubMenu", {
    menuID = self.imenuID,
    position = 500,
    menuName = "SubMenupositive" .. tostring(self.imenuID)
  })

  EXPECT_HMICALL("UI.AddSubMenu", {
    menuID = self.imenuID,
    menuParams = {
      position = 500,
      menuName = "SubMenupositive" .. tostring(self.imenuID)
    }
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

function Test:Precondition_CreateInteractionChoiceSet()
  self.ichoiceID = 3
  local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet", {
    interactionChoiceSetID = self.ichoiceID,
    choiceSet = {
      {
        choiceID = self.ichoiceID,
        menuName = "Choice" .. tostring(self.ichoiceID),
        vrCommands = { "VrChoice" .. tostring(self.ichoiceID) }
      }
    }
  })

  EXPECT_HMICALL("VR.AddCommand", {
    cmdID = self.ichoiceID,
    appID = self.hmi_app_id,
    type = "Choice",
    vrCommands = { "VrChoice" .. tostring(self.ichoiceID) }
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
--[[ Test Data and hmiLevel Resumption after HeartBeat Timeout ]]
common_steps:AddNewTestCasesGroup("Test Data and hmiLevel Resumption after HeartBeat Timeout")

function Test:TestStep_Wait_HeartBeat_Timeout_and_App_Unregister()
  common_functions:DelayedExp(14000)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {
    appID = self.hmi_app_id,
    unexpectedDisconnect = true
  })
  local event = events.Event()
  event.matches = function(_, data)
    return data.frameType == 0 and
      data.sessionId == self.mobileSession.sessionId and
      data.frameInfo == 4
  end
  self.mobileSession:ExpectEvent(event, "EndService")
end

function Test:TestStep_RestartSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

function Test:TestStep_RegisterApp_and_check_Data_and_hmiLevel_Resumption()
  config.application1.registerAppInterfaceParams.hashID = self.currentHashID
  local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface",
    config.application1.registerAppInterfaceParams)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { resumeVrGrammars = true })

  self.mobileSession:ExpectResponse(CorIdRegister, {
    success = true, resultCode = "SUCCESS"
  })

  self.mobileSession:ExpectNotification("OnHMIStatus")
  :ValidIf(function(exp, data)
    if exp.occurences == 1 and
      data.payload.hmiLevel == "NONE" and
      data.payload.audioStreamingState == "NOT_AUDIBLE" and
      data.payload.systemContext == "MAIN" then
      return true
    elseif exp.occurences == 2 and
      self.appIsActive and
      data.payload.hmiLevel == "FULL" and
      data.payload.audioStreamingState == "AUDIBLE" and
      data.payload.systemContext == "MAIN" then
      return true
    else
      if exp.occurences == 1 then
        local expMessage = "Expected: " ..
          "{ hmiLevel = \"NONE\", audioStreamingState = \"NOT_AUDIBLE\", systemContext = \"MAIN\" }\n"
      elseif exp.occurences == 2 then
        local expMessage = "Expected: " ..
          "{ hmiLevel = \"FULL\", audioStreamingState = \"AUDIBLE\", systemContext = \"MAIN\" }\n"
      end
      common_functions:PrintError("OnHMIStartus parameters are not correct.\n" ..
        expMessage ..
        "Got: { hmiLevel = " .. data.payload.hmiLevel ..
        ", audioStreamingState = " .. data.payload.audioStreamingState ..
        ", systemContext = " .. data.payload.systemContext)
      return false
    end
  end)
  :Times(2)

  EXPECT_HMICALL("UI.AddCommand", {
    appID = self.hmi_app_id,
    cmdID = self.icmdID,
    menuParams = { menuName = "Play" .. tostring(self.icmdID) }
  })

  EXPECT_HMICALL("UI.AddSubMenu", {
    menuID = self.imenuID,
    menuParams = {
      position = 500,
      menuName = "SubMenupositive" .. tostring(self.imenuID)
    }
  })

  EXPECT_HMICALL("VR.AddCommand", {
    cmdID = self.ichoiceID,
    appID = self.hmi_app_id,
    type = "Choice",
    vrCommands = { "VrChoice" .. tostring(self.ichoiceID) }
  })

  EXPECT_HMICALL("BasicCommunication.ActivateApp")
  :Do(function(_, data)
    self.hmiConnection:SendResponse(data.id,
      "BasicCommunication.ActivateApp", "SUCCESS", {})
    self.appIsActive = true
  end)
end

---------------------------------------------------------------------------------------------
--[[ Postconditions ]]
common_steps:StopSDL("Postcondition_StopSDL")
