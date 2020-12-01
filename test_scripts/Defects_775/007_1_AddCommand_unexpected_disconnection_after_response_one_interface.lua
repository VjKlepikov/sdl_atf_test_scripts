---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/CustomSDL/Sync3.2v2/issues/775
--
-- Description:
-- Successfully processing unexpected disconnect after UI.AddCommad response from HMI
--
-- Pre-conditions:
-- a. HMI and SDL are started
-- b. App is registered and activated on SDL
--
-- Steps:
-- App requests AddCommand with menuParams
-- SDL sends to HMI UI.AddCommad to HMI
-- HMI sends response for UI.AddCommad to SDL during SDL's default timeout
-- Unexpected disconnect after UI.AddCommad response from HMI
-- SDL sends BasicCommunication.OnAppUnregistered notification to HMI
--
-- Expected:
-- SDL does not send DeleteCommand for the successfully added cmdID to HMI
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
local function unexpectedDisconnect_UI_Addcommand(params, pRunAfterTime)
  local cid = common.getMobileSession():SendRPC("AddCommand", params)

  common.getHMIConnection():ExpectRequest("UI.AddCommand", responseUiParams)
  :Do(function(_,data)
    -- unexpected Disconnect after response
    RUN_AFTER(common.unexpectedDisconnect, pRunAfterTime)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  common.getHMIConnection():ExpectRequest("UI.DeleteCommand")
  :Times(0)
 common.wait(5000)
end


--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.startWait)
runner.Step("RAI", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
for i = 1, 50, 20 do
  runner.Step("Unexpected disconnect in " .. i .. "msec after response UI.AddCommand",
    unexpectedDisconnect_UI_Addcommand, { requestParams, i })
  runner.Step("Connect mobile", common.connectMobile)
  runner.Step("App registration after disconnect", common.registerApp)
  runner.Step("Activate App", common.activateApp)
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
