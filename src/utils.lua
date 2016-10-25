--[[
  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

function str2bool(str)
    return string.upper(str) == "ON"
end

function bool2str(bool)
    if bool then
        return "ON"
    else
        return "OFF"
    end
end

math.sign = math.sign or function(x) return x<0 and -1 or x>0 and 1 or 0 end

function debugPrint(lvl, str)
    if (lvl <= debuglevel) then
        print(str)
    end
end
