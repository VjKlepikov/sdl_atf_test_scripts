-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

------------------------------------ Common Variables ---------------------------------------
local invalid_character = {
  {value = "1\n", description = "NextLineCharacter"},
  {value = "2\t", description = "TabCharacter"},
  {value = 1, description = "WrongType"},
  {value = " ", description = "WhiteSpace"},
  {value = "", description = "Empty"},
  {value = nil, description = "Omit"}
}
local invalid_values_usbTransportStatus = {
  {value = "", description = "Empty"},
  {value = "ABLED", description = "non existent value"}
}
local invalid_values_transporttype = {
  {value = "", description = "Empty"},
  {value = "NEW", description = "non existent value"}
}
local invalid_values_issdlallowed = {
  {value = 1, description = "WrongType"},
  {value = "NEW", description = "non existent value"}
}
------------------------------------ Common Functions ---------------------------------------
-- Remove existed snapshot file
os.execute( "rm -f /tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json" )

-- Get string value of usbTransportStatus
local function getBooleanValueOFUserSetting(stringValue)
  if stringValue == "ENABLED" then
    return '1'
  elseif stringValue == "DISABLED" then
    return '0'
  else
    return nil
  end
end

-- Add records to device table of database
local function AddRecordsIntoLPT(test_case_name, list_records)
  Test[test_case_name .. "_AddRecordsToDB"] = function(self)
    local policy_file = config.pathToSDL .. "storage/policy.sqlite"
    local policy_file_temp = "/tmp/policy.sqlite"
    os.execute("cp " .. policy_file .. " " .. policy_file_temp)
    for i = 1, #list_records do
      local sql_query = "INSERT INTO DEVICE (id, hardware, firmware_rev, os, os_version, carrier, max_number_rfcom_ports, connection_type, usb_transport_enabled, unpaired) Values ("
      .. tostring(list_records[i].id) ..", ".."'" .. list_records[i].name .. "', 'Name: Linux, Version: 3.4.0-perf', 'Android', '4.4.2', 'Megafon', 1, '"
      .. list_records[i].transport_type .. "', '" .. getBooleanValueOFUserSetting(list_records[i].usb_transport_enabled) .."', 0);"
      ful_sql_query = "sqlite3 " .. policy_file_temp .. " \"" .. sql_query .. "\""
      handler = io.popen(ful_sql_query, 'r')
      handler:close()
    end
    os.execute("sleep 1")
    os.execute("cp " .. policy_file_temp .. " " .. policy_file)
  end
end

-- Check GetDeviceConnectionStatus API when sending with invalid ID
local function GetDeviceConnectionStatusWithInvalid_Id(test_case_name)
  for i = 1, #invalid_character do
    Test[test_case_name .. "_" .. tostring(invalid_character[i].description) .. "_In_ID"] = function(self)
      local request_id = self.hmiConnection:SendRequest("SDL.GetDeviceConnectionStatus", {device = {
            { id = invalid_character[i].value, name = "Samsung"}
        }})
      EXPECT_HMIRESPONSE(request_id, {error = {code = 11, data = {method = "SDL.GetDeviceConnectionStatus"}}})
    end
  end
end

-- Check GetDeviceConnectionStatus API when sending with invalid Name
local function GetDeviceConnectionStatusWithInvalid_Name(test_case_name)
  for i = 1, #invalid_character do
    Test[test_case_name .. "_" .. tostring(invalid_character[i].description) .. "_In_Name"] = function(self)
      local request_id = self.hmiConnection:SendRequest("SDL.GetDeviceConnectionStatus", {device = {
            { id = "1" , name = invalid_character[i].value}
        }})
      EXPECT_HMIRESPONSE(request_id, {error = {code = 11, data = {method = "SDL.GetDeviceConnectionStatus"}}})
    end
  end
end

-- Check GetDeviceConnectionStatus API when sending with invalid usbTransportStatus
local function GetDeviceConnectionStatusWithInvalid_usbTransportStatus(test_case_name)
  for i = 1, #invalid_values_usbTransportStatus do
    Test[test_case_name .. "_" .. tostring(invalid_values_usbTransportStatus[i].description) .. "_In_usbTransportStatus"] = function(self)
      local request_id = self.hmiConnection:SendRequest("SDL.GetDeviceConnectionStatus", {device = {
            { id = "1" , name = "Samsung", usbTransportStatus = invalid_values_usbTransportStatus[i].value}
        }})
      EXPECT_HMIRESPONSE(request_id, {error = {code = 11, data = {method = "SDL.GetDeviceConnectionStatus"}}})
    end
  end
end

-- Check GetDeviceConnectionStatus API when sending with invalid transportType
local function GetDeviceConnectionStatusWithInvalid_transportType(test_case_name)
  for i = 1, #invalid_values_transporttype do
    Test[test_case_name .. "_" .. tostring(invalid_values_transporttype[i].description) .. "_In_usbTransportStatus"] = function(self)
      local request_id = self.hmiConnection:SendRequest("SDL.GetDeviceConnectionStatus", {device = {
            { id = "1" , name = "Samsung", usbTransportStatus = invalid_values_transporttype[i].value}
        }})
      EXPECT_HMIRESPONSE(request_id, {error = {code = 11, data = {method = "SDL.GetDeviceConnectionStatus"}}})
    end
  end
end

-- Check GetDeviceConnectionStatus API when sending with invalid isSDLAllowed
local function GetDeviceConnectionStatusWithInvalid_issdlallowed(test_case_name)
  for i = 1, #invalid_values_issdlallowed do
    Test[test_case_name .. "_" .. tostring(invalid_values_issdlallowed[i].description) .. "_In_isSDLAllowed"] = function(self)
      local request_id = self.hmiConnection:SendRequest("SDL.GetDeviceConnectionStatus", {device = {
            { id = "1" , name = "Samsung", isSDLAllowed = invalid_values_issdlallowed[i].value}
        }})
      EXPECT_HMIRESPONSE(request_id, {error = {code = 11, data = {method = "SDL.GetDeviceConnectionStatus"}}})
    end
  end
end

-- Check GetDeviceConnectionStatus API when sending with invalid JSon
local function GetDeviceConnectionStatusWithInvalidJson(test_case_name)
  Test[test_case_name .. "_InvalidJSon"] = function(self)
    local request_id = self.hmiConnection:Send('{"params":{"device":[{"name":"Samsung","id":"1"}]},"id":55,"method":"SDL.GetDeviceConnectionStatus","jsonrpc":"2.0"}')
    EXPECT_HMIRESPONSE(request_id, {error = {code = 11, data = {method = "SDL.GetDeviceConnectionStatus"}, message = "HMIDeactivate is active"}})
    :Times(0)
  end
end

-- Check GetDeviceConnectionStatus API when sending with 1 device param and this record is existed in DB
-- @record: record which will be query from HMI
-- @flag: if flag = true then check @record = expect. If flag = false then check @record.id and @record.name only
local function GetDeviceConnectionStatusWith1FoundDeviceParam(test_case_name, record, flag)
  Test[test_case_name] = function(self)
    local request_id = self.hmiConnection:SendRequest("SDL.GetDeviceConnectionStatus", {device = {
          { id = tostring(record.id), name = record.name, transportType = record.transport_type, usbTransportStatus = record.usb_transport_enabled }
      }})
    if flag == nil then
      EXPECT_HMIRESPONSE(request_id, {device = {
            {id = tostring(record.id), name = record.name, transportType = record.transport_type, usbTransportStatus = record.usb_transport_enabled }
        }, method = "SDL.GetDeviceConnectionStatus"})
    elseif flag == false then
      EXPECT_HMIRESPONSE(request_id, {device = {
            {id = tostring(record.id), name = record.name }}, method = "SDL.GetDeviceConnectionStatus"})
    end
  end
end

-- Check GetDeviceConnectionStatus API when sending with 1 device param and this record is not existed in DB
-- @record: record which will be query from HMI
local function GetDeviceConnectionStatusWith1NotFoundDeviceParam(test_case_name, record)
  Test[test_case_name] = function(self)
    local request_id = self.hmiConnection:SendRequest("SDL.GetDeviceConnectionStatus", {device = {
          { id = tostring(record.id), name = record.name, transportType = record.transport_type, usbTransportStatus = record.usb_transport_enabled }
      }})
    EXPECT_HMIRESPONSE(request_id, {device = {}, method = "SDL.GetDeviceConnectionStatus"})
  end
end

-- Check GetDeviceConnectionStatus API when sending with 2 devices param
-- @record1: record which will be query from HMI and found in DB
-- @record2: record which will be query from HMI but not found in DB
-- @notification: false: only record1 is existed in DB. True: both 2 records are found
local function GetDeviceConnectionStatusWith2DevicesParam(test_case_name, record1, record2, notification)
  Test[test_case_name] = function(self)
    local request_id = self.hmiConnection:SendRequest("SDL.GetDeviceConnectionStatus", {device = {
          {id = tostring(record1.id), name = record1.name},
          {id = tostring(record2.id), name = record2.name},
      }})
    local list_device = {}
    if notification == false then
      list_device[1] = {id = tostring(record1.id), name = record1.name, transportType = record1.transport_type, usbTransportStatus = record1.usb_transport_enabled }
    else
      list_device[1] = {id = tostring(record1.id), name = record1.name, transportType = record1.transport_type, usbTransportStatus = record1.usb_transport_enabled }
      list_device[2] = {id = tostring(record2.id), name = record2.name, transportType = record2.transport_type, usbTransportStatus = record2.usb_transport_enabled }
    end
    EXPECT_HMIRESPONSE(request_id, {device = list_device, method = "SDL.GetDeviceConnectionStatus"})
  end
end

-- Check GetDeviceConnectionStatus API when sending with 100 devices param
local function GetDeviceConnectionStatusWith100DevicesParam(test_case_name)
  Test[test_case_name] = function(self)
    local list_device = {}
    for i = 101, 125 do
      list_device[i-100] = {id = tostring(i), name = "Samsung", transportType = "USB_AOA", usbTransportStatus = "DISABLED"}
    end
    for i = 126, 150 do
      list_device[i-100] = {id = tostring(i), name = "Samsung", transportType = "USB_AOA", usbTransportStatus = "ENABLED"}
    end
    for i = 151, 175 do
      list_device[i-100] = {id = tostring(i), name = "Samsung", transportType = "BLUETOOTH", usbTransportStatus = "ENABLED"}
    end
    for i = 176, 200 do
      list_device[i-100] = {id = tostring(i), name = "Samsung", transportType = "WIFI", usbTransportStatus = "ENABLED"}
    end
    local request_id = self.hmiConnection:SendRequest("SDL.GetDeviceConnectionStatus", {device = list_device})
    EXPECT_HMIRESPONSE(request_id, {device = list_device, method = "SDL.GetDeviceConnectionStatus"})
  end
end

-- Check GetDeviceConnectionStatus API when sending with 0/ 101 element in array
local function GetDeviceConnectionStatusOutOfArray(test_case_name)
  Test[test_case_name .. "_0_element_in_request"] = function(self)
    local request_id = self.hmiConnection:SendRequest("SDL.GetDeviceConnectionStatus", {device = {}})
    EXPECT_HMIRESPONSE(request_id, {error = {code = 11, data = {method = "SDL.GetDeviceConnectionStatus"}}})
  end

  Test[test_case_name .. "_101_elements_in_request"] = function(self)
    local list_device = {}
    for i = 1, 101 do
      list_device[i] = {id = i, name = "Samsung", transportType = "USB_AOA", usbTransportStatus = "DISABLED"}
    end
    local request_id = self.hmiConnection:SendRequest("SDL.GetDeviceConnectionStatus", {device = list_device})
    EXPECT_HMIRESPONSE(request_id, {error = {code = 11, data = {method = "SDL.GetDeviceConnectionStatus"}}})
  end
end

-------------------------------------------Preconditions-------------------------------------
common_functions:DeleteLogsFileAndPolicyTable()

-----------------------------------------------Body------------------------------------------
--[[ Requirement summary: HMI sends GetDeviceConnectionStatus with:
-Valid device param
-Valid without device param
-Empty String param
-Contains special characters: \n; \t; white space
-Wrong type of param
1.Preconditions: Clear log and LPT
2.Steps:
2.1: HMI -> SDL: GetDeviceConnectionStatus(<without device info (when there are 0/ 100/ 101 elements in DB)>)
2.2: HMI -> SDL: GetDeviceConnectionStatus(<valid device info>)
2.3: HMI -> SDL: GetDeviceConnectionStatus(<invalid ID>)
2.4: HMI -> SDL: GetDeviceConnectionStatus(<invalid Name>)
2.5: HMI -> SDL: GetDeviceConnectionStatus(<invalid usbTransportStatus>)
2.6: HMI -> SDL: GetDeviceConnectionStatus(<invalid transportType>)
2.7: HMI -> SDL: GetDeviceConnectionStatus(<invalid isSDLAllowed>)
2.8: HMI -> SDL: GetDeviceCOnnectionStatus(with 0 or 101 elements in array)
3.Expected Result:
3.1: SDL -> HMI: GetDeviceConnectionStatus(<empty array - when there is not any record in DB>)
SDL -> HMI: GetDeviceConnectionStatus(<100 elements - when there is at least 100 records in DB>)
3.2: SDL -> HMI: GetDeviceConnectionStatus(empty array if result is not found - array contains result if found)
3.3: SDL -> HMI: GetDeviceConnectionStatus(INVALID_DATA)
3.4: SDL -> HMI: GetDeviceConnectionStatus(INVALID_DATA)
3.5: SDL -> HMI: GetDeviceConnectionStatus(INVALID_DATA)
3.6: SDL -> HMI: GetDeviceConnectionStatus(INVALID_DATA)
3.7: SDL -> HMI: GetDeviceConnectionStatus(INVALID_DATA)
3.8: SDL -> HMI: GetDeviceConnectionStatus(INVALID_DATA)
]]

common_steps:AddNewTestCasesGroup("GetDeviceConnectionStatus without device param")
-- Start SDL, Init HMI OnReady only. To check GetDeviceConnectionStatus when there is not any record in DB
common_steps:PreconditionSteps("CreateEmptyLPT", 3)
Test["GetDeviceConnectionStatus_device_omit_LocalPolicy_does_not_have_any_device"] = function(self)
  local request_id = self.hmiConnection:SendRequest("SDL.GetDeviceConnectionStatus", {})
  EXPECT_HMIRESPONSE(request_id, {device = {}, method = "SDL.GetDeviceConnectionStatus"})
end
common_steps:StopSDL("StopForUpdateLPT")
-- Prepare and insert 100 records to DB to check GetDeviceConnectionStatus when there are 100 records in DB
local one_hundred_records = {}
for i = 101, 125 do
  one_hundred_records[i-100] = {id = tostring(i), name = "Samsung", transport_type = "USB_AOA", usb_transport_enabled = "DISABLED"}
end
for i = 126, 150 do
  one_hundred_records[i-100] = {id = tostring(i), name = "Samsung", transport_type = "USB_AOA", usb_transport_enabled = "ENABLED"}
end
for i = 151, 175 do
  one_hundred_records[i-100] = {id = tostring(i), name = "Samsung", transport_type = "BLUETOOTH", usb_transport_enabled = "ENABLED"}
end
for i = 176, 200 do
  one_hundred_records[i-100] = {id = tostring(i), name = "Samsung", transport_type = "WIFI", usb_transport_enabled = "ENABLED"}
end

AddRecordsIntoLPT("Case_1", one_hundred_records)
common_steps:PreconditionSteps("Precondition", 3)

Test["GetDeviceConnectionStatus_device_omit_LocalPolicy_have_100_devices"] = function(self)
  local request_id = self.hmiConnection:SendRequest("SDL.GetDeviceConnectionStatus", {})
  local list_device = {}
  for i = 101, 125 do
    list_device[i-100] = {id = tostring(i), name = "Samsung", transportType = "USB_AOA", usbTransportStatus = "DISABLED"}
  end
  for i = 126, 150 do
    list_device[i-100] = {id = tostring(i), name = "Samsung", transportType = "USB_AOA", usbTransportStatus = "ENABLED"}
  end
  for i = 151, 175 do
    list_device[i-100] = {id = tostring(i), name = "Samsung", transportType = "BLUETOOTH", usbTransportStatus = "ENABLED"}
  end
  for i = 176, 200 do
    list_device[i-100] = {id = tostring(i), name = "Samsung", transportType = "WIFI", usbTransportStatus = "ENABLED"}
  end
  EXPECT_HMIRESPONSE(request_id, {device = list_device, method = "SDL.GetDeviceConnectionStatus"})
end

GetDeviceConnectionStatusWith100DevicesParam("GetDeviceConnectionStatus_with_request_contains_array_100_elements")

common_steps:StopSDL("StopForUpdateLPT")
-- Connect mobile and register app to check GetDeviceConnectionStatus when there are 101 records in DB
common_steps:PreconditionSteps("Precondition", 6)
Test["GetDeviceConnectionStatus_device_omit_LocalPolicy_have_101_devices"] = function(self)
  local request_id = self.hmiConnection:SendRequest("SDL.GetDeviceConnectionStatus", {})
  EXPECT_HMIRESPONSE(request_id, {method = "SDL.GetDeviceConnectionStatus"})
  :ValidIf (function(_,data)
      local count = #data.result.device
      if count ~= 100 then
        self:FailTestCase("Expected result: 100 devices are returned. Actual result: " ..tostring (count) .. " devices are returned")
      else
        return true
      end
    end)
end

common_steps:AddNewTestCasesGroup("GetDeviceConnectionStatus with valid device param")
common_steps:StopSDL("StopForUpdateLPT")
delete_query = "DELETE FROM DEVICE"
common_steps:ModifyLocalPolicyTable("Case_2_DeleteRecordInDeviceTable", delete_query)
local two_records = {}
two_records[1] = {id = 1, name = "Samsung", transport_type = "USB_AOA", usb_transport_enabled = "DISABLED"}
two_records[2] = {id = 2, name = "Motorola", transport_type = "USB_AOA", usb_transport_enabled = "ENABLED"}
AddRecordsIntoLPT("Add_2_records", two_records)
-- app is registered
common_steps:PreconditionSteps("Precondition", 6)
GetDeviceConnectionStatusWith1FoundDeviceParam("Case_2_FirstQuery", {id = "1", name = "Samsung"})
GetDeviceConnectionStatusWith1FoundDeviceParam("Case_2_SecondQuery", {id = "2", name = "Motorola"})
GetDeviceConnectionStatusWith1FoundDeviceParam("Case_2_ThirdQuery", {id = "1", name = "Samsung", transport_type = "USB_AOA"})
GetDeviceConnectionStatusWith1FoundDeviceParam("Case_2_FourthQuery", {id = "2", name = "Motorola", usb_transport_enabled = "ENABLED"})
GetDeviceConnectionStatusWith1FoundDeviceParam("Case_2_FifthQuery", {id = "1", name = "Samsung", transport_type = "USB_AOA", usb_transport_enabled = "DISABLED"})
GetDeviceConnectionStatusWith1FoundDeviceParam("Case_2_SixthQuery", {id = "1", name = "Samsung", transport_type = "WIFI"}, false)
GetDeviceConnectionStatusWith1FoundDeviceParam("Case_2_SeventhQuery", {id = "2", name = "Motorola", usb_transport_enabled = "DISABLED"}, false)
GetDeviceConnectionStatusWith1NotFoundDeviceParam("Case_2_EightthQuery", {id = "3", name = "Sony"})
GetDeviceConnectionStatusWith1NotFoundDeviceParam("Case_2_NinthQuery", {id = "4", name = "HTC"})
GetDeviceConnectionStatusWith2DevicesParam("Case_2_TenthQuery", two_records[1], two_records[2], true)
GetDeviceConnectionStatusWith2DevicesParam("Case_2_EleventhQuery", two_records[1], {id = "3", name = "Sony"}, false)

common_steps:AddNewTestCasesGroup("GetDeviceConnectionStatus with invalid ID")
GetDeviceConnectionStatusWithInvalid_Id("Case_3")

common_steps:AddNewTestCasesGroup("GetDeviceConnectionStatus with invalid Name")
GetDeviceConnectionStatusWithInvalid_Name("Case_4")

common_steps:AddNewTestCasesGroup("GetDeviceConnectionStatus with invalid usbTransportStatus")
GetDeviceConnectionStatusWithInvalid_usbTransportStatus("Case_5")

common_steps:AddNewTestCasesGroup("GetDeviceConnectionStatus with invalid transportType")
GetDeviceConnectionStatusWithInvalid_transportType("Case_6")

common_steps:AddNewTestCasesGroup("GetDeviceConnectionStatus with invalid isSDLAllowed")
GetDeviceConnectionStatusWithInvalid_issdlallowed("Case_7")

common_steps:AddNewTestCasesGroup("GetDeviceConnectionStatus with 0 or 101 elements in device param")
GetDeviceConnectionStatusOutOfArray("Case_8")
