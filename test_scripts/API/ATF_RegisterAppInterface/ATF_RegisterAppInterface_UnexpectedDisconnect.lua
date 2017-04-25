-- Requirements: [APPLINK-21897]: SDL behavior in case subscribed app unexpectedly disconnects.

-- Description:
-- In case mobile app subscribed on wayPoints related parameters and then unexpectedly disconnects
-- SDL must: store the status of subscription on wayPoints related data for this app and send
-- UnsubscribeWayPoints request to HMI ONLY, restore status of subscription on wayPoints related
-- data for this app right after the same mobile app re-connects within the same ignition cycle
-- with the same <hashID> being before unexpected disconnect.

-- Preconditions:
-- 1. Backup sdl_preloaded_pt.json
-- 2. Add SubscribeWayPoints() and UnSubscribeWayPoints() rpcs to sdl_preloaded_pt.json
-- 3. App is registered and activated

-- Steps:
-- 1. Mob -> SDL: SubscribeWayPoints()
-- 2. Unexpected disconnect: SDL -> HMI: CloseMobileSession and UnsibscribeWayPoints
-- 3. Mob -> SDL: register App

-- Postconditions:
-- 1. Restore sdl_preloaded_pt.json
-- 2. Stop SDL

-- Expected result:
-- SDL -> Mob: register app after unexpected disconnect {success = true, resultCode = "SUCCESS"}

-- -----------------------------------------------------------------------------------------
require('user_modules/all_common_modules')
---------------------------------------------------------------------------------------------
--[[ Preconditions ]]
common_functions:BackupFile("sdl_preloaded_pt.json")
local added_json_items =
{
  SubscribeWayPoints =
  {
    hmi_levels =
    {
      "BACKGROUND",
      "FULL",
      "LIMITED",
      "NONE"
    }
  },
  UnSubscribeWayPoints =
  {
    hmi_levels =
    {
      "BACKGROUND",
      "FULL",
      "LIMITED",
      "NONE"
    }
  }
}
local json_file = config.pathToSDL .. "sdl_preloaded_pt.json"
common_functions:AddItemsIntoJsonFile(json_file, {"policy_table", "functional_groupings", "Base-4", "rpcs"}, added_json_items)
common_steps:PreconditionSteps("Preconditions", 7)

---------------------------------------------------------------------------------------------
--[[ Test ]]
function Test:SubscribeWayPoints()
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints",{})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
    end)
  EXPECT_RESPONSE(CorIdSWP, {success = true , resultCode = "SUCCESS"})
  EXPECT_NOTIFICATION("OnHashChange")
end

function Test:CloseMobileSessionAndUnsubscribeWayPoints()
  local mobile_session_name = "mobileSession"
  local app_name = common_functions:GetApplicationName(mobile_session_name, self)
  common_steps:CloseMobileSession_InternalUsed(app_name, self)
  EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
end

common_steps:AddMobileConnection("AddMobileConnection")
common_steps:AddMobileSession("AddMobileSession")

function Test:RegisterApplication()
  local mobile_session_name = "mobileSession"
  local application_parameters = config.application1.registerAppInterfaceParams
  local app_name = application_parameters.appName
  common_functions:StoreApplicationData(mobile_session_name, app_name, application_parameters, _, self)
  local CorIdRAI = self[mobile_session_name]:SendRPC("RegisterAppInterface", application_parameters)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = {appName = app_name}})
  :Do(function(_,data)
      common_functions:StoreHmiAppId(app_name, data.params.application.appID, self)
    end)
  local expected_response = {success = true, resultCode = "SUCCESS"}
  self[mobile_session_name]:ExpectResponse(CorIdRAI, expected_response)
  local expected_on_hmi_status = {audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
  self[mobile_session_name]:ExpectNotification("OnHMIStatus", expected_on_hmi_status)
  :ValidIf(function(exp, data)
      if exp.occurences == 1 and data.payload.hmiLevel ~= "NONE" then
        return false
      elseif exp.occurences == 2 and data.payload.hmiLevel ~= "FULL" then
        return false
      end
    end)
  :Times(2)
  :Timeout(4000)
end
-------------------------------------------------------------------------------------------
-- [[ Postconditions ]]
function Test:RestoreFile()
  common_functions:RestoreFile("sdl_preloaded_pt.json", 1)
end
common_steps:StopSDL("StopSDL")
