---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: EndAudioPassThru
-- Item: Happy path
--
-- Requirement summary:
-- [EndAudioPassThru] SUCCESS: getting SUCCESS:UI.EndAudioPassThru()
--
-- Description:
-- Mobile application sends valid EndAudioPassThru request and gets UI.EndAudioPassThru "SUCCESS"
-- response from HMI

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level

-- Steps:
-- appID requests EndAudioPassThru with valid parameters

-- Expected:
-- SDL validates parameters of the request
-- SDL checks if UI interface is available on HMI
-- SDL checks if EndAudioPassThru is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL transfers the UI part of request with allowed parameters to HMI
-- SDL receives UI part of response from HMI with "SUCCESS" result code
-- SDL responds with (resultCode: SUCCESS, success:true) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSmoke = require('test_scripts/Smoke/commonSmoke')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--[[ Local Variables ]]
local requestParams = {
  audioPassThruDisplayText1 = "DisplayText1",
  audioPassThruDisplayText2 = "DisplayText2",
  samplingRate = "8KHZ",
  maxDuration = 2000,
  bitsPerSample = "8_BIT",
  audioType = "PCM",
  muteAudio = true
}

local requestUiParams = {
  audioPassThruDisplayTexts = { },
  maxDuration = requestParams.maxDuration,
  muteAudio = requestParams.muteAudio
}

requestUiParams.audioPassThruDisplayTexts[1] = {
  fieldName = "audioPassThruDisplayText1",
  fieldText = requestParams.audioPassThruDisplayText1
}

requestUiParams.audioPassThruDisplayTexts[2] = {
  fieldName = "audioPassThruDisplayText2",
  fieldText = requestParams.audioPassThruDisplayText2
}

local allParams = {
  requestParams = requestParams,
  requestUiParams = requestUiParams,
}

--[[ Local Functions ]]
local function file_check(file_name)
  local file_found = io.open(file_name, "r")
  if nil == file_found then
    return false
  end
  return true
end

local function sendOnSystemContext(self, pCtx, pAppID)
  self.hmiConnection:SendNotification("UI.OnSystemContext",
    { appID = pAppID, systemContext = pCtx })
end

local function EndAudioPassThru(pParams, self)
  local uiPerformID
  local AudibleState = commonSmoke.GetAudibleState()
  local cid = self.mobileSession1:SendRPC("PerformAudioPassThru", pParams.requestParams)
  pParams.requestUiParams.appID = commonSmoke.getHMIAppId()
  EXPECT_HMICALL("UI.PerformAudioPassThru", pParams.requestUiParams)
  :Do(function(_,data)
    sendOnSystemContext(self, "HMI_OBSCURED", pParams.requestUiParams.appID)
    uiPerformID = data.id
  end)
  EXPECT_HMINOTIFICATION("UI.OnRecordStart", { appID = pParams.requestUiParams.appID })
  self.mobileSession1:ExpectNotification("OnAudioPassThru")
  :Do(function()
    local cidEndAudioPassThru = self.mobileSession1:SendRPC("EndAudioPassThru", { })
    EXPECT_HMICALL("UI.EndAudioPassThru")
    :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
      self.hmiConnection:SendResponse(uiPerformID, "UI.PerformAudioPassThru", "SUCCESS", { })
      sendOnSystemContext(self, "MAIN", pParams.requestUiParams.appID)
    end)
    self.mobileSession1:ExpectResponse(cidEndAudioPassThru, { success = true, resultCode = "SUCCESS" })
  end)
  self.mobileSession1:ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", audioStreamingState = AudibleState, systemContext = "HMI_OBSCURED" },
    { hmiLevel = "FULL", audioStreamingState = AudibleState, systemContext = "MAIN" })
  :Times(2)
  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :ValidIf (function()
    local file = commonPreconditions:GetPathToSDL() .. "storage/" .. "audio.wav"
    if true ~= file_check(file) then
      return false, "Can not found file: audio.wav"
    end
    return true
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSmoke.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSmoke.start)
runner.Step("RAI", commonSmoke.registerApp)
runner.Step("Activate App", commonSmoke.activateApp)

runner.Title("Test")
runner.Step("EndAudioPassThru Positive Case", EndAudioPassThru, { allParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
