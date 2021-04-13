---------------------------------------------------------------------------------------------------
-- Description:
-- Check that SDL processes correctly BC.OnEventChanged received when PTU has been triggered by HMI
-- in case one app is registered
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/HMI_level_change_during_PTU_start/common')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function triggerPTUwithOnEventChange(pTime)
  local function onEventChanged()
    common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged",
      { isActive = true, eventName = "PHONE_CALL" })
  end
  local requestId = common.getHMIConnection():SendRequest("SDL.UpdateSDL")
  common.getHMIConnection():ExpectResponse(requestId)
  RUN_AFTER(onEventChanged, pTime)
end

local function onEventChangeAvailableFalse()
  common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged",
    { isActive = false, eventName = "PHONE_CALL" })
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", systemContext = "MAIN" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("PTU", common.policyTableUpdate)

for iter, time in pairs(common.timeToSendNotif) do
  runner.Title("Test " .. iter)
  runner.Step("Trigger PTU, OnEventChanged available=true", triggerPTUwithOnEventChange, { time })
  runner.Step("PTU", common.policyTableUpdate)
  runner.Step("OnEventChanged available=false", onEventChangeAvailableFalse)
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
