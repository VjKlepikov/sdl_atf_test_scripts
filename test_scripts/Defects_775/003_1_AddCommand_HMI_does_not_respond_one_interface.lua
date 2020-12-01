---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/CustomSDL/Sync3.2v2/issues/775
--
-- Description:
-- [AddCommand] GENERIC_ERROR: SDL responds with 'GENERIC_ERROR, success:false' to mobile application
-- in case HMI does not send response for UI.AddCommad to SDL during SDL's default timeout
--
-- Pre-conditions:
-- a. HMI and SDL are started
-- b. App is registered and activated on SDL
--
-- Steps:
-- App requests AddCommand UI.AdddCommand and menuParams
-- SDL sends to HMI UI.AddCommad to HMI
-- HMI does not send response UI.AdddCommand to SDL during SDL's default timeout
--
-- Expected:
-- SDL does not send DeleteCommand for the successfully added cmdID to HMI
-- SDL responds with 'GENERIC_ERROR, success:false' to mobile application.
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
local function withoutResponse_UI_and_VR_Addcommand(params)
  local cid = common.getMobileSession():SendRPC("AddCommand", params)

  common.getHMIConnection():ExpectRequest("UI.AddCommand", responseUiParams)
  :Do(function(_,data)
    -- HMI does not respond
  end)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR", info = params.info})
  common.getHMIConnection():ExpectRequest("UI.DeleteCommand")
  :Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.startWait)
runner.Step("RAI", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("HMI does not response UI.AddCommand and VR.AddCommand",
  withoutResponse_UI_and_VR_Addcommand, { requestParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
