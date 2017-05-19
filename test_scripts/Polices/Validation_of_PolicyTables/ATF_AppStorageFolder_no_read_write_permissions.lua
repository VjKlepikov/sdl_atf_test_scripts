---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-8112]: [Policies Manager] SDL must interrupt its starting up in case of policies-related failures
--  7) The path defined in AppStorageFolder does not actually exist or does not have read-write permissions.

-- Description:
-- SDL Must log an error and shutdown if AppStorageFolder
--  exists, but does not have read-write permissions

-- Preconditions:
-- 1. Create no_permissions_folder directory with no read/write permissions
-- 2. AppStorageFolder = no_permissions_folder in smartDeviceLink.ini
-- 3. StartSDL

-- Steps:
-- 1. Verify Error message is logged
-- 2. Verify SDL has Stopped
-- 3. Set read/write permission to AppStorageFolder
-- 4. Verify SDL is Started

-- Expected result:
-- SDL: Logs "Storage directory doesn't have read/write permissions" in .log file
-- SDL: Stops after logging error
-- SDL: Starts with Valid AppStorageFolder permissions
---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')
local SDL = require('modules/SDL')
config.ExitOnCrash = false

---------------------------------------------------------------------------------------------
--[[ Preconditions ]]
function Test:Precondition_CreateDirectory_Without_ReadWritePermissions()
  -- Create directory no_permissions_folder in config.pathToSDL
  os.execute("mkdir " .. config.pathToSDL .. "/no_permissions_folder")
  -- Remove user, group, other read/write permissions for no_permissions_folder
  os.execute("chmod 100 " .. config.pathToSDL .. "/no_permissions_folder")
end

common_steps:SetValuesInIniFile("Precondition_Set_Invalid_AppStorageFolder",
  "AppStorageFolder%s? = %s-.-%s-\n", "AppStorageFolder", "no_permissions_folder")

common_steps:PreconditionSteps("Precondition", const.precondition.START_SDL)

---------------------------------------------------------------------------------------------
--[[ Test Error message loging and SDL status with wrong r/w permissions for AppStorageFolder ]]
function Test:TestStep_VerifyErrorMessageIsLogged()
  os.execute("sleep 5") -- wait for SDL to STOP
  local log_file_content = io.open(tostring(config.pathToSDL) ..
    "SmartDeviceLinkCore.log", "r"):read("*all")

  -- NOTE: If Error message is changed in future test WILL Fail at this check
  if not string.find(log_file_content,
    "Storage directory doesn't have read/write permissions")
  then
    self:FailTestCase("Error message not present")
  end

  if not string.find(log_file_content, "BasicCommunication.OnSDLClose") then
    self:FailTestCase("OnSDLClose is not present in .log")
  end
end

function Test:TestStep_CheckSDLStatus()
  if SDL:CheckStatusSDL() ~= SDL.STOPPED then
    self:FailTestCase("SDL does NOT Stop when AppStorageFolder has no read/write permissions")
  end
end

function Test:TestStep_SetReadWritePermissions()
  os.execute("chmod 755 " .. config.pathToSDL .. "/no_permissions_folder")
end

common_steps:StartSDL("StartSDL")

function Test:TestStep_Wait_10s_SDLContinuesToRun()
  common_functions:DelayedExp(10000)
end

function Test:TestStep_CheckSDLStatus_With_Valid_Permissions_AppStorageFolder()
  if SDL:CheckStatusSDL() ~= SDL.RUNNING then
    self:FailTestCase("SDL does NOT Start with valid read/write permissions " ..
      "of AppStorageFolder")
  end
end
---------------------------------------------------------------------------------------------
--[[ Postconditions ]]
common_steps:StopSDL("Postcondition_StopSDL")
function Test:Postcondition_RemoveAppStorageFolder()
  os.execute("rm -rf " .. config.pathToSDL .. "/no_permissions_folder")
end
