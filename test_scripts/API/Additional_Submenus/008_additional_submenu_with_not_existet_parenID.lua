---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0148-template-additional-submenus.md#backwards-compatibility
-- Description: Draft (Under Clarification)
-- In case:
-- 1) Mobile application is set to appropriate HMI level and System Context MENU, MAIN
-- 2) Mobile sends additional AddSubMenu request with non-existent parentID = 1
-- SDL does:
-- 1) Sends AddSubMenu( resultCode: INVALID_ID, success=false ) response to App
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Additional_Submenus/additional_submenus_common')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParam = {
  menuID = 99,
  menuName = "SubMenu2",
  parentID = 1
}

local function addSubMenu(requestParams)
    common.getHMIConnection():ExpectRequest("UI.AddSubMenu")
    :Times(0)
    local cid = common.getMobileSession():SendRPC("AddSubMenu", requestParams)
    common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "INVLID_ID" })
    common.getMobileSession():ExpectNotification("OnHashChange")
    :Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)

runner.Title("Test")
runner.Step("App activate, HMI SystemContext MAIN", common.activateApp)
runner.Step("Add submenu", addSubMenu, { requestParam })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
