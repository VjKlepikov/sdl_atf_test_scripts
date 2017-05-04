---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-19427]: [PerformInteraction]: SDL must wait response for both UI and VR components
-- [APPLINK-28014]: [PerformInteraction] SDL must increase <timeout> param for MANUAL_ONLY and BOTH modes

-- Description:
-- SDL starts timeout = <default watchdog timeout> + < timeout_requested_by_app >*2 for UI when receiving response from VR for PerformInteraction
-- And UI sends PerformInteraction response before timeout expired, SDL will forward this response to mobile.

-- Preconditions:
-- 1. App is registered and activated
-- 2. A choiceset is created

-- Steps and expectations:
-- 1. App -> SDL: PerformInteraction (timeout, params, mode: BOTH)
-- 2. SDL -> HMI: VR.PerformInteraction (params, timeout)// with grammarID
-- 3. SDL does not start the timeout for VR
-- 4. SDL -> HMI: UI.PerformInteraction (params, timeout)
-- 5. HMI -> SDL: VR.PerformInteraction (SUCCESS, choiceID)
-- 6. SDL starts <default watchdog timeout> + < timeout_requested_by_app >*2 for UI// according to APPLINK-19427 SDL must wait for response from both components
-- 7. HMI -> SDL: UI.PerformInteraction (SUCCESS)
-- 8. SDL -> App: PerformInteraction (SUCCESS, success:true, choiceID)
---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')

--[[ Local Variables ]]
local mob_cid, vr_cid, ui_cid, vr_response_time, hmi_app_id
local default_timeout = common_functions:GetValueFromIniFile("DefaultTimeout")

--[[ Preconditions ]]
common_steps:AddNewTestCasesGroup("Preconditions")
-- An app is registered and activated
common_steps:PreconditionSteps("Preconditions", const.precondition.ACTIVATE_APP)
common_steps:PutFile("Preconditions_PutFile_action.png", "action.png")
function Test:Precondition_CreateInteractionChoiceSet_interactionChoiceSetID_1()
  local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
    {
      interactionChoiceSetID = 1,
      choiceSet =
      {
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

---------------------------------------------------------------------------------------------
--[[ Test ]]
common_steps:AddNewTestCasesGroup("Test")

function Test:Step_1_4_Mobile_Sends_Request_PerformInteraction_BOTH()
  -- 1. App -> SDL: PerformInteraction (timeout, params, mode: BOTH)
  local request = {
    interactionMode = "BOTH",
    timeout = 5000,
    initialText = "StartPerformInteraction",
    initialPrompt = {{text = "Make your choice", type = "TEXT"}},
    interactionChoiceSetIDList = {1},
    helpPrompt = {{text = "Help Prompt", type = "TEXT"}},
    timeoutPrompt = {{text = "Time out", type = "TEXT"}},
    vrHelp = {
      {
        text = "New VRHelp",
        position = 1,
        image = {value = "icon.png", imageType = "STATIC"}
      }
    },
    interactionLayout = "ICON_ONLY"
  }
  -- mobile side: sending PerformInteraction request
  mob_cid = self.mobileSession:SendRPC("PerformInteraction", request)
  -- 2. SDL -> HMI: VR.PerformInteraction (params, timeout)// with grammarID
  EXPECT_HMICALL("VR.PerformInteraction",
    {
      helpPrompt = request.helpPrompt,
      initialPrompt = request.initialPrompt,
      timeout = request.timeout,
      timeoutPrompt = request.timeoutPrompt
    })
  :ValidIf(function(_,data)
      if data.params.grammarID then
        return true
      else
        self:FailTestCase("VR.PerformInteraction does not have grammarID parameter")
      end
    end)
  :Do(function(_,data)
      vr_cid = data.id
    end)
  -- 3. SDL does not start the timeout for VR
  -- 4. SDL -> HMI: UI.PerformInteraction (params, timeout)
  EXPECT_HMICALL("UI.PerformInteraction",
    {
      timeout = request.timeout,
      choiceSet = {
        {
          choiceID = 1,
          image = {imageType = "STATIC", value = "action.png"},
          menuName = "Choice1"
        }
      },
      initialText =
      {
        fieldName = "initialInteractionText",
        fieldText = request.initialText
      }
    })
  :Do(function(_,data)
      ui_cid = data.id
    end)
end

function Test:Step_1_4_VR_Started()
  self.hmiConnection:SendNotification("VR.Started")
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
end

function Test:Step_1_4_TTS_Started_initialPrompt()
  self.hmiConnection:SendNotification("TTS.Started")
end

function Test:Step_1_4_UI_OnSystemContext_VRSESSION()
  hmi_app_id = common_functions:GetHmiAppId(const.default_app.appName, self)
  self.hmiConnection:SendNotification("UI.OnSystemContext",{appID = hmi_app_id, systemContext = "VRSESSION"})
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "VRSESSION"})
end

function Test:Step_5_VR_Responds_SUCCESS_SDL_Start_Timer()
  -- 5. HMI -> SDL: VR.PerformInteraction (SUCCESS, choiceID)
  self.hmiConnection:SendResponse(vr_cid, "VR.PerformInteraction", "SUCCESS", {info = "VR error message"})
  vr_response_time = timestamp()
  -- display date time
  common_functions:UserPrint(const.color.green, "=====Time when HMI sends VR.PerformInteraction response and SDL start timer=====")
  os.execute("date")
  -- SDL does not send PerformInteraction to mobile
  EXPECT_RESPONSE("PerformInteraction")
  :Times(0)  
end

function Test:Step_6_TTS_Stopped_initialPrompt()
  self.hmiConnection:SendNotification("TTS.Stopped")
end

function Test:Step_6_TTS_Started_timeoutPrompt()
  self.hmiConnection:SendNotification("TTS.Started")
end

function Test:Step_6_TTS_Stopped_timeoutPrompt()
  self.hmiConnection:SendNotification("TTS.Stopped")
end

function Test:Step_6_VR_Stopped()
  self.hmiConnection:SendNotification("VR.Stopped")
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "VRSESSION"})
end

function Test:Step_6_UI_display_Choices_OnSystemContext_HMI_OBSCURED()
  --Choice icon list is displayed
  self.hmiConnection:SendNotification("UI.OnSystemContext",{appID = hmi_app_id, systemContext = "HMI_OBSCURED"})
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "HMI_OBSCURED"})
end

function Test:Step_7_UI_PerformInteraction_SUCCESS()
  -- Calculate time to send UI.PerformInteraction response
  local timeout = default_timeout + 5000*2  
  local current_time = timestamp()
  local interval = current_time - vr_response_time
  local ui_response_time = timeout - 1000
  if (interval < ui_response_time) then -- 1s to make sure that HMI sends UI response before timeout
    local wait_more_time = math.floor((ui_response_time - interval)/1000) -- unit is second
    common_functions:UserPrint(const.color.green, "[INFO] This step may take " .. wait_more_time .. " miliseconds to wait before sending UI.PerformInteraction response")
    os.execute("sleep " .. tostring(wait_more_time))
  end
  common_functions:UserPrint(const.color.green, "=====Time when HMI sends UI.PerformInteraction response=====")
  os.execute("date")  
  -- 7. HMI -> SDL: UI.PerformInteraction (SUCCESS)
  self.hmiConnection:SendResponse(ui_cid, "UI.PerformInteraction", "SUCCESS", {choiceID = 1})  
  -- 8. SDL -> App: PerformInteraction (SUCCESS, success:true, choiceID)
  EXPECT_RESPONSE("PerformInteraction", {success = true, resultCode = "SUCCESS", triggerSource = "MENU", choiceID = 1})  
end

function Test:Step_7_UI_close_pop_up_OnSystemContext_MAIN()
  self.hmiConnection:SendNotification("UI.OnSystemContext",{appID = hmi_app_id, systemContext = "MAIN"})
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
end

---------------------------------------------------------------------------------------------
--[[ Postconditions ]]
common_steps:AddNewTestCasesGroup("Postconditions")
local app_name = const.default_app.appName
common_steps:UnregisterApp("Postcondition_UnRegisterApp", app_name)
common_steps:StopSDL("Postcondition_StopSDL")
