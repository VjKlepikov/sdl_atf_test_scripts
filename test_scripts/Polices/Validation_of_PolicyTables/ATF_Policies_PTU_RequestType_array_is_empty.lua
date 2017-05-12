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
local request_type = {
  "HTTP",
  "FILE_RESUME",
  "AUTH_REQUEST",
  "AUTH_CHALLENGE",
  "AUTH_ACK",
  "PROPRIETARY",
  "LAUNCH_APP",
  -- "QUERY_APPS", -- SDL behaviour in case SDL 4.0 feature is required to be ommited in implementation (UNSUPPORTED_RESOURCE)
  --"LOCK_SCREEN_ICON_URL", -> applicable to OnSystemRequest only
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

--[[ Local Functions ]]
--[[ Specific Precondition ]]
common_steps:AddNewTestCasesGroup("Preconditions")
common_steps:PreconditionSteps("PreconditionSteps", const.precondition.ACTIVATE_APP)
update_policy:updatePolicy("files/PTU_RequestType_empty.json", _, "PreconditionSteps_UpdatePolicy_With_RequestType_Of_App_SPT2_Is_Empty")

function Test:Check_Request_Type_Is_Empty_In_SnapShot()
  local file_name = strIvsu_cacheFolder .. "sdl_snapshot.json"
  if common_steps:FileExisted(file_name) then
    file_name = file_name
  else
    self:FailTestCase("snapshot is not exist")
  end
  local file = io.open(file_name, r)
  local snapshot_file = file:read("*a")
  local snapshot_data_table = json.decode(snapshot_file)

  if not common_functions:CompareTables(snapshot_data_table.policy_table.app_policies.SPT2.RequestType,{}) then
    self:FailTestCase("RequestType of " .. app.appID .. " is not empty")
  end
end

common_steps:AddMobileSession("AddMobileSession", _, "mobileSession1")
common_steps:RegisterApplication("Precondition_Register_App_" .. app.appID, "mobileSession1", app,_, expected_on_hmi_status)
common_steps:ActivateApplication("Precondition_Activate_App_" .. app.appID, app.appName)

for i=1, #request_type do
  common_steps:AddNewTestCasesGroup("RequestType = " .. request_type[i] )

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
function Test:PostconditionStopSDL()
  StopSDL()
end
