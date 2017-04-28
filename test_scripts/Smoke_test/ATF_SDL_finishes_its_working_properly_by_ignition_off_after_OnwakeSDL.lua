---------------------------------------------------------------------------------------------
-- Requirement summary: APPLINK-15702 APPLINK-19742
-- [APPLINK-15702]: [Data Resumption]:OnExitAllApplications(SUSPEND) in terms of resumption
-- [APPLINK-19742]: [Unexpected Disconnect]: 9. "unexpectedDisconnect:false" in case of ignition off

-- Description:
-- SDL finishes its working properly by IGNITION_OFF after OnAwakeSDL

-- Preconditions:
-- 1. SDL and HMI are running on system.
-- 2. One App is registered and activated on HMI.
-- 3. App has added 1 sub menu, 1 command and 1 choice set.

-- Steps:
-- 1. HMI --> SDL: OnExitAllApplication (SUSPEND)
-- 2. HMI --> SDL: Sends OnAwakeSDL()
-- 3. HMI --> SDL: OnExitAllApplication (IGNITION_OFF)
-- Expected results:
-- 1. SDL stores resumption data then sends OnSDLPersistenceComplete() to HMI
-- 3.SDL sends OnAppUnregistered() to HMI
-- -- SDL sends to HMI OnSDLClose and stops working.
-- -- SDL sends to mobile OnAppInterfaceUnregistered (IGNITION_OFF)

---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')

--[[ Local variables]]
local mobile_session = "mobileSession"
local app = common_functions:CreateRegisterAppParameters(
  {isMediaApplication = true, appHMIType = {"MEDIA"}, appID = "1", appName = "Application"})

--[[ Preconditions ]]
common_steps:AddNewTestCasesGroup("Preconditions")
common_functions:DeleteLogsFileAndPolicyTable()
common_steps:PreconditionSteps("Precondition",const.precondition.ACTIVATE_APP)

function Test:Precondition_AddSubMenu()
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

function Test:Precondition_AddCommand()
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
  EXPECT_NOTIFICATION("OnHashChange")
  :Do(function(_, data)
      self.currentHashID = data.payload.hashID
    end)
end

function Test:Precondition_CreateInteractionChoiceSet()
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
  :Do(function(_,data)
      EXPECT_NOTIFICATION("OnHashChange")
      :Do(function(_, data)
          self.currentHashID = data.payload.hashID
        end)
    end)
end

--[[ Test ]]
common_steps:AddNewTestCasesGroup("Tests")

function Test:OnExitAllApplication_SUSPEND()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {reason = "SUSPEND"})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
end

function Test:OnAwakeSDL()
  self.hmiConnection:SendNotification("BasicCommunication.OnAwakeSDL",{})
end

function Test:OnExitAllApplication_IGNITION_OFF()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",{reason = "IGNITION_OFF"})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
  EXPECT_NOTIFICATION("OnAppInterfaceUnregistered",{reason="IGNITION_OFF"})
end
