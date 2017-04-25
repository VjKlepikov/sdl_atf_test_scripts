---------------------------------------------------------------------------------------------
-- Temporary script
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

  for i = 1, 51 do
    Test["RPC_" .. string.format("%02d", i)] = function(self)
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

  function Test.Delay()
    commonTestCases:DelayedExp(2000)
  end

  function Test.Check_OnAppInterfaceUnregistered()
    print("Is OnAppInterfaceUnregistered(TOO_MANY_REQUESTS) received: " .. tostring(received))
    print("Number of Sent RPCs: " .. numRq)
    print("Number of Responses: " .. numRs)
  end

  function Test:Check_RAI_NoSuccess()
    local corId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered"):Times(0)
    self.mobileSession:ExpectResponse(corId):Times(0)
    self.mobileSession:ExpectNotification("OnHMIStatus"):Times(0)
    self.mobileSession:ExpectNotification("OnPermissionsChange"):Times(0)
    commonTestCases:DelayedExp(3000)
  end

-- [[ Postconditions ]]

  function Test.Restore_files()
    commonPreconditions:RestoreFile("smartDeviceLink.ini")
  end

  function Test.StopSDL()
    StopSDL()
  end

return Test
