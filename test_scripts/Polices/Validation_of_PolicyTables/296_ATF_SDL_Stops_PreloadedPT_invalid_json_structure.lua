---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-8112]: Policies Manager - SDL must interrupt its starting up in case of policies-related failures (see in description)
-- 3) Fail parsing the preloaded PT - cases of invalid json and-or invalidated preloaded PT.
--
-- Description:
-- In case the Preloaded PT has invalid json format
-- PoliciesManager must log this error and shut SDL down.
--
-- Preconditions:
-- 1. Backup sdl_preloaded_pt.json file
-- 2. Replace in sdl_preloaded_pt.json: '"policy_table": {' with '"policy_table": ''
--
-- Steps:
-- 1. Start SDL.
-- 2. Restore sdl_preloaded_pt.json file
-- 3. Start again SDL
--
-- Expected result:
-- 1. SDL should log error. SDL should shut down.
-- 3. SDL should start normal communication.
---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')
local testCasesForPolicySDLErrorsStops = require('user_modules/shared_testcases_genivi/testCasesForPolicySDLErrorsStops')
local SDL = require('modules/SDL')
config.ExitOnCrash = false

---------------------------------------------------------------------------------------------
--[[ Preconditions ]]
common_functions:BackupFile("sdl_preloaded_pt.json")

function Test.Precondition_Corrupt_Preloaded_file()
  local path_to_file = config.pathToSDL .. 'sdl_preloaded_pt.json'
  local file = io.open(path_to_file, "r")
  local preloaded_data = file:read("*all")
  file:close()

  preloaded_data = string.gsub(preloaded_data, '\"policy_table\": {', '\"policy_table\": ')
  
  file = io.open(path_to_file, "w+")
  file:write(preloaded_data)
  file:close()
end

function Test.Precondition_StartSDL_corrupt_preloaded()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
  os.execute("sleep 5")
end

---------------------------------------------------------------------------------------------
--[[ Test Error message logging and SDL status with corrupted sdl_preloaded_pt.json ]]
function Test:TestStep_CheckSDLStatus_STOPPED()
  if SDL:CheckStatusSDL() ~= SDL.STOPPED then
    self:FailTestCase("SDL does NOT Stop when sdl_preloaded_pt.json is missing")
  end
end

function Test:TestStep_CheckSDLLogError()
  local result = testCasesForPolicySDLErrorsStops.ReadSpecificMessage("Preloaded PT is corrupted")
  if (false == result) then
    self:FailTestCase("Error: message 'Preloaded PT is corrupted' is not observed in smartDeviceLink.log.")
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

---------------------------------------------------------------------------------------------
-- --[[ Test Normal SDL communication when sdl_preloaded_pt.json is restored ]]
function Test.TestStep_Restore_Preloaded_file()
  common_functions:RestoreFile("sdl_preloaded_pt.json", true)
end

function Test.TestStep_StartSDL_correct_preloaded()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
  os.execute("sleep 10")
end


function Test:TestStep_CheckSDLStatus_RUNNING()
  if SDL:CheckStatusSDL() ~= SDL.RUNNING then
    self:FailTestCase("SDL is NOT Running after sdl_preloaded_pt.json is restored")
  end
end
---------------------------------------------------------------------------------------------
--[[ Postconditions ]]
common_steps:StopSDL("Postcondition_StopSDL")
