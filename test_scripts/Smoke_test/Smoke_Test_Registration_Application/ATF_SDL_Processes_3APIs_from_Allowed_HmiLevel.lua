---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-16839]: [Policies] HMI Levels the request is allowed to be processed in (multiple functional groups)

-- Description: In case the RPC is listed under more than one functional group in "functional_groupings" section
-- of Policy Table, Policy Manager must perform a logical
-- OR among all of the possible allowed permissions scenarios
-- for the RPC (and parameter/or HMI level) defined by each of the functional groups.

-- Precondition: App is registered and has default permissions

-- Steps:
-- 1. Send 3 APIs from allowed levels with valid parameters

-- Expected behaviour
-- 1. All APIs are processed correctly

-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

---------------------------- Variables and Common function ----------------------------------
local path_sdl_preload_file = config.pathToSDL.."sdl_preloaded_pt.json"
local removed_item = {"policy_table", "functional_groupings","Base-4","rpcs"}
local icon_image_full_path = common_functions:GetFullPathIcon("icon.png")
local added_items = [[{
  "AddCommand": {
    "hmi_levels": [
    "BACKGROUND",
    "FULL",
    "LIMITED"
    ]},
  "DeleteCommand": {
    "hmi_levels": [
    "BACKGROUND",
    "FULL",
    "LIMITED"
    ]},
  "PutFile": {
    "hmi_levels": [
    "BACKGROUND",
    "FULL",
    "LIMITED"
    ]}
}]]

------------------------------------ Precondition -------------------------------------------
common_steps:BackupFile("Precondition_Backup_PreloadedPT", "sdl_preloaded_pt.json")
function Test:Delete_Policy_Table()
  common_functions:DeletePolicyTable()
end
common_functions:AddItemsIntoJsonFile(path_sdl_preload_file, removed_item, added_items)
common_steps:PreconditionSteps("PreconditionSteps", 7)

------------------------------------------- Steps -------------------------------------------
function Test:Verify_PutFile_ALLOWED()
  local cid = self.mobileSession:SendRPC("PutFile", {
      syncFileName = "icon.png",
      fileType = "GRAPHIC_PNG",
      persistentFile = false,
      systemFile = false, }, "files/icon.png")
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
end

function Test:Verify_AddCommand_ALLOWED()
  local cid = self.mobileSession:SendRPC("AddCommand",
    {
      cmdID = 1,
      menuParams = {
        position = 0,
        menuName ="Commandpositive"
      },
      vrCommands = {
        "VRCommandonepositive",
        "VRCommandonepositivedouble"
      },
      cmdIcon = {
        value ="icon.png",
        imageType ="DYNAMIC"
      }
    })
  EXPECT_HMICALL("UI.AddCommand", {
      cmdID = 1,
      cmdIcon = {
        value = icon_image_full_path,
        imageType = "DYNAMIC"
      },
      menuParams = {
        position = 0,
        menuName ="Commandpositive"
      }
    })
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  EXPECT_HMICALL("VR.AddCommand", {
      cmdID = 1,
      type = "Command",
      vrCommands = {
        "VRCommandonepositive",
        "VRCommandonepositivedouble"
      }
    })
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  EXPECT_NOTIFICATION("OnHashChange")
end

function Test:Verify_DeleteCommand_ALLOWED()
  local cid = self.mobileSession:SendRPC("DeleteCommand",{ cmdID = 1})
  EXPECT_HMICALL("UI.DeleteCommand", {
      cmdID = 1,
      appID = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)
    })
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  EXPECT_HMICALL("VR.DeleteCommand", {
      cmdID = 1,
      type = "Command",
      grammarID = data.params.grammarID,
      appID = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)
    })
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  EXPECT_NOTIFICATION("OnHashChange")
end

-------------------------------------------Postconditions-------------------------------------
common_steps:StopSDL("Postcondition_StopSDL")
common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")
