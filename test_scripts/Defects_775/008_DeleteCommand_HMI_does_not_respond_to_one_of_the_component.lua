---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/CustomSDL/Sync3.2v2/issues/775
-- Description:
-- SDL sends VR.AddCommand to HMI in case of non-response for VR.DeleteCommand from HMI
--
-- Pre-conditions:
-- a. HMI and SDL are started
-- b. App is registered and activated on SDL
-- c. App is currently in Background, Full or Limited HMI level
-- d. AddCommand is added with the both vrCommands and menuParams
--
-- Steps:
-- App requests DeleteCommand with the both vrCommands and menuParams
-- SDL sends to HMI UI.DeleteCommad and VR.DeleteCommad to HMI
-- HMI sends response for UI.DeleteCommad and does not send response VR.DeleteCommad to SDL during SDL's default timeout
--
-- Expected:
-- SDL sends UI.AddCommand for the successfully added cmdID to HMI
-- SDL responds with 'GENERIC_ERROR, success:false' to mobile application.
--
-- Steps:
-- App requests DeleteCommand with the both vrCommands and menuParams
-- SDL sends to HMI UI.DeleteCommad and VR.DeleteCommad to HMI
-- HMI sends response for VR.DeleteCommad and does not send response UI.DeleteCommad to SDL during SDL's default timeout
--
-- Expected:
-- SDL sends VR.AddCommand for the successfully added cmdID to HMI
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
    menuName ="Commandpositive"
  },
  vrCommands = {
    "VRCommandone",
    "VRCommandtwo"
  }
}

local responseUiParams = {
  cmdID = requestParams.cmdID,
  menuParams = requestParams.menuParams
}

local responseVrParams = {
  cmdID = requestParams.cmdID,
  type = "Command",
  vrCommands = requestParams.vrCommands
}

local addCommandAllParams = {
  requestParams = requestParams,
  responseUiParams = responseUiParams,
  responseVrParams = responseVrParams
}

local deleteVR = {
  cmdID = requestParams.cmdID,
}

local deleteUI = {
  cmdID = requestParams.cmdID
}

--[[ Local Functions ]]
local function addCommand(params)
  local cid = common.getMobileSession():SendRPC("AddCommand", params.requestParams)

  params.responseUiParams.appID = common.getHMIAppId()
  common.getHMIConnection():ExpectRequest("UI.AddCommand", params.responseUiParams)
  :Do(function(_,data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  params.responseVrParams.appID = common.getHMIAppId()
  common.getHMIConnection():ExpectRequest("VR.AddCommand", params.responseVrParams)
  :Do(function(_,data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
  common.getMobileSession():ExpectNotification("OnHashChange")
end

local function deleteVRCommand(paramsVr)
  local cid = common.getMobileSession():SendRPC("DeleteCommand", paramsVr)

  paramsVr.appID = common.getHMIAppId()
  common.getHMIConnection():ExpectRequest("UI.DeleteCommand", paramsVr)
  :Do(function(_,data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  local responseVrParams = {
    cmdID = paramsVr.cmdID
  }
  common.getHMIConnection():ExpectRequest("VR.DeleteCommand", responseVrParams)
  :Do(function(_,data)
    -- HMI does not respond
  end)

  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR"})

  common.getHMIConnection():ExpectRequest("UI.AddCommand", paramsVr.responseUiParams)
  :Do(function(_,data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
end

local function deleteUICommand(paramsUI)
  local cid = common.getMobileSession():SendRPC("DeleteCommand", paramsUI)

  paramsUI.appID = common.getHMIAppId()
  common.getHMIConnection():ExpectRequest("UI.DeleteCommand", paramsUI)
  :Do(function(_,data)
    -- HMI does not respond
  end)

  local responseVrParams = {
    cmdID = paramsUI.cmdID
  }
  common.getHMIConnection():ExpectRequest("VR.DeleteCommand", responseVrParams)
  :Do(function(_,data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR"})

  common.getHMIConnection():ExpectRequest("VR.AddCommand", paramsUI.responseVrParams)
  :Do(function(_,data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.startWait)
runner.Step("RAI", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("AddCommand", addCommand, { addCommandAllParams })

runner.Title("Test")
runner.Step("HMI does not response VR.DeleteCommand", deleteVRCommand, { deleteVR } )
runner.Step("HMI does not response UI.DeleteCommand", deleteUICommand, { deleteUI })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
