---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/2129
---------------------------------------------------------------------------------------------------
-- Description:
-- In case:
-- 1) Mobile app is audio source ('audioStreamingState' = AUDIBLE)
-- 2) And TTS is started
-- SDL must:
-- 1) Send OnHMIStatus notification with 'audioStreamingState' = ATTENUATED
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/MobileProjection/Phase2/common')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local testCases = {
  [108] = { t = "PROJECTION",    m = true }
}

--[[ Local Functions ]]
local function sendSpeak(pTC)
  local request = {
    ttsChunks = {
      { text ="Text1", type ="TEXT" }
    }
  }
  local cid = common.getMobileSession():SendRPC("Speak", request)
  common.getHMIConnection():ExpectRequest("TTS.Speak")
  :Do(function(_, data)
      common.getHMIConnection():SendNotification("TTS.Started")
      local function speakResponse()
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
        common.getHMIConnection():SendNotification("TTS.Stopped")
      end
      RUN_AFTER(speakResponse, 1000)
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })

  common.getMobileSession():ExpectNotification("OnHMIStatus")
  :ValidIf(function(e, data)
      if e.occurences == 1 then
        return common.checkAudioSS(pTC, "App1", "ATTENUATED", data.payload.audioStreamingState)
      else
        return common.checkAudioSS(pTC, "App1", "AUDIBLE", data.payload.audioStreamingState)
      end
    end)
  :Times(2)
end

--[[ Scenario ]]
for n, tc in common.spairs(testCases) do
  runner.Title("TC[" .. string.format("%03d", n) .. "]: "
    .. "[hmiType:" .. tc.t .. ", isMedia:" .. tostring(tc.m) .. "]")
  runner.Step("Clean environment", common.preconditions)
  runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  runner.Step("Set App Config", common.setAppConfig, { 1, tc.t, tc.m })
  runner.Step("Register App", common.registerApp)
  runner.Step("Activate App", common.activateApp)
  runner.Step("Send Speak, audioState:ATTENUATED", sendSpeak, { n })
  runner.Step("Clean sessions", common.cleanSessions)
  runner.Step("Stop SDL", common.postconditions)
end
runner.Step("Print failed TCs", common.printFailedTCs)
