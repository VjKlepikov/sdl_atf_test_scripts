---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-22733]: [Policies] "default" policies assigned to the application and "priority" value
-- [APPLINK-19072]: [PolicyTableUpdate] OnStatusUpdate(UPDATE_NEEDED) on new PTU request

-- Description: Check that SDL:
-- adds new appIDs to local policy table
-- sends OnHMIStatus with default hmi level
-- sends OnPermissionChange with RPCs from default

-- Precondition:
-- 1. Device is consented
-- 2. Policy is up-to-date

-- Steps:
-- 1. Register new App

-- Expected behaviour
-- 1. App receives OnHMIStatus with "default_hmi" value from table "application", id=default
-- 2. App receives OnPermissionChange notification with default permissionItem
-- 3. SDL sends to HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
-- 4. SDL sends to the App OnSystemRequest

-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')
local policy = require('user_modules/shared_testcases/testCasesForPolicyTable')
--local snapshot = require('user_modules/shared_testcases_genivi/testCasesForPolicyTableSnapshot')

------------------------------ Variables and Common Functions -------------------------------
local app = common_functions:CreateRegisterAppParameters(
  {appID = "2", appName = "NAVIGATION", isMediaApplication = false, appHMIType = {"NAVIGATION"}}
)
local preloaded_file = config.pathToSDL .. "sdl_preloaded_pt.json"
local copied_preload_file = config.pathToSDL .. "update_sdl_preloaded_pt.json"
local expectation = {}

local function Get_RPCs()
  rpcs = common_functions:GetParameterValueInJsonFile(copied_preload_file, {"policy_table", "functional_groupings", "Base-4", "rpcs"})
  local i=1
  for k, v in pairs(rpcs)do
    if v.parameters == nil then
      parameters_allowed = {}
    else
      parameters_allowed = v.parameters
    end
    expectation[i] =
    {
      rpcName = k,
      parameterPermissions =
      {
        userDisallowed = {},
        allowed = parameters_allowed
      },
      hmiPermissions =
      {
        userDisallowed = {},
        allowed = v.hmi_levels

      }
    }
    i = i+1
  end
end
Get_RPCs()

local parent_default_group = {"policy_table", "app_policies","default","groups"}
local added_default_group = {"Base-4"}

-- ------------------------------------ Precondition -------------------------------------------
common_steps:BackupFile("Precondition_Backup_PreloadedPT", "sdl_preloaded_pt.json")
common_functions:AddItemsIntoJsonFile(preloaded_file, parent_default_group, added_default_group)
common_steps:PreconditionSteps("PreconditionSteps", const.precondition.ACTIVATE_APP)

policy:updatePolicy(copied_preload_file, _, "PreconditionSteps_UpdatePolicy")

-- ---------------------------------------- Steps ----------------------------------------------
function Test:StartNewSession()
  self.mobileSession1 = mobile_session.MobileSession( self, self.mobileConnection)
  self.mobileSession1:StartService(7)
end

function Test:Register_NewApp_And_Verify_SDL_Send_Correct_Params_to_HMI()
  local parent_default_hmi = {"policy_table","app_policies","default","default_hmi"}
  local default_hmi = common_functions:GetParameterValueInJsonFile(preloaded_file, parent_default_hmi)

  local cid = self.mobileSession1:SendRPC("RegisterAppInterface", app)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = {appName = app.appName}})
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})
  self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", { requestType = "PROPRIETARY",
      fileName = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate" })
  EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
  self.mobileSession1:ExpectResponse(cid, {success = true, resultCode = "SUCCESS"})
  self.mobileSession1:ExpectNotification("OnHMIStatus", {hmiLevel = default_hmi, audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  self.mobileSession1:ExpectNotification("OnPermissionsChange")
  :ValidIf(function(exp,data)
      if common_functions:CompareTablesNotSorted(expectation, data.payload.permissionItem) then
        return true
      else
        self:FailTestCase("Fail: OnPermissionsChange.permissionItem is incorrect")
        return false
      end
    end)
end

-------------------------------------------Postconditions-------------------------------------
common_steps:StopSDL("Postcondition_StopSDL")
common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")
