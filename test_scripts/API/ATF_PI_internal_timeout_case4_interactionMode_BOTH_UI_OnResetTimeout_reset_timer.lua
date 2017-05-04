---------------------------------------------------------------------------------------------
-- Requirement summary: 
-- [APPLINK-19427]: [PerformInteraction]: SDL must wait response for both UI and VR components 
-- [APPLINK-28014]: [PerformInteraction] SDL must increase <timeout> param for MANUAL_ONLY and BOTH modes

-- Description:
-- SDL resets <default watchdog timeout> for UI when receiving OnResetTimeout() during timeout is not expired

-- Preconditions:
-- 1. App is registered and activated
-- 2. A choiceset is created

-- Steps:
-- 1. App -> SDL: PerformInteraction (timeout, params, mode: BOTH)
-- 2. SDL -> HMI: VR.PerformInteraction (params, timeout)// with grammarID
-- 3. SDL does not start the timeout for VR
-- 4. SDL -> HMI: UI.PerformInteraction (params, timeout)
-- 5. No user action on VR
-- 6. HMI closes VR session as TIMED_OUT
-- 7. SDL starts <default watchdog timeout> + < timeout_requested_by_app >*2 for UI
-- 8. No user action on UI
-- 9. HMI -> SDL: OnResetTimeout () during timeout is not expired
-- 10. SDL resets <default watchdog timeout> for UI
-- 11. HMI resets timeout until user action
-- 12. User chose an option
-- 13. HMI -> SDL: UI.PerformInteraction (<result_code>, choiceID)
-- 14. SDL -> App: PerformInteraction (<result_code>, choiceID)
---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')

--[[ Local Variables ]]
local mob_cid, vr_cid, ui_cid, hmi_app_id, vr_response_time, on_reset_time
local default_timeout = common_functions:GetValueFromIniFile("DefaultTimeout")

--[[ Preconditions ]]
common_steps:AddNewTestCasesGroup("Preconditions")
-- An app is registered and activated
common_steps:PreconditionSteps("Preconditions", const.precondition.ACTIVATE_APP)
common_steps:PutFile("Preconditions_PutFile_action.png", "action.png")
function Test:Precondition_CreateInteractionChoiceSet_interactionChoiceSetID_1()
  cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
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

function Test:Step_1_4_Mobile_Sends_Request_PerformInteraction_BOTH_timeout_5000()
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

function Test:Step_5_7_VR_Started()
  hmi_app_id = common_functions:GetHmiAppId(const.default_app.appName, self)
  self.hmiConnection:SendNotification("VR.Started")						
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
end

function Test:Step_5_7_TTS_Started_initialPrompt()
  self.hmiConnection:SendNotification("TTS.Started")	
end

function Test:Step_5_7_UI_OnSystemContext_VRSESSION()
  self.hmiConnection:SendNotification("UI.OnSystemContext",{appID = hmi_app_id, systemContext = "VRSESSION"}) 
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "VRSESSION"})
end

function Test:Step_5_7_TTS_Stopped_initialPrompt()
  self.hmiConnection:SendNotification("TTS.Stopped")
end

function Test:Step_5_7_TTS_Started_timeoutPrompt()
  self.hmiConnection:SendNotification("TTS.Started")	
end

function Test:Step_5_7_TTS_Stopped_timeoutPrompt()
  self.hmiConnection:SendNotification("TTS.Stopped")  
end

function Test:Step_5_7_VR_Responds_TIMED_OUT_SDL_Start_Timer()
  self.hmiConnection:SendError(vr_cid, "VR.PerformInteraction", "TIMED_OUT", "VR error message")
  vr_response_time = timestamp()
  -- display date time
  common_functions:UserPrint(const.color.green, "=====Time when HMI sends VR.PerformInteraction response and SDL start timer=====")
  os.execute("date")  
end

function Test:Step_5_7_VR_Stopped()
  self.hmiConnection:SendNotification("VR.Stopped") 
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "VRSESSION"})
end

function Test:Step_5_7_UI_display_Choices_OnSystemContext_HMI_OBSCURED()
 --Choice icon list is displayed
  self.hmiConnection:SendNotification("UI.OnSystemContext",{appID = hmi_app_id, systemContext = "HMI_OBSCURED"}) 
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "HMI_OBSCURED"}) 
end

function Test:Step_8_10_UI_OnResetTimeout_SDL_Restart_Timer()
  -- 8. No user action on UI
  -- 9. HMI -> SDL: OnResetTimeout () during timeout is not expired
  -- 10. SDL resets <default watchdog timeout> for UI  
  local timeout_after_reset = default_timeout + 5000*2
  common_functions:UserPrint(const.color.green, "[INFO] This step takes about " .. tostring(timeout_after_reset - 2000) .. " miliseconds. Please wait!")
  local on_reset_time = timestamp()
  local interval = on_reset_time - vr_response_time
  if (interval <= 19000) then
    local wait_more_time = math.floor((19000 - interval)/1000) -- unit is second
    os.execute("sleep " .. tostring(wait_more_time))
  end  
  common_functions:UserPrint(const.color.green, "=====Time when HMI sends UI.PerformInteraction response=====")
  os.execute("date")
  
  
  common_functions:DelayedExp(timeout_after_reset - 2000) -- -2s to make sure that timeout has not happened.
  self.hmiConnection:SendNotification("UI.OnResetTimeout", {appID = hmi_app_id, methodName = "UI.PerformInteraction"})  
  -- SDL does not respond PerformInteraction to mobile
  EXPECT_RESPONSE("PerformInteraction")
  :Times(0)
end

function Test:Step_11_UI_OnResetTimeout_SDL_Restart_Timer_one_more_time()
  -- 11. HMI resets timeout until user action
  local timeout_after_reset = default_timeout + 5000*2
  common_functions:UserPrint(const.color.green, "[INFO] This step takes about " .. tostring(timeout_after_reset - 2000) .. " miliseconds. Please wait!")
  common_functions:DelayedExp(timeout_after_reset - 2000) -- -2s to make sure that timeout has not happened.
  self.hmiConnection:SendNotification("UI.OnResetTimeout", {appID = hmi_app_id, methodName = "UI.PerformInteraction"})  
  -- SDL does not respond PerformInteraction to mobile
  EXPECT_RESPONSE("PerformInteraction")
  :Times(0)
end

function Test:Step_12_14_UI_PerformInteraction()
  -- 12. User chose an option
  -- 13. HMI -> SDL: UI.PerformInteraction (<result_code>, choiceID)
  self.hmiConnection:SendResponse(ui_cid, "UI.PerformInteraction", "SUCCESS", {choiceID = 1}) 
  -- 14. SDL -> App: PerformInteraction (<result_code>, choiceID)
  EXPECT_RESPONSE(mob_cid, {success = true, resultCode = "SUCCESS", triggerSource = "MENU", choiceID = 1})
end

function Test:Step_12_14_UI_close_pop_up_OnSystemContext_MAIN()
  self.hmiConnection:SendNotification("UI.OnSystemContext",{appID = hmi_app_id, systemContext = "MAIN"}) 
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
end

---------------------------------------------------------------------------------------------
--[[ Postconditions ]]
common_steps:AddNewTestCasesGroup("Postconditions")
local app_name = const.default_app.appName
common_steps:UnregisterApp("Postcondition_UnRegisterApp", app_name)
common_steps:StopSDL("Postcondition_StopSDL")
