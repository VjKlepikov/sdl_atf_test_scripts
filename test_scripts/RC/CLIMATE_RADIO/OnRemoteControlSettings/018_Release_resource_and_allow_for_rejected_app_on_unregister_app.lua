---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/10
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/resource_allocation.md
-- Item: Use Case 1: Exception 1.1
--
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/10
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/resource_allocation.md
-- Item: Use Case 1: Exception 2.2
--
-- Requirement summary:
-- [SDL_RC] Resource allocation based on access mode
--
-- Description:
-- In case:
-- RC_functionality is disabled on HMI and HMI sends notification OnRemoteControlSettings (allowed:true, <any_accessMode>)
--
-- SDL must:
-- 1) store RC state allowed:true and received from HMI internally
-- 2) allow RC functionality for applications with REMOTE_CONTROL appHMIType
--
-- Additional checks:
-- - Result code SUCCESS in ASK_DRIVER access mode for previously rejected apps in ASK_DRIVER access mode after unregister app which allocated resource on
-- - Result code IN_USE in AUTO_DENY access mode for previously rejected apps in ASK_DRIVER access mode after unregister app which allocated resource on
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

config.application3.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }

--[[ Local Functions ]]
local function ptu_update_func(tbl)
  tbl.policy_table.app_policies[config.application2.registerAppInterfaceParams.fullAppID] = commonRC.getRCAppConfig()
  tbl.policy_table.app_policies[config.application3.registerAppInterfaceParams.fullAppID] = commonRC.getRCAppConfig()
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI1, PTU", commonRC.rai_ptu, { ptu_update_func })
runner.Step("RAI2", commonRC.rai_n, { 2 })
runner.Step("RAI3", commonRC.rai_n, { 3 })

runner.Title("Test")
runner.Title("Default -> ASK_DRIVER")
runner.Step("Enable RC from HMI with ASK_DRIVER access mode", commonRC.defineRAMode, { true, "ASK_DRIVER"})
runner.Step("Activate App2", commonRC.activate_app, { 2 })
runner.Step("Module CLIMATE App2 ButtonPress allowed", commonRC.rpcAllowed, { "CLIMATE", 2, "ButtonPress" })
runner.Step("Activate App1", commonRC.activate_app)
runner.Step("Module CLIMATE App1 SetInteriorVehicleData rejected with driver consent", commonRC.rpcRejectWithConsent, { "CLIMATE", 1, "SetInteriorVehicleData" })
runner.Step("Activate App3", commonRC.activate_app, { 3 })
runner.Step("Module CLIMATE App3 ButtonPress rejected with driver consent", commonRC.rpcRejectWithConsent, { "CLIMATE", 3, "ButtonPress" })
runner.Step("Unregister App2", commonRC.unregisterApp, { 2 })
runner.Step("Module CLIMATE App3 ButtonPress allowed", commonRC.rpcAllowed, { "CLIMATE", 3, "ButtonPress" })
runner.Title("ASK_DRIVER -> AUTO_DENY")
runner.Step("Enable RC from HMI with AUTO_DENY access mode", commonRC.defineRAMode, { true, "AUTO_DENY"})
runner.Step("Activate App1", commonRC.activate_app)
runner.Step("Check module CLIMATE App1 SetInteriorVehicleData denied", commonRC.rpcDenied, { "CLIMATE", 1, "SetInteriorVehicleData", "IN_USE" })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
