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

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }

--[[ Local Variables ]]
local Expected = 1
local NotExpected = 0

local function SubscribeWayPointsGENERIC_ERROR()
  local cid = common.getMobileSession():SendRPC("SubscribeWayPoints",{})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
  common.getMobileSession():ExpectResponse(cid, {success = false , resultCode = "GENERIC_ERROR" })
end

local function UnsubscribeWayPointsGENERIC_ERROR()
  local cid = common.getMobileSession():SendRPC("UnsubscribeWayPoints",{})
  EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
  common.getMobileSession():ExpectResponse(cid, {success = false , resultCode = "GENERIC_ERROR" })
end

--[[ Scenario ]]

runner.Title("Test")
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update preloaded_pt", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("Activate App", common.activateApp)

for i = 1, common.iterator do
  runner.Title("Test" ..i)
  runner.Step("SubscribeWayPoints", SubscribeWayPointsGENERIC_ERROR)
  runner.Step("Does not send OnWayPointChange", common.OnWayPointChange, { NotExpected })
  runner.Step("SubscribeWayPoints", common.SubscribeWayPoints)
  runner.Step("Sends OnWayPointChange", common.OnWayPointChange, { Expected })
  runner.Step("UnsubscribeWayPoints", UnsubscribeWayPointsGENERIC_ERROR)
  runner.Step("Sends OnWayPointChange", common.OnWayPointChange, { Expected })
  runner.Step("UnsubscribeWayPoints", common.UnsubscribeWayPoints)
  runner.Step("Does not send OnWayPointChange", common.OnWayPointChange, { NotExpected })
end

runner.Title("Postconditions")
runner.Step("Clean sessions", common.cleanSessions)
runner.Step("Stop SDL", common.postconditions)

