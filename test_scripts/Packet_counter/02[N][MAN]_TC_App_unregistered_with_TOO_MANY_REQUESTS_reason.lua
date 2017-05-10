---------------------------------------------------------------------------------------------
-- APPLINK-16207 [GenericResultCodes] TOO_MANY_REQUESTS for the applications in other than NONE levels
-- APPLINK-8533 SDL must block apps that send messages of higher frequency than defined in .ini file
--
-- Mobile app sends more packets than defined by "count of packets" in custom period of time.
-- Source: SDLAQ-TC-726 in Jama
--
-- Preconditions:
-- 1. Define FrequencyCount = 50 and FrequencyTime = 5000 in .ini file
-- 2. Start SDL
-- 3. Register application
-- 4. Activate application --> hmiLevel = "FULL"
--
-- Steps:
-- 1. Send 51 RPCs within 5 seconds
--
-- Expected result:
-- All RPCs processed successfully except the last one
-- Application is unregistered with TOO_MANY_REQUESTS reason
---------------------------------------------------------------------------------------------

-- [[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
config.defaultProtocolVersion = 2

-- [[ Required Shared libraries ]]
local commonFunctions = require("user_modules/shared_testcases_genivi/commonFunctions")
local commonSteps = require("user_modules/shared_testcases_genivi/commonSteps")
local commonTestCases = require("user_modules/shared_testcases_genivi/commonTestCases")
local commonPreconditions = require("user_modules/shared_testcases_genivi/commonPreconditions")

-- [[ Local Variables ]]
local start_time = 0
local finish_time = 0

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
  commonTestCases:DelayedExp(5000)
end

-- [[ Test ]]

local received = false

function Test:RegisterNotification()
  self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered")
  :Do(function(_, d)
      if d.payload.reason == "TOO_MANY_REQUESTS" then
        received = true
      end
    end)
  :Pin()
  :Times(AnyNumber())
end

local numRq = 0
local numRs = 0

function Test.DelayBefore()
  commonTestCases:DelayedExp(5000)
  RUN_AFTER(function() start_time = timestamp() end, 5000)
end

for i = 1, 51 do
  Test["RPC_" .. string.format("%02d", i)] = function(self)
    if i == 1 then start_time = timestamp() end
    commonTestCases:DelayedExp(50)
    if not received then
      local cid = self.mobileSession:SendRPC("ListFiles", { })
      numRq = numRq + 1
      if numRq <= 50 then
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        :Do(function() numRs = numRs + 1 end)
      end
    end
  end
end

function Test.DelayAfter()
  finish_time = timestamp()
  commonTestCases:DelayedExp(5000)
end

function Test:CheckTimeOut()
  local processing_time = finish_time - start_time
  print("Processing time: " .. processing_time)
  if processing_time > 5000 then
    self:FailTestCase("Processing time is more than 5 sec.")
  end
end

function Test:CheckAppIsUnregistered()
  print("Number of Sent RPCs: " .. numRq)
  print("Number of Responses: " .. numRs)
  if not received then
    self:FailTestCase("OnAppInterfaceUnregistered(TOO_MANY_REQUESTS) is not received")
  else
    print("OnAppInterfaceUnregistered(TOO_MANY_REQUESTS) is received")
  end
end

-- [[ Postconditions ]]

function Test.RestoreFiles()
  commonPreconditions:RestoreFile("smartDeviceLink.ini")
end

function Test.StopSDL()
  StopSDL()
end

return Test
