--[[ Description ]]
-- [APPLINK-23967]: [Policies] PTU "RequestType" array is empty
-- Description:
-- In case PTU with "<appID>" policies comes and "RequestType" array is empty
-- -> Policies Manager must leave "RequestType" as empty array and allow any request type for such <appID> app

-- Preconditions:
-- App1 is activated
-- Update Policy with App2 has RequestType is empty

-- Steps:
-- 1. Verify "RequestType" is empty in App2
-- 2. Send SystemRequest RPC with any RequestType

-- Expected result:
-- System allows any request type for App2

--[[ Generic precondition ]]
require('user_modules/all_common_modules')

--[[ Local Variables ]]
local app = common_functions:CreateRegisterAppParameters(
  {appID = "SPT2", appName = "SPT_Name_02", isMediaApplication = false, appHMIType = {"NAVIGATION"}}
)
local expected_on_hmi_status = {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}
local strIvsu_cacheFolder = common_functions:GetValueFromIniFile("SystemFilesPath") .. "/"
local snapshot_file = strIvsu_cacheFolder .. "sdl_snapshot.json"
local request_type = {
  "HTTP",
  "FILE_RESUME",
  "AUTH_REQUEST",
  "AUTH_CHALLENGE",
  "AUTH_ACK",
  "PROPRIETARY",
  "LAUNCH_APP",
  -- "QUERY_APPS", -> SDL behaviour in case SDL 4.0 feature is required to be omitted in implementation (UNSUPPORTED_RESOURCE)
  -- "LOCK_SCREEN_ICON_URL", -> applicable to OnSystemRequest only
  "TRAFFIC_MESSAGE_CHANNEL",
  "DRIVER_PROFILE",
  "VOICE_SEARCH",
  "NAVIGATION",
  "PHONE",
  "CLIMATE",
  "SETTINGS",
  "VEHICLE_DIAGNOSTICS",
  "EMERGENCY",
  "MEDIA",
  "FOTA"
}

--[[ Specific Precondition ]]
common_steps:AddNewTestCasesGroup("Preconditions")

function Test:Remove_Existed_Snapshot_File()
  if common_steps:FileExisted(snapshot_file) then
    os.execute( "rm -f " .. snapshot_file)
  end
end

common_steps:PreconditionSteps("PreconditionSteps", const.precondition.ACTIVATE_APP)
update_policy:updatePolicy("files/PTU_RequestType_empty.json", _, "PreconditionSteps_UpdatePolicy_With_RequestType_Of_App_SPT2_Is_Empty")
common_steps:AddMobileSession("AddMobileSession", _, "mobileSession1")
common_steps:RegisterApplication("Precondition_Register_App_" .. app.appID, "mobileSession1", app,_, expected_on_hmi_status)
common_steps:ActivateApplication("Precondition_Activate_App_" .. app.appID, app.appName)

function Test:Check_Request_Type_Is_Empty_In_SnapShot()
  local count_sleep = 1
  while not common_steps:FileExisted(snapshot_file) and count_sleep < 9 do
    os.execute("sleep 1")
    count_sleep = count_sleep + 1
  end
  if not common_steps:FileExisted(snapshot_file) then
    self:FailTestCase("snapshot does not exist")
    return
  end
  local snapshot_requestType = common_functions:GetParameterValueInJsonFile(snapshot_file, {"policy_table", "app_policies", app.appID, "RequestType"})

  if not common_functions:CompareTables(snapshot_requestType,{}) then
    self:FailTestCase("RequestType of " .. app.appID .. " is not empty")
  end
end

for i=1, #request_type -10 do
  common_steps:AddNewTestCasesGroup("RequestType = " .. request_type[i])

  Test["Precondtion_PutFile_icon.png_" .. tostring(i)] = function(self)
    local cid = self.mobileSession1:SendRPC(
      "PutFile",
      {
        syncFileName = "icon.png" .. tostring(i),
        fileType = "GRAPHIC_PNG",
        persistentFile = false,
        systemFile = false,
      }, "files/icon.png")

    self.mobileSession1:ExpectResponse(cid, {success = true, resultCode = "SUCCESS"})
  end

  Test["TEST:RequestType_Is_" .. request_type[i]] = function(self)
    local hmi_app_id = common_functions:GetHmiAppId(app.appName, self)
    local cid = self.mobileSession1:SendRPC("SystemRequest",
      { requestType = request_type[i],
        fileName = "icon.png" .. tostring(i)
      }
    )
    EXPECT_HMICALL("BasicCommunication.SystemRequest",
      {
        requestType = request_type[i],
        fileName = strIvsu_cacheFolder .. "icon.png" .. tostring(i),
        appID = hmi_app_id
      })
    :Do(function (_,data)
        self.hmiConnection:SendResponse(data.id, "BasicCommunication.SystemRequest", "SUCCESS", {})
      end)
    self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
  end
end

--[[ Postconditions ]]
common_steps:AddNewTestCasesGroup("Postconditions")
common_steps:StopSDL("Postcondition_StopSDL")
