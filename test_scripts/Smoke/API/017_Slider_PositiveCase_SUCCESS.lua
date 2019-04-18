---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: Slider
-- Item: Happy path
--
-- Requirement summary:
-- [Slider] SUCCESS: getting SUCCESS:UI.Slider()
--
-- Description:
-- Mobile application sends valid Slider request and gets UI.Slider "SUCCESS" response from HMI

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level

-- Steps:
-- appID requests Slider with valid parameters

-- Expected:
-- SDL validates parameters of the request
-- SDL checks if UI interface is available on HMI
-- SDL checks if Slider is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL transfers the UI part of request with allowed parameters to HMI
-- SDL receives UI part of response from HMI with "SUCCESS" result code
-- SDL responds with (resultCode: SUCCESS, success:true) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSmoke = require('test_scripts/Smoke/commonSmoke')

--[[ Local Variables ]]
local requestParams = {
  numTicks = 7,
  position = 1,
  sliderHeader ="sliderHeader",
  timeout = 1000,
  sliderFooter = { "sliderFooter" }
}

--[[ Local Functions ]]
local function slider(params, self)
  local cid = self.mobileSession1:SendRPC("Slider", params)
  params.appID = commonSmoke.getHMIAppId()
  EXPECT_HMICALL("UI.Slider", params)
  :Do(function(_,data)
      self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = params.appID, systemContext = "HMI_OBSCURED" })
      local function sendReponse()
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 1})
        self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = params.appID, systemContext = "MAIN" })
      end
      RUN_AFTER(sendReponse, 1000)
    end)
  self.mobileSession1:ExpectNotification("OnHMIStatus",
    { systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = commonSmoke.GetAudibleState() },
    { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = commonSmoke.GetAudibleState() })
  :Times(2)
  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS", sliderPosition = 1 })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSmoke.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSmoke.start)
runner.Step("RAI", commonSmoke.registerApp)
runner.Step("Activate App", commonSmoke.activateApp)

runner.Title("Test")
runner.Step("Slider Positive Case", slider, {requestParams})

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
