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
local AppId1 = 1
local Expected = 1
local NotExpected = 0
--[[ Scenario ]]

--runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update preloaded_pt", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.startWait)
runner.Step("App registration", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("SubscribeWayPoints, close session", common.SubscribeWayPointsUnexpectedDisconnect)
runner.Step("Connect mobile", common.connectMobile)
runner.Step("App registration after disconnect without SubscribeWayPoints ",
  common.registerAppSubscribeWayPoints, { AppId1, NotExpected })

runner.Title("Postconditions")
runner.Step("Clean sessions", common.cleanSessions)
runner.Step("Stop SDL", common.postconditions)

