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
-- -- 5. HMI -> SDL: VR.PerformInteraction (SUCCESS)
-- -- 6. SDL starts <default watchdog timeout> + < timeout_requested_by_app >*2 for UI // after receiving response from VR
-- -- 7. No user action on UI
-- -- 8. HMI -> SDL: OnResetTimeout during timeout is not expried
-- -- 9. SDL resets <default watchdog timeout> + < timeout_requested_by_app >*2 for UI
-- -- 10. HMI resets timeout until user action
-- -- 11. User chose an option
-- -- 12. HMI -> SDL: UI.PerformInteraction (<result_code>)
-- -- 13. SDL -> App: PerformInteraction (<result_code>)

---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')

--[[ Local variables]]
local hmi_cid_vr
local hmi_app_id
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

--[[ Common functions]]
function convert_time(time)
  return tostring(time.hour .. ":" .. time.min .. ":" .. time.sec)
end

--[[ Preconditions ]]
common_steps:AddNewTestCasesGroup("Preconditions")
common_steps:PreconditionSteps("Preconditions", const.precondition.ACTIVATE_APP)
common_steps:PutFile("Preconditions_PutFile_action.png", "action.png")

function Test:Preconditions_CreateInteractionChoiceSet()
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
  local mobile_cid = self.mobileSession:SendRPC("PerformInteraction", mobile_request)
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
        self:FailTestCase("grammarID exists")
      end
      return true
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
  -- display time
  time = os.date("*t")
  common_functions:UserPrint(const.color.green, "== Time when HMI sends VR.PerformInteraction response and SDL start timer: " .. convert_time(time).." ==")
  EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "ATTENUATED"})
end

function Test:UI_Display_Choices()
  hmi_app_id = common_functions:GetHmiAppId(const.default_app.appName, self)
  self.hmiConnection:SendNotification("UI.OnSystemContext",{appID = hmi_app_id, systemContext = "HMI_OBSCURED"})
  EXPECT_NOTIFICATION("OnHMIStatus", {systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = "ATTENUATED"})
end

function Test:SDL_sends_OnResetTimeout()
  -- 8. HMI -> SDL: OnResetTimeout () during timeout is not expired
  local time_send_OnResetTimeout = ui_timeout - 2000
  common_functions:UserPrint(const.color.green,"== [INFO] Please wait about " .. time_send_OnResetTimeout/1000 .. " seconds before sending UI.OnResetTimeout ==")
  os.execute("sleep " .. tostring(time_send_OnResetTimeout/1000))
  time = os.date("*t")
  common_functions:UserPrint(const.color.green,"== Time when HMI sends UI.OnResetTimeout: " .. convert_time(time) .. " ==")
  self.hmiConnection:SendNotification("UI.OnResetTimeout", {appID = hmi_app_id, methodName = "UI.PerformInteraction"})
  reset_timeout = timestamp()
end

function Test:HMI_sends_UI_PerformInteraction_response_after_OnResetTimeout_SUCCESS()
  --Step 12. HMI -> SDL: UI.PerformInteraction (<result_code>)
  local time_send_UI_PerformInteraction = ui_timeout - 3000

  common_functions:UserPrint(const.color.green,"== [INFO] Please wait about " .. time_send_UI_PerformInteraction/1000 .. " seconds before sending UI.PerformInteraction ==")
  os.execute("sleep " .. tostring(time_send_UI_PerformInteraction/1000))
  time = os.date("*t")
  common_functions:UserPrint(const.color.green,"== Time when HMI sends UI.PerformInteraction: " .. convert_time(time) .. " ==")
  self.hmiConnection:SendResponse(hmi_cid_ui, "UI.PerformInteraction", "SUCCESS", {choiceID = 1})

  self.hmiConnection:SendNotification("TTS.Stopped")
  self.hmiConnection:SendNotification("VR.Stopped")
  self.hmiConnection:SendNotification("UI.OnSystemContext",{appID = hmi_app_id, systemContext = "MAIN"})self.hmiConnection:SendNotification("UI.OnSystemContext",{appID = hmi_app_id, systemContext = "MAIN"})

  EXPECT_NOTIFICATION("OnHMIStatus",
    { systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" },
    { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })
  :Times(2)

  EXPECT_RESPONSE("PerformInteraction", {success = true, resultCode = "SUCCESS", triggerSource = "MENU", choiceID = 1})
end

--[[ Postconditions ]]
common_steps:AddNewTestCasesGroup("Postcondition")
local app_name = const.default_app.appName
common_steps:UnregisterApp("Postcondition_UnRegisterApp", app_name)
common_steps:StopSDL("Postcondition_StopSDL")
