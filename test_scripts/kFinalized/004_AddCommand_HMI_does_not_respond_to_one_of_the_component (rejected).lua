---------------------------------------------------------------------------------------------------
-- Description:
-- SDL does not send UI.DeleteCommand to HMI in case of non-response VR.AdddCommand from HMI

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. App is registered and activated on SDL

-- Steps:
-- App requests AddCommand with the both vrCommands and menuParams
-- SDL sends to HMI UI.AddCommad and VR.AdddCommand with one and the same <cmdID.> to HMI
-- HMI sends response for UI.AddCommad and does not send response VR.AdddCommand to SDL during SDL's default timeout

-- Expected:
-- SDL sends UI.DeleteCommand for the successfully added cmdID to HMI
-- SDL responds with 'GENERIC_ERROR, success:false' to mobile application.

-- Steps:
-- App requests AddCommand with the both vrCommands and menuParams
-- SDL sends to HMI UI.AddCommad and VR.AdddCommand with one and the same <cmdID.> to HMI
-- HMI sends response for VR.AddCommad and does not send response UI.AdddCommand to SDL during SDL's default timeout

-- Expected:
-- SDL sends VR.DeleteCommand for the successfully added cmdID to HMI
-- SDL responds with 'GENERIC_ERROR, success:false' to mobile application.
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

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

local deleteUI_AddCommand = {
  requestParams = requestParams;
  deleteUIcommand = {
    cmdID = 11,
    appID = common.getHMIAppId()
  },
  info = "VR component does not respond"
}

local deleteVR_AddCommand = {
  requestParams = requestParams,
  deleteVRcommand = {
    appID = common.getHMIAppId(),
    cmdID = requestParams.cmdID,
    type = "Command",
  },
  info = "UI component does not respond"
}

--[[ Local Functions ]]
local function rejected_VR_Addcommand(params)
  local cid = common.getMobileSession():SendRPC("AddCommand", params.requestParams)

  common.getHMIConnection():ExpectRequest("UI.AddCommand", params.responseUiParams)
  :Do(function(_,data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  common.getHMIConnection():ExpectRequest("VR.AddCommand", params.responseVrParams)
  :Do(function(_,data)
    -- HMI rejected
    common.getHMIConnection():SendError(data.id, data.method, "REJECTED", "Error message.")
  end)

  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "REJECTED", info = "Error message." })

  common.getHMIConnection():ExpectRequest("UI.DeleteCommand", params.deleteUIcommand)
  :Do(function(_,data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
end

local function rejected_UI_Addcommand(params)
  local cid = common.getMobileSession():SendRPC("AddCommand", params.requestParams)

  common.getHMIConnection():ExpectRequest("UI.AddCommand", params.responseUiParams)
  :Do(function(_,data)
    -- HMI rejected
    common.getHMIConnection():SendError(data.id, data.method, "REJECTED", "Error message.")
  end)

  common.getHMIConnection():ExpectRequest("VR.AddCommand", params.responseVrParams)
  :Do(function(_,data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "REJECTED", info = "Error message." })

  common.getMobileSession():ExpectResponse("VR.DeleteCommand", params.deleteVRcommand)
  :Do(function(_,data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
end

local function rejected_Both_Addcommand(params)
  local cid = common.getMobileSession():SendRPC("AddCommand", params.requestParams)

  common.getHMIConnection():ExpectRequest("UI.AddCommand", params.responseUiParams)
  :Do(function(_,data)
    -- HMI rejected
    common.getHMIConnection():SendError(data.id, data.method, "REJECTED", "Error message.")
  end)

  common.getHMIConnection():ExpectRequest("VR.AddCommand", params.responseVrParams)
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
runner.Step("HMI does not response VR.AddCommand", rejected_VR_Addcommand, { deleteUI_AddCommand })
runner.Step("HMI does not response UI.AddCommand", rejected_UI_Addcommand, { deleteVR_AddCommand })
runner.Step("HMI does not response BOTH.AddCommand", rejected_Both_Addcommand)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
