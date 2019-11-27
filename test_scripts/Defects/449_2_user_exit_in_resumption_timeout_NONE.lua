---------------------------------------------------------------------------------------------------
-- User story: https://github.com/CustomSDL/Sync3.2v2/issues/499
--
-- Description: App HMI status is not changing to none when exiting via VR
--
-- Steps:
-- 1. SyncProxyTester app running and in default HMI level NONE
-- 2. Starts resumption timeout for FULL HMI level resumption
-- 3. Perform USER_EXIT from SyncProxyTester
--
-- Expected result:
-- 1. OnHMIStatus notification for the SyncProxyTester app should be HMI Level=None and Not_Audible
--   after BC.OnExitApplication(USER_EXIT)
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
local function sendOnExitApplication()
  common.getHMIConnection():SendNotification("BasicCommunication.OnExitApplication",
    {reason = "USER_EXIT", appID = common.getHMIAppId() })

  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered")
  :Times(0)

  common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp")
  :Times(0)

  common.getMobileSession():ExpectNotification("OnHMIStatus")
  :Times(0)

  common.wait(5000)
end

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
runner.Step("Activate App", common.activateApp)
runner.Step("Close session", common.unexpectedDisconnect)
runner.Step("Connect mobile", common.connectMobile)
runner.Step("App registration after disconnect", common.registerApp)

runner.Title("Test")
runner.Step("USER_EXIT from HMI", sendOnExitApplication)
runner.Step("Activation after exit", common.activateApp)

runner.Title("Postconditions")
runner.Step("Restore values in ini file", restoreValuestIniFile)
runner.Step("Stop SDL", common.postconditions)
