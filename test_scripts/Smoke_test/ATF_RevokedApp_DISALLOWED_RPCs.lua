---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-19829]: [RegisterAppInterface] Allow only RegisterAppInterface for the application with NULL policies.
-- [APPLINK-16253]: [GeneralResultCode] DISALLOWED. A request comes with appID which has "null" permissions in Policy Table.

-- Description:
-- In case PolicyTable has "<appID>": "null" in the Local PolicyTable for the specified application with appID
-- "policy_table":{
-- "app_policies":{
-- "123":null
-- }
--}
-- PoliciesManager must return DISALLOWED resultCode and success:"false" to any RPC requested by such <appID> app.

-- Preconditions:
--1. SDL and HMI are running
--2. App (appId=123: null) is registered

-- Steps:
-- 1. Mob -> SDL: Any_RPC_except_of_RegisterAppInterface (params)

-- Expected result:
-- SDL -> Mob: Any_RPC_except_of_RegisterAppInterface(DISALLOWED, success:"false")

---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')

---------------------------------------------------------------------------------------------
common_steps:AddNewTestCasesGroup("Preconditions")

-- An app is registered and activated
common_steps:PreconditionSteps("Preconditions", 7)
update_policy:updatePolicy("files/PTU_For_SmokeTesting.json", _, "PTU_With_RevokedApp")
local mobile_session_name = "mobilesession2"
common_steps:AddMobileSession("AddMobileSession_For_Revoked_App",_, mobile_session_name)
local app_revoked = common_functions:CreateRegisterAppParameters(
  {appID = "123", appName = "Revoked_app"})
common_steps:RegisterApplication("Register_Revoked_Application_AppId_123", mobile_session_name, app_revoked)

-- common_steps:AddNewTestCasesGroup("Test")
function Test:SetGlobalProperties_DISALLOWED()
  local cid = self[mobile_session_name]:SendRPC("SetGlobalProperties",
    {
      menuTitle = "Menu Title",
      timeoutPrompt =
      {
        {
          text = "Timeout prompt",
          type = "TEXT"
        }
      },
      vrHelp =
      {
        {
          position = 1,
          image =
          {
            value = "icon.png",
            imageType = "DYNAMIC"
          },
          text = "VR help item"
        }
      },
      menuIcon =
      {
        value = "icon.png",
        imageType = "DYNAMIC"
      },
      helpPrompt =
      {
        {
          text = "Help prompt",
          type = "TEXT"
        }
      },
      vrHelpTitle = "VR help title",
      keyboardProperties =
      {
        keyboardLayout = "QWERTY",
        keypressMode = "SINGLE_KEYPRESS",
        limitedCharacterList =
        {
          "a"
        },
        language = "EN-US",
        autoCompleteText = "Daemon, Freedom"
      }
    })
  self[mobile_session_name]:ExpectResponse(cid, { success = false, resultCode = "DISALLOWED"})
end

function Test:SetAppIcon_DISALLOWED()
  local cid = self[mobile_session_name]:SendRPC("SetAppIcon",{ syncFileName = "icon.png" })
  self[mobile_session_name]:ExpectResponse(cid, { success = false, resultCode = "DISALLOWED"})
end

function Test:ChangeRegistration_DISALLOWED()
  local request = {
    language ="EN-US",
    hmiDisplayLanguage ="EN-US",
    appName ="SyncProxyTester",
    ttsName =
    {
      {
        text ="SyncProxyTester",
        type ="TEXT"
      }
    },
    ngnMediaScreenAppName ="SPT",
    vrSynonyms =
    {
      "VRSyncProxyTester"
    }
  }
  local cid = self[mobile_session_name]:SendRPC("ChangeRegistration", request)
  self[mobile_session_name]:ExpectResponse(cid, { success = false, resultCode = "DISALLOWED"})
end

-----------------------------------Postcondition-------------------------------
common_steps:AddNewTestCasesGroup("Postconditions")
common_steps:StopSDL("Postcondition_StopSDL")
