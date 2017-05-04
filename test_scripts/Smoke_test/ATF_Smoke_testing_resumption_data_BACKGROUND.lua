---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-15683]: [Data Resumption]: SDL data resumption SUCCESS sequence
-- [APPLINK-15586]: [HMILevel Resumption]: Both LIMITED and FULL applications must be included to resumption list

-- Description:
-- Transport unexpected disconnect. Media app not resume at BACKGROUND level but resume data

-- Preconditions:
-- There is app in BACKGROUND level

-- Steps:
-- 1. Add 1 sub menu, 1 command and 1 choice set.
-- 2. Turn off and turn on mobile device
-- 3. Resume app with hashID

-- Expected result:
-- 4. App is registered successfully, SDL resumes data (1 sub menu, 1 command and 1 choiceset) and sends OnResumeAudioSource to HMI. App gets NONE level (default HMI level)
---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')

--[[ Local variables]]
local app1 = common_functions:CreateRegisterAppParameters(
  {isMediaApplication = true, appHMIType = {"MEDIA"}, appID = "1", appName = "Application1"})
local app2 = common_functions:CreateRegisterAppParameters(
  {isMediaApplication = true, appHMIType = {"MEDIA"}, appID = "2", appName = "Application2"})

--[[ Preconditions ]]
common_steps:AddNewTestCasesGroup("Preconditions")
common_functions:DeleteLogsFileAndPolicyTable()
common_steps:PreconditionSteps("Precondition", const.precondition.CONNECT_MOBILE)
common_steps:AddMobileSession("Precondition_Add_Mobile_Session_1", _, "mobileSession")
common_steps:RegisterApplication("Precondition_Register_Application_1", "mobileSession", app1)
common_steps:ActivateApplication("Precondition_Activate_Application_1", app1.appName)
common_steps:AddMobileSession("Precondition_Add_Mobile_Session_2", _, "mobileSession2")
common_steps:RegisterApplication("Precondition_Register_Application_2", "mobileSession2", app2)
local hmi_status = {}
hmi_status[app1.appName] = {hmiLevel = "BACKGROUND", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"}
common_steps:ActivateApplication("Precondition_Activate_Application_2", app2.appName, _, hmi_status)
common_steps:UnregisterApp("Precondition_Unregister_App_2", app2.appName )
common_steps:CloseMobileSession("Precondition_Close_Mobile_Session_2", "mobileSession2")

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

common_steps:CloseMobileSession("Turn_off_Transport", "mobileSession")
common_steps:AddMobileSession("Turn_on_Transport")
function Test:ResumeData()
  common_functions:StoreApplicationData("mobileSession", app1.appName, app1, _, self)
  app1.hashID = self.currentHashID
  local correlation_id = self.mobileSession:SendRPC("RegisterAppInterface", app1)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
  :Do(function(_,data)
      common_functions:StoreHmiAppId(app1.appName, data.params.application.appID, self)
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
common_steps:UnregisterApp("Postcondition_Unregister_App", app1.appName )
common_steps:CloseMobileSession("Postcondition_Close_Mobile_Session", "mobileSession")
common_steps:StopSDL("Postcondition_StopSDL")
