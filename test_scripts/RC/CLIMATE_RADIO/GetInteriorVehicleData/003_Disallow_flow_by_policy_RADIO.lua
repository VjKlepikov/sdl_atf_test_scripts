---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/2
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/current_module_status_data.md
-- Use Case 1: Exceptions: 3.1
--
-- Requirement summary:
-- [SDL_RC] Current module status data GetInteriorVehicleData
-- [SDL_RC] Policy support of basic RC functionality
--
-- Description:
-- In case:
-- 1) "moduleType" in app's assigned policies has one or more valid values
-- 2) and SDL received GetInteriorVehicleData request from App with moduleType not in list
-- SDL must:
-- 1) Disallow app's remote-control RPCs for this module (success:false, "DISALLOWED")
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

--[[ Local Variables ]]
local mod = "RADIO"

--[[ Local Functions ]]
local function getDataForModule(pModuleType, self)
  local cid = self.mobileSession1:SendRPC("GetInteriorVehicleData", {
    moduleType = pModuleType
  })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {})
  :Times(0)

  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "DISALLOWED" })

  commonTestCases:DelayedExp(commonRC.timeout)
end

local function ptu_update_func(tbl)
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].moduleType = { "CLIMATE" }
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu, { ptu_update_func })
runner.Step("Activate App", commonRC.activate_app)

runner.Title("Test")
runner.Step("GetInteriorVehicleData " .. mod, getDataForModule, { mod })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
