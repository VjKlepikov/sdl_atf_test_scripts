---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/CustomSDL/Sync3.2v2/issues/775
--
-- Description:
-- Successfully processing unexpected disconnect after VR.AddCommad(UI.AddCommad) response from HMI
--
-- Pre-conditions:
-- a. HMI and SDL are started
-- b. App is registered and activated on SDL
--
-- Steps:
-- App requests AddCommand with the both vrCommands and menuParams
-- SDL sends to HMI UI.AddCommad and VR.AdddCommand to HMI
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
local runAfterTime = 1

local requestParams = {
  cmdID = 11,
  menuParams = {
    position = 0,
    menuName ="Command1"
  },
  vrCommands = {
    "VRCommandone",
    "VRCommandtwo"
  }
}

local responseUiParams = {
  cmdID = requestParams.cmdID
}

local responseVrParams = {
  cmdID = requestParams.cmdID,
  type = "Command",
  vrCommands = requestParams.vrCommands
}

--[[ Local Functions ]]
local function unexpectedDisconnect_VR_Addcommand(params, pRunAfterTime)
  local cid = common.getMobileSession():SendRPC("AddCommand", params)

  common.getHMIConnection():ExpectRequest("UI.AddCommand", responseUiParams)
  :Do(function(_,data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  common.getHMIConnection():ExpectRequest("VR.AddCommand", responseVrParams)
  :Do(function(_,data)
    -- unexpected Disconnect after response
    RUN_AFTER(common.unexpectedDisconnect, pRunAfterTime)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  common.getHMIConnection():ExpectRequest("UI.DeleteCommand")
  :Times(0)
  common.getHMIConnection():ExpectRequest("VR.DeleteCommand")
  :Times(0)
end

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
  common.getHMIConnection():ExpectRequest("VR.DeleteCommand")
  :Times(0)

end


--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("Activate App", common.activateApp)

for i = 1, 50, 1 do
  runner.Title("Test " .. i)
  runner.Step("Unexpected disconnect in 1 msec after response VR.AddCommand",
    unexpectedDisconnect_VR_Addcommand, { requestParams, runAfterTime })
  runner.Step("Connect mobile", common.connectMobile)
  runner.Step("App registration after disconnect", common.registerApp)
  runner.Step("Activate App", common.activateApp)
  runner.Step("Unexpected disconnect in 1 msec after response UI.AddCommand",
    unexpectedDisconnect_UI_Addcommand, { requestParams, runAfterTime })
  runner.Step("Connect mobile", common.connectMobile)
  runner.Step("App registration after disconnect", common.registerApp)
  runner.Step("Activate App", common.activateApp)
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
