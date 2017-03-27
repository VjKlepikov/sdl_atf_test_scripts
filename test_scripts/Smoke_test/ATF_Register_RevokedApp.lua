---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-19829]: [RegisterAppInterface] Allow only RegisterAppInterface for the application with NULL policies.

-- Description:
-- In case PolicyTable has "<appID>": "null" in the Local PolicyTable,
-- PoliciesManager must only process RegisterAppInterface request with successful response

-- Preconditions:
-- 1. Appid = 123 existed in LPT, not revoked.
-- 2. Perform PTU contains: "<appID>" section (for example, appID=123) with "null" permissions to app with appID = 123 become revoked app :
-- "policy_table":{
-- "app_policies":{
-- "123":null
-- }
--}
-- Steps:
-- 1. Mob -> SDL: Send valid registration request: app->SDL:RegisterAppInterface (appID: 123, params)

-- Expected result:
-- SDL -> Mob: RegisterAppInterface(SUCCESS)

---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')
---------------------------------------------------------------------------------------------
common_steps:AddNewTestCasesGroup("Precondtions")
common_steps:PreconditionSteps("PrecondtionSteps", 7)
update_policy:updatePolicy("files/PTU_For_SmokeTesting.json", _, "Preconditions_PTU_With_RevokedApp")
common_steps:UnregisterApp("PrecondtionSteps_UnRegister_Normal_App", config.application1.registerAppInterfaceParams.appName)

common_steps:AddNewTestCasesGroup("Test")
local app_revoked = common_functions:CreateRegisterAppParameters(
  {appID = "123", appName = "Revoked_app"})
common_steps:RegisterApplication("Register_Revoked_Application_AppId_123", _, app_revoked)

-----------------------------------Postcondition-------------------------------
common_steps:AddNewTestCasesGroup("Postconditions")
common_steps:StopSDL("Postcondition_StopSDL")
