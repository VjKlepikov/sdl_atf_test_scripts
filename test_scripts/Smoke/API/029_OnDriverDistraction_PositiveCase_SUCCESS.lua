---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: OnDriverDistraction
-- Item: Happy path
--
-- Requirement summary:
-- [OnDriverDistraction] SUCCESS: getting SUCCESS:UI.OnDriverDistraction()
--
-- Description:
-- HMI sends OnDriverDistraction notification with valid parameters to SDL,
-- SDL resends notification to mobile application successful

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level

-- Steps:
-- HMI sends OnDriverDistraction with valid parameters

-- Expected:
-- SDL  receives notification and validates parameters
-- SDL checks if OnDriverDistraction is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL transfers notification with allowed parameters to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSmoke = require('test_scripts/Smoke/commonSmoke')

--[[ Local Variables ]]
local OnDDValue = { "DD_ON", "DD_OFF" }

--[[ Local Functions ]]
local function onDriverDistraction(pOnDDValue, self)
  local request = { state = pOnDDValue }
  self.hmiConnection:SendNotification("UI.OnDriverDistraction", request)
  self.mobileSession1:ExpectNotification("OnDriverDistraction", request)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSmoke.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSmoke.start)
runner.Step("RAI", commonSmoke.registerApp)
runner.Step("Activate App", commonSmoke.activateApp)

runner.Title("Test")
for _, v in pairs(OnDDValue) do
  runner.Step("OnDriverDistraction with state " .. v .. " Positive Case", onDriverDistraction, { v })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
