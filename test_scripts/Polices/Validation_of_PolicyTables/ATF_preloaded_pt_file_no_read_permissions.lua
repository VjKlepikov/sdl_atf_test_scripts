---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-23701]: [Policy] Preloaded PT exists at the path defined in .ini file but NO "read" permissions

-- Description:
-- SDL Must log an error and shutdown if PreloadedPT file
--  exists, but does not have read permissions

-- Preconditions:
-- 1. Remove Read permissions of PreloadedPT
-- 2. StartSDL

-- Steps:
-- 1. Verify Error message is logged
-- 2. Verify SDL has Stopped
-- 3. Set read permission to PreloadedPT
-- 4. Verify SDL is Started

-- Expected result:
-- SDL: Logs "Failed to read policy table source file" in .log file
-- SDL: Stops after logging error
-- SDL: Starts with Valid Read permissions of PreloadedPT File
---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')
local SDL = require('modules/SDL')
config.ExitOnCrash = false
local preloaded_pt_file = common_functions:GetValueFromIniFile("PreloadedPT")

---------------------------------------------------------------------------------------------
--[[ Preconditions ]]
function Test:Precondition_Remove_ReadPermissions_Of_PreloadedPT_file()
  -- Remove user, group, other read permissions for preloadedPT file
  os.execute("chmod 333 " .. config.pathToSDL .. "/" .. preloaded_pt_file)
end
common_steps:PreconditionSteps("Precondition", const.precondition.START_SDL)

---------------------------------------------------------------------------------------------
--[[ Test Error message loging and SDL status with wrong read permissions for PreloadedPT file ]]
function Test:TestStep_VerifyErrorMessageIsLogged()
  -- Wait for SDL to STOP with `sleep 5`
  -- common_functions:DelayedExp will FAIL if SDL STOPS, `sleep` is used instead
  os.execute("sleep 5")
  
  local log_file_content = io.open(tostring(config.pathToSDL) ..
    "SmartDeviceLinkCore.log", "r"):read("*all")

  -- NOTE: If Error message is changed in future test WILL Fail at this check
  if not string.find(log_file_content,
    "Failed to read policy table source file")
  then
    self:FailTestCase("Error message not present")
  end

  if not string.find(log_file_content, "BasicCommunication.OnSDLClose") then
    self:FailTestCase("OnSDLClose is not present in .log")
  end
end

function Test:TestStep_CheckSDLStatus()
  if SDL:CheckStatusSDL() ~= SDL.STOPPED then
    self:FailTestCase("SDL does NOT Stop when PreloadedPT File has no read permissions")
  end
end

function Test:TestStep_Set_ReadPermissions_To_PreloadedPT_file()
  os.execute("chmod 755 " .. config.pathToSDL .. "/" .. preloaded_pt_file)
end

common_steps:StartSDL("StartSDL")

function Test:TestStep_Wait_10s_SDLContinuesToRun()
  common_functions:DelayedExp(10000)
end

function Test:TestStep_CheckSDLStatus_With_Valid_Permissions_PreloadedPT_File()
  if SDL:CheckStatusSDL() ~= SDL.RUNNING then
    self:FailTestCase("SDL does NOT Start with valid read permissions " ..
      "of PreloadedPT File")
  end
end

---------------------------------------------------------------------------------------------
--[[ Postconditions ]]
common_steps:StopSDL("Postcondition_StopSDL")
