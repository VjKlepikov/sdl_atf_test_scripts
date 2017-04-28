---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-19427]: [PerformInteraction]: SDL must wait response for both UI and VR components
-- [APPLINK-28014]: [PerformInteraction] SDL must increase <timeout> param for MANUAL_ONLY and BOTH modes
-- Description:
-- In case
-- -- SDL splits PerformInteraction_request to UI\ VR-related requests
-- -- and transfers these requests to HMI
-- -- then HMI sends UI.OnResetTimeout
-- -- SDL must:
-- -- resets timeout
-- -- and return resultCode = GENERIC_ERROR to app in case timeout expired
-- Preconditions:
-- -- 1. App is registered and activated
-- -- 2. A ChoiceSet is created
-- Steps:
-- -- 1. App -> SDL: PerformInteraction (timeout, params, mode: MANUAL_ONLY)
-- -- 2. SDL -> HMI: VR.PerformInteraction (initialPrompt, timeoutPrompt,helpPrompt, timeout)// without grammarID
-- -- 3. SDL does not start the timeout for VR
-- -- 4. SDL -> HMI: UI.PerformInteraction (params, timeout)
-- -- 5. HMI -> SDL: VR.PerformInteraction (SUCCESS)// in MANUAL_ONLY HMI responds on request right after storing initial/timeout/help prompts to be used for current PerformInteraction
-- -- 6. SDL starts <default watchdog timeout> + < timeout_requested_by_app >*2 for UI // after receiving response from VR
-- -- 7. No user action on UI
-- -- 8. HMI -> SDL: OnResetTimeout () during timeout is not expired
-- -- 9. SDL resets <default watchdog timeout> for UI
-- -- 10. HMI does not send OnResetTimeout() during timeout is not expried
-- -- 11. SDL <default watchdog timeout> expires on SDL
-- -- 12. SDL -> App: PerformInteraction (GENERIC_ERROR, success:false)

---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')

--[[ Local variables]]
local mobile_cid
local hmi_cid_vr
local default_timeout = tonumber(common_functions:GetValueFromIniFile("DefaultTimeout"))

local mobile_request = {
  interactionMode = "MANUAL_ONLY",
  timeout = 5000,
  initialText = "StartPerformInteraction",
  initialPrompt = {
    {
      text = "Make your choice",
      type = "TEXT"
    }
  },
  interactionChoiceSetIDList = {1},
  helpPrompt = {
    {
      text = "Help Prompt",
      type = "TEXT"
    }
  },
  timeoutPrompt = {
    {
      text = "Time out",
      type = "TEXT"
    }
  },
  vrHelp = {
    {
      text = " New VRHelp ",
      position = 1,
      image = {
        value = "icon.png",
        imageType = "STATIC"
      }
    }
  },
  interactionLayout = "ICON_ONLY"
}

local ui_timeout = default_timeout + mobile_request.timeout * 2

--[[ Preconditions ]]
common_steps:AddNewTestCasesGroup("Preconditions")
common_steps:PreconditionSteps("Preconditions", const.precondition.ACTIVATE_APP)
common_steps:PutFile("Preconditions_PutFile_action.png", "action.png")

function Test:Precondition_CreateInteractionChoiceSet()
  cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",{
      interactionChoiceSetID = 1,
      choiceSet = {
        {
          choiceID = 1,
          menuName ="Choice1",
          vrCommands =
          {
            "VrChoice1",
          },
          image =
          {
            value ="action.png",
            imageType ="STATIC",
          }
        }
      }
    })
  EXPECT_HMICALL("VR.AddCommand",
    {
      cmdID = 1,
      type = "Choice",
      vrCommands = {"VrChoice1"}
    })
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  EXPECT_RESPONSE(cid, { resultCode = "SUCCESS", success = true })
end

--[[ Test ]]
common_steps:AddNewTestCasesGroup("Test")
function Test:Send_PerformInteraction_Request()
  --Step 1. App -> SDL: PerformInteraction (timeout, params, mode: MANUAL_ONLY)
  mobile_cid = self.mobileSession:SendRPC("PerformInteraction", mobile_request)

  --Step 2. SDL -> HMI: VR.PerformInteraction (initialPrompt, timeoutPrompt,helpPrompt, timeout)// without grammarID
  EXPECT_HMICALL("VR.PerformInteraction",
    {
      helpPrompt = mobile_request.helpPrompt,
      initialPrompt = mobile_request.initialPrompt,
      timeout = mobile_request.timeout,
      timeoutPrompt = mobile_request.timeoutPrompt
    }
  )
  :ValidIf(function(_,data)
      if data.params.grammarID then
        self:FailTestCase("grammarID exist")
        return false
      else
        return true
      end
    end)
  :Do(function(_,data)
      hmi_cid_vr = data.id
    end)

  --Step 4. SDL -> HMI: UI.PerformInteraction (params, timeout)
  EXPECT_HMICALL("UI.PerformInteraction",
    {
      timeout = mobile_request.timeout,
      choiceSet = {
        {
          choiceID = 1,
          image = {
            imageType = "STATIC",
            value = "action.png"
          },
          menuName = "Choice1"
        }
      },
      initialText =
      {
        fieldName = "initialInteractionText",
        fieldText = mobile_request.initialText
      }
    })
end

function Test:Send_VR_Responds()
  -- Step 5. HMI -> SDL: VR.PerformInteraction (SUCCESS)
  self.hmiConnection:SendNotification("TTS.Started")
  self.hmiConnection:SendResponse(hmi_cid_vr, "VR.PerformInteraction", "SUCCESS", {info = "vr info"})
  vr_time = timestamp()
  -- display date time
  print("=====Time when HMI sends VR.PerformInteraction response and SDL start timer=====")
  os.execute("date")
  EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "ATTENUATED"})
end

function Test:UI_Display_Choices_and_OnResetTimeout()
  local hmi_app_id = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)
  self.hmiConnection:SendNotification("UI.OnSystemContext",{appID = hmi_app_id, systemContext = "HMI_OBSCURED"})
  EXPECT_NOTIFICATION("OnHMIStatus", {systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = "ATTENUATED"})

  -- 8. HMI -> SDL: OnResetTimeout () during timeout is not expired
  local function OnResetTimeout()
    local current_time = timestamp()
    local interval = current_time - vr_time
    if (interval > default_timeout) and (interval < ui_timeout) then
      self.hmiConnection:SendNotification("UI.OnResetTimeout", {appID = hmi_app_id, methodName = "UI.PerformInteraction"})
      reset_timeout = timestamp()
      common_functions:UserPrint(32, "Time to sending OnResetTimeout is " ..
        tostring(interval) ..", expected ~" .. tostring(ui_timeout - 2000))
    else
      self:FailTestCase("Time to sending OnResetTimeout is more than " .. tostring(ui_timeout))
    end
  end
  RUN_AFTER(OnResetTimeout, ui_timeout - 2000)
  common_functions:DelayedExp(ui_timeout - 2000)
end

function Test:SDL_sends_GENERIC_ERROR_after_timeout_expired()
  --Step 12. SDL -> App: PerformInteraction (GENERIC_ERROR, success:false)
  EXPECT_RESPONSE(mobile_cid, {success = false, resultCode = "GENERIC_ERROR"})
  :Timeout(ui_timeout + 1000)
  :ValidIf(function(_,data)
      local current_time = timestamp()
      local interval = current_time - reset_timeout
      if (interval < ui_timeout + 1000) and (interval > ui_timeout - 1000) then
        common_functions:UserPrint(32, "SUCCESS:Time to GENERIC_ERROR: " ..
          tostring(interval) ..", expected ~" .. tostring(ui_timeout))
        return true
      else
        common_functions:UserPrint(31, "FAIL:Time to GENERIC_ERROR: " ..
          tostring(interval) ..", expected ~" .. tostring(ui_timeout))
        return false
      end
    end)
end

--[[ Postconditions ]]
common_steps:AddNewTestCasesGroup("Postcondition")
local app_name = config.application1.registerAppInterfaceParams.appName
common_steps:UnregisterApp("Postcondition_UnRegisterApp", app_name)
common_steps:StopSDL("Postcondition_StopSDL")
