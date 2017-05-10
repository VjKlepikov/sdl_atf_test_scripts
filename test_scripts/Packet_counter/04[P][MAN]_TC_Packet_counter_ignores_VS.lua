---------------------------------------------------------------------------------------------
-- APPLINK-16207 [GenericResultCodes] TOO_MANY_REQUESTS for the applications in other than NONE levels
-- APPLINK-8533 SDL must block apps that send messages of higher frequency than defined in .ini file
--
-- Packet counter ignores video streaming.
-- Source: SDLAQ-TC-730 in Jama
--
-- Preconditions:
-- 1. Define FrequencyCount = 50 and FrequencyTime = 5000 in .ini file
-- 2. Start SDL
-- 3. Register application
-- 4. Activate application --> hmiLevel = "FULL"
--
-- Steps:
-- 1. Start Video streaming
-- 2. Send 50 RPCs within 5 seconds
--
-- Expected result:
-- All RPCs processed successfully
-- Application is not unregistered
---------------------------------------------------------------------------------------------

-- [[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
config.defaultProtocolVersion = 3

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
commonFunctions:write_parameter_to_smart_device_link_ini("HeartBeatTimeout", "20000")
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

-- [[ Test ]]

local received = false

function Test:RegisterNotification()
  self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered")
  :Do(function(_, d)
      received = true
    end)
  :Pin()
  :Times(AnyNumber())
end

function Test:StartVideoStreaming()
  self.mobileSession:StartService(11)
  :Do(function()
      EXPECT_HMICALL("Navigation.StartStream")
      :Do(function(_, d)
          self.hmiConnection:SendResponse(d.id, d.method, "SUCCESS")
          RUN_AFTER(function() self.mobileSession:StartStreaming(11, "files/Wildlife.wmv") end, 1500)
          EXPECT_HMINOTIFICATION("Navigation.OnVideoDataStreaming")
        end)
    end)
end

function Test.DelayBefore()
  commonTestCases:DelayedExp(5000)
  RUN_AFTER(function() start_time = timestamp() end, 5000)
end

for i = 1, 50 do

  Test["RPC_" .. string.format("%02d", i)] = function(self)
    commonTestCases:DelayedExp(50)
    local cid = self.mobileSession:SendRPC("ListFiles", { })
    EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  end

end

function Test.DelayAfter()
  finish_time = timestamp()
  commonTestCases:DelayedExp(5000)
end

function Test:StopVideoStreaming()
  self.mobileSession:StopService(11)
  :Do(function()
      EXPECT_HMICALL("Navigation.StopStream")
      :Do(function(_, d)
          self.hmiConnection:SendResponse(d.id, d.method, "SUCCESS", { })
        end)
    end)
end

function Test:CheckTimeOut()
  local processing_time = finish_time - start_time
  print("Processing time: " .. processing_time)
  if processing_time > 5000 then
    self:FailTestCase("Processing time is more than 5 sec.")
  end
end

function Test:CheckAppIsNotUnregistered()
  if received then
    self:FailTestCase("OnAppInterfaceUnregistered(TOO_MANY_REQUESTS) is received")
  else
    print("OnAppInterfaceUnregistered(TOO_MANY_REQUESTS) is not received")
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
