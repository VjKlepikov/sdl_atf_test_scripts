---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/CustomSDL/Sync3.2v2/issues/775
--
-- Description:
-- Successfully processing unexpected disconnect before VR.AddCommad(UI.AddCommad) response from HMI
--
-- Pre-conditions:
-- a. HMI and SDL are started
-- b. App is registered and activated on SDL
--
-- Steps:
-- App requests AddCommand with the both vrCommands and menuParams
-- SDL sends to HMI UI.AddCommad and VR.AdddCommand to HMI
-- HMI sends response for UI.AddCommad to SDL during SDL's default timeout
-- Unexpected disconnect before VR.AddCommad response from HMI
-- SDL sends BasicCommunication.OnAppUnregistered notification to HMI
-- HMI sends response for VR.AddCommad to SDL
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
  },
  vrCommands = {
    "VRCommandone",
    "VRCommandtwo"
  },
  grammarID = 1
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
local function withoutRespond_VR_Addcommand(params)
  local cid = common.getMobileSession():SendRPC("AddCommand", params)

  common.getHMIConnection():ExpectRequest("UI.AddCommand", responseUiParams)
  :Do(function(_,data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  common.getHMIConnection():ExpectRequest("VR.AddCommand", responseVrParams)
  :Do(function(_,data)
    -- unexpected Disconnect before response
    local function sendResponse()
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end
    common.unexpectedDisconnect(sendResponse)
  end)

  common.getHMIConnection():ExpectRequest("UI.DeleteCommand")
  :Times(0)
  common.getHMIConnection():ExpectRequest("VR.DeleteCommand")
  :Times(0)
end

local function withoutRespond_UI_Addcommand()
  local cid = common.getMobileSession():SendRPC("AddCommand", requestParams)

  common.getHMIConnection():ExpectRequest("UI.AddCommand", responseUiParams)
  :Do(function(_,data)
    -- unexpected Disconnect before response
    local function sendResponse()
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end
    common.unexpectedDisconnect(sendResponse)

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

runner.Title("Test")
runner.Step("HMI does not response VR.AddCommand", withoutRespond_VR_Addcommand, { requestParams })
runner.Step("Connect mobile", common.connectMobile)
runner.Step("App registration after disconnect", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Step("HMI does not response UI.AddCommand", withoutRespond_UI_Addcommand, { requestParams })
runner.Step("Connect mobile", common.connectMobile)
runner.Step("App registration after disconnect", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
