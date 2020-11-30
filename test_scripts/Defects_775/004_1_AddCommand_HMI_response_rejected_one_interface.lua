---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/CustomSDL/Sync3.2v2/issues/775
--
-- Description:
-- [AddCommand] REJECTED: SDL responds with 'REJECTED, success:false' to mobile application
-- in case HMI sends REJECTED for UI.AddCommad to SDL during SDL's default timeout
--
-- Pre-conditions:
-- a. HMI and SDL are started
-- b. App is registered and activated on SDL
--
-- Steps:
-- App requests AddCommand with UI.AddCommad and menuParams
-- SDL sends to HMI UI.AddCommad to HMI
-- HMI sends REJECTED response for UI.AdddCommand to SDL during SDL's default timeout
--
-- Expected:
-- SDL does not send DeleteCommand for the successfully added cmdID to HMI
-- SDL responds with 'REJECTED, success:false' to mobile application.
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects_775/commonDefects')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParams = {
  cmdID = 11,
  menuParams = {
    position = 0,
    menuName ="Command1"
  }
}

local responseUiParams = {
  cmdID = requestParams.cmdID
}

--[[ Local Functions ]]
local function rejected_Addcommand()
  local cid = common.getMobileSession():SendRPC("AddCommand", requestParams)

  common.getHMIConnection():ExpectRequest("UI.AddCommand", responseUiParams)
  :Do(function(_,data)
    -- HMI rejected
    common.getHMIConnection():SendError(data.id, data.method, "REJECTED", "Error message.")
  end)

  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "REJECTED", info = "Error message." })

  common.getHMIConnection():ExpectRequest("UI.DeleteCommand")
  :Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("HMI sends UI.AddCommand with REJECTED ", rejected_Addcommand)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
