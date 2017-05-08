---------------------------------------------------------------------------------------------
-- Requirement summary: APPLINK-15702 APPLINK-19742
-- [APPLINK-15702]: [Data Resumption]:OnExitAllApplications(SUSPEND) in terms of resumption
-- [APPLINK-19742]: [Unexpected Disconnect]: 9. "unexpectedDisconnect:false" in case of ignition off

-- Description:
-- SDL finishes its working properly by IGNITION_OFF after OnAwakeSDL

-- Preconditions:
-- 1. SDL and HMI are running on system.
-- 2. One App is registered and activated on HMI.
-- 3. App has added 1 sub menu, 1 command and 1 choice set.

-- Steps:
-- 1. HMI --> SDL: OnExitAllApplication (SUSPEND)
-- 2. HMI --> SDL: Sends OnAwakeSDL()
-- 3. HMI --> SDL: OnExitAllApplication (IGNITION_OFF)
-- Expected results:
-- 1. SDL stores resumption data then sends OnSDLPersistenceComplete() to HMI
-- 3.SDL sends OnAppUnregistered() to HMI
-- -- SDL sends to HMI OnSDLClose and stops working.
-- -- SDL sends to mobile OnAppInterfaceUnregistered (IGNITION_OFF)

---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')

--[[ Local variables]]
local grammarIDValue
local request_AddSubMenu =
{
  menuID = 1,
  position = 500,
  menuName = "SubMenupositive1"
}
local request_AddCommand =
{
  cmdID = 1,
  menuParams =
  {
    position = 0,
    menuName ="Command1",
    parentID = 0
  },
  vrCommands = {"VRCommand1"}
}
local request_ChoiceSet =
{
  interactionChoiceSetID = 1,
  choiceSet =
  {
    {
      choiceID = 1,
      menuName = "Choice1",
      vrCommands =
      {
        "VrChoice1",
      }
    }
  }
}

--[[ Preconditions ]]
common_steps:AddNewTestCasesGroup("Preconditions")
common_steps:PreconditionSteps("Precondition",const.precondition.ACTIVATE_APP)

function Test:Precondition_AddSubMenu()
  local cid = self.mobileSession:SendRPC("AddSubMenu", request_AddSubMenu)
  EXPECT_HMICALL("UI.AddSubMenu",
    {
      menuID = 1,
      menuParams = {
        position = 500,
        menuName = "SubMenupositive1"
      }
    })
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  :Do(function()
      EXPECT_NOTIFICATION("OnHashChange")
      :Do(function(_, data)
          self.currentHashID = data.payload.hashID
        end)
    end)
end

function Test:Precondition_AddCommand()
  local cid = self.mobileSession:SendRPC("AddCommand", request_AddCommand)
  EXPECT_HMICALL("UI.AddCommand",
    {
      cmdID = 1,
      menuParams =
      {
        position = 0,
        menuName ="Command1"
      }
    })
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)

  EXPECT_HMICALL("VR.AddCommand",
    {
      cmdID = 1,
      type = "Command",
      vrCommands =
      {
        "VRCommand1"
      }
    })
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  -- :Do(function(_,data)
  EXPECT_NOTIFICATION("OnHashChange")
  :Do(function(_, data)
      self.currentHashID = data.payload.hashID
    end)
  -- end)
end

function Test:Precondition_CreateInteractionChoiceSet()
  local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",request_ChoiceSet)
  EXPECT_HMICALL("VR.AddCommand",
    {
      cmdID = 1,
      appID = self.applications[const.default_app.appName],
      type = "Choice",
      vrCommands = {"VrChoice1"}
    })
  :Do(function(_,data)
      grammarIDValue = data.params.grammarID
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  :Do(function(_,data)
      EXPECT_NOTIFICATION("OnHashChange")
      :Do(function(_, data)
          self.currentHashID = data.payload.hashID
        end)
    end)
end

--[[ Test ]]
common_steps:AddNewTestCasesGroup("Tests")

function Test:OnExitAllApplication_SUSPEND()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {reason = "SUSPEND"})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
end

function Test:SDLStoresResumptionDataInAppInfoDatAfterSUSPEND()
  local resumptionAppData
  local resumptionDataTable
  local file_exist = false
  local count_sleep = 1
  path_file = config.pathToSDL .."app_info.dat"

  -- Check file "app_info.dat" is exist in 9 seconds
  while file_exist == false and count_sleep < 9 do
    file_exist = common_functions:IsFileExist(path_file)
    if not file_exist then
      os.execute("sleep 1")
      count_sleep = count_sleep + 1
    else
      file_exist = true
    end
  end

  if not file_exist then
    self:FailTestCase("File app_info.dat is not exist")
    return
  end

  -- Check data saved in "app_info.dat"
  local file = io.open(path_file, r)
  local resumptionfile = file:read("*a")
  local resumptionDataTable = json.decode(resumptionfile)

  -- Check resume_app_list is exist
  for p = 1, #resumptionDataTable.resumption.resume_app_list do
    if resumptionDataTable.resumption.resume_app_list[p].appID == const.default_app.appID then
      resumptionAppData = resumptionDataTable.resumption.resume_app_list[p]
    end
  end

  -- Check resume_app_list is not exist
  if not resumptionAppData then
    self:FailTestCase("resume_app_list for app is not exist")
    return
  end

  -- Check AddSubmenu is saved in "app_info.dat"
  if not resumptionAppData.applicationSubMenus then
    self:FailTestCase("applicationSubMenus is not exist in resumption data for app")
    return
  end

  if #resumptionAppData.applicationSubMenus > 1 then
    self:FailTestCase("Wrong number of SubMenus saved in app_info.dat " .. tostring(#resumptionAppData.applicationSubMenus) .. ", expected 1")
    return
  end

  if not common_functions:CompareTablesNotSorted(request_AddSubMenu,resumptionAppData.applicationSubMenus[1]) then
    self:FailTestCase("Wrong data of SubMenus saved in app_info.dat ")
    return
  end

  -- Check AddCommand is saved in "app_info.dat"
  if not resumptionAppData.applicationCommands then
    self:FailTestCase("applicationCommands is not exist in resumption data for app")
    return
  end

  if #resumptionAppData.applicationCommands > 1 then
    self:FailTestCase("Wrong number of AddCommands saved in app_info.dat " .. tostring(#resumptionAppData.applicationCommands) .. ", expected 1")
    return
  end

  if not common_functions:CompareTablesNotSorted(request_AddCommand,resumptionAppData.applicationCommands[1]) then
    self:FailTestCase("Wrong data of AddCommands saved in app_info.dat ")
    return
  end

  -- Check ChoiceSet is saved in "app_info.dat"
  if not resumptionAppData.applicationChoiceSets then
    self:FailTestCase("applicationChoiceSets is not exist in resumption data for app")
    return
  end

  if #resumptionAppData.applicationChoiceSets > 1 then
    self:FailTestCase("Wrong number of ChoiceSets saved in app_info.dat " .. tostring(#resumptionAppData.applicationChoiceSets) .. ", expected 1")
    return
  end

  request_ChoiceSet.grammarID = grammarIDValue
  if not common_functions:CompareTablesNotSorted(request_ChoiceSet,resumptionAppData.applicationChoiceSets[1]) then
    self:FailTestCase("Wrong data of ChoiceSets saved in app_info.dat ")
    return
  end

end

function Test:OnAwakeSDL()
  self.hmiConnection:SendNotification("BasicCommunication.OnAwakeSDL",{})
  common_functions:DelayedExp(5000)
end

function Test:OnExitAllApplication_IGNITION_OFF()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",{reason = "IGNITION_OFF"})
  EXPECT_NOTIFICATION("OnAppInterfaceUnregistered",{reason="IGNITION_OFF"})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
  -- remove sdl.pid avoid SDL crashed
  if common_functions:IsFileExist("sdl.pid") then
    os.remove("sdl.pid")
  end
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")
end
