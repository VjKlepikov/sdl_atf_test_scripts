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
local AppId1 = 1

--[[ Scenario ]]
for i = 1, common.iterator do
  runner.Title("Test" ..i)
  runner.Title("Preconditions")
  runner.Step("Clean environment", common.preconditions)
  runner.Step("Update preloaded_pt", common.updatePreloadedPT)
  runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  runner.Step("App registration", common.registerApp)
  runner.Step("Activate App", common.activateApp)

  runner.Title("Test" ..i)

  runner.Step("SubscribeWayPoints", common.SubscribeWayPoints)
  runner.Step("Sends OnWayPointChange", common.OnWayPointChange, { Expected })
  runner.Step("unexpectedDisconnect with UnsubscribeWayPoints",
    common.unexpectedDisconnectUnsubscribeWayPoints, { Expected })
  runner.Step("Connect mobile", common.connectMobile)
  runner.Step("App registration after disconnect with SubscribeWayPoints ",
    common.registerAppSubscribeWayPoints, { AppId1, Expected })
  runner.Step("OnWayPointChange", common.OnWayPointChange, { Expected })
  runner.Step("UnsubscribeWayPoints", common.UnsubscribeWayPoints)
  runner.Step("unexpectedDisconnect without UnsubscribeWayPoints",
    common.unexpectedDisconnectUnsubscribeWayPoints, { NotExpected })
  runner.Step("Connect mobile", common.connectMobile)
   runner.Step("App registration after disconnect without SubscribeWayPoints ",
    common.registerAppSubscribeWayPoints, { AppId1, NotExpected })

  runner.Title("Postconditions")
  runner.Step("Clean sessions", common.cleanSessions)
  runner.Step("Stop SDL", common.postconditions)
end
