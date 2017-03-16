---------------------------------------------------------------------------------------------
-- TC: Check that SDL verifies every App's request before processing it using
-- appropriate group of permission
-- Precondition: App is registered
-- Steps:
-- -- 1. Send 3 APIs from allowed levels with valid parameters
-- Expected behaviour
-- -- 1. Output shows all permissions for default group
-- -- 2. All APIs are processed correctly

-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

---------------------------- Variables and Common function ----------------------------------
api_name = "SetDisplayLayout"
local functional_groupings = common_functions:GetParameterValueInJsonFile
(config.pathToSDL.."sdl_preloaded_pt.json", {"policy_table", "app_policies", "default", "groups"})

local list_allowed_levels = common_functions:GetParameterValueInJsonFile
(config.pathToSDL.."sdl_preloaded_pt.json", {"policy_table", "functional_groupings",
    functional_groupings[1], "rpcs", api_name, "hmi_levels"})

function check_api_has_NONE_allowed_level()
  for i=1, #list_allowed_levels do
    if list_allowed_levels[i] == "NONE" then
      return true
    end
  end
  return false
end

function displayCap_imageFields_Value()

  local imageFields =
  {
    {
      imageResolution =
      {
        resolutionHeight = 64,
        resolutionWidth = 64
      },
      imageTypeSupported =
      {
        "GRAPHIC_BMP",
        "GRAPHIC_JPEG",
        "GRAPHIC_PNG"
      },
      name = "softButtonImage"
    },
    {
      imageResolution =
      {
        resolutionHeight = 64,
        resolutionWidth = 64
      },
      imageTypeSupported =
      {
        "GRAPHIC_BMP",
        "GRAPHIC_JPEG",
        "GRAPHIC_PNG"
      },
      name = "choiceImage"
    },
    {
      imageResolution =
      {
        resolutionHeight = 64,
        resolutionWidth = 64
      },
      imageTypeSupported =
      {
        "GRAPHIC_BMP",
        "GRAPHIC_JPEG",
        "GRAPHIC_PNG"
      },
      name = "choiceSecondaryImage"
    },
    {
      imageResolution =
      {
        resolutionHeight = 64,
        resolutionWidth = 64
      },
      imageTypeSupported =
      {
        "GRAPHIC_BMP",
        "GRAPHIC_JPEG",
        "GRAPHIC_PNG"
      },
      name = "vrHelpItem"
    },
    {
      imageResolution =
      {
        resolutionHeight = 64,
        resolutionWidth = 64
      },
      imageTypeSupported =
      {
        "GRAPHIC_BMP",
        "GRAPHIC_JPEG",
        "GRAPHIC_PNG"
      },
      name = "turnIcon"
    },
    {
      imageResolution =
      {
        resolutionHeight = 64,
        resolutionWidth = 64
      },
      imageTypeSupported =
      {
        "GRAPHIC_BMP",
        "GRAPHIC_JPEG",
        "GRAPHIC_PNG"
      },
      name = "menuIcon"
    },
    {
      imageResolution =
      {
        resolutionHeight = 64,
        resolutionWidth = 64
      },
      imageTypeSupported =
      {
        "GRAPHIC_BMP",
        "GRAPHIC_JPEG",
        "GRAPHIC_PNG"
      },
      name = "cmdIcon"
    },
    {
      imageResolution =
      {
        resolutionHeight = 64,
        resolutionWidth = 64
      },
      imageTypeSupported =
      {
        "GRAPHIC_BMP",
        "GRAPHIC_JPEG",
        "GRAPHIC_PNG"
      },
      name = "graphic"
    },
    {
      imageResolution =
      {
        resolutionHeight = 64,
        resolutionWidth = 64
      },
      imageTypeSupported =
      {
        "GRAPHIC_BMP",
        "GRAPHIC_JPEG",
        "GRAPHIC_PNG"
      },
      name = "showConstantTBTIcon"
    },
    {
      imageResolution =
      {
        resolutionHeight = 64,
        resolutionWidth = 64
      },
      imageTypeSupported =
      {
        "GRAPHIC_BMP",
        "GRAPHIC_JPEG",
        "GRAPHIC_PNG"
      },
      name = "showConstantTBTNextTurnIcon"
    },
    {
      imageResolution =
      {
        resolutionHeight = 64,
        resolutionWidth = 64
      },
      imageTypeSupported =
      {
        "GRAPHIC_BMP",
        "GRAPHIC_JPEG",
        "GRAPHIC_PNG"
      },
      name = "showConstantTBTNextTurnIcon"
    }
  }
  return imageFields

end
function displayCap_textFields_Value()

  local textFields =
  {
    {
      characterSet = "TYPE2SET",
      name = "mainField1",
      rows = 1,
      width = 500
    },
    {
      characterSet = "TYPE2SET",
      name = "mainField2",
      rows = 1,
      width = 500
    },
    {
      characterSet = "TYPE2SET",
      name = "mainField3",
      rows = 1,
      width = 500
    },
    {
      characterSet = "TYPE2SET",
      name = "mainField4",
      rows = 1,
      width = 500
    },
    {
      characterSet = "TYPE2SET",
      name = "statusBar",
      rows = 1,
      width = 500
    },
    {
      characterSet = "TYPE2SET",
      name = "mediaClock",
      rows = 1,
      width = 500
    },
    {
      characterSet = "TYPE2SET",
      name = "mediaTrack",
      rows = 1,
      width = 500
    },
    {
      characterSet = "TYPE2SET",
      name = "alertText1",
      rows = 1,
      width = 500
    },
    {
      characterSet = "TYPE2SET",
      name = "alertText2",
      rows = 1,
      width = 500
    },
    {
      characterSet = "TYPE2SET",
      name = "alertText3",
      rows = 1,
      width = 500
    },
    {
      characterSet = "TYPE2SET",
      name = "scrollableMessageBody",
      rows = 1,
      width = 500
    },
    {
      characterSet = "TYPE2SET",
      name = "initialInteractionText",
      rows = 1,
      width = 500
    },
    {
      characterSet = "TYPE2SET",
      name = "navigationText1",
      rows = 1,
      width = 500
    },
    {
      characterSet = "TYPE2SET",
      name = "navigationText2",
      rows = 1,
      width = 500
    },
    {
      characterSet = "TYPE2SET",
      name = "ETA",
      rows = 1,
      width = 500
    },
    {
      characterSet = "TYPE2SET",
      name = "totalDistance",
      rows = 1,
      width = 500
    },
    {
      characterSet = "TYPE2SET",
      name = "navigationText", --Error
      rows = 1,
      width = 500
    },
    {
      characterSet = "TYPE2SET",
      name = "audioPassThruDisplayText1",
      rows = 1,
      width = 500
    },
    {
      characterSet = "TYPE2SET",
      name = "audioPassThruDisplayText2",
      rows = 1,
      width = 500
    },
    {
      characterSet = "TYPE2SET",
      name = "sliderHeader",
      rows = 1,
      width = 500
    },
    {
      characterSet = "TYPE2SET",
      name = "sliderFooter",
      rows = 1,
      width = 500
    },
    {
      characterSet = "TYPE2SET",
      name = "notificationText",
      rows = 1,
      width = 500
    },
    {
      characterSet = "TYPE2SET",
      name = "menuName",
      rows = 1,
      width = 500
    },
    {
      characterSet = "TYPE2SET",
      name = "secondaryText",
      rows = 1,
      width = 500
    },
    {
      characterSet = "TYPE2SET",
      name = "tertiaryText",
      rows = 1,
      width = 500
    },
    {
      characterSet = "TYPE2SET",
      name = "timeToDestination",
      rows = 1,
      width = 500
    },
    {
      characterSet = "TYPE2SET",
      name = "turnText",
      rows = 1,
      width = 500
    },
    {
      characterSet = "TYPE2SET",
      name = "menuTitle",
      rows = 1,
      width = 500
    },
    {
      characterSet = "TYPE2SET",
      name = "locationName",
      rows = 1,
      width = 500
    },
    {
      characterSet = "TYPE2SET",
      name = "locationDescription",
      rows = 1,
      width = 500
    },
    {
      characterSet = "TYPE2SET",
      name = "addressLines",
      rows = 1,
      width = 500
    },
    {
      characterSet = "TYPE2SET",
      name = "phoneNumber",
      rows = 1,
      width = 500
    }
  }

  return textFields

end
function displayCap_Value()
  local displayCapabilities =
  {
    displayType = "GEN2_8_DMA",
    graphicSupported = true,
    imageCapabilities =
    {
      "DYNAMIC",
      "STATIC"
    },
    imageFields = displayCap_imageFields_Value(),

    mediaClockFormats =
    {
      "CLOCK1",
      "CLOCK2",
      "CLOCK3",
      "CLOCKTEXT1",
      "CLOCKTEXT2",
      "CLOCKTEXT3",
      "CLOCKTEXT4"
    },
    numCustomPresetsAvailable = 10,
    screenParams =
    {
      resolution =
      {
        resolutionHeight = 480,
        resolutionWidth = 800
      },
      touchEventAvailable =
      {
        doublePressAvailable = false,
        multiTouchAvailable = true,
        pressAvailable = true
      }
    },
    templatesAvailable =
    {
      "ONSCREEN_PRESETS"
    },
    textFields = displayCap_textFields_Value()
  }

  return displayCapabilities
end
function butCap_Value()

  local buttonCapabilities =
  {
    {
      name = "PRESET_0",
      shortPressAvailable = true,
      longPressAvailable = true,
      upDownAvailable = true
    },
    {
      name = "PRESET_1",
      shortPressAvailable = true,
      longPressAvailable = true,
      upDownAvailable = true
    },
    {
      name = "PRESET_2",
      shortPressAvailable = true,
      longPressAvailable = true,
      upDownAvailable = true
    },
    {
      name = "PRESET_3",
      shortPressAvailable = true,
      longPressAvailable = true,
      upDownAvailable = true
    },
    {
      name = "PRESET_4",
      shortPressAvailable = true,
      longPressAvailable = true,
      upDownAvailable = true
    },
    {
      name = "PRESET_5",
      shortPressAvailable = true,
      longPressAvailable = true,
      upDownAvailable = true
    },
    {
      name = "PRESET_6",
      shortPressAvailable = true,
      longPressAvailable = true,
      upDownAvailable = true
    },
    {
      name = "PRESET_7",
      shortPressAvailable = true,
      longPressAvailable = true,
      upDownAvailable = true
    },
    {
      name = "PRESET_8",
      shortPressAvailable = true,
      longPressAvailable = true,
      upDownAvailable = true
    },
    {
      name = "PRESET_9",
      shortPressAvailable = true,
      longPressAvailable = true,
      upDownAvailable = true
    },

    {
      name = "OK",
      shortPressAvailable = true,
      longPressAvailable = true,
      upDownAvailable = true
    },
    {
      name = "SEEKLEFT",
      shortPressAvailable = true,
      longPressAvailable = true,
      upDownAvailable = true
    },
    {
      name = "SEEKRIGHT",
      shortPressAvailable = true,
      longPressAvailable = true,
      upDownAvailable = true
    },
    {
      name = "TUNEUP",
      shortPressAvailable = true,
      longPressAvailable = true,
      upDownAvailable = true
    },
    {
      name = "TUNEDOWN",
      shortPressAvailable = true,
      longPressAvailable = true,
      upDownAvailable = true
    }
  }
  return buttonCapabilities
end
function createDefaultResponseParamsValues(strInfo)
  local param =
  {
    displayCapabilities = displayCap_Value(),
    buttonCapabilities = butCap_Value(),
    softButtonCapabilities =
    {{
        shortPressAvailable = true,
        longPressAvailable = true,
        upDownAvailable = true,
        imageSupported = true
    }},
    presetBankCapabilities =
    {
      onScreenPresetsAvailable = true
    },
    info = strInfo
  }
  return param
end

------------------------------------ Precondition -------------------------------------------
function Test:Delete_Policy_Table()
  common_functions:DeletePolicyTable()
end
common_steps:PreconditionSteps("PreconditionSteps", 6)
common_steps:PutFile("PreconditionSteps_Putfile_Icon.png", "icon.png")

------------------------------------------- Steps -------------------------------------------
function Test:Verify_SetDispLay_ALLOWED()
  if check_api_has_NONE_allowed_level() then
    local cid = self.mobileSession:SendRPC("SetDisplayLayout",
      {
        displayLayout = "ONSCREEN_PRESETS"
      })
    EXPECT_HMICALL("UI.SetDisplayLayout",
      {
        displayLayout = "ONSCREEN_PRESETS"
      })
    :Do(function(_,data)
        local responsedParams = createDefaultResponseParamsValues()
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
      end)
    EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
  else
    self.FailTestCase(api_name .. ": NONE isn't allowed level")
  end
end

-------------------------------------------Postconditions-------------------------------------
common_steps:StopSDL("Postcondition_StopSDL")
