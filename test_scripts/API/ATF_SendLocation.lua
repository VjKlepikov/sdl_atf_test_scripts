-- ATF version: 2.2
--------------------------------------------------------------------------------
-- Preconditions
local Preconditions = require('user_modules/shared_testcases/commonPreconditions')
Preconditions:Connecttest_without_ExitBySDLDisconnect("connecttest_sendLocation.lua")
--------------------------------------------------------------------------------
Test = require('user_modules/connecttest_sendLocation')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection = require('file_connection')
local config = require('config')
local json = require('json')
local module = require('testbase')
---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local stringParameter = require('user_modules/shared_testcases/testCasesForStringParameter')
local enumerationParameter = require('user_modules/shared_testcases/testCasesForEnumerationParameter')
local imageParameter = require('user_modules/shared_testcases/testCasesForImageParameter')
local arraySoftButtonsParameter = require('user_modules/shared_testcases/testCasesForArraySoftButtonsParameter')
local arrayStringParameter = require('user_modules/shared_testcases/testCasesForArrayStringParameter')
local integerParameter = require('user_modules/shared_testcases/testCasesForIntegerParameter')
local floatParamter = require('user_modules/shared_testcases/testCasesForFloatParameter')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
----------------------------------------------------------------------------
-- User required files
require('user_modules/AppTypes')
local SDLConfig = require('user_modules/shared_testcases/SmartDeviceLinkConfigurations')
---------------------------------------------------------------------------------------------
------------------------------------ Common Variables ---------------------------------------
---------------------------------------------------------------------------------------------
APIName = "SendLocation" -- set request name
strMaxLengthFileName255 = string.rep("a", 251) .. ".png" -- set max length file name
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
local STORAGE_PATH = config.pathToSDL .. SDLConfig:GetValue("AppStorageFolder") .. "/" .. tostring(config.application1.registerAppInterfaceParams.appID .. "_" .. tostring(config.deviceMAC) .. "/")
---------------------------------------------------------------------------------------------
-------------------------- Overwrite These Functions For This Script-------------------------
---------------------------------------------------------------------------------------------
-- Specific functions for this script
-- 1. createRequest()
-- 2. createUIParameters(RequestParams)
-- 3. verify_SUCCESS_Case(RequestParams)
-- 4. verify_INVALID_DATA_Case(RequestParams)
---------------------------------------------------------------------------------------------
-- Create default request parameters
function Test:createRequest()
  return {
    longitudeDegrees = 1.1,
    latitudeDegrees = 1.1
  }
end
---------------------------------------------------------------------------------------------
-- Create UI expected result based on parameters from the request
function Test:createUIParameters(RequestParams)
  local param = {}
  if RequestParams["locationImage"] ~= nil then
    param["locationImage"] = RequestParams["locationImage"]
    if param["locationImage"].imageType == "DYNAMIC" then
      param["locationImage"].value = STORAGE_PATH .. param["locationImage"].value
    end
  end
  if RequestParams["longitudeDegrees"] ~= nil then
    param["longitudeDegrees"] = RequestParams["longitudeDegrees"]
  end
  if RequestParams["latitudeDegrees"] ~= nil then
    param["latitudeDegrees"] = RequestParams["latitudeDegrees"]
  end
  if RequestParams["locationName"] ~= nil then
    param["locationName"] = RequestParams["locationName"]
  end
  if RequestParams["locationDescription"] ~= nil then
    param["locationDescription"] = RequestParams["locationDescription"]
  end
  if RequestParams["addressLines"] ~= nil then
    param["addressLines"] = RequestParams["addressLines"]
  end
  if RequestParams["deliveryMode"] ~= nil then
    param["deliveryMode"] = RequestParams["deliveryMode"]
  end
  if RequestParams["phoneNumber"] ~= nil then
    param["phoneNumber"] = RequestParams["phoneNumber"]
  end
  if RequestParams["address"] ~= nil then
    local addressParams = {"countryName", "countryCode", "postalCode", "administrativeArea", "subAdministrativeArea", "locality", "subLocality", "thoroughfare", "subThoroughfare"}
    local parameterFind = false
    param.address = {}
    for i=1, #addressParams do
      if RequestParams.address[addressParams[i]] ~= nil then
        param.address[addressParams[i]] = RequestParams.address[addressParams[i]]
        parameterFind = true
      end
    end
    if
    parameterFind == false then
      param.address = nil
    end
  end
  if RequestParams["timeStamp"] ~= nil then
    param.timeStamp = {}
    local timeStampParams = {"millisecond","second", "minute", "hour", "day", "month", "year", "tz_hour", "tz_minute"}
    for i=1, #timeStampParams do
      if
      RequestParams.timeStamp[timeStampParams[i]] ~= nil then
        param.timeStamp[timeStampParams[i]] = RequestParams.timeStamp[timeStampParams[i]]
      else
        if RequestParams.timeStamp["tz_hour"] == nil then
          param.timeStamp["tz_hour"] = 0
        end
        if RequestParams.timeStamp["tz_minute"] == nil then
          param.timeStamp["tz_minute"] = 0
        end
      end
    end
  end
  return param
end
---------------------------------------------------------------------------------------------
-- This function sends a request from mobile and verify result on HMI and mobile for SUCCESS resultCode cases.
function Test:verify_SUCCESS_Case(RequestParams)
  local temp = json.encode(RequestParams)
  local cid = 0
  if string.find(temp, "{}") ~= nil or string.find(temp, "{{}}") ~= nil then
    temp = string.gsub(temp, "{}", "[]")
    temp = string.gsub(temp, "{{}}", "[{}]")
    if string.find(temp, "\"address\":%[%]") ~= nil then
      temp = string.gsub(temp, "\"address\":%[%]", "\"address\":{}")
    end
    if string.find(temp, "\"timeStamp\":%[%]") ~= nil then
      temp = string.gsub(temp, "\"timeStamp\":%[%]", "\"timeStamp\":{}")
    end
    self.mobileSession.correlationId = self.mobileSession.correlationId + 1
    cid = self.mobileSession.correlationId
    local msg =
    {
      serviceType = 7,
      frameInfo = 0,
      rpcType = 0,
      rpcFunctionId = 39,
      rpcCorrelationId = cid,
      payload = temp
    }
    self.mobileSession:Send(msg)
  else
    -- mobile side: sending SendLocation request
    cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
  end
  UIParams = self:createUIParameters(RequestParams)
  if
  RequestParams.longitudeDegrees and
  RequestParams.latitudeDegrees and
  RequestParams.address == {} then
    -- hmi side: expect Navigation.SendLocation request
    EXPECT_HMICALL("Navigation.SendLocation", UIParams)
    :Do(function(_,data)
      -- hmi side: sending Navigation.SendLocation response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    :ValidIf(function(_,data)
      if data.params.address then
        commonFunctions:userPrint(31,"Navigation.SendLocation contain address parameter in request when should be omitted")
        return false
      else
        return true
      end
    end)
  else
    -- hmi side: expect Navigation.SendLocation request
    EXPECT_HMICALL("Navigation.SendLocation", UIParams)
    :Do(function(_,data)
      -- hmi side: sending Navigation.SendLocation response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  end
  -- mobile side: expect SendLocation response
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
end
---------------------------------------------------------------------------------------------
-- This function sends a request from mobile with INVALID_DATA and verify result on mobile.
function Test:verify_INVALID_DATA_Case(RequestParams)
  local temp = json.encode(RequestParams)
  local cid = 0
  if string.find(temp, "{}") ~= nil or string.find(temp, "{{}}") ~= nil then
    temp = string.gsub(temp, "{}", "[]")
    temp = string.gsub(temp, "{{}}", "[{}]")
    if string.find(temp, "\"address\":%[%]") ~= nil then
      temp = string.gsub(temp, "\"address\":%[%]", "\"address\":{}")
    end
    self.mobileSession.correlationId = self.mobileSession.correlationId + 1
    cid = self.mobileSession.correlationId
    local msg =
    {
      serviceType = 7,
      frameInfo = 0,
      rpcType = 0,
      rpcFunctionId = 39,
      rpcCorrelationId = cid,
      payload = temp
    }
    self.mobileSession:Send(msg)
  else
    -- mobile side: sending SendLocation request
    cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
  end
  -- mobile side: expect SendLocation response
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
end
---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
-- Precondition for SendLocation script execution: Because of APPLINK-17511 SDL defect hmi_capabilities.json need to be updated : added textfields locationName, locationDescription, addressLines, phoneNumber.
--------------------------------------------------------------------------------------------------------
-- Precondition function is added needed fields.
-- TODO: need to be removed after resolving APPLINK-17511
-- 1. Precondition: deleting logs, policy table
commonSteps:DeleteLogsFileAndPolicyTable()

-- 2. Verify config.pathToSDL
commonSteps:CheckSDLPath()

-- 3. Update hmi_capabilities.json
local HmiCapabilities = config.pathToSDL .. "hmi_capabilities.json"
Preconditions:BackupFile("hmi_capabilities.json")
f = assert(io.open(HmiCapabilities, "r"))
fileContent = f:read("*all")
fileContentTextFields = fileContent:match("%s-\"%s?textFields%s?\"%s-:%s-%[[%w%d%s,:%{%}\"]+%]%s-,?")
if not fileContentTextFields then
  print ( " \27[31m textFields is not found in hmi_capabilities.json \27[0m " )
else
  fileContentTextFieldsContant = fileContent:match("%s-\"%s?textFields%s?\"%s-:%s-%[([%w%d%s,:%{%}\"]+)%]%s-,?")
  if not fileContentTextFieldsContant then
    print ( " \27[31m textFields contant is not found in hmi_capabilities.json \27[0m " )
  else
    fileContentTextFieldsContantTab = fileContent:match("%s-\"%s?textFields%s?\"%s-:%s-%[.+%{\n([^\n]+)(\"name\")")
    local StringToReplace = fileContentTextFieldsContant
    fileContentLocationNameFind = fileContent:match("locationName")
    if not fileContentLocationNameFind then
      local ContantToAdd = ",\n " .. tostring(fileContentTextFieldsContantTab) .. " { \"name\": \"locationName\",\"characterSet\": \"TYPE2SET\",\"width\": 500,\"rows\": 1 }"
      StringToReplace = StringToReplace .. ContantToAdd
    end
    fileContentLocationDescriptionFind = fileContent:match("locationDescription")
    if not fileContentLocationDescriptionFind then
      local ContantToAdd = ",\n " .. tostring(fileContentTextFieldsContantTab) .. " { \"name\": \"locationDescription\",\"characterSet\": \"TYPE2SET\",\"width\": 500,\"rows\": 1 }"
      StringToReplace = StringToReplace .. ContantToAdd
    end
    fileContentAddressLinesFind = fileContent:match("addressLines")
    if not fileContentAddressLinesFind then
      local ContantToAdd = ",\n " .. tostring(fileContentTextFieldsContantTab) .. " { \"name\": \"addressLines\",\"characterSet\": \"TYPE2SET\",\"width\": 500,\"rows\": 1 }"
      StringToReplace = StringToReplace .. ContantToAdd
    end
    fileContentPhoneNumberFind = fileContent:match("phoneNumber")
    if not fileContentPhoneNumberFind then
      local ContantToAdd = ",\n " .. tostring(fileContentTextFieldsContantTab) .. " { \"name\": \"phoneNumber\",\"characterSet\": \"TYPE2SET\",\"width\": 500,\"rows\": 1 }"
      StringToReplace = StringToReplace .. ContantToAdd
    end
    fileContentUpdated = string.gsub(fileContent, fileContentTextFieldsContant, StringToReplace)
    f = assert(io.open(HmiCapabilities, "w"))
    f:write(fileContentUpdated)
    f:close()
  end
end
--------------------------------------------------------------------------------------------------------
-- Postcondition: removing user_modules/connecttest_sendLocation.lua, restore hmi_capabilities
function Test:Postcondition_remove_user_connecttest_restore_hmi_capabilities()
  os.execute( "rm -f ./user_modules/connecttest_sendLocation.lua" )
  Preconditions:RestoreFile("hmi_capabilities.json")
end
--------------------------------------------------------------------------------------------------------
-- 4. Activate application
commonSteps:ActivationApp()

-- 5. PutFiles ("a", "icon.png", "action.png", strMaxLengthFileName255)
commonSteps:PutFile( "PutFile_MinLength", "a")
commonSteps:PutFile( "PutFile_icon.png", "icon.png")
commonSteps:PutFile( "PutFile_action.png", "action.png")
commonSteps:PutFile( "PutFile_MaxLength_255Characters", strMaxLengthFileName255)

-- 6. UpdatePolicy
policyTable:precondition_updatePolicy_AllowFunctionInHmiLeves({"BACKGROUND", "FULL", "LIMITED"})
-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK I----------------------------------------
--------------------------------Check normal cases of Mobile request---------------------------
-----------------------------------------------------------------------------------------------
-- Requirement id in JAMA or JIRA:
-- APPLINK-9735
-- APPLINK-16076
-- APPLINK-21923
-- APPLINK-21924
-- APPLINK-16133
-- APPLINK-16118
-- APPLINK-16115
-- APPLINK-16110
-- APPLINK-21925
-- APPLINK-16109
-- APPLINK-21909
-- APPLINK-21910
-- APPLINK-24180
-- APPLINK-24215
-- Verification criteria:
-- 1. Verify request with valid and invalid values of parameters;
-- 2. SDL must treat integer value for params of float type as valid
-- 3. In case mobile app sends SendLocation_request to SDL with "address" parameter and without both "longitudeDegrees" and "latitudeDegrees" parameters with any others params related to request SDL must: consider such request as invalid and responds INVALID_DATA, success: false to mobile app
-- 4. In case mobile app sends SendLocation_request to SDL with "address" parameter and without both "longitudeDegrees" and "latitudeDegrees" parameters with any others params related to request SDL must: consider such request as invalid and responds INVALID_DATA, success: false to mobile app
-- 5. In case the request comes to SDL with empty value"" in "String" type parameters (including parameters of the structures), SDL must respond with resultCode "INVALID_DATA" and success:"false" value.
-- 6. In case the request comes to SDL with wrong type parameters (including parameters of the structures), SDL must respond with resultCode "INVALID_DATA" and success:"false" value.
-- 7. In case the request comes without parameters defined as mandatory in mobile API, SDL must respond with resultCode "INVALID_DATA" and success:"false" value.
-- 8. In case the request comes to SDL with out-of-bounds array ranges or out-of-bounds parameters values (including parameters of the structures) of any type, SDL must respond with resultCode "INVALID_DATA" and success:"false" value.
-- 9. In case mobile app sends SendLocation_request to SDL with OR without "address" parameter and with just "longitudeDegrees" OR with just "latitudeDegrees" parameters with any others params related to request SDL must: respond "INVALID_DATA, success:false" to mobile app
-- 10. In case the request comes with '\n' and-or '\t' and-or 'whitespace'-as-the-only-symbol(s) at any "String" type parameter in the request structure, SDL must respond with resultCode "INVALID_DATA" and success:"false" value.
-----------------------------------------------------------------------------------------------
-- List of parameters in the request:
-- 1. name="longitudeDegrees" type="Float" minvalue="-180" maxvalue="180" mandatory="true"
-- 2. name="latitudeDegrees" type="Float" minvalue="-90" maxvalue="90" mandatory="true"
-- 3. name="locationName" type="String" maxlength="500" mandatory="false"
-- 4. name="locationDescription" type="String" maxlength="500" mandatory="false"
-- 5. name="addressLines" type="String" maxlength="500" minsize="0" maxsize="4" array="true" mandatory="false"
-- 6. name="phoneNumber" type="String" maxlength="500" mandatory="false"
-- 7. name="locationImage" type="Image" mandatory="false"
-- 8. name="timeStamp" type="DateTime" mandatory="false"
-- 9. name="address" type="OASISAddress" mandatory="false"
-----------------------------------------------------------------------------------------------
-- Common Test cases:
-- 1. All parameters are lower bound
-- 2. All parameters are upper bound
-- 3. Mandatory only
-- 4. Check for each params
-----------------------------------------------------------------------------------------------
-- Description: longitudeDegrees and latitudeDegress are integer value
local Request = {
  longitudeDegrees = 1,
  latitudeDegrees = 1,
  address = {
    countryName = "countryName",
    countryCode = "countryCode",
    postalCode = "postalCode",
    administrativeArea = "administrativeArea",
    subAdministrativeArea = "subAdministrativeArea",
    locality = "locality",
    subLocality = "subLocality",
    thoroughfare = "thoroughfare",
    subThoroughfare = "subThoroughfare"
  },
  timeStamp = {
    millisecond = 20,
    second = 40,
    minute = 30,
    hour = 14,
    day = 25,
    month = 5,
    year = 2017,
    tz_hour = 5,
    tz_minute = 30
  },
  locationName = "location Name",
  locationDescription = "location Description",
  addressLines =
  {
    "line1",
    "line2",
  },
  phoneNumber = "phone Number",
  deliveryMode = "PROMPT",
  locationImage =
  {
    value = "icon.png",
    imageType = "DYNAMIC",
  }
}
function Test:SendLocation_Positive_IntDeegrees()
  self:verify_SUCCESS_Case(Request)
end
-- Description: All params are lower bound value
local Request = {
  longitudeDegrees = -179.9,
  latitudeDegrees = -89.9,
  address = {
    countryName = "c",
    countryCode = "c",
    postalCode = "p",
    administrativeArea = "a",
    subAdministrativeArea = "s",
    locality = "l",
    subLocality = "s",
    thoroughfare = "t",
    subThoroughfare = "s"
  },
  timeStamp = {
    millisecond = 0,
    second = 0,
    minute = 0,
    hour = 0,
    day = 1,
    month = 1,
    year = 0,
    tz_hour = -12,
    tz_minute = 0
  },
  locationName ="a",
  locationDescription ="a",
  addressLines = {},
  phoneNumber ="a",
  deliveryMode = "PROMPT",
  locationImage =
  {
    value ="a",
    imageType ="DYNAMIC",
  }
}
function Test:SendLocation_LowerBound()
  self:verify_SUCCESS_Case(Request)
end
-- Description: longitudeDegrees and latitudeDegress are lower integer value
local Request = {
  longitudeDegrees = -180,
  latitudeDegrees = -90,
  address = {
    countryName = "c",
    countryCode = "c",
    postalCode = "p",
    administrativeArea = "a",
    subAdministrativeArea = "s",
    locality = "l",
    subLocality = "s",
    thoroughfare = "t",
    subThoroughfare = "s"
  },
  timeStamp = {
    millisecond = 0,
    second = 0,
    minute = 0,
    hour = 0,
    day = 25,
    month = 5,
    year = 0,
    tz_hour = -12,
    tz_minute = 0
  },
  locationName ="a",
  locationDescription ="a",
  addressLines = {},
  phoneNumber ="a",
  deliveryMode = "PROMPT",
  locationImage =
  {
    value ="a",
    imageType ="DYNAMIC",
  }
}
function Test:SendLocation_LowerBound_IntDeegrees()
  self:verify_SUCCESS_Case(Request)
end
-- Description: All params are upper values except longitudeDegrees and latitudeDegrees
local Request = {
  longitudeDegrees = 179.9,
  latitudeDegrees = 89.9,
  address = {
    countryName = string.rep("a", 200),
    countryCode = string.rep("a", 200),
    postalCode = string.rep("a", 200),
    administrativeArea = string.rep("a", 200),
    subAdministrativeArea = string.rep("a", 200),
    locality = string.rep("a", 200),
    subLocality = string.rep("a", 200),
    thoroughfare = string.rep("a", 200),
    subThoroughfare = string.rep("a", 200)
  },
  timeStamp = {
    millisecond = 999,
    second = 60,
    minute = 59,
    hour = 23,
    day = 31,
    month = 12,
    year = 4095,
    tz_hour = 14,
    tz_minute = 59
  },
  locationName =string.rep("a", 500),
  locationDescription = string.rep("a", 500),
  addressLines =
  {
    string.rep("a", 500),
    string.rep("a", 500),
    string.rep("a", 500),
    string.rep("a", 500)
  },
  phoneNumber =string.rep("a", 500),
  deliveryMode = "PROMPT",
  locationImage =
  {
    value =strMaxLengthFileName255,
    imageType ="DYNAMIC",
  }
}
function Test:SendLocation_UpperBound()
  self:verify_SUCCESS_Case(Request)
end
-- Description: longitudeDegrees and latitudeDegress are upper value and others are upper value
local Request = {
  longitudeDegrees = 180,
  latitudeDegrees = 90,
  address = {
    countryName = string.rep("a", 200),
    countryCode = string.rep("a", 200),
    postalCode = string.rep("a", 200),
    administrativeArea = string.rep("a", 200),
    subAdministrativeArea = string.rep("a", 200),
    locality = string.rep("a", 200),
    subLocality = string.rep("a", 200),
    thoroughfare = string.rep("a", 200),
    subThoroughfare = string.rep("a", 200)
  },
  timeStamp = {
    millisecond = 999,
    second = 60,
    minute = 59,
    hour = 23,
    day = 31,
    month = 12,
    year = 4095,
    tz_hour = 14,
    tz_minute = 59
  },
  locationName =string.rep("a", 500),
  locationDescription = string.rep("a", 500),
  addressLines =
  {
    string.rep("a", 500),
    string.rep("a", 500),
    string.rep("a", 500),
    string.rep("a", 500)
  },
  phoneNumber =string.rep("a", 500),
  deliveryMode = "PROMPT",
  locationImage =
  {
    value =strMaxLengthFileName255,
    imageType ="DYNAMIC",
  }
}
function Test:SendLocation_UpperBound_IntDeegrees()
  self:verify_SUCCESS_Case(Request)
end
-- Description: Only mandatory params (longitudeDegrees and latitudeDegrees)
local Request = {
  longitudeDegrees = 1.1,
  latitudeDegrees = 1.1
}
function Test:SendLocation_MandatoryOnly_Degrees()
  self:verify_SUCCESS_Case(Request)
end
-------------------------------------------------------------------------------------------------
-- Test cases for parameters: locationName, locationDescription, phoneNumber
-----------------------------------------------------------------------------------------------
-- List of test cases for String type parameter:
-- 1. IsMissed
-- 2. LowerBound
-- 3. UpperBound
-- 4. OutLowerBound/IsEmpty
-- 5. OutUpperBound
-- 6. IsWrongType
-- 7. IsInvalidCharacters
-----------------------------------------------------------------------------------------------
local Boundary = {1, 500}
local Request = Test:createRequest()
stringParameter:verify_String_Parameter(Request, {"locationName"}, Boundary, false)
stringParameter:verify_String_Parameter(Request, {"locationDescription"}, Boundary, false)
stringParameter:verify_String_Parameter(Request, {"phoneNumber"}, Boundary, false)
-----------------------------------------------------------------------------------------------
-- List of test cases for parameters: locationImage
-----------------------------------------------------------------------------------------------
-- List of test cases for Image type parameter:
-- 1. IsMissed
-- 2. IsEmpty
-- 3. IsWrongType
-- 4. image.imageType: type=ImageType ("STATIC", "DYNAMIC")
-- 5. image.value: type=String, minlength=0 maxlength=65535
-----------------------------------------------------------------------------------------------
local Request = Test:createRequest()
imageParameter:verify_Image_Parameter(Request, {"locationImage"}, {"a", strMaxLengthFileName255}, false)
-----------------------------------------------------------------------------------------------
-- List of test cases for parameters: longitudeDegrees, latitudeDegrees
-----------------------------------------------------------------------------------------------
-- List of test cases for float type parameter:
-- 1. IsMissed
-- 2. IsEmpty
-- 3. IsWrongType
-- 4. IsLowerBound
-- 5. IsUpperBound
-- 6. IsOutLowerBound
-- 7. IsOutUpperBound
-----------------------------------------------------------------------------------------------
-- Request without address
local Request = Test:createRequest()
local Boundary_longitudeDegrees = {-180, 180}
local Boundary_latitudeDegrees = {-90, 90}
floatParamter:verify_Float_Parameter(Request, {"longitudeDegrees"}, Boundary_longitudeDegrees, true)
floatParamter:verify_Float_Parameter(Request, {"latitudeDegrees"}, Boundary_latitudeDegrees, true)

-- Request with address
local Request = {
  longitudeDegrees = 1.1,
  latitudeDegrees = 1.1,
  address = {
    countryName = "countryName"
  }
}

floatParamter:verify_Float_Parameter(Request, {"longitudeDegrees"}, Boundary_longitudeDegrees, true, "withAddress_")
floatParamter:verify_Float_Parameter(Request, {"latitudeDegrees"}, Boundary_latitudeDegrees, true, "withAddress_")
-----------------------------------------------------------------------------------------------
-- List of test cases for parameters: addressLines
-----------------------------------------------------------------------------------------------
-- List of test cases for String type parameter:
-- 1. IsMissed
-- 2. IsEmpty
-- 3. IsWrongType
-- 4. IsLowerBound

-- 6. IsOutLowerBound
-- 7. IsOutUpperBound
-----------------------------------------------------------------------------------------------
local Request = Test:createRequest()
local ArrayBoundary = {0, 4}
local ElementBoundary = {1, 500}
arrayStringParameter:verify_Array_String_Parameter(Request, {"addressLines"}, ArrayBoundary, ElementBoundary, false)
-----------------------------------------------------------------------------------------------
-- List of test cases for parameters: address
-----------------------------------------------------------------------------------------------
-- List of test cases for Struct type parameter:
-- 1. IsMissed
-- 2. IsEmpty
-- 3. IsWrongType
-----------------------------------------------------------------------------------------------
-- Requirement id in JAMA or JIRA: APPLINK-21926, APPLINK-22014
-- Verification criteria:
-- In case mobile app sends SendLocation_Request to SDL without "address" parameter and without both "longitudeDegrees" and "latitudeDegrees" parameters with any others params related to Request SDL must: respond "INVALID_DATA, success:false" to mobile app
-- In case mobile app sends SendLocation_Request to SDL with both "longitudeDegrees" and "latitudeDegrees" parameters and with "address" parameter and with any others params related to Request and the "address" param is empty SDL must: consider such Request as valid transfer SendLocation_request without "address" param to HMI
-- 1. IsMissed: with longitudeDegrees, latitudeDegrees
commonFunctions:newTestCasesGroup({"address"})
local Request = Test:createRequest()
commonFunctions:TestCase(self, Request, {"address"}, "IsMissed_With_longitudeDegrees_latitudeDegrees", nil, "SUCCESS")
-- 2. IsEmpty: with longitudeDegrees, latitudeDegrees
local Request = Test:createRequest()
commonFunctions:TestCase(self, Request, {"address"}, "IsEmpty_With_longitudeDegrees_latitudeDegrees", {}, "SUCCESS")
-- 3. IsEmpty: without longitudeDegrees, latitudeDegrees
local Request = {locationName = "locationName"}
commonFunctions:TestCase(self, Request, {"address"}, "IsEmpty", {}, "INVALID_DATA")
-- 4. IsWrongType
local Request = Test:createRequest()
commonFunctions:TestCase(self, Request, {"address"}, "IsWrongType", "123", "INVALID_DATA")
-----------------------------------------------------------------------------------------------
-- List of test cases for parameters:
-- countryName
-- countryCode
-- postalCode
-- administrativeArea
-- subAdministrativeArea
-- locality
-- subLocality
-- thoroughfare
-- subThoroughfare
-----------------------------------------------------------------------------------------------
-- List of test cases for String type parameter:
-- 1. IsMissed
-- 2. IsEmpty
-- 3. IsWrongType
-- 4. IsLowerBound
-- 5. IsUpperBound
-- 6. IsOutLowerBound
-- 7. IsOutUpperBound
-----------------------------------------------------------------------------------------------
local Request = {
  address = {
    countryName = "countryName",
    subThoroughfare = "subThoroughfare"
  },
  longitudeDegrees = 1.1,
  latitudeDegrees = 1.1
}
local ElementBoundary = {0, 200}
stringParameter:verify_String_Parameter(Request, {"address", "countryName"}, ElementBoundary, false)
local ElementBoundary = {0, 200}
stringParameter:verify_String_Parameter(Request, {"address", "countryCode"}, ElementBoundary, false)
local ElementBoundary = {0, 200}
stringParameter:verify_String_Parameter(Request, {"address", "postalCode"}, ElementBoundary, false)
local ElementBoundary = {0, 200}
stringParameter:verify_String_Parameter(Request, {"address", "administrativeArea"}, ElementBoundary, false)
stringParameter:verify_String_Parameter(Request, {"address", "subAdministrativeArea"}, ElementBoundary, false)
stringParameter:verify_String_Parameter(Request, {"address", "locality"}, ElementBoundary, false)
stringParameter:verify_String_Parameter(Request, {"address", "subLocality"}, ElementBoundary, false)
stringParameter:verify_String_Parameter(Request, {"address", "thoroughfare"}, ElementBoundary, false)
stringParameter:verify_String_Parameter(Request, {"address", "subThoroughfare"}, ElementBoundary, false)
function Test:SendLocation_address_allParams_without_longitudeDegrees_latitudeDegrees()
  local RequestParams = {
    address = {
      countryName = "countryName",
      countryCode = "countryCode",
      postalCode = "postalCode",
      administrativeArea = "administrativeArea",
      subAdministrativeArea = "subAdministrativeArea",
      locality = "locality",
      subLocality = "subLocality",
      thoroughfare = "thoroughfare",
      subThoroughfare = "subThoroughfare"
    }
  }
  self:verify_INVALID_DATA_Case(RequestParams)
end
function Test:SendLocation_address_allParams_with_longitudeDegrees_latitudeDegrees()
  local RequestParams = {
    longitudeDegrees = 1.1,
    latitudeDegrees = 1.1,
    address = {
      countryName = "countryName",
      countryCode = "countryCode",
      postalCode = "postalCode",
      administrativeArea = "administrativeArea",
      subAdministrativeArea = "subAdministrativeArea",
      locality = "locality",
      subLocality = "subLocality",
      thoroughfare = "thoroughfare",
      subThoroughfare = "subThoroughfare"
    }
  }
  self:verify_SUCCESS_Case(RequestParams)
end
-----------------------------------------------------------------------------------------------
-- List of test cases for parameters:
-- timeStamp
-----------------------------------------------------------------------------------------------
-- List of test cases for Struct type parameter:
-- 1. IsMissed
-- 2. IsEmpty
-- 3. IsWrongType
-----------------------------------------------------------------------------------------------
-- 1. IsMissed
commonFunctions:newTestCasesGroup({"timeStamp"})
local Request = Test:createRequest()
commonFunctions:TestCase(self, Request, {"timeStamp"}, "IsMissed", nil, "SUCCESS")
-- 2. IsEmpty
commonFunctions:TestCase(self, Request, {"timeStamp"}, "IsEmpty", {}, "INVALID_DATA")
-- 3. IsWrongType
commonFunctions:TestCase(self, Request, {"timeStamp"}, "IsWrongType", "123", "INVALID_DATA")
-----------------------------------------------------------------------------------------------
-- List of test cases for parameters:
-- millisecond
-- second
-- minute
-- hour
-- day
-- month
-- year
-- tz_hour
-- tz_minute
-----------------------------------------------------------------------------------------------
-- List of test cases for Integer type parameter:
-- 1. IsMissed
-- 2. IsEmpty
-- 3. IsWrongType
-- 4. IsLowerBound
-- 5. IsUpperBound
-- 6. IsOutLowerBound
-- 7. IsOutUpperBound
-----------------------------------------------------------------------------------------------
local Request = Test:createRequest()
Request.address = { countryName = "countryName" }
Request.timeStamp = {
  millisecond=10,
  second = 40,
  minute = 30,
  hour = 14,
  day = 25,
  month = 5,
  year = 2017,
  tz_hour = 5,
  tz_minute = 30
}
-- millisecond parameter
local ElementBoundary = {0, 999}
integerParameter:verify_Integer_Parameter(Request, {"timeStamp", "millisecond"}, ElementBoundary, false)
-- second parameter
local ElementBoundary = {0, 60}
integerParameter:verify_Integer_Parameter(Request, {"timeStamp", "second"}, ElementBoundary, false)
-- minute parameter
local ElementBoundary = {0, 59}
integerParameter:verify_Integer_Parameter(Request, {"timeStamp", "minute"}, ElementBoundary, false)
-- hour parameter
local ElementBoundary = {0, 23}
integerParameter:verify_Integer_Parameter(Request, {"timeStamp", "hour"}, ElementBoundary, false)
-- day parameter
local ElementBoundary = {1, 31}
integerParameter:verify_Integer_Parameter(Request, {"timeStamp", "day"}, ElementBoundary, false)
-- month parameter
local ElementBoundary = {1, 12}
integerParameter:verify_Integer_Parameter(Request, {"timeStamp", "month"}, ElementBoundary, false)
-- year parameter
local ElementBoundary = {0, 4095}
integerParameter:verify_Integer_Parameter(Request, {"timeStamp", "year"}, ElementBoundary, false)
-- tz_hour parameter
local ElementBoundary = {-12, 14}
integerParameter:verify_Integer_Parameter(Request, {"timeStamp", "tz_hour"}, ElementBoundary, false, 0)
-- tz_minute parameter
local ElementBoundary = {0, 59}
integerParameter:verify_Integer_Parameter(Request, {"timeStamp", "tz_minute"}, ElementBoundary, false, 0)
----------------------------------------------------------------------------------------------
-- List of test cases for parameters: deliveryMode, mandatory = false
-----------------------------------------------------------------------------------------------
-- List of test cases for softButtons type parameter:
-- 1. IsMissed
-- 2. IsEmpty
-- 3. IsWrongType
-- 4. IsLowerBound
-- 5. IsUpperBound
-- 6. IsOutLowerBound
-- 7. IsOutUpperBound
-----------------------------------------------------------------------------------------------
local DeliveryMode = {
  "PROMPT",
  "DESTINATION",
  "QUEUE"
}
local Request = Test:createRequest()
enumerationParameter:verify_Enum_String_Parameter(Request, {"deliveryMode"}, DeliveryMode, false)
--------------------------------------Coverage of CRQ APPLINK-24201-------------------------------------
-- Requirement IDs
--[[
APPLINK-24201
APPLINK-21166
APPLINK-24180
APPLINK-24215
APPLINK-24224
APPLINK-24229
APPLINK-25890
APPLINK-25891
--]]
-----------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("Test suit for coverage of CRQ APPLINK-24201")
-----------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("1. Checking when parameters is empty in Base 4")
-- RequirementID: APPLINK-21166
-- Description: SendLocation is present in Base4 with empty parameters in Policy.
local permission_lines_parameters_empty =
[[
"SendLocation": {
  "hmi_levels": [
  "BACKGROUND",
  "FULL",
  "LIMITED"
  ],
  "parameters": [
  ]
}
]]
local permission_lines_for_base4 = permission_lines_parameters_empty .. ", \n"
local permission_lines_for_group1 = nil
local permission_lines_for_application = nil
local policy_file_name = policyTable:createPolicyTableFile(permission_lines_for_base4, permission_lines_for_group1, permission_lines_for_application,{"SendLocation"})
policyTable:updatePolicy(policy_file_name, nil, "UpdatePolicy_SendLocation_InBase4_WithEmptyParameters")
local AllDisallowedParams = {
  longitudeDegrees = 1.1,
  latitudeDegrees = 1.1,
  address = {
    countryName = "countryName",
    countryCode = "countryCode",
    postalCode = "postalCode",
    administrativeArea = "administrativeArea",
    subAdministrativeArea = "subAdministrativeArea",
    locality = "locality",
    subLocality = "subLocality",
    thoroughfare = "thoroughfare",
    subThoroughfare = "subThoroughfare"
  },
  timeStamp = {
    millisecond = 999,
    second = 40,
    minute = 30,
    hour = 14,
    day = 25,
    month = 5,
    year = 2017,
    tz_hour = 5,
    tz_minute = 30
  },
  locationName = "location Name",
  locationDescription = "location Description",
  addressLines =
  {
    "line1",
    "line2",
  },
  phoneNumber = "phone Number",
  deliveryMode = "PROMPT",
  locationImage =
  {
    value = "icon.png",
    imageType = "DYNAMIC",
  }
}
-- SDL responds DISALLOWED with info when send SendLocation with all params when "parammeters" is empty in Base 4
function Test:SendLocation_InBase4_WithEmptyParamters()
  local cid = self.mobileSession:SendRPC("SendLocation", AllDisallowedParams)
  -- hmi side: not expect Navigation.SendLocation
  EXPECT_HMICALL("Navigation.SendLocation", {})
  :Times(0)
  -- mobile side: expect response
  EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Requested parameters are disallowed by Policies"})
  commonTestCases:DelayedExp(1000)
end
-------------------------------------------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("2. Checking when other parameters are present in Base-4 except longitudeDegrees and longitudeDegrees")
-- RequirementID: APPLINK-24180, APPLINK-24215, APPLINK-24229
-- Description: SendLocation is present in Base4 with 9 allowed params and disallowed (locationName) by policies
local permissionLines_disallowed_madatory =
[[
"SendLocation": {
  "hmi_levels": [
  "BACKGROUND",
  "FULL",
  "LIMITED"
  ],
  "parameters": [
  "locationDescription",
  "addressLines",
  "phoneNumber",
  "locationImage",
  "deliveryMode",
  "timeStamp",
  "address",
  "locationName"
  ]
}
]]
local permission_lines_for_base4 = permissionLines_disallowed_madatory .. ", \n"
local permission_lines_for_group1 = nil
local permission_lines_for_application = nil
local policy_file_name = policyTable:createPolicyTableFile(permission_lines_for_base4, permission_lines_for_group1, permission_lines_for_application,{"SendLocation"})
policyTable:updatePolicy(policy_file_name, nil, "UpdatePolicy_SendLocation4_InBase4_WithDisallowed_longitudeDegreesAndlatitudeDegrees")
-- SDL responds DISALLOWED when send SendLocation request with disallowed params
local DisallowedMandatoryParams = {
  longitudeDegrees = 1.1,
  latitudeDegrees = 1.1
}
function Test:SendLocation_InBase4_With2DisallowedParams()
  -- mobile side: sending the request
  local cid = self.mobileSession:SendRPC("SendLocation", DisallowedMandatoryParams)
  -- hmi side: not expect Navigation.SendLocation
  EXPECT_HMICALL("Navigation.SendLocation", {})
  :Times(0)
  -- mobile side: expect response
  EXPECT_RESPONSE(cid, {resultCode = "DISALLOWED", info = "Requested parameters are disallowed by Policies", success = false})
  commonTestCases:DelayedExp(1000)
end
-- SDL responds INVALID_DATA according to APPLINK-22208 and APPLINK-22209 when send SendLocation with allowed and without mandatory
local AllowedAndWithoutMandatory = {
  locationName="LocationName",
  address = {
    countryName = "countryName",
    countryCode = "countryCode",
    postalCode = "postalCode",
    administrativeArea = "administrativeArea",
    subAdministrativeArea = "subAdministrativeArea",
    locality = "locality",
    subLocality = "subLocality",
    thoroughfare = "thoroughfare",
    subThoroughfare = "subThoroughfare"
  },
  timeStamp = {
    millisecond = 999,
    second = 40,
    minute = 30,
    hour = 14,
    day = 25,
    month = 5,
    year = 2017,
    tz_hour = 5,
    tz_minute = 30
  },
  locationDescription = "location Description",
  addressLines =
  {
    "line1",
    "line2",
  },
  phoneNumber = "phone Number",
  deliveryMode = "PROMPT",
  locationImage =
  {
    value = "icon.png",
    imageType = "DYNAMIC",
  }
}
function Test:SendLocation_WithOnlyAllowedParams()
  self:verify_INVALID_DATA_Case(AllowedAndWithoutMandatory)
end
-- SDL responds DISALLOWED with info about disallowed params when send allowed + disallowed params
local AllowedAndDissallowedParams = {
  longitudeDegrees = 1.1,
  latitudeDegrees = 1.1,
  address = {
    countryName = "countryName",
    countryCode = "countryCode",
    postalCode = "postalCode",
    administrativeArea = "administrativeArea",
    subAdministrativeArea = "subAdministrativeArea",
    locality = "locality",
    subLocality = "subLocality",
    thoroughfare = "thoroughfare",
    subThoroughfare = "subThoroughfare"
  },
  timeStamp = {
    millisecond = 999,
    second = 40,
    minute = 30,
    hour = 14,
    day = 25,
    month = 5,
    year = 2017,
    tz_hour = 5,
    tz_minute = 30
  },
  locationName = "locationName",
  locationDescription = "location Description",
  addressLines =
  {
    "line1",
    "line2",
  },
  phoneNumber = "phone Number",
  deliveryMode = "PROMPT",
  locationImage =
  {
    value = "icon.png",
    imageType = "DYNAMIC",
  }
}
function Test:SendLocation_InBase4_WithAllowedParams_DisallowedParams()
  -- mobile side: sending SendLocation request
  cid = self.mobileSession:SendRPC("SendLocation", AllowedAndDissallowedParams)
  -- hmi side: expect Navigation.SendLocation request
  EXPECT_HMICALL("Navigation.SendLocation", {})
  :Times(0)
  -- mobile side: expect SendLocation response. Expected result is confirmed by APPLINK-29372
  EXPECT_RESPONSE(cid, {success = false, info = "'latitudeDegrees', 'longitudeDegrees' are disallowed by policies", resultCode = "DISALLOWED"})
end
-------------------------------------------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("3. Checking when 4 parameters are present in Base-4 including latitudeDegrees and longitudeDegrees")
-- RequirementID: APPLINK-24180, APPLINK-24215, APPLINK-24229
-- Description: SendLocation is present in Base4 with 4 allowed params and 6 disallowed params by policies.
local permission_lines_allowed_for_base4 =
[[
"SendLocation": {
  "hmi_levels": [
  "BACKGROUND",
  "FULL",
  "LIMITED"
  ],
  "parameters": [
  "longitudeDegrees",
  "latitudeDegrees",
  "locationName",
  "locationDescription"
  ]
}
]]
local permission_lines_for_base4 = permission_lines_allowed_for_base4 .. ", \n"
local permission_lines_for_group1 = nil
local permission_lines_for_application = nil
local policy_file_name = policyTable:createPolicyTableFile(permission_lines_for_base4, permission_lines_for_group1, permission_lines_for_application)
policyTable:updatePolicy(policy_file_name, nil, "UpdatePolicy_DisallowedSomeParams_AllowBase4")
local DisallowedParamsWithoutMandatory = {
  address = {
    countryName = "countryName",
    countryCode = "countryCode",
    postalCode = "postalCode",
    administrativeArea = "administrativeArea",
    subAdministrativeArea = "subAdministrativeArea",
    locality = "locality",
    subLocality = "subLocality",
    thoroughfare = "thoroughfare",
    subThoroughfare = "subThoroughfare"
  },
  timeStamp = {
    millisecond = 999,
    second = 40,
    minute = 30,
    hour = 14,
    day = 25,
    month = 5,
    year = 2017,
    tz_hour = 5,
    tz_minute = 30
  },
  addressLines =
  {
    "line1",
    "line2",
  },
  phoneNumber = "phone Number",
  deliveryMode = "PROMPT",
  locationImage =
  {
    value = "icon.png",
    imageType = "DYNAMIC",
  }
}
-- SDL responds INVALID_DATA according to APPLINK-22208 and APPLINK-22209 when send SendLocation request with 9 allowed params (without longitudeDegrees and laitudeDegrees) by Policies
function Test:SendLocation_Base4_With_SomeDisallowedParams_ByPolicies()
  self:verify_INVALID_DATA_Case(DisallowedParamsWithoutMandatory)
end
-- SDL responds SUCCESS with info about disallowed params for SendLocation request with allowed and disallowed params
local AllowedAndDisallowedParamsWithMandatory = {
  longitudeDegrees = 1.1,
  latitudeDegrees = 1.1,
  address = {
    countryName = "countryName",
    countryCode = "countryCode",
    postalCode = "postalCode",
    administrativeArea = "administrativeArea",
    subAdministrativeArea = "subAdministrativeArea",
    locality = "locality",
    subLocality = "subLocality",
    thoroughfare = "thoroughfare",
    subThoroughfare = "subThoroughfare"
  },
  timeStamp = {
    second = 40,
    minute = 30,
    hour = 14,
    day = 25,
    month = 5,
    year = 2017,
    tz_hour = 5,
    tz_minute = 30
  },
  locationName = "location Name",
  locationDescription = "location Description",
  addressLines =
  {
    "line1",
    "line2",
  },
  phoneNumber = "phone Number",
  deliveryMode = "PROMPT",
  locationImage =
  {
    value = "icon.png",
    imageType = "DYNAMIC",
  }
}
function Test:SendLocation_InBase4_With_SomeAllowedParams_And_SomeDisallowedParams()
  -- mobile side: sending SendLocation request
  cid = self.mobileSession:SendRPC("SendLocation", AllowedAndDisallowedParamsWithMandatory)
  -- hmi side: expect Navigation.SendLocation request
  EXPECT_HMICALL("Navigation.SendLocation", {
    longitudeDegrees = 1.1,
    latitudeDegrees = 1.1,
    locationName = "location Name",
    locationDescription = "location Description"
  })
  :Do(function(_,data)
    -- hmi side: sending Navigation.SendLocation response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  :ValidIf(function(_,data)
    if data.params.address or data.params.addressLines or data.params.deliveryMode or data.params.locationImage or data.params.phoneNumber or data.timeStamp then
      commonFunctions:userPrint(31,"Navigation.SendLocation contain some parameters in request when should be omitted")
      return false
    else
      return true
    end
  end)
  -- mobile side: expect SendLocation response
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = "'address', 'addressLines', 'deliveryMode', 'locationImage', 'phoneNumber', 'timeStamp' are disallowed by policies"})
end
-- SDL responds SUCCESS with when SendLocation request with allowed params
local AllowedParamsWithMandatory = {
  longitudeDegrees = 1.1,
  latitudeDegrees = 1.1,
  locationName = "location Name",
  locationDescription = "location Description"
}
function Test:SendLocation_InBase4_With_SomeAllowedParams()
  self:verify_SUCCESS_Case(AllowedParamsWithMandatory)
end
-------------------------------------------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("4. Checking when 2 parameters are present in Base-4, 5 params are in consent group1 (with no answer) and 3 params are disallowed")
-- RequirementID: APPLINK-25890, APPLINK-25891
-- Description: SendLocation(longitudeDegrees, latitudeDegrees) exists at Base4, SendLocation(addressLines, phoneNumber, deliveryMode, timeStamp and address) exists at group1 in Policies but Base4 and group1 was assigned to User.Group1 need to consent.
local permission_lines_allowed_for_base4 =
[[
"SendLocation": {
  "hmi_levels": [
  "BACKGROUND",
  "FULL",
  "LIMITED"
  ],
  "parameters": [
  "addressLines",
  "phoneNumber"
  ]
}
]]
local permission_lines_allowed_for_sendlocation =
[[
"SendLocation": {
  "hmi_levels": [
  "BACKGROUND",
  "FULL",
  "LIMITED"
  ],
  "parameters": [
  "longitudeDegrees",
  "latitudeDegrees",
  "deliveryMode",
  "timeStamp",
  "address"
  ]
}
]]
local permission_lines_allowed_for_app1=[[			"]].."0000001" ..[[":{
  "keep_context": true,
  "steal_focus": true,
  "priority": "NONE",
  "default_hmi": "BACKGROUND",
  "groups": ["group1","Base-4"]
}
]]
local permission_lines_for_base4 = permission_lines_allowed_for_base4 .. ", \n"
local permission_lines_for_group1 = permission_lines_allowed_for_sendlocation
local permission_lines_for_application = permission_lines_allowed_for_app1 ..", \n"
local policy_file_name = policyTable:createPolicyTableFile(permission_lines_for_base4, permission_lines_for_group1, permission_lines_for_application,{"SendLocation"})
policyTable:updatePolicy(policy_file_name, nil, "UpdatePolicy_SendLocation_PresentGroup1AndBase4_AssignedToApp")
-- SDL responds DISALLOWED with info when send SendLocation request with params in the group 1 (without longitudeDegrees and latitudeDegrees) when user does not answer for consent.
local DisallowedParamsFromConsentGroup = {
  longitudeDegrees = 1.1,
  latitudeDegrees = 1.1,
  address = {
    countryName = "countryName",
    countryCode = "countryCode",
    postalCode = "postalCode",
    administrativeArea = "administrativeArea",
    subAdministrativeArea = "subAdministrativeArea",
    locality = "locality",
    subLocality = "subLocality",
    thoroughfare = "thoroughfare",
    subThoroughfare = "subThoroughfare"
  }
}
function Test:SendLocation_ParamsInGroup1_User_Not_Answer_Consent()
  -- mobile side: sending SendLocation request
  local cid = self.mobileSession:SendRPC("SendLocation", DisallowedParamsFromConsentGroup)
  -- hmi side: not expect Navigation.SendLocation
  EXPECT_HMICALL("Navigation.SendLocation", {})
  :Times(0)
  -- mobile side: expect SendLocation response
  EXPECT_RESPONSE(cid, {success = false, resultCode = "DISALLOWED", info = "Requested parameters are disallowed by Policies"})
  commonTestCases:DelayedExp(1000)
end
-- SDL responds DISALLOWED with info about disallowed params when send SendLocation with allowed params in Base4 and params in group1 when user does not answer consent for group1.
local DisallowedParamsFromConsentAndAllowedParamsFromBase4 = {
  longitudeDegrees = 1.1,
  latitudeDegrees = 1.1,
  phoneNumber = "phone Number",
  addressLines =
  {
    "line1",
    "line2",
  },
}
function Test:SendLocation_AllowedParamsInBase4_NotAnswerForUserConsentForGroup1()
  --mobile side: sending SendLocation request
  cid = self.mobileSession:SendRPC("SendLocation", DisallowedParamsFromConsentAndAllowedParamsFromBase4)
  --hmi side: expect Navigation.SendLocation request
  EXPECT_HMICALL("Navigation.SendLocation", {}):Times(0)
  --mobile side: expect SendLocation response. Expected result is confirmed by APPLINK-29372
  EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "latitudeDegrees', 'longitudeDegrees' are disallowed by policies"})
end
-- SDL responds DISALLOWED with info about disallowed params when send SendLocation with allowed params and disallowed params (by policies and in not consent group1)
local AllowedParamsFromBase4GroupAndAllDisalowedParams = {
  longitudeDegrees = 1.1,
  latitudeDegrees = 1.1,
  address = {
    countryName = "countryName",
    countryCode = "countryCode",
    postalCode = "postalCode",
    administrativeArea = "administrativeArea",
    subAdministrativeArea = "subAdministrativeArea",
    locality = "locality",
    subLocality = "subLocality",
    thoroughfare = "thoroughfare",
    subThoroughfare = "subThoroughfare"
  },
  timeStamp = {
    second = 40,
    minute = 30,
    hour = 14,
    day = 25,
    month = 5,
    year = 2017,
    tz_hour = 5,
    tz_minute = 30
  },
  locationName = "location Name",
  locationDescription = "location Description",
  addressLines =
  {
    "line1",
    "line2",
  },
  phoneNumber = "phone Number",
  deliveryMode = "PROMPT",
  locationImage =
  {
    value = "icon.png",
    imageType = "DYNAMIC",
  }
}
function Test:SendLocation_AllowedParamsBase4_ParamsNotPresentedInPolicies_NotAnswerForConsentGroup1()
  -- mobile side: sending SendLocation request
  cid = self.mobileSession:SendRPC("SendLocation", AllowedParamsFromBase4GroupAndAllDisalowedParams)
  -- hmi side: expect Navigation.SendLocation request
  EXPECT_HMICALL("Navigation.SendLocation", {})
  :Times(0)
  -- mobile side: expect SendLocation response
  EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "'address', 'deliveryMode', 'latitudeDegrees', 'locationDescription', 'locationImage', 'locationName', 'longitudeDegrees', 'timeStamp' are disallowed by policies"})
end
-------------------------------------------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("5. Checking when user answers NO for Consent group")
policyTable:userConsent(false, "group1", "UserConsent_Answer_No")
-- RequirementID: APPLINK-25890
-- SDL responds USER_DISALLOWED with info when send SendLocation with user_disallowed params. Question: APPLINK-26856 and APPLINK-26869
local UserDisallowedParams = {
  address = {
    countryName = "countryName",
    countryCode = "countryCode",
    postalCode = "postalCode",
    administrativeArea = "administrativeArea",
    subAdministrativeArea = "subAdministrativeArea",
    locality = "locality",
    subLocality = "subLocality",
    thoroughfare = "thoroughfare",
    subThoroughfare = "subThoroughfare"
  },
  timeStamp = {
    second = 40,
    minute = 30,
    hour = 14,
    day = 25,
    month = 5,
    year = 2017,
    tz_hour = 5,
    tz_minute = 30
  },
  longitudeDegrees = 1.1,
  latitudeDegrees = 1.1,
  deliveryMode = "PROMPT"
}
function Test:SendLocation_ParamsInGroup1_User_Answer_NO()
  -- mobile side: sending SendLocation request
  local cid = self.mobileSession:SendRPC("SendLocation", UserDisallowedParams)
  -- hmi side: not expect Navigation.SendLocation
  EXPECT_HMICALL("Navigation.SendLocation", {})
  :Times(0)
  -- mobile side: expect SendLocation response
  EXPECT_RESPONSE(cid, {success = false, resultCode = "USER_DISALLOWED", info = "RPC is disallowed by the user"})
  commonTestCases:DelayedExp(1000)
end
-- SDL responds DISALLOWED when send SendLocation with allowed param by Policies and disallowed params by User
local UserDisallowedParamsAndAllowedParams = {
  addressLines =
  {
    "line1",
    "line2",
  },
  phoneNumber = "phone Number",
  address = {
    countryName = "countryName",
    countryCode = "countryCode",
    postalCode = "postalCode",
    administrativeArea = "administrativeArea",
    subAdministrativeArea = "subAdministrativeArea",
    locality = "locality",
    subLocality = "subLocality",
    thoroughfare = "thoroughfare",
    subThoroughfare = "subThoroughfare"
  },
  deliveryMode = "PROMPT",
  longitudeDegrees = 1.1,
  latitudeDegrees = 1.1,
}
function Test:SendLocation_ParamsInBase4_ParamInGroup1_User_Answer_NO()
  -- mobile side: sending SendLocation request
  local cid = self.mobileSession:SendRPC("SendLocation", UserDisallowedParamsAndAllowedParams)
  -- hmi side: not expect Navigation.SendLocation
  EXPECT_HMICALL("Navigation.SendLocation", {})
  :Times(0)
  -- mobile side: expect SendLocation response
  EXPECT_RESPONSE(cid, {success = false, resultCode = "DISALLOWED", info = "'address', 'deliveryMode', 'latitudeDegrees', 'longitudeDegrees' are disallowed by user"})
  commonTestCases:DelayedExp(1000)
end
-- RequirementID: APPLINK-25891
-- SDL responds DISALLOWED with info when send SendLocation with some params are disallowed by Policies and some params are disallowed by User. Question: APPLINK-26903 case 2
local DisallowedParamsAndUserDissallowedParams = {
  address = {
    countryName = "countryName",
    countryCode = "countryCode",
    postalCode = "postalCode",
    administrativeArea = "administrativeArea",
    subAdministrativeArea = "subAdministrativeArea",
    locality = "locality",
    subLocality = "subLocality",
    thoroughfare = "thoroughfare",
    subThoroughfare = "subThoroughfare"
  },
  timeStamp = {
    second = 40,
    minute = 30,
    hour = 14,
    day = 25,
    month = 5,
    year = 2017,
    tz_hour = 5,
    tz_minute = 30
  },
  locationName = "location Name",
  locationDescription = "location Description",
  longitudeDegrees = 1.1,
  latitudeDegrees = 1.1,
  deliveryMode = "PROMPT",
  locationImage =
  {
    value = "icon.png",
    imageType = "DYNAMIC",
  }
}
function Test:SendLocation_With_DisallowedParamsByPolicies_ParamInGroup1_UserAnswerNO()
  -- mobile side: sending SendLocation request
  local cid = self.mobileSession:SendRPC("SendLocation", DisallowedParamsAndUserDissallowedParams)
  -- hmi side: not expect Navigation.SendLocation
  EXPECT_HMICALL("Navigation.SendLocation", {})
  :Times(0)
  -- mobile side: expect SendLocation response
  EXPECT_RESPONSE(cid, {success = false, resultCode = "DISALLOWED", info= "'locationDescription', 'locationImage', 'locationName' are disallowed by policies, 'address', 'deliveryMode', 'latitudeDegrees', 'longitudeDegrees', 'timeStamp' are disallowed by user"})
  commonTestCases:DelayedExp(1000)
end
-- RequirementID: APPLINK-25891.
-- Question: APPLINK-26904
-- SDL responds DISALLOWED with info when send SendLocation with allowed, disallowed and user-disallowed params.
local AllowedAndDisallowedAndUserDisallowedParams = {
  longitudeDegrees = 1.1,
  latitudeDegrees = 1.1,
  address = {
    countryName = "countryName",
    countryCode = "countryCode",
    postalCode = "postalCode",
    administrativeArea = "administrativeArea",
    subAdministrativeArea = "subAdministrativeArea",
    locality = "locality",
    subLocality = "subLocality",
    thoroughfare = "thoroughfare",
    subThoroughfare = "subThoroughfare"
  },
  timeStamp = {
    second = 40,
    minute = 30,
    hour = 14,
    day = 25,
    month = 5,
    year = 2017,
    tz_hour = 5,
    tz_minute = 30
  },
  locationName = "location Name",
  locationDescription = "location Description",
  addressLines =
  {
    "line1",
    "line2",
  },
  phoneNumber = "phone Number",
  deliveryMode = "PROMPT",
  locationImage =
  {
    value = "icon.png",
    imageType = "DYNAMIC",
  }
}
function Test:SendLocation_AlowedParamsInBase4_ParamsNotPresentedInPolicies_DisallowedParamsByUser()
  -- mobile side: sending SendLocationRequest request
  local cid = self.mobileSession:SendRPC("SendLocation", AllowedAndDisallowedAndUserDisallowedParams)
  EXPECT_HMICALL("Navigation.SendLocation", {}):Times(0)
  -- mobile side: expect SendLocation response
  EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "'locationDescription', 'locationImage', 'locationName' are disallowed by policies, 'address', 'deliveryMode', 'latitudeDegrees', 'longitudeDegrees', 'timeStamp' are disallowed by user"})
end
------------------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("6. Checking when user answers YES for Consent group")
policyTable:userConsent(true, "group1", "UserConsent_true")
-- RequirementID: APPLINK-24215
-- SDL responds SUCCESS with info when send SendLocation with allowed params by policies, allowed params by user and disallowed param
local AllowedAndUserAllowedAndDisallowedParams = {
  longitudeDegrees = 1.1,
  latitudeDegrees = 1.1,
  address = {
    countryName = "countryName",
    countryCode = "countryCode",
    postalCode = "postalCode",
    administrativeArea = "administrativeArea",
    subAdministrativeArea = "subAdministrativeArea",
    locality = "locality",
    subLocality = "subLocality",
    thoroughfare = "thoroughfare",
    subThoroughfare = "subThoroughfare"
  },
  locationName = "location Name",
  locationDescription = "location Description",
  addressLines =
  {
    "line1",
    "line2",
  },
  phoneNumber = "phone Number",
  deliveryMode = "PROMPT",
  locationImage =
  {
    value = "icon.png",
    imageType = "DYNAMIC",
  }
}
function Test:SendLocation_AllowedParamsInBase4_ParamsNotPresentedInPolicies_AllowedParamsInGroup1()
  -- mobile side: sending SendLocation request
  cid = self.mobileSession:SendRPC("SendLocation", AllowedAndUserAllowedAndDisallowedParams)
  -- hmi side: expect Navigation.SendLocation request
  EXPECT_HMICALL("Navigation.SendLocation", {
    longitudeDegrees = 1.1,
    latitudeDegrees = 1.1,
    address = {
      countryName = "countryName",
      countryCode = "countryCode",
      postalCode = "postalCode",
      administrativeArea = "administrativeArea",
      subAdministrativeArea = "subAdministrativeArea",
      locality = "locality",
      subLocality = "subLocality",
      thoroughfare = "thoroughfare",
      subThoroughfare = "subThoroughfare"
    },
    addressLines =
    {
      "line1",
      "line2",
    },
    phoneNumber = "phone Number",
    deliveryMode = "PROMPT"
  })
  :Do(function(_,data)
    -- hmi side: sending Navigation.SendLocation response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  :ValidIf(function(_,data)
    if data.params.locationName or data.params.locationDescription or data.params.locationImage then
      commonFunctions:userPrint(31,"Navigation.SendLocation contain location info in request when should be omitted")
      return false
    else
      return true
    end
  end)
  -- mobile side: expect SendLocation response
  EXPECT_RESPONSE(cid, {success = true, info = "'locationDescription', 'locationImage', 'locationName' are disallowed by policies", resultCode = "SUCCESS"})
end
-- Description: SDL respond SUCCESS for SendLocation request with allowed params by user.
local UserAlowedParams = {
  address = {
    countryName = "countryName",
    countryCode = "countryCode",
    postalCode = "postalCode",
    administrativeArea = "administrativeArea",
    subAdministrativeArea = "subAdministrativeArea",
    locality = "locality",
    subLocality = "subLocality",
    thoroughfare = "thoroughfare",
    subThoroughfare = "subThoroughfare"
  },
  timeStamp = {
    second = 40,
    minute = 30,
    hour = 14,
    day = 25,
    month = 5,
    year = 2017,
    tz_hour = 5,
    tz_minute = 30
  },
  longitudeDegrees = 1.1,
  latitudeDegrees = 1.1,
  deliveryMode = "PROMPT"
}
function Test:SendLocation_AllParamsInGroup1_UserAnswerYES()
  self:verify_SUCCESS_Case(UserAlowedParams)
end
-- Description: SDL respond SUCCESS for SendLocation request with allowed params by user and allowed params by policies
local AllowedAndUserAlowedParams = {
  longitudeDegrees = 1.1,
  latitudeDegrees = 1.1,
  address = {
    countryName = "countryName",
    countryCode = "countryCode",
    postalCode = "postalCode",
    administrativeArea = "administrativeArea",
    subAdministrativeArea = "subAdministrativeArea",
    locality = "locality",
    subLocality = "subLocality",
    thoroughfare = "thoroughfare",
    subThoroughfare = "subThoroughfare"
  },
  timeStamp = {
    second = 40,
    minute = 30,
    hour = 14,
    day = 25,
    month = 5,
    year = 2017,
    tz_hour = 5,
    tz_minute = 30
  },
  addressLines =
  {
    "line1",
    "line2",
  },
  phoneNumber = "phone Number",
  deliveryMode = "PROMPT"
}
function Test:SendLocation_AllowedParamsBase4_ParamsInGroup1_UserAnswerYES()
  self:verify_SUCCESS_Case(AllowedAndUserAlowedParams)
end
-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("7. Case when all params are present at 'parameters'")
-- RequirementID: APPLINK-24180, APPLINK-23497
-- Description: All parameters are presented at Base4 in Policy. SDL respond SUCCESS for SendLocation request with allowed params by Policy.
local permission_lines_all_parameters =
[[
"SendLocation": {
  "hmi_levels": [
  "BACKGROUND",
  "FULL",
  "LIMITED"
  ],
  "parameters": [
  "longitudeDegrees",
  "latitudeDegrees",
  "locationName",
  "locationDescription",
  "addressLines",
  "phoneNumber",
  "locationImage",
  "deliveryMode",
  "timeStamp",
  "address"
  ]
}
]]
local permission_lines_for_app1=[[			"]].."0000001" ..[[":{
  "keep_context": true,
  "steal_focus": true,
  "priority": "NONE",
  "default_hmi": "BACKGROUND",
  "groups": ["Base-4"]
}
]]
local permission_lines_for_base4 = permission_lines_all_parameters .. ", \n"
local permission_lines_for_group1 = nil
local permission_lines_for_application = permission_lines_for_app1 ..", \n"
local policy_file_name = policyTable:createPolicyTableFile(permission_lines_for_base4, permission_lines_for_group1, permission_lines_for_application)
policyTable:updatePolicy(policy_file_name, nil, "UpdatePolicy_SendLocation_Base4_WithAllParams")
local Request = {
  longitudeDegrees = 1.1,
  latitudeDegrees = 1.1,
  address = {
    countryName = "countryName",
    countryCode = "countryCode",
    postalCode = "postalCode",
    administrativeArea = "administrativeArea",
    subAdministrativeArea = "subAdministrativeArea",
    locality = "locality",
    subLocality = "subLocality",
    thoroughfare = "thoroughfare",
    subThoroughfare = "subThoroughfare"
  },
  timeStamp = {
    second = 40,
    minute = 30,
    hour = 14,
    day = 25,
    month = 5,
    year = 2017,
    tz_hour = 5,
    tz_minute = 30
  },
  locationName = "location Name",
  locationDescription = "location Description",
  addressLines =
  {
    "line1",
    "line2",
  },
  phoneNumber = "phone Number",
  deliveryMode = "PROMPT",
  locationImage =
  {
    value = "icon.png",
    imageType = "DYNAMIC",
  }
}
function Test:SendLocation_AllowedAllParams_InBase4()
  self:verify_SUCCESS_Case(Request)
end
-------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("8. Case when 'parameters' is omitted'")
-- RequirementID: APPLINK-24224
-- Description: All parameters are omitted on Policy. SDL must allow all parameter.
local permissionLines_empty_parameters =
[[
"SendLocation": {
  "hmi_levels": [
  "BACKGROUND",
  "FULL",
  "LIMITED"
  ]
}
]]
local permission_lines_for_base4 = permissionLines_empty_parameters .. ", \n"
local permission_lines_for_group1 = nil
local permission_lines_for_application = nil
local policy_file_name = policyTable:createPolicyTableFile(permission_lines_for_base4, permission_lines_for_group1, permission_lines_for_application)
policyTable:updatePolicy(policy_file_name, nil, "UpdatePolicy_OmittedAllParam")
local AllParams = {
  longitudeDegrees = 1.1,
  latitudeDegrees = 1.1,
  address = {
    countryName = "countryName",
    countryCode = "countryCode",
    postalCode = "postalCode",
    administrativeArea = "administrativeArea",
    subAdministrativeArea = "subAdministrativeArea",
    locality = "locality",
    subLocality = "subLocality",
    thoroughfare = "thoroughfare",
    subThoroughfare = "subThoroughfare"
  },
  timeStamp = {
    second = 40,
    minute = 30,
    hour = 14,
    day = 25,
    month = 5,
    year = 2017,
    tz_hour = 5,
    tz_minute = 30
  },
  locationName = "location Name",
  locationDescription = "location Description",
  addressLines =
  {
    "line1",
    "line2",
  },
  phoneNumber = "phone Number",
  deliveryMode = "PROMPT",
  locationImage =
  {
    value = "icon.png",
    imageType = "DYNAMIC",
  }
}
function Test:SendLocation_OmitedAllParams_InBase4()
  self:verify_SUCCESS_Case(AllParams)
end
commonFunctions:newTestCasesGroup("End Test suit for coverage of CRQ APPLINK-24201")
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK II----------------------------------------
-----------------------------Check special cases of Mobile request----------------------------
----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-- Requirement id in JAMA or JIRA:
-- APPLINK-14765
-- APPLINK-16739
-- Verification criteria:
-- SDL must cut off the fake parameters from requests, responses and notifications received from HMI
-- In case the request comes to SDL with wrong json syntax, SDL must respond with resultCode "INVALID_DATA" and success:"false" value.
-----------------------------------------------------------------------------------------
-- List of test cases for softButtons type parameter:
-- 1. InvalidJSON
-- 2. CorrelationIdIsDuplicated
-- 3. FakeParams and FakeParameterIsFromAnotherAPI
-- 4. MissedAllParameters
-----------------------------------------------------------------------------------------------
local function special_request_checks()
  -- Begin Test case NegativeRequestCheck
  -- Description: Check negative request
  -- Print new line to separate new test cases group
  commonFunctions:newTestCasesGroup(self, "TestCaseGroupForAbnormal")
  -- Begin Test case NegativeRequestCheck.1
  -- Description: Invalid JSON
  function Test:SendLocation_InvalidJSON()
    self.mobileSession.correlationId = self.mobileSession.correlationId
    local msg =
    {
      serviceType = 7,
      frameInfo = 0,
      rpcType = 0,
      rpcFunctionId = 39,
      rpcCorrelationId = self.mobileSession.correlationId,
      --<<-- Missing :
      payload = '{"longitudeDegrees" 1.1, "latitudeDegrees":1.1}'
    }
    self.mobileSession:Send(msg)
    self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })
  end
  -- End Test case NegativeRequestCheck.1
  -----------------------------------------------------------------------------------------
  -- Begin Test case NegativeRequestCheck.2
  -- Description: Check CorrelationId duplicate value
  function Test:SendLocation_CorrelationIdIsDuplicated()
    -- mobile side: sending SendLocation request
    local cid = self.mobileSession:SendRPC("SendLocation",
    {
      longitudeDegrees = 1.1,
      latitudeDegrees = 1.1
    })
    -- request from mobile side
    local msg =
    {
      serviceType = 7,
      frameInfo = 0,
      rpcType = 0,
      rpcFunctionId = 39,
      rpcCorrelationId = cid,
      payload = '{"longitudeDegrees":1.1, "latitudeDegrees":1.1}'
    }
    -- hmi side: expect Navigation.SendLocation request
    EXPECT_HMICALL("Navigation.SendLocation",
    {
      longitudeDegrees = 1.1,
      latitudeDegrees = 1.1
    })
    :Do(function(exp,data)
      if exp.occurences == 1 then
        self.mobileSession:Send(msg)
      end
      -- hmi side: sending Navigation.SendLocation response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    :Times(2)

    -- response on mobile side
    EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"}):Times(1)

    -- Expected result should be changed as below after crq about same <correlationID> is implemented
    -- EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"},{ success = false, resultCode = "INVALID_DATA"})
    -- :Times(2)
  end
  -- End Test case NegativeRequestCheck.2
  -- ---------------------------------------------------------------------------------------
  -- Begin Test case NegativeRequestCheck.3
  -- Description: Fake parameters check
  -- Begin Test case NegativeRequestCheck.3.1
  -- Description: With fake parameters (SUCCESS)
  function Test:SendLocation_WithFakeParam()
    local Param = 	{
      longitudeDegrees = 1.1,
      latitudeDegrees = 1.1,
      locationName ="location Name",
      locationDescription ="location Description",
      addressLines =
      {
        "line1",
        "line2"
      },
      phoneNumber ="phone Number",
      locationImage =
      {
        value ="icon.png",
        imageType ="DYNAMIC",
        fakeParam ="fakeParam"
      },
      fakeParam ="fakeParam"
    }
    -- mobile side: sending SendLocation request
    local cid = self.mobileSession:SendRPC("SendLocation", Param)
    Param.fakeParam = nil
    Param.locationImage.fakeParam = nil
    -- hmi side: expect the request
    UIParams = self:createUIParameters(Param)
    EXPECT_HMICALL("Navigation.SendLocation", UIParams)
    :ValidIf(function(_,data)
      if data.params.fakeParam or
      data.params.locationImage.fakeParam then
        print(" \27[36m SDL re-sends fakeParam parameters to HMI \27[0m")
        return false
      else
        return true
      end
    end)
    :Do(function(_,data)
      -- hmi side: sending the response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    -- mobile side: expect the response
    EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  end
  -- End Test case NegativeRequestCheck.3.1
  -----------------------------------------------------------------------------------------
  -- Begin Test case NegativeRequestCheck.3.2
  -- Description: Check processing response with fake parameters from another API
  function Test:SendLocation_ParamsAnotherRequest()
    -- mobile side: sending SendLocation request
    local Param = 	{
      longitudeDegrees = 1.1,
      latitudeDegrees = 1.1,
      locationName ="location Name",
      locationDescription ="location Description",
      addressLines =
      {
        "line1",
        "line2"
      },
      phoneNumber ="phone Number",
      locationImage =
      {
        value ="icon.png",
        imageType ="DYNAMIC",
        cmdID = 1005,
      },
      cmdID = 1005,
    }
    local cid = self.mobileSession:SendRPC("SendLocation", Param)
    Param.cmdID = nil
    Param.locationImage.cmdID = nil
    -- hmi side: expect the request
    UIParams = self:createUIParameters(Param)
    EXPECT_HMICALL("Navigation.SendLocation", UIParams)
    :ValidIf(function(_,data)
      if data.params.cmdID or
      data.params.locationImage.cmdID then
        print(" \27[36m SDL re-sends cmdID parameters to HMI \27[0m")
        return false
      else
        return true
      end
    end)
    :Do(function(_,data)
      -- hmi side: sending the response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    -- mobile side: expect the response
    EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  end
  -- End Test case NegativeRequestCheck.3.2
  -- End Test case NegativeRequestCheck.3
  -----------------------------------------------------------------------------------------
  -- Begin Test case NegativeRequestCheck.4
  -- Description: All parameters missing
  function Test:SendLocation_MissedAllParameters()
    -- mobile side: sending SendLocation request
    local cid = self.mobileSession:SendRPC("SendLocation", {} )
    -- mobile side: expect the response
    EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
  end
  -- End Test case NegativeRequestCheck.4
  -- End Test case NegativeRequestCheck
end
special_request_checks()
-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK III--------------------------------------
----------------------------------Check normal cases of HMI response---------------------------
-----------------------------------------------------------------------------------------------
-- Requirement id in Jira: APPLINK-14551, APPLINK-8083, APPLINK-14765, APPLINK-21930
-- Verification criteria:
-- SDL behavior: cases when SDL must transfer "info" parameter via corresponding RPC to mobile app
-- SDL must return INVALID_DATA success:false to mobile app IN CASE any of the above requests comes with '\n' and '\t' symbols in param of 'string' type.
-- In case SDL cuts off fake parameters from response (request) that SDL should transfer to mobile app AND this response (request) is invalid SDL must respond GENERIC_ERROR (success:false, info: "Invalid message received from vehicle") to mobile app
-- The new "SAVED" resultCode must be added to "Result" enum of HMI_API
-----------------------------------------------------------------------------------------
--[[TODO: check after APPLINK-14765 is resolved
-----------------------------------------------------------------------------------------------
-- Parameter 1: resultCode
-- ---------------------------------------------------------------------------------------------
-- List of test cases:
-- 1. IsMissed
-- 2. IsValidValues
-- 3. IsNotExist
-- 4. IsEmpty
-- 5. IsWrongType
-- 6. IsInvalidCharacter - \n, \t
-----------------------------------------------------------------------------------------------
local function verify_resultCode_parameter()
  -- Print new line to separate new test cases group
  commonFunctions:newTestCasesGroup(self, "TestCaseGroupForResultCodeParameter")
  -----------------------------------------------------------------------------------------
  -- 1. IsMissed
  Test[APIName.."_Response_resultCode_IsMissed"] = function(self)
    -- mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
    -- hmi side: expect the request
    UIParams = self:createUIParameters(RequestParams)
    EXPECT_HMICALL("Navigation.SendLocation", UIParams)
    :Do(function(_,data)
      -- hmi side: sending the response
      -- self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"Navigation.SendLocation", "code":0}}')
      self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"Navigation.SendLocation"}}')
    end)
    -- mobile side: expect the response
    EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
  end
  -----------------------------------------------------------------------------------------
  -- 2. IsValidValue
  local ResultCodes = {
    {resultCode = "INVALID_DATA", success = false},
    {resultCode = "OUT_OF_MEMORY", success = false},
    {resultCode = "TOO_MANY_PENDING_REQUESTS", success = false},
    {resultCode = "APPLICATION_NOT_REGISTERED", success = false},
    {resultCode = "GENERIC_ERROR", success = false},
    {resultCode = "REJECTED", success = false},
    {resultCode = "DISALLOWED", success = false},
    {resultCode = "SAVED", success = true},
  }
  for i =1, #ResultCodes do
    Test[APIName.."_resultCode_IsValidValues_" .. ResultCodes[i].resultCode .."_SendResponse"] = function(self)
      -- mobile side: sending the request
      local RequestParams = Test:createRequest()
      local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
      -- hmi side: expect the request
      UIParams = self:createUIParameters(RequestParams)
      EXPECT_HMICALL("Navigation.SendLocation", UIParams)
      :Do(function(_,data)
        -- hmi side: sending the response
        self.hmiConnection:SendResponse(data.id, data.method, ResultCodes[i].resultCode, {})
      end)
      -- mobile side: expect SetGlobalProperties response
      EXPECT_RESPONSE(cid, { success = ResultCodes[i].success, resultCode = ResultCodes[i].resultCode})
    end
    -----------------------------------------------------------------------------------------
    Test[APIName.."_resultCode_IsValidValues_" .. ResultCodes[i].resultCode .."_SendError"] = function(self)
      -- mobile side: sending the request
      local RequestParams = Test:createRequest()
      local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
      -- hmi side: expect the request
      UIParams = self:createUIParameters(RequestParams)
      EXPECT_HMICALL("Navigation.SendLocation", UIParams)
      :Do(function(_,data)
        -- hmi side: sending the response
        self.hmiConnection:SendError(data.id, data.method, ResultCodes[i].resultCode, "info")
      end)
      -- mobile side: expect SetGlobalProperties response
      EXPECT_RESPONSE(cid, { success = ResultCodes[i].success, resultCode = ResultCodes[i].resultCode})
    end
  end
  -----------------------------------------------------------------------------------------
  -- 3. IsNotExist
  -- 4. IsEmpty
  -- 5. IsWrongType
  local TestData = {
    {value = "ANY", name = "IsNotExist"},
    {value = "", name = "IsEmpty"},
    {value = 123, name = "IsWrongType"},
  }
  for i =1, #TestData do
    Test[APIName.."_resultCode_" .. TestData[i].name .."_SendResponse"] = function(self)
      -- mobile side: sending the request
      local RequestParams = Test:createRequest()
      local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
      -- hmi side: expect the request
      UIParams = self:createUIParameters(RequestParams)
      EXPECT_HMICALL("Navigation.SendLocation", UIParams)
      :Do(function(_,data)
        -- hmi side: sending the response
        self.hmiConnection:SendResponse(data.id, data.method, TestData[i].value, {})
      end)
      -- mobile side: expect SetGlobalProperties response
      EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
    end
    -----------------------------------------------------------------------------------------
    Test[APIName.."_resultCode_" .. TestData[i].name .."_SendError"] = function(self)
      -- mobile side: sending the request
      local RequestParams = Test:createRequest()
      local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
      -- hmi side: expect the request
      UIParams = self:createUIParameters(RequestParams)
      EXPECT_HMICALL("Navigation.SendLocation", UIParams)
      :Do(function(_,data)
        -- hmi side: sending the response
        self.hmiConnection:SendError(data.id, data.method, TestData[i].value)
      end)
      -- mobile side: expect SetGlobalProperties response
      EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
    end
  end
end
verify_resultCode_parameter()
-----------------------------------------------------------------------------------------------
-- Parameter 2: method
-----------------------------------------------------------------------------------------------
-- List of test cases:
-- 1. IsMissed
-- 2. IsValidValue
-- 3. IsNotExist
-- 4. IsEmpty
-- 5. IsWrongType
-- 6. IsInvalidCharacter - \n, \t
-----------------------------------------------------------------------------------------------
local function verify_method_parameter()
  -- Print new line to separate new test cases group
  commonFunctions:newTestCasesGroup(self, "TestCaseGroupForMethodParameter")
  -----------------------------------------------------------------------------------------
  -- 1. IsMissed
  Test[APIName.."_Response_method_IsMissed_GENERIC_ERROR"] = function(self)
    -- mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
    -- hmi side: expect the request
    UIParams = self:createUIParameters(RequestParams)
    EXPECT_HMICALL("Navigation.SendLocation", UIParams)
    :Do(function(_,data)
      -- hmi side: sending the response
      -- self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"Navigation.SendLocation", "code":0}}')
      self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0}}')
    end)
    -- mobile side: expect the response
    EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
  end
  -----------------------------------------------------------------------------------------
  -- 2. IsValidValue
  Test[APIName.."_Response_method_IsValidValue_SendResponse"] = function(self)
    -- mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
    -- hmi side: expect the request
    UIParams = self:createUIParameters(RequestParams)
    EXPECT_HMICALL("Navigation.SendLocation", UIParams)
    :Do(function(_,data)
      -- hmi side: sending the response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    -- mobile side: expect SetGlobalProperties response
    EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
  end
  -----------------------------------------------------------------------------------------
  Test[APIName.."_Response_method_IsValidValue_SendError"] = function(self)
    -- mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
    -- hmi side: expect the request
    UIParams = self:createUIParameters(RequestParams)
    EXPECT_HMICALL("Navigation.SendLocation", UIParams)
    :Do(function(_,data)
      -- hmi side: sending the response
      self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "info")
    end)
    -- mobile side: expect SetGlobalProperties response
    EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "info"})
  end
  -----------------------------------------------------------------------------------------
  -- 3. IsNotExist
  -- 4. IsEmpty
  -- 5. IsWrongType
  -- 6. IsInvalidCharacter - \n, \t
  local Methods = {
    {method = "ANY", name = "IsNotExist"},
    {method = "", name = "IsEmpty"},
    {method = 123, name = "IsWrongType"},
    {method = "a\nb", name = "IsInvalidCharacter_NewLine"},
    {method = "a\tb", name = "IsInvalidCharacter_Tab"}
  }
  for i =1, #Methods do
    Test[APIName.."_Response_method_" .. Methods[i].name .."_GENERIC_ERROR_SendResponse"] = function(self)
      -- mobile side: sending the request
      local RequestParams = Test:createRequest()
      local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
      -- hmi side: expect the request
      UIParams = self:createUIParameters(RequestParams)
      EXPECT_HMICALL("Navigation.SendLocation", UIParams)
      :Do(function(_,data)
        -- hmi side: sending the response
        -- self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
        self.hmiConnection:SendResponse(data.id, Methods[i].method, "SUCCESS", {})
      end)
      -- mobile side: expect SetGlobalProperties response
      EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
    end
    -----------------------------------------------------------------------------------------
    Test[APIName.."_Response_method_" .. Methods[i].name .."_GENERIC_ERROR_SendError"] = function(self)
      -- mobile side: sending the request
      local RequestParams = Test:createRequest()
      local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
      -- hmi side: expect the request
      UIParams = self:createUIParameters(RequestParams)
      EXPECT_HMICALL("Navigation.SendLocation", UIParams)
      :Do(function(_,data)
        -- hmi side: sending the response
        -- self.hmiConnection:SendError(data.id, data.method, "UNSUPPORTED_RESOURCE", "info")
        self.hmiConnection:SendError(data.id, Methods[i].method, "UNSUPPORTED_RESOURCE", "info")
      end)
      -- mobile side: expect SetGlobalProperties response
      EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
    end
  end
end
verify_method_parameter()
--]]
----------------------------------------------------------------------------------------------
-- Parameter 3: info
-----------------------------------------------------------------------------------------------
-- List of test cases:
-- 1. IsMissed
-- 2. IsLowerBound
-- 3. IsUpperBound
-- 4. IsOutUpperBound
-- 5. IsEmpty/IsOutLowerBound
-- 6. IsWrongType
-- 7. InvalidCharacter - \n, \t
-----------------------------------------------------------------------------------------------
local function verify_info_parameter()
  -- Print new line to separate new test cases group
  commonFunctions:newTestCasesGroup(self, "TestCaseGroupForInfoParameter")
  -----------------------------------------------------------------------------------------
  -- 1. IsMissed
  Test[APIName.."_info_IsMissed_SendResponse"] = function(self)
    -- mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
    -- hmi side: expect the request
    UIParams = self:createUIParameters(RequestParams)
    EXPECT_HMICALL("Navigation.SendLocation", UIParams)
    :Do(function(_,data)
      -- hmi side: sending the response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    -- mobile side: expect the response
    EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
    :ValidIf (function(_,data)
      if data.payload.info then
        print(" \27[32m SDL resends invalid info parameter to mobile app. \27[0m")
        return false
      else
        return true
      end
    end)
  end
  -----------------------------------------------------------------------------------------
  Test[APIName.."_info_IsMissed_SendError"] = function(self)
    -- mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
    -- hmi side: expect the request
    UIParams = self:createUIParameters(RequestParams)
    EXPECT_HMICALL("Navigation.SendLocation", UIParams)
    :Do(function(_,data)
      -- hmi side: sending the response
      self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR")
    end)
    -- mobile side: expect the response
    EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
    :ValidIf (function(_,data)
      if data.payload.info then
        print(" \27[32m SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\" \27[0m")
        return false
      else
        return true
      end
    end)
  end
  -----------------------------------------------------------------------------------------
  -- 2. IsLowerBound
  -- 3. IsUpperBound
  local TestData = {
    {value = "a", name = "IsLowerBound"},
  {value = commonFunctions:createString(1000), name = "IsUpperBound"}}
  for i =1, #TestData do
    Test[APIName.."_info_" .. TestData[i].name .."_SendResponse"] = function(self)
      -- mobile side: sending the request
      local RequestParams = Test:createRequest()
      local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
      -- hmi side: expect the request
      UIParams = self:createUIParameters(RequestParams)
      EXPECT_HMICALL("Navigation.SendLocation", UIParams)
      :Do(function(_,data)
        -- hmi side: sending the response
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {message = TestData[i].value})
      end)
      -- mobile side: expect SetGlobalProperties response
      EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = TestData[i].value})
    end
    -----------------------------------------------------------------------------------------
    Test[APIName.."_info_" .. TestData[i].name .."_SendError"] = function(self)
      -- mobile side: sending the request
      local RequestParams = Test:createRequest()
      local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
      -- hmi side: expect the request
      UIParams = self:createUIParameters(RequestParams)
      EXPECT_HMICALL("Navigation.SendLocation", UIParams)
      :Do(function(_,data)
        -- hmi side: sending the response
        self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", TestData[i].value)
      end)
      -- mobile side: expect SetGlobalProperties response
      EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = TestData[i].value})
    end
  end
  -----------------------------------------------------------------------------------------
  -- 4. IsOutUpperBound
  Test[APIName.."_info_IsOutUpperBound_SendResponse"] = function(self)
    local infoMaxLength = commonFunctions:createString(1000)
    -- mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
    -- hmi side: expect the request
    UIParams = self:createUIParameters(RequestParams)
    EXPECT_HMICALL("Navigation.SendLocation", UIParams)
    :Do(function(_,data)
      -- hmi side: sending the response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {message = infoMaxLength .. "1"})
    end)
    -- mobile side: expect SetGlobalProperties response
    EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = infoMaxLength})
  end
  -----------------------------------------------------------------------------------------
  Test[APIName.."_info_IsOutUpperBound_SendError"] = function(self)
    local infoMaxLength = commonFunctions:createString(1000)
    -- mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
    -- hmi side: expect the request
    UIParams = self:createUIParameters(RequestParams)
    EXPECT_HMICALL("Navigation.SendLocation", UIParams)
    :Do(function(_,data)
      -- hmi side: sending the response
      self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoMaxLength .."1")
    end)
    -- mobile side: expect SetGlobalProperties response
    EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = infoMaxLength})
  end
  -----------------------------------------------------------------------------------------
  -- 5. IsEmpty/IsOutLowerBound
  -- 6. IsWrongType
  -- 7. InvalidCharacter - \n, \t, white spaces only
  local TestData = {
    {value = "", name = "IsEmpty_IsOutLowerBound"},
    {value = 123, name = "IsWrongType"},
    {value = "a\nb", name = "IsInvalidCharacter_NewLine"},
    {value = "a\tb", name = "IsInvalidCharacter_Tab"},
  {value = " ", name = "WhiteSpacesOnly"}}
  for i =1, #TestData do
    Test[APIName.."_info_" .. TestData[i].name .."_SendResponse"] = function(self)
      -- mobile side: sending the request
      local RequestParams = Test:createRequest()
      local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
      -- hmi side: expect the request
      UIParams = self:createUIParameters(RequestParams)
      EXPECT_HMICALL("Navigation.SendLocation", UIParams)
      :Do(function(_,data)
        -- hmi side: sending the response
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {message = TestData[i].value})
      end)
      -- mobile side: expect SetGlobalProperties response
      EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
      :ValidIf (function(_,data)
        if data.payload.info then
          print(" \27[32m SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\" \27[0m")
          return false
        else
          return true
        end
      end)
    end
    -----------------------------------------------------------------------------------------
    Test[APIName.."_info_" .. TestData[i].name .."_SendError"] = function(self)
      -- mobile side: sending the request
      local RequestParams = Test:createRequest()
      local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
      -- hmi side: expect the request
      UIParams = self:createUIParameters(RequestParams)
      EXPECT_HMICALL("Navigation.SendLocation", UIParams)
      :Do(function(_,data)
        -- hmi side: sending the response
        self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", TestData[i].value)
      end)
      -- mobile side: expect SetGlobalProperties response
      EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
      :ValidIf (function(_,data)
        if data.payload.info then
          print(" \27[32m SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\" \27[0m")
          return false
        else
          return true
        end
      end)
    end
  end
end
verify_info_parameter()
--[[TODO: check after APPLINK-14765 is resolved
-----------------------------------------------------------------------------------------------
-- Parameter 4: correlationID
-- ---------------------------------------------------------------------------------------------
-- List of test cases:
-- 1. CorrelationIDMissing
-- 2. CorrelationIDWrongType
-- 3. CorrelationIDNotExisted
-- 4. CorrelationIDNegative
-- 5. CorrelationIDNull
-----------------------------------------------------------------------------------------------
local function verify_correlationID_parameter()
  -- Print new line to separate new test cases group
  commonFunctions:newTestCasesGroup("TestCaseGroupForCorrelationIDParameter")
  -----------------------------------------------------------------------------------------
  -- 1. CorrelationIDMissing
  Test[APIName.."_Response_CorrelationIDMissing"] = function(self)
    -- mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
    -- hmi side: expect the request
    UIParams = self:createUIParameters(RequestParams)
    EXPECT_HMICALL("Navigation.SendLocation", UIParams)
    :Do(function(_,data)
      -- hmi side: sending the response
      -- self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"Navigation.SendLocation", "code":0}}')
      self.hmiConnection:Send('{"jsonrpc":"2.0","result":{"method":"Navigation.SendLocation", "code":0}}')
    end)
    -- mobile side: expect the response
    EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
  end
  -----------------------------------------------------------------------------------------
  -- 2. CorrelatioIDWrongType
  Test[APIName.."_Response_CorrelationIDWrongType"] = function(self)
    -- mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
    -- hmi side: expect the request
    UIParams = self:createUIParameters(RequestParams)
    EXPECT_HMICALL("Navigation.SendLocation", UIParams)
    :Do(function(_,data)
      -- hmi side: sending the response
      self.hmiConnection:SendResponse(tostring(data.id), data.method, "SUCCESS", {})
    end)
    -- mobile side: expect the response
    EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
  end
  -----------------------------------------------------------------------------------------
  -- 3. CorrelationIDNotExisted
  Test[APIName.."_Response_CorrelationIDNotExisted"] = function(self)
    -- mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
    -- hmi side: expect the request
    UIParams = self:createUIParameters(RequestParams)
    EXPECT_HMICALL("Navigation.SendLocation", UIParams)
    :Do(function(_,data)
      -- hmi side: sending the response
      self.hmiConnection:SendResponse(9999, data.method, "SUCCESS", {})
    end)
    -- mobile side: expect the response
    EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
  end
  -----------------------------------------------------------------------------------------
  -- 4. CorrelationIDNegative
  Test[APIName.."_Response_CorrelationIDNegative"] = function(self)
    -- mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
    -- hmi side: expect the request
    UIParams = self:createUIParameters(RequestParams)
    EXPECT_HMICALL("Navigation.SendLocation", UIParams)
    :Do(function(_,data)
      -- hmi side: sending the response
      self.hmiConnection:SendResponse(-1, data.method, "SUCCESS", {})
    end)
    -- mobile side: expect the response
    EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
  end
  -----------------------------------------------------------------------------------------
  -- 5. CorrelationIDNull
  Test[APIName.."_Response_CorrelationIDNull"] = function(self)
    -- mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
    -- hmi side: expect the request
    UIParams = self:createUIParameters(RequestParams)
    EXPECT_HMICALL("Navigation.SendLocation", UIParams)
    :Do(function(_,data)
      -- hmi side: sending the response
    self.hmiConnection:Send('"id":null,"jsonrpc":"2.0","result":{"code":0,"method":"Navigation.SendLocation"}}')
  end)
  -- mobile side: expect the response
  EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
end
end
verify_correlationID_parameter()
--]]
----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK IV----------------------------------------
------------------------------Check special cases of HMI response-----------------------------
----------------------------------------------------------------------------------------------
-- Requirement id in JAMA: APPLINK-14765
-- Verification criteria: 	In case SDL cuts off fake parameters from response (request) that SDL should transfer to mobile app AND this response (request) is invalid SDL must respond GENERIC_ERROR (success:false, info: "Invalid message received from vehicle") to mobile app
-----------------------------------------------------------------------------------------------
-- List of test cases for softButtons type parameter:
-- 1. InvalidJsonSyntax
-- 2. InvalidStructure
-- 2. DuplicatedCorrelationId
-- 3. FakeParams and FakeParameterIsFromAnotherAPI
-- 4. MissedAllPArameters
-- 5. NoResponse
-- 6. SeveralResponsesToOneRequest with the same and different resultCode
-----------------------------------------------------------------------------------------------
local function special_response_checks()
  -- Begin Test case NegativeResponseCheck
  -- Description: Check all negative response cases
  -- Print new line to separate new test cases group
  commonFunctions:newTestCasesGroup(self, "NewTestCasesGroupForNegativeResponseCheck")
  -- Begin Test case NegativeResponseCheck.1
  -- Description: Invalid JSON
  --[[ToDo: Check after APPLINK-14765 is resolved
  function Test:SendLocation_InvalidJsonSyntaxResponse()
    -- mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
    -- hmi side: expect the request
    local UIParams = self:createUIParameters(RequestParams)
    EXPECT_HMICALL("Navigation.SendLocation", UIParams)
    :Do(function(_,data)
      -- hmi side: sending the response
      -- ":" is changed by ";" after {"id"
        -- self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"Navigation.SendLocation", "code":0}}')
        self.hmiConnection:Send('{"id";'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"Navigation.SendLocation", "code":0}}')
      end)
      -- mobile side: expect the response
      EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
    end
    -- End Test case NegativeResponseCheck.1
    -----------------------------------------------------------------------------------------
    -- Begin Test case NegativeResponseCheck.2
    -- Description: Invalid structure of response
    function Test:SendLocation_InvalidStructureResponse()
      -- mobile side: sending the request
      local RequestParams = Test:createRequest()
      local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
      -- hmi side: expect the request
      local UIParams = self:createUIParameters(RequestParams)
      EXPECT_HMICALL("Navigation.SendLocation", UIParams)
      :Do(function(_,data)
        -- hmi side: sending the response
        -- self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"Navigation.SendLocation", "code":0}}')
        self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0", "code":0, "result":{"method":"Navigation.SendLocation"}}')
      end)
      -- mobile side: expect response
      EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
    end
    -- End Test case NegativeResponseCheck.2
    ]]
  -----------------------------------------------------------------------------------------
  -- Begin Test case NegativeResponseCheck.3
  -- Description: Check processing response with fake parameters
  -- Requirement id in JAMA/or Jira ID: APPLINK-14765
  -- Verification criteria: SDL must cut off the fake parameters from requests, responses and notifications received from HMI
  -- Begin Test case NegativeResponseCheck.3.1
  -- Description: Parameter is not from API
  function Test:SendLocation_FakeParamsInResponse()
    -- mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
    -- hmi side: expect the request
    local UIParams = self:createUIParameters(RequestParams)
    EXPECT_HMICALL("Navigation.SendLocation", UIParams)
    :Do(function(exp,data)
      -- hmi side: sending the response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {fake = "fake"})
    end)
    -- mobile side: expect the response
    EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
    :ValidIf (function(_,data)
      if data.payload.fake then
        print(" \27[32m SDL resend fake parameter to mobile app \27[0m")
        return false
      else
        return true
      end
    end)
  end
  -- End Test case NegativeResponseCheck.3.1
  -----------------------------------------------------------------------------------------
  -- Begin Test case NegativeResponseCheck.3.2
  -- Description: Parameter is not from another API
  function Test:SendLocation_AnotherParameterInResponse()
    -- mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
    -- hmi side: expect the request
    local UIParams = self:createUIParameters(RequestParams)
    EXPECT_HMICALL("Navigation.SendLocation", UIParams)
    :Do(function(exp,data)
      -- hmi side: sending the response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 5})
    end)
    -- mobile side: expect the response
    EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
    :ValidIf (function(_,data)
      if data.payload.sliderPosition then
        print(" \27[32m SDL resend fake parameter to mobile app \27[0m")
        return false
      else
        return true
      end
    end)
  end
  -- End Test case NegativeResponseCheck.3.2
  -- End Test case NegativeResponseCheck.3
  -----------------------------------------------------------------------------------------
  -- Begin NegativeResponseCheck.4
  -- Description: Check processing response without all parameters
  --[[TODO: Check after APPLINK-14765 is resolved
  function Test:SendLocation_Response_MissedAllPArameters()
    -- mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
    -- hmi side: expect the request
    UIParams = self:createUIParameters(RequestParams)
    EXPECT_HMICALL("Navigation.SendLocation", UIParams)
    :Do(function(_,data)
      -- hmi side: sending Navigation.SendLocation response
      -- self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"Navigation.SendLocation", "code":0}}')
      self.hmiConnection:Send('{}')
    end)
    -- mobile side: expect the response
    EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
  end
  ]]
  -- End NegativeResponseCheck.4
  -----------------------------------------------------------------------------------------
  -- Begin Test case NegativeResponseCheck.5
  -- Description: request without responses from HMI
  function Test:SendLocation_NoResponse()
    -- mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
    -- hmi side: expect the request
    local UIParams = self:createUIParameters(RequestParams)
    EXPECT_HMICALL("Navigation.SendLocation", UIParams)
    -- mobile side: expect SetGlobalProperties response
    EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Navigation component does not respond"})
    :Timeout(12000)
  end
  -- End NegativeResponseCheck.5
  -----------------------------------------------------------------------------------------
  -- Begin Test case NegativeResponseCheck.6
  -- Description: Several response to one request
  function Test:SendLocation_SeveralResponsesToOneRequest()
    -- mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
    -- hmi side: expect the request
    local UIParams = self:createUIParameters(RequestParams)
    EXPECT_HMICALL("Navigation.SendLocation", UIParams)
    :Do(function(exp,data)
      -- hmi side: sending the response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "")
      self.hmiConnection:SendError(data.id, data.method, "REJECTED", "")
    end)
    -- mobile side: expect response
    EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
  end
  -- End Test case NegativeResponseCheck.6
  -----------------------------------------------------------------------------------------
  --[[TODO: Check after APPLINK-14765 is resolved
  -- Begin Test case NegativeResponseCheck.7
  -- Description: Wrong response to correct correlationID
  function Test:SendLocation_WrongResponse()
    -- mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
    -- hmi side: expect the request
    local UIParams = self:createUIParameters(RequestParams)
    EXPECT_HMICALL("Navigation.SendLocation", UIParams)
    :Do(function(exp,data)
      -- hmi side: sending the response
      self.hmiConnection:Send('{"error":{"code":4,"message":"SendLocation is REJECTED"},"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0,"method":"Navigation.SendLocation"}}')
    end)
    -- mobile side: expect response
    EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
  end
  -- End Test case NegativeResponseCheck.7
  --]]
  -- End Test case NegativeResponseCheck
end
special_response_checks()
-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK V----------------------------------------
-------------------------------------Checks All Result Codes-----------------------------------
-----------------------------------------------------------------------------------------------
-- Requirement id in JAMA: APPLINK-9735, SDLAQ-CRS-2396
-- Verification criteria:
--[[
-- An RPC request is not allowed by the backend. Policies Manager validates it as "disallowed".
-- 1) SDL must support the following result-codes:
-- 1.3) USER_DISALLOWED -
-- SDL must return 'user_dissallowed, success:false' in case the SendLocation RPC is included to the group disallowed by the user.
-- 1.4.) WARNINGS
-- In case SDL receives WARNINGS from HMI, SDL must transfer this resultCode with adding 'success:true' to mobile app.
-- The use case: requested image is corrupted or does not exist by the defined path -> HMI displays all other requested info and returns WARNINGS with problem description -> SDL transfers 'warnings, success:true' to mobile app.
--]]
local function result_code_checks()
  -- Print new line to separate new test cases group
  commonFunctions:newTestCasesGroup(self, "NewTestCasesGroupForResultCodeChecks")
  --------------------------------------------------------------------------------
  -- Description: Check resultCode APPLICATION_NOT_REGISTERED
  function Test:Precondition_CreationNewSession()
    -- Connected expectation
    self.mobileSession2 = mobile_session.MobileSession(
    self,
    self.mobileConnection
    )
  end
  function Test:SendLocation_resultCode_APPLICATION_NOT_REGISTERED()
    -- mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession2:SendRPC("SendLocation", RequestParams)
    -- mobile side: expect response
    self.mobileSession2:ExpectResponse(cid, { success = false, resultCode = "APPLICATION_NOT_REGISTERED"})
  end
  -----------------------------------------------------------------------------------------
  -- Description: Check resultCode DISALLOWED when HMI level is NONE >> Covered by test case SendLocation_HMIStatus_NONE
  -----------------------------------------------------------------------------------------
  -- Description: Check resultCode DISALLOWED when request is not assigned to app
  policyTable:checkPolicyWhenAPIIsNotExist()
  -----------------------------------------------------------------------------------------
  -- Description: Check resultCode USER_DISALLOWED when request is assigned to app but user does not allow
  policyTable:checkPolicyWhenUserDisallowed({"FULL", "LIMITED", "BACKGROUND"})
  -- Postcondition: Allow consents
  policyTable:userConsent(true)
  -----------------------------------------------------------------------------------------
  -- Description: Check resultCode WARNINGS
  function Test:SendLocation_resultCode_WARNINGS()
    -- mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
    -- hmi side: expect the request
    local UIParams = self:createUIParameters(RequestParams)
    EXPECT_HMICALL("Navigation.SendLocation", UIParams)
    :Do(function(exp,data)
      -- hmi side: sending the response
      self.hmiConnection:SendResponse(data.id, data.method, "UNSUPPORTED_RESOURCE", {message = "HMI doesn't support STATIC, DYNAMIC or any image types which exist in request data"})
    end)
    -- mobile side: expect response
    -- EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS", info = "HMI doesn't support STATIC, DYNAMIC or any image types which exist in request data"})
    EXPECT_RESPONSE(cid, { success = true, resultCode = "UNSUPPORTED_RESOURCE" })
  end
end
result_code_checks()
----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VI----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------
-- Not Applicable
----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VII---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------
local function different_hmilevel_checks()
  -- Print new line to separate new test cases group
  commonFunctions:newTestCasesGroup(self, "NewTestCasesGroupForSequenceChecks")
  -----------------------------------------------------------------------------------------
  -- Description: Check request is disallowed in NONE HMI level
  function Test:Precondition_DeactivateToNone()
    -- hmi side: sending BasicCommunication.OnExitApplication notification
    self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {appID = self.applications["Test Application"], reason = "USER_EXIT"})
    EXPECT_NOTIFICATION("OnHMIStatus",
    { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
  end
  function Test:SendLocation_HMIStatus_NONE()
    -- mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
    -- mobile side: expect response
    EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED"})
  end
  -- Postcondition: Activate app
  commonSteps:ActivationApp(self)
  -----------------------------------------------------------------------------------------
  -- Description: Check HMI level Full: covered by above test cases
  -----------------------------------------------------------------------------------------
  -- Description: Check HMI level LIMITED
  if
  Test.isMediaApplication == true or
  Test.appHMITypes["NAVIGATION"] == true then
    -- Precondition: Deactivate app to LIMITED HMI level
    commonSteps:ChangeHMIToLimited(self)
    function Test:SendLocation_HMIStatus_LIMITED()
      local RequestParams = Test:createRequest()
      self:verify_SUCCESS_Case(RequestParams)
    end
    -----------------------------------------------------------------------------------
    -- Description: Check HMI level BACKGROUND
    -- Precondition 1: Opening new session
    function Test:AddNewSession()
      -- Connected expectation
      self.mobileSession1 = mobile_session.MobileSession(
      self,
      self.mobileConnection)
      self.mobileSession1:StartService(7)
    end
    -- Precondition 2: Register app2
    function Test:RegisterAppInterface_App2()
      -- mobile side: RegisterAppInterface request
      local CorIdRAI = self.mobileSession1:SendRPC("RegisterAppInterface",
      {
        syncMsgVersion =
        {
          majorVersion = 2,
          minorVersion = 2,
        },
        appName ="SPT2",
        isMediaApplication = true,
        appHMIType = config.application1.registerAppInterfaceParams.appHMIType,
        languageDesired ="EN-US",
        hmiDisplayLanguageDesired ="EN-US",
        appID ="2",
        ttsName =
        {
          {
            text ="SyncProxyTester2",
            type ="TEXT",
          },
        },
        vrSynonyms =
        {
          "vrSPT2",
        }
      })
      -- hmi side: expect BasicCommunication.OnAppRegistered request
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
      {
        application =
        {
          appName = "SPT2"
        }
      })
      :Do(function(_,data)
        self.applications["SPT2"] = data.params.application.appID
      end)
      -- mobile side: RegisterAppInterface response
      self.mobileSession1:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
      :Timeout(2000)
      self.mobileSession1:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    end
    -- Precondition 3: Activate an other media app to change app to BACKGROUND
    function Test:Activate_Media_App2()
      -- HMI send ActivateApp request
      local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["SPT2"]})
      EXPECT_HMIRESPONSE(RequestId)
      :Do(function(_,data)
        if data.result.isSDLAllowed ~= true then
          local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
          EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
          :Do(function(_,data)
            -- hmi side: send request SDL.OnAllowSDLFunctionality
            self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = 1, name = "127.0.0.1"}})
          end)
          EXPECT_HMICALL("BasicCommunication.ActivateApp")
          :Do(function(_,data)
            self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
          end)
          :Times(2)
        end
      end)
      self.mobileSession1:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
      :Timeout(12000)
      self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    end
  elseif Test.isMediaApplication == false then
    -- Precondition: Deactivate app to BACKGOUND HMI level
    commonSteps:DeactivateToBackground(self)
  end
  -- Description: Check HMI level BACKGOUND
  function Test:SendLocation_HMIStatus_BACKGOUND()
    local RequestParams = Test:createRequest()
    self:verify_SUCCESS_Case(RequestParams)
  end
end
different_hmilevel_checks()
-- Postcondition: restoring hmi_capabilities.json to original
-- TODO: need to be removed after resolving APPLINK-17511
function Test:Postcondition_RestoringHmiCapabilitiesFile()
  str = tostring(config.pathToSDL)
  local PathToSDLWihoutBin = string.gsub(str, "bin/", "")
  OriginalHmiCapabilitiesFile = PathToSDLWihoutBin .. "src/appMain/hmi_capabilities.json"
  os.execute( " cp " .. tostring(OriginalHmiCapabilitiesFile) .. " " .. tostring(config.pathToSDL) .. "" )
end
--------------------------------------------------------------------------------------------------------
return Test