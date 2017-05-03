---------------------------------------------------------------------------------------------
-- Requirement summary: 
-- [APPLINK-27301]: [RTC 1015339] [F-S] SDL must start <DefaultTimeout>+<RPCs_internal_timeout> for all RPCs with own timer 
-- [APPLINK-28014]: [PerformInteraction] SDL must increase <timeout> param for MANUAL_ONLY and BOTH modes

-- Description:
-- SDL does not start timer for PerformInteraction rpc when VR has not responded VR.PerformInteraction() to SDL.
-- as result, SDL does not send PerformInteraction response to mobile.

-- Preconditions:
-- 1. App is registered and activated
-- 2. A choiceset is created

-- Steps and expectations:
-- 1. App -> SDL: PerformInteraction (timeout, params, mode: BOTH)
-- 2. SDL -> HMI: VR.PerformInteraction (params, timeout)// with grammarID
-- 3. SDL does not start the timeout for VR
-- 4. SDL -> HMI: UI.PerformInteraction (params, timeout)
-- 5. No user action on VR
-- 6. HMI keeps VR session opened
-- 7. SDL waits for VR response eternally, does not start the timer for UI and does not send any <result_code> to mobile app

---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')

--[[ Preconditions ]]
common_steps:AddNewTestCasesGroup("Preconditions")
-- An app is registered and activated
common_steps:PreconditionSteps("Preconditions", 7)
common_steps:PutFile("Preconditions_PutFile_action.png", "action.png")
function Test:Precondition_CreateInteractionChoiceSet_ChoiceSetID_1()
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

function Test:Mobile_sends_PerformInteraction_BOTH_and_VR_does_not_respond()
  common_functions:UserPrint(const.color.green, "[INFO] This test case is executed in 60 seconds. Please wait!") 
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
  -- 1. App -> SDL: PerformInteraction (timeout, params, mode: BOTH) 
  local mobile_cid = self.mobileSession:SendRPC("PerformInteraction", request)
  -- 2. SDL -> HMI: VR.PerformInteraction (params, timeout)// with grammarID
  -- 3. SDL does not start the timeout for VR
  -- 5. No user action on VR
  -- 6. HMI keeps VR session opened 
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
    self.hmiConnection:SendNotification("VR.Started")
    self.hmiConnection:SendNotification("TTS.Started")	
    local hmi_app_id = common_functions:GetHmiAppId(const.default_app.appName, self)
    self.hmiConnection:SendNotification("UI.OnSystemContext",{appID = hmi_app_id, systemContext = "VRSESSION"})   
  end)	   
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
  -- 7. SDL waits for VR response eternally, does not start the timer for UI and does not send any <result_code> to mobile app  
  -- If SDL starts timer for UI, SDL will respond when timer is finished (in 10 + 5*2 = 20s)
  -- => check SDL does not send response from 21 to 60 seconds.
  common_functions:DelayedExp(60000) 
  self.mobileSession:ExpectResponse(mobile_cid, {})
  :Times(0)
  --mobile side: OnHMIStatus notification
  EXPECT_NOTIFICATION("OnHMIStatus", 
    {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
    {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "VRSESSION"}
  )
  :Times(2)  
end

---------------------------------------------------------------------------------------------
--[[ Postconditions ]]
common_steps:AddNewTestCasesGroup("Postconditions")
local app_name = const.default_app.appName
common_steps:UnregisterApp("Postcondition_UnRegisterApp", app_name)
common_steps:StopSDL("Postcondition_StopSDL")
