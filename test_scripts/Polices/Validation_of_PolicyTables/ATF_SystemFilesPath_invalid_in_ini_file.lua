---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-19441]: [Policies] [MemoryConstrains]:
--  PoliciesManager must check the "SystemFilesPath" at .ini file upon each SDL`s start up
-- [APPLINK-8112]: [Policies Manager] SDL must interrupt its starting up in case of policies-related failures

-- Description:
-- SDL Must log an error and shutdown if SystemFilesPath is invalid in .ini file

-- Preconditions:
-- 1. SystemFilesPath = /invalid/path in smartDeviceLink.ini
-- 2. StartSDL

-- Steps:
-- 1. Verify Error message is logged
-- 2. Verify SDL has Stopped
-- 3. Set Valid SystemFilesPath value
-- 4. Verify SDL is Started

-- Expected result:
-- SDL: Logs "System files directory doesn't exist" in .log file
-- SDL: Stops after logging error
-- SDL: Starts with Valid SystemFilesPath value
---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')
local SDL = require('modules/SDL')
config.ExitOnCrash = false
local valid_system_files_path = common_functions:GetValueFromIniFile("SystemFilesPath")

---------------------------------------------------------------------------------------------
--[[ Preconditions ]]
common_steps:SetValuesInIniFile("Precondition_Set_Invalid_SystemFilesPath",
  "SystemFilesPath%s? = %s-.-%s-\n", "SystemFilesPath", "/invalid/path")
common_steps:PreconditionSteps("Precondition", const.precondition.START_SDL)

---------------------------------------------------------------------------------------------
--[[ Test Error message loging and SDL status with wrong SystemFilesPath value ]]
function Test:TestStep_VerifyErrorMessageIsLogged()
  os.execute("sleep 5") -- wait for SDL to STOP
  local log_file_content = io.open(tostring(config.pathToSDL) ..
    "SmartDeviceLinkCore.log", "r"):read("*all")

  -- NOTE: If Error message is changed in future test WILL Fail at this check
  if not string.find(log_file_content,
    "System files directory doesn't exist")
  then
    self:FailTestCase("Error message not present")
  end

  if not string.find(log_file_content, "BasicCommunication.OnSDLClose") then
    self:FailTestCase("OnSDLClose is not present in .log")
  end
end

function Test:TestStep_CheckSDLStatus()
  if SDL:CheckStatusSDL() ~= SDL.STOPPED then
    self:FailTestCase("SDL does NOT Stop with incorect SystemFilesPath value in smartDeviceLink.ini")
  end
end

common_steps:SetValuesInIniFile("TestStep_Set_Valid_SystemFilesPath",
  "SystemFilesPath%s? = %s-.-%s-\n", "SystemFilesPath", valid_system_files_path)

common_steps:StartSDL("StartSDL")

function Test:TestStep_Wait_10s_SDLContinuesToRun()
  common_functions:DelayedExp(10000)
end

function Test:TestStep_CheckSDLStatus_With_Valid_SystemFilesPath()
  if SDL:CheckStatusSDL() ~= SDL.RUNNING then
    self:FailTestCase("SDL does NOT Start with valid SystemFilesPath value in smartDeviceLink.ini")
  end
end
---------------------------------------------------------------------------------------------
--[[ Postconditions ]]
common_steps:StopSDL("Postcondition_StopSDL")
