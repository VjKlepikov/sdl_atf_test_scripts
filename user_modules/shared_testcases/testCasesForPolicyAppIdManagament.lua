---------------------------------------------------------------------------------------------
-- Policy: AppID Management common module
---------------------------------------------------------------------------------------------

local common = {}

local commonFunctions = require("user_modules/shared_testcases/commonFunctions")

local policy_file_path = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")
local policy_file_name = "PolicyTableUpdate"

----------------------------------------------------------------------------------------------------------------------------
-- The function is used only in case when PTU PROPRIETARY should have as result: UP_TO_DATE
-- The funcion will be used when PTU is triggered.
-- 1. It is assumed that notification is recevied: EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})
-- 2. It is assumed that request/response is received: EXPECT_HMICALL("BasicCommunication.PolicyUpdate",
-- 3. Function will use default endpoints
-- Difference with PROPRIETARY flow is clarified in "Can you clarify is PTU flows for External_Proprietary and Proprietary have differences?"
-- But this should be checked in appropriate scripts
--TODO(istoimenova): functions with External_Proprietary should be merged at review of common functions.
function common:updatePolicyTable(test, file)
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status = "UPDATING" }, { status = "UP_TO_DATE" }):Times(2)
  local requestId = test.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  EXPECT_HMIRESPONSE(requestId, {result = {code = 0, method = "SDL.GetURLS", urls = {{url = "http://policies.telematics.ford.com/api/policies"}}}})
  :Do(function(_, _)
      test.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", { requestType = "PROPRIETARY", fileName = policy_file_name })

      EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
      :Do(function(_, _)

          local corIdSystemRequest = test.mobileSession:SendRPC("SystemRequest",
            {
              requestType = "PROPRIETARY",
              fileName = policy_file_name
            },
            file)
          EXPECT_HMICALL("BasicCommunication.SystemRequest",{requestType = "PROPRIETARY", fileName = policy_file_path.."/"..policy_file_name },file)
          :Do(function(_, data)
              test.hmiConnection:SendResponse(data.id, "BasicCommunication.SystemRequest", "SUCCESS", {})
              test.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
                {
                  policyfile = policy_file_path.."/"..policy_file_name
                }
              )
            end)

          EXPECT_RESPONSE(corIdSystemRequest, { success = true, resultCode = "SUCCESS"})
          :Do(function(_, _)
              -- requestId = test.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"StatusUpToDate"}})
              -- EXPECT_HMIRESPONSE(requestId)
            end)
        end)

    end)
end

return common