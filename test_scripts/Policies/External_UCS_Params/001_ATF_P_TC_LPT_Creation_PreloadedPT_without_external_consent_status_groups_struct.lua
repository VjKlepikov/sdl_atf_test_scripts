---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-28631]: [Policies] External UCS: PreloadedPT without "external_consent_status_groups" struct
--
-- Description:
-- In case:
-- SDL uploads PreloadedPolicyTable without "external_consent_status_groups:
-- [<functional_grouping>: <Boolean>]" -> of "device_data" -> "<device identifier>"
-- -> "user_consent_records" -> "<app id>" section
-- SDL must:
-- a. consider this PreloadedPT as valid (with the pre-conditions of all other valid PreloadedPT content)
-- b. continue working as assigned.
--
-- Preconditions:
-- 1. Stop SDL
-- 2. Check that PreloadedPT doesn't contain 'external_consent_status_groups' section
--
-- Steps:
-- 1. Start SDL
-- 2. Check SDL status
--
-- Expected result:
-- Status = 1 (SDL is running)
--
-- Note: Script is designed for EXTERNAL_PROPRIETARY flow
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
config.defaultProtocolVersion = 2

--[[ Required Shared Libraries ]]
local commonFunctions = require('user_modules/shared_testcases_genivi/commonFunctions')
local commonSteps = require('user_modules/shared_testcases_genivi/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases_genivi/commonPreconditions')
local sdl = require('SDL')
local testCasesForExternalUCS = require('user_modules/shared_testcases_genivi/testCasesForExternalUCS')

--[[ Local variables ]]
local checkedSection = "external_consent_status_groups"

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeletePolicyTable()
commonSteps:DeleteLogsFiles()

--[[ General Settings for configuration ]]
Test = require("user_modules/shared_testcases_genivi/connecttest_resumption")
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:StopSDL()
  testCasesForExternalUCS.ignitionOff(self)
end

function Test:CheckSDLStatus_1_STOPPED()
  testCasesForExternalUCS.checkSDLStatus(self, sdl.STOPPED)
end

function Test:CheckPreloadedPT()
  local preloadedFile = commonPreconditions:GetPathToSDL() .. "sdl_preloaded_pt.json"
  local preloadedTable = testCasesForExternalUCS.createTableFromJsonFile(preloadedFile)
  local result = true
  if preloadedTable
  and preloadedTable.policy_table
  and preloadedTable.policy_table.device_data
  and preloadedTable.policy_table.device_data[config.deviceMAC]
  and preloadedTable.policy_table.device_data[config.deviceMAC].user_consent_records
  then
    for _, v in pairs(preloadedTable.policy_table.device_data[config.deviceMAC].user_consent_records) do
      if v[checkedSection] then
        result = false
      end
    end
  end
  if result == false then
    self:FailTestCase("Section '" .. checkedSection .. "'' was found in PreloadedPT")
  end
end

function Test.RemoveLPT()
  testCasesForExternalUCS.removeLPT()
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test.StartSDL()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
  os.execute("sleep 5")
end

function Test:CheckSDLStatus_2_RUNNING()
  testCasesForExternalUCS.checkSDLStatus(self, sdl.RUNNING)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.StopSDL()
  StopSDL()
end

return Test
