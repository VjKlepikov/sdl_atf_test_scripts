---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: UnregisterAppInterface
-- Item: Happy path
--
-- Requirement summary:
-- [UnregisterAppInterface] SUCCESS: getting SUCCESS:UnregisterAppInterface()
--
-- Description:
-- Mobile application sends valid UnregisterAppInterface request and gets UnregisterAppInterface "SUCCESS"
-- response from SDL

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level

-- Steps:
-- appID requests UnregisterAppInterface

-- Expected:
-- SDL checks if UnregisterAppInterface is allowed by Policies
-- SDL sends the BasicCommunication notification to HMI
-- SDL responds with (resultCode: SUCCESS, success:true) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSmoke = require('test_scripts/Smoke/commonSmoke')

--[[ Local Functions ]]
local function unregisterAppInterface(self)
	local cid = self.mobileSession1:SendRPC("UnregisterAppInterface", { })
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered",
		{ appID = commonSmoke.getHMIAppId(), unexpectedDisconnect = false })
	self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSmoke.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSmoke.start)
runner.Step("RAI", commonSmoke.registerApp)
runner.Step("Activate App", commonSmoke.activateApp)

runner.Title("Test")
runner.Step("UnregisterAppInterface Positive Case", unregisterAppInterface)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
