---------------------------------------------------------------------------------------------------
-- User story:
--
-- Description:
--
-- Steps:
--
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects_WayPoint/commonDefects')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }

--[[ Local Variables ]]
local ApplicationResumingTimeout

--[[ Local Functions ]]
local function updateIniFile()
  ApplicationResumingTimeout = commonFunctions:read_parameter_from_smart_device_link_ini("ApplicationResumingTimeout")
  commonFunctions:write_parameter_to_smart_device_link_ini("ApplicationResumingTimeout", 5000)
end

local function restoreValuestIniFile()
  commonFunctions:write_parameter_to_smart_device_link_ini("ApplicationResumingTimeout", ApplicationResumingTimeout)
end
--[[ Local Functions ]]
local function SubscribeWayPoints()
  local cid = common.getMobileSession():SendRPC("SubscribeWayPoints",{})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
  :Do(function(_,data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",{})
    end)
  common.getMobileSession():ExpectResponse(cid, {success = true , resultCode = "SUCCESS"})
  common.getMobileSession():ExpectNotification("OnHashChange")
  :Do(function(_,data)
      common.getConfigAppParams().hashID = data.payload.hashID
    end)
end

local function UnsubscribeWayPoints()
  local cid = common.getMobileSession():SendRPC("UnsubscribeWayPoints",{})
  EXPECT_HMICALL("Navigation.UnsubscribeWayPoints"):Times(AtMost(1))
  :Do(function(_,data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",{})
    end)
  common.getMobileSession():ExpectResponse(cid, {success = true , resultCode = "SUCCESS"})
  common.getMobileSession():ExpectNotification("OnHashChange")
  :Do(function(_,data)
      common.getConfigAppParams().hashID = data.payload.hashID
    end)
end


--[[ Scenario ]]

--runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update ini file ApplicationResumingTimeout=5000", updateIniFile)
runner.Step("Update preloaded_pt", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("Activate App", common.activateApp)

for i = 1, 100 do
runner.Title("Test" ..i)
runner.Step("SubscribeWayPoints, close session", common.SubscribeWayPointsUnexpectedDisconnect2)
runner.Step("Connect mobile", common.connectMobile)
runner.Step("App registration after disconnect", common.registerApp)
runner.Step("Activate App", common.activateApp)
-- runner.Step("SubscribeWayPoints", SubscribeWayPoints)
-- runner.Step("UnsubscribeWayPoints, close session", common.UnsubscribeWayPointsPointsUnexpectedDisconnect)
-- runner.Step("Connect mobile", common.connectMobile)
-- runner.Step("App registration after disconnect", common.registerApp)
-- runner.Step("Activate App", common.activateApp)
-- runner.Step("UnsubscribeWayPoints", UnsubscribeWayPoints)
end

runner.Title("Postconditions")
runner.Step("Restore values in ini file", restoreValuestIniFile)
runner.Step("Clean sessions", common.cleanSessions)
runner.Step("Stop SDL", common.postconditions)

