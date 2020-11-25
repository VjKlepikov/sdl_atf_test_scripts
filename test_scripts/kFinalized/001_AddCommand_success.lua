---------------------------------------------------------------------------------------------------
-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/1878
--
-- Description:
-- SDL does not restore AddCommands in the same order as they were created by mobile app
--
-- Steps:
-- 1) App is registered and activated.
-- 2) App successfully added some AddCommands

-- Expected result:
-- 1) SDL must generate <internal_consecutiveNumber>
-- and assign this <internal_consecutiveNumber> to each AddCommand requested by app
-- 2) Restore AddCommand by this <internal_consecutiveNumber> during data resumption
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local addCommandParam = {
  {
    cmdID = 1,
    menuParams = {
      position = 0,
      menuName ="Command1"
    },
    vrCommands = {
      "VRCommand1"
    }
  }
}

--[[ Local Functions ]]
local function addCommand(pParams)
  local cid = common.getMobileSession():SendRPC("AddCommand", pParams)
  common.getHMIConnection():ExpectRequest("UI.AddCommand")
  :Do(function(_,data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getHMIConnection():ExpectRequest("VR.AddCommand")
  :Do(function(_,data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("AddCommand success", addCommand, { addCommandParam })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
