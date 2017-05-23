--[[ Description ]]
-- Requirement summary:
-- [APPLINK-23968]: [Policies] PreloadPT the only one invalid value in "RequestType" array

-- Description:
-- In case PreloadedPT has only one value in "RequestType" array and this value is invalid
-- SDL must log this error and shut SDL down

-- Preconditions:
-- -- 1. Preloaded PT exists at the path defined in .ini file

-- Steps:
-- -- 1. Policies manager checks PreloadedPT
-- -- 2. PreloadedPT-> "app_policies" -> "default" -> RequestType has only one invalid value

-- Expected result:
-- -- 1. SDL logs error internally and shuts down

--[[ Generic precondition ]]
require('user_modules/all_common_modules')
local testCasesForPolicySDLErrorsStops = require('user_modules/shared_testcases_genivi/testCasesForPolicySDLErrorsStops')
config.ExitOnCrash = false

--[[ Local Variables ]]
local parent_item = {"policy_table", "app_policies", "default"}
local request_type = {RequestType = {"ABC"}}

--[[ Specific Precondition ]]
common_steps:AddNewTestCasesGroup("Preconditions")
common_steps:BackupFile("PreconditionSteps_Backup_sdl_preloaded_pt.json", "sdl_preloaded_pt.json")

function Test.PreconditionSteps_Update_RequestType_has_only_one_invalid_In_PreloadedPT_file()
  common_functions:AddItemsIntoJsonFile(
    config.pathToSDL .. "sdl_preloaded_pt.json", parent_item, request_type)
end

common_steps:PreconditionSteps("PreconditionSteps", const.precondition.START_SDL)

--[[ Test ]]
common_steps:AddNewTestCasesGroup("Test")

function Test:Check_SDL_is_shutdown()
  os.execute(" sleep 5 ")
  local status = sdl:CheckStatusSDL()
  if (status == 1) then
    StopSDL()
    self:FailTestCase("SDL is not shut down")
  end
end

function Test:Check_SDL_logs_error_internally()
  local logFileContent = io.open(tostring(config.pathToSDL) .. "SmartDeviceLinkCore.log", "r")
  :read("*all")
  if not string.find(logFileContent, "default policy invalid RequestTypes will be cleaned")
  or not string.find(logFileContent, "ERROR(.+)default policy RequestTypes is empty after clean.up") then
    self:FailTestCase("No errors in log file")
  end

  result = testCasesForPolicySDLErrorsStops.ReadSpecificMessage("DCHECK")
  if (result == true) then
    self:FailTestCase("'DCHECK' is observed in smartDeviceLink.log.")
  end
end

--[[ Postconditions ]]
common_steps:AddNewTestCasesGroup("Postconditions")
common_steps:RestoreIniFile("Postcondition_Restore_sdl_preloaded_pt.json", "sdl_preloaded_pt.json")
