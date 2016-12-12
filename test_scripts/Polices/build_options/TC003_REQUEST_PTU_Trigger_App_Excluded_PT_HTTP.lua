---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PolicyTableUpdate] Request PTU - an app registered is not listed in local PT

-- Description:
-- The policies manager must request an update to its local policy table 
--when an appID of a registered app is not listed on the Local Policy Table.

-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- Connect mobile phone over WiFi.
-- Register new application.
-- Successful PTU.
-- 2. Performed steps
-- Register new application
--
-- Expected result:
-- PTU is requested. PTS is created.
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
-- SDL->HMI: BasicCommunication.PolicyUpdate
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
--TODO: Should be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')
local mobile_session = require('mobile_session')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_HTTP_Successful_Flow ()
  testCasesForPolicyTable.flow_PTU_SUCCEESS_HTTP (self)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_StartNewSession()
  self.mobileSession1 = mobile_session.MobileSession( self, self.mobileConnection)
  self.mobileSession1:StartService(7)
end

function Test:TestStep_PTU_AppID_SecondApp_NotListed_PT()
  local hmi_app1_id = self.applications[config.application1.registerAppInterfaceParams.appName]

  local correlationId = self.mobileSession1:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application2.registerAppInterfaceParams.appName } })
  :Do(function(_,data)
      local hmi_app2_id = data.params.application.appID
      EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})

      testCasesForPolicyTableSnapshot:verify_PTS(true, {
          config.application1.registerAppInterfaceParams.appID,
          config.application2.registerAppInterfaceParams.appID,
        },
        {config.deviceMAC},
        {hmi_app1_id, hmi_app2_id})

      local timeout_after_x_seconds = testCasesForPolicyTableSnapshot:get_data_from_PTS("module_config.timeout_after_x_seconds")
      local seconds_between_retries = {}
      for i = 1, #testCasesForPolicyTableSnapshot.pts_seconds_between_retries do
        seconds_between_retries[i] = testCasesForPolicyTableSnapshot.pts_seconds_between_retries[i].value
      end

      EXPECT_HMICALL("BasicCommunication.PolicyUpdate",
        {
          file = "/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json",
          timeout = timeout_after_x_seconds,
          retry = seconds_between_retries
        })
      :Do(function(_,data1)
          self.hmiConnection:SendResponse(data1.id, data1.method, "SUCCESS", {})
        end)
    end)
  self.mobileSession1:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test

