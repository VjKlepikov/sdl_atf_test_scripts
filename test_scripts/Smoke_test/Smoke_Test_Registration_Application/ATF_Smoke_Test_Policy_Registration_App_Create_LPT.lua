---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-22374]:[Policies]: Creation of LocalPT from PreloadedPT

-- Description:
-- In case the Local Table does not yet exist (as a result of first SDL run or Master Reset)
-- PoliciesManager must create the Local PT from the Preloaded PT.
-- PoliciesManager must populate the LocalPT with items (that is, sections, sub-sections and fields)
-- defined as 'required' in Data Dictionary 043 under "PT Snapshot" column.

-- Preconditions: SDL was never started before, policy DB absent on file system

-- Steps:
-- 1. Start SDL

-- Expected behaviour
-- 1. SDL created policy DB in AppStorageFolder

-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

------------------------------------ Precondition -------------------------------------------
function Test:Delete_Policy_Table()
  common_functions:DeletePolicyTable()
end

---------------------------------------- Steps ----------------------------------------------
common_steps:StartSDL("StartSDL")

function Test:Check_SDL_Create_Policy_Table()
  local exist_flag = common_functions:IsFileExist (config.pathToSDL .. "storage/policy.sqlite")
  if exist_flag == false then
    self.FailTestCase()
  end
end

------------------------------------ PostCondition ------------------------------------------
common_steps:StopSDL("PostCondition_StopSDL")
