---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-8112]: Policies Manager - SDL must interrupt its starting up in case of policies-related failures (see in description)
-- 5) The path defined in SystemFilesPath does not have read-write permissions.
--
-- Description:
-- In case file defined in SystemFilesPath from INI does not have read-write permissions
-- PoliciesManager must log this error and shut SDL down.
--
-- Preconditions:
-- 1. Replace in INI file SystemFilesPath = tmp_dir
-- 2. Remove permissions for SystemFilesPath(tmp_dir)
--
-- Steps:
-- 1. Start SDL.
-- 2. Restore permissions for SystemFilesPath(tmp_dir)
-- 3. Start again SDL
--
-- Expected result:
-- 1. SDL should log error. SDL should shut down.
-- 3. SDL should start normal communication.
---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')
local testCasesForPolicySDLErrorsStops = require('user_modules/shared_testcases_genivi/testCasesForPolicySDLErrorsStops')
local commonFunctions = require('user_modules/shared_testcases_genivi/commonFunctions')
local commonPreconditions = require('user_modules/shared_testcases_genivi/commonPreconditions')
local SDL = require('modules/SDL')
config.ExitOnCrash = false
config.pathToSDL = commonPreconditions:GetPathToSDL()

--[[ Local Variables ]]
local new_path = config.pathToSDL .. "tmp_dir"

---------------------------------------------------------------------------------------------
--[[ Preconditions ]]
function Test.Precondition_Set_SystemFilesPath_no_rw_access()
  os.execute("mkdir " .. new_path)
  -- Remove user, group, other read/write permissions
  os.execute("chmod 100 ".. new_path)
  commonFunctions:write_parameter_to_smart_device_link_ini("SystemFilesPath","tmp_dir")
end

function Test.Precondition_StartSDL_SystemFilesPath_no_rw_access()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
  -- Additional wait to be sure that SDL will stop
  os.execute("sleep 5")
end

---------------------------------------------------------------------------------------------
--[[ Test Error message logging and SDL status when SystemFilesPath has no rw access ]]
function Test:TestStep_CheckSDLStatus_STOPPED()
  if SDL:CheckStatusSDL() ~= SDL.STOPPED then
    self:FailTestCase("SDL does NOT Stop when SystemFilesPath has no rw access")
  end
end

function Test:TestStep_CheckSDLLogError()
  -- Verification will fail in case error message is changed
  local result = testCasesForPolicySDLErrorsStops.ReadSpecificMessage("System directory doesn't have read/write permissions")
  if (false == result) then
    self:FailTestCase("Error: message 'System directory doesn't have read/write permissions' is not observed in smartDeviceLink.log.")
  end

  result = testCasesForPolicySDLErrorsStops.ReadSpecificMessage("BasicCommunication.OnSDLClose")
  if (false == result) then
    self:FailTestCase("Error: 'BasicCommunication.OnSDLClose' is not observed in smartDeviceLink.log.")
  end

  result = testCasesForPolicySDLErrorsStops.ReadSpecificMessage("DCHECK")
  if (true == result) then
    self:FailTestCase("'DCHECK' is observed in smartDeviceLink.log.")
  end
end

-------------------------------------------------------------------------------------------
--[[ Test Normal SDL communication when SystemFilesPath has rw access]]
function Test.TestStep_Restore_rw_access()
  os.execute("chmod 755 ".. new_path)
end

function Test.TestStep_StartSDL_SystemFilesPath_rw_access()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
  -- Additional wait to be sure that SDL will not stop
  os.execute("sleep 10")
end

function Test:TestStep_CheckSDLStatus_RUNNING()
  if SDL:CheckStatusSDL() ~= SDL.RUNNING then
    self:FailTestCase("SDL is NOT Running when permissions for SystemFilesPath(tmp_dir) are restored")
  end
end

---------------------------------------------------------------------------------------------
--[[ Postconditions ]]
function Test.Postcondition_Remove_tmp_path()
  os.execute("rm -rf " .. new_path)
end

common_steps:StopSDL("Postcondition_StopSDL")
