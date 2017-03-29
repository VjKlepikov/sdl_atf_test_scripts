---------------------------------------------------------------------------------------------
-- Requirement summary: 
-- [APPLINK-19859]: [OnAppInterfaceUnregistered] "APP_UNAUTHORIZED" in case of failed nickname validation after updated policies.

-- Description:
-- In case the application with appName = "FordMondeo" is successfully registered to SDL
-- and the updated policies do not have this "appName" in this app's specific policies (= "nicknames" filed in "<appID>" section of "app_policies")
-- SDL must: send OnAppInterfaceUnregistered (APP_UNAUTHORIZED) to such application.

-- Preconditions:
-- 1. App is registered and activated

-- Steps:
-- 1. Initiate a Policy Table Update (for example, by registering an application with <appID> non-existing in LocalPT).
-- 2. Updated PT has a different "nicknames" for appID=123:

-- Expected result:
-- SDL -> Mob: OnAppInterfaceUnregistered (APP_UNAUTHORIZED) after PTU successfully.
---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')
---------------------------------------------------------------------------------------------
common_steps:AddNewTestCasesGroup("Preconditions")
common_steps:PreconditionSteps("Precondition", 5)
-- Register application
common_steps:RegisterApplication("RegisterApplication_app_with_original_name", 
"mobileSession", common_functions:CreateRegisterAppParameters(
{appID = "12345", appName = "FordMondeo"}))
common_steps:ActivateApplication("ActivationApplication_app_with_original_name", 
"FordMondeo", _, _)

common_steps:AddNewTestCasesGroup("Test") 

-- Perform PTU with appName not listed in nicknames of ptu file
-- Nicknames in ptu file:"Ford", "FordMotorCompany","FordFocus"
function Test:PTU_Success_App_Unregistered_UNAUTHORIZED()
	local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
	EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetURLS", urls = {{url = const.endpoints_rpc_url}}}})
	:Do(function()
		self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",{requestType = "PROPRIETARY", fileName = "filename"})
		EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
		:Do(function()
			local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", {fileName = "PolicyTableUpdate", requestType = "PROPRIETARY"}, "files/PTU_For_SmokeTesting.json")
			local systemRequestId
			EXPECT_HMICALL("BasicCommunication.SystemRequest")
			:Do(function(_,data)
				systemRequestId = data.id
				self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
				{
					policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
				})
				local function to_run()
					self.hmiConnection:SendResponse(systemRequestId, "BasicCommunication.SystemRequest", "SUCCESS", {})
					self.mobileSession:ExpectResponse(CorIdSystemRequest, {success = true, resultCode = "SUCCESS"})
				end
				RUN_AFTER(to_run, 800)
				EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UP_TO_DATE"}):Timeout(500)
			end)
		end)
	end)
	EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", {reason = "APP_UNAUTHORIZED"})	
end

common_steps:AddNewTestCasesGroup("Postconditions")
common_steps:StopSDL("Postconditions_StopSDL")
