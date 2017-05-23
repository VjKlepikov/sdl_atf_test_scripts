---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-23700]: [Policy]: Log an error if PreloadedPT does not exist at the path defined in .ini file

-- Description:
-- SDL Must log an error and shutdown if PreloadedPT does not exist at the path defined in .ini

-- Preconditions:
-- 1. PreloadedPT = "invalid_preladedPt.json" in smartDeviceLink.ini
-- 2. StartSDL

-- Steps:
-- 1. Verify Error message is logged
-- 2. Verify SDL has Stopped
-- 3. Set Valid PreloadedPT value
-- 4. Verify SDL is Started

-- Expected result:
-- SDL: Logs "The file which contains preloaded PT is not exist" in .log file
-- SDL: Stops after logging error
-- SDL: Starts with Valid PreloadedPT value
---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')
local SDL = require('modules/SDL')
config.ExitOnCrash = false
local validPreloadePtFile = common_functions:GetValueFromIniFile("PreloadedPT")

---------------------------------------------------------------------------------------------
--[[ Preconditions ]]
common_steps:SetValuesInIniFile("Precondition_Set_Invalid_PreloadedPT",
  "PreloadedPT%s? = %s-.-%s-\n", "PreloadedPT", "invalid_preladedPt.json")
common_steps:PreconditionSteps("Precondition", const.precondition.START_SDL)

---------------------------------------------------------------------------------------------
--[[ Test Error message loging and SDL status with wrong PreloadePT value ]]
function Test:TestStep_VerifyErrorMessageIsLogged()
  os.execute("sleep 5") -- wait for SDL to STOP
  local logFileContent = io.open(tostring(config.pathToSDL) ..
    "SmartDeviceLinkCore.log", "r"):read("*all")

  -- NOTE: If Error message is changed in future test WILL Fail at this check
  if not string.find(logFileContent,
    "FATAL .* The file which contains preloaded PT is not exist")
  then
    self:FailTestCase("Error message not present")
  end

  if not string.find(logFileContent, "BasicCommunication.OnSDLClose") then
    self:FailTestCase("OnSDLClose is not present in .log")
  end

  if string.find(logFileContent, "DCHECK") then
    self:FailTestCase("'DCHECK' is present in .log")
  end
end

function Test:TestStep_CheckSDLStatus()
  if SDL:CheckStatusSDL() ~= SDL.STOPPED then
    self:FailTestCase("SDL does NOT Stop with incorect PreloadedPT value in smartDeviceLink.ini")
  end
end

common_steps:SetValuesInIniFile("TestStep_Set_Valid_PreloadedPT",
  "PreloadedPT%s? = %s-.-%s-\n", "PreloadedPT", validPreloadePtFile)

common_steps:StartSDL("StartSDL")

function Test:TestStep_Wait_10s_SDLContinuesToRun()
  common_functions:DelayedExp(10000)
end

function Test:TestStep_CheckSDLStatus_With_Valid_PreloadedPT()
  if SDL:CheckStatusSDL() ~= SDL.RUNNING then
    self:FailTestCase("SDL does NOT Start with valid PreloadedPT value in smartDeviceLink.ini")
  end
end
---------------------------------------------------------------------------------------------
--[[ Postconditions ]]
common_steps:StopSDL("Postcondition_StopSDL")
