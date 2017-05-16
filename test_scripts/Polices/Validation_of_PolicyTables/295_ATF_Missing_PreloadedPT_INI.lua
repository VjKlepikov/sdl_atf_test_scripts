---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-23700]: [Policy] log an error if PreloadedPT does not exist at the path defined in .ini file
--
-- Description:
-- In case the Preloaded PT does not exist at the path defined in .ini file, 
-- PoliciesManager must log this error and shut SDL down.
--
-- Preconditions:
-- 1. Backup sdl_preloaded_pt.json file
-- 2. Delete sdl_preloaded_pt.json from SDL folder.
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

function Test:Precondition_Remove_Preloaded_file()
  local is_removed
  local error_msg
  is_removed, error_msg = os.remove(config.pathToSDL .. "sdl_preloaded_pt.json")

  if(is_removed ~= true) then
    self:FailTestCase("PRECONDITION: ".. error_msg)
  end
end

function Test.Precondition_StartSDL()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
  os.execute("sleep 5")
end

---------------------------------------------------------------------------------------------
--[[ Test Error message logging and SDL status with missing sdl_preloaded_pt.json ]]
function Test:TestStep_CheckSDLStatus()
  if SDL:CheckStatusSDL() ~= SDL.STOPPED then
    self:FailTestCase("SDL does NOT Stop when sdl_preloaded_pt.json is missing")
  end
end

function Test:TestStep_CheckSDLLogError()
  local result = testCasesForPolicySDLErrorsStops.ReadSpecificMessage("Policy table is not initialized.")
  if (result == false) then
    self:FailTestCase("Error: message 'Policy table is not initialized.' is not observed in smartDeviceLink.log.")
  end

  result = testCasesForPolicySDLErrorsStops.ReadSpecificMessage("BasicCommunication.OnSDLClose")
  if (result == false) then
    self:FailTestCase("Error: 'BasicCommunication.OnSDLClose' is not observed in smartDeviceLink.log.")
  end
end

---------------------------------------------------------------------------------------------
--[[ Test Normal SDL communication when sdl_preloaded_pt.json is restored ]]
function Test.TestStep_Restore_Preloaded_file()
  common_functions:RestoreFile("sdl_preloaded_pt.json", true)
end

function Test.TestStep_StartSDL()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
  os.execute("sleep 10")
end

function Test:TestStep_CheckSDLStatus()
  if SDL:CheckStatusSDL() ~= SDL.RUNNING then
    self:FailTestCase("SDL is NOT Running after sdl_preloaded_pt.json is restored")
  end
end
---------------------------------------------------------------------------------------------
--[[ Postconditions ]]
common_steps:StopSDL("Postcondition_StopSDL")
