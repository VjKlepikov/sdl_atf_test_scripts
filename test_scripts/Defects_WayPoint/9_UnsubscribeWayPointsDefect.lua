---------------------------------------------------------------------------------------------------
-- Defect: SDL sends Navigation.UnsubscribeWayPoints twice #744
-- https://github.com/CustomSDL/Sync3.2v2/issues/744
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects_WayPoint/commonDefects')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }

local Expected = 1

--[[ Scenario ]]

runner.Title("Test")
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update preloaded_pt", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Step("SubscribeWayPoints", common.SubscribeWayPoints)
runner.Step("OnWayPointChange", common.OnWayPointChange, { Expected })
runner.Step("UnsubscribeWayPoints, close session", common.UnsubscribeWayPointsPointsUnexpectedDisconnect)

runner.Title("Postconditions")
runner.Step("Clean sessions", common.cleanSessions)
runner.Step("Stop SDL", common.postconditions)

