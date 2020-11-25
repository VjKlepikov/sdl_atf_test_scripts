---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/CustomSDL/Sync3.2v2/issues/461
-- Description:
-- SDL does not send VR.AddCommand to HMI in case of non-response VR.DeleteCommand from HMI

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. App is registered and activated on SDL
-- c. App is currently in Background, Full or Limited HMI level
-- d. App requests AddCommand with the both vrCommands and menuParams

-- Steps:
-- App requests DeleteCommand with the both vrCommands and menuParams
-- SDL sends to HMI UI.DeleteCommad and VR.DeleteCommad with one and the same <cmdID.> to HMI
-- HMI sends response for UI.DeleteCommad and does not send response VR.DeleteCommad to SDL during SDL's default timeout

-- Expected:
-- SDL sends UI.AddCommand for the successfully added cmdID to HMI
-- SDL responds with 'GENERIC_ERROR, success:false' to mobile application.

-- Steps:
-- App requests DeleteCommand with the both vrCommands and menuParams
-- SDL sends to HMI UI.DeleteCommad and VR.DeleteCommad with one and the same <cmdID.> to HMI
-- HMI sends response for VR.DeleteCommad and does not send response UI.DeleteCommad to SDL during SDL's default timeout

-- Expected:
-- SDL sends VR.AddCommand for the successfully added cmdID to HMI
-- SDL responds with 'GENERIC_ERROR, success:false' to mobile application.
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSmoke = require('test_scripts/Smoke/commonSmoke')

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
  },
  grammarID = 1
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
local function addCommand(params, self)
  local cid = self.mobileSession1:SendRPC("AddCommand", params.requestParams)

  params.responseUiParams.appID = commonSmoke.getHMIAppId()
  EXPECT_HMICALL("UI.AddCommand", params.responseUiParams)
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  params.responseVrParams.appID = commonSmoke.getHMIAppId()
  EXPECT_HMICALL("VR.AddCommand", params.responseVrParams)
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
  self.mobileSession1:ExpectNotification("OnHashChange")
end

local function deleteVRCommand(paramsVr, self)
  local cid = self.mobileSession1:SendRPC("DeleteCommand", paramsVr)

  paramsVr.appID = commonSmoke.getHMIAppId()
  EXPECT_HMICALL("UI.DeleteCommand", paramsVr)
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  local responseVrParams = {
    cmdID = paramsVr.cmdID
  }
  EXPECT_HMICALL("VR.DeleteCommand", responseVrParams)
  :Do(function(_,data)
    -- HMI does not respond
  end)

  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR"})

  EXPECT_HMICALL("UI.AddCommand", paramsVr.responseUiParams)
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
end

local function deleteUICommand(paramsUI, self)
  local cid = self.mobileSession1:SendRPC("DeleteCommand", paramsUI)

  paramsUI.appID = commonSmoke.getHMIAppId()
  EXPECT_HMICALL("UI.DeleteCommand", paramsUI)
  :Do(function(_,data)
    -- HMI does not respond
  end)

  local responseVrParams = {
    cmdID = paramsUI.cmdID
  }
  EXPECT_HMICALL("VR.DeleteCommand", responseVrParams)
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR"})

  EXPECT_HMICALL("VR.AddCommand", paramsUI.responseVrParams)
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSmoke.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSmoke.start)
runner.Step("RAI", commonSmoke.registerApp)
runner.Step("Activate App", commonSmoke.activateApp)
runner.Step("AddCommand", addCommand, {addCommandAllParams})

runner.Title("Test")
runner.Step("HMI does not response VR.DeleteCommand", deleteVRCommand, { deleteVR } )
runner.Step("HMI does not response UI.DeleteCommand", deleteUICommand, { deleteUI })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
