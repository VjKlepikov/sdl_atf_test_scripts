---------------------------------------------------------------------------------------------------
-- Description: Check OnWayPointChange notitifcation to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects_WayPoint/commonDefects')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }

local Expected = 1
local NotExpected = 0

--[[ Scenario ]]

runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update preloaded_pt", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("Activate App", common.activateApp)

for i = 1, 5 do
runner.Title("Test" ..i)
runner.Step("Does not send OnWayPointChange to App", common.OnWayPointChange, { NotExpected })
runner.Step("SubscribeWayPoints", common.SubscribeWayPoints)
runner.Step("Sends OnWayPointChange to App", common.OnWayPointChange, { Expected })
runner.Step("UnsubscribeWayPoints", common.UnsubscribeWayPoints)
runner.Step("Does not send OnWayPointChange to App", common.OnWayPointChange, { NotExpected })
end

runner.Title("Postconditions")
runner.Step("Clean sessions", common.cleanSessions)
runner.Step("Stop SDL", common.postconditions)

