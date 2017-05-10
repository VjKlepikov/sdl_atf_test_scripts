---------------------------------------------------------------------------------------------
-- APPLINK-16207 [GenericResultCodes] TOO_MANY_REQUESTS for the applications in other than NONE levels
-- APPLINK-8533 SDL must block apps that send messages of higher frequency than defined in .ini file
--
-- SDL should close session correctly by "TOO_MANY_REQUESTS" reason.
-- Source: SDLAQ-TC-736 in Jama
--
-- Preconditions:
-- 1. Define FrequencyCount = 50 and FrequencyTime = 5000 in .ini file
-- 2. Start SDL
-- 3. Register 2 applications
-- 4. Activate both applications
--
-- Steps:
-- 1. Send 51 RPCs within 5 seconds from 1st application
-- 2. Application one is unregistered with TOO_MANY_REQUESTS reason
-- 3. Register application one
--
-- Expected result:
-- Application one is not possible to register
-- Application two remains registered
---------------------------------------------------------------------------------------------

-- [[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
config.defaultProtocolVersion = 2

-- [[ Required Shared libraries ]]
local commonFunctions = require("user_modules/shared_testcases_genivi/commonFunctions")
local commonSteps = require("user_modules/shared_testcases_genivi/commonSteps")
local commonTestCases = require("user_modules/shared_testcases_genivi/commonTestCases")
local commonPreconditions = require("user_modules/shared_testcases_genivi/commonPreconditions")
local mobile_session = require("mobile_session")

-- [[ Local Variables ]]
local start_time = 0
local finish_time = 0

-- [[ Local Functions ]]
local function activateApp(test, id)
  local appName = config["application"..id].registerAppInterfaceParams.appName
  local reqId = test.hmiConnection:SendRequest("SDL.ActivateApp", { appID = test.applications[appName] })
  EXPECT_HMIRESPONSE(reqId)
  :Do(function(_, d1)
      if d1.result.isSDLAllowed ~= true then
        local reqId2 = test.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
          { language = "EN-US", messageCodes = { "DataConsent" } })
        EXPECT_HMIRESPONSE(reqId2)
        :Do(function()
            test.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
              { allowed = true, source = "GUI", device = { id = config.deviceMAC, name = "127.0.0.1" } })
            EXPECT_HMICALL("BasicCommunication.ActivateApp")
            :Do(function(_, d2)
                test.hmiConnection:SendResponse(d2.id,"BasicCommunication.ActivateApp", "SUCCESS", { })
                if id == 1 then id = "" end
                test["mobileSession"..id]:ExpectNotification("OnHMIStatus",
                  { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
              end)
          end)
      end
    end)
end

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

function Test:ActivateApp_1()
  activateApp(self, 1)
end

function Test:StartSession_2()
  self.mobileSession2 = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession2:StartService(7)
end

function Test:RAI_2()
  local corId = self.mobileSession2:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application2.registerAppInterfaceParams.appName } })
  :Do(function(_, d)
      self.applications[config.application2.registerAppInterfaceParams.appName] = d.params.application.appID
    end)
  self.mobileSession2:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
  :Do(function()
      self.mobileSession2:ExpectNotification("OnHMIStatus", { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
      self.mobileSession2:ExpectNotification("OnPermissionsChange")
    end)
end

function Test:ActivateApp_2()
  activateApp(self, 2)
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

function Test:Check_App_1_NoPossibleToRegister()
  local corId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered"):Times(0)
  self.mobileSession:ExpectResponse(corId, { success = false, resultCode = "TOO_MANY_PENDING_REQUESTS" }):Times(1)
  self.mobileSession:ExpectNotification("OnHMIStatus"):Times(0)
  self.mobileSession:ExpectNotification("OnPermissionsChange"):Times(0)
  commonTestCases:DelayedExp(3000)
end

function Test:Check_App_2_AlreadyRegistered()
  local corId = self.mobileSession2:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
  self.mobileSession2:ExpectResponse(corId, { success = false, resultCode = "APPLICATION_REGISTERED_ALREADY" })
end

-- [[ Postconditions ]]

function Test.RestoreFiles()
  commonPreconditions:RestoreFile("smartDeviceLink.ini")
end

function Test.StopSDL()
  StopSDL()
end

return Test
