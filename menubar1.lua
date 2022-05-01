-- parentDirPathToAnVMSRBinary = "~/Documents/git/AnVMSR/Release-10.15"
parentDirPathToSMCUtilBinary = "~/Desktop/GitHub/smcFanControl/smc-command" --BATTERY

savedTemperatureLimit = 0
savedTurboBoostSetting = false
savedPowerLimit = 0
savedBatteryChargingLimit = 100
isGPUModeTemporary = false

mnu1 = hs.menubar.new()


menuTable1 = {
    -- { title = "Mac Nerd's Utility", disabled = true },
    { title = "-" },
    { title = "Batt. Charge Limit", disabled = true },
    { title = "50%", indent = 1, fn = function() setBatteryChargeLimit(50); refreshStatus1() end },
    { title = "60%", indent = 1, fn = function() setBatteryChargeLimit(60); refreshStatus1() end },
    { title = "70%", indent = 1, fn = function() setBatteryChargeLimit(70); refreshStatus1() end },
    { title = "80%", indent = 1, fn = function() setBatteryChargeLimit(80); refreshStatus1() end },
    { title = "90%", indent = 1, fn = function() setBatteryChargeLimit(90); refreshStatus1() end },
    { title = "100%", indent = 1, fn = function() setBatteryChargeLimit(100); refreshStatus1() end },
    { title = "Custom...", indent = 1, fn = function() setBatteryChargeLimit(askForBatteryChargeLimit()); refreshStatus1() end },
    { title = "-" },
    { title = "GPU Mode", disabled = true },
    { title = "Auto switch", indent = 1, fn = function() setGraphicsCardAuto(); refreshStatus1() end },
    { title = "Integrated", indent = 1, fn = function() setGraphicsCardIntegrated(); refreshStatus1() end },
    { title = "High Performance", indent = 1, fn = function() setGraphicsCardDedicated(); refreshStatus1() end },
    { title = "Temporary Mode", indent = 1, fn = function() isGPUModeTemporary = not isGPUModeTemporary; refreshStatus1() end },
    { title = "-" },
    { title = "Refresh status", indent = 1, fn = function() refreshStatus1() end },
    { title = "-" },
    -- { title = "by Charlie", disabled = true }
}
-----------------------------------------------------------------------------------------

function refreshStatus1()
    currentGraphicsCardMode = getGraphicsCardMode()
    currentBatteryChargingLimit = getBatteryChargeLimit()
    savedBatteryChargingLimit = currentBatteryChargingLimit

    if (currentGraphicsCardMode == 0) then
        graphicsModeChar = "I"
    elseif (currentGraphicsCardMode == 1) then
        graphicsModeChar = "D"
    elseif (currentGraphicsCardMode == 2) then
        graphicsModeChar = "Auto"
    else 
        graphicsModeChar = "Err"
    end

    
    -- mnu1:setTitle(tostring(currentBatteryChargingLimit)..tostring(graphicsModeChar))
    mnu1:setTitle(tostring(currentBatteryChargingLimit))

    local isAfterFanSpeed = false
    local hasTickedChargeLimit = false
    for idx, iTable in pairs(menuTable1) do
        if string.sub(iTable["title"], 1, 4) == "Batt" then
            isAfterFanSpeed = true
        end
        if isAfterFanSpeed then
            -- Tick battery charge limits
            if string.sub(iTable["title"], -1) == "%" then
                if iTable["title"] == tostring(currentBatteryChargingLimit).."%" then
                    iTable["checked"] = true
                    hasTickedChargeLimit = true
                else
                    iTable["checked"] = false
                end
            end

            -- Tick graphics card mode
            if iTable["title"] == "Auto switch" then
                if (currentGraphicsCardMode == 0) then
                    menuTable1[idx]["checked"] = false
                    menuTable1[idx + 1]["checked"] = true
                    menuTable1[idx + 2]["checked"] = false
                elseif (currentGraphicsCardMode == 1) then
                    menuTable1[idx]["checked"] = false
                    menuTable1[idx + 1]["checked"] = false
                    menuTable1[idx + 2]["checked"] = true
                elseif (currentGraphicsCardMode == 2) then
                    menuTable1[idx]["checked"] = true
                    menuTable1[idx + 1]["checked"] = false
                    menuTable1[idx + 2]["checked"] = false
                end
            end

            -- Tick 'Temporary' label
            if iTable["title"] == "Temporary Mode" then
                menuTable1[idx]["checked"] = isGPUModeTemporary
            end

            -- Tick "Custom..."
            if iTable["title"] == "Custom..." then
                if (string.sub(menuTable1[idx - 1]["title"], -1) == "%") then
                    iTable["checked"] = not hasTickedChargeLimit
                end
            end
        end
        
    end
    mnu1:setMenu(menuTable1)
end


--BATTERY--------------------------------------------------------------------------------

function getBatteryChargeLimit()
    cmd = "cd "..parentDirPathToSMCUtilBinary.."; ./smc -k BCLM -r"
    ok,returnValue = hs.osascript.applescript(string.format('do shell script "%s"', cmd))
    if ok == false then
        hs.alert.show("Operation failed!")
    end
    --returnValue有30/29位长 
    --'  BCLM  [ui8 ]  100 (bytes 64)'
    --'  BCLM  [ui8 ]  80 (bytes 50)'
    batteryLimit = tonumber(string.sub(returnValue, 15, 19))

    return batteryLimit
end

function setBatteryChargeLimit(desiredBatteryChargeLimit)
    savedBatteryChargingLimit = desiredBatteryChargeLimit
    cmd = "cd "..parentDirPathToSMCUtilBinary.."; sudo ./smc -k BCLM -w "..string.format("%x", desiredBatteryChargeLimit) --x 小写十六进制
    result = hs.osascript.applescript(string.format('do shell script "%s" with administrator privileges', cmd))
    if result == false then
        hs.alert.show("Operation failed!")
    end
end

function askForBatteryChargeLimit()
    button, input = hs.dialog.textPrompt("Set custom battery charge limit...", "Please enter the number your desired (%)", tostring(getBatteryChargeLimit()), "OK", "Cancel")
    if (button == "Cancel") then
        return getBatteryChargeLimit()
    end

    input_num = math.floor(tonumber(input))
    if (input_num <= 100 and input_num >= 30) then
        return input_num
    else
        hs.alert.show("Invalid battery charge limit! Nothing will be changed.")
        return getBatteryChargeLimit()
    end
    return getBatteryChargeLimit()
end


--GRAPHICS-------------------------------------------------------------------------------

function setGraphicsCardAuto()
    cmd = "sudo pmset -a gpuswitch 2"
    --hs.alert.show(cmd)
    result = hs.osascript.applescript(string.format('do shell script "%s"', cmd))
    print("setGraphicsMode:     2")
    if result == false then
        hs.alert.show("Operation failed!")
    end
end

function setGraphicsCardDedicated()
    cmd = "sudo pmset -a gpuswitch 1"
    --hs.alert.show(cmd)
    result = hs.osascript.applescript(string.format('do shell script "%s"', cmd))
    print("setGraphicsMode:     1")
    if result == false then
        hs.alert.show("Operation failed!")
    end
end

function setGraphicsCardIntegrated()
    cmd = "sudo pmset -a gpuswitch 0"
    --hs.alert.show(cmd)
    result = hs.osascript.applescript(string.format('do shell script "%s"', cmd))
    print("setGraphicsMode:     0")
    if result == false then
        hs.alert.show("Operation failed!")
    end
end

function getGraphicsCardMode()
    cmd = "pmset -g | grep gpuswitch"
    ok,returnValue = hs.osascript.applescript(string.format('do shell script "%s"', cmd))
    if ok == false then
        hs.alert.show("Operation failed!")
    end
    --hs.alert.show(returnValue)
    GPUStr = string.sub(returnValue, 23, 23)
    print("getGraphicsCardMode: "..GPUStr)
    --hs.alert.show(tonumber(GPUStr, 10))
    --hs.alert.show(hexNum)
    return tonumber(GPUStr, 10)
end

-----------------------------------------------------------------------------------------

mnu1:setMenu(menuTable1)
mnu1:setClickCallback(refreshStatus1())
