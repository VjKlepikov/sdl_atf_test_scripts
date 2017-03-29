---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-23203]: [Policies] "pre_DataConsent" policies assigned to the application and "priority" value

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

------------------------------Variables and Functions----------------------------------------
local mobile_session_name = "mobileSession"

------------------------------------ Precondition -------------------------------------------
local preDataConsent_priority = common_functions:GetParameterValueInJsonFile
(config.pathToSDL.."sdl_preloaded_pt.json", {"policy_table", "app_policies", "pre_DataConsent", "priority"})
---------------------------------------- Steps ----------------------------------------------
common_steps:PreconditionSteps("PreconditionSteps", const.precondition.ADD_MOBILE_SESSION)

function Test:Verify_App1_Is_Assigned_PriorityLevel_from_PredataConsent()
  common_functions:StoreApplicationData(mobile_session_name, const.default_app.appName, const.default_app, _, self)
  local cid = self.mobileSession:SendRPC("RegisterAppInterface", const.default_app)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = {appName = const.default_app.appName}, priority = preDataConsent_priority})
  :Do(function(_,data)
      common_functions:StoreHmiAppId(const.default_app.appName, data.params.application.appID, self)
    end)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
end

common_steps:UnregisterApp("Unregister_Application", const.default_app.appName)

function Test:Verify_App2_Is_Assigned_PriorityLevel_from_PredataConsent()
  local app = common_functions:CreateRegisterAppParameters(
    {appID = "2", appName = "NAVIGATION", isMediaApplication = false, appHMIType = {"NAVIGATION"}}
  )
  common_functions:StoreApplicationData(mobile_session_name, app.appName, app, _, self)
  local cid = self.mobileSession:SendRPC("RegisterAppInterface", app)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = {appName = app.appName}, priority = preDataConsent_priority})
  :Do(function(_,data)
      common_functions:StoreHmiAppId(app.appName, data.params.application.appID, self)
    end)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
end

-------------------------------------------Postconditions-------------------------------------
common_steps:StopSDL("Postcondition_StopSDL")

