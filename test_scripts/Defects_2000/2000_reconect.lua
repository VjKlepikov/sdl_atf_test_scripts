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
local common = require('test_scripts/Defects/commonDefects')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local ApplicationResumingTimeout

--[[ Local Functions ]]
local function updateIniFile()
  ApplicationResumingTimeout = commonFunctions:read_parameter_from_smart_device_link_ini("ApplicationResumingTimeout")
  commonFunctions:write_parameter_to_smart_device_link_ini("ApplicationResumingTimeout", 5000)
end

local function restoreValuestIniFile()
  commonFunctions:write_parameter_to_smart_device_link_ini("ApplicationResumingTimeout", ApplicationResumingTimeout)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update ini file ApplicationResumingTimeout=5000", updateIniFile)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)

runner.Title("Test")
for i = 1, 2002 do
runner.Step("Activate App", common.activateApp)
runner.Step("Close session", common.unexpectedDisconnect)
runner.Step("Connect mobile", common.connectMobile)
runner.Step("App registration after disconnect", common.registerApp)
end
runner.Title("Postconditions")
runner.Step("Restore values in ini file", restoreValuestIniFile)
runner.Step("Stop SDL", common.postconditions)
