------------------------------------General Settings for Configuration--------------------------------
require('user_modules/all_common_modules')
local common_functions_ccs_off = require('user_modules/ATF_Policies_CCS_ON_OFF_common_functions')

---------------------------------------Common Variables-----------------------------------------------
local id_group_1
local policy_file = config.pathToSDL .. "storage/policy.sqlite"

---------------------------------------Preconditions--------------------------------------------------
-- Start SDL and register application
common_functions_ccs_off:PreconditonSteps("mobileConnection","mobileSession")
-- Activate application
common_steps:ActivateApplication("Activate_Application_1", config.application1.registerAppInterfaceParams.appName)

------------------------------------------Tests-------------------------------------------------------
-- TEST 01:
-- In case:
-- SDL Policies database omits "disallowed_by_ccs_entities_off" or "disallowed_by_ccs_entities_on" param in "functional grouping" section
-- and SDL gets SDL.OnAppPermissionConsent ("ccsStatus: OFF")
-- and registered application has this "functional grouping" assigned,
-- SDL must process requested RPCs from "functional groupings" assigned to mobile app in terms of user_consent and data_consent policies rules
--------------------------------------------------------------------------
-- Test 01.01:
-- Description: disallowed_by_ccs_entities_on/off is omitted. HMI -> SDL: OnAppPermissionConsent(ccsStatus OFF, function allowed)
-- Expected Result: requested RPC is allowed by user consent
--------------------------------------------------------------------------
-- Precondition:
-- Prepare JSON file with consent groups. Add all consent group names into app_polices of applications
-- Request Policy Table Update.
--------------------------------------------------------------------------
Test[TEST_NAME_OFF.."Precondition_Update_Policy_Table"] = function(self)
  -- create PTU from localPT
  local data = common_functions_ccs_off:ConvertPreloadedToJson()
  data.policy_table.module_config.preloaded_pt = false
  -- insert Group001 into "functional_groupings"
  data.policy_table.functional_groupings.Group001 = {
    user_consent_prompt = "ConsentGroup001",
    -- omit disallowed_by_ccs_entities_on/off
    rpcs = {
      SubscribeWayPoints = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}
      }
    }
  }
  -- insert Group002 into "functional_groupings"
  data.policy_table.functional_groupings.Group002 = {
    user_consent_prompt = "ConsentGroup002",
    disallowed_by_ccs_entities_off = {{
        entityType = 2,
        entityID = 5
    }},
    rpcs = {
      SubscribeVehicleData = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}
      }
    }
  }
  --insert application "0000001" into "app_policies"
  data.policy_table.app_policies["0000001"] = {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = {"Base-4", "Group001", "Group002"}
  }
  --insert "ConsentGroup001" into "consumer_friendly_messages"
  data.policy_table.consumer_friendly_messages.messages["ConsentGroup001"] = {languages = {}}
  data.policy_table.consumer_friendly_messages.messages.ConsentGroup001.languages["en-us"] = {
    tts = "tts_test",
    label = "label_test",
    textBody = "textBody_test"
  }
  --insert "ConsentGroup002" into "consumer_friendly_messages"
  data.policy_table.consumer_friendly_messages.messages["ConsentGroup002"] = {languages = {}}
  data.policy_table.consumer_friendly_messages.messages.ConsentGroup002.languages["en-us"] = {
    tts = "tts_test",
    label = "label_test",
    textBody = "textBody_test"
  }
  -- create json file for Policy Table Update
  common_functions_ccs_off:CreateJsonFileForPTU(data, "/tmp/ptu_update.json", "/tmp/ptu_update_debug.json")
  -- update policy table
  common_functions_ccs_off:UpdatePolicy(self, "/tmp/ptu_update.json")
  --common_functions:DelayedExp(5000)
end

--------------------------------------------------------------------------
-- Precondition:
-- Check GetListOfPermissions response with empty ccsStatus array list. Get group id.
--------------------------------------------------------------------------
Test[TEST_NAME_OFF.."Precondition_GetListOfPermissions"] = function(self)
  --hmi side: sending SDL.GetListOfPermissions request to SDL
  local request_id = self.hmiConnection:SendRequest("SDL.GetListOfPermissions")
  -- hmi side: expect SDL.GetListOfPermissions response
  EXPECT_HMIRESPONSE(request_id,{
      result = {
        code = 0,
        method = "SDL.GetListOfPermissions",
        allowedFunctions = {{name = "ConsentGroup001", allowed = nil}},
        ccsStatus = {}
      }
    })
  :Do(function(_,data)
      id_group_1 = common_functions_ccs_off:GetGroupId(data, "ConsentGroup001")
    end)
end

--------------------------------------------------------------------------
-- Precondition:
-- HMI sends OnAppPermissionConsent with ccs status = OFF and consented function = allowed
--------------------------------------------------------------------------
Test[TEST_NAME_OFF .. "Precondition_HMI_sends_OnAppPermissionConsent"] = function(self)
  hmi_app_id_1 = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)
  -- hmi side: sending SDL.OnAppPermissionConsent for applications
  self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
      appID = hmi_app_id_1, source = "GUI",
      ccsStatus = {{entityType = 2, entityID = 5, status = "OFF"}},
      consentedFunctions = {{name = "ConsentGroup001", id = id_group_1, allowed = true}}
    })
  self.mobileSession:ExpectNotification("OnPermissionsChange")
  :Times(1)
  common_functions:DelayedExp(2000)
end

--------------------------------------------------------------------------
-- Main check:
-- Check consent_group in Policy Table: is_consented = 1
--------------------------------------------------------------------------
Test[TEST_NAME_OFF .. "MainCheck_Check_Consent_Group"] = function(self)
  local sql_query = "SELECT is_consented FROM consent_group WHERE application_id = '0000001' and functional_group_id = 'Group001';"
  local result = common_functions_ccs_off:QueryPolicyTable(policy_file, sql_query)
  print(" \27[33m group consent = " .. tostring(result) .. ". \27[0m ")
  if result ~= "1" then
    self.FailTestCase("Incorrect consent status.")
  end
end

--------------------------------------------------------------------------
-- Main check:
-- Check ccs_consent_group in Policy Table: not exist
--------------------------------------------------------------------------
Test[TEST_NAME_OFF .. "MainCheck_Check_Ccs_Consent_Group"] = function(self)
  local sql_query = "SELECT is_consented FROM ccs_consent_group WHERE application_id = '0000001' and functional_group_id = 'Group001';"
  local result = common_functions_ccs_off:QueryPolicyTable(policy_file, sql_query)
  print(" \27[33m ccs consent = " .. tostring(result) .. ". \27[0m ")
  if result ~= nil then
    self.FailTestCase("Incorrect ccs consent status.")
  end
end

--------------------------------------------------------------------------
-- Main check:
-- RPC is allowed to process.
--------------------------------------------------------------------------
Test[TEST_NAME_OFF .. "MainCheck_RPC_is_allowed"] = function(self)
  --mobile side: send SubscribeWayPoints request
  local corid = self.mobileSession:SendRPC("SubscribeWayPoints",{})
  --hmi side: expected SubscribeWayPoints request
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
  :Do(function(_,data)
      --hmi side: sending Navigation.SubscribeWayPoints response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
    end)
  --mobile side: SubscribeWayPoints response
  EXPECT_RESPONSE("SubscribeWayPoints", {success = true , resultCode = "SUCCESS"})
  EXPECT_NOTIFICATION("OnHashChange")
end

--------------------------------------Postcondition------------------------------------------
Test["Stop_SDL"] = function(self)
  StopSDL()
end