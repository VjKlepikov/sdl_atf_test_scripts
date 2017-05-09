---------------------------------------------------------------------------------------------
-- Requirement summary: 
-- [APPLINK-18053]: [PolicyTableUpdate] PTS creation rule

-- Description:
-- To create Policy Table Snapshot PoliciesManager must copy the Local Policy Table into memory. 
-- Application's appID must be present at section "app_level" and "module_config" same as Local PT.

-- Preconditions:
-- 1. appID is not listed in LPT

-- Steps:
-- 1. Device is consented
-- 2. Register app 

-- Expected result:
-- PTU process should be started like below:
-- 1. SDL -> HMI OnStatusUpdate(UPDATE_NEEDED) notification
-- 2. SDL -> HMI: BC.PolicyUpdate()
-- 3. HMI -> SDL: SDL.GetURLS()
-- 4. HMI -> SDL: BC.PolicyUpdate() response
-- 5. SDL -> HMI: SDL. GetURLS() response
-- 6. HMI -> SDL: OnSystemRequest(request_type=PROPRIETARY, url, appID, file)
-- 7. SDL -> app: OnSystemRequest()
-- 8. App -> SDL: SystemRequest
-- 9. SDL -> HMI: SDL.OnStatusUpdate", "params" : {"status" : "UPDATING"}
-- 10. HMI -> SDL: SDL.GetUserFriendlyMessage (messageCode: "StatusPending")
-- 11. SDL -> HMI: SDL.GetUserFriendlyMessage (messageCode: "StatusPending") response
-- 12. SDL creates a snapshot file via information from OnSystemRequest(). This json file
-- should be stored as a JSON file with filename and filepath are defined in 
-- "PathToSnapshot" parameter of smartDeviceLink.ini: Application's appID must be present 
-- at section "app_level" of snapshot file and "module_config" same as Local PT.
-- 13. SDL -> HMI: BC. SystemRequest(request_type=PROPRIETARY, filename)
-- 14. HMI -> SDL: SDL.OnReceivedPolicyTable(policyfile)
-- 15. HMI -> SDL: BC. SystemRequest (response)
-- 16. SDL -> HMI: SDL.OnStatusUpdate", "params" : {"status" : "UP_TO_DATE"}
-- 17. HMI -> SDL: SDL.GetUserFriendlyMessage (messageCode: "StatusUpToDate")
-- 18. SDL -> HMI: SDL.GetUserFriendlyMessage (messageCode: "StatusUpToDate") response

---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')

--[[ Local variables]]
local system_files_path = common_functions:GetValueFromIniFile("SystemFilesPath")
local snapshot_file = common_functions:GetValueFromIniFile("PathToSnapshot")
local snapshot_path = system_files_path .. "/" .. snapshot_file
local sdl_preloaded_pt_path = config.pathToSDL .. "sdl_preloaded_pt.json"

--[[ Preconditions ]]
common_steps:AddNewTestCasesGroup("Preconditions")

common_functions:DeleteLogsFileAndPolicyTable()

os.execute( "rm -f " ..  snapshot_path)

common_steps:PreconditionSteps("Preconditions", const.precondition.ADD_MOBILE_SESSION)

---------------------------------------------------------------------------------------------
--[[ Test ]]
common_steps:AddNewTestCasesGroup("Test")

function Test:ConsentDevice_OnStatusUpdate_UPDATE_NEEDED()
  local request_id = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {
    language = "EN-US", messageCodes = {"DataConsent"}})
  EXPECT_HMIRESPONSE(request_id,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
  :Do(function(_,data)
    self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {
      allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
  end)
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"}) 
end

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

function Test:Verify_Snapshot()
  -- check Snapshot file exists
  if not common_functions:IsFileExist(snapshot_path) then
    self:FailTestCase("Snapshot file does not exist.")
    return
  end
  -- check appID exist in "usage_and_error_counts"."app_level"
  local path_to_app_level = {"policy_table", "usage_and_error_counts", "app_level"}
  local app_level = common_functions:GetItemsFromJsonFile(snapshot_path, path_to_app_level)
  if not app_level[const.default_app.appID] then
    self:FailTestCase("Application id = " .. const.default_app.appID .. "does not exist in Snapshot's 'app_level'.")
  end
  -- check "module_config" in Snapshot same as in Policy Table (same as sdl_preloaded_pt.json) except:
  -- preloaded_pt value in Snapshot can be 'false' or empty when preloaded_pt value in Policy Table is 'true',
  -- preloaded_date value in Snapshot can be empty
  local path_to_module_config = {"policy_table", "module_config"}
  local module_config_in_preloaded_pt = common_functions:GetItemsFromJsonFile(sdl_preloaded_pt_path, path_to_module_config)
  local module_config_in_snapshot = common_functions:GetItemsFromJsonFile(snapshot_path, path_to_module_config)
  module_config_in_preloaded_pt.preloaded_pt = module_config_in_snapshot.preloaded_pt
  module_config_in_preloaded_pt.preloaded_date = module_config_in_snapshot.preloaded_date
  if not common_functions:CompareTables(module_config_in_preloaded_pt, module_config_in_snapshot) then
    self:FailTestCase("Module Config sections in Snapshot and PreloadedPT are different.")
  end
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

common_steps:StopSDL("Postconditions_StopSDL")
