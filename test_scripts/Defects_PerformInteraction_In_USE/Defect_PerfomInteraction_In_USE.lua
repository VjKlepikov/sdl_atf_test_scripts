---------------------------------------------------------------------------------------------------
-- User story: https://github.com/CustomSDL/Sync3.2v2/issues/512
---------------------------------------------------------------------------------------------------
--
-- Description: Wrong processing of PerformInteraction with ABORTED resultCode
--
-- Steps:
-- 1. Mobile app requests PerformInteraction BOTH
-- 2. User aborts the PerformInteraction
--
-- Expected result:
-- 1. HMI responds with resultCode:5(ABORTED) to VR and UI
-- 2. SDL sends PI response to mobile app with resultCode ABORTED and with appropriate error message
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/commonDefects')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local utils = require("user_modules/utils")
local test = require("user_modules/dummy_connecttest")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParamsAddCommand = {
  menuID = 1000,
  position = 500,
  menuName ="SubMenupositive"
}

local responseUiParams = {
  menuID = requestParamsAddCommand.menuID,
  menuParams = {
    position = requestParamsAddCommand.position,
    menuName = requestParamsAddCommand.menuName
  }
}

local putFileParams = {
  requestParams = {
    syncFileName = 'icon.png',
    fileType = "GRAPHIC_PNG",
    persistentFile = false,
    systemFile = false
  },
  filePath = "files/icon.png"
}

local storagePath = commonPreconditions:GetPathToSDL() .. "storage/" ..
config.application1.registerAppInterfaceParams.appID .. "_" .. common.getDeviceMAC() .. "/"

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

local vrHelpvalue2 = {
  {
    text = " New VRHelp2 ",
    position = 2,
    image = ImageValue
  }
}

-- local requestParams = {
--   initialText = "StartPerformInteraction",
--   initialPrompt = initialPromptValue,
--   interactionMode = "BOTH",
--   interactionChoiceSetIDList = {
--     100, 200, 300
--   },
--   helpPrompt = helpPromptValue,
--   timeoutPrompt = timeoutPromptValue,
--   timeout = 5000,
--   vrHelp = vrHelpvalue,
--   interactionLayout = "ICON_ONLY"
-- }

local requestParams_noVR = {
  initialText = "StartPerformInteraction",
  initialPrompt = initialPromptValue,
  interactionMode = "BOTH",
  interactionChoiceSetIDList = {
    400
  },
  helpPrompt = helpPromptValue,
  timeoutPrompt = timeoutPromptValue,
  timeout = 5000,
  vrHelp = vrHelpvalue,
  interactionLayout = "ICON_ONLY"
}

local requestParams_noVR_2 = {
  initialText = "StartPerformInteraction",
  initialPrompt = initialPromptValue,
  interactionMode = "BOTH",
  interactionChoiceSetIDList = {
    400
  },
  helpPrompt = helpPromptValue,
  timeoutPrompt = timeoutPromptValue,
  timeout = 5000,
  --vrHelp = vrHelpvalue2,
  interactionLayout = "ICON_ONLY"
}

--[[ Local Functions ]]
local function addSubMenu()
  local cid = common.getMobileSession():SendRPC("AddSubMenu", requestParamsAddCommand)

  responseUiParams.appID = common.getHMIAppId()
  EXPECT_HMICALL("UI.AddSubMenu", responseUiParams)
  :Do(function(_,data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)

  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
  common.getMobileSession():ExpectNotification("OnHashChange")
  :Do(function(_,data)
      common.getConfigAppParams().hashID = data.payload.hashID
    end)
end


local function checkAppInfoDat()
  local appInfoDat = commonPreconditions:GetPathToSDL() .. "app_info.dat"
  if utils.isFileExist(appInfoDat) then
    local tbl = utils.jsonFileToTable(appInfoDat)
    if tbl.resumption.resume_app_list[1].appID == common.getConfigAppParams(1).appID and
      tbl.resumption.resume_app_list[1].ign_off_count == 1 then
        utils.cprint(35, "Actual ign_off_count value is saved for app")
    else
      test:FailTestCase("Wrong resumption data is saved for app. AppID is " ..
        tbl.resumption.resume_app_list[1].appID .. ",\n expected ign_off_count value is 1, \n" ..
        "  actual ign_off_count value is " .. tbl.resumption.resume_app_list[1].ign_off_count )
    end
  else
    test:FailTestCase("app_info.dat file was not found")
  end
end

local function registerAppWithResumption()
  common.getMobileSession():StartService(7)
  :Do(function()
      local appParams = common.getConfigAppParams()
      local corId = common.getMobileSession():SendRPC("RegisterAppInterface", appParams)
      common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = common.getConfigAppParams().appName } })
      :Do(function(_, d1)
          common.setHMIAppId(d1.params.application.appID, 1)
        end)
      common.getHMIConnection():ExpectRequest("UI.AddSubMenu", responseUiParams)
      :Do(function(_,data)
          common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
        end)
      common.getMobileSession():ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          common.getMobileSession():ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
            { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
          :Times(2)
          common.getMobileSession():ExpectNotification("OnPermissionsChange")
        end)

      common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp")
      :Do(function(_,data)
          common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
        end)
    end)
end


--! @setChoiceSet: Creates Choice structure
--! @parameters:
--! choiceIDValue - Id for created choice
--! @return: table of created choice structure
local function setChoiceSet(choiceIDValue)
  local temp = {
    {
      choiceID = choiceIDValue,
      menuName ="Choice" .. tostring(choiceIDValue),
      vrCommands = {
        "VrChoice" .. tostring(choiceIDValue),
      },
      image = {
        value ="icon.png",
        imageType ="STATIC",
      }
    }
  }
  return temp
end

--! @setChoiceSet_noVR: Creates Choice structure without VRcommands
--! @parameters:
--! choiceIDValue - Id for created choice
--! @return: table of created choice structure
local function setChoiceSet_noVR(choiceIDValue)
  local temp = {
    {
      choiceID = choiceIDValue,
      menuName ="Choice" .. tostring(choiceIDValue),
      image = {
        value ="icon.png",
        imageType ="STATIC",
      }
    }
  }
  return temp
end

--! @SendOnSystemContext: OnSystemContext notification
--! @parameters:
--! ctx - systemContext value
--! @return: none
local function SendOnSystemContext(ctx)
  common.getHMIConnection():SendNotification("UI.OnSystemContext",
    { appID = common.getHMIAppId(), systemContext = ctx })
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

--! @ExpectOnHMIStatusWithAudioStateChanged_PI: Expectations of OnHMIStatus notification depending on the application
--! type, HMI level and interaction mode
--! @parameters:
--! request - interaction mode,
--! @return: none
local function ExpectOnHMIStatusWithAudioStateChanged_PI(request)
  if "BOTH" == request then
    common.getMobileSession():ExpectNotification("OnHMIStatus",
      { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
      { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "VRSESSION" },
      { hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "VRSESSION" },
      { hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "HMI_OBSCURED" },
      { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "HMI_OBSCURED" },
      { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
    :Times(6)
  elseif "VR" == request then
    common.getMobileSession():ExpectNotification("OnHMIStatus",
      { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "ATTENUATED" },
      { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE" },
      { systemContext = "VRSESSION", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE" },
      { systemContext = "VRSESSION", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" },
      { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })
    :Times(5)
  elseif "MANUAL" == request then
    common.getMobileSession():ExpectNotification("OnHMIStatus",
      { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "ATTENUATED" },
      { systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = "ATTENUATED" },
      { systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" },
      { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })
    :Times(4)
  end
end

--! @CreateInteractionChoiceSet: Creation of Choice Set
--! @parameters:
--! choiceSetID - id for choice set
--! @return: none
local function CreateInteractionChoiceSet(choiceSetID)
  local choiceID = choiceSetID
  local cid = common.getMobileSession():SendRPC("CreateInteractionChoiceSet", {
      interactionChoiceSetID = choiceSetID,
      choiceSet = setChoiceSet(choiceID),
    })
  EXPECT_HMICALL("VR.AddCommand", {
      cmdID = choiceID,
      type = "Choice",
      vrCommands = { "VrChoice" .. tostring(choiceID) }
    })
  :Do(function(_,data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  common.getMobileSession():ExpectResponse(cid, { resultCode = "SUCCESS", success = true })
end

--! @CreateInteractionChoiceSet_noVR: Creation of Choice Set with no vrCommands
--! @parameters:
--! choiceSetID - id for choice set
--! @return: none
local function CreateInteractionChoiceSet_noVR(choiceSetID)
  local choiceID = choiceSetID
  local cid = common.getMobileSession():SendRPC("CreateInteractionChoiceSet", {
      interactionChoiceSetID = choiceSetID,
      choiceSet = setChoiceSet_noVR(choiceID),
    })
  common.getMobileSession():ExpectResponse(cid, { resultCode = "SUCCESS", success = true })
  common.getMobileSession():ExpectNotification("OnHashChange")
  :Do(function(_,data)
      common.getConfigAppParams().hashID = data.payload.hashID
    end)
end

--! @SetImageValue: Set full image path in vrHelp array
--! @parameters:
--! vrHelp - array of the vrHelp items
--! @return: vrHelp array with full image path
local function SetImageValue(vrHelp)
  local tmp = common.cloneTable(vrHelp)
  for i, value in pairs(tmp)  do
    if value.image then
      tmp[i].image.value = storagePath .. tmp[i].image.value
    end
  end
  return tmp
end

--! @PI_PerformViaVR_ONLY: Processing PI with interaction mode VR_ONLY
--! @parameters:
--! paramsSend - parameters for PI request
--! @return: none
local function PI_PerformViaVR_ONLY(paramsSend)
  paramsSend.interactionMode = "VR_ONLY"
  local cid = common.getMobileSession():SendRPC("PerformInteraction",paramsSend)
  EXPECT_HMICALL("VR.PerformInteraction", {
      helpPrompt = paramsSend.helpPrompt,
      initialPrompt = paramsSend.initialPrompt,
      timeout = paramsSend.timeout,
      timeoutPrompt = paramsSend.timeoutPrompt
    })
  :Do(function(_,data)
    local function vrResponse()
      common.getHMIConnection():SendNotification("TTS.Started")
      common.getHMIConnection():SendNotification("VR.Started")
      SendOnSystemContext("VRSESSION")
      common.getHMIConnection():SendError(data.id, data.method, "ABORTED", "Perform Interaction error response.")
      common.getHMIConnection():SendNotification("TTS.Stopped")
      common.getHMIConnection():SendNotification("VR.Stopped")
      SendOnSystemContext("MAIN")
    end
    RUN_AFTER(vrResponse, 1000)
  end)

  EXPECT_HMICALL("UI.PerformInteraction", {
    timeout = paramsSend.timeout,
    vrHelp = SetImageValue(paramsSend.vrHelp),
    vrHelpTitle = paramsSend.initialText,
  })
  :Do(function()
    EXPECT_HMICALL("UI.ClosePopUp", { methodName = "UI.PerformInteraction" })
    :Do(function(_,data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  end)
  ExpectOnHMIStatusWithAudioStateChanged_PI("VR")
  common.getMobileSession():ExpectResponse(cid,
    { success = false, resultCode = "ABORTED", info = "Perform Interaction error response." })
  :ValidIf(function(_, data)
      if data.payload.triggerSource then
        return false, "SDL sends redundant triggerSource parameter in response"
      end
      return true
    end)
end

--! @PI_PerformViaMANUAL_ONLY: Processing PI with interaction mode MANUAL_ONLY
--! @parameters:
--! paramsSend - parameters for PI request
--! @return: none
local function PI_PerformViaMANUAL_ONLY(paramsSend)
  paramsSend.interactionMode = "MANUAL_ONLY"
  local cid = common.getMobileSession():SendRPC("PerformInteraction", paramsSend)
  EXPECT_HMICALL("VR.PerformInteraction", {
      helpPrompt = paramsSend.helpPrompt,
      initialPrompt = paramsSend.initialPrompt,
      timeout = paramsSend.timeout,
      timeoutPrompt = paramsSend.timeoutPrompt
    })
  :Do(function(_,data)
      common.getHMIConnection():SendNotification("TTS.Started")
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  -- EXPECT_HMICALL("UI.PerformInteraction", {
  --     timeout = paramsSend.timeout,
  --     choiceSet = setExChoiceSet(paramsSend.interactionChoiceSetIDList),
  --     initialText = {
  --       fieldName = "initialInteractionText",
  --       fieldText = paramsSend.initialText
  --     }
  --   })
  -- :Do(function(_,data)
  --     SendOnSystemContext("HMI_OBSCURED")
  --     local function uiResponse()
  --       common.getHMIConnection():SendError(data.id, data.method, "ABORTED", "Perform Interaction error response.")
  --       common.getHMIConnection():SendNotification("TTS.Stopped")
  --       SendOnSystemContext("MAIN")
  --     end
  --     RUN_AFTER(uiResponse, 1000)
  --   end)
  -- ExpectOnHMIStatusWithAudioStateChanged_PI("MANUAL")
  -- common.getMobileSession():ExpectResponse(cid,
  --   { success = false, resultCode = "ABORTED", info = "Perform Interaction error response." })
  -- :ValidIf(function(_, data)
  --     if data.payload.triggerSource then
  --       return false, "SDL sends redundant triggerSource parameter in response"
  --     end
  --     return true
  --   end)
end

--! @PI_PerformViaBOTH: Processing PI with interaction mode BOTH with timeout on VR and IU
--! @parameters:
--! paramsSend - parameters for PI request
--! @return: none
local function PI_PerformViaBOTH(paramsSend)
  paramsSend.interactionMode = "BOTH"
  local cid = common.getMobileSession():SendRPC("PerformInteraction",paramsSend)
  EXPECT_HMICALL("VR.PerformInteraction", {
      helpPrompt = paramsSend.helpPrompt,
      initialPrompt = paramsSend.initialPrompt,
      timeout = paramsSend.timeout,
      timeoutPrompt = paramsSend.timeoutPrompt
    })
  :Do(function(_,data)
      common.getHMIConnection():SendNotification("VR.Started")
      common.getHMIConnection():SendNotification("TTS.Started")
      SendOnSystemContext("VRSESSION")
      local function firstSpeakTimeOut()
        common.getHMIConnection():SendNotification("TTS.Stopped")
        common.getHMIConnection():SendNotification("TTS.Started")
      end
      RUN_AFTER(firstSpeakTimeOut, 5)
      local function vrResponse()
        common.getHMIConnection():SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
        common.getHMIConnection():SendNotification("VR.Stopped")
      end
      RUN_AFTER(vrResponse, 20)
    end)
  EXPECT_HMICALL("UI.PerformInteraction", {
      timeout = paramsSend.timeout,
      choiceSet = setExChoiceSet(paramsSend.interactionChoiceSetIDList),
      initialText = {
        fieldName = "initialInteractionText",
        fieldText = paramsSend.initialText
      },
      vrHelp = SetImageValue(paramsSend.vrHelp),
      vrHelpTitle = paramsSend.initialText
    })
  :Do(function(_,data)
      local function choiceIconDisplayed()
        SendOnSystemContext("HMI_OBSCURED")
      end
      RUN_AFTER(choiceIconDisplayed, 25)
      local function uiResponse()
        common.getHMIConnection():SendNotification("TTS.Stopped")
        common.getHMIConnection():SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
        SendOnSystemContext("MAIN")
      end
      RUN_AFTER(uiResponse, 30)
    end)
  ExpectOnHMIStatusWithAudioStateChanged_PI("BOTH")
  common.getMobileSession():ExpectResponse(cid,
    { success = false, resultCode = "TIMED_OUT", info = "Perform Interaction error response." })
  :ValidIf(function(_, data)
      if data.payload.triggerSource then
        return false, "SDL sends redundant triggerSource parameter in response"
      end
      return true
    end)
end

--! @putFile: Processing PutFile
--! @parameters:
--! params - parameters for PutFile request
--! @return: none
local function putFile(params)
  local cid = common.getMobileSession():SendRPC("PutFile", params.requestParams, params.filePath)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end

local createRequestParams = {
  interactionChoiceSetID = 400,
  choiceSet = {
    {
      choiceID = 400,
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

local function deleteInteractionChoiceSet(params)
  utils.wait(300000)
  local cid = common.getMobileSession():SendRPC("DeleteInteractionChoiceSet", params.requestParams)

  params.responseVrParams.appID = common.getHMIAppId()
  EXPECT_HMICALL("VR.DeleteCommand", params.responseVrParams)
  :Do(function(_,data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
  common.getMobileSession():ExpectNotification("OnHashChange")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("Upload icon file", putFile, {putFileParams})
--runner.Step("CreateInteractionChoiceSet with id 100", CreateInteractionChoiceSet, {100})
--runner.Step("CreateInteractionChoiceSet with id 200", CreateInteractionChoiceSet, {200})
--runner.Step("CreateInteractionChoiceSet with id 300", CreateInteractionChoiceSet, {300})
runner.Step("AddSubMenu", addSubMenu)
runner.Step("CreateInteractionChoiceSet no VR commands with id 400", CreateInteractionChoiceSet_noVR, {400})

runner.Title("Test")
--runner.Step("PerformInteraction with VR_ONLY interaction mode", PI_PerformViaVR_ONLY, {requestParams})
--runner.Step("PerformInteraction with MANUAL_ONLY interaction mode", PI_PerformViaMANUAL_ONLY, {requestParams})
runner.Step("PerformInteraction with MANUAL_ONLY interaction mode no VR commands",
  PI_PerformViaMANUAL_ONLY, {requestParams_noVR})

--runner.Step("PerformInteraction with BOTH interaction mode", PI_PerformViaBOTH, {requestParams})
runner.Step("unexpectedDisconnect", common.unexpectedDisconnect)
runner.Step("connectMobile", common.connectMobile)
runner.Step("Data resumption during registration", registerAppWithResumption)
runner.Step("PerformInteraction with MANUAL_ONLY interaction mode no VR commands",
  PI_PerformViaMANUAL_ONLY, {requestParams_noVR_2})
runner.Step("DeleteInteractionChoiceSet Positive Case", deleteInteractionChoiceSet, {deleteAllParams})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
