---------------------------------------------------------------------------------------------------
-- Description: [SubscribeWayPoints]: SDL must transfer request from mobile app to hMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects_WayPoint/commonDefects')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }

--[[ Scenario ]]

--runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update preloaded_pt", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.startWait)
runner.Step("App registration", common.registerApp)
runner.Step("Activate App", common.activateApp)

for i = 1, common.iterator do
  runner.Title("Test" ..i)
  runner.Step("SubscribeWayPoints", common.SubscribeWayPoints)
  runner.Step("UnsubscribeWayPoints", common.UnsubscribeWayPoints)
end

runner.Title("Postconditions")
runner.Step("Clean sessions", common.cleanSessions)
runner.Step("Stop SDL", common.postconditions)

