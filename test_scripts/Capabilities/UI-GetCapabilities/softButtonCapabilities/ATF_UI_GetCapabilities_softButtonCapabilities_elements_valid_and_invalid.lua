---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-19635]: SDL must use the default values in case HMI does not provide values

-- Description:
-- SDL will use default capabilities stored at hmi_capabilities.json file when value softButtonCapabilities.longPressAvailable is invalid

-- Preconditions:
-- 1. HMI -> SDL: invalid value of softButtonCapabilities.longPressAvailable in UI.GetCapabilities

-- Steps:
-- 1. Register App

-- Expected result:
-- SDL -> Mob: value softButtonCapabilities.longPressAvailable from hmi_capabilities.json file
---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')

--[[ Local variables]]
local functions_UIGetCapabilities = require('test_scripts/Capabilities/UI-GetCapabilities/common_functions_for_UI_GetCapabilities')
local softButtonCapabilities = common_functions:GetItemsFromJsonFile(config.pathToSDL .. "hmi_capabilities.json", {"UI", "softButtonCapabilities"})

--[[ Preconditions ]]
common_steps:AddNewTestCasesGroup("Preconditions")
common_steps:PreconditionSteps("Preconditions", const.precondition.INIT_HMI)
function Test:Preconditions_InitHMI_OnReady()
  functions_UIGetCapabilities:InitHMI_onReady_without_UI_GetCapabilities(self)
  local send_softButtonCapabilities =
  {{
      shortPressAvailable = false,
      longPressAvailable = "true",
      upDownAvailable = true,
      imageSupported = true
    },
    {
      shortPressAvailable = false,
      longPressAvailable = true,
      upDownAvailable = true,
      imageSupported = true
    },
    {
  }}

  EXPECT_HMICALL("UI.GetCapabilities")
  :Do(function(_,data)
      send_hmi_capabilities.softButtonCapabilities = send_softButtonCapabilities
      self.hmiConnection:SendResponse(data.id, "UI.GetCapabilities", "SUCCESS", send_hmi_capabilities)
    end)
end

common_steps:AddMobileConnection("Preconditions_Add_Mobile_Connection")
common_steps:AddMobileSession("Preconditions_Add_Mobile_Session")

--[[ Test ]]
common_steps:AddNewTestCasesGroup("Tests")
function Test:Register_App()
  local cid = self.mobileSession:SendRPC("RegisterAppInterface", const.default_app)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = {appName = const.default_app_name}})
  EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", softButtonCapabilities =
      {{
          shortPressAvailable = false,
          longPressAvailable = softButtonCapabilities[1].longPressAvailable,
          upDownAvailable = true,
          imageSupported = true
        },
        {
          shortPressAvailable = false,
          longPressAvailable = true,
          upDownAvailable = true,
          imageSupported = true
        },
        {
          shortPressAvailable = softButtonCapabilities[1].shortPressAvailable,
          longPressAvailable = softButtonCapabilities[1].longPressAvailable,
          upDownAvailable = softButtonCapabilities[1].upDownAvailable,
          imageSupported = softButtonCapabilities[1].imageSupported
        }
    }})
  EXPECT_NOTIFICATION("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
end

--[[ Postconditions ]]
common_steps:AddNewTestCasesGroup("Postconditions")
common_steps:StopSDL("Postconditions_Stop_SDL")