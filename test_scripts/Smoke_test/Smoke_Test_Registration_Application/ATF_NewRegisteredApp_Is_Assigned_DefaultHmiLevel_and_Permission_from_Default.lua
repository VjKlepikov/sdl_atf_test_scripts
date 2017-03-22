---------------------------------------------------------------------------------------------
-- Requirement summary:
-- APPLINK-22733]: [Policies] "default" policies assigned to the application and "priority" value
--[APPLINK-19072]: [PolicyTableUpdate] OnStatusUpdate(UPDATE_NEEDED) on new PTU request

-- Description: PoliciesManager must:
-- Adds new appIDs to local policy table;
-- Send OnHMIStatus with default hmi level to mobile
-- Send OnPermissionsChange with RPCs from default section to mobile
-- Start PTU process

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
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases_genivi/testCasesForPolicyTableSnapshot')

------------------------------ Variables and Common Functions -------------------------------
app = common_functions:CreateRegisterAppParameters(
  {appID = "2", appName = "NAVIGATION", isMediaApplication = false, appHMIType = {"NAVIGATION"}}
)
preloaded_file = config.pathToSDL .. "sdl_preloaded_pt.json"
copied_preload_file = config.pathToSDL .. "update_sdl_preloaded_pt.json"
parent_item = {"policy_table","app_policies","default","default_hmi"}
default_hmi = common_functions:GetParameterValueInJsonFile(preloaded_file, parent_item)

local RPC_Base4 = {}
local function Get_RPCs()
  testCasesForPolicyTableSnapshot:extract_preloaded_pt()
  for i = 1, #testCasesForPolicyTableSnapshot.preloaded_elements do
    if ( string.sub(testCasesForPolicyTableSnapshot.preloaded_elements[i].name,1,string.len("functional_groupings.Base-4.rpcs.")) == "functional_groupings.Base-4.rpcs." ) then
      local str = string.match(testCasesForPolicyTableSnapshot.preloaded_elements[i].name, "functional_groupings%.Base%-4%.rpcs%.(%S+)%.%S+%.%S+")

      if(#RPC_Base4 == 0) then
        RPC_Base4[#RPC_Base4 + 1] = str
      end

      if(RPC_Base4[#RPC_Base4] ~= str) then
        RPC_Base4[#RPC_Base4 + 1] = str
      end
    end
  end
end
Get_RPCs()

------------------------------------ Precondition -------------------------------------------

function Test:Delete_Policy_Table()
  common_functions:DeletePolicyTable()
end

function Test:Create_PTU_file()
  os.execute(" cp " .. preloaded_file .. " " .. copied_preload_file)
  local parent_item = {"policy_table","module_config"}
  local removed_json_items = {"preloaded_pt", "preloaded_date"}
  common_functions:RemoveItemsFromJsonFile(copied_preload_file, parent_item, removed_json_items)
end

common_steps:PreconditionSteps("PreconditionSteps", 7)

testCasesForPolicyTable:updatePolicy(copied_preload_file, _, "PreconditionSteps_UpdatePolicy")

---------------------------------------- Steps ----------------------------------------------
function Test:StartNewSession()
  self.mobileSession1 = mobile_session.MobileSession( self, self.mobileConnection)
  self.mobileSession1:StartService(7)
end

function Test:Register_NewApp_And_Verify_SDL_Send_Correct_Params_to_HMI()
  local cid = self.mobileSession1:SendRPC("RegisterAppInterface", app)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = {appName = app.appName}})
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})
  self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", { requestType = "PROPRIETARY",
      fileName = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate" })
  EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
  self.mobileSession1:ExpectResponse(cid, {success = true, resultCode = "SUCCESS"})
  self.mobileSession1:ExpectNotification("OnHMIStatus", {hmiLevel = default_hmi, audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  self.mobileSession1:ExpectNotification("OnPermissionsChange")
  :Do(function(_,_data)
      local is_perm_item_receved = {}
      for i = 1, #RPC_Base4 do
        is_perm_item_receved[i] = false
      end

      local is_perm_item_needed = {}
      for i = 1, #_data.payload.permissionItem[1].rpcName do
        is_perm_item_needed[i] = false
      end
      for i = 1, #_data.payload.permissionItem do
        for j = 1, #RPC_Base4 do
          if(_data.payload.permissionItem[i].rpcName == RPC_Base4[j]) then
            is_perm_item_receved[j] = true
            is_perm_item_needed[i] = true
            break
          end
        end
      end

      for i = 1,#is_perm_item_needed do
        if (is_perm_item_needed[i] == false) then
          common_functions:PrintError("RPC: ".._data.payload.permissionItem[i].rpcName.." should not be sent")
          is_test_fail = false
        end
      end

      for i = 1,#is_perm_item_receved do
        if (is_perm_item_receved[i] == false) then
          common_functions:PrintError("RPC: "..RPC_Base4[i].." is not sent")
          is_test_fail = false
        end
      end

      if(is_test_fail == true) then
        self:FailTestCase("Test is FAILED. See prints.")
      end
      common_functions:PrintTable(RPC_Base4)
    end)
end

-------------------------------------------Postconditions-------------------------------------
common_steps:StopSDL("Postcondition_StopSDL")
