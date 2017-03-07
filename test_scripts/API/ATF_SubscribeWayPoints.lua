-------------------------------------------------------------------------------------------------
-------------------------------------------- Preconditions --------------------------------------
-------------------------------------------------------------------------------------------------
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
if commonSteps:file_exists(config.pathToSDL .. "policy.sqlite") == true then
    os.remove(config.pathToSDL .. "policy.sqlite")
end
-- Precondition: preparation connecttest_SWP.lua
commonPreconditions:Connecttest_without_ExitBySDLDisconnect("connecttest_SWP.lua")
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
commonSteps:DeleteLogsFileAndPolicyTable()
f = assert(io.open(config.pathToSDL.. "/sdl_preloaded_pt.json", "r"))
  print ( " \27[31m  rpcs is not found in sdl_preloaded_pt.json \27[0m " )
else
   DefaultContant =  string.gsub(DefaultContant, '"rpcs".?:.?.?%{', '"rpcs": { \n"SubscribeWayPoints": {\n "hmi_levels": [\n  "BACKGROUND",\n   "FULL",\n   "LIMITED" \n]\n},\n"UnsubscribeWayPoints": { \n"hmi_levels": [\n   "BACKGROUND",\n   "FULL", \n  "LIMITED" \n]\n},')
end
f:close()
-- os.execute(" cp " .. config.pathToSDL .. "sdl_preloaded_pt.json " .. config.pathToSDL .. "sdl_preloaded_pt_corrected.json" )
-------------------------------------------------------------------------------------
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local json = require("json")

-------------------------------------------------------------------------------------
local infoMessage1000 = "1qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYqwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYqwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYqwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'"
local infoMessage1001 = "1qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYqwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYqwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYqwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'2"

-- ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2

end

  StopSDL()
    appNumber = 1
  end
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
    {
      reason = "IGNITION_OFF"
    })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
  :Times(appNumber)
  EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
  :Times(0)
end

  Test[TestName] = function(self)
    -- Requirement id in JAMA/or Jira ID:
    -- APPLINK-21629 #1
    local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})
    EXPECT_HMICALL("Navigation.SubscribeWayPoints")
    :Do(function(_,data)
        -- hmi side: sending Navigation.SubscribeWayPoints response
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    EXPECT_RESPONSE(CorIdSWP, {success = true , resultCode = "SUCCESS"} )
    :Times(1)
  end
end

  Test[TestName] = function(self)
    -- mobile side: send UnsubscribeWayPoints request
    local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints", {})
    -- hmi side: expected UnsubscribeWayPoints request
    :Do(function(_,data)
      -- hmi side: sending Navigation.UnsubscribeWayPoints response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    EXPECT_RESPONSE(CorIdSWP,   {success = true , resultCode = "SUCCESS"})
  end
end
-------------------------------------------PreConditions-------------------------------------
---------------------------------------------------------------------------------------------
-- Description: removing user_modules/connecttest_SWP.lua
function Test:Precondition_remove_user_connecttest()
      os.execute( "rm -f ./user_modules/connecttest_SWP.lua" )
end
-- End PreCondition.1

-- Description: Activation application
  --hmi side: sending SDL.ActivateApp request
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})
  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_,data)
    if data.result.isSDLAllowed ~= true then
      local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
      -- TODO: Update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
      EXPECT_HMIRESPONSE(RequestId)
      :Do(function(_,data)
          -- hmi side: send request SDL.OnAllowSDLFunctionality
          self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
          EXPECT_HMICALL("BasicCommunication.ActivateApp")
          :Do(function(_,data)
              -- hmi side: sending BasicCommunication.ActivateApp response
              self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
            end)
          :Times(AnyNumber())
        end)
  end)
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL"},"OnHMIStatus", {hmiLevel = "FULL"})
end
-- End PreCondition.2
-----------------------------------------I TEST BLOCK----------------------------------------
------CommonRequestCheck: Check of mandatory/conditional request's parameters (mobile protocol)----
---------------------------------------------------------------------------------------------
-- Description:
-- request with all parameters
-- request with only mandatory parameters
-- request with all combinations of conditional-mandatory parameters (if exist)
-- request with one by one conditional parameters (each case - one conditional parameter)
-- request with missing mandatory parameters one by one (each case - missing one mandatory parameter)
-- request with all parameters are missing
-- request with fake parameters (fake - not from protocol, from another request)
-- request is sent with invalid JSON structure
-- different conditions of correlationID parameter (invalid, several the same etc.)
----------------------------------------------------------------------------------------------------------
-- Begin Test case CommonRequestCheck.1
-- Description: Success resultCode
-- APPLINK-21629 #1
-- In case mobile app sends the valid SubscribeWayPoints_request to SDL and this request is allowed by Policies SDL must: transfer SubscribeWayPoints_request_ to HMI respond with <resultCode> received from HMI to mobile app
-- The request for SubscribeWayPoints is sent and executed successfully. The response code SUCCESS is returned.

-----------------------------------------------------------------------------------------------------------

-- Description: Check processing invalid format of JSON message of SubscribeWayPoints request
-- APPLINK-21629 #3
  userPrint(34, "=================== Test Case ===================")
  self.mobileSession.correlationId = self.mobileSession.correlationId + 1
  local msg =
  {
    serviceType = 7,
    frameInfo = 0,
    rpcType = 0,
    rpcFunctionId = 42,
    rpcCorrelationId = self.mobileSession.correlationId,
    --<<!-- extra ','
    payload = '{,}'
  }
  self.mobileSession:Send(msg)
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
  :Times(0)
  self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })
  :Times(0)
end
------------------------------------------------------------------------------------------
-- Description: Check processing SubscribeWayPoints request with fake parameter
-- APPLINK-21629 #3
-- According to APPLINK-13008 and APPLINK-11906 SDL must cut off fake parameters and process only parameters valid for named request
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {fakeParam = "fakeParam"})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
  :Times(1)
    -- hmi side: sending Navigation.SubscribeWayPoints response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  :ValidIf(function(_,data)
      if data.params then
        print("SDL re-sends fakeParam parameters to HMI in SubscribeWayPoints request")
        return false
      else
        return true
      end
    end)
  self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = true, resultCode = "SUCCESS"})
  :Times(1)
------------------------------------------------------------------------------------------------------------

-- Description: Check processing UnregisterAppInterface request with parameters from another request
-- APPLINK-21629 #3
-- In case mobile app sends the SubscribeWayPoints_request to SDL with invalid format of JSON message SDL must: consider this request as invalid respond "INVALID_DATA, success:false" to mobile app
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: UnregisterAppInterface request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", { menuName = "shouldn't be transfered" })
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
  :Times(1)
    -- hmi side: sending Navigation.SubscribeWayPoints response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  :ValidIf(function(_,data)
      if data.params then
        print("SDL re-sends fakeParam parameters to HMI in SubscribeWayPoints request")
        return false
      else
        return true
      end
    end)
  self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = true, resultCode = "SUCCESS" })
  :Times(1)
------------------------------------------------------------------------------------------

-- Description: Check processing requests with duplicate correlationID
-- TODO: fill Requirement, Verification criteria about duplicate correlationID
-- Requirement id in JAMA/or Jira ID:
-- APPLINK-21629 #6
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints",{})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
  :Times(1)
    -- hmi side: sending Navigation.SubscribeWayPoints response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  :Times(1)
  EXPECT_RESPONSE(CorIdSWP,
    { success = true, resultCode = "SUCCESS"},
    { success = false, resultCode = "IGNORED"})
  :Times(2)
  :Do(function(exp,data)
        local msg =
        {
          serviceType = 7,
          frameInfo = 0,
          rpcType = 0,
          rpcFunctionId = 42,
          rpcCorrelationId = self.mobileSession.correlationId,
          payload = '{}'
        }
        self.mobileSession:Send(msg)
      end
  :Times(1)
----------------------------------------II TEST BLOCK----------------------------------------
----------------------------------------Positive cases---------------------------------------
---------------------------------------------------------------------------------------------
--------------------------------Positive request check-------------------------------
--=================================================================================--
-- Description: Check of each request parameter value in bound and boundary conditions
-- ------------------------------------------------------------------------------------
-- Description: Check "info" parameter in response with lower bound, in bound and upper bound values
-- APPLINK-21629
-- TODO: add verification criteria
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
    -- hmi side: sending Navigation.SubscribeWayPoints response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = "a"} )
  end)
  EXPECT_RESPONSE(CorIdSWP, {success = true , resultCode = "SUCCESS", info = "a"})

  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
    -- hmi side: sending Navigation.SubscribeWayPoints response
    self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "a" )
  end)
  EXPECT_RESPONSE(CorIdSWP, {success = false , resultCode = "GENERIC_ERROR", info = "a"})
  :Times (0)
  commonTestCases:DelayedExp(1000)
-----------------------------------------------------------------------------------------

-- Description: Check "info" parameter in response with upper bound, in bound and upper bound values
-- APPLINK-21629
-- TODO: add verification criteria
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
    -- hmi side: sending Navigation.SubscribeWayPoints response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = infoMessage1000} )
  end)
  EXPECT_RESPONSE(CorIdSWP, {success = true , resultCode = "SUCCESS", info = infoMessage1000})

  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
    -- hmi side: sending Navigation.SubscribeWayPoints response
    self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoMessage1000 )
   end)
  EXPECT_RESPONSE(CorIdSWP, {success = false , resultCode = "GENERIC_ERROR", info = infoMessage1000})
  :Times(0)
  commonTestCases:DelayedExp(1000)
-------------------------------------------------------------------------------------------------------

-- Description: Check "info" parameter in response with upper bound, in bound and upper bound values
-- APPLINK-21629
-- TODO: add verification criteria
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
    -- hmi side: sending Navigation.SubscribeWayPoints response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = "in_bound_information123"} )
  end)
  EXPECT_RESPONSE(CorIdSWP, {success = true , resultCode = "SUCCESS", info = "in_bound_information123"})

  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
    -- hmi side: sending Navigation.SubscribeWayPoints response
    self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "in_bound_information123" )
  end)
  EXPECT_RESPONSE(CorIdSWP, {success = false, resultCode = "GENERIC_ERROR", info = "in_bound_information123"})
  :Times(0)
  commonTestCases:DelayedExp(1000)
----------------------------------------III TEST BLOCK----------------------------------------
----------------------------------------Negative cases----------------------------------------
---------------------------------------------------------------------------------------------
---------------------------------Negative request check------------------------------
--=================================================================================--
-- check "info" value in out of bound, missing, with wrong type, empty, duplicate etc.
-- Begin Test case NegativeRequestCheck.1
-- info param is empty (SendResponse)
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
    -- hmi side: sending Navigation.SubscribeWayPoints response
    -- According CRS APPLINK-14551 In case HMI responds via RPC with "message" param AND the value of "message" param is empty SDL must NOT transfer "info" parameter via corresponding RPC to mobile app
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = ""} )
  end)
  EXPECT_RESPONSE(CorIdSWP, {success = true , resultCode = "SUCCESS"})

function Test:SubscribeWayPoints_SendError_info_empty()
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
    -- hmi side: sending Navigation.SubscribeWayPoints response
    -- According CRS APPLINK-14551 In case HMI responds via RPC with "message" param AND the value of "message" param is empty SDL must NOT transfer "info" parameter via corresponding RPC to mobile app
    self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR",  "" )
  end)
  EXPECT_RESPONSE(CorIdSWP, {success = false , resultCode = "GENERIC_ERROR"})
  :Times(0)
  commonTestCases:DelayedExp(1000)
--------------------------------------------------------------------------------------------------

-- info param is out of upper bound (SendResponse)
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
    -- hmi side: sending Navigation.SubscribeWayPoints response
    -- According CRS APPLINK-14551 In case SDL receives <message> from HMI with maxlength more than defined for <info> param at MOBILE_API SDL must:truncate <message> to maxlength of <info> defined at MOBILE_API
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { info = infoMessage1001} )
  end)
  EXPECT_RESPONSE(CorIdSWP, {success = true , resultCode = "SUCCESS", info = infoMessage1000})
function Test:SubscribeWayPoints_SendError_info_out_upper_bound()
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
    -- hmi side: sending Navigation.SubscribeWayPoints response
    -- According CRS APPLINK-14551 In case SDL receives <message> from HMI with maxlength more than defined for <info> param at MOBILE_API SDL must:truncate <message> to maxlength of <info> defined at MOBILE_API
    self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoMessage1001 )
  end)
  EXPECT_RESPONSE(CorIdSWP, {success = false , resultCode = "GENERIC_ERROR", info = infoMessage1000})
  :Times(0)
  commonTestCases:DelayedExp(1000)
---------------------------------------------------------------------------

  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
      -- hmi side: sending Navigation.SubscribeWayPoints response
    end)
  EXPECT_RESPONSE(CorIdSWP, {success = true , resultCode = "SUCCESS"})
  :ValidIf (function(_,data)
            if data.payload.info then
              commonFunctions:printError(" SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\"")
              return false
            else
              return true
            end
          end)

  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
    -- hmi side: sending Navigation.SubscribeWayPoints response
  end)
  :Times(0)
  commonTestCases:DelayedExp(1000)
--------------------------------------------------------------------------------------------------------

  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
    -- hmi side: sending Navigation.SubscribeWayPoints response
  end)
  EXPECT_RESPONSE(CorIdSWP, {success = true , resultCode = "SUCCESS"})
  :ValidIf (function(_,data)
    if data.payload.info then
      commonFunctions:printError(" SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\"")
      return false
    else
      return true
    end
  end)

  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
    -- hmi side: sending Navigation.SubscribeWayPoints response
  end)
  :ValidIf (function(_,data)
        if data.payload.info then
          commonFunctions:printError(" SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\"")
          return false
        else
          return true
        end
  :Times(0)
  commonTestCases:DelayedExp(1000)

-- Begin NegativeRequestCheck.5
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
    -- hmi side: sending Navigation.SubscribeWayPoints response
  end)
  EXPECT_RESPONSE(CorIdSWP, {success = true , resultCode = "SUCCESS"})
  :ValidIf (function(_,data)
    if data.payload.info then
      commonFunctions:printError(" SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\"")
      return false
    else
      return true
    end
  end)
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
    -- hmi side: sending Navigation.SubscribeWayPoints response
  end)
    if data.payload.info then
      commonFunctions:printError(" SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\"")
      return false
    else
      return true
    end
  :Times(0)
  commonTestCases:DelayedExp(1000)

--------------------------------------------------------------------------------------------------
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
    -- hmi side: sending Navigation.SubscribeWayPoints response
  end)
  EXPECT_RESPONSE(CorIdSWP, {success = true , resultCode = "SUCCESS"})
  :ValidIf (function(_,data)
    if data.payload.info then
      commonFunctions:printError(" SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\"")
      return false
    else
      return true
    end
  end)

  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
    -- hmi side: sending Navigation.SubscribeWayPoints response
  end)
    if data.payload.info then
      commonFunctions:printError(" SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\"")
      return false
    else
      return true
    end
  :Times(0)
  commonTestCases:DelayedExp(1000)
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result code check--------------------------------------
----------------------------------------------------------------------------------------------
-- Description: TC's check all resultCodes values in pair with success value
-- Begin Test case ResultCodeCheck.1
-- Description: Checking result code responded from HMI
-- APPLINK-21629
-- SDL returns REJECTED code for the request sent
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
    -- hmi side: sending UI.AddCommand response
    self.hmiConnection:SendError(data.id, data.method, "REJECTED", "")
  end)
  :Times(0)
-- End Test case 4.1
----------------------------------------------------------------------------------------------

-- HMI does NOT respond to Navi.IsReady_request -> SDL must transfer received RPC to HMI even to non-responded Navi module
-- Begin Test case 4.2
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
    -- hmi side: sending UI.AddCommand response
    self.hmiConnection:SendError(data.id, data.method, "UNSUPPORTED_RESOURCE", "Navigation is not supported")
  end)
  :Times(0)
-- End Test case 4.2
----------------------------------------------------------------------------------------------

-- Description: Checking "GENERIC_ERROR" result code in case HMI does NOT respond during <DefaultTimeout>
-- Requirement id in JIRA:
-- APPLINK-21629, APPLINK-17008
-- Verification criteria: SDL must respond with "GENERIC_ERROR, success:false" in case HMI does NOT respond during <DefaultTimeout>
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
  EXPECT_RESPONSE(CorIdSWP, {success = false , resultCode = "GENERIC_ERROR", info = "Navigation component does not respond"})
  :Times(0)
----------------------------------------------------------------------------------------------

-- Requirements in Jira: APPLINK-21900
-- Verification criteria: In case mobile app already subscribed on wayPoints-related parameters and the same mobile app sends SubscribeWayPoints_request to SDL SDL must: respond "IGNORED, success:false" to mobile app
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints",{})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
  :Times(1)
    -- hmi side: sending Navigation.SubscribeWayPoints response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  :Times(1)
  EXPECT_RESPONSE(CorIdSWP,{ success = true, resultCode = "SUCCESS"})
  :Times(1)
  :Times(1)
  :Do(function(_, data)
    self.currentHashID1 = data.payload.hashID
  end)
end
    userPrint(34, "=================== Test Case ===================")
    -- mobile side: SubscribeWayPoints request
    local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints",{})
    EXPECT_HMICALL("Navigation.SubscribeWayPoints")
    :Times(0)
    EXPECT_RESPONSE(CorIdSWP,{ success = false, resultCode = "IGNORED"})
    :Times(1)
    :Times(0)
----------------------------------------------------------------------------------------------

-- Requirements in Jira: APPLINK-21900
-- Verification criteria: In case mobile app already subscribed on wayPoints-related parameters and the another app sends SubscribeWayPoints_request to SDL
function Test:Case_StartSession2()
  userPrint(34, "=================== Precondition ===================")
  -- Connected expectation
  self.mobileSession2 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    config.application2.registerAppInterfaceParams)
end
  self.mobileSession2:Start()
  :Do(function(_,data)
    if data.params.application.appName == "Test Application2" then
      HMIAppID2 = data.params.application.appID
    end
  end)
end
    -- hmi side: sending SDL.ActivateApp request
    EXPECT_HMIRESPONSE(RequestId)
    :Do(function(_,data)
      if
      data.result.isSDLAllowed ~= true then
        local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
        -- TODO: Update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
        EXPECT_HMIRESPONSE(RequestId)
        :Do(function(_,data)
            -- hmi side: send request SDL.OnAllowSDLFunctionality
            self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
            EXPECT_HMICALL("BasicCommunication.ActivateApp")
            :Do(function(_,data)
                -- hmi side: sending BasicCommunication.ActivateApp response
                self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
              end)
            :Times(AnyNumber())
          end)
      end)
    EXPECT_NOTIFICATION("OnHMIStatus",
      { systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"})
      { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"})
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: SubscribeWayPoints request
  local CorIdSWP = self.mobileSession2:SendRPC("SubscribeWayPoints",{})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
  :Times(0)
  self.mobileSession2:ExpectResponse("SubscribeWayPoints",{ success = true, resultCode = "SUCCESS"})
  self.mobileSession2:ExpectNotification("OnHashChange", {})
  :Times(1)
  :Do(function(_, data)
    self.currentHashID2 = data.payload.hashID
  end)
----------------------------------------------------------------------------------------------

-- Requirement id in JIRA:APPLINK-21900
-- Verification criteria: In case mobile app already subscribed on wayPoints-related parameters and the another app sends SubscribeWayPoints_request to SDL, SDL must: remember this another app as subscribed on wayPoints-related data
  userPrint(34, "=================== Precondition ===================")
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
  {
    reason = "SUSPEND"
  })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
  EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
  :Times(0)
  IGNITION_OFF(self,2)
  commonTestCases:DelayedExp(3000)
end
  userPrint(34, "=================== Test Case ===================")
  -- checkSDLPathValue
  commonSteps:CheckSDLPath()
  local resumptionDataTable
  local resumptionAppData2
    if resumptionDataTable.resumption.resume_app_list[p].appID == "0000001" then
      resumptionAppData1 = resumptionDataTable.resumption.resume_app_list[p]
    elseif resumptionDataTable.resumption.resume_app_list[p].appID == "0000002" then
      resumptionAppData2 = resumptionDataTable.resumption.resume_app_list[p]
  end
  -- print_table(resumptionAppData1)
  -- print_table(resumptionAppData2)
  local ErrorStatus = false
  resumptionAppData1.subscribed_for_way_points == false then
    ErrorMessage = ErrorMessage .. "subscribed_for_way_points saved in app_info.dat for app1 with false or data for app1 is absent at all\n"
    ErrorStatus = true
    -- self:FailTestCase("subscribed_for_way_points saved in app_info.dat with false")
  end
  if
  not resumptionAppData2 or
  resumptionAppData2.subscribed_for_way_points == false then
    ErrorMessage = ErrorMessage .. "subscribed_for_way_points saved in app_info.dat for app2 with false or data for app2 is absent at all\n"
    ErrorStatus = true
    -- self:FailTestCase("subscribed_for_way_points saved in app_info.dat with false")
  end
    self:FailTestCase(ErrorMessage)
  end
end
----------------------------------------------------------------------------------------------

-- Requirement id in JIRA: APPLINK-21898
-- Verification criteria: In case mobile app being subscribed on wayPoints-related data at previous ignition cycle registers at the next ignition cycle with the same <hashID> being at previous ignition cycle SDL must: restore status of subscription on wayPoints-related data being at previous ignition cycle for this app
function Test:RunSDL()
  userPrint(34, "=================== PreCondition ===================")
  StartSDL(config.pathToSDL, true)
end
end
end
end
  -- Connected expectation
  self.mobileSession2 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    config.application2.registerAppInterfaceParams)
end
  config.application2.registerAppInterfaceParams.hashID = self.currentHashID2
  self.mobileSession2:Start()
  print("\27[33m " .. "in app_info.dat hashID for app2 = ".. tostring(self.currentHashID2) .. "\27[0m")
    { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
  userPrint(34, "=================== Test Case ===================")
  -- body
  EXPECT_HMICALL("BasicCommunication.ActivateApp")
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
    end)
    { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"})
----------------------------------------------------------------------------------------------

-- Description: Check that there is no redundant request to HMI when app1 registers with hashID
  userPrint(34, "=================== Precondition ===================")
  -- Connected expectation
  self.mobileSession = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    config.application1.registerAppInterfaceParams)
end
  userPrint(34, "=================== Test Case ===================")
  config.application1.registerAppInterfaceParams.hashID = self.currentHashID1
  self.mobileSession:Start()
  print("\27[33m " .. "in app_info.dat hashID for app1 = ".. tostring(self.currentHashID1) .. "\27[0m")
  :Times(0)
----------------------------------------------------------------------------------------------

-- Requirement in JIRA: APPLINK-21897
-- [[ verification criteria: In case mobile app subscribed on wayPoints-related parameters unexpectedly disconnects SDL must:
-- store the status of subscription on wayPoints-related data for this app send UnsubscribeWayPoints_request to HMI ONLY if
-- no any apps currently subscribed to wayPoints-related data (please see APPLINK-21641) restore status of subscription on
-- ayPoints-related data for this app right after the same mobile app re-connects within the same ignition cycle with the same <hashID> being before unexpected disconnect ]]
  userPrint(34, "=================== Precondition ===================")
  -- mobile side: UnregisterAppInterface request
  self.mobileSession:SendRPC("UnregisterAppInterface", {})
  -- mobile side: UnregisterAppInterface request
  self.mobileSession2:SendRPC("UnregisterAppInterface", {})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered",
    {unexpectedDisconnect = false},
    {unexpectedDisconnect = false})
  :Times(2)
  :Times(1)
  self.mobileSession:ExpectResponse("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})
  -- mobile side: UnregisterAppInterface response
  self.mobileSession2:ExpectResponse("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})
  -- Connected expectation
  self.mobileSession = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    config.application1.registerAppInterfaceParams)
end
  self.mobileSession:Start()
  :Do(function(_,data)
    if data.params.application.appName == "Test Application" then
      HMIAppID1 = data.params.application.appID
    end
  end)
  -- hmi side: sending SDL.ActivateApp request
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = HMIAppID1 })
  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_,data)
    if
    data.result.isSDLAllowed ~= true then
      local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
      -- TODO: Update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
      EXPECT_HMIRESPONSE(RequestId)
      :Do(function(_,data)
          -- hmi side: send request SDL.OnAllowSDLFunctionality
          self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
          EXPECT_HMICALL("BasicCommunication.ActivateApp")
          :Do(function(_,data)
              -- hmi side: sending BasicCommunication.ActivateApp response
              self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
            end)
          :Times(AnyNumber())
        end)
   end)
  EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"})
end
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
    -- hmi side: sending Navigation.SubscribeWayPoints response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  EXPECT_RESPONSE(CorIdSWP, {success = true , resultCode = "SUCCESS"})
  :Do(function(_, data)
    self.currentHashID3 = data.payload.hashID
  end)
  -- Connected expectation
  self.mobileSession2 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    config.application2.registerAppInterfaceParams)
end
  self.mobileSession2:Start()
  :Do(function(_,data)
    if data.params.application.appName == "Test Application2" then
      HMIAppID2 = data.params.application.appID
    end
  end)
  -- hmi side: sending SDL.ActivateApp request
  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_,data)
      if
      data.result.isSDLAllowed ~= true then
        local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
        -- TODO: Update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
        EXPECT_HMIRESPONSE(RequestId)
        :Do(function(_,data)
            -- hmi side: send request SDL.OnAllowSDLFunctionality
            self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
            EXPECT_HMICALL("BasicCommunication.ActivateApp")
            :Do(function(_,data)
                -- hmi side: sending BasicCommunication.ActivateApp response
                self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
              end)
            :Times(AnyNumber())
          end)
    end)
  EXPECT_NOTIFICATION("OnHMIStatus",
    { systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"})
    { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"})
function Test:SubscribeWayPoints_Success_App2()
  local CorIdSWP = self.mobileSession2:SendRPC("SubscribeWayPoints", {})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
  :Times(0)
    -- hmi side: sending Navigation.SubscribeWayPoints response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  self.mobileSession2:ExpectResponse("SubscribeWayPoints", {success = true , resultCode = "SUCCESS"})
  self.mobileSession2:ExpectNotification("OnHashChange", {})
  :Do(function(_, data)
    self.currentHashID4 = data.payload.hashID
  end)
end
-- self.mobileSession:Stop()
-- end
-- function Test:CloseSession2()
-- self.mobileSession2:Stop()
-- end
end
  userPrint(34, "=================== Test Case ===================")
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true})
  :Times(2)
end
----------------------------------------------------------------------------------------------

-- Description: Check that SDL store the status of subscription on wayPoints-related data for this app
  userPrint(34, "=================== Test Case ===================")
  -- checkSDLPathValue()
  commonSteps:CheckSDLPath()
  local resumptionDataTable
  local resumptionAppData2
    if resumptionDataTable.resumption.resume_app_list[p].appID == "0000001" then
      resumptionAppData1 = resumptionDataTable.resumption.resume_app_list[p]
    elseif resumptionDataTable.resumption.resume_app_list[p].appID == "0000002" then
      resumptionAppData2 = resumptionDataTable.resumption.resume_app_list[p]
  end
  -- print_table(resumptionAppData1)
  -- print_table(resumptionAppData2)
  local ErrorStatus = false
  resumptionAppData1.subscribed_for_way_points == false then
    ErrorMessage = ErrorMessage .. "subscribed_for_way_points saved in app_info.dat for app1 with false or data for app1 is absent at all\n"
    ErrorStatus = true
    -- self:FailTestCase("subscribed_for_way_points saved in app_info.dat with false")
  end
  if
  not resumptionAppData2 or
  resumptionAppData2.subscribed_for_way_points == false then
    ErrorMessage = ErrorMessage .. "subscribed_for_way_points saved in app_info.dat for app2 with false or data for app2 is absent at all\n"
    ErrorStatus = true
    -- self:FailTestCase("subscribed_for_way_points saved in app_info.dat with false")
  end
    self:FailTestCase(ErrorMessage)
  end
end
----------------------------------------------------------------------------------------------

-- within the same ignition cycle with the same <hashID> being before unexpected disconnect
  userPrint(34, "=================== Precondition ===================")
  self:connectMobile()
end
  -- Connected expectation
  self.mobileSession2 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    config.application2.registerAppInterfaceParams)
end
  config.application2.registerAppInterfaceParams.hashID = self.currentHashID4
  self.mobileSession2:Start()
  print("\27[33m " .. "in app_info.dat hashID for app2 = ".. tostring(self.currentHashID4) .. "\27[0m")
  userPrint(34, "=================== Test Case ===================")
  -- body
  EXPECT_HMICALL("BasicCommunication.ActivateApp")
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
  end)
  :Do(function(_, data)
    self.currentHashID6 = data.payload.hashID
  end)
----------------------------------------------------------------------------------------------

-- Begin test case 4.12
  userPrint(34, "=================== Precondition ===================")
  -- Connected expectation
  self.mobileSession = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    config.application1.registerAppInterfaceParams)
end
  userPrint(34, "=================== Test Case ===================")
  config.application1.registerAppInterfaceParams.hashID = self.currentHashID3
  self.mobileSession:Start()
  print("\27[33m " .. "in app_info.dat hashID for app1 = ".. tostring(self.currentHashID3) .. "\27[0m")
    { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
  :Times(0)
  :Do(function(_, data)
    self.currentHashID5 = data.payload.hashID
  end)
----------------------------------------------------------------------------------------------

-- Begin test case 4.13
-- Description: Check that SDL does't send UnsubscribeWayPoints if unexpected disconnect occurs with one app but another one still registers
  userPrint(34, "=================== Precondition ===================")
  self.mobileSession2:Stop()
  userPrint(34, "=================== Test Case ===================")
  -- EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true})
  :Times(0)
----------------------------------------------------------------------------------------------

-- Begin test case 4.14
  userPrint(34, "=================== Precondition ===================")
  -- Connected expectation
  self.mobileSession2 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    config.application2.registerAppInterfaceParams)
end
  config.application2.registerAppInterfaceParams.hashID = self.currentHashID6
  self.mobileSession2:Start()
  print("\27[33m " .. "in app_info.dat hashID for app2 = ".. tostring(self.currentHashID6) .. "\27[0m")
    { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
  userPrint(34, "=================== Test Case ===================")
  EXPECT_HMICALL("BasicCommunication.ActivateApp")
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
  end)
  :Times(0)
----------------------------------------------------------------------------------------------

-- Description: Check DISALLOWED result code wirh success false
-- Requirement id in JIRA: APPLINK-21896
-- In case mobile app sends the valid SubscribeWayPoints_request to SDL and this request is NOT allowed by Policies SDL must: respond "DISALLOWED, success;false" to mobile app
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
  :Times(0)
  EXPECT_RESPONSE(CorIdSWP, {success = false , resultCode = "DISALLOWED"})
  :Times(0)
----------------------------------------------------------------------------------------------

-- Description: Check processing RPC in LIMITED Level
-- Requirement id in JIRA: APPLINK-21894
-- In case mobile app sends the valid SubscribeWayPoints_request to SDL and this request is allowed by Policies SDL must: transfer SubscribeWayPoints_request_ to HMI respond with <resultCode> received from HMI to mobile app 
  userPrint(34, "=================== Precondition ===================")
  -- hmi side: sending SDL.ActivateApp request
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})
  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_,data)
    if
    data.result.isSDLAllowed ~= true then
      local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
      -- TODO: Update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
      EXPECT_HMIRESPONSE(RequestId)
      :Do(function(_,data)
          -- hmi side: send request SDL.OnAllowSDLFunctionality
          self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
          EXPECT_HMICALL("BasicCommunication.ActivateApp")
          :Do(function(_,data)
            -- hmi side: sending BasicCommunication.ActivateApp response
            self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
          end)
          :Times(AnyNumber())
        end)
  end)
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL"},"OnHMIStatus", {hmiLevel = "FULL"})
end
function Test:DeactivateApp_Limited()
  local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
  {
    appID = self.applications["Test Application"],
    reason = "GENERAL"
  })
  EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
  userPrint(34, "=================== Test Case ===================")
 local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
  -- hmi side: sending Navigation.SubscribeWayPoints response
  self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
 end)
  EXPECT_RESPONSE(CorIdSWP, {success = true , resultCode = "SUCCESS"})
  EXPECT_NOTIFICATION("OnHashChange")
  :Times(1)  
end
----------------------------------------------------------------------------------------------

-- Begin test case 4.17
-- activate app1
  userPrint(34, "=================== Precondition ===================")
  -- hmi side: sending SDL.ActivateApp request
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})
  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_,data)
    if data.result.isSDLAllowed ~= true then
      local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
      -- hmi side: expect SDL.GetUserFriendlyMessage message response
      -- TODO: Update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
      EXPECT_HMIRESPONSE(RequestId)
      :Do(function(_,data)
        -- hmi side: send request SDL.OnAllowSDLFunctionality
        self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
        -- hmi side: expect BasicCommunication.ActivateApp request
        EXPECT_HMICALL("BasicCommunication.ActivateApp")
        :Do(function(_,data)
          -- hmi side: sending BasicCommunication.ActivateApp response
          self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
        end)
        :Times(AnyNumber())
      end)
    end
  end)
  -- mobile side: expect notification
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL"},"OnHMIStatus", {hmiLevel = "FULL"})
end
-- Precondition: UnsubscribeWayPoints request
postcondition_unsubscribewaypoints_success("Unsubscribewaypoints_success_15")
-- Upate policy where app1 has Location-1 group of permission
policyTable:updatePolicy("files/PTU_ForSubscribeWayPoints1.json")
----------------------------------------------------------------------------------
---------------------Common Functions for Policy check-----------------------------
-----------------------------------------------------------------------------------
function Test:PolicyCheckPrintName()
  userPrint(34, "=================== Test Case ===================")
end
policyTable:userConsent(true, "Location")
-- End test case 4.17
----------------------------------------------------------------------------------------------

-- Begin test case 4.18
-- Description: Request successful after user allow
function Test:PolicyCheckPrintName()
userPrint(34, "=================== Test Case ===================")
end
subscribewaypoints_success("SubscribeWayPoints_Success_4")
-- Postcondition: UnsubscribeWayPoints request
postcondition_unsubscribewaypoints_success("Unsubscribewaypoints_success_16")
-- End test case 4.18
-- testCasesForPolicyTable:userConsent(false, "Location")
function Test:PolicyCheckPrintName()
 userPrint(34, "=================== Precondition ===================")
end
policyTable:userConsent(false, "Location")
-- Send request and check USER_DISALLOWED resultCode
Test[APIName .."_resultCode_USER_DISALLOWED"] = function(self)
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: sending the request
  local cid = self.mobileSession:SendRPC("SubscribeWayPoints", {})
 -- mobile side: expect response
  self.mobileSession:ExpectResponse(cid, { success = false, resultCode = "USER_DISALLOWED"})
end
function Test:Postcondition_remove_user_connecttest_restore_preloaded_file()
 os.execute(" cp " .. config.pathToSDL .. "sdl_preloaded_pt_origin.json " .. config.pathToSDL .. "sdl_preloaded_pt.json" )
 os.execute(" rm -f " .. config.pathToSDL .. "/sdl_preloaded_pt_origin.json" )
 os.execute( "rm -f ./user_modules/connecttest_OnButtonSubscription.lua" )
end