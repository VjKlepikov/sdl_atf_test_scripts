---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-8112]: Policies Manager - SDL must interrupt its starting up in case of policies-related failures (see in description)
-- 6) The name defined in PathToSnapshot is incorrect for the specific OS.
--
-- Description:
-- In case the sdl_snapshot.json is incorrect for the specific OS, 
-- PoliciesManager must log this error and shut SDL down.
--
-- Preconditions:
-- 1. Update PathToSnapshot form INI file to incorrect for the specific OS.
--
-- Steps:
-- 1. Start SDL.
-- 2. Restore original PathToSnapshot in INI file.
-- 3. Start again SDL
--
-- Expected result:
-- 1. SDL should log error. SDL should shut down.
-- 3. SDL should start normal communication.
---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')
local testCasesForPolicySDLErrorsStops = require('user_modules/shared_testcases_genivi/testCasesForPolicySDLErrorsStops')
local commonFunctions = require('user_modules/shared_testcases_genivi/commonFunctions')
local SDL = require('modules/SDL')
config.ExitOnCrash = false

--[[ Local variables ]]
local snapshot_path = common_functions:GetValueFromIniFile("PathToSnapshot")

---------------------------------------------------------------------------------------------
--[[ Preconditions ]]
function Test.Precondition_Set_invalid_snapshot_file()
  os.execute()
  commonFunctions:write_parameter_to_smart_device_link_ini("PathToSnapshot", "-\tsdl$snapshot.json")
end

function Test.Precondition_StartSDL()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
  -- Additional wait to be sure that SDL will stop
  os.execute("sleep 5")
end

---------------------------------------------------------------------------------------------
--[[ Test Error message logging and SDL status with missing snapshot.json ]]
function Test:TestStep_CheckSDLStatus()
  if SDL:CheckStatusSDL() ~= SDL.STOPPED then
    self:FailTestCase("SDL does NOT Stop when defined snapshot file is missing")
  end
end

function Test:TestStep_CheckSDLLogError()
  -- Check may fail in case the error message is changed
  local result = testCasesForPolicySDLErrorsStops.ReadSpecificMessage("PathToSnapshot has forbidden")
  if (false == result) then
    self:FailTestCase("Error: message 'PathToSnapshot has forbidden(non-portable) symbols' is not observed in smartDeviceLink.log.")
  end

  result = testCasesForPolicySDLErrorsStops.ReadSpecificMessage("DCHECK")
  if (true == result) then
    self:FailTestCase("'DCHECK' is observed in smartDeviceLink.log.")
  end
end

---------------------------------------------------------------------------------------------
--[[ Test Normal SDL communication when snapshot.json is restored ]]
function Test.TestStep_Restore_snapshot_file()
  commonFunctions:write_parameter_to_smart_device_link_ini("PathToSnapshot", snapshot_path)
end

function Test.TestStep_StartSDL()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
  -- Additional wait to be sure that SDL will NOT stop
  os.execute("sleep 10")
end

function Test:TestStep_CheckSDLStatus()
  if SDL:CheckStatusSDL() ~= SDL.RUNNING then
    self:FailTestCase("SDL is NOT Running when defined snapshot file exists")
  end
end

---------------------------------------------------------------------------------------------
--[[ Postconditions ]]
common_steps:StopSDL("Postcondition_StopSDL")
