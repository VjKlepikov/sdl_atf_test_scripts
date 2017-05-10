require('user_modules/all_common_modules')
------------------------------------ Common variables ---------------------------------------
local invalid_values_string = {
  {value = "a\nb", description = "contains new line character"},
  {value = "a\tb", description = "contains tab character"},
  {value = " ", description = "contains only space"},
  {value = "", description = "empty"},
  {value = 1, description = "wrong type"},
  {value = nil, description = "Omit"}
}
local invalid_values_enum = {
  {value = "", description = "empty"},
  {value = "ABLED", description = "non existent value"},
  {value = nil, description = "Omit"}
}
local invalid_transport_type = {
  {value = "WIFI", description = "WIFI"},
  {value = "BLUETOOTH", description = "BLUETOOTH"},
  {value = 1, description = "wrong type"},
  {value = "ABC", description = "non existent value"},
  {value = nil, description = "Omit"}
}

------------------------------------ Common functions ---------------------------------------
-- Check usb_transport_status in LPT
local function CheckDevicesNotUpdateInPolicyTable()
  Test["Check_usbTranportStatus_is_not_updated_in_LPT"] = function(self)
    -- Wait for data is saved to DB
    os.execute("sleep 2")
    local sql_query = "select * from device where (id = '1' or id = '2') and usb_transport_enabled = '1'"
    local result = common_functions:QueryPolicyDataBase(sql_query)
    if(result ~= nil) then
      self:FailTestCase("usbTransportStatus is updated in DB")
    end
  end
end

-------------------------------------- Preconditions --------------------------
Test["Precondition_RemoveExistedLogAndLPT"] = function (self)
  common_functions:DeleteLogsFileAndPolicyTable()
end
-- Start and stop SDL to create and update LPT
common_steps:PreconditionSteps("CreateEmptyLPT", 1)
common_steps:StopSDL("StopForUpdateLPT")
-- Prepare devices in LPT
for i = 1, 2 do
  insert_devices = "INSERT INTO DEVICE (id, hardware, firmware_rev, os, os_version, carrier, max_number_rfcom_ports, connection_type, usb_transport_enabled, unpaired) Values (" .. tostring(i)..", 'HTC" .. tostring(i) .. "', 'Name: Linux, Version: 3.4.0-perf', 'Android', '4.4.2', 'Megafon', 1, 'USB_AOA', 0, 0);"
  common_steps:ModifyLocalPolicyTable("InsertDevicesIntoLPT_" ..tostring(i) , insert_devices)
end
common_steps:PreconditionSteps("PreconditionSteps", 6)
------------------------------------------- Case 1 ----------------------------
common_steps:AddNewTestCasesGroup("SDL.OnDeviceConnectionStatus with invalid json")
Test["HMI_sends_SDL.OnDeviceConnectionStatus_with_invalid_Json"] = function(self)
  -- correct json message: {"params":device{"usbTransportStatus":"ENABLED","transportType":"USB_AOA","name":"HTC1","id":"1","isSDLAllowed":"false"},"jsonrpc":"2.0","method":"SDL.OnDeviceConnectionStatus"}')
  self.hmiConnection:Send('{"params":device{"usbTransportStatus":"ENABLED","transportType":"USB_AOA","name":"HTC1","id":"1","isSDLAllowed":"false"},"jsonrpc";"2.0","method":"SDL.OnDeviceConnectionStatus"}')
end
common_steps:StopSDL("StopSDL")
CheckDevicesNotUpdateInPolicyTable()

------------------------------------------- Case 2 ----------------------------
common_steps:AddNewTestCasesGroup("SDL.OnDeviceConnectionStatus without device param")
common_steps:PreconditionSteps("PreconditionSteps", 6)
Test["HMI_sends_OnDeviceConnectionStatus_without_param"] = function(self)
  self.hmiConnection:SendNotification("SDL.OnDeviceConnectionStatus", {})
end
common_steps:StopSDL("StopSDL")
CheckDevicesNotUpdateInPolicyTable()

------------------------------------------- Case 3 ----------------------------
common_steps:AddNewTestCasesGroup("SDL.OnDeviceConnectionStatus with empty device param")
common_steps:PreconditionSteps("PreconditionSteps", 6)
Test["HMI_sends_OnDeviceConnectionStatus_with_empty_Device_param"] = function(self)
  self.hmiConnection:SendNotification("SDL.OnDeviceConnectionStatus", {device = {}})
end
common_steps:StopSDL("StopSDL")
CheckDevicesNotUpdateInPolicyTable()

------------------------------------------- Case 4 ----------------------------
common_steps:AddNewTestCasesGroup("SDL.OnDeviceConnectionStatus with invalid name param")
for i = 1, #invalid_values_string do
  common_steps:PreconditionSteps("PreconditionSteps", 6)
  Test["HMI_sends_SDL.OnDeviceConnectionStatus_name_" .. tostring(invalid_values_string[i].description)] = function(self)
    local device_info = {
      name = invalid_values_string[i].value,
      id = "1",
      transportType = "USB_AOA",
      isSDLAllowed = "false",
      usbTransportStatus = "ENABLED"
    }
    self.hmiConnection:SendNotification("SDL.OnDeviceConnectionStatus", {device = device_info})
  end
  common_steps:StopSDL("StopSDL")
  CheckDevicesNotUpdateInPolicyTable()
end

------------------------------------------- Case 5 ----------------------------
common_steps:AddNewTestCasesGroup("SDL.OnDeviceConnectionStatus with invalid id param")
for i = 1, #invalid_values_string do
  common_steps:PreconditionSteps("PreconditionSteps", 6)
  Test["HMI_sends_SDL.OnDeviceConnectionStatus_id_" .. tostring(invalid_values_string[i].description)] = function(self)
    local device_info = {
      name = "HTC1",
      id = invalid_values_string[i].value,
      transportType = "USB_AOA",
      isSDLAllowed = "false",
      usbTransportStatus = "ENABLED"
    }
    self.hmiConnection:SendNotification("SDL.OnDeviceConnectionStatus", {device = device_info})
  end
  common_steps:StopSDL("StopSDL")
  CheckDevicesNotUpdateInPolicyTable()
end

------------------------------------------- Case 6 ----------------------------
common_steps:AddNewTestCasesGroup("SDL.OnDeviceConnectionStatus with invalid usbTransportStatus param")
for i = 1, #invalid_values_enum do
  common_steps:PreconditionSteps("PreconditionSteps", 6)
  Test["HMI_sends_SDL.OnDeviceConnectionStatus_usbTransportStatus_" .. tostring(invalid_values_enum[i].description)] = function(self)
    local device_info = {
      name = "HTC1",
      id = "1",
      transportType = "USB_AOA",
      isSDLAllowed = "false",
      usbTransportStatus = invalid_values_enum[i].value
    }
    self.hmiConnection:SendNotification("SDL.OnDeviceConnectionStatus", {device = device_info})
  end
  common_steps:StopSDL("StopSDL")
  CheckDevicesNotUpdateInPolicyTable()
end

------------------------------------------- Case 7 ----------------------------
common_steps:AddNewTestCasesGroup("SDL.OnDeviceConnectionStatus with invalid Transport Type param")
for i = 1, #invalid_transport_type do
  common_steps:PreconditionSteps("PreconditionSteps", 6)
  Test["HMI_sends_SDL.OnDeviceConnectionStatus_transportType_" .. tostring(invalid_transport_type[i].description)] = function(self)
    local device_info = {
      name = "HTC1",
      id = "1",
      transportType = invalid_transport_type[i].value,
      isSDLAllowed = "false",
      usbTransportStatus = "ENABLED"
    }
    self.hmiConnection:SendNotification("SDL.OnDeviceConnectionStatus", {device = device_info})
  end
  common_steps:StopSDL("StopSDL")
  CheckDevicesNotUpdateInPolicyTable()
end
