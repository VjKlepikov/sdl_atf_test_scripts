---------------------------------------------------------------------------------------------
-- TC: Check that SDL:
-- -- Assign correct priority level (from "pre_dataConsent" session)
-- -- to all registered mobile applications.
-- Precondition: Register App
-- Steps:
-- -- 1. Unregister App
-- -- 2. Register App again
-- Expected behaviour
-- -- 1. App has unregistered from
-- -- 2. App is registered, during registration SDL sends to HMI OnAppRegistered
-- -- with priority (from "application" table for id = default)

-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

------------------------------------ Precondition -------------------------------------------
function Test:Delete_Policy_Table()
  common_functions:DeletePolicyTable()
end
common_steps:PreconditionSteps("PreconditionSteps", 6)

local default_priority = common_functions:GetParameterValueInJsonFile
(config.pathToSDL.."sdl_preloaded_pt.json", {"policy_table", "app_policies", "default", "priority"})
---------------------------------------- Steps ----------------------------------------------
common_steps:UnregisterApp("Unregister_Application", const.default_app_name)

function Test:Verify_SDL_Send_Correct_Params_to_HMI()
  common_functions:DelayedExp(3000)
  local app_name = config.application1.registerAppInterfaceParams.appName
  local app_id = config.application1.registerAppInterfaceParams.appID
  local cid = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = {appName = app_name}, priority= default_priority})
end

-------------------------------------------Postconditions-------------------------------------
common_steps:StopSDL("Postcondition_StopSDL")

