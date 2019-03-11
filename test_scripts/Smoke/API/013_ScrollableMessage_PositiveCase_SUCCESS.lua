---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: ScrollableMessage
-- Item: Happy path
--
-- Requirement summary:
-- [AddCommand] SUCCESS: getting SUCCESS on UI.ScrollableMessage()
--
-- Description:
-- Mobile application sends valid ScrollableMessage request

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level

-- Steps:
-- appID requests ScrollableMessage with valid values of parameters

-- Expected:
-- SDL validates parameters of the request
-- SDL checks if UI interface is available on HMI
-- SDL checks if ScrollableMessage is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL transfers the UI request with allowed parameters to HMI
-- SDL receives UI response from HMI with "SUCCESS" result code
-- SDL responds with (resultCode: SUCCESS, success:true) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSmoke = require('test_scripts/Smoke/commonSmoke')

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

local requestParams = {
  scrollableMessageBody = "abc",
  softButtons = {
    {
      softButtonID = 1,
      text = "Button1",
      type = "BOTH",
      image = {
        value = "icon.png",
        imageType = "DYNAMIC"
      },
      isHighlighted = false,
      systemAction = "DEFAULT_ACTION"
      },
    {
      softButtonID = 2,
      text = "Button2",
      type = "TEXT",
      isHighlighted = false,
      systemAction = "DEFAULT_ACTION"
    }
  },
  timeout = 5000
}

local responseUiParams = {
  messageText = {
    fieldName = "scrollableMessageBody",
    fieldText = requestParams.scrollableMessageBody
  },
  softButtons = requestParams.softButtons
}

local allParams = {
  requestParams = requestParams,
  responseUiParams = responseUiParams,
}

--[[ Local Functions ]]
local function ScrollableMessage(params, self)
  local cid = self.mobileSession1:SendRPC("ScrollableMessage", params.requestParams)
  params.responseUiParams.appID = commonSmoke.getHMIAppId()
  for _, v in pairs(params.responseUiParams.softButtons) do
    if v.image then
      v.image.value = commonSmoke.getPathToFileInStorage("icon.png")
    end
  end
  EXPECT_HMICALL("UI.ScrollableMessage", params.responseUiParams)
  :Do(function(_,data)
	self.hmiConnection:SendNotification("UI.OnSystemContext",
	  { appID = params.responseUiParams.appID, systemContext = "HMI_OBSCURED" })
	local function uiResponse()
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      self.hmiConnection:SendNotification("UI.OnSystemContext",
        { appID = params.responseUiParams.appID, systemContext = "MAIN" })
    end
    RUN_AFTER(uiResponse, 1000)
  end)
  local AudibleState = commonSmoke.GetAudibleState()
  self.mobileSession1:ExpectNotification("OnHMIStatus",
    { systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = AudibleState },
    { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = AudibleState })
  :Times(2)
  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSmoke.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSmoke.start)
runner.Step("RAI", commonSmoke.registerApp)
runner.Step("Activate App", commonSmoke.activateApp)
runner.Step("Upload icon file", commonSmoke.putFile, {putFileParams})

runner.Title("Test")
runner.Step("ScrollableMessage Positive Case", ScrollableMessage, {allParams})

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
