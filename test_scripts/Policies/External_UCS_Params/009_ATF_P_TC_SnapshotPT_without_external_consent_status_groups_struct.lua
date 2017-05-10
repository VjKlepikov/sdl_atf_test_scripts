---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-28549]: [Policies] External UCS: SnapshotPT without "external_consent_status_groups" param
-- [APPLINK-28631]: [Policies] External UCS: PreloadedPT without "external_consent_status_groups" struct
--
-- Description:
-- In case:
-- SDL Policies database omits "external_consent_status_groups:
-- [<functional_grouping>: <Boolean>]” param-> in "device_data" -> "<device identifier>"
-- -> "user_consent_records" -> "<app id>" section,
-- and SDL is triggered to create a SnapshotPolicyTable
-- SDL must:
-- omit this "external_consent_status_groups: [<functional_grouping>: <Boolean>]” field
-- in the corresponding "<functional grouping>" -> in the SnapshotPolicyTable.
--
-- Preconditions:
-- 1. Start SDL (make sure 'external_consent_status_groups' section is omitted in PreloadedPT)
--
-- Steps:
-- 1. Register app
-- 2. Activate app
-- 3. Verify PTSnapshot
--
-- Expected result:
-- Section "external_consent_status_groups" is omitted
--
-- Note: Script is designed for EXTERNAL_PROPRIETARY flow
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
config.defaultProtocolVersion = 2

--[[ Required Shared Libraries ]]
local commonFunctions = require('user_modules/shared_testcases_genivi/commonFunctions')
local commonSteps = require('user_modules/shared_testcases_genivi/commonSteps')
local testCasesForExternalUCS = require('user_modules/shared_testcases_genivi/testCasesForExternalUCS')

--[[ Local variables ]]
local appId = config.application1.registerAppInterfaceParams.appID
local checkedSection = "external_consent_status_groups"

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForExternalUCS.removePTS()
config.application1.registerAppInterfaceParams.isMediaApplication = true

--[[ General Settings for configuration ]]
Test = require("user_modules/shared_testcases_genivi/connecttest_resumption")
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:ConnectMobile()
  self:connectMobile()
end

function Test:StartSession()
  testCasesForExternalUCS.startSession(self, 1)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:RAI()
  testCasesForExternalUCS.registerApp(self, 1)
end

function Test:ActivateApp()
  testCasesForExternalUCS.activateApp(self, 1)
end

function Test:CheckPTS()
  if not testCasesForExternalUCS.pts then
    self:FailTestCase("PTS was not created")
  elseif testCasesForExternalUCS.pts.policy_table
    and testCasesForExternalUCS.pts.policy_table.device_data
    and testCasesForExternalUCS.pts.policy_table.device_data[config.deviceMAC]
    and testCasesForExternalUCS.pts.policy_table.device_data[config.deviceMAC].user_consent_records
    and testCasesForExternalUCS.pts.policy_table.device_data[config.deviceMAC].user_consent_records[appId]
    and testCasesForExternalUCS.pts.policy_table.device_data[config.deviceMAC].user_consent_records[appId][checkedSection]
    then
      self:FailTestCase("Section '" .. checkedSection .. "' was found in PTS")
    else
      print("Section '".. checkedSection .. "' doesn't exist in PTS")
      print(" => OK")
    end
  end

  --[[ Postconditions ]]
  commonFunctions:newTestCasesGroup("Postconditions")

  function Test.StopSDL()
    StopSDL()
  end

  return Test
