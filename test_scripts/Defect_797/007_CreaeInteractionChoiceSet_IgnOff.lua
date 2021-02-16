---------------------------------------------------------------------------------------------------
-- Requirement summary:
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defect_797/commonDefects')

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

local createRequestParams = {
	interactionChoiceSetID = 1001,
	choiceSet = {
		{
			choiceID = 1001,
			menuName ="Choice1001",
			vrCommands = {
				"Choice1001"
			}
		},
		{
			choiceID = 1002,
			menuName ="Choice1002",
			vrCommands = {
				"Choice1002"
			}
		}
	}
}

local createResponseVrParams = {
	cmdID = createRequestParams.interactionChoiceSetID,
	type = "Choice",
	vrCommands = createRequestParams.vrCommands
}

local createAllParams = {
	requestParams = createRequestParams,
	responseVrParams = createResponseVrParams
}

local deleteRequestParams = {
	interactionChoiceSetID = createRequestParams.interactionChoiceSetID
}

local deleteResponseVrParams = {
	cmdID = createRequestParams.interactionChoiceSetID,
	type = "Choice"
}

local deleteAllParams = {
	requestParams = deleteRequestParams,
	responseVrParams = deleteResponseVrParams
}

--[[ Local Functions ]]
local function createInteractionChoiceSet(params, pApp)
	local cid = common.getMobileSession(pApp):SendRPC("CreateInteractionChoiceSet", params.requestParams)

	params.responseVrParams.appID = common.getHMIAppId(pApp)
	common.getHMIConnection():ExpectRequest("VR.AddCommand")
	:ValidIf(function(_,data)
		if data.params.grammarID ~= nil then
			deleteResponseVrParams.grammarID = data.params.grammarID
			return true
		else
			return false, "grammarID should not be empty"
		end
	end)
	:Do(function(_,data)
		common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	:Times(2)

	common.getMobileSession(pApp):ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
	common.getMobileSession(pApp):ExpectNotification("OnHashChange")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("CreateInteractionChoiceSet", createInteractionChoiceSet, { createAllParams })
runner.Step("RAI App2", common.registerApp, { 2 })
runner.Step("Activate App", common.activateApp, { 2 })
runner.Step("CreateInteractionChoiceSet App2", createInteractionChoiceSet, { createAllParams, 2 })
runner.Step("RAI App2", common.registerApp, { 3 })

runner.Title("Test")
runner.Step("Ignition Off", common.ignitionOff)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration after ign off", common.registerApp)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)

