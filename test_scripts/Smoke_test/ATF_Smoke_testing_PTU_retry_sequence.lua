---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-19169]: [PolicyTableUpdate] PoliciesManager changes status to “UPDATE_NEEDED”
-- [APPLINK-19044]: [PolicyTableUpdate] Sending PTS to mobile application
-- [APPLINK-18952]: [PolicyTableUpdate] Request PTU - an app registered is not listed in PT (device consented)

-- Description: SDL initiates PTU retry sequence in case of fail PTU

-- Preconditions:
-- 1. Device is consented
-- 2. App is configure to not send SystemRequest() to SDL

-- Steps:
-- 1. Register new app that not listed in LPT

-- Expected result:
-- Policy Manager must start PTU process when new app is connected
-- 1st retry should start like below flow
-- SDL – > HMI OnStatusUpdate(UPDATE_NEEDED) notification
-- SDL – > HMI: BC.PolicyUpdate(retry[], timeout)
-- HMI – >SDL: SDL. GetURLS()
-- HMI – > SDL: BC.PolicyUpdate() response
-- SDL – > HMI: SDL. GetURLS() response
-- HMI – > SDL: OnSystemRequest(request_type=PROPRIETARY, url, appID, file)
-- SDL – > app: OnSystemRequest()
-- SDL – > HMI: SDL.OnStatusUpdate", "params" : {"status" : "UPDATING"}
-- HMI – > SDL: SDL.GetUserFriendlyMessage (messageCode: “StatusPending”)
-- SDL – > HMI: SDL.GetUserFriendlyMessage (messageCode: “StatusPending”) response
-- Note: App doesn't send SDL: SystemRequest() here so PTU process can't be completed
-- 2nd retry must start after 2nd_RetryTimeout =1st_RetryTimeout + retry[2] +timeout with the same above steps
-- 3rd retry must start after 3rd_RetryTimeout =2nd_RetryTimeout + retry[3] +timeout with the same above steps
-- 4th retry must start after 4th_RetryTimeout =3rd_RetryTimeout + retry[4] +timeout with the same above steps
-- 5th retry must start after 5th_RetryTimeout =4thrd_RetryTimeout + retry[5] +timeout with the same above steps

---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')

--[[ Local variables]]
local expect_time = {}
local preload_timeout = 5
local preload_seconds_between_retries = {1, 5, 10, 15, 20}
local time_diff
local pre_OnStatusUpdate
local cur_OnStatusUpdate

--[[ Local functions]]
function PolicyUpdate(self, timeout)
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})
  :ValidIf(function()
      cur_OnStatusUpdate = timestamp()
      time_diff = math.abs(cur_OnStatusUpdate - pre_OnStatusUpdate)
      common_functions:UserPrint(const.color.yellow, "Time between retries is: " .. time_diff)
      common_functions:UserPrint(const.color.yellow, "expect time is: " .. timeout)
      pre_OnStatusUpdate = cur_OnStatusUpdate

      if math.abs(time_diff - timeout) > 1000 then
        common_functions:PrintError(
        "Times between retries are different to expected")
        return false
      else
        return true
      end
    end)
end

function GetURLS(self)
  local get_urls_corid = self.hmiConnection:SendRequest("SDL.GetURLS", {service = 7})
  EXPECT_HMIRESPONSE(get_urls_corid)
end

function OnSystemRequest_OnStatusUpdate_UPDATING(self, timeout)
  local sleeptime = timeout/1000 - preload_timeout
  os.execute("sleep " .. sleeptime)
  self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", {
      requestType = "PROPRIETARY",
      fileName = "filename",
      appID = common_functions:GetHmiAppId(const.default_app.appName, self)})
  EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "PROPRIETARY"})
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATING"})
end

function GetUserFriendlyMessage_StatusPending(self)
  local get_user_friendly_message_corid = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {
      language = "EN-US", messageCodes = {"StatusPending"}})
  EXPECT_HMIRESPONSE(get_user_friendly_message_corid, {
      result = {
        code = 0,
        method = "SDL.GetUserFriendlyMessage",
        messages = {{
            line1 = "Updating...",
            messageCode = "StatusPending",
            textBody = "Updating..."}}}})
end

--[[ Preconditions ]]
common_steps:AddNewTestCasesGroup("Preconditions")
function Test:Preconditions_UpdateParamInPreloadFile()
  local path_to_file = config.pathToSDL .. 'sdl_preloaded_pt.json'
  local parent_item = {"policy_table", "module_config"}
  local added_json_items_1 = {timeout_after_x_seconds = preload_timeout}
  local added_json_items_2 = {seconds_between_retries = preload_seconds_between_retries}
  common_functions:AddItemsIntoJsonFile(path_to_file, parent_item, added_json_items_1)
  common_functions:AddItemsIntoJsonFile(path_to_file, parent_item, added_json_items_2)
end

function Test:Preconditions_CalculateTime()
  expect_time[1] = (preload_timeout + preload_seconds_between_retries[1]) * 1000
  for i = 2, 5 do
    expect_time[i] = expect_time[i-1] + (preload_timeout + preload_seconds_between_retries[i]) *1000
  end
end

common_steps:PreconditionSteps("Preconditions", const.precondition.ADD_MOBILE_SESSION)

function Test:Preconditions_ConsentDevice()
  local request_id = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {
      language = "EN-US", messageCodes = {"DataConsent"}})
  EXPECT_HMIRESPONSE(request_id,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
  :Do(function()
      self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {
          allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
    end)
end

---------------------------------------------------------------------------------------------
--[[ Test ]]
common_steps:AddNewTestCasesGroup("Test")
function Test:RegisterAppInterface_PolicyUpdate()
  common_functions:StoreApplicationData("mobileSession", const.default_app.appName, const.default_app, _, self)
  local regist_corid = self.mobileSession:SendRPC("RegisterAppInterface", const.default_app)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = {appName = const.default_app.appName}})
  :Do(function(_,data)
      common_functions:StoreHmiAppId(const.default_app.appName, data.params.application.appID, self)
    end)
  self.mobileSession:ExpectResponse(regist_corid, {success = true, resultCode = "SUCCESS"})
  self.mobileSession:ExpectNotification("OnHMIStatus", {
      hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  :Do(function(_,data)
      common_functions:StoreHmiStatus(const.default_app.appName, data.payload, self)
    end)
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
end

function Test:GetURLS_0()
  local get_urls_corid = self.hmiConnection:SendRequest("SDL.GetURLS", {service = 7})
  EXPECT_HMIRESPONSE(get_urls_corid)
end

function Test:OnSystemRequest_OnStatusUpdate_UPDATING_0()
  pre_OnStatusUpdate = timestamp()
  self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", {
      requestType = "PROPRIETARY",
      fileName = "filename",
      appID = common_functions:GetHmiAppId(const.default_app.appName, self)})
  EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "PROPRIETARY"})
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATING"})
end

function Test:GetUserFriendlyMessage_StatusPending_0()
  local get_user_friendly_message_corid = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {
      language = "EN-US", messageCodes = {"StatusPending"}})
  EXPECT_HMIRESPONSE(get_user_friendly_message_corid, {
      result = {
        code = 0,
        method = "SDL.GetUserFriendlyMessage",
        messages = {{
            line1 = "Updating...",
            messageCode = "StatusPending",
            textBody = "Updating..."}}}})
end

function Test:PolicyUpdate_0()
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})
  :ValidIf(function()
      cur_OnStatusUpdate = timestamp()
      time_diff = math.abs(cur_OnStatusUpdate - pre_OnStatusUpdate)
      common_functions:UserPrint(const.color.yellow, "Time between retries is: " .. time_diff)
      pre_OnStatusUpdate = cur_OnStatusUpdate

      if time_diff > (preload_timeout + 1) *1000 or time_diff < (preload_timeout - 1) * 1000 then
        common_functions:PrintError(
        "Times between retries are different to expected")
        return false
      else
        return true
      end
    end)
end

for i = 1, 5 do
  common_steps:AddNewTestCasesGroup("Retry_" .. i)
  Test["GetURLS_" .. i] = function(self)
    GetURLS(self)
  end

  Test["OnSystemRequest_OnStatusUpdate_UPDATING_" .. i] = function(self)
    OnSystemRequest_OnStatusUpdate_UPDATING(self, expect_time[i])
  end

  Test["GetUserFriendlyMessage_StatusPending_" .. i] = function(self)
    GetUserFriendlyMessage_StatusPending(self)
  end

  Test["PolicyUpdate_" .. i] = function(self)
    PolicyUpdate(self, expect_time[i])
  end
end

--[[ Postconditions ]]
common_steps:AddNewTestCasesGroup("Postconditions")
common_steps:UnregisterApp("Postconditions_UnregisterApp", const.default_app.appName)
common_steps:StopSDL("Postconditions_StopSDL")
