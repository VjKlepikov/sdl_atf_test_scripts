---------------------------------------------------------------------------------------------
-- Requirement summary: 
-- [APPLINK-18952]: [PolicyTableUpdate] Request PTU - an app registered is not listed in PT (device consented)

-- Description:
-- The policies manager must request an update to its local policy table 
-- when an appID of a registered app is not listed on the Local Policy Table 
-- and the device the application is running on is consented. 

-- Preconditions:
-- 1. App is not listed in LPT

-- Steps:
-- 1. Register app then consent device

-- Expected result:
-- PTU process should be started like below:
-- SDL -> HMI OnStatusUpdate(UPDATE_NEEDED) notification
-- SDL -> HMI: BC.PolicyUpdate()
-- HMI -> SDL: SDL.GetURLS()
-- HMI -> SDL: BC.PolicyUpdate() response
-- SDL -> HMI: SDL. GetURLS() response
-- HMI -> SDL: OnSystemRequest(request_type=PROPRIETARY, url, appID, file)
-- SDL -> app: OnSystemRequest()
-- App -> SDL: SystemRequest
-- SDL -> HMI: SDL.OnStatusUpdate", "params" : {"status" : "UPDATING"}
-- HMI -> SDL: SDL.GetUserFriendlyMessage (messageCode: "StatusPending")
-- SDL -> HMI: SDL.GetUserFriendlyMessage (messageCode: "StatusPending") response
-- SDL -> HMI: BC. SystemRequest(request_type=PROPRIETARY, filename)
-- HMI -> SDL: SDL.OnReceivedPolicyTable(policyfile)
-- HMI -> SDL: BC. SystemRequest (response)
-- SDL -> HMI: SDL.OnStatusUpdate", "params" : {"status" : "UP_TO_DATE"}
-- HMI -> SDL: SDL.GetUserFriendlyMessage (messageCode: "StatusUpToDate")
-- SDL -> HMI: SDL.GetUserFriendlyMessage (messageCode: "StatusUpToDate") response

---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')

--[[ Preconditions ]]
common_steps:AddNewTestCasesGroup("Preconditions")

common_functions:DeleteLogsFileAndPolicyTable()

common_functions:BackupFile("sdl_preloaded_pt.json")

function Test:Preconditions_Remove_appID_From_sdl_preloaded_pt()
  local json_file = config.pathToSDL .. "sdl_preloaded_pt.json"
  local parent_item = {"policy_table", "app_policies"}
  local item_to_remove = {const.default_app.appID}
  common_functions:RemoveItemsFromJsonFile(json_file, parent_item, item_to_remove)
end

common_steps:PreconditionSteps("Preconditions", const.precondition.ADD_MOBILE_SESSION)

---------------------------------------------------------------------------------------------
--[[ Test ]]
common_steps:AddNewTestCasesGroup("Test")

function Test:RegisterAppInterface_OnStatusUpdate_UPDATE_NEEDED()
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
end

function Test:ConsentDevice_Allow_PolicyUpdate()
  local request_id = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {
    language = "EN-US", messageCodes = {"DataConsent"}})
  EXPECT_HMIRESPONSE(request_id,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
  :Do(function(_,data)
    self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {
      allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
  end)
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :Do(function(_, data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
end

function Test:GetURLS()
  local get_urls_corid = self.hmiConnection:SendRequest("SDL.GetURLS", {service = 7})
  EXPECT_HMIRESPONSE(get_urls_corid)
end

function Test:OnSystemRequest_OnStatusUpdate_UPDATING()
  self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", {
      requestType = "PROPRIETARY",
      fileName = "filename",
      appID = common_functions:GetHmiAppId(const.default_app.appName, self)})
  EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "PROPRIETARY"})
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATING"})
end

function Test:GetUserFriendlyMessage_StatusPending()
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

function Test:SystemRequest_OnStatusUpdate_UP_TO_DATE()
  local system_request_corid = self.mobileSession:SendRPC("SystemRequest", {
      fileName = "PolicyTableUpdate",
      requestType = "PROPRIETARY"
    }, 'files/PTU_For_SmokeTesting.json')
  local system_request_id
  EXPECT_HMICALL("BasicCommunication.SystemRequest")
  :Do(function(_,data)
    system_request_id = data.id
    self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", {
        policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"})
    local function to_run()
      self.hmiConnection:SendResponse(system_request_id,"BasicCommunication.SystemRequest", "SUCCESS", {})
    end
    RUN_AFTER(to_run, 500)
  end)
  EXPECT_RESPONSE(system_request_corid, { success = true, resultCode = "SUCCESS"})
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UP_TO_DATE"})            
end

function Test:GetUserFriendlyMessage_StatusUpToDate()
  local get_user_friendly_message_corid = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {
    language = "EN-US", messageCodes = {"StatusUpToDate"}})
  EXPECT_HMIRESPONSE(get_user_friendly_message_corid, {
      result = {
        code = 0, 
        method = "SDL.GetUserFriendlyMessage", 
        messages = {{
          line1 = "Up-To-Date", 
          messageCode = "StatusUpToDate", 
          textBody = "Up-To-Date"}}}})
end

---------------------------------------------------------------------------------------------
--[[ Postconditions ]]
common_steps:AddNewTestCasesGroup("Postconditions")

common_steps:UnregisterApp("Postconditions_UnregisterApp", const.default_app.appName)

common_steps:RestoreIniFile("Postconditions_Restore_PreloadedPT", "sdl_preloaded_pt.json")

common_steps:StopSDL("Postconditions_StopSDL")
