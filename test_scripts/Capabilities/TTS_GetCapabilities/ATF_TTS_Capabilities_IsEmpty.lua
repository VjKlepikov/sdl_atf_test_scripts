---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-24101]: [HMI API] TTS.GetCapabilities request/response
-- [APPLINK-19635]: SDL must retrieve default value from 'HMi_capabilities.json' file and return to app
-- [APPLINK-16101]: [RegisterAppInterface] prerecordedSpeech is NOT provided by HMI
-- Description:
-- In case HMI responds speechCapabilities param or prerecordedSpeech param is empty
-- SDL must retrieve default value from 'hmi_capabilities.json' file and return to app
-- Preconditions:
-- 1. StartSDL
-- 2. InitHMI
-- Steps:
-- 1. HMI->SDL: TTS.Capabilities (speechCapabilities or prerecordedSpeech is empty)
-- 2. InitHMIOnready
-- 3. Register App
-- Expected result:
-- 4. SDL->Mob: {success = true, speechCapabilities = <value from hmi_capabilities.json>})
-- -- SDL must NOT provide prerecordedSpeech parameter within a response to RegisterAppInterface request.

------------------------------------ Common Variables And Functions -------------------------
require('user_modules/all_common_modules')
local TTSCapabilities_Default = common_functions:GetParameterValueInJsonFile
(config.pathToSDL.."hmi_capabilities.json", {"TTS", "capabilities"})
local speechCapabilities_empty ={}
local speechCapabilities = {
  ("TEXT"),
  ("SAPI_PHONEMES"),
  ("LHPLUS_PHONEMES"),
  ("PRE_RECORDED"),
  ("SILENCE")
}
local prerecordedSpeech_empty = {}
local prerecordedSpeech = {
  ("HELP_JINGLE"),
  ("INITIAL_JINGLE"),
  ("LISTEN_JINGLE"),
  ("POSITIVE_JINGLE"),
  ("NEGATIVE_JINGLE")
}

local function ExpectRequest(self, name, mandatory, params)
  local event = events.Event()
  event.level = 2
  event.matches = function(self, data) return data.method == name end
  return
  EXPECT_HMIEVENT(event, name)
  :Times(mandatory and 1 or AnyNumber())
  :Do(function(_, data)
      xmlReporter.AddMessage("hmi_connection","SendResponse",{
          ["methodName"] = tostring(name),
          ["mandatory"] = mandatory ,
          ["params"]= params
        })
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", params)
    end)
end

local function button_capability(name, shortPressAvailable, longPressAvailable, upDownAvailable)
  return {
    name = name,
    shortPressAvailable = shortPressAvailable == nil and true or shortPressAvailable,
    longPressAvailable = longPressAvailable == nil and true or longPressAvailable,
    upDownAvailable = upDownAvailable == nil and true or upDownAvailable
  }
end

local function text_field(name, characterSet, width, rows)
  return {
    name = name,
    characterSet = characterSet or "TYPE2SET",
    width = width or 500,
    rows = rows or 1
  }
end

local function image_field(name, width, height)
  return {
    name = name,
    imageTypeSupported = {
      "GRAPHIC_BMP",
      "GRAPHIC_JPEG",
      "GRAPHIC_PNG"
    },
    imageResolution = {
      resolutionWidth = width or 64,
      resolutionHeight = height or 64
    }
  }
end

local function HMISendTTSGetCapabilitiesInvalid(self, speechCapabilities, prerecordedSpeech)
  ExpectRequest(self,"BasicCommunication.MixingAudioSupported",true, {attenuatedSupported = true})
  ExpectRequest(self,"BasicCommunication.GetSystemInfo", false, {
      ccpu_version = "ccpu_version",
      language = "EN-US",
      wersCountryCode = "wersCountryCode"
    })
  ExpectRequest(self,"UI.GetLanguage", true, { language = "EN-US" })
  ExpectRequest(self,"VR.GetLanguage", true, { language = "EN-US" })
  ExpectRequest(self,"TTS.GetLanguage", true, { language = "EN-US" })
  ExpectRequest(self,"UI.ChangeRegistration", false, { }):Pin()
  ExpectRequest(self,"TTS.SetGlobalProperties", false, { }):Pin()
  ExpectRequest(self,"BasicCommunication.UpdateDeviceList", false, { }):Pin()
  ExpectRequest(self,"VR.ChangeRegistration", false, { }):Pin()
  ExpectRequest(self,"TTS.ChangeRegistration", false, { }):Pin()
  ExpectRequest(self,"VR.GetSupportedLanguages", true, {
      languages = {
        "EN-US","ES-MX","FR-CA","DE-DE","ES-ES","EN-GB","RU-RU",
        "TR-TR","PL-PL","FR-FR","IT-IT","SV-SE","PT-PT","NL-NL",
        "ZH-TW","JA-JP","AR-SA","KO-KR","PT-BR","CS-CZ","DA-DK",
        "NO-NO","NL-BE","EL-GR","HU-HU","FI-FI","SK-SK" }
    })
  ExpectRequest(self,"TTS.GetSupportedLanguages", true, {
      languages = {
        "EN-US","ES-MX","FR-CA","DE-DE","ES-ES","EN-GB","RU-RU",
        "TR-TR","PL-PL","FR-FR","IT-IT","SV-SE","PT-PT","NL-NL",
        "ZH-TW","JA-JP","AR-SA","KO-KR","PT-BR","CS-CZ","DA-DK",
        "NO-NO","NL-BE","EL-GR","HU-HU","FI-FI","SK-SK" }
    })
  ExpectRequest(self,"UI.GetSupportedLanguages", true, {
      languages = {
        "EN-US","ES-MX","FR-CA","DE-DE","ES-ES","EN-GB","RU-RU",
        "TR-TR","PL-PL","FR-FR","IT-IT","SV-SE","PT-PT","NL-NL",
        "ZH-TW","JA-JP","AR-SA","KO-KR","PT-BR","CS-CZ","DA-DK",
        "NO-NO","NL-BE","EL-GR","HU-HU","FI-FI","SK-SK" }
    })
  ExpectRequest(self,"VehicleInfo.GetVehicleType", true, {
      vehicleType = {
        make = "Ford",
        model = "Fiesta",
        modelYear = "2013",
        trim = "SE"
      }
    })
  ExpectRequest(self,"VehicleInfo.GetVehicleData", true, { vin = "52-452-52-752" })

  local buttons_capabilities = {
    capabilities = {
      button_capability("PRESET_0"),
      button_capability("PRESET_1"),
      button_capability("PRESET_2"),
      button_capability("PRESET_3"),
      button_capability("PRESET_4"),
      button_capability("PRESET_5"),
      button_capability("PRESET_6"),
      button_capability("PRESET_7"),
      button_capability("PRESET_8"),
      button_capability("PRESET_9"),
      button_capability("OK", true, false, true),
      button_capability("SEEKLEFT"),
      button_capability("SEEKRIGHT"),
      button_capability("TUNEUP"),
      button_capability("TUNEDOWN")
    },
    presetBankCapabilities = {onScreenPresetsAvailable = true}
  }
  ExpectRequest(self,"Buttons.GetCapabilities", true, buttons_capabilities)
  ExpectRequest(self,"VR.GetCapabilities", true, {vrCapabilities = {"TEXT"}})
  ExpectRequest(self,"TTS.GetCapabilities", true, {
      speechCapabilities = speechCapabilities,
      prerecordedSpeechCapabilities = prerecordedSpeech
    })
  ExpectRequest(self,"UI.GetCapabilities", true, {
      displayCapabilities = {
        displayType = "GEN2_8_DMA",
        textFields = {
          text_field("mainField1"),
          text_field("mainField2"),
          text_field("mainField3"),
          text_field("mainField4"),
          text_field("statusBar"),
          text_field("mediaClock"),
          text_field("mediaTrack"),
          text_field("alertText1"),
          text_field("alertText2"),
          text_field("alertText3"),
          text_field("scrollableMessageBody"),
          text_field("initialInteractionText"),
          text_field("navigationText1"),
          text_field("navigationText2"),
          text_field("ETA"),
          text_field("totalDistance"),
          text_field("navigationText"),
          text_field("audioPassThruDisplayText1"),
          text_field("audioPassThruDisplayText2"),
          text_field("sliderHeader"),
          text_field("sliderFooter"),
          text_field("notificationText"),
          text_field("menuName"),
          text_field("secondaryText"),
          text_field("tertiaryText"),
          text_field("timeToDestination"),
          text_field("turnText"),
          text_field("menuTitle"),
          text_field("locationName"),
          text_field("locationDescription"),
          text_field("addressLines"),
          text_field("phoneNumber")
        },
        imageFields = {
          image_field("softButtonImage"),
          image_field("choiceImage"),
          image_field("choiceSecondaryImage"),
          image_field("vrHelpItem"),
          image_field("turnIcon"),
          image_field("menuIcon"),
          image_field("cmdIcon"),
          image_field("showConstantTBTIcon"),
          image_field("locationImage")
        },
        mediaClockFormats = {
          "CLOCK1",
          "CLOCK2",
          "CLOCK3",
          "CLOCKTEXT1",
          "CLOCKTEXT2",
          "CLOCKTEXT3",
          "CLOCKTEXT4"
        },
        graphicSupported = true,
        imageCapabilities = {"DYNAMIC", "STATIC"},
        templatesAvailable = {"TEMPLATE"},
        screenParams = {
          resolution = {resolutionWidth = 800, resolutionHeight = 480},
          touchEventAvailable = {
            pressAvailable = true,
            multiTouchAvailable = true,
            doublePressAvailable = false
          }
        },
        numCustomPresetsAvailable = 10
      },
      audioPassThruCapabilities = {
        samplingRate = "44KHZ",
        bitsPerSample = "8_BIT",
        audioType = "PCM"
      },
      hmiZoneCapabilities = "FRONT",
      softButtonCapabilities = {
        {
          shortPressAvailable = true,
          longPressAvailable = true,
          upDownAvailable = true,
          imageSupported = true
        }
      }
    })
  ExpectRequest(self,"VR.IsReady", true, { available = true })
  ExpectRequest(self,"TTS.IsReady", true, { available = true })
  ExpectRequest(self,"UI.IsReady", true, { available = true })
  ExpectRequest(self,"Navigation.IsReady", true, { available = true })
  ExpectRequest(self,"VehicleInfo.IsReady", true, { available = true })
  self.applications = { }
  ExpectRequest(self,"BasicCommunication.UpdateAppList", false, { })
  :Pin()
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
      self.applications = { }
      for _, app in pairs(data.params.applications) do
        self.applications[app.appName] = app.appID
      end
    end)

  self.hmiConnection:SendNotification("BasicCommunication.OnReady")
end

local function MobileRegisterAppAndVerifyTTSCapabilities(self)
  local correlationId = self.mobileSession:SendRPC("RegisterAppInterface"
    , config.application1.registerAppInterfaceParams)
  EXPECT_RESPONSE(correlationId, {success = true, speechCapabilities = TTSCapabilities_Default})
  :ValidIf(function(_, data)
      return (data.payload.prerecordedSpeech == nil)
    end)
end
---------------------------------------- Steps ---------------------------------------
local function verifyTTSCapabilitiesWhenSpeechCapabilitiesIsEmtpty()
  common_steps:AddNewTestCasesGroup("Test case: HMI sends TTS.GetCapabilities with speechCapabilities is empty")
  common_steps:StartSDL("Precondition_StartSDL")
  common_steps:InitializeHmi("Precondition_InitHMI")

  function Test:Verify_HMI_Send_TTS_Capabilities_Invalid()
    HMISendTTSGetCapabilitiesInvalid(self, speechCapabilities_empty, prerecordedSpeech)
  end
  common_steps:AddMobileConnection("Precondition_AddMobileConnection")
  common_steps:AddMobileSession("Precondition_AddMobileSession")

  function Test:Mobile_Register_App_And_Verify_TTS_Capabilities()
    if (MobileRegisterAppAndVerifyTTSCapabilities(self) == false) then
      self.FailTestCase("prerecordedSpeech is not null")
    end
  end
  common_steps:StopSDL("PostCondition_StopSDL")
end
verifyTTSCapabilitiesWhenSpeechCapabilitiesIsEmtpty()

local function verifyTTSCapabilitiesWhenPrerecordSpeechCapabilitiesIsEmtpty()
  common_steps:AddNewTestCasesGroup("Test case: HMI sends TTS.GetCapabilities "..
  "with prerecordedSpeechCapabilities is empty")
  common_steps:StartSDL("Precondition_StartSDL")
  common_steps:InitializeHmi("Precondition_InitHMI")

  function Test:Verify_HMI_Send_TTS_Capabilities_Invalid()
    HMISendTTSGetCapabilitiesInvalid(self, speechCapabilities, prerecordedSpeech_empty)
  end
  common_steps:AddMobileConnection("Precondition_AddMobileConnection")
  common_steps:AddMobileSession("Precondition_AddMobileSession")

  function Test:Mobile_Register_App_And_Verify_TTS_Capabilities()
    if (MobileRegisterAppAndVerifyTTSCapabilities(self) == false) then
      self.FailTestCase("prerecordedSpeech is not null")
    end
  end
  common_steps:StopSDL("PostCondition_StopSDL")
end
verifyTTSCapabilitiesWhenPrerecordSpeechCapabilitiesIsEmtpty()
