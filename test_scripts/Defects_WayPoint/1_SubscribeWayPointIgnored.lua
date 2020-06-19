---------------------------------------------------------------------------------------------------
-- Description: Conditions for SDL to respond with IGNORED resultCode to mobile app
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

--[[ Local Functions ]]
local function SubscribeWayPointsIgnored()
  local cid = common.getMobileSession():SendRPC("SubscribeWayPoints",{})
  common.getMobileSession():ExpectResponse(cid, {success = false , resultCode = "IGNORED" })
end

local function UnsubscribeWayPointsIgnored()
  local cid = common.getMobileSession():SendRPC("UnsubscribeWayPoints",{})
  common.getMobileSession():ExpectResponse(cid, {success = false , resultCode = "IGNORED" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update preloaded_pt", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("UnsubscribeWayPoints IGNORED", UnsubscribeWayPointsIgnored)
runner.Step("Does not send OnWayPointChange to App", common.OnWayPointChange, { NotExpected })
runner.Step("SubscribeWayPoints", common.SubscribeWayPoints)
runner.Step("Sends OnWayPointChange to App", common.OnWayPointChange, { Expected })

for i = 1, 5 do
runner.Title("Test SubscribeWayPoints IGNORED " ..i)
runner.Step("SubscribeWayPoints IGNORED", SubscribeWayPointsIgnored)
runner.Step("Sends OnWayPointChange to App", common.OnWayPointChange, { Expected })
end

runner.Step("UnsubscribeWayPoints", common.UnsubscribeWayPoints)
runner.Step("Does not send OnWayPointChange to App", common.OnWayPointChange, { NotExpected })

for i = 6, 10 do
runner.Title("Test UnsubscribeWayPoints IGNORED " ..i)
runner.Step("UnsubscribeWayPoints IGNORED", UnsubscribeWayPointsIgnored)
runner.Step("OnWayPointChange", common.OnWayPointChange, { NotExpected })
end

runner.Title("Postconditions")
runner.Step("Clean sessions", common.cleanSessions)
runner.Step("Stop SDL", common.postconditions)

