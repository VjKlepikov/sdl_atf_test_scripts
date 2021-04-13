---------------------------------------------------------------------------------------------------
-- Description:
-- Check that SDL processes correctly BC.OnEventChanged received when PTU has been triggered by HMI
-- in case 2 apps are registered
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
  common.getMobileSession(1):ExpectNotification("OnHMIStatus",
    { hmiLevel = "LIMITED", systemContext = "MAIN" })
  common.getMobileSession(2):ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", systemContext = "MAIN" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI1", common.registerApp, { 1 })
runner.Step("RAI2", common.registerApp, { 2 })
runner.Step("Activate App1", common.activateApp, { 1 })
runner.Step("Activate App2", common.activateApp, { 2 })
runner.Step("PTU", common.policyTableUpdate)

for iter, time in pairs(common.timeToSendNotif) do
  runner.Title("Test " .. iter)
  runner.Step("Trigger PTU, OnEventChanged available=true", triggerPTUwithOnEventChange, { time })
  runner.Step("PTU", common.policyTableUpdate)
  runner.Step("OnEventChanged available=false", onEventChangeAvailableFalse)
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
