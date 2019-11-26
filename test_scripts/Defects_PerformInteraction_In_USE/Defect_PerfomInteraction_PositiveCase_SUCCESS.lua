---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: DeleteInteractionChoiceSet
-- Item: Happy path
--
-- Requirement summary:
-- [DeleteInteractionChoiceSet] SUCCESS choiceSet removal
--
-- Description:
-- Mobile application sends valid DeleteInteractionChoiceSet request to SDL
-- and interactionChoiceSet with <interactionChoiceSetID> was successfully
-- removed on SDL and HMI for the application.

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level
-- d. Choice set with <interactionChoiceSetID> is created

-- Steps:
-- appID requests DeleteInteractionChoiceSet request with valid parameters

-- Expected:
-- SDL validates parameters of the request
-- SDL checks if VR interface is available on HMI
-- SDL checks if DeleteInteractionChoiceSet is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL transfers the VR.DeleteCommand with allowed parameters to HMI
-- SDL receives successful responses to corresponding VR.DeleteCommand from HMI
-- SDL responds with (resultCode: SUCCESS, success:true) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSmoke = require('test_scripts/Smoke/commonSmoke')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local utils = require('user_modules/utils')

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
      },
      image = {
        value ="icon.png",
        imageType ="DYNAMIC"
      }
    }
  }
}

local storagePath = commonPreconditions:GetPathToSDL() .. "storage/" ..
config.application1.registerAppInterfaceParams.appID .. "_" .. commonSmoke.getDeviceMAC() .. "/"


local ImageValue = {
  value = "icon.png",
  imageType = "DYNAMIC",
}

local function PromptValue(text)
  local tmp = {
    {
      text = text,
      type = "TEXT"
    }
  }
  return tmp
end

local initialPromptValue = PromptValue(" Make your choice ")

local helpPromptValue = PromptValue(" Help Prompt ")

local timeoutPromptValue = PromptValue(" Time out ")

local vrHelpvalue = {
  {
    text = " New VRHelp ",
    position = 1,
    image = ImageValue
  }
}

local requestParams_noVR = {
  initialText = "StartPerformInteraction",
  initialPrompt = initialPromptValue,
  interactionMode = "BOTH",
  interactionChoiceSetIDList = {
    1001
  },
  helpPrompt = helpPromptValue,
  timeoutPrompt = timeoutPromptValue,
  timeout = 5000,
  vrHelp = vrHelpvalue,
  interactionLayout = "ICON_ONLY"
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
local function createInteractionChoiceSet(params, self)
  local cid = self.mobileSession1:SendRPC("CreateInteractionChoiceSet", params.requestParams)

  params.responseVrParams.appID = commonSmoke.getHMIAppId()
  EXPECT_HMICALL("VR.AddCommand", params.responseVrParams)
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  :ValidIf(function(_,data)
    if data.params.grammarID ~= nil then
      deleteResponseVrParams.grammarID = data.params.grammarID
      return true
    else
      return false, "grammarID should not be empty"
    end
  end)

  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
  self.mobileSession1:ExpectNotification("OnHashChange")
end

local function deleteInteractionChoiceSet(params, self)
  local cid = self.mobileSession1:SendRPC("DeleteInteractionChoiceSet", params.requestParams)

  params.responseVrParams.appID = commonSmoke.getHMIAppId()
  EXPECT_HMICALL("VR.DeleteCommand", params.responseVrParams)
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
  self.mobileSession1:ExpectNotification("OnHashChange")
end

--[[ Local Functions ]]
local function unregisterAppInterface(self)
  local cid = self.mobileSession1:SendRPC("UnregisterAppInterface", { })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered",
    { appID = commonSmoke.getHMIAppId(), unexpectedDisconnect = false })
  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end
--! @PI_PerformViaMANUAL_ONLY: Processing PI with interaction mode MANUAL_ONLY with performing selection
--! @parameters:
--! paramsSend - parameters for PI request
--! self - test object
--! @return: none
local function PI_PerformViaMANUAL_ONLY(paramsSend, self)
  paramsSend.interactionMode = "MANUAL_ONLY"
  local cid = self.mobileSession1:SendRPC("PerformInteraction", paramsSend)
  EXPECT_HMICALL("VR.PerformInteraction", {
      helpPrompt = paramsSend.helpPrompt,
      initialPrompt = paramsSend.initialPrompt,
      timeout = paramsSend.timeout,
      timeoutPrompt = paramsSend.timeoutPrompt
    })
  :Do(function(_,data)
      self.hmiConnection:SendNotification("TTS.Started")
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  EXPECT_HMICALL("UI.PerformInteraction", {
      timeout = paramsSend.timeout,
      choiceSet = setExChoiceSet(paramsSend.interactionChoiceSetIDList),
      initialText = {
        fieldName = "initialInteractionText",
        fieldText = paramsSend.initialText
      }
    })
  :Do(function(_,data)
      SendOnSystemContext(self,"HMI_OBSCURED")
      local function uiResponse()
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",
          { choiceID = paramsSend.interactionChoiceSetIDList[1] })
        self.hmiConnection:SendNotification("TTS.Stopped")
        SendOnSystemContext(self,"MAIN")
      end
      RUN_AFTER(uiResponse, 1000)
    end)
  ExpectOnHMIStatusWithAudioStateChanged_PI(self, "MANUAL")
  self.mobileSession1:ExpectResponse(cid,
    {
      success = true,
      resultCode = "SUCCESS",
      choiceID = paramsSend.interactionChoiceSetIDList[1],
      triggerSource = "MENU"
    })
end

--! @setExChoiceSet: ChoiceSet structure for UI.PerformInteraction request
--! @parameters:
--! choiceIDValues - value of choice id
--! @return: none
local function setExChoiceSet(choiceIDValues)
  local exChoiceSet = { }
  for i = 1, #choiceIDValues do
    exChoiceSet[i] = {
      choiceID = choiceIDValues[i],
      image = {
        value = "icon.png",
        imageType = "STATIC",
      },
      menuName = "Choice" .. choiceIDValues[i]
    }
  end
  return exChoiceSet
end

--! @SendOnSystemContext: OnSystemContext notification
--! @parameters:
--! self - test object,
--! ctx - systemContext value
--! @return: none
local function SendOnSystemContext(self, ctx)
  self.hmiConnection:SendNotification("UI.OnSystemContext",
    { appID = commonSmoke.getHMIAppId(), systemContext = ctx })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSmoke.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSmoke.start)
runner.Step("RAI", commonSmoke.registerApp)
runner.Step("Activate App", commonSmoke.activateApp)
runner.Step("Upload icon file", commonSmoke.putFile, {putFileParams})
runner.Step("CreateInteractionChoiceSet", createInteractionChoiceSet, {createAllParams})

runner.Title("Test")
runner.Step("PerformInteraction with MANUAL_ONLY interaction mode no VR commands", PI_PerformViaMANUAL_ONLY, {requestParams_noVR})
--runner.Step("UnregisterAppInterface Positive Case", unregisterAppInterface)
--runner.Step("RAI", commonSmoke.registerApp)
runner.Step("DeleteInteractionChoiceSet Positive Case", deleteInteractionChoiceSet, {deleteAllParams})

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
