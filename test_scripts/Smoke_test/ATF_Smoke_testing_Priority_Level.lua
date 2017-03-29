---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-23000]: [Policies] "app id" policies assigned to the application and "priority" value

-- Description:
-- SDL assigns Priority level from appropriate appID OnAppRegistered and ActivateApp

-- Preconditions:
-- 1. In the LPT: appId = 0000001 has priority = NORMAL

-- Steps:
-- 1. Register app (Id = 0000001)
-- 2. Activate app from HMI

-- Expected result:
-- 1. SDL --> HMI: OnAppRegistered(priority: NORMAL)
-- SDL --> HMI: RegisterAppInterface(SUCCESS, resultCode: success)
-- 2. SDL --> HMI: BasicCommunication.ActivateApp(priority: NORMAL)
---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')

--[[ Local variables]]
local app = common_functions:CreateRegisterAppParameters(
  {appID = "0000001", appName = "Application1", isMediaApplication = true, appHMIType = {"MEDIA"}}
)

--[[ Preconditions ]]
common_steps:AddNewTestCasesGroup("Preconditions")
function Test:Preconditions_Update_LPT()
  local path = config.pathToSDL .. 'sdl_preloaded_pt.json'
  local parent_item = {"policy_table", "app_policies"}
  local added_json_items = {}
  added_json_items["0000001"] = {
    keep_context = false,
    steal_focus = false,
    priority = "NORMAL",
    default_hmi = "NONE",
    groups = {
      "Base-4"
    }
  }

  common_functions:AddItemsIntoJsonFile(path, parent_item, added_json_items)
end

common_steps:PreconditionSteps("Preconditions", const.precondition.ADD_MOBILE_SESSION)

--[[ Test ]]
common_steps:AddNewTestCasesGroup("Tests")
function Test:Register_App()
  local cid = self.mobileSession:SendRPC("RegisterAppInterface", app)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = {appName = app.appName}, priority = "NORMAL"})
  :Do(function(_,data)
      self.appID = data.params.application.appID
    end)
  EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
  EXPECT_NOTIFICATION("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
end

function Test:Activate_App()
  local cid = self.hmiConnection:SendRequest("SDL.ActivateApp", {appID = self.appID})
  EXPECT_HMIRESPONSE(cid)
  :Do(function(_,data)
      if
      data.result.isSDLAllowed ~= true then
        local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
        EXPECT_HMIRESPONSE(RequestId)
        :Do(function(_,data)
            self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device =
                {id = config.deviceMAC, name = "127.0.0.1"}})
            EXPECT_HMICALL("BasicCommunication.ActivateApp", {priority = "NORMAL"})
            :Do(function(_,data)
                self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS")
              end)
          end)
      end
    end)
  EXPECT_NOTIFICATION("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"})
end

--[[ Postconditions ]]
common_steps:AddNewTestCasesGroup("Postconditions")
common_steps:StopSDL("Postconditions_Stop_SDL")
