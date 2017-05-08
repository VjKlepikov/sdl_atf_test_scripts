---------------------------------------------------------------------------------------------
-- Requirement summary: 
-- [APPLINK-19427]: [PerformInteraction]: SDL must wait response for both UI and VR components 
-- [APPLINK-28014]: [PerformInteraction] SDL must increase <timeout> param for MANUAL_ONLY and BOTH modes
-- [APPLINK-14566]: [SDL - HMI relations]: SDL behavior: in case HMI responds the "message" param to HMI interfaces

-- Description:
-- SDL responds TIMED_OUT when VR and UI respond TIMED_OUT during watchdog timeout in BOTH mode.

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
-- 10. SDL resets <default watchdog timeout> + < timeout_requested_by_app >*2 for UI
-- 11. HMI resets timeout until user action
-- 12. HMI closed UI session as TIMED_OUT
-- 13. SDL -> App: PerformInteraction (TIMED_OUT, success:false)

-- Note: In this script, all steps of TTS.Started and TTS.Stopped will be skipped 
-- because they're belong to another component.

---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')

--[[ Local Variables ]]
local mobile_cid, hmi_app_id, hmi_cid_ui, hmi_cid_vr
local params_send = {
  interactionMode = "BOTH",
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
local default_timeout = common_functions:GetValueFromIniFile("DefaultTimeout")
local ui_timeout = default_timeout + params_send.timeout * 2

--[[ Preconditions ]]
common_steps:AddNewTestCasesGroup("Preconditions")
config.application1.registerAppInterfaceParams.isMediaApplication = true
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

---------------------------------------------------------------------------------------------
--[[ Test ]]
common_steps:AddNewTestCasesGroup("Test")  
function Test:Send_PerformInteraction_Request()
  hmi_app_id = common_functions:GetHmiAppId(const.default_app.appName, self)
  -- 1. App -> SDL: PerformInteraction (timeout, params, mode: BOTH)
  mobile_cid = self.mobileSession:SendRPC("PerformInteraction", params_send)
	
  -- 2. SDL -> HMI: VR.PerformInteraction (params, timeout)// with grammarID
  EXPECT_HMICALL("VR.PerformInteraction", 
    {
      helpPrompt = params_send.helpPrompt,
      initialPrompt = params_send.initialPrompt,
      timeout = params_send.timeout,
      timeoutPrompt = params_send.timeoutPrompt
    }
  )					
  :ValidIf(function(_,data)
    if data.params.grammarID then
      return true
    else
      self:FailTestCase("The grammarID does not exist.")
    end
  end)
  :Do(function(_,data)
    hmi_cid_vr = data.id
  end)	

  -- 3. SDL does not start the timeout for VR
  -- 4. SDL -> HMI: UI.PerformInteraction (params, timeout)
  EXPECT_HMICALL("UI.PerformInteraction", 
  {
    timeout = params_send.timeout,
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
      fieldText = params_send.initialText
    }
  })	
  :Do(function(_,data)
    hmi_cid_ui = data.id
  end)  
end

function Test:VR_Started()
  self.hmiConnection:SendNotification("VR.Started")
  self.hmiConnection:SendNotification("UI.OnSystemContext",{
      appID = hmi_app_id, systemContext = "VRSESSION"})
  EXPECT_NOTIFICATION("OnHMIStatus",
  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "VRSESSION"})
  :Times(2)  
end

function Test:Send_VR_Responds_TIMED_OUT()
  -- 5. No user action on VR
  -- 6. HMI closes VR session as TIMED_OUT
  self.hmiConnection:SendError(hmi_cid_vr, 
      "VR.PerformInteraction", "TIMED_OUT", "VR error message")
  vr_time = timestamp() 		
end

function Test:VR_Stopped()
  self.hmiConnection:SendNotification("VR.Stopped")
  EXPECT_NOTIFICATION("OnHMIStatus",
  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "VRSESSION"})
end

function Test:Display_Choices_UI()
  -- 7. SDL starts <default watchdog timeout> + < timeout_requested_by_app >*2 for UI
  -- 8. No user action on UI
  self.hmiConnection:SendNotification("UI.OnSystemContext",{
      appID = hmi_app_id, systemContext = "HMI_OBSCURED"})
  EXPECT_NOTIFICATION("OnHMIStatus",
  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "HMI_OBSCURED"})
end

function Test:Wait_Until_2s_Before_Expire_TimeOut()
  local current_time = timestamp()
  local interval = current_time - vr_time
  common_functions:UserPrint(const.color.green, "Waiting in " .. tostring(ui_timeout - 2000 - interval) .. " miliseconds")
  common_functions:DelayedExp(ui_timeout - 2000 - interval)
end

function Test:UI_Reset_Timeout()
  -- 9. HMI -> SDL: OnResetTimeout () during timeout is not expired
  -- 10. SDL resets <default watchdog timeout> for UI
  self.hmiConnection:SendNotification("UI.OnResetTimeout", {
      appID = hmi_app_id, methodName = "UI.PerformInteraction"})
  reset_time = timestamp()
end

function Test:Wait_Until_2s_Before_Expire_TimeOut_After_Reset()
  local current_time = timestamp()
  local interval = current_time - reset_time
  common_functions:UserPrint(const.color.green, "Waiting in " .. tostring(ui_timeout - 2000 - interval) .. " miliseconds")
  common_functions:DelayedExp(ui_timeout - 2000 - interval)
end

function Test:Send_UI_Responds_TIMED_OUT()
  -- 11. HMI resets timeout until user action
  -- 12. HMI closed UI session as TIMED_OUT
  -- 13. SDL -> App: PerformInteraction (TIMED_OUT, success:false)
  self.hmiConnection:SendError(
      hmi_cid_ui, "UI.PerformInteraction", "TIMED_OUT", "UI error message")
  EXPECT_RESPONSE(mobile_cid, {success = false, resultCode = "TIMED_OUT"})
  :Timeout(ui_timeout + 1000)

  :ValidIf(function(_,data)
    if (data.payload.info == "VR error message, UI error message") or 
        (data.payload.info == "UI error message, VR error message") then
      return true
    else
      self:FailTestCase('Actual "info": "' .. tostring(data.payload.info) ..
          '", expected "info": "VR error message, UI error message".')
    end
  end)
end

---------------------------------------------------------------------------------------------
--[[ Postconditions ]]
common_steps:AddNewTestCasesGroup("Postconditions")
common_steps:UnregisterApp("Postcondition_UnRegisterApp", const.default_app.appName)
common_steps:StopSDL("Postcondition_StopSDL")
