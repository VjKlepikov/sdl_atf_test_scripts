-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

-------------------------------------------Preconditions-------------------------------------
-- Register App -> Activate App
common_steps:PreconditionSteps("PreconditionSteps", 7)
common_steps:PutFile("PreconditionSteps_PutFile_action.png", "action.png")

--------------------------------------------BODY---------------------------------------------
-- Checking: when all params are correct and image of vrHelp does not exist
-- SDL -> MOB : {success = true, resultCode = "WARNINGS", info = "Reference image(s) not found"}
---------------------------------------------------------------------------------------------
function Test:Verify_AllParamsCorrect_ImageNotExist_WARNINGS()
  local cid = self.mobileSession:SendRPC("SetGlobalProperties",
    {
      menuTitle = "Menu Title",
      timeoutPrompt =
      {
        {
          text = "Timeout prompt",
          type = "TEXT"
        }
      },
      vrHelp =
      {
        {
          position = 1,
          image =
          {
            value = "invalidImage.png",
            imageType = "DYNAMIC"
          },
          text = "VR help item"
        }
      },
      menuIcon =
      {
        value = "action.png",
        imageType = "DYNAMIC"
      },
      helpPrompt =
      {
        {
          text = "Help prompt",
          type = "TEXT"
        }
      },
      vrHelpTitle = "VR help title",
      keyboardProperties =
      {
        keyboardLayout = "QWERTY",
        keypressMode = "SINGLE_KEYPRESS",
        language = "EN-US"
      }
    })

  EXPECT_HMICALL("TTS.SetGlobalProperties",
    {
      timeoutPrompt =
      {
        {
          text = "Timeout prompt",
          type = "TEXT"
        }
      },
      helpPrompt =
      {
        {
          text = "Help prompt",
          type = "TEXT"
        }
      }
    })
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)

  EXPECT_HMICALL("UI.SetGlobalProperties",
    {
      menuTitle = "Menu Title",
      vrHelp =
      {
        {
          position = 1,
          image =
          {
            imageType = "DYNAMIC",
            value = common_functions:GetFullPathIcon("invalidImage.png")
          },
          text = "VR help item"
        }
      },
      menuIcon =
      {
        imageType = "DYNAMIC",
        value = common_functions:GetFullPathIcon("action.png")
      },
      vrHelpTitle = "VR help title",
      keyboardProperties =
      {
        keyboardLayout = "QWERTY",
        keypressMode = "SINGLE_KEYPRESS",
        language = "EN-US"
      }
    })
  :Do(function(_,data)
      self.hmiConnection:SendError(data.id, data.method, "WARNINGS","Reference image(s) not found")
    end)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS", info = "Reference image(s) not found"})
  EXPECT_NOTIFICATION("OnHashChange")
end

-------------------------------------------Postconditions-------------------------------------
common_steps:UnregisterApp("Postcondition_UnRegisterApp", const.default_app_name)
common_steps:StopSDL("Postcondition_StopSDL")
