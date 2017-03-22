---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-16833]:DISALLOWED in case app's current HMI Level is not listed in assigned policies

-- Description: 
-- Check that SDL verifies every App's request before processing it using appropriate 
-- group of permissions

-- Precondition: App is registered and has default permissions

-- Steps:
-- 1. Send 3 APIs from disallowed levels

-- Expected behaviour
-- 1. All APIs are disallowed

-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

---------------------------- Variables and Common function ----------------------------------
local path_sdl_preload_file = config.pathToSDL.."sdl_preloaded_pt.json"
local removed_item = {"policy_table", "functional_groupings","Base-4","rpcs"}
local icon_image_full_path = common_functions:GetFullPathIcon("icon.png")
local added_items = [[{
  "AddSubMenu": {
    "hmi_levels": [
    "BACKGROUND",
    "LIMITED"
    ]},
  "Show": {
    "hmi_levels": [
    "BACKGROUND",
    "LIMITED"
    ]},
  "ScrollableMessage": {
    "hmi_levels": [
    "BACKGROUND",
    "LIMITED",
    "NONE"
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
function Test:Verify_AddSubMenu_DISALLOWED()
  local cid = self.mobileSession:SendRPC("AddSubMenu",{
      menuID = 1000,
      position = 500,
      menuName ="SubMenupositive"
    })
  EXPECT_RESPONSE(cid, {success = false, resultCode = "DISALLOWED"})
end

function Test:Verify_Show_DISALLOWED()
  local request_params = {
    mainField1 = "a",
    statusBar= "a",
    mediaClock = "a",
    mediaTrack = "a",
    alignment = "CENTERED",
  }
  local cid = self.mobileSession:SendRPC("Show", request_params)
  EXPECT_RESPONSE(cid, {success = false, resultCode = "DISALLOWED"})
end

function Test:Verify_ScrollableMessage_DISALLOWED()
  local cid = self.mobileSession:SendRPC("ScrollableMessage", {
      scrollableMessageBody = "abc",
      softButtons = {
        {
          softButtonID = 1,
          text = "Button1",
          type = "BOTH",
          image = {
            value = "icon.png",
            imageType = "DYNAMIC"
          },
          isHighlighted = false,
          systemAction = "DEFAULT_ACTION"
        }
      }
    })
  EXPECT_RESPONSE(cid, {success = false, resultCode = "DISALLOWED"})
end

-------------------------------------------Postconditions-------------------------------------
common_steps:StopSDL("Postcondition_StopSDL")
common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")
