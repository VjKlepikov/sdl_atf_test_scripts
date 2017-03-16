---------------------------------------------------------------------------------------------
-- TC: Check that SDL verifies every App's request before processing it using
-- appropriate group of permission
-- Precondition: App is registered
-- Steps:
-- -- 1. Send 3 APIs from allowed levels with valid parameters
-- Expected behaviour
-- -- 1. Output shows all permissions for default group
-- -- 2. All APIs are processed correctly

-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

---------------------------- Variables and Common function ----------------------------------
api_name = "AddCommand"
local functional_groupings = common_functions:GetParameterValueInJsonFile
(config.pathToSDL.."sdl_preloaded_pt.json", {"policy_table", "app_policies", "default", "groups"})

local list_allowed_levels = common_functions:GetParameterValueInJsonFile
(config.pathToSDL.."sdl_preloaded_pt.json", {"policy_table", "functional_groupings",
    functional_groupings[1], "rpcs", api_name, "hmi_levels"})

function check_api_has_NONE_disallowed_level()
  for i=1, #list_allowed_levels do
    if list_allowed_levels[i] == "NONE" then
      return false
    end
  end
  return true
end

------------------------------------ Precondition -------------------------------------------
function Test:Delete_Policy_Table()
  common_functions:DeletePolicyTable()
end
common_steps:PreconditionSteps("PreconditionSteps", 6)
common_steps:PutFile("Putfile_Icon.png", "icon.png")

------------------------------------------- Steps -------------------------------------------
function Test:Verify_AddCommand_DISALLOWED_at_NONE_level()
  if check_api_has_NONE_disallowed_level() then
    local cid = self.mobileSession:SendRPC("AddCommand", {
        cmdID = 11,
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
      }})
    EXPECT_RESPONSE(cid, {success = false, resultCode = "DISALLOWED"})
  else
    self.FailTestCase(api_name .. ": NONE isn't disallowed level")
  end
end
-------------------------------------------Postconditions-------------------------------------
common_steps:StopSDL("Postcondition_StopSDL")

