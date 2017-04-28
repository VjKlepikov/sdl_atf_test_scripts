---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-17039]: [Establishing and Ending Communication]:
-- In case app successfully registered SDL must allow to start audio services
-- [APPLINK-17040]: [Establishing and Ending Communication]:
-- In case app successfully registered SDL must allow to stop audio services

-- Description:
-- SDL Must be able to Stream audio to HMI via pipe

-- Preconditions:
-- 1. StartStreamRetry = 3, 1000 in smartDeviceLink.ini
-- 2. AudioStreamConsumer = pipe in smartDeviceLink.ini
-- 3. ForceProtectedService = Non in smartDeviceLink.ini
-- 4. App with appHMIType = NAVIGATION, isMedia = false
--  is registered and activated over protocol version = 3

-- Steps:
-- 1. Start Audio Service
-- 2. Start Audio Stream
-- 3. Stop Audio Stream
-- 4. Stop Audio Service

-- Expected result:
-- SDL -> Mob: Start Service ACK
-- SDL -> HMI: Navigation.StartAudioStream
-- SDL -> HMI: Navigation.OnAudioDataStreaming with available = true
-- SDL -> Mob: Stop Service ACK
-- SDL -> HMI: Navigation.OnAudioDataStreaming with available = false
-- SDL -> HMI: Navigation.StopAudioStream
---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')

const.default_app.isMediaApplication = false
const.default_app.appHMIType = { "NAVIGATION" }
config.defaultProtocolVersion = 3

---------------------------------------------------------------------------------------------
--[[ Preconditions ]]
common_steps:SetValuesInIniFile("Precondition_Update_StartStreamRetry_To_3_1000",
  "%p?StartStreamRetry%s? = %s-[%w,%s]-%s-\n", "StartStreamRetry", "3, 1000")
common_steps:SetValuesInIniFile("Precondition_Update_AudioStreamConsumer_To_pipe",
  "AudioStreamConsumer%s? = %s-[%w]-%s-\n", "AudioStreamConsumer", "pipe")
common_steps:SetValuesInIniFile("Precondition_Update_ForceProtectedService_To_Non",
  "ForceProtectedService%s? = %s-[%w,%s]-%s-\n", "ForceProtectedService", "Non")
common_steps:PreconditionSteps("Precondition", const.precondition.ACTIVATE_APP)

---------------------------------------------------------------------------------------------
--[[ Test SDL streams audio to HMI via pipe ]]
function Test:TestStep_StartAudio()
  self.mobileSession:StartService(10) -- start Audio Service
  EXPECT_HMICALL("Navigation.StartAudioStream")
  :Do(function(_, data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})         

    local function ToRun()
      self.mobileSession:StartStreaming(10, "files/Kalimba.mp3")
    end
    RUN_AFTER(ToRun, 300)
  end)

  EXPECT_HMINOTIFICATION("Navigation.OnAudioDataStreaming", { available = true })

  common_functions:DelayedExp(2000)
end

function Test:TestStep_StopAudio()
  self.mobileSession:StopStreaming("files/Kalimba.mp3")
  self.mobileSession:StopService(10) -- stop Audio Service

  EXPECT_HMICALL("Navigation.StopAudioStream")
  :Do(function(_, data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})         
  end)

  EXPECT_HMINOTIFICATION("Navigation.OnAudioDataStreaming", { available = false })
end

--[[ TODO ]]
-- AFT Feature for Reading data during stream [APPLINK-18896] is not yet implementted
-- The only way to verify data is written is by checking .log
-- Change Verification step when APPLINK-18896 is implemented.
-- If "bytes of data have been written to pipe" message is changed in log this
-- will result in FAIL of test.
function Test:TestStep_VerifyDataIsWrittenToPipe()
  local logFileContent = io.open(tostring(config.pathToSDL) .. "SmartDeviceLinkCore.log", "r")
  :read("*all")

  if not string.find(logFileContent, "%d+ bytes of data have been written to pipe")
  then
    self:FailTestCase("Nothing written to pipe file")
  end
end

---------------------------------------------------------------------------------------------
--[[ Postconditions ]]
common_steps:StopSDL("Postcondition_StopSDL")
