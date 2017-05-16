---------------------------------------------------------------------------------------------
-- Requirement summary: 
-- [APPLINK-18966]: [PolicyTableUpdate] PoliciesManager must initiate PTU in case getting 'device consent' from the user
-- [APPLINK-19072]: [PolicyTableUpdate] OnStatusUpdate(UPDATE_NEEDED) on new PTU request
-- [APPLINK-18053]: [PolicyTableUpdate] PTS creation rule
-- [APPLINK-19050]: [PolicyTableUpdate] Policy Manager responds on GetURLs from HMI
-- [APPLINK-18708]: [PolicyTableUpdate] PoliciesManager changes status to “UPDATING”
-- [APPLINK-18803]: [PolicyTableUpdate] PoliciesManager changes status to “UP_TO_DATE”

-- Description: Snapshot is created with "app_policies" section should contains appID and its permission
-- as the same as in sdl_preaded_pt.json file

-- Preconditions:
-- 1. appID = 0000001 is present at "app_policies" of sdl_preloaded_pt.json file with its own permissions:
--   keep_context
--   steal_focus
--   priority
--   default_hmi
--   groups
-- 2. SDL is at 1st life cycle

-- Steps:
-- 1. Register new app with appID = 0000001
-- 2. Activate app to answer YES for Device Data Consent

-- Expected result:
-- 1. After App is registered success full. 
-- 2. Device Data Consent is consented. PM starts PTU process and snapshot file is created 
-- 3. Section "app_policies" should be contain appID = 0000001 and its permission (keep_context, 
-- steal_focus, priority, default_hmi, groups) should be as the same as in sdl_preaded_pt.json file

---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')

--[[ Local variables]]
local system_files_path = common_functions:GetValueFromIniFile("SystemFilesPath")
local snapshot_file = common_functions:GetValueFromIniFile("PathToSnapshot")
local snapshot_path = system_files_path .. "/" .. snapshot_file
local sdl_preloaded_pt_path = config.pathToSDL .. "sdl_preloaded_pt.json"
local preload_app_permissions = {
  keep_context = true,
  steal_focus = true,
  priority = "NORMAL",
  default_hmi = "NONE",
  groups = {"Base-4", "Notifications"}
}

--[[ Preconditions ]]
common_steps:AddNewTestCasesGroup("Preconditions")

-- Remove existed snapshot file
os.execute( "rm -f " .. snapshot_path)

common_functions:BackupFile("sdl_preloaded_pt.json")

function Test:Preconditions_Add_appID_To_sdl_preloaded_pt()
  local parent_item = {"policy_table", "app_policies"}
  local json_items_to_add = {}
  json_items_to_add[const.default_app.appID] = preload_app_permissions
  common_functions:AddItemsIntoJsonFile(sdl_preloaded_pt_path, parent_item, json_items_to_add)
end

common_steps:PreconditionSteps("Preconditions", const.precondition.ADD_MOBILE_SESSION)

---------------------------------------------------------------------------------------------
--[[ Test ]]
common_steps:AddNewTestCasesGroup("Test")

function Test:RegisterAppInterface()
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
end

function Test:ActivateApp_ConsentDevice_OnStatusUpdate_UPDATE_NEEDED_PolicyUpdate()
  local hmi_app_id = common_functions:GetHmiAppId(const.default_app.appName, self)
  local audio_streaming_state
  if common_functions:IsMediaApp(const.default_app.appName, self) then
    audio_streaming_state = "AUDIBLE"
  else
    audio_streaming_state = "NOT_AUDIBLE"
  end
  local activate_cid = self.hmiConnection:SendRequest("SDL.ActivateApp", {appID = hmi_app_id})
  EXPECT_HMIRESPONSE(activate_cid)
  :Do(function()
    self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {
        allowed = true, 
        source = "GUI", 
        device = {
          id = config.deviceMAC, 
          name = common_functions:GetValueFromIniFile("ServerAddress")}})
    EXPECT_HMICALL("BasicCommunication.ActivateApp")
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
      end)   
  end)
  self.mobileSession:ExpectNotification("OnHMIStatus", {
      hmiLevel = "FULL", audioStreamingState = audio_streaming_state, systemContext = "MAIN"})
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"}) 
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :Do(function(_, data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
end

function Test:Verify_Snapshot()
  -- check Snapshot file exists
  if not common_functions:IsFileExist(snapshot_path) then
    self:FailTestCase("Snapshot file does not exist.")
  end
  -- check appID exist in "app_policies"
  local path_to_app_policies = {"policy_table", "app_policies"}
  local app_policies = common_functions:GetItemsFromJsonFile(snapshot_path, path_to_app_policies)
  if not app_policies[const.default_app.appID] then
    self:FailTestCase("Application id = " .. const.default_app.appID .. "does not exist in Snapshot's 'app_policies'.")
  end
  -- check app permission in Snapshot should be the same as in sdl_preaded_pt.json file
  local path_to_app_permissions = {"policy_table", "app_policies", const.default_app.appID}
  local snapshot_app_permissions = common_functions:GetItemsFromJsonFile(snapshot_path, path_to_app_permissions)
  local result = true
  for k in pairs(preload_app_permissions) do
    if k == "groups" then 
      if not common_functions:CompareTables(preload_app_permissions[k], snapshot_app_permissions[k]) then
        common_functions:PrintError("App's '" .. k .. "' values in Snapshot and PreloadedPT are different:")
        common_functions:PrintTable(snapshot_app_permissions[k])
        common_functions:PrintTable(preload_app_permissions[k])
        result = false
      end
    else
      if preload_app_permissions[k] ~= snapshot_app_permissions[k] then
        common_functions:PrintError("App's '" .. k .. "' values in Snapshot (= " .. 
        tostring(snapshot_app_permissions[k]) .. ") and PreloadedPT (= " .. 
        tostring(preload_app_permissions[k]) .. ") are different.")
        result = false
      end
    end
  end
  if not result then
    self:FailTestCase("App permissions in Snapshot and PreloadedPT are different.")
  end
end

function Test:GetURLS()
  local get_urls_corid = self.hmiConnection:SendRequest("SDL.GetURLS", {service = 7})
  EXPECT_HMIRESPONSE(get_urls_corid)
end

function Test:OnSystemRequest_OnStatusUpdate_UPDATING()
  self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", {
      requestType = "PROPRIETARY",
      fileName = snapshot_path,
      appID = common_functions:GetHmiAppId(const.default_app.appName, self)})
  EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "PROPRIETARY", fileType = "JSON"})
  :Do(function(_, data)
    if not (data.binaryData ~= nil and string.len(data.binaryData) > 0) then
      self:FailTestCase("PTS was not sent to Mobile in payload of OnSystemRequest")
    end
  end)
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
