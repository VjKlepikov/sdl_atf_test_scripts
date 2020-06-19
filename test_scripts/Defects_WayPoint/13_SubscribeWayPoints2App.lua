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
local AppId2 = 2

--[[ Scenario ]]
for i = 1, 1 do
  runner.Title("Test" ..i)
  runner.Title("Preconditions")
  runner.Step("Clean environment", common.preconditions)
  runner.Step("Update preloaded_pt", common.updatePreloadedPT)
  runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  runner.Step("App1 registration", common.registerApp)
  runner.Step("Activate App", common.activateApp)

  runner.Title("Test" ..i)

  runner.Step("SubscribeWayPoints", common.SubscribeWayPoints)
  runner.Step("Sends OnWayPointChange", common.OnWayPointChange, { Expected })
  runner.Step("unexpectedDisconnect", common.unexpectedDisconnect, { 1000 })

  runner.Step("Connect mobile", common.connectMobile)
  runner.Step("App2 registration without SubscribeWayPoints",
  common.registerAppSubscribeWayPoints, { AppId2, NotExpected })
  runner.Step("OnWayPointChange", common.OnWayPointChange, { NotExpected, AppId2 })
  runner.Step("App1 registration after disconnect with SubscribeWayPoints",
    common.registerAppSubscribeWayPoints, { AppId1, Expected })
  runner.Step("OnWayPointChange", common.OnWayPointChange, { Expected, AppId1 })


  runner.Title("Postconditions")
  runner.Step("Clean sessions", common.cleanSessions)
  runner.Step("Stop SDL", common.postconditions)
end
