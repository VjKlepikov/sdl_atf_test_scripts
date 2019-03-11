---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: DialNumber
-- Item: Happy path
--
-- Requirement summary:
-- [DialNumber] SUCCESS: getting SUCCESS:BasicCommunication.DialNumber()
--
-- Description:
-- Mobile application sends valid DialNumber request and gets BasicCommunication.DialNumber "SUCCESS" response from HMI

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level

-- Steps:
-- appID requests DialNumber with valid parameters

-- Expected:
-- SDL validates parameters of the request
-- SDL checks if BasicCommunication interface is available on HMI
-- SDL checks if DialNumber is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL transfers the BasicCommunication part of request with allowed parameters to HMI
-- SDL receives BasicCommunication part of response from HMI with "SUCCESS" result code
-- SDL responds with (resultCode: SUCCESS, success:true) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSmoke = require('test_scripts/Smoke/commonSmoke')

--[[ Local Variables ]]
local requestParams = {
  number = "#3804567654*"
}

--[[ Local Functions ]]
local function dialNumber(pParams, self)
  local cid = self.mobileSession1:SendRPC("DialNumber", pParams)
  pParams.appID = commonSmoke.getHMIAppId()
  EXPECT_HMICALL("BasicCommunication.DialNumber", pParams)
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSmoke.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSmoke.start)
runner.Step("RAI", commonSmoke.registerApp)
runner.Step("Activate App", commonSmoke.activateApp)

runner.Title("Test")
runner.Step("DialNumber Positive Case", dialNumber, { requestParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
