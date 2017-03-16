---------------------------------------------------------------------------------------------
-- TC: Check that all AppIDs of connected application
-- -- added to "app_level" session of local policy table
-- Precondition: App is configured to do not reply for OnSystemRequest
-- Steps:
-- -- 1. Register 4 Apps
-- Expected behaviour
-- All AppIDs of connected application added to "app_level" session of local policy table

-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

---------------------------Variables and Common Function-------------------------------------
local MOBILE_SESSION = {"mobileSession1", "mobileSession2", "mobileSession3", "mobileSession4"}
local apps = {}
apps[1] = common_functions:CreateRegisterAppParameters(
  {appID = "1", appName = "NAVIGATION", isMediaApplication = false, appHMIType = {"NAVIGATION"}}
)
apps[2] = common_functions:CreateRegisterAppParameters(
  {appID = "2", appName = "MEDIA", isMediaApplication = true, appHMIType = {"MEDIA"}}
)
apps[3] = common_functions:CreateRegisterAppParameters(
  {appID = "3", appName = "COMMUNICATION", isMediaApplication = false, appHMIType = {"COMMUNICATION"}}
)
apps[4] = common_functions:CreateRegisterAppParameters(
  {appID = "4", appName = "NON_MEDIA", isMediaApplication = false, appHMIType = {"DEFAULT"}}
)

local function getRegisteredAppIDs(self)
  local appIDs = {}
  for k_mobile_connection_name, v_mobile_connection_data in pairs(self.mobile_connections) do
    for k_mobile_session_name, v_mobile_session_data in pairs(v_mobile_connection_data) do
      for k_application_id, v_application_data in pairs(v_mobile_session_data) do
        if not v_application_data.is_unregistered then
          appIDs[#appIDs + 1] = v_application_data.register_application_parameters.appID
        end
      end
    end
  end
  return appIDs
end

------------------------------------ Precondition -------------------------------------------
common_steps:PreconditionSteps("PreconditionSteps", 4)

--------------------------------------------BODY---------------------------------------------
for i = 1, #apps do
  common_steps:AddMobileSession("Add_Mobile_Session_" .. tostring(i), _, MOBILE_SESSION[i])
  common_steps:RegisterApplication("Register_App_" .. apps[i].appName, MOBILE_SESSION[i], apps[i])
  common_steps:ActivateApplication("Activate_App_" .. apps[i].appName, apps[i].appName)
end

function Test:Check_all_AppIDS_are_In_app_level()
  local expected_appIDs = {}
  for i=1, #apps do
    expected_appIDs[#expected_appIDs + 1] = apps[i].appID
  end
  local actual_appIDs = getRegisteredAppIDs(self)
  table.sort(expected_appIDs)
  table.sort(actual_appIDs)
  local value = common_functions:CompareTables(expected_appIDs, actual_appIDs)
  if value == false then self.FailTestCase() end
end

-------------------------------------------Postconditions-------------------------------------
common_steps:StopSDL("Postcondition_StopSDL")

