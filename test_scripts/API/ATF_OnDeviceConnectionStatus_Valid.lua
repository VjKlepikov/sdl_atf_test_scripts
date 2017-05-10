require('user_modules/all_common_modules')
------------------------------------ Common functions ---------------------------------------
-- Remove existed snapshot file
os.execute( "rm -f /tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json" )

local function UpdateSDL(test_case_name)
  Test[test_case_name] = function(self)
    local RequestIdUpdateSDL = self.hmiConnection:SendRequest("SDL.UpdateSDL")
    EXPECT_HMIRESPONSE(RequestIdUpdateSDL,{result = {code = 0, method = "SDL.UpdateSDL", result = "UPDATE_NEEDED" }})
  end
end

-- Check existed usb_transport_status in LPT
local function CheckDataIsExistInPolicyTable(test_case_name, sql_query)
  Test[test_case_name] = function(self)
    local result = common_functions:QueryPolicyDataBase(sql_query)
    if(result == nil or result == "") then
      self:FailTestCase("Data is not existed in DB")
    end
  end
end

-- Check existed usb_transport_status in Snapshot
local function CheckExistedUsbTransportStatusInSnapShot(test_case_name, device_id, usb_status)
  Test[test_case_name] = function(self)
    local ivsu_cache_folder = common_functions:GetValueFromIniFile("SystemFilesPath")
    local file_name = ivsu_cache_folder .. "/sdl_snapshot.json"
    local value = common_functions:GetItemsFromJsonFile(file_name, {"policy_table", "device_data", device_id, "usb_transport_enabled"})
    if(value ~= usb_status ) then
      self:FailTestCase("Expected Result is: " .. tostring(usb_status) .. ". Actual Result is: " .. tostring(value))
    end
  end
end

-- local function Sleep(test_case_name, duration)
--   Test[test_case_name] = function(self)
--     common_functions:DelayedExp(duration*1000)
--   end
-- end

-------------------------------------- Preconditions --------------------------
Test["Precondition_RemoveExistedLogAndLPT"] = function (self)
  common_functions:DeleteLogsFileAndPolicyTable()
end
-- Start and stop SDL to create and update LPT
common_steps:PreconditionSteps("CreateEmptyLPT", 1)
common_steps:StopSDL("StopForUpdateLPT")
-- Prepare devices in LPT
insert_device1 = "INSERT INTO DEVICE (id, hardware, firmware_rev, os, os_version, carrier, max_number_rfcom_ports, connection_type, usb_transport_enabled, unpaired) Values ('1', 'HTC1', 'Name: Linux, Version: 3.4.0-perf', 'Android', '4.4.2', 'Megafon', 1, 'USB_AOA', 0, 0);"
insert_device2 = "INSERT INTO DEVICE (id, hardware, firmware_rev, os, os_version, carrier, max_number_rfcom_ports, connection_type, usb_transport_enabled, unpaired) Values ('2', 'HTC2', 'Name: Linux, Version: 3.4.0-perf', 'Android', '4.4.2', 'Megafon', 1, 'USB_AOA', 1, 0);"
insert_device3 = "INSERT INTO DEVICE (id, hardware, firmware_rev, os, os_version, carrier, max_number_rfcom_ports, connection_type, usb_transport_enabled, unpaired) Values ('3', 'HTC3', 'Name: Linux, Version: 3.4.0-perf', 'Android', '4.4.2', 'Megafon', 1, 'USB_AOA', 0, 0);"
common_steps:ModifyLocalPolicyTable("InsertDevices1IntoLPT", insert_device1)
common_steps:ModifyLocalPolicyTable("InsertDevices2IntoLPT", insert_device2)
common_steps:ModifyLocalPolicyTable("InsertDevices3IntoLPT", insert_device3)
-- App is registered
common_steps:PreconditionSteps("PreconditionSteps", 6)

------------------------------------------- Case 1 ----------------------------
--[[
1. Precondition: Send SDL.OnAppPermissionConsent with DeviceInfo:
-id = '1'
-name = 'HTC1'
-usbTransportStatus = 'ENABLED'
-transportType = 'USB_AOA'
2. Body:
2.1. Check Policy table
2.2. Activate app
2.3. Check Snapshot file
3. Expected Result:
3.1. The record in PT is updated with usb_transport_status = "ENABLED"
3.2. Snapshot file is created
3.3. Record with id 1, usb_transport_status ENABLED is existed in snapshot file
]]
common_steps:AddNewTestCasesGroup("Case 1")
Test["HMI_sends_OnDeviceConnectionStatus_ENABLED"] = function(self)
  local device_info = {
    name = "HTC1",
    id = "1",
    transportType = "USB_AOA",
    isSDLAllowed = false,
    usbTransportStatus = "ENABLED"
  }
  self.hmiConnection:SendNotification("SDL.OnDeviceConnectionStatus", {device = device_info})
  -- Wait for data is saved to DB
  os.execute("sleep 2")
end

common_steps:ActivateApplication("ActivateApp", config.application1.registerAppInterfaceParams.appName)
common_steps:Sleep("WaitingSDLCreateSnapshot", 5)
common_steps:StopSDL("StopSDL")
local sql_query1 = "select * from device where id = '1' and usb_transport_enabled = '1'"
CheckDataIsExistInPolicyTable("Check_usbTranportStatus_is_saved_into_LocalPolicyTable", sql_query1)
CheckExistedUsbTransportStatusInSnapShot("CheckExistedUsbStatusInSnapShot_1", "1", true)

------------------------------------------- Case 2 ----------------------------
--[[
1. Precondition: Send SDL.OnAppPermissionConsent with DeviceInfo:
-id = '2'
-name = 'HTC2'
-usbTransportStatus = 'DISABLED'
-transportType = 'USB_AOA'
2. Body:
2.1. Check Policy table
2.2. Send Update SDL Request
2.3. Check Snapshot file
3. Expected Result:
3.1. The record in PT is updated with usb_transport_status = "DISABLED"
3.2. Snapshot file is created
3.3. Record with id 2, usb_transport_status DISABLED is existed in snapshot file
]]

common_steps:AddNewTestCasesGroup("Case 2")
common_steps:PreconditionSteps("PreconditionSteps", 6)
Test["HMI_sends_OnDeviceConnectionStatus_DISABLED"] = function(self)
  local device_info = {
    name = "HTC2",
    id = "2",
    transportType = "USB_AOA",
    isSDLAllowed = false,
    usbTransportStatus = "DISABLED"
  }
  self.hmiConnection:SendNotification("SDL.OnDeviceConnectionStatus", {device = device_info})
  -- Wait for data is saved to DB
  os.execute("sleep 2")
end

UpdateSDL("UpdateSDL")
common_steps:Sleep("WaitingSDLCreateSnapshot", 5)
common_steps:StopSDL("StopSDL")
local sql_query2 = "select * from device where id = '2' and usb_transport_enabled = '0'"
CheckDataIsExistInPolicyTable("Check_usbTranportStatus_is_saved_into_LocalPolicyTable", sql_query2)
CheckExistedUsbTransportStatusInSnapShot("CheckExistedUsbStatusInSnapShot_2", "2", false)

------------------------------------------- Case 3 ----------------------------
--[[
1. Precondition: Send SDL.OnAppPermissionConsent with fake param in DeviceInfo:
-id = '3'
-name = 'HTC3'
-usbTransportStatus = 'ENABLED'
-transportType = 'USB_AOA'
-fake = 'a'
2. Body:
2.1. Check Policy table
2.2. Send Update SDL Request
2.3. Check Snapshot file
3. Expected Result:
3.1. The record in PT is updated with usb_transport_status = "ENABLED"
3.2. Snapshot file is created
3.3. Record with id 3, usb_transport_status ENABLED is existed in snapshot file
]]

common_steps:AddNewTestCasesGroup("Case 3")
common_steps:PreconditionSteps("PreconditionSteps", 6)
Test["HMI_sends_OnDeviceConnectionStatus_With_Fake_Param"] = function(self)
  local device_info = {
    name = "HTC3",
    id = "3",
    transportType = "USB_AOA",
    isSDLAllowed = false,
    usbTransportStatus = "ENABLED",
    fake = "a"
  }
  self.hmiConnection:SendNotification("SDL.OnDeviceConnectionStatus", {device = device_info})
  -- Wait for data is saved to DB
  os.execute("sleep 2")
end

UpdateSDL("UpdateSDL")
common_steps:Sleep("WaitingSDLCreateSnapshot", 5)
common_steps:StopSDL("StopSDL")
local sql_query3 = "select * from device where id = '3' and usb_transport_enabled = '1'"
CheckDataIsExistInPolicyTable("Check_usbTranportStatus_is_saved_into_LocalPolicyTable", sql_query3)
CheckExistedUsbTransportStatusInSnapShot("CheckExistedUsbStatusInSnapShot_3", "3", true)
