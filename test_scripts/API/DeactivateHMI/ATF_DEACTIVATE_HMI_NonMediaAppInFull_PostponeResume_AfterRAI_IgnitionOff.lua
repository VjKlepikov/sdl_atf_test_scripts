-----------------------------------Test cases----------------------------------------
-- Requirement summary:
-- [APPLINK-16173]:[HMILevel resumption]: SDL must postpone HMILevel resumption in case of DEACTIVATE_HMI mode
-- Description:
-- Checks that SDL postpones resumption of non-media app that was in FULL 
-- and satisfies the conditions of successful HMILevel resumption 
-- if SDL receives BasicCommunication.OnEventChanged("DEACTIVATE_HMI","isActive":true) notification 
-- during "ApplicationResumingTimeout" and receives BasicCommunication.OnEventChanged("eventName":"DEACTIVATE_HMI","isActive":false) 
-- notification after "ApplicationResumingTimeout". 
-- Precondition: 
-- -- 1. Default HMI level = NONE.
-- -- 2. Core and HMI are started.
-- -- 3. These values are configured in .ini file:
-- -- -- AppSavePersistentDataTimeout =10;
-- -- -- ResumptionDelayBeforeIgn = 30;
-- -- -- ResumptionDelayAfterIgn = 30;
-- -- 4. The conditions of successful HMILevel resumption:
-- -- -- app unregisters during the time frame of 30 sec (inclusive) before BC.OnExitAllApplications(SUSPEND) from HMI
-- -- -  and it registers during 30 sec. after BC.OnReady from HMIl
-- Steps:
-- -- 1. Register non-media app and activate it 
-- -- 2. Make IGN_OFF-ON  
-- -- 3. After app registration activate Carplay/GAL on HU (during 3 seconds after RAI)
-- -- 4. Wait more than 5 seconds and deactivate Carplay/GAL
-- Expected result
-- -- 1. SDL sends UpdateDeviceList with appropriate deviceID
-- -- 2. SDL is reloaded
-- -- 3. App is registered with default HMI level NONE, HMI send BasicCommunication.OnEventChanged("eventName":"DEACTIVATE_HMI","isActive":true) to SDL
-- -- 4. ApplicationResumingTimeout is expired. SDL postpones resumption. 
-- -- -- HMI send BasicCommunication.OnEventChanged("eventName":"DEACTIVATE_HMI","isActive":false) to SDL. App is resumed to HMI level FULL
-- Postcondition
-- -- 1.UnregisterApp
-- -- 2.StopSDL
-------------------------------------Required Shared Libraries-------------------------------
require('user_modules/all_common_modules')
------------------------------------ Common Variables ---------------------------------------
resume_timeout = 5000
local mobile_session = "mobileSession"
non_media_app = common_functions:CreateRegisterAppParameters(
{appID = "1", appName = "NON-MEDIA", isMediaApplication = false, appHMIType = {"DEFAULT"}})
--------------------------------------Preconditions------------------------------------------
common_steps:BackupFile("Backup Ini file", "smartDeviceLink.ini")
common_steps:SetValuesInIniFile("Update ApplicationResumingTimeout value", "%p?ApplicationResumingTimeout%s? = %s-[%d]-%s-\n", "ApplicationResumingTimeout", resume_timeout)
common_steps:PreconditionSteps("Precondition", 5)
-----------------------------------------------Steps------------------------------------------
--1. Register non-media app and activate it
common_steps:RegisterApplication("Precondition_Register_App", mobile_session, non_media_app)
common_steps:ActivateApplication("Precondition_Activate_App", non_media_app.appName)

-- 2. Make IGN_OFF-ON
common_steps:IgnitionOff("Precondition_Ignition_Off")
common_steps:IgnitionOn("Precondition_Ignition_On")

-- 3. After app registration activate Carplay/GAL on HU (during 3 seconds after RAI)
common_steps:AddMobileSession("Add_Mobile_Session", _, mobile_session)
common_steps:RegisterApplication("Register_App", mobile_session, non_media_app)

function Test:StartDeactivateHmi()
	self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="DEACTIVATE_HMI"})
end

function Test:CheckAppIsNotResumedAfterResumingTimeout()
    common_functions:DelayedExp(resume_timeout + 1000)
    EXPECT_HMICALL("BasicCommunication.ActivateApp"):Times(0)
    EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource"):Times(0)
    local mobile_conenction_name, mobile_session = common_functions:GetMobileConnectionNameAndSessionName(non_media_app.appName, self)
    self[mobile_session]:ExpectNotification("OnHMIStatus"):Times(0)
end

-- 4. Wait more than 5 seconds and deactivate Carplay/GAL
function Test:StopDeactivateHmi()		
    function to_run()
		self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="DEACTIVATE_HMI"})
    end
    RUN_AFTER(to_run, 1000)
end

function Test:CheckAppIsResumedSuccessful()  
	EXPECT_HMICALL("BasicCommunication.ActivateApp")
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
	end)     			
	self[mobile_session]:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
end

-------------------------------------------Postcondition-------------------------------------
common_steps:UnregisterApp("Postcondition_UnRegister_App", non_media_app.appName)
common_steps:StopSDL("Postcondition_StopSDL")
common_steps:RestoreIniFile("Postcondition_Restore_Ini_file")
