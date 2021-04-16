---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
-- Description:
-- Successfully processing unexpected disconnect during Alert request from mobile App
--
-- Pre-conditions:
-- 1. HMI and SDL are started
-- 2. App is registered and activated on SDL
--
-- Steps:
-- App requests Alert with UI-related-params & with TTSChunks
-- Unexpected disconnect during Alert request from mobile App
--
-- Expected:
-- SDL sends BasicCommunication.OnAppUnregistered to App
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonDefect = require('test_scripts/Defect_Alert/commonDefects')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local putFileParams = {
	requestParams = {
	    syncFileName = 'icon.png',
	    fileType = "GRAPHIC_PNG",
	    persistentFile = false,
	    systemFile = false
	},
	filePath = "files/icon.png"
}

local step2SpecificParams = {
	duration = 5000
}

local requestParams = {
	alertText1 = "alertText1",
	alertText2 = "alertText2",
	alertText3 = "alertText3",
	ttsChunks = {
		{
			text = "TTSChunk",
			type = "TEXT",
		}
	},
	playTone = true,
	progressIndicator = true
}

local responseUiParams = {
	alertStrings = {
		{
			fieldName = requestParams.alertText1,
			fieldText = requestParams.alertText1
		},
		{
			fieldName = requestParams.alertText2,
			fieldText = requestParams.alertText2
		},
		{
			fieldName = requestParams.alertText3,
			fieldText = requestParams.alertText3
		}
	},
	alertType = "BOTH",
	progressIndicator = requestParams.progressIndicator,
}

local ttsSpeakRequestParams = {
	ttsChunks = requestParams.ttsChunks,
	speakType = "ALERT",
	playTone = requestParams.playTone
}

local allParams = {
	requestParams = requestParams,
	responseUiParams = responseUiParams,
	ttsSpeakRequestParams = ttsSpeakRequestParams
}

--[[ Local Functions ]]
local function sendOnSystemContext(ctx)
	commonDefect.getHMIConnection():SendNotification("UI.OnSystemContext",
		{
			appID = commonDefect.getHMIAppId(),
			systemContext = ctx
		})
end

local function prepareAlertParams(params, additionalParams)
	params.responseUiParams.appID = commonDefect.getHMIAppId()

	if additionalParams.softButtons ~= nil then
		params.requestParams.duration = nil
		params.requestParams.softButtons = additionalParams.softButtons
		params.responseUiParams.duration = nil;
		params.responseUiParams.softButtons = additionalParams.softButtons
		params.responseUiParams.softButtons[1].image.value =
			commonDefect.getPathToFileInStorage(putFileParams.requestParams.syncFileName)
		params.responseUiParams.softButtons[3].image.value =
			commonDefect.getPathToFileInStorage(putFileParams.requestParams.syncFileName)
	elseif additionalParams.duration ~= nil then
		params.requestParams.softButtons = nil
		params.requestParams.duration = additionalParams.duration
		params.responseUiParams.softButtons = nil
		params.responseUiParams.duration = additionalParams.duration
	end
end

local function unexpectedDisconnectAlert(params, additionalParams, pRunAfterTime)
	prepareAlertParams(params, additionalParams)

	local responseDelay = 50
		 -- unexpected Disconnect during Alert sequence
  RUN_AFTER(commonDefect.unexpectedDisconnect, pRunAfterTime)
	local cid = commonDefect.getMobileSession():SendRPC("Alert", params.requestParams)
	commonDefect.log("APP->SDL: RQ Alert")


	commonDefect.getHMIConnection():ExpectRequest("UI.Alert", params.responseUiParams)
	:Do(function(_,data)
    commonDefect.log("SDL->HMI: RQ UI.Alert")
		sendOnSystemContext("ALERT")

		local alertId = data.id
		local function alertResponse()
			commonDefect.getHMIConnection():SendResponse(alertId, "UI.Alert", "SUCCESS", { })
			commonDefect.log("HMI->SDL: RS UI.Alert")
			sendOnSystemContext("MAIN")
		end
		RUN_AFTER(alertResponse, responseDelay)
	end)
	:Times(AnyNumber())

	params.ttsSpeakRequestParams.appID = commonDefect.getHMIAppId()
	commonDefect.getHMIConnection():ExpectRequest("TTS.Speak", params.ttsSpeakRequestParams)
	:Do(function(_,data)
		commonDefect.log("SDL->HMI: RQ TTS.Speak")
		commonDefect.getHMIConnection():SendNotification("TTS.Started")
		commonDefect.log("HMI->SDL: N TTS.Started")

		local speakId = data.id
		local function speakResponse()
			commonDefect.getHMIConnection():SendResponse(speakId, "TTS.Speak", "SUCCESS", { })
			commonDefect.log("HMI->SDL: RS TTS.Speak")
			commonDefect.getHMIConnection():SendNotification("TTS.Stopped")
			commonDefect.log("HMI->SDL: N TTS.Stopped")
		end

		RUN_AFTER(speakResponse, responseDelay - 30)
	end)
	:ValidIf(function(_,data)
		if #data.params.ttsChunks == 1 then
			return true
		else
			return false, "ttsChunks array in TTS.Speak request has wrong element number." ..
			" Expected 1, actual " .. tostring(#data.params.ttsChunks)
		end
	end)
	:Times(AnyNumber())

	commonDefect.expectOnHMIStatusWithAudioStateChanged()

	commonDefect.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
	:Do(function(_,data)
		commonDefect.log("SDL->APP: RS Alert")
	end)
	:Times(AnyNumber())
	commonDefect.wait(100)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonDefect.preconditions)
runner.Step("Update preloaded", commonDefect.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonDefect.start)
runner.Step("RAI", commonDefect.registerApp)
runner.Step("Activate App", commonDefect.activateApp)
runner.Step("Upload icon file", commonDefect.putFile, { putFileParams })


for iter = 0, 40, 0.1 do
	runner.Title("Test_" .. iter)
	runner.Step("Unexpected disconnect during Alert request", unexpectedDisconnectAlert,
		{ allParams, step2SpecificParams, iter })
	runner.Step("Connect mobile", commonDefect.connectMobile)
	runner.Step("App registration after disconnect", commonDefect.registerApp)
	runner.Step("Activate App", commonDefect.activateApp)
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonDefect.postconditions)
