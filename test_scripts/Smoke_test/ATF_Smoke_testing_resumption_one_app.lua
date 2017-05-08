-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

------------------------------------ Common Variables ---------------------------------------
local mobile_session = "mobileSession"
local app = common_functions:CreateRegisterAppParameters(
  {isMediaApplication = true, appHMIType = {"MEDIA"}, appID = "1", appName = "Application"})

------------------------------------ Common Functions ---------------------------------------
local function RegisterAndResumeApp(self, hmi_level, app)
  common_functions:StoreApplicationData(mobile_session, app.appName, app, _, self)
  local correlation_id = self.mobileSession:SendRPC("RegisterAppInterface", app)
  local time = timestamp()

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
  :Do(function(_,data)
      common_functions:StoreHmiAppId(app.appName, data.params.application.appID, self)
    end)
  self.mobileSession:ExpectResponse(correlation_id, { success = true })

  local hmi_appid = common_functions:GetHmiAppId(app.appName, self)
  if hmi_level == "FULL" then
    EXPECT_HMICALL("BasicCommunication.ActivateApp", {appID = hmi_appid})
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
      end)
  else
    EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = hmi_appid})
  end

  EXPECT_NOTIFICATION("OnHMIStatus",
    {hmiLevel = "NONE", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"},
    {hmiLevel = hmi_level, systemContext = "MAIN", audioStreamingState = "AUDIBLE"} )
  :ValidIf(function(exp,data)
      if exp.occurences == 2 then
        local time2 = timestamp()
        local timeToresumption = time2 - time
        if timeToresumption >= 3000 and
        timeToresumption < 3500 then
          common_functions:UserPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
          return true
        else
          common_functions:UserPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
          return false
        end
      elseif exp.occurences == 1 then
        return true
      end
    end)
  :Do(function(_,data)
      self.hmiLevel = data.payload.hmiLevel
    end)
  :Times(2)
end

local function RegisterAndNoResumeApp(self, app)
  common_functions:StoreApplicationData(mobile_session, app.appName, app, _, self)
  local correlation_id = self.mobileSession:SendRPC("RegisterAppInterface", app)
  local time = timestamp()

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
  :Do(function(_,data)
      common_functions:StoreHmiAppId(app.appName, data.params.application.appID, self)
    end)
  self.mobileSession:ExpectResponse(correlation_id, { success = true })

  EXPECT_HMICALL("BasicCommunication.ActivateApp")
  :Times(0)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource")
  :Times(0)
  EXPECT_HMICALL("BasicCommunication.UpdateAppList")
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, "BasicCommunication.UpdateAppList", "SUCCESS", {})
    end)
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
end

-------------------------------------------Preconditions-------------------------------------
common_functions:DeleteLogsFileAndPolicyTable()

-----------------------------------------------Body------------------------------------------
-- Case 1: No resumption if App unregister itself
common_steps:AddNewTestCasesGroup("No resumption if App unregister itself")
common_steps:PreconditionSteps("Case_1_Precondition", const.precondition.ACTIVATE_APP)
common_steps:UnregisterApp("Case_1_Unregister_App", config.application1.registerAppInterfaceParams.appName )
Test["Case_1_Register_And_Check_App_not_resume"] = function(self)
  RegisterAndNoResumeApp(self, config.application1.registerAppInterfaceParams)
end
common_steps:UnregisterApp("Case_1_Postcondition_Unregister_App", config.application1.registerAppInterfaceParams.appName )
common_steps:CloseMobileSession("Case_1_Postcondition_Close_Mobile_Session", mobile_session)
common_steps:StopSDL("Case_1_Postcondition_StopSDL")

-- Case 2: Transport disconnect <30s before IGNITION_OFF. Media app resume at FULL level
common_steps:AddNewTestCasesGroup("Transport disconnect <30s before IGNITION_OFF. Media app resume at FULL level")
common_steps:PreconditionSteps("Case_2_Precondition", const.precondition.CONNECT_MOBILE)
common_steps:AddMobileSession("Case_2_Add_Mobile_Session")
common_steps:RegisterApplication("Case_2_Register_Application", mobile_session, app)
common_steps:ActivateApplication("Case_2_Activate_Application", app.appName)
common_steps:CloseMobileSession("Case_2_Turn_off_Transport", mobile_session)
common_steps:Sleep("Case_2_Sleep_29s", 29)
Test["Case_2_Ignition_off"] = function (self)
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {reason = "IGNITION_OFF"})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = false})
  StopSDL()
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")
end
common_steps:IgnitionOn("Case_2_Ignition_on")
common_steps:AddMobileSession("Case_2_Add_Mobile_Session")
Test["Case_2_Register_And_Resume_App_FULL"] = function(self)
  RegisterAndResumeApp(self, "FULL", app)
end
common_steps:UnregisterApp("Case_2_Postcondition_Unregister_App", app.appName )
common_steps:CloseMobileSession("Case_2_Postcondition_Close_Mobile_Session", mobile_session)
common_steps:StopSDL("Case_2_Postcondition_StopSDL")

-- Case 3: Transport disconnect <30s before IGNITION_OFF. Media app resume at LIMITED level
common_steps:AddNewTestCasesGroup("Transport disconnect <30s before IGNITION_OFF. Media app resume at LIMITED level")
common_steps:PreconditionSteps("Case_3_Precondition", const.precondition.CONNECT_MOBILE)
common_steps:AddMobileSession("Case_3_Add_Mobile_Session")
common_steps:RegisterApplication("Case_3_Register_Application", mobile_session, app)
common_steps:ActivateApplication("Case_3_Activate_Application", app.appName)
common_steps:ChangeHMIToLimited("Case_3_Change_app_to_Limited", app.appName)
common_steps:CloseMobileSession("Case_3_Turn_off_Transport", mobile_session)
common_steps:Sleep("Case_3_Sleep_29s", 29)
Test["Case_3_Ignition_off"] = function (self)
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {reason = "IGNITION_OFF"})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = false})
  StopSDL()
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")
end
common_steps:IgnitionOn("Case_3_Ignition_on")
common_steps:AddMobileSession("Case_3_Add_Mobile_Session")
Test["Case_3_Register_And_Resume_App_LIMITED"] = function(self)
  RegisterAndResumeApp(self, "LIMITED", app)
end
common_steps:UnregisterApp("Case_3_Postcondition_Unregister_App", app.appName )
common_steps:CloseMobileSession("Case_3_Postcondition_Close_Mobile_Session", mobile_session)
common_steps:StopSDL("Case_3_Postcondition_StopSDL")

-- Case 4: Transport disconnect >30s before IGNITION_OFF. Media app not resume
common_steps:AddNewTestCasesGroup("Transport disconnect >30s before IGNITION_OFF. Media app not resume")
common_steps:PreconditionSteps("Case_4_Precondition", const.precondition.CONNECT_MOBILE)
common_steps:AddMobileSession("Case_4_Add_Mobile_Session")
common_steps:RegisterApplication("Case_4_Register_Application", mobile_session, app)
common_steps:ActivateApplication("Case_4_Activate_Application", app.appName)
common_steps:CloseMobileSession("Case_4_Turn_off_Transport", mobile_session)
common_steps:Sleep("Case_4_Sleep_31s", 31)
Test["Case_4_Ignition_off"] = function (self)
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {reason = "IGNITION_OFF"})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = false})
  StopSDL()
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")
end
common_steps:IgnitionOn("Case_4_Ignition_on")
common_steps:AddMobileSession("Case_4_Add_Mobile_Session")
Test["Case_4_Register_And_Check_App_not_resume"] = function(self)
  RegisterAndNoResumeApp(self, app)
end
common_steps:UnregisterApp("Case_4_Postcondition_Unregister_App", app.appName )
common_steps:CloseMobileSession("Case_4_Postcondition_Close_Mobile_Session", mobile_session)
common_steps:StopSDL("Case_4_Postcondition_StopSDL")
