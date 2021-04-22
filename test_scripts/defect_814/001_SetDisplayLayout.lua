---------------------------------------------------------------------------------------------------

-- Description:
-- Check that SDL successfully processing SetDisplayLayout request from mobile App1 during new App2 registration
--
-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
--
-- Steps:
-- Application sends SetDisplayLayout request with template to SDL during new app registration
--
-- Expected:
-- New App is registered
-- SDL transfers SetDisplayLayout response to mobile app
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/defect_814/commonDefects')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function sendSetDisplayLayoutDuringRAI(pTime)
  local AppID2 = 2
  RUN_AFTER(common.setDisplaySuccess, pTime)
  common.registerAppLog(AppID2)
end

--[[ Scenario ]]
for time = 1, 200, 2  do
  runner.Title("Test_" .. time)
  runner.Title("Preconditions")
  runner.Step("Clean environment", common.preconditions)
  runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  runner.Step("RAI", common.registerApp)
  runner.Step("Activate App", common.activateApp)

  runner.Title("Test__" .. time)
  runner.Step("Send SetDisplayLayout during RAI", sendSetDisplayLayoutDuringRAI, { time })

  runner.Title("Postconditions")
  runner.Step("Clean sessions", common.cleanSessions)
  runner.Step("Stop SDL", common.postconditions)
end
