---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-15657]: [Data Resumption]: Data resumption on Unexpected Disconnect

-- Description:
-- Check that SDL perform resumption with a big amount of data after unexpected disconnect.

-- Preconditions:
-- 1. App is registered and activated
-- 2. AddSubmenu, AddCommand, CreateInteractionChoiceSet, SubscribeButton, SubscribeVehicleData are allowed for app

-- Steps:
-- 1. Add 20 submenus
-- 2. Add 20 commands
-- 3. Add 20 interation choice set
-- 4. Send SubscribeButton for all buttons
-- 5. Send SubscribeVehicleData for gps
-- 6. Turn off transport
-- 7. Turn on transport
-- 8. Register app with lastest hashid
-- 9. Send some APIs to verify the resumption of app
-- 9.1 Send Delete Submenu with added menuID in step 1
-- 9.2 Send Delete Command with added cmdIDs in step 2
-- 9.3 Send DeleteInteractionChoiceSet with added interactionChoiceSetIDs in step 3
-- 9.4 Send SubscribeButton(all button) again
-- 9.5 Send SubscribeVehicleData(gps)

-- Expected result:
-- 1. 20 submenus are added
-- 2. 20 commands are added
-- 3. 20 interation choice sets are added
-- 4. all buttons are subscibled
-- 5. gps is subscribled
-- 6. App is disconnected
-- 7. Session is started again
-- 8. App is registered and get full HMI level
-- 9. Results after resumption
-- 9.1 SDL --> application: DeleteSubMenu(SUCCESS)
-- 9.2 SDL --> application: DeleteCommand(SUCCESS)
-- 9.3 SDL --> application: DeleteInterationChoiceSets(SUCCESS)
-- 9.4 SDL --> application: SubscribleButton(resultCode:IGNORED, success:"false")
-- 9.5 SDL --> application: SubscribleVehicleData (success = false, resultCode = "IGNORED", gps = {dataType = "VEHICLEDATA_GPS", resultCode = "DATA_ALREADY_SUBSCRIBED"}, info = "Already subscribed on some provided VehicleData.")

-------------------------------------------------------------------------------
require('user_modules/all_common_modules')
local app_name = config.application1.registerAppInterfaceParams.appName
-------------------------------------------------------------------------------
common_steps:AddNewTestCasesGroup("Preconditions")
update_policy:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/PTU_For_SmokeTesting.json")
-- An app is registered and activated
common_steps:PreconditionSteps("Preconditions", const.precondition.ACTIVATE_APP)
-------------------------------------------------------------------------------
common_steps:AddNewTestCasesGroup("Tests_Step1_Add_20_Submenus")
for i = 1, 20 do
  Test["AddSubMenu_MenuID_" .. tostring(i).."_SUCCESS"] = function(self)
    --mobile side: sending AddSubMenu request
    local cid = self.mobileSession:SendRPC("AddSubMenu",
    {
      menuID = i,
      menuName ="SubMenumandatoryonly_"..tostring(i )
    })
    EXPECT_HMICALL("UI.AddSubMenu",
    {
      menuID = i,
      menuParams = {
        menuName ="SubMenumandatoryonly_"..tostring(i )
      }
    })
    :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
    EXPECT_NOTIFICATION("OnHashChange")
  end
end

common_steps:AddNewTestCasesGroup("Tests_Step2_Add_20_Commands")
for i = 1, 20 do
  Test["AddCommand_Command_ID_" .. tostring(i).."_SUCCESS"] = function(self)
    local cid = self.mobileSession:SendRPC("AddCommand", {
      cmdID = i,
    menuParams = { menuName ="menuName_"..tostring(i)}})
    
    EXPECT_HMICALL("UI.AddCommand", { cmdID = i})
    :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
    EXPECT_NOTIFICATION("OnHashChange")
  end
end

common_steps:AddNewTestCasesGroup("Tests_Step3_Create_20_InteractionChoiceSets")
for i=1, 20 do
  Test["CreateInteractionChoiceSet_Choice_Id_" .. tostring(i)] = function(self)
    local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet", {
      interactionChoiceSetID = i,
        choiceSet = {{
          choiceID = i,
          menuName = "Choice_" .. tostring(i),
    vrCommands = {"Choice_" .. tostring(i)},}}})
    EXPECT_HMICALL("VR.AddCommand", {
      cmdID = i,
      appID = common_functions:GetHmiAppId(app_name, self),
      type = "Choice",
    vrCommands = {"Choice_" .. tostring(i)}})
    :Do(function(_,data)
      grammarIDValue = data.params.grammarID
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
    EXPECT_NOTIFICATION("OnHashChange")
  end
end

common_steps:AddNewTestCasesGroup("Tests_Step4_Subscribe_All_Buttons")
local buttonName = {"OK","SEEKLEFT","SEEKRIGHT","TUNEUP","TUNEDOWN", "PRESET_0","PRESET_1","PRESET_2","PRESET_3","PRESET_4","PRESET_5","PRESET_6","PRESET_7","PRESET_8", "PRESET_9"}
for i=1,#buttonName do
  Test["SubscribeButton_01_05_SubscribeButton_" .. tostring(buttonName[i]).."_SUCCESS"] = function(self)
    local cid = self.mobileSession:SendRPC("SubscribeButton", { buttonName = buttonName[i]})
    EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {appID = self.applications["Test Application"], isSubscribed = true, name = buttonName[i]})
    EXPECT_RESPONSE(cid, {resultCode = "SUCCESS", success = true})
    EXPECT_NOTIFICATION("OnHashChange")
  end
end

common_steps:AddNewTestCasesGroup("Tests_Step5_SubscribeVehicleData_For_GPS")
function Test:SubscribeVehicleData_For_GPS_SUCCESS()
  local cid = self.mobileSession:SendRPC("SubscribeVehicleData",{gps = true})
  EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true})
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { gps = {resultCode = "SUCCESS",dataType = "VEHICLEDATA_GPS"}
    })
  end)
  EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
  EXPECT_NOTIFICATION("OnHashChange")
  :Do(function(_, data)
    self.currentHashID = data.payload.hashID
  end)
end

common_steps:AddNewTestCasesGroup("Tests_Step6_Turn_Off")
common_steps:CloseMobileSession("Turn_off_Transport", "mobileSession")

common_steps:AddNewTestCasesGroup("Tests_Step7_Turn_On")
common_steps:AddMobileSession("Turn_on_Transport")

common_steps:AddNewTestCasesGroup("Tests_Step8_AppIsResumpedToFullHMILevel")
Test["Register_Resump_App_To_Full_HMILevel"] = function(self)
  config.application1.registerAppInterfaceParams.hashID = self.currentHashID
  common_functions:StoreApplicationData("mobileSession", app_name, config.application1.registerAppInterfaceParams, _, self)
  local correlation_id = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
  local time = timestamp()
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
  self.mobileSession:ExpectResponse(correlation_id, { success = true })
  local hmi_appid = common_functions:GetHmiAppId(app_name, self)
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
      if timeToresumption >= 3000 and
      timeToresumption < 3500 then
        common_functions:UserPrint(const.color.yellow, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 ")
        return true
      else
        common_functions:PrintError("Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 ")
        return false
      end
    elseif exp.occurences == 1 then
      return true
    end
  end)
  :Do(function(_,data)
    self.hmiLevel = data.payload.hmiLevel
  end)
  :Times(2)
end

common_steps:AddNewTestCasesGroup("Tests_Step9.1_SUCCESSS_For_Delete_20_SubMenus")
for i =1, 20 do
  Test["TC_DeleteSubMenu_SubMenuID_" .. tostring(i).."_SUCCESS"] = function(self)
    local cid = self.mobileSession:SendRPC("DeleteSubMenu", { menuID = i})
    EXPECT_HMICALL("UI.DeleteSubMenu", {
      menuID = i,
      appID = common_functions:GetHmiAppId(app_name, self)
    })
    :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
    EXPECT_NOTIFICATION("OnHashChange")
  end
end

common_steps:AddNewTestCasesGroup("Tests_Step9.2_SUCCESSS_For_Delete_20_Commands")
for i = 1, 20 do
  Test["TC_DeleteCommand_CommandID_" .. tostring(i).."_SUCCESS"] = function(self)
    local cid = self.mobileSession:SendRPC("DeleteCommand",{ cmdID = i})
    EXPECT_HMICALL("UI.DeleteCommand",
    {
      cmdID = i,
      appID = common_functions:GetHmiAppId(app_name, self)
    })
    :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
    EXPECT_NOTIFICATION("OnHashChange")
  end
end

common_steps:AddNewTestCasesGroup("Tests_Step9.3_SUCCESSS_For_Delete_20_InterationChoiceSets")
for i = 1, 20 do
  Test["DeleteInteractionChoiceSet_ChoiceID_" .. tostring(i).."_SUCCESS"] = function(self)
    common_functions:DelayedExp(5000)
    local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",{interactionChoiceSetID = i})
    EXPECT_HMICALL("VR.DeleteCommand",
    {cmdID = i,
      type = "Choice",
      grammarID = data.params.grammarID,
      appID = common_functions:GetHmiAppId(app_name, self)
    }
    )
    :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
    EXPECT_NOTIFICATION("OnHashChange")
  end
end

common_steps:AddNewTestCasesGroup("Tests_Step9.4_IGNORED_For_SubscribeButton_AllButtons")
for i=1,#buttonName do
  Test["TC_SubscribeButton_01_05_SubscribeButton_" .. tostring(buttonName[i]).."_IGNORED"] = function(self)
    local cid = self.mobileSession:SendRPC("SubscribeButton", {
    buttonName = buttonName[i]})
    EXPECT_RESPONSE(cid, {success = false, resultCode = "IGNORED"})
    EXPECT_NOTIFICATION("OnHashChange")
    :Times(0)
  end
end

common_steps:AddNewTestCasesGroup("Tests_Step9.5_IGNORED_For_SubscribeVehicleData_GPS")
function Test:SubscribeVehicleData_For_GPS_IGNORED()
  local cid = self.mobileSession:SendRPC("SubscribeVehicleData",{gps = true})
  EXPECT_RESPONSE(cid, {success = false, resultCode = "IGNORED", gps = {dataType = "VEHICLEDATA_GPS", resultCode = "DATA_ALREADY_SUBSCRIBED"}, info = "Already subscribed on some provided VehicleData."})
  EXPECT_NOTIFICATION("OnHashChange")
  :Times(0)
end

common_steps:AddNewTestCasesGroup("Postconditions")
common_steps:UnregisterApp("Postcondition_UnRegisterApp", app_name)
common_steps:StopSDL("Postcondition_StopSDL")
