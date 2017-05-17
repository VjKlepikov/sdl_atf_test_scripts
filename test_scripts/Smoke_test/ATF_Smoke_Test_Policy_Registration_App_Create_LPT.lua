---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-22374]:[Policies]: Creation of LocalPT from PreloadedPT

-- Description:
-- Check that SDL create policy DB from sdl_preload_pt.json on 1st start

-- Preconditions: SDL was never started before, policy DB absent on file system

-- Steps:
-- 1. Start SDL

-- Expected behaviour
-- 1. SDL created policy DB in AppStorageFolder

-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

---------------------------------------- Steps ----------------------------------------------
common_steps:StartSDL("StartSDL")

function Test:Delayed2s()
  common_functions:DelayedExp(2000)
end

function Test:Check_SDL_Create_Policy_Table()
  local policy_file = config.pathToSDL .. common_functions:GetValueFromIniFile("AppStorageFolder") .. "/policy.sqlite"
  local exist_flag = common_functions:IsFileExist (policy_file)
  if exist_flag == false then
    self.FailTestCase()
  end
end

------------------------------------ PostCondition ------------------------------------------
common_steps:StopSDL("PostCondition_StopSDL")
