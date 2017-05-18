---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-28633]: [Policies] External UCS: PreloadedPT with "external_consent_status_groups" struct
-- [APPLINK-28631]: [Policies] External UCS: PreloadedPT without "external_consent_status_groups" struct
--
-- Description:
-- In case:
-- SDL uploads PreloadedPolicyTable with "external_consent_status_groups:
-- [<functional_grouping>: <Boolean>]" -> of "device_data" -> "<device identifier>"
-- -> "user_consent_records" -> "<app id>" section
-- SDL must:
-- a. consider such PreloadedPT is invalid
-- b. log corresponding error internally
-- c. shut SDL down
--
-- Preconditions:
-- 1. Start SDL (first run)
-- 2. Check SDL status => 1 (SDL is running)
-- 3. Stop SDL
--
-- Steps:
-- 1. Remove Local Policy Table
-- 2. Modify PreloadedPolicyTable (add 'external_consent_status_groups' section)
-- 3. Start SDL
-- 4. Check SDL status
--
-- Expected result:
-- Status = 0 (SDL is stopped)
--
-- Note: Script is designed for EXTERNAL_PROPRIETARY flow
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
config.defaultProtocolVersion = 2
config.ExitOnCrash = false

--[[ Required Shared Libraries ]]
local commonFunctions = require('user_modules/shared_testcases_genivi/commonFunctions')
local commonSteps = require('user_modules/shared_testcases_genivi/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases_genivi/commonPreconditions')
local sdl = require('SDL')
local testCasesForExternalUCS = require('user_modules/shared_testcases_genivi/testCasesForExternalUCS')
local testCasesForPolicySDLErrorsStops = require('user_modules/shared_testcases_genivi/testCasesForPolicySDLErrorsStops')

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()
commonPreconditions:BackupFile("sdl_preloaded_pt.json")

--[[ General Settings for configuration ]]
Test = require("user_modules/shared_testcases_genivi/connecttest_resumption")
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:CheckSDLStatus_1_RUNNING()
  testCasesForExternalUCS.checkSDLStatus(self, sdl.RUNNING)
end

function Test:StopSDL()
  testCasesForExternalUCS.ignitionOff(self)
end

function Test:CheckSDLStatus_2_STOPPED()
  testCasesForExternalUCS.checkSDLStatus(self, sdl.STOPPED)
end

function Test.RemoveLPT()
  testCasesForExternalUCS.removeLPT()
end

function Test.UpdatePreloadedPT_Add_section()
  local updateFunc = function(preloadedTable)
    preloadedTable.policy_table.device_data = {
      [config.deviceMAC] = {
        user_consent_records = {
          [config.application1.registerAppInterfaceParams.appID] = {
            external_consent_status_groups = {
              Location = false
            }
          }
        }
      }
    }
  end
  testCasesForExternalUCS.updatePreloadedPT(updateFunc)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test.StartSDL()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
  os.execute("sleep 5")
end

function Test:CheckSDLStatus_3_STOPPED()
  testCasesForExternalUCS.checkSDLStatus(self, sdl.STOPPED)
end

function Test:CheckLog()
  local result = testCasesForPolicySDLErrorsStops.ReadSpecificMessage("Parsed table is not valid policy_table")
  if result ~= true then
    self:FailTestCase("Error message was not found in log file")
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.StopSDL()
  StopSDL()
end

function Test.RestorePreloadedFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end

return Test
