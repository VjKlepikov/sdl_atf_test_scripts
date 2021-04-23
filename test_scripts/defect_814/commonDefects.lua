---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.checkAllValidations = true

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require('user_modules/utils')
local test = require("user_modules/dummy_connecttest")
local atf_logger = require("atf_logger")
local events = require("events")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local hmi_values = require("user_modules/hmi_values")

--[[ Local Variables ]]
local commonDefect = actions
commonDefect.wait = utils.wait
commonDefect.cloneTable = utils.cloneTable

function commonDefect.cleanSessions()
  for i = 1, actions.getAppsCount() do
    test.mobileSession[i]:StopRPC()
    :Do(function(_, d)
        utils.cprint(35, "Mobile session " .. d.sessionId .. " deleted")
        test.mobileSession[i] = nil
      end)
  end
  utils.wait()
end

function commonDefect.log(...)
  local str = "[" .. atf_logger.formated_time(true) .. "]"
  for i, p in pairs({...}) do
    local delimiter = "\t"
    if i == 1 then delimiter = " " end
    str = str .. delimiter .. p
  end
  utils.cprint(35, str)
end

function commonDefect.getSoftButCapValues()
  return {
    {
      shortPressAvailable = false,  -- default 'true'
      longPressAvailable = false, -- default 'true'
      upDownAvailable = false, -- default 'true'
      imageSupported = false -- default 'true'
    }
  }
end

function commonDefect.getPresetBankCapValues()
  return { onScreenPresetsAvailable = false } -- default "true"
end

function commonDefect.getButCapValues()
      local names = {
        "PRESET_0",
        "PRESET_1",
        "PRESET_2",
        "PRESET_3",
        "PRESET_4"
        -- "PRESET_5", -- default
        -- "PRESET_6", -- default
        -- "PRESET_7", -- default
        -- "PRESET_8", -- default
        -- "PRESET_9", -- default
        -- "OK", -- default
        -- "SEEKLEFT", -- default
        -- "SEEKRIGHT", -- default
        -- "TUNEUP", -- default
        -- "TUNEDOWN" -- default
      }
      local values = { }
      for _, v in pairs(names) do
        local item = {
          name = v,
          shortPressAvailable = false, -- default 'false'
          longPressAvailable = false, -- default 'false'
          upDownAvailable = false -- default 'false'
        }
        table.insert(values, item)
      end
      return values
end

function commonDefect.getDisplayCapImageFieldsValues()
  local names = {
    "softButtonImage",
    "choiceImage",
    "choiceSecondaryImage",
    "vrHelpItem",
    "turnIcon",
    "menuIcon",
    "cmdIcon",
    "graphic"
    -- "secondaryGraphic", -- value is missed in ImageFieldName
    -- "showConstantTBTIcon", -- default
    -- "showConstantTBTNextTurnIcon", -- default
    -- "locationImage", -- default
    -- "appIcon" -- default
  }
  local values = { }
  for _, v in pairs(names) do
  local item = {
  imageResolution = {
    resolutionHeight = 100,
    resolutionWidth = 100
  },
  imageTypeSupported = {
    "GRAPHIC_BMP"
  },
  name = v
  }
  table.insert(values, item)
  end
  return values
end

function commonDefect.getDisplayCapTextFieldsValues()
-- some text fields are excluded due to SDL issue
  local names = {
    -- "mainField1", -- default
    -- "mainField2", -- default
    -- "mainField3", -- default
    -- "mainField4", -- default
    -- "statusBar", -- default
    -- "mediaClock", -- default
    "mediaTrack",
    "alertText1",
    "alertText2",
    "alertText3",
    "scrollableMessageBody",
    "initialInteractionText",
    "navigationText1",
    "navigationText2",
    "ETA",
    "totalDistance",
    "audioPassThruDisplayText1",
    "audioPassThruDisplayText2",
    "sliderHeader",
    "sliderFooter",
    "menuName",
    "secondaryText",
    "tertiaryText",
    "menuTitle",
    -- "timeToDestination",
    -- "navigationText",
    -- "notificationText",
    -- "locationName",
    -- "locationDescription",
    -- "addressLines",
    -- "phoneNumber",
    "turnText"
  }
  local values = { }
  for _, v in pairs(names) do
    local item = {
      characterSet = "CID1SET",
      name = v,
      rows = 8, -- default '1'
      width = 1 -- default '500'
    }
    table.insert(values, item)
  end
  return values
end


function commonDefect.getDisplayCapValues()
-- some capabilities are excluded due to SDL issue
  return {
    displayType = "TYPE2", -- default 'GEN2_8_DMA'
    graphicSupported = true,  -- default 'true'
    -- imageCapabilities = {
    --   --"DYNAMIC", -- default
    --   "STATIC"
    --  },
    imageFields = commonDefect.getDisplayCapImageFieldsValues(),
    mediaClockFormats = {
      "CLOCK1",
      "CLOCK2",
      -- "CLOCK3", -- default
      -- "CLOCKTEXT1", -- default
      -- "CLOCKTEXT2", -- default
      -- "CLOCKTEXT3", -- default
      -- "CLOCKTEXT4" -- default
    },
    numCustomPresetsAvailable = 50, -- default '10'
    screenParams = {
      resolution = {
        resolutionHeight = 300, -- default '64'
        resolutionWidth = 200 -- default '64'
      },
      touchEventAvailable = {
        doublePressAvailable = true, -- default 'false'
        multiTouchAvailable = false, -- default 'true'
        pressAvailable = false -- default 'true'
      }
    },
    templatesAvailable = {
      "ONSCREEN_PRESETS" -- default 'TEMPLATE'
    },
    textFields = commonDefect.getDisplayCapTextFieldsValues()
    }
end


function commonDefect.getRequestParams()
  return { displayLayout = "ONSCREEN_PRESETS" }
end

function commonDefect.getResponseParams()
  return {
    displayCapabilities = commonDefect.getDisplayCapValues(),
    buttonCapabilities = commonDefect.getButCapValues(),
    softButtonCapabilities = commonDefect.getSoftButCapValues(),
    presetBankCapabilities = commonDefect.getPresetBankCapValues()
  }
end

function commonDefect.setDisplaySuccess(pAppId)
  if pAppId == nil then pAppId = 1 end
  local responseParams = commonDefect.getResponseParams()
  local cid = commonDefect.getMobileSession(pAppId):SendRPC("SetDisplayLayout", commonDefect.getRequestParams())
  commonDefect.log("APP->SDL: RQ SetDisplayLayout")
  commonDefect.getHMIConnection(pAppId):ExpectRequest("UI.SetDisplayLayout", commonDefect.getRequestParams())
  :Do(function(_, data)
      commonDefect.log("SDL->HMI: RQ UI.SetDisplayLayout")
      commonDefect.getHMIConnection(pAppId):SendResponse(data.id, data.method, "SUCCESS", responseParams)
      commonDefect.log("HMI->SDL: RS UI.SetDisplayLayout")
    end)
  local mobileRespDisplayCapabilities = commonDefect.cloneTable(responseParams.displayCapabilities)
  mobileRespDisplayCapabilities.imageCapabilities = nil
  commonDefect.getMobileSession(pAppId):ExpectResponse(cid, {
    success = true,
    resultCode = "SUCCESS",
    displayCapabilities = mobileRespDisplayCapabilities,
    buttonCapabilities = responseParams.buttonCapabilities,
    softButtonCapabilities = responseParams.softButtonCapabilities,
    presetBankCapabilities = responseParams.presetBankCapabilities
  })
  :Do(function(_,data)
      commonDefect.log("SDL->APP: RS SetDisplayLayout")
    end)
end

function commonDefect.registerAppLog(pAppId)
  if not pAppId then pAppId = 1 end
  commonDefect.getMobileSession(pAppId):StartService(7)
  :Do(function()
      local corId = commonDefect.getMobileSession(pAppId):SendRPC("RegisterAppInterface", commonDefect.getConfigAppParams(pAppId))
      commonDefect.log("App->SDL: RQ RegisterAppInterface")
      commonDefect.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = commonDefect.getConfigAppParams(pAppId).appName } })
      :Do(function(_, d1)
          commonDefect.log("SDL->HMI: N BC.OnAppRegistered")
          commonDefect.setHMIAppId(d1.params.application.appID, pAppId)
          commonDefect.getHMIConnection():ExpectRequest("BasicCommunication.PolicyUpdate")
          :Do(function(_, d2)
              commonDefect.getHMIConnection():SendResponse(d2.id, d2.method, "SUCCESS", { })
            end)
        end)
      commonDefect.getMobileSession(pAppId):ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          commonDefect.log("SDL->App: RS RegisterAppInterface")
        end)
    end)
end

local function allowSDL()
    actions.getHMIConnection():SendNotification("SDL.OnAllowSDLFunctionality", {
    allowed = true,
    source = "GUI",
    device = {
      id = utils.getDeviceMAC(),
      name = utils.getDeviceName()
    }
  })
end

function commonDefect.startWoHMIonReady()
  local event = events.Event()
  event.matches = function(e1, e2) return e1 == e2 end
  test:runSDL()
  commonFunctions:waitForSDLStart(test)
  :Do(function()
      test:initHMI()
      :Do(function()
          utils.cprint(35, "HMI initialized")
          test:connectMobile()
          :Do(function()
              utils.cprint(35, "Mobile connected")
              allowSDL(test)
              actions.getHMIConnection():RaiseEvent(event, "Start event")
            end)
        end)
    end)
  return actions.getHMIConnection():ExpectEvent(event, "Start event")
end

function commonDefect.getHMIParams()
  local hmiCaps = hmi_values.getDefaultHMITable()
  hmiCaps.UI.GetCapabilities.mandatory = false

  -- Update UI.GetCapabilities
  hmiCaps.UI.GetCapabilities.params.displayCapabilities.mediaClockFormats = {
    "CLOCK1",
    "CLOCK2",
    "CLOCK3"
    -- "CLOCKTEXT1", -- default
    -- "CLOCKTEXT2", -- default
    -- "CLOCKTEXT3", -- default
    -- "CLOCKTEXT4"  -- default
  }
  hmiCaps.UI.GetCapabilities.params.displayCapabilities.graphicSupported = false -- default 'true'
  hmiCaps.UI.GetCapabilities.params.displayCapabilities.imageCapabilities = {
    "DYNAMIC"
    -- "STATIC"  --default
  }
  hmiCaps.UI.GetCapabilities.params.hmiZoneCapabilities = "BACK" -- default 'FRONT'
  hmiCaps.UI.GetCapabilities.params.softButtonCapabilities = {
    {
      shortPressAvailable = false, -- default 'true'
      longPressAvailable = false, -- default 'true'
      upDownAvailable = false, -- default 'true'
      imageSupported = false -- default 'true'
    }
  }
  return hmiCaps
end

function commonDefect.HMIonReady(pHMIParams)
  test:initHMI_onReady(pHMIParams)
  :Do(function()
    utils.cprint(35, "HMI is ready")
  end)
end


function commonDefect.RAIDuringUIGetCapabilities(pTime)
local hmiCapsParam = commonDefect.getHMIParams()
RUN_AFTER(commonDefect.registerAppLog, pTime)
commonDefect.getHMIConnection():ExpectRequest("UI.GetCapabilities")
:Do(function(_, data)
    commonDefect.log("SDL->HMI: RQ UI.GetCapabilities")
    commonDefect.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", hmiCapsParam.UI.GetCapabilities.params)
    commonDefect.log("SDL->HMI: RS UI.GetCapabilities")
  end)

commonDefect.HMIonReady(hmiCapsParam)
commonDefect.getMobileSession():ExpectNotification("OnHMIStatus",
  { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
end

function commonDefect.UIGetCapabilitiesDuringRAI(pTime)
local hmiCapsParam = commonDefect.getHMIParams()
local function HMIonReadyWithUpdateParam()
  commonDefect.HMIonReady(hmiCapsParam)
end
RUN_AFTER(HMIonReadyWithUpdateParam, pTime)
commonDefect.getHMIConnection():ExpectRequest("UI.GetCapabilities")
:Do(function(_, data)
    commonDefect.log("SDL->HMI: RQ UI.GetCapabilities")
    commonDefect.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", hmiCapsParam.UI.GetCapabilities.params)
    commonDefect.log("SDL->HMI: RS UI.GetCapabilities")
  end)
commonDefect.registerAppLog()
commonDefect.getMobileSession():ExpectNotification("OnHMIStatus",
  { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
end

return commonDefect
