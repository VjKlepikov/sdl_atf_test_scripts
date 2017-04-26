---------------------------------------------------------------------------------------------
-- SDL should allow mobile app to send custom count of packets in custom time.
-- Source: SDLAQ-TC-724 in Jama
---------------------------------------------------------------------------------------------

-- [[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
config.defaultProtocolVersion = 2

-- [[ Required Shared libraries ]]
local commonFunctions = require("user_modules/shared_testcases_genivi/commonFunctions")
local commonSteps = require("user_modules/shared_testcases_genivi/commonSteps")
local commonTestCases = require("user_modules/shared_testcases_genivi/commonTestCases")
local commonPreconditions = require("user_modules/shared_testcases_genivi/commonPreconditions")

-- [[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeletePolicyTable()
commonSteps:DeleteLogsFiles()

commonPreconditions:BackupFile("smartDeviceLink.ini")
commonFunctions:write_parameter_to_smart_device_link_ini("FrequencyCount", "50")
commonFunctions:write_parameter_to_smart_device_link_ini("FrequencyTime", "5000")

-- [[ General Settings for configuration ]]
Test = require("connecttest")
require('user_modules/AppTypes')

-- [[ Preconditions ]]

function Test:ActivateApp()
  local requestId1 = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName] })
  EXPECT_HMIRESPONSE(requestId1)
  :Do(function(_, d1)
      if d1.result.isSDLAllowed ~= true then
        local requestId2 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", { language = "EN-US", messageCodes = { "DataConsent" } })
        EXPECT_HMIRESPONSE(requestId2)
        :Do(function()
            self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", { allowed = true, source = "GUI", device = { id = config.deviceMAC, name = "127.0.0.1" } })
            EXPECT_HMICALL("BasicCommunication.ActivateApp")
            :Do(function(_, d2)
                self.hmiConnection:SendResponse(d2.id,"BasicCommunication.ActivateApp", "SUCCESS", { })
                self.mobileSession:ExpectNotification("OnHMIStatus", { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
              end)
          end)
      end
    end)
end

-- -- [[ Test ]]

for i = 1, 50 do

  Test["RPC_" .. string.format("%02d", i)] = function(self)
    commonTestCases:DelayedExp(90)
    local cid = self.mobileSession:SendRPC("ListFiles", { })
    EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  end

end

-- [[ Postconditions ]]

function Test.Restore_files()
  commonPreconditions:RestoreFile("smartDeviceLink.ini")
end

function Test.StopSDL()
  StopSDL()
end

return Test
