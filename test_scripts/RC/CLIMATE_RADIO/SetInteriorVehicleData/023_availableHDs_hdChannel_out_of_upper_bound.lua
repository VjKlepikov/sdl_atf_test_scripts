---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0160-rc-radio-parameter-update.md
-- User story: TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- In case:
-- 1) Application is registered with REMOTE_CONTROL appHMIType
-- 2) and sends valid SetInteriorVehicleData RPC with out of upper bound value for hdChannel
-- 3) HMI sends OnInteriorVehicleData with out of upper bound value for availableHDs
-- SDL must:
-- 1) Respond with INVALID_DATA result code, success = false to mobile application
-- 3) not transfer notification to mobile application
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local Module = "RADIO"

--[[ Local Functions ]]
local function setVehicleData()
  local requestParams = commonRC.getSettableModuleControlData(Module)
  requestParams.radioControlData.hdChannel = 8

  local cid = commonRC.getMobileSession():SendRPC("SetInteriorVehicleData", {
	moduleData = requestParams
  })

  EXPECT_HMICALL("RC.SetInteriorVehicleData")
  :Times(0)

  commonRC.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA" })
end

local function onVehicleData()
  local notificationParams = commonRC.getHMIResponseParams("OnInteriorVehicleData", Module)
  notificationParams.moduleData.radioControlData.availableHDs = 8

  commonRC.getHMIConnection():SendNotification(commonRC.getHMIEventName("OnInteriorVehicleData"), notificationParams)
  commonRC.getMobileSession():ExpectNotification(commonRC.getAppEventName("OnInteriorVehicleData"))
  :Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate App", commonRC.activateApp)
runner.Step("Subscribe app to " .. Module, commonRC.subscribeToModule, { Module })

runner.Title("Test")

runner.Step("SetInteriorVehicleData with out of upper bound value for hdChannel", setVehicleData)
runner.Step("OnInteriorVehicleData with out of upper bound value for availableHDs", onVehicleData)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
