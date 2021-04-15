---------------------------------------------------------------------------------------------------
-- Description:
-- Check that SDL processes correctly BC.OnEventChanged received when PTU has been triggered by new app registration
-- in case 4 apps are registered and BC.OnEventChanged notification was sent after SDL.OnStatusUpdate
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/HMI_level_change_during_PTU_start/common')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local timeToSendNotif = {
  0, 1, 2, 3, 4, 5, 7, 10, 13, 15, 17, 20, 25, 30, 35, 50, 70, 100, 120, 150, 200, 400
}

--[[ Local Functions ]]
local function triggerPTUwithOnEventChange(pIter, pTime)
  local appId = 5 + pIter
  config["application" .. appId] = config.application1
  config["application" .. appId].registerAppInterfaceParams.appName = "Test " .. appId
  config["application" .. appId].registerAppInterfaceParams.appID = tostring(appId)
  local function onEventChanged()
    common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged",
      { isActive = true, eventName = "PHONE_CALL" })
  end
  common.registerApp(appId)
  common.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate", { status = "UPDATE_NEEDED" })
  :Do(function(_, d2)
      RUN_AFTER(onEventChanged, pTime)
      common.getHMIConnection():SendResponse(d2.id, d2.method, "SUCCESS", { })
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI1", common.registerApp)
runner.Step("RAI2", common.registerApp, { 2 })
runner.Step("RAI3", common.registerApp, { 3 })
runner.Step("RAI4", common.registerApp, { 4 })
runner.Step("Activate App1", common.activateApp)
runner.Step("Activate App2", common.activateApp, { 2 })
runner.Step("Activate App3", common.activateApp, { 3 })
runner.Step("Activate App4", common.activateApp, { 4 })
runner.Step("PTU", common.policyTableUpdate)

for iter=1, 400 do
  runner.Title("Test " .. iter)
  runner.Step("Trigger PTU, OnEventChanged available=true", triggerPTUwithOnEventChange, { iter, iter })
  runner.Step("PTU", common.policyTableUpdate)
  runner.Step("OnEventChanged available=false", common.onEventChangeAvailableFalse)
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
