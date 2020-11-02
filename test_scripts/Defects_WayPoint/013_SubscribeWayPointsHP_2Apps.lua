---------------------------------------------------------------------------------------------------
-- User story:
--
-- Description:
--
-- Steps:
--
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects_WayPoint/commonDefects')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }

--[[ Local Variables ]]
local Expected = 1
local NotExpected = 0
local AppId1 = 1
local AppId2 = 2

--[[ Local Functions ]]
local function SubscribeWayPointsSecondApp(pAppId)
  local cid = common.getMobileSession(pAppId):SendRPC("SubscribeWayPoints",{})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints"):Times(0)
  common.getMobileSession(pAppId):ExpectNotification("OnWayPointChange")
  :Times(1)
  common.getMobileSession(pAppId):ExpectResponse(cid, {success = true , resultCode = "SUCCESS"})
  common.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_,data)
      common.getConfigAppParams(pAppId).hashID = data.payload.hashID
    end)
  common.wait(1000)
end

local function UnsubscribeWaySecondApp(pAppId)
  local cid = common.getMobileSession(pAppId):SendRPC("UnsubscribeWayPoints",{})
  EXPECT_HMICALL("Navigation.UnsubscribeWayPoints"):Times(0)
  common.getMobileSession(pAppId):ExpectResponse(cid, {success = true , resultCode = "SUCCESS"})
  common.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_,data)
      common.getConfigAppParams(pAppId).hashID = data.payload.hashID
    end)
  common.wait(1000)
end

local function OnWayPointChange(pTime1, pTime2)
  local notifications = {
    wayPoints = {{
      coordinate = {
        latitudeDegrees = -90,
        longitudeDegrees = -180},
      locationName = "Ho Chi Minh City",
      addressLines = {"182 LDH"},
      locationDescription = "Flemington Building",
      phoneNumber = "1234321",
      searchAddress = {
        countryName = "aaa",
        countryCode = "084",
        postalCode = "test",
        administrativeArea = "aa",
        subAdministrativeArea="a",
        locality="a",
        subLocality="a",
        thoroughfare="a",
        subThoroughfare="a"}}}}
  common.getHMIConnection():SendNotification("Navigation.OnWayPointChange", notifications)
  common.getMobileSession(AppId1):ExpectNotification("OnWayPointChange")
  :Times(pTime1)
  common.getMobileSession(AppId2):ExpectNotification("OnWayPointChange")
  :Times(pTime2)
  common.wait(1000)
end

--[[ Scenario ]]

runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update preloaded_pt", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.startWait)
runner.Step("App1 registration", common.registerApp)
runner.Step("App2 registration", common.registerApp, { AppId2 })
runner.Step("Activate App1", common.activateApp)

runner.Step("SubscribeWayPoints App1", common.SubscribeWayPoints)
runner.Step("Sends OnWayPointChange to App1, doesn't send to App2",
  OnWayPointChange, { Expected, NotExpected })

runner.Title("Test_1")
runner.Step("Activate App2", common.activateApp, { AppId2 })
runner.Step("SubscribeWayPoints App2", SubscribeWayPointsSecondApp, { AppId2 })
runner.Step("Sends OnWayPointChange to App1, App2", OnWayPointChange, { Expected, Expected })

runner.Step("UnsubscribeWayPoints App2", UnsubscribeWaySecondApp, { AppId2 })
runner.Step("Sends OnWayPointChange to App1, doesn't send to App2",
  OnWayPointChange, { Expected, NotExpected })
runner.Step("UnsubscribeWayPoints App1", common.UnsubscribeWayPoints)
runner.Step("Does not sends OnWayPointChange to App1, App2",
  OnWayPointChange, { NotExpected, NotExpected })

runner.Title("Test_2")
runner.Step("SubscribeWayPoints App1", common.SubscribeWayPoints)
runner.Step("Sends OnWayPointChange to App1, doesn't send to App2",
  OnWayPointChange, { Expected, NotExpected })
runner.Step("SubscribeWayPoints App2", SubscribeWayPointsSecondApp, { AppId2 })
runner.Step("Sends OnWayPointChange to App1, App2", OnWayPointChange, { Expected, Expected })

runner.Step("UnsubscribeWayPoints App2", UnsubscribeWaySecondApp, { AppId1 })
runner.Step("Sends OnWayPointChange to App2, doesn't send to App1",
  OnWayPointChange, { NotExpected, Expected })
runner.Step("UnsubscribeWayPoints App1", common.UnsubscribeWayPoints, { AppId2 })
runner.Step("Does not sends OnWayPointChange to App1, App2",
  OnWayPointChange, { NotExpected, NotExpected })

runner.Title("Test_3")
runner.Step("SubscribeWayPoints App1", common.SubscribeWayPoints)
runner.Step("Sends OnWayPointChange to App1, doesn't send to App2",
  OnWayPointChange, { Expected, NotExpected })
runner.Step("SubscribeWayPoints App2", SubscribeWayPointsSecondApp, { AppId2 })
runner.Step("Sends OnWayPointChange to App1, doesn't send to App2",
  OnWayPointChange, { Expected, Expected })
 runner.Step("unexpectedDisconnect with UnsubscribeWayPoints",
    common.unexpectedDisconnectUnsubscribeWayPoints, { Expected })
runner.Step("Connect mobile", common.connectMobile)
runner.Step("App1 registration after disconnect with SubscribeWayPoints",
    common.registerAppSubscribeWayPoints, { AppId1, Expected })
runner.Step("Sends OnWayPointChange to App1, doesn't send to App2",
  OnWayPointChange, { Expected, NotExpected })
runner.Step("App2 registration after disconnect with SubscribeWayPoints",
    common.registerAppSubscribeWayPointsSecond, { AppId2, NotExpected })
runner.Step("Sends OnWayPointChange to App1, to App2",
  OnWayPointChange, { Expected, Expected })

runner.Title("Postconditions")
runner.Step("Clean sessions", common.cleanSessions)
runner.Step("Stop SDL", common.postconditions)

