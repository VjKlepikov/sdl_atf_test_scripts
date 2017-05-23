---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-20756]: [Policies] Merging rules for "functional_groupings" section
--  exists in both LocalPT and PreloadedPT

-- Description:
-- SDL Must overwrite the fields & values of "functional_group_name" section at
--  LocalPT based on updated PreloadedPT
--  (that is, replace such functional_group_name in the database by the new one from PreloadedPT)

-- Preconditions:
-- 1. Set AddCommand hmi_levels in PreloadedPT to {"FULL", "BACKGROUND", "LIMITED"}
--  for Base-4 functional_group
-- 2. Set default functional_group to Base-4
-- 3. StartSDL and Activate App to HMILevel FULL

-- Steps:
-- 1. Send AddCommand RPC
-- 2. Change App's HMILevel to BACKGROUND
-- 3. Send AddCommand RPC
-- 4. Stop SDL
-- 5. Set preloaded_date to current date in PreloadedPT
-- 6. Set AddCommand hmi_levels in PreloadedPT to {"FULL", "LIMITED"}
--  for Base-4 functional_group
-- 7. Start SDL and Activate App to HMILevel FULL
-- 8. Send Addcommand RPC
-- 9. Change App's HMILevel to BACKGROUND
-- 10. Send Addcommand RPC

-- Expected result:
-- SDL -> Mob: AddCommand RPC response {success = true, resultCode = "SUCCESS"}
--  Before merge and HMILevel is FULL or BACKGROUND
-- SDL -> Mob: AddCommand RPC response {success = true, resultCode = "SUCCESS"}
--  After merge for HMILevel FULL
-- SDL -> Mob: AddCommand RPC response {success = false, resultCode = "DISALLOWED"}
--  After merge for HMILevel BACKGROUND
---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')
local preloaded_pt_file = config.pathToSDL .. common_functions:GetValueFromIniFile("PreloadedPT")
-- Used to bring app to BACKGROUND with BA.OnAppDeactivated
const.default_app.isMediaApplication = false
const.default_app.appHMIType = {"DEFAULT"}

---------------------------------------------------------------------------------------------
--[[ Preconditions ]]
function Test:Precondition_Set_functional_groupings_into_PreloadedPT()
  local parent_item = {
    "policy_table", "functional_groupings", "Base-4", "rpcs", "AddCommand"
  }
  local values = {
    hmi_levels = {"FULL", "BACKGROUND", "LIMITED"}
  }

  common_functions:AddItemsIntoJsonFile(preloaded_pt_file, parent_item, values)
end

function Test:Precondition_Set_app_policies_default_groups_Base4()
  local parent_item = {"policy_table", "app_policies", "default"}
  local values = {
    groups = {"Base-4"}
  }

  common_functions:AddItemsIntoJsonFile(preloaded_pt_file, parent_item, values)
end

common_steps:PreconditionSteps("Precondition", const.precondition.ACTIVATE_APP)

---------------------------------------------------------------------------------------------
--[[ Test Merge preloadedPT in to LocalPT in case "functional_groupings" exists in both]]
function Test:TestStep_AddCommand_HMILevel_FULL()
  self.icmd_id = 1
  self.hmi_app_id = common_functions:GetHmiAppId(const.default_app_name, self)

  local cid = self.mobileSession:SendRPC("AddCommand", {
    cmdID = self.icmd_id,
    menuParams = { menuName = "Play" .. tostring(self.icmd_id) }
  })

  EXPECT_HMICALL("UI.AddCommand", {
    appID = self.hmi_app_id,
    cmdID = self.icmd_id,
    menuParams = { menuName = "Play" .. tostring(self.icmd_id) }
  })
  :Do(function(_, data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  self.mobileSession:ExpectNotification("OnHashChange")
  :Do(function(_, data)
    self.currentHashID = data.payload.hashID
  end)

  self.mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

function Test:TestStep_SendAppToBACKGROUND()
  self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {
    appID = common_functions:GetHmiAppId(const.default_app_name, self),
    reason = "GENERAL"
  })

  EXPECT_NOTIFICATION("OnHMIStatus", {
    hmiLevel = "BACKGROUND",
    systemContext = "MAIN",
    audioStreamingState = "NOT_AUDIBLE"
  })
end

function Test:TestStep_AddCommand_HMILevel_BACKGROUND()
  self.icmd_id = 2

  local cid = self.mobileSession:SendRPC("AddCommand", {
    cmdID = self.icmd_id,
    menuParams = { menuName = "Play" .. tostring(self.icmd_id) }
  })

  EXPECT_HMICALL("UI.AddCommand", {
    appID = self.hmi_app_id,
    cmdID = self.icmd_id,
    menuParams = { menuName = "Play" .. tostring(self.icmd_id) }
  })
  :Do(function(_, data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  self.mobileSession:ExpectNotification("OnHashChange")
  :Do(function(_, data)
    self.currentHashID = data.payload.hashID
  end)

  self.mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

common_steps:StopSDL("TestStep_StopSDL")

function Test:TestStep_Change_PreloadePT_preloaded_date()
  -- changing preloaded_date will force SDL to merge PrelaodedPT with LocalPT
  local parent_item = {"policy_table", "module_config"}
  local values = {
    preloaded_date = os.date("%Y-%m-%d") -- returns curent year-month-day
  }

  common_functions:AddItemsIntoJsonFile(preloaded_pt_file, parent_item, values)
end

function Test:TestStep_Change_PreloadedPT_functional_groupings()
  local parent_item = {
    "policy_table", "functional_groupings", "Base-4", "rpcs", "AddCommand"
  }
  local values = {
    hmi_levels = {"FULL", "LIMITED"}
  }

  common_functions:AddItemsIntoJsonFile(preloaded_pt_file, parent_item, values)
end

common_steps:PreconditionSteps("TestStep", const.precondition.ACTIVATE_APP)

function Test:TestStep_AddCommand_After_LocalPT_merge_HMILevel_FULL()
  self.icmd_id = 3
  self.hmi_app_id = common_functions:GetHmiAppId(const.default_app_name, self)

  local cid = self.mobileSession:SendRPC("AddCommand", {
    cmdID = self.icmd_id,
    menuParams = { menuName = "Play" .. tostring(self.icmd_id) }
  })

  EXPECT_HMICALL("UI.AddCommand", {
    appID = self.hmi_app_id,
    cmdID = self.icmd_id,
    menuParams = { menuName = "Play" .. tostring(self.icmd_id) }
  })
  :Do(function(_, data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  self.mobileSession:ExpectNotification("OnHashChange")
  :Do(function(_, data)
    self.currentHashID = data.payload.hashID
  end)

  self.mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

function Test:TestStep_Send_AppToBACKGROUND_After_LocalPT_merge()
  self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {
    appID = common_functions:GetHmiAppId(const.default_app_name, self),
    reason = "GENERAL"
  })

  EXPECT_NOTIFICATION("OnHMIStatus", {
    hmiLevel = "BACKGROUND",
    systemContext = "MAIN",
    audioStreamingState = "NOT_AUDIBLE"
  })
end

function Test:TestStep_AddCommand_After_LocalPT_merge_HMILevel_BACKGROUND()
  self.icmd_id = 4
  local cid = self.mobileSession:SendRPC("AddCommand", {
    cmdID = self.icmd_id,
    menuParams = { menuName = "Play" .. tostring(self.icmd_id) }
  })

  self.mobileSession:ExpectResponse(cid, { success = false, resultCode = "DISALLOWED" })
end

---------------------------------------------------------------------------------------------
--[[ Postconditions ]]
common_steps:StopSDL("Postcondition_StopSDL")
