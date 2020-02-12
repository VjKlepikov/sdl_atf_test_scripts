---------------------------------------------------------------------------------------------------
-- User story: https://github.com/CustomSDL/Sync3.2v2/issues/512
---------------------------------------------------------------------------------------------------
--
-- Description: TBA
--
-- Steps:
-- TBA
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects_OnTouchEvent/commonDefects')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }
config.application1.registerAppInterfaceParams.isMediaApplication = false



local valid_values = {
  {name = "IsLowerBound", value = 0},
  {name = "IsMiddle", value = 1147483647},
  {name = "IsMax", value = 2147483648}
}

local invalid_values = {
  {name = "IsMaxOut", value = 2147483649},
  {name = "IsUpperBound", value = 5000000000},
  {name = "IsMissed", value = nil},
  {name = "IsOutLowerBound", value = {}},
  {name = "WrongDataType", value = "123"}
}


-- [[ Local Functions ]]
local function OnTouchEvent(pTs, pTimes)
  local sendParams = {
    type = "BEGIN",
    event = { {c = {{x = 1, y = 1}}, id = 1, ts = { pTs }}}
  }
  common.getHMIConnection():SendNotification("UI.OnTouchEvent", sendParams)
  common.getMobileSession():ExpectNotification("OnTouchEvent", sendParams)
  :Times(pTimes)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update preloaded", common.updatePreloadedPT())
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("RAI", common.registerApp)
runner.Step("Activate App", common.activateApp)

for i = 1, #valid_values do
  runner.Step("HMI sends UI.OnTouchEvent with the 'ts' ".. tostring(valid_values[i].value),
  OnTouchEvent, { valid_values[i].value, 1 })
end

for i = 1, #invalid_values do
  runner.Step("HMI sends UI.OnTouchEvent with the 'ts' ".. tostring(valid_values[i].value),
    OnTouchEvent, { invalid_values[i].value, 0 })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
