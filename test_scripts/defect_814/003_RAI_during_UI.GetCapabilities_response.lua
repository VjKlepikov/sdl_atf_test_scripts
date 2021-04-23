---------------------------------------------------------------------------------------------------
-- Description:
-- Check that SDL successfully registered App during UI.GetCapabilities response from HMI
--
-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
--
-- Steps:
-- Application sends RAI request to SDL during  UI.GetCapabilities response from HMI
--
-- Expected:
-- App is registered
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/defect_814/commonDefects')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Scenario ]]
for time = 1, 60, 1  do
	runner.Title("Test_" .. time)
	runner.Title("Preconditions")
	runner.Step("Clean environment", common.preconditions)
	runner.Step("Start SDL, HMI, connect Mobile, start Session", common.startWoHMIonReady)

	runner.Title("Test__" .. time)
	runner.Step("Send RAI during UI.GetCapabilities response", common.RAIDuringUIGetCapabilities, { time })

	runner.Title("Postconditions")
	runner.Step("Clean sessions", common.cleanSessions)
	runner.Step("Stop SDL", common.postconditions)
end
