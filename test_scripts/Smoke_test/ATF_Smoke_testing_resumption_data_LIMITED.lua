---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-15683]: [Data Resumption]: SDL data resumption SUCCESS sequence
-- [APPLINK-15586]: [HMILevel Resumption]: Both LIMITED and FULL applications must be included to resumption list

-- Description:
-- Transport unexpected disconnect. Media app resume at LIMITED level and resume data

-- Preconditions:
-- App is registered and activated

-- Steps:
-- 1. Add 1 sub menu, 1 command and 1 choice set.
-- 2. Bring app to LIMITED
-- 3. Turn off and turn on mobile device
-- 4. Register app with hashID

-- Expected result:
-- 4. App is registered successfully, SDL resumes data (1 sub menu, 1 command and 1 choiceset) and sends OnResumeAudioSource to HMI. App gets LIMITED HMI Level.
---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')

--[[ Local variables]]
local mobile_session = "mobileSession"
local app = common_functions:CreateRegisterAppParameters(
  {isMediaApplication = true, appHMIType = {"MEDIA"}, appID = "1", appName = "Application"})

--[[ Preconditions ]]
common_steps:AddNewTestCasesGroup("Preconditions")
common_functions:DeleteLogsFileAndPolicyTable()
common_steps:PreconditionSteps("Precondition", const.precondition.CONNECT_MOBILE)
common_steps:AddMobileSession("Precondition_Add_Mobile_Session")
common_steps:RegisterApplication("Precondition_Register_Application", "mobileSession", app)
common_steps:ActivateApplication("Precondition_Activate_Application", app.appName)

--[[ Test ]]
common_steps:AddNewTestCasesGroup("Tests")
function Test:AddSubMenu()
  local cid = self.mobileSession:SendRPC("AddSubMenu",
    {
      menuID = 1,
      position = 500,
      menuName = "SubMenupositive1"
    })
  EXPECT_HMICALL("UI.AddSubMenu",
    {
      menuID = 1,
      menuParams = {
        position = 500,
        menuName = "SubMenupositive1"
      }
    })
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  :Do(function()
      EXPECT_NOTIFICATION("OnHashChange")
      :Do(function(_, data)
          self.currentHashID = data.payload.hashID
        end)
    end)
end

function Test:AddCommand()
  local cid = self.mobileSession:SendRPC("AddCommand",
    {
      cmdID = 1,
      menuParams =
      {
        position = 0,
        menuName ="Command1"
      },
      vrCommands = {"VRCommand1"}
    })
  EXPECT_HMICALL("UI.AddCommand",
    {
      cmdID = 1,
      menuParams =
      {
        position = 0,
        menuName ="Command1"
      }
    })
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)

  EXPECT_HMICALL("VR.AddCommand",
    {
      cmdID = 1,
      type = "Command",
      vrCommands =
      {
        "VRCommand1"
      }
    })
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  :Do(function()
      EXPECT_NOTIFICATION("OnHashChange")
      :Do(function(_, data)
          self.currentHashID = data.payload.hashID
        end)
    end)
end

function Test:CreateInteractionChoiceSet()
  local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
    {
      interactionChoiceSetID = 1,
      choiceSet =
      {

        {
          choiceID = 1,
          menuName = "Choice1",
          vrCommands =
          {
            "VrChoice1",
          }
        }
      }
    })
  EXPECT_HMICALL("VR.AddCommand",
    {
      cmdID = 1,
      appID = self.applications[config.application1.registerAppInterfaceParams.appName],
      type = "Choice",
      vrCommands = {"VrChoice1"}
    })
  :Do(function(_,data)
      grammarIDValue = data.params.grammarID
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  :Do(function()
      EXPECT_NOTIFICATION("OnHashChange")
      :Do(function(_, data)
          self.currentHashID = data.payload.hashID
        end)
    end)
end

common_steps:ChangeHMIToLimited("Change_app_to_Limited", app.appName)
common_steps:CloseMobileSession("Turn_off_Transport", "mobileSession")
common_steps:AddMobileSession("Turn_on_Transport")

function Test:ResumeApp()
  common_functions:StoreApplicationData(mobile_session, app.appName, app, _, self)
  local application_resuming_timeout = tonumber(common_functions:GetValueFromIniFile("ApplicationResumingTimeout"))
  local resumption_max_wait_time = 500
  app.hashID = self.currentHashID
  local correlation_id = self.mobileSession:SendRPC("RegisterAppInterface", app)
  local time = timestamp()

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
  :Do(function(_,data)
      common_functions:StoreHmiAppId(app.appName, data.params.application.appID, self)
    end)
  self.mobileSession:ExpectResponse(correlation_id, { success = true })

  local hmi_appid = common_functions:GetHmiAppId(app.appName, self)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = hmi_appid})
  EXPECT_NOTIFICATION("OnHMIStatus",
    {hmiLevel = "NONE", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"},
    {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"} )
  :ValidIf(function(exp,data)
      if exp.occurences == 2 then
        local timeAtResume = timestamp()
        local timeToresumption = timeAtResume - time
        if timeToresumption >= application_resuming_timeout and
        timeToresumption < application_resuming_timeout + resumption_max_wait_time then
          common_functions:UserPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~ " .. application_resuming_timeout )
          return true
        else
          common_functions:UserPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~ " .. application_resuming_timeout )
          return false
        end
      elseif exp.occurences == 1 then
        return true
      end
    end)
  :Times(2)
  EXPECT_HMICALL("UI.AddSubMenu",
    {
      menuID = 1,
      menuParams = {
        position = 500,
        menuName = "SubMenupositive1"
      }
    })
  EXPECT_HMICALL("UI.AddCommand",
    {
      cmdID = 1,
      menuParams =
      {
        position = 0,
        menuName ="Command1"
      }
    })
  EXPECT_HMICALL("VR.AddCommand",
    {
      cmdID = 1,
      type = "Choice",
      vrCommands = {"VrChoice1"}
    })
end

--[[ Postconditions ]]
common_steps:AddNewTestCasesGroup("Postconditions")
common_steps:UnregisterApp("Postcondition_Unregister_App", app.appName )
common_steps:CloseMobileSession("Postcondition_Close_Mobile_Session", mobile_session)
common_steps:StopSDL("Postcondition_StopSDL")
