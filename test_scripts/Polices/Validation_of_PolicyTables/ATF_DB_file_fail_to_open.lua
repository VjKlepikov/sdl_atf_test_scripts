---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-8112]: [Policies Manager] SDL must interrupt its starting up in case of policies-related failures
-- 1) Fail to open the database - Driver (library) of Database Management System (DBMS)
--  is responsible for that. Conditions depended on DBMS.

-- Description:
-- SDL Must log an error and shutdown if cannot open Database file

-- Preconditions:
-- 1. StartSDL

-- Steps:
-- 1. Verify SDL is Running
-- 2. Stop SDL
-- 3. Remove read permission of database file
-- 4. Start SDL
-- 5. Verify SDL has logged message
-- 6. Verify SDL has Stoped

-- Expected result:
-- SDL: Logs "Failed to read policy table source file" in .log file
-- SDL: Stops after logging error
---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')
local SDL = require('modules/SDL')
config.ExitOnCrash = false
local app_storage_folder = common_functions:GetValueFromIniFile("AppStorageFolder")
local attempts_to_open_policy_db = common_functions:GetValueFromIniFile("AttemptsToOpenPolicyDB")
local open_attempt_timeout = common_functions:GetValueFromIniFile("OpenAttemptTimeoutMs")

---------------------------------------------------------------------------------------------
--[[ Preconditions ]]
common_steps:PreconditionSteps("Precondition", const.precondition.START_SDL)

---------------------------------------------------------------------------------------------
--[[ Test Error message loging and SDL status when cannot open Database file ]]
function Test:TestStep_Wait_10s_SDLContinuesToRun()
  common_functions:DelayedExp(10000)
end

function Test:TestStep_CheckStatusSDL_Valid_Read_Permissions()
  if SDL:CheckStatusSDL() ~= SDL.RUNNING then
    self:FailTestCase("SDL does NOT Start with valid read permissions " ..
      "of database File")
  end
end

common_steps:StopSDL("TestStep_StopSDL")

function Test:Precondition_Remove_ReadPermissions_Of_DatabaseFile()
  -- Remove user, group, other read/write permissions for database file
  os.execute("chmod 100 " .. config.pathToSDL .. "/" .. app_storage_folder ..
    "/policy.sqlite")
  common_functions:DeleteLogsFiles() -- Clean *.log files for next verifications
end

common_steps:StartSDL("TestStep_StartSDL_NoReadPermission_DatabaseFile")

function Test:TestStep_VerifyErrorMessageIsLogged()
  -- Wait for SDL to STOP with `sleep`, timeout is calculated + 1s
  local timeout = 1 + (attempts_to_open_policy_db * open_attempt_timeout)/1000
  os.execute("sleep " .. tostring(timeout))

  local logFileContent = io.open(tostring(config.pathToSDL) ..
    "SmartDeviceLinkCore.log", "r"):read("*all")

  -- NOTE: If Error message is changed in future test WILL Fail at this check
  if not string.find(logFileContent,
    "Open retry sequence failed. Tried " .. attempts_to_open_policy_db ..
    " attempts with " .. open_attempt_timeout .. " open timeout%(ms%) for each.")
  then
    self:FailTestCase("Error message not present")
  end

  if not string.find(logFileContent, "BasicCommunication.OnSDLClose") then
    self:FailTestCase("OnSDLClose is not present in .log")
  end
end

function Test:TestStep_CheckSDLStatus()
  if SDL:CheckStatusSDL() ~= SDL.STOPPED then
    self:FailTestCase("SDL does NOT Stop when Database File cannot be opened")
  end
end

---------------------------------------------------------------------------------------------
--[[ Postconditions ]]
common_steps:StopSDL("Postcondition_StopSDL")
function Test:Postcondition_Set_ReadPermissions_To_DatabaseFile()
  os.execute("chmod 755 " .. config.pathToSDL .. "/" .. app_storage_folder ..
    "/policy.sqlite")
end
