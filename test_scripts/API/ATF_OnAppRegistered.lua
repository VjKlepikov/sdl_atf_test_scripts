---------------------------------------------------------------------------------------------
--ATF version: 2.2
--Last modify date: 14/Dec/2015
--Author: Ta Thanh Dong
---------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------
-------------------------------------------- Preconditions --------------------------------------
-------------------------------------------------------------------------------------------------
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--------------------------------------------------------------------------------
--Precondition: preparation connecttest_OnAppRegistered.lua
commonPreconditions:Connecttest_without_ExitBySDLDisconnect("connecttest_OnAppRegistered.lua")
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

Test = require('user_modules/connecttest_OnAppRegistered')
local mobile_session = require('mobile_session')
require('cardinalities')
local events = require('events')

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
common_functions = require('user_modules/common_functions')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
require('user_modules/AppTypes')

---------------------------------------------------------------------------------------------
------------------------------------------Common variables-----------------------------------
---------------------------------------------------------------------------------------------
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2

---------------------------------------------------------------------------------------------
------------------------------------------Common functions-----------------------------------
---------------------------------------------------------------------------------------------

local function startSession(self)

  self.mobileSession= mobile_session.MobileSession(self, self.mobileConnection)

  --configure HB and protocol
  self.mobileSession.version = 3
  self.mobileSession:SetHeartbeatTimeout(7000)

  --start session
  self.mobileSession:StartService(7)
  --start HB in case you need and protocol version is 3
  self.mobileSession:StartHeartbeat()

end

local function StopSDL_StartSDLAgain_StartHMI_StartMobile(TestCase_Suffix)

  Test["StopSDL_" .. TestCase_Suffix] = function(self)
    StopSDL()
  end

  Test["StartSDL_" .. TestCase_Suffix] = function(self)
    StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  Test["InitHMI_" .. TestCase_Suffix] = function(self)
    self:initHMI()
  end

  Test["InitHMI_onReady_" .. TestCase_Suffix] = function(self)
    self:initHMI_onReady()
  end

  Test["ConnectMobile_" .. TestCase_Suffix] = function(self)
    self:connectMobile()
  end

  Test["StartSession_" .. TestCase_Suffix] = function(self)
    startSession(self)
  end

end

local function Ignition_On(TestCase_Suffix)

  Test["Ignition_On_Step1_StopSDL_" .. TestCase_Suffix] = function(self)
    StopSDL()
  end

  Test["Ignition_On_Step2_StartSDL_" .. TestCase_Suffix] = function(self)
    StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  Test["Ignition_On_Step3_InitHMI_" .. TestCase_Suffix] = function(self)
    self:initHMI()
  end

  Test["Ignition_On_Step4_InitHMI_onReady_" .. TestCase_Suffix] = function(self)
    self:initHMI_onReady()
  end

  Test["Ignition_On_Step5_ConnectMobile_" .. TestCase_Suffix] = function(self)
    self:connectMobile()
  end

  Test["Ignition_On_Step6_StartSession_" .. TestCase_Suffix] = function(self)
    startSession(self)
  end

end

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

commonSteps:DeleteLogsFileAndPolicyTable()

-- Precondition: removing user_modules/connecttest_OnAppRegistered.lua
function Test:Precondition_remove_user_connecttest()
  os.execute( "rm -f ./user_modules/connecttest_OnAppRegistered.lua" )
end

--TODO: Remove print after resolving APPLINK-16052
-- print ("\27[33m Because of ATF defect APPLINK-16052 check of deviceInfo params in BC.OnAppRegistered is commented \27[0m")

----------------------------------------------------------------------------------------------
--SDLAQ-TC-1363: TC_OnAppRegistered_01
--APPLINK-18435: 04[P][MAN]_TC_SDL_sends_OnAppRegistered_during_RAI
--Verification criteria: Check that SDL sends OnAppRegistered during RegisterAppInterface processing (verification of mandatory parameters + integer HMI appID)

--And

--SDLAQ-TC-1426: TC_OnAppRegistered_06
--APPLINK-18440: 09[P][MAN]_TC_SDL_sends_transportType_within_mandatory_deviceInfo_in_OnAppRegistered_during_RAI
--Verification criteria: SDL sends optional parameter "transportType" within mandatory deviceInfo if App connected via WiFi
----------------------------------------------------------------------------------------------
local function TC_OnAppRegistered_01()
  --Print new line to separate new test cases group
  commonFunctions:newTestCasesGroup("Test case: TC_OnAppRegistered_01/04[P][MAN]_TC_SDL_sends_OnAppRegistered_during_RAI and TC_OnAppRegistered_06/09[P][MAN]_TC_SDL_sends_transportType_within_mandatory_deviceInfo_in_OnAppRegistered_during_RAI")

  --Preconditions: Stop SDL, start SDL again, start HMI, connect to SDL, start mobile, start new session.
  StopSDL_StartSDLAgain_StartHMI_StartMobile("01")

  function Test:OnAppRegistered_Verify_Mandatory_Parameters_And_Integer_HMI_appID()

    --mobile side: RegisterAppInterface request
    local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
      {
        syncMsgVersion =
        {
          majorVersion = 3,
          minorVersion = 0
        },
        appName = "SPT",
        isMediaApplication = true,
        languageDesired = "EN-US",
        hmiDisplayLanguageDesired = "EN-US",
        appID = "1234567",
        deviceInfo =
        {
          os = "Android",
          carrier = "Megafon",
          firmwareRev = "Name: Linux, Version: 3.4.0-perf",
          osVersion = "4.4.2",
          maxNumberRFCOMMPorts = 1
        }
      })

    --hmi side: expected BasicCommunication.OnAppRegistered
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
      {
        application =
        {
          appName = "SPT",
          policyAppID = "1234567",
          isMediaApplication = true,
          hmiDisplayLanguageDesired = "EN-US"
          --TODO: update after resolving APPLINK-16052
          -- deviceInfo =
          -- {
          -- name = "127.0.0.1",
          -- id = config.deviceMAC,
          -- transportType = "WIFI",
          -- isSDLAllowed = true
          -- }
        }
      })
    :ValidIf(function(_,data)
        local result = true
        if data.params.application.appID == nil or type(data.params.application.appID) ~= "number" then
          commonFunctions:printError("OnAppRegistered notification came with appID parameter is nil or not a number")
          result = false
        end

        if (data.params.application.requestType ~= nil) then
          for i=1, #data.params.application.requestType do
            --print("data.params.application.requestType = " ..data.params.application.requestType[i])
            if (#data.params.application.requestType[i] == 0) then
              print ("\27[33m DEFECT: APPLINK-13603 \27[0m")
              print("application.requestType[" ..i .."] is NIL")
              result = false
            end
          end
        end

        return result

      end)

    --mobile side: RegisterAppInterface response
    EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})

    EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

    EXPECT_NOTIFICATION("OnPermissionsChange", {})

  end

end

TC_OnAppRegistered_01()

----------------------------------------------------------------------------------------------
--SDLAQ-TC-1364: TC_OnAppRegistered_02 (genivi_only)
--APPLINK-18436: 05[P][MAN]_TC_SDL_sends_optional_icon_in_OnAppRegistered_during_RAI
--Verification criteria: Check that SDL sends optional icon parameter in OnAppRegistered notification
--Note: Developed in ATF_OnAppRegistered_Genivi_Only.lua
----------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------
--SDLAQ-TC-1365: TC_OnAppRegistered_03
--APPLINK-18437: 06[P][MAN]_TC_SDL_sends_hmiDisplayLanguageDesired_in_OnAppRegistered_during_RAI
--Verification criteria: SDL sends optional hmiDisplayLanguageDesired parameter in OnAppRegistered notification.
----------------------------------------------------------------------------------------------
local function OnAppRegistered_hmiDisplayLanguageDesired()
  --Print new line to separate new test cases group
  commonFunctions:newTestCasesGroup("Test case: TC_OnAppRegistered_03/06[P][MAN]_TC_SDL_sends_hmiDisplayLanguageDesired_in_OnAppRegistered_during_RAI")

  --Preconditions: UnregisterApplication
  commonSteps:UnregisterApplication("OnAppRegistered_hmiDisplayLanguageDesired_Precondition_UnregisterApplication")

  --ToDo: shall be removed when APPLINK-24902: "Genivi: Unexpected unregistering application at resumption after closing session" is fixed
  function ReRegisterAppInterface(self)
  print("\27[31m Register application again because of APPLINK-24902: Genivi: Unexpected unregistering application at resumption after closing session.\27[0m")
  local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
  {
  syncMsgVersion =
  {
  majorVersion = 3,
  minorVersion = 0
  },
  appName = "SPT",
  isMediaApplication = true,
  languageDesired = "FR-CA",
  hmiDisplayLanguageDesired = "FR-CA",
  appID = "1234567",
  deviceInfo =
  {
  os = "Android",
  carrier = "Megafon",
  firmwareRev = "Name: Linux, Version: 3.4.0-perf",
  osVersion = "4.4.2",
  maxNumberRFCOMMPorts = 1
  }
  })
  --hmi side: expected BasicCommunication.OnAppRegistered
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
  {
  application =
  {
  appName = "SPT",
  policyAppID = "1234567",
  isMediaApplication = true,
  hmiDisplayLanguageDesired = "FR-CA"
  }
  })
  :ValidIf(function(_,data)
  --UPDATED to verify APPLINK-13603
  local result = true
  if (data.params.application.requestType ~= nil) then
  for i=1, #data.params.application.requestType do
  --print("data.params.application.requestType = " ..data.params.application.requestType[i])
  if (#data.params.application.requestType[i] == 0) then
  print ("\27[33m DEFECT: APPLINK-13603 \27[0m")
  print("application.requestType[" ..i .."] is NIL")
  result = false
  end
  end
  end
  return result
  end)

  --mobile side: RegisterAppInterface response
  EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "WRONG_LANGUAGE"})

  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

  EXPECT_NOTIFICATION("OnPermissionsChange", {})

  end

  function Test:OnAppRegistered_hmiDisplayLanguageDesired()
    local result = true
    --mobile side: RegisterAppInterface request
    local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
      {
        syncMsgVersion =
        {
          majorVersion = 3,
          minorVersion = 0
        },
        appName = "SPT",
        isMediaApplication = true,
        languageDesired = "FR-CA",
        hmiDisplayLanguageDesired = "FR-CA",
        appID = "1234567",
        deviceInfo =
        {
          os = "Android",
          carrier = "Megafon",
          firmwareRev = "Name: Linux, Version: 3.4.0-perf",
          osVersion = "4.4.2",
          maxNumberRFCOMMPorts = 1
        }
      })

    --hmi side: expected BasicCommunication.OnAppRegistered
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
      {
        application =
        {
          appName = "SPT",
          policyAppID = "1234567",
          isMediaApplication = true,
          hmiDisplayLanguageDesired = "FR-CA"
        }
      })
    --ToDo: shall be removed when APPLINK-24902: "Genivi: Unexpected unregistering application at resumption after closing session" is fixed
    :Do(function(_,data)
    local result = true
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {})
    :ValidIf(function(_,data)
    --Vald
    result = ReRegisterAppInterface(self)
    return result
    end)
    end)
    :ValidIf(function(_,data)
        local result = true
        --UPDATED to verify APPLINK-13603
        if (data.params.application.requestType ~= nil) then
          for i=1, #data.params.application.requestType do
            --print("data.params.application.requestType = " ..data.params.application.requestType[i])
            if (#data.params.application.requestType[i] == 0) then
              print ("\27[33m DEFECT: APPLINK-13603 \27[0m")
              print("application.requestType[" ..i .."] is NIL")
              result = false
            end
          end
        end
        return result
      end)

    --ToDo: shall be uncommented when APPLINK-24902: "Genivi: Unexpected unregistering application at resumption after closing session" is fixed
    --[[--mobile side: RegisterAppInterface response
    EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "WRONG_LANGUAGE"})

    EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

    EXPECT_NOTIFICATION("OnPermissionsChange", {})
    --]]
  end

end

OnAppRegistered_hmiDisplayLanguageDesired()

----------------------------------------------------------------------------------------------
--SDLAQ-TC-1366: TC_OnAppRegistered_04
--APPLINK-18438: 07[P][MAN]_TC_SDL_sends_appHMIType_in_OnAppRegistered_during_RAI
--Verification criteria: SDL sends optional appHMIType parameter in OnAppRegistered notification.
----------------------------------------------------------------------------------------------

local function OnAppRegistered_appHMIType()
  --Print new line to separate new test cases group
  commonFunctions:newTestCasesGroup("Test case: TC_OnAppRegistered_04/07[P][MAN]_TC_SDL_sends_appHMIType_in_OnAppRegistered_during_RAI")

  commonSteps:UnregisterApplication("OnAppRegistered_AppHMIType_UnregisterApplication_1")

  function Test:OnAppRegistered_AppHMIType_MEDIA_And_NAVIGATION()

    --mobile side: RegisterAppInterface request
    local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
      {
        syncMsgVersion =
        {
          majorVersion = 3,
          minorVersion = 0
        },
        appName = "SPT",
        isMediaApplication = true,
        languageDesired = "EN-US",
        hmiDisplayLanguageDesired = "EN-US",
        appID = "1234567",
        appHMIType = {"MEDIA", "NAVIGATION"},
        deviceInfo =
        {
          os = "Android",
          carrier = "Megafon",
          firmwareRev = "Name: Linux, Version: 3.4.0-perf",
          osVersion = "4.4.2",
          maxNumberRFCOMMPorts = 1
        }
      })

    --hmi side: expected BasicCommunication.OnAppRegistered
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
      {
        application =
        {
          appName = "SPT",
          policyAppID = "1234567",
          isMediaApplication = true,
          hmiDisplayLanguageDesired = "EN-US",
          appType = {"MEDIA", "NAVIGATION"}
        }
      })
    :ValidIf(function(_,data)
        local result = true
        --UPDATED to verify APPLINK-13603
        if (data.params.application.requestType ~= nil) then
          for i=1, #data.params.application.requestType do
            --print("data.params.application.requestType = " ..data.params.application.requestType[i])
            if (#data.params.application.requestType[i] == 0) then
              print ("\27[33m DEFECT: APPLINK-13603 \27[0m")
              print("application.requestType[" ..i .."] is NIL")
              result = false
            end
          end
        end

        return result
      end)

    --mobile side: RegisterAppInterface response
    EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})

    EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

    EXPECT_NOTIFICATION("OnPermissionsChange", {})

  end

  commonSteps:UnregisterApplication("OnAppRegistered_AppHMIType_UnregisterApplication_2")

  function Test:OnAppRegistered_AppHMIType_SOCIAL()

    --mobile side: RegisterAppInterface request
    local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
      {
        syncMsgVersion =
        {
          majorVersion = 3,
          minorVersion = 0
        },
        appName = "SPT",
        isMediaApplication = true,
        languageDesired = "EN-US",
        hmiDisplayLanguageDesired = "EN-US",
        appID = "1234567",
        appHMIType = {"SOCIAL"},
        deviceInfo =
        {
          os = "Android",
          carrier = "Megafon",
          firmwareRev = "Name: Linux, Version: 3.4.0-perf",
          osVersion = "4.4.2",
          maxNumberRFCOMMPorts = 1
        }
      })

    --hmi side: expected BasicCommunication.OnAppRegistered
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
      {
        application =
        {
          appName = "SPT",
          policyAppID = "1234567",
          isMediaApplication = true,
          hmiDisplayLanguageDesired = "EN-US",
          appType = {"SOCIAL"}
        }
      })
    :ValidIf(function(_,data)
        local result = true
        --UPDATED to verify APPLINK-13603
        if (data.params.application.requestType ~= nil) then
          for i=1, #data.params.application.requestType do
            --print("data.params.application.requestType = " ..data.params.application.requestType[i])
            if (#data.params.application.requestType[i] == 0) then
              print ("\27[33m DEFECT: APPLINK-13603 \27[0m")
              print("application.requestType[" ..i .."] is NIL")
              result = false
            end
          end
        end
        return result
      end)

    --mobile side: RegisterAppInterface response
    EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})

    EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

    EXPECT_NOTIFICATION("OnPermissionsChange", {})

  end

end

OnAppRegistered_appHMIType()

----------------------------------------------------------------------------------------------
--SDLAQ-TC-1425: TC_OnAppRegistered_05:
--APPLINK-18439: 08[P][MAN]_TC_SDL_sends_transportType_in_OnAppRegistered_during_RAI
--Verification criteria: SDL sends opional parameter "transportType" within mandatory "DeviceInfo" if App connected via Bluetooth.
--TODO: Waiting for solution to simulate Bluetooth transport type
----------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------
--SDLAQ-TC-1428: TC_OnAppRegistered_08
--APPLINK-18443: 12[P][MAN]_TC_SDL_sends_same_deviceID_if_WiFi
--Verification criteria: Check that SDL sends the same "deviceID" between ignition cycles in case WiFi connection.
--TODO: update after resolving APPLINK-16052
----------------------------------------------------------------------------------------------
local function TC_OnAppRegistered_08()

  --Print new line to separate new test cases group
  commonFunctions:newTestCasesGroup("Test case: TC_OnAppRegistered_08/12[P][MAN]_TC_SDL_sends_same_deviceID_if_WiFi")

  --Preconditions: Stop SDL, start SDL again, start HMI, connect to SDL, start mobile, start new session.
  StopSDL_StartSDLAgain_StartHMI_StartMobile("08")

  --Test case's body:
  local function RegisterAppInterface_Verify_OnAppRegistered_deviceID()

    function Test:RegisterAppInterface_Verify_OnAppRegistered_deviceID()

      --mobile side: RegisterAppInterface request
      local RegParams = config.application1.registerAppInterfaceParams
      local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface", RegParams)

      --hmi side: expected BasicCommunication.OnAppRegistered
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
        {
          application =
          {
            appName = RegParams.appName,
            policyAppID = RegParams.appID,
            isMediaApplication = RegParams.isMediaApplication,
            hmiDisplayLanguageDesired = RegParams.hmiDisplayLanguageDesired,
            --TODO: update after resolving APPLINK-16052
            deviceInfo =
            {
              name = "127.0.0.1",
              id = config.deviceMAC,
              transportType = "WIFI",
              isSDLAllowed = false
            },
            appType = RegParams.appHMIType
          }
        })
      :ValidIf(function(_,data)
          local result = true

          if data.params.application.deviceInfo.name ~= "127.0.0.1" then
            commonFunctions:printError(" Device name parameter value is "..tostring(data.params.application.deviceInfo.name)..", expected 127.0.0.1")
            result = false
          end

          if data.params.application.deviceInfo.id ~= config.deviceMAC then
            commonFunctions:printError(" Device ID parameter value is "..tostring(data.params.application.deviceInfo.id)..", expected " ..config.deviceMAC)
            result = false
          end

          if data.params.application.deviceInfo.transportType ~= "WIFI" then
            commonFunctions:printError(" transportType parameter value is "..tostring(data.params.application.deviceInfo.transportType)..", expected WIFI")
            result = false
          end

          --UPDATED: according to APPLINK-24148
          --FORD-SPECIFIC
          if data.params.application.deviceInfo.isSDLAllowed ~= false then
            commonFunctions:printError(" isSDLAllowed parameter value is "..tostring(data.params.application.deviceInfo.isSDLAllowed)..", expected false")
            result = false
          end
          --Genivi
          -- if data.params.application.deviceInfo.isSDLAllowed ~= true then
          -- commonFunctions:printError(" isSDLAllowed parameter value is "..tostring(data.params.application.deviceInfo.isSDLAllowed)..", expected true")
          -- result = false
          -- end

          --UPDATED to verify APPLINK-13603
          if (data.params.application.requestType ~= nil) then
            for i=1, #data.params.application.requestType do
              --print("data.params.application.requestType = " ..data.params.application.requestType[i])
              if (#data.params.application.requestType[i] == 0) then
                print ("\27[33m DEFECT: APPLINK-13603 \27[0m")
                print("application.requestType[" ..i .."] is NIL")
                result = false
              end
            end
          end

          return result

        end)

      --mobile side: RegisterAppInterface response
      EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})

      EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

      EXPECT_NOTIFICATION("OnPermissionsChange", {})

    end

  end

  RegisterAppInterface_Verify_OnAppRegistered_deviceID()

  function Test:Ignition_Off()

    --hmi side: send notification
    local RegParams = config.application1.registerAppInterfaceParams
    self.hmiConnection:SendNotification("BasicCommunication.OnIgnitionCycleOver", {})
    self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {reason = "IGNITION_OFF"})
    self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications[RegParams.appName], reason = "GENERAL"})
    self.hmiConnection:SendNotification("BasicCommunication.OnFindApplications", {})

    --hmi side: expect notification
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications[RegParams.appName], unexpectedDisconnect = false})
    EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose", {})

    --mobile side: expected notification
    EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", {reason = "IGNITION_OFF"})

  end

  Ignition_On("08")

  RegisterAppInterface_Verify_OnAppRegistered_deviceID()

end

TC_OnAppRegistered_08()

----------------------------------------------------------------------------------------------
--SDLAQ-TC-1429: TC_OnAppRegistered_09
--APPLINK-18446: 15[P][MAN]_TC_SDL_sends_appD_as_policyAppID
--Verification criteria: SDL sends appID from RegisterAppInteface request in OnAppRegistered notification to HMI as"policyAppID" parameter.
----------------------------------------------------------------------------------------------
local function TC_OnAppRegistered_09()

  --Print new line to separate new test cases group
  commonFunctions:newTestCasesGroup("Test case: TC_OnAppRegistered_09/15[P][MAN]_TC_SDL_sends_appD_as_policyAppID")

  --Preconditions: Stop SDL, start SDL again, start HMI, connect to SDL, start mobile, start new session.
  StopSDL_StartSDLAgain_StartHMI_StartMobile("09_1")

  --Test case's body:

  --1. Register App with appID 584421907
  function Test:RegisterAppInterface_App1_And_Verify_OnAppRegistered_policyAppID()

    --mobile side: RegisterAppInterface request
    local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface", {
        syncMsgVersion =
        {
          majorVersion = 3,
          minorVersion = 0
        },
        appName = "App1",
        isMediaApplication = false,
        languageDesired = 'EN-US',
        hmiDisplayLanguageDesired = 'EN-US',
        appHMIType = { "DEFAULT" },
        appID = "584421907",
        deviceInfo =
        {
          os = "Android",
          carrier = "Megafon",
          firmwareRev = "Name: Linux, Version: 3.4.0-perf",
          osVersion = "4.4.2",
          maxNumberRFCOMMPorts = 1
        }
      })

    --hmi side: expected BasicCommunication.OnAppRegistered
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
      {
        application =
        {
          appName = "App1",
          policyAppID = "584421907"
        }
      })
    :ValidIf(function(_,data)
        local result = true
        if data.params.application.appID == nil or type(data.params.application.appID) ~= "number" then
          commonFunctions:printError("OnAppRegistered notification came with appID parameter is nil or not a number")
          result = false
        else
          self.applications["App1"] = data.params.application.appID
          --return true
        end

        --UPDATED to verify APPLINK-13603
        if (data.params.application.requestType ~= nil) then
          for i=1, #data.params.application.requestType do
            --print("data.params.application.requestType = " ..data.params.application.requestType[i])
            if (#data.params.application.requestType[i] == 0) then
              print ("\27[33m DEFECT: APPLINK-13603 \27[0m")
              print("application.requestType[" ..i .."] is NIL")
              result = false
            end
          end
        end

        return result
      end)

    --mobile side: RegisterAppInterface response
    EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})

    EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

    EXPECT_NOTIFICATION("OnPermissionsChange", {})

  end

  --2. Register App with appID FORD
  function Test:AddSession2()

    self.mobileSession2 = mobile_session.MobileSession(self,self.mobileConnection)

    self.mobileSession2:StartService(7)

  end

  function Test:RegisterAppInterface_App2_And_Verify_OnAppRegistered_policyAppID()

    --mobile side: RegisterAppInterface request
    local CorIdRAI = self.mobileSession2:SendRPC("RegisterAppInterface", {
        syncMsgVersion =
        {
          majorVersion = 3,
          minorVersion = 0
        },
        appName = "App2",
        isMediaApplication = false,
        languageDesired = 'EN-US',
        hmiDisplayLanguageDesired = 'EN-US',
        appHMIType = { "DEFAULT" },
        appID = "FORD",
        deviceInfo =
        {
          os = "Android",
          carrier = "Megafon",
          firmwareRev = "Name: Linux, Version: 3.4.0-perf",
          osVersion = "4.4.2",
          maxNumberRFCOMMPorts = 1
        }
      })

    --hmi side: expected BasicCommunication.OnAppRegistered
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
      {
        application =
        {
          appName = "App2",
          policyAppID = "FORD"
        }
      })
    :ValidIf(function(_,data)
        local result = true

        if data.params.application.appID == nil or type(data.params.application.appID) ~= "number" then
          commonFunctions:printError("OnAppRegistered notification came with appID parameter is nil or not a number")
          result = false
        else
          self.applications["App2"] = data.params.application.appID
          --return true
        end

        --UPDATED to verify APPLINK-13603
        if (data.params.application.requestType ~= nil) then
          for i=1, #data.params.application.requestType do
            --print("data.params.application.requestType = " ..data.params.application.requestType[i])
            if (#data.params.application.requestType[i] == 0) then
              print ("\27[33m DEFECT: APPLINK-13603 \27[0m")
              print("application.requestType[" ..i .."] is NIL")
              result = false
            end
          end
        end

        return result
      end)

    --mobile side: RegisterAppInterface response
    self.mobileSession2:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})

    self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    self.mobileSession2:ExpectNotification("OnPermissionsChange", {})

  end

  --3. On the phone exit from App with appID 584421907
  function Test:MobileCloseSession1_And_Verify_OnAppUnregistered()
    --Exit app on the first session
    local cid = self.mobileSession:SendRPC("UnregisterAppInterface",{})

    --hmi side: expect BasicCommunication.OnAppUnregistered
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications["App1"], unexpectedDisconnect = false})

    --mobile side: expects UnregisterAppInterface response
    EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})

  end

  --4. Register App with appID 584421907
  function Test:AddSession3()

    self.mobileSession3 = mobile_session.MobileSession(self,self.mobileConnection)

    self.mobileSession3:StartService(7)

  end

  function Test:RegisterAppInterface_App1_Again_And_Verify_OnAppRegistered_policyAppID_2()

    --mobile side: RegisterAppInterface request
    local CorIdRAI = self.mobileSession3:SendRPC("RegisterAppInterface", {
        syncMsgVersion =
        {
          majorVersion = 3,
          minorVersion = 0
        },
        appName = "App1",
        isMediaApplication = false,
        languageDesired = 'EN-US',
        hmiDisplayLanguageDesired = 'EN-US',
        appHMIType = { "DEFAULT" },
        appID = "584421907",
        deviceInfo =
        {
          os = "Android",
          carrier = "Megafon",
          firmwareRev = "Name: Linux, Version: 3.4.0-perf",
          osVersion = "4.4.2",
          maxNumberRFCOMMPorts = 1
        }
      })

    --hmi side: expected BasicCommunication.OnAppRegistered
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
      {
        application =
        {
          appName = "App1",
          policyAppID = "584421907"
        }
      })
    :ValidIf(function(_,data)
        local result = true
        if data.params.application.appID == nil or type(data.params.application.appID) ~= "number" then
          commonFunctions:printError("OnAppRegistered notification came with appID parameter is nil or not a number")
          result = false
        else
          self.applications["App1"] = data.params.application.appID
          result = true
        end

        --UPDATED to verify APPLINK-13603
        if (data.params.application.requestType ~= nil) then
          for i=1, #data.params.application.requestType do
            --print("data.params.application.requestType = " ..data.params.application.requestType[i])
            if (#data.params.application.requestType[i] == 0) then
              print ("\27[33m DEFECT: APPLINK-13603 \27[0m")
              print("application.requestType[" ..i .."] is NIL")
              result = false
            end
          end
        end

        return result

      end)

    --mobile side: RegisterAppInterface response
    self.mobileSession3:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})

    self.mobileSession3:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    self.mobileSession3:ExpectNotification("OnPermissionsChange", {})

  end

  --5. On the phone exit from App with appID FORD
  function Test:MobileCloseConnection_Verify_OnAppUnregistered()

    --Exit app on the first session
    local cid = self.mobileSession2:SendRPC("UnregisterAppInterface",{})

    --hmi side: expect BasicCommunication.OnAppUnregistered
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications["App2"], unexpectedDisconnect = false})

    --mobile side: expects UnregisterAppInterface response
    self.mobileSession2:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})

  end

  --6. Register App with appID FORD
  function Test:StartSession4()

    self.mobileSession4 = mobile_session.MobileSession(self,self.mobileConnection)

    self.mobileSession4:StartService(7)
  end

  function Test:RegisterAppInterface_App2_And_Verify_OnAppRegistered_policyAppID_2()

    --mobile side: RegisterAppInterface request
    local CorIdRAI = self.mobileSession4:SendRPC("RegisterAppInterface", {
        syncMsgVersion =
        {
          majorVersion = 3,
          minorVersion = 0
        },
        appName = "App2",
        isMediaApplication = false,
        languageDesired = 'EN-US',
        hmiDisplayLanguageDesired = 'EN-US',
        appHMIType = { "DEFAULT" },
        appID = "FORD",
        deviceInfo =
        {
          os = "Android",
          carrier = "Megafon",
          firmwareRev = "Name: Linux, Version: 3.4.0-perf",
          osVersion = "4.4.2",
          maxNumberRFCOMMPorts = 1
        }
      })

    --hmi side: expected BasicCommunication.OnAppRegistered
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
      {
        application =
        {
          appName = "App2",
          policyAppID = "FORD"
        }
      })
    :ValidIf(function(_,data)
        local result = true
        if data.params.application.appID == nil or type(data.params.application.appID) ~= "number" then
          commonFunctions:printError("OnAppRegistered notification came with appID parameter is nil or not a number")
          result = false
        else
          self.applications["App2"] = data.params.application.appID
          --return true
        end

        --UPDATED to verify APPLINK-13603
        if (data.params.application.requestType ~= nil) then
          for i=1, #data.params.application.requestType do
            --print("data.params.application.requestType = " ..data.params.application.requestType[i])
            if (#data.params.application.requestType[i] == 0) then
              print ("\27[33m DEFECT: APPLINK-13603 \27[0m")
              print("application.requestType[" ..i .."] is NIL")
              result = false
            end
          end
        end

        return result
      end)

    --mobile side: RegisterAppInterface response
    self.mobileSession4:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})

    self.mobileSession4:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    self.mobileSession4:ExpectNotification("OnPermissionsChange", {})

  end

  --7. Make ignition off/on => During registration of Apps on start, policyAppID parameters should be the same as appID from RegisterAppInterface

  function Test:Ignition_Off()

    --hmi side: send notification
    self.hmiConnection:SendNotification("BasicCommunication.OnIgnitionCycleOver", {})
    self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {reason = "IGNITION_OFF"})
    self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["App1"], reason = "GENERAL"})
    self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["App2"], reason = "GENERAL"})

    self.hmiConnection:SendNotification("BasicCommunication.OnFindApplications", {})

    --hmi side: expect notification
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered",
      {appID = self.applications["Test Application"], unexpectedDisconnect = false},
      {appID = self.applications["Test Application"], unexpectedDisconnect = false})
    :Times(2)

    EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose", {})

    --mobile side: expected notification
    self.mobileSession3:ExpectNotification("OnAppInterfaceUnregistered", {reason = "IGNITION_OFF"})
    self.mobileSession4:ExpectNotification("OnAppInterfaceUnregistered", {reason = "IGNITION_OFF"})

  end

  --Stop SDL, start SDL again, start HMI, connect to SDL, start mobile, start new session.
  StopSDL_StartSDLAgain_StartHMI_StartMobile("09_2")

  --Register App with appID 584421907
  function Test:AddSession3()

    self.mobileSession3 = mobile_session.MobileSession(self,self.mobileConnection)

    self.mobileSession3:StartService(7)

  end

  function Test:RegisterAppInterface_App1_Again_And_Verify_OnAppRegistered_policyAppID_3()

    --mobile side: RegisterAppInterface request
    local CorIdRAI = self.mobileSession3:SendRPC("RegisterAppInterface", {
        syncMsgVersion =
        {
          majorVersion = 3,
          minorVersion = 0
        },
        appName = "App1",
        isMediaApplication = false,
        languageDesired = 'EN-US',
        hmiDisplayLanguageDesired = 'EN-US',
        appHMIType = { "DEFAULT" },
        appID = "584421907",
        deviceInfo =
        {
          os = "Android",
          carrier = "Megafon",
          firmwareRev = "Name: Linux, Version: 3.4.0-perf",
          osVersion = "4.4.2",
          maxNumberRFCOMMPorts = 1
        }
      })

    --hmi side: expected BasicCommunication.OnAppRegistered
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
      {
        application =
        {
          appName = "App1",
          policyAppID = "584421907"
        }
      })
    :ValidIf(function(_,data)
        local result = true
        if data.params.application.appID == nil or type(data.params.application.appID) ~= "number" then
          commonFunctions:printError("OnAppRegistered notification came with appID parameter is nil or not a number")
          result = false
        else
          self.applications["App1"] = data.params.application.appID
          --result = true
        end

        --UPDATED to verify APPLINK-13603
        if (data.params.application.requestType ~= nil) then
          for i=1, #data.params.application.requestType do
            --print("data.params.application.requestType = " ..data.params.application.requestType[i])
            if (#data.params.application.requestType[i] == 0) then
              print ("\27[33m DEFECT: APPLINK-13603 \27[0m")
              print("application.requestType[" ..i .."] is NIL")
              result = false
            end
          end
        end

        return result

      end)

    --mobile side: RegisterAppInterface response
    self.mobileSession3:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})

    self.mobileSession3:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    self.mobileSession3:ExpectNotification("OnPermissionsChange", {})

  end

  --Register App with appID FORD
  function Test:StartSession4()

    self.mobileSession4 = mobile_session.MobileSession(self,self.mobileConnection)

    self.mobileSession4:StartService(7)
  end

  function Test:RegisterAppInterface_App2_And_Verify_OnAppRegistered_policyAppID_3()

    --mobile side: RegisterAppInterface request
    local CorIdRAI = self.mobileSession4:SendRPC("RegisterAppInterface", {
        syncMsgVersion =
        {
          majorVersion = 3,
          minorVersion = 0
        },
        appName = "App2",
        isMediaApplication = false,
        languageDesired = 'EN-US',
        hmiDisplayLanguageDesired = 'EN-US',
        appHMIType = { "DEFAULT" },
        appID = "FORD",
        deviceInfo =
        {
          os = "Android",
          carrier = "Megafon",
          firmwareRev = "Name: Linux, Version: 3.4.0-perf",
          osVersion = "4.4.2",
          maxNumberRFCOMMPorts = 1
        }
      })

    --hmi side: expected BasicCommunication.OnAppRegistered
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
      {
        application =
        {
          appName = "App2",
          policyAppID = "FORD"
        }
      })
    :ValidIf(function(_,data)
        local result = true
        if data.params.application.appID == nil or type(data.params.application.appID) ~= "number" then
          commonFunctions:printError("OnAppRegistered notification came with appID parameter is nil or not a number")
          result = false
        else
          self.applications["App2"] = data.params.application.appID
          --return true
        end

        --UPDATED to verify APPLINK-13603
        if (data.params.application.requestType ~= nil) then
          for i=1, #data.params.application.requestType do
            --print("data.params.application.requestType = " ..data.params.application.requestType[i])
            if (#data.params.application.requestType[i] == 0) then
              print ("\27[33m DEFECT: APPLINK-13603 \27[0m")
              print("application.requestType[" ..i .."] is NIL")
              result = false
            end
          end
        end
        return result
      end)

    --mobile side: RegisterAppInterface response
    self.mobileSession4:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})

    self.mobileSession4:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    self.mobileSession4:ExpectNotification("OnPermissionsChange", {})

  end

end

TC_OnAppRegistered_09()

----------------------------------------------------------------------------------------------
--SDLAQ-TC-1464: TC_OnAppRegistered_13
--APPLINK-18447: 16[P][MAN]_TC_SDL_sends_diff_deviceID_ if_MAC_address_of_device_changed
--Verification criteria: SDL sends the different "deviceID" between ignition cycles in case WiFi connection, if MAC address of WiFi device was changed during IGNITION_OFF.

--Note: Purpose of this test case is verify id (deviceID) parameter of UpdateDeviceList request. This test case should be checked in ATF_UpdateDeviceList.lua with other cases: empty, wrongtype, invalid,..
----------------------------------------------------------------------------------------------

function Test:Postcondition_StopSDL_IfItIsStillRunning()
  print("----------------------------------------------------------------------------------------------")
  StopSDL()
end

return Test
