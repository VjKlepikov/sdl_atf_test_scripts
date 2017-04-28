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
-- -- transfer received resultCode from HMI to mobile app
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
-- -- 8. HMI -> SDL: OnResetTimeout during timeout is not expried
-- -- 9. SDL resets <default watchdog timeout> for UI
-- -- 10. HMI resets timeout until user action
-- -- 11. User chose an option
-- -- 12. HMI -> SDL: UI.PerformInteraction (<result_code>)
-- -- 13. SDL -> App: PerformInteraction (<result_code>)

---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')

--[[ Local variables]]
local default_timeout = tonumber(common_functions:GetValueFromIniFile("DefaultTimeout"))
local mobile_cid
local hmi_cid_ui
local hmi_cid_vr

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
local reset_timeout = 0

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
  :Do(function(_,data)
      hmi_cid_ui = data.id
    end)
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

function Test:UI_Display_Choices_and_Send_OnResetTimeout()
  local hmi_app_id = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)
  self.hmiConnection:SendNotification("UI.OnSystemContext",{appID = hmi_app_id, systemContext = "HMI_OBSCURED"})
  EXPECT_NOTIFICATION("OnHMIStatus", {systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = "ATTENUATED"})

  --Step 10. HMI resets timeout until user action
  local function OnResetTimeout()
    local current_time = timestamp()
    local interval = current_time - vr_time
    if (interval > ui_timeout - mobile_request.timeout) and (interval < ui_timeout) then
      self.hmiConnection:SendNotification("UI.OnResetTimeout", {appID = hmi_app_id, methodName = "UI.PerformInteraction"})
      reset_timeout = timestamp()
      common_functions:UserPrint(32, "Time to send OnResetTimeout is " .. tostring(interval) ..", expected ~" .. tostring(ui_timeout - 2000))
    else
      self:FailTestCase("Time for sending OnResetTimeout is 111" .. tostring(ui_timeout))
    end
  end
  RUN_AFTER(OnResetTimeout, ui_timeout - 2000)
end

function Test:Send_Response_UI_PerformInteraction_To_HMI_After_OnResetTimeout_SUCCESS()
  --Step 12. HMI -> SDL: UI.PerformInteraction (<result_code>)
  local hmi_app_id = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)
  local function UI_PerformInteraction()
    local current_time = timestamp()
    local interval = current_time - reset_timeout
    if (interval <= tonumber(default_timeout)) then
      self.hmiConnection:SendResponse(hmi_cid_ui, "UI.PerformInteraction", "SUCCESS", {choiceID = 1})
      common_functions:UserPrint(32, "Time to send response UI.PerformInteraction after OnResetTimeout is " ..
        tostring(interval) ..", < DefaultTimeout (" .. tostring(default_timeout) .. ")")
    else
      self:FailTestCase("Time for sending response UI.PerformInteraction is more than " .. tostring(default_timeout))
    end
  end
  RUN_AFTER(UI_PerformInteraction, ui_timeout + 2000)

  local function Stopped()
    self.hmiConnection:SendNotification("TTS.Stopped")
  end
  RUN_AFTER(Stopped, ui_timeout + 3000)

  local function OnSystemContext2()
    self.hmiConnection:SendNotification("UI.OnSystemContext",{appID = hmi_app_id, systemContext = "MAIN"})
  end
  RUN_AFTER(OnSystemContext2, ui_timeout + 4000)

  EXPECT_NOTIFICATION("OnHMIStatus",
    { systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" },
    { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })
  :Times(2)
  :Timeout(ui_timeout + 5000)

  --Step 13. SDL -> App: PerformInteraction (<result_code>)
  EXPECT_RESPONSE(mobile_cid, {success = true, resultCode = "SUCCESS"})
  :Timeout(ui_timeout + 5000)
end

--[[ Postconditions ]]
common_steps:AddNewTestCasesGroup("Postcondition")
local app_name = config.application1.registerAppInterfaceParams.appName
common_steps:UnregisterApp("Postcondition_UnRegisterApp", app_name)
common_steps:StopSDL("Postcondition_StopSDL")
