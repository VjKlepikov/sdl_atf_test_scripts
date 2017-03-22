---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-23203]: [Policies]  "pre_DataConsent" policies  assigned to the application and "priority" value

-- Description: 
-- Check that SDL assigns correct Priority level (from "pre_DataConsent" section)
-- to all registered mobile applications

-- Precondition: SDL is started at the 1st life cycle

-- Steps:
-- 1. Register App1
-- 2. Unregister App1
-- 3. Register Ap2

-- Expected behavior:
-- 1. App1 is registered, during registration SDL sends to HMI OnAppRegistered
-- -- with priority (from "application" table for id = "pre_dataConsent")
-- 2. App1 is unregistered
-- 3. App2 is registered, during registration SDL sends to HMI OnAppRegistered
-- -- with priority (from "application" table for id = "pre_dataConsent")

-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

------------------------------------ Precondition -------------------------------------------
function Test:Delete_Policy_Table()
  common_functions:DeletePolicyTable()
end
common_steps:PreconditionSteps("PreconditionSteps", 6)

local preDataConsent_priority = common_functions:GetParameterValueInJsonFile
(config.pathToSDL.."sdl_preloaded_pt.json", {"policy_table", "app_policies", "pre_DataConsent", "priority"})
---------------------------------------- Steps ----------------------------------------------
common_steps:UnregisterApp("Unregister_Application", const.default_app_name)

function Test:Verify_Registered_App_Is_Assigned_PriorityLevel_from_PredataConsent()
  local app_name = config.application1.registerAppInterfaceParams.appName
  local app_id = config.application1.registerAppInterfaceParams.appID
  local cid = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = {appName = app_name}, priority = preDataConsent_priority})
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
end

-------------------------------------------Postconditions-------------------------------------
common_steps:StopSDL("Postcondition_StopSDL")

