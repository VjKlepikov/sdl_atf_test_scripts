---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-15604]:[HMILevel Resumption]: Conditions to resume app to FULL after "unexpected disconnect" event.

-- Description:
-- Check that SDL resumes App's data after unexpected disconnect.

-- Preconditions:
-- 1. App is registered and activated on HMI.
-- 2. App has added 1 sub menu, 1 command and 1 choice set.

-- Steps:
-- 1. Turn off transport on Mobile device.
-- 2. Turn on transport on Mobile device.

-- Expected behavior:
-- 1. App is unregistered.
-- 2. App is registered successfully, SDL resumes all App data and sends BC.ActivateApp to HMI. App gets FULL HMI Level.

----------------------------- Required Shared Libraries ------------------------------------
require('user_modules/all_common_modules')

------------------------------------ Precondition ------------------------------------------
const.default_app.audioStreamingState = "AUDIBLE"
common_steps:AddNewTestCasesGroup("Preconditions")
common_steps:PreconditionSteps("Preconditions", const.precondition.ACTIVATE_APP)

function Test:Preconditions_AddSubmenu_SUCCESS()
  self.menuID = 100
  local cid = self.mobileSession:SendRPC("AddSubMenu",
    {
      menuID = self.menuID,
      menuName = "SubMenu_" .. tostring(self.menuID)
    })
  EXPECT_HMICALL("UI.AddSubMenu",
    {
      menuID = self.menuID,
      menuParams = {
        menuName = "SubMenu_" .. tostring(self.menuID)
      }
    })
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
  EXPECT_NOTIFICATION("OnHashChange")
end

function Test:Preconditions_AddCommand_SUCCESS()
  self.cmdID = 200
  local cid = self.mobileSession:SendRPC("AddCommand", {
      cmdID = self.cmdID,
      menuParams = {menuName = "menuName_" .. tostring(self.cmdID)}})
  EXPECT_HMICALL("UI.AddCommand", {cmdID = self.cmdID})
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
  EXPECT_NOTIFICATION("OnHashChange")
end

function Test:Preconditions_CreateInteractionChoiceSet_SUCCESS()
  self.choiceID = 300
  local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet", {
      interactionChoiceSetID = 1,
      choiceSet = {{
          choiceID = self.choiceID,
          menuName = "Choice_" .. tostring(self.choiceID),
          vrCommands = {"Choice_" .. tostring(self.choiceID)},}}})
  EXPECT_HMICALL("VR.AddCommand", {
      cmdID = self.choiceID,
      appID = common_functions:GetHmiAppId(const.default_app.appName, self),
      type = "Choice",
      vrCommands = {"Choice_" .. tostring(self.choiceID)}})
  :Do(function(_,data)
      grammarIDValue = data.params.grammarID
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
  EXPECT_NOTIFICATION("OnHashChange")
  :Do(function(_, data)
      self.currentHashID = data.payload.hashID
    end)
end

------------------------------------------- Steps -------------------------------------------
common_steps:AddNewTestCasesGroup("Tests")
common_steps:CloseMobileSession("Turn_off_Transport", "mobileSession")
common_steps:AddMobileSession("Turn_on_Transport")

function Test:TC_SDL_Resume_AppData_After_Unexpected_Disconnect()
  const.default_app.hashID = self.currentHashID
  common_functions:StoreApplicationData("mobileSession", const.default_app.appName, const.default_app, _, self)
  local cid = self.mobileSession:SendRPC("RegisterAppInterface", const.default_app)
  local time = timestamp()
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {resumeVrGrammars = true})
  self.mobileSession:ExpectResponse(cid, {success = true})
  local hmi_appid = common_functions:GetHmiAppId(const.default_app.appName, self)
  EXPECT_HMICALL("BasicCommunication.ActivateApp", {appID = hmi_appid})
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
    end)
  EXPECT_NOTIFICATION("OnHMIStatus",
    {hmiLevel = "NONE", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"},
    {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
  :ValidIf(function(exp,data)
      if exp.occurences == 2 then
        local time2 = timestamp()
        local timeToresumption = time2 - time
        if timeToresumption >= 3000 and timeToresumption < 3500 then
          common_functions:UserPrint(const.color.yellow, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 ")
          return true
        else
          common_functions:UserPrint(const.color.red, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 ")
          return false
        end
      elseif exp.occurences == 1 then
        return true
      end
    end)
  :Times(2)

  EXPECT_HMICALL("UI.AddSubMenu", {
      menuID = self.menuID,
      menuParams = {
        position = 1000,
        menuName = "SubMenu_" .. tostring(self.menuID)
      }
    })

  EXPECT_HMICALL("UI.AddCommand", {
      cmdID = self.cmdID,
      appID = hmi_appid,
      menuParams = {menuName = "menuName_" .. tostring(self.cmdID)}
    })

  EXPECT_HMICALL("VR.AddCommand", {
      cmdID = self.choiceID,
      appID = hmi_appid,
      type = "Choice",
      vrCommands = {"Choice_" .. tostring(self.choiceID)}
    })
end

------------------------------------ Postcondition ------------------------------------------
common_steps:AddNewTestCasesGroup("Postconditions")
common_steps:StopSDL("Postcondition_StopSDL")
