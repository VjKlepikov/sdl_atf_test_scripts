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
local Expected = 1
local NotExpected = 0
local AppId1 = 1

local function SubscribeWayPointsIgnored()
  local cid = common.getMobileSession():SendRPC("SubscribeWayPoints",{})
  common.getMobileSession():ExpectResponse(cid, {success = false , resultCode = "IGNORED" })
end

--[[ Scenario ]]
for i = 1, 1 do
  runner.Title("Preconditions")
  runner.Step("Clean environment", common.preconditions)
  runner.Step("Update preloaded_pt", common.updatePreloadedPT)
  runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  runner.Step("App registration", common.registerApp)
  runner.Step("Activate App", common.activateApp)

  runner.Title("Test" ..i)
  runner.Step("SubscribeWayPoints, UnexpectedDisconnect", common.SubscribeWayPointsUnexpectedDisconnect)
  runner.Step("Connect mobile", common.connectMobile)
  runner.Step("App registration after disconnect without SubscribeWayPoints ",
    common.registerAppSubscribeWayPoints, { AppId1, NotExpected })
  runner.Step("Activate App", common.activateApp)
  runner.Step("Does not send OnWayPointChange to App", common.OnWayPointChange, { NotExpected, AppId1 })

  runner.Step("SubscribeWayPoints", common.SubscribeWayPoints)
  runner.Step("Sends OnWayPointChange", common.OnWayPointChange, { Expected, AppId1 })

  runner.Step("UnsubscribeWayPoints, UnexpectedDisconnect", common.UnsubscribeWayPointsPointsUnexpectedDisconnect)
  runner.Step("Connect mobile", common.connectMobile)
  runner.Step("App registration after disconnect without SubscribeWayPoints",
    common.registerAppSubscribeWayPoints, { AppId1, Expected })
  runner.Step("Activate App", common.activateApp)
  runner.Step("Send OnWayPointChange", common.OnWayPointChange, { Expected })

  runner.Step("SubscribeWayPoints", SubscribeWayPointsIgnored)
  runner.Step("Sends OnWayPointChange to App", common.OnWayPointChange, { Expected })
  runner.Step("UnsubscribeWayPoints", common.UnsubscribeWayPoints)
  runner.Step("Does not send OnWayPointChange to App", common.OnWayPointChange, { NotExpected } )


  runner.Title("Postconditions")
  runner.Step("Clean sessions", common.cleanSessions)
  runner.Step("Stop SDL", common.postconditions)
end
