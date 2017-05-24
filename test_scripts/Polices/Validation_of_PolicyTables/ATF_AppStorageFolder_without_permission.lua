---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-8112]: [Policies Manager] SDL must interrupt its starting up in case of policies-related failures
-- 7) The path defined in AppStorageFolder does not actually exist or does not have read-write permissions.

-- Description:
-- SDL Must log an error and shutdown if AppStorageFolder does not have read-write permissions

-- Preconditions:
-- 1. StartSDL

-- Steps:
-- 1. Verify AppStorageFolder is created
-- 2. Stop SDL
-- 3. Disallow read/ write permission of AppStorageFolder
-- 4. Start SDL

-- Expected result:
-- SDL: Stops after logging error
---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')
local SDL = require('modules/SDL')
config.ExitOnCrash = false

--[[ Local variables ]]
local app_storage_folder = "storage"
local path_storage_file = config.pathToSDL .. app_storage_folder

---------------------------------------------------------------------------------------------
--[[ Preconditions ]]
common_steps:AddNewTestCasesGroup("Preconditions")
common_steps:BackupFile("Precondition_Backup_smartDeviceLink.ini", "smartDeviceLink.ini")

common_steps:SetValuesInIniFile("Precondition_Set_Incorrect_AppStorageFolder",
  "AppStorageFolder%s? = %s-.-%s-\n", "AppStorageFolder", app_storage_folder)

common_steps:PreconditionSteps("Precondition", const.precondition.START_SDL)

--[[ Tests ]]
common_steps:AddNewTestCasesGroup("Tests")
function Test:TestStep_WaitForCreatingStorage()
  os.execute("sleep 3") -- wait for SDL to create storage folder
end

common_steps:StopSDL("Postcondition_StopSDL")

function Test:TestStep_CheckStorageFolderExisted()
  if not common_functions:IsFileExist(path_storage_file) then
    self:FailTestCase("Storage does not exist")
  end
end

function Test:Update_Storage_Without_ReadWritePermissions()
  os.execute("chmod 100 " .. path_storage_file)
end

common_steps:StartSDL("StartSDL")

function Test:TestStep_CheckSDLStatus()
  os.execute("sleep 3") -- Wait for SDL to stop
  if SDL:CheckStatusSDL() ~= SDL.STOPPED then
    self:FailTestCase("SDL does NOT Stop when AppStorageFolder has no read/write permissions")
  end
end

--[[ Postconditions ]]
common_steps:AddNewTestCasesGroup("Postconditions")
function Test:Postcondition_Restore_Permission()
  os.execute("chmod 755 " .. path_storage_file)
end

common_steps:RestoreIniFile("Postcondition_Restore_smartDeviceLink.ini", "smartDeviceLink.ini")
