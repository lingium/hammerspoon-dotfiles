

----------------------------------------------------------------------------------------------------
-- MultiClick
----------------------------------------------------------------------------------------------------
-- https://stackoverflow.com/questions/44303244/binding-to-multiple-button-clicks

require("hs.timer")

keyDownCount = 0
keyMultipressGapTime = 0.2
keyMaxPressCount = 3

key2Action = { --文件路径内层必须是双引号，applescript不能使用单引号
    {'1', '"/Users/lingzhi/Downloads/Moodle/STATS4038STATS5013 Advanced Bayesian Methods 2021-22"', '"https://moodle.gla.ac.uk/course/view.php?id=28730"'},
    {'2', '"/Users/lingzhi/Downloads/Moodle/STATS4045STATS5054 Linear Mixed Models 2021-22"', '"https://moodle.gla.ac.uk/course/view.php?id=28736"'},
    {'3', '"/Users/lingzhi/Downloads/Moodle/STATS4040STATS5052 Flexible Regression 2021-2022"', '"https://moodle.gla.ac.uk/course/view.php?id=28735"'},
    {'4', '"/Users/lingzhi/Downloads/Moodle/STATS4047 Principles of Probability and Statistics 2021-22"', '"https://moodle.gla.ac.uk/course/view.php?id=28725"'},
    {'5', '"/Users/lingzhi/Downloads/Moodle/STATS5053STATS4073 - Functional Data Analysis 2021-22"', '"https://moodle.gla.ac.uk/course/view.php?id=23028"'},
    {'6', '"/Users/lingzhi/Downloads/Moodle/MATHS4117 - 4H Financial Mathematics (2021-22)"', '"https://moodle.gla.ac.uk/course/view.php?id=28756"'},
    {'7', '"/Users/lingzhi/Downloads/Moodle/STATS5012 Spatial Statistics (Levels 4H and 5M) 2021-22"', '"https://moodle.gla.ac.uk/course/view.php?id=29613"'},
    {'8', '"/Users/lingzhi/Downloads/Moodle/STATS40745011 Statistical Genetics (Levels 4H and 5M) 2021-22"', '"https://moodle.gla.ac.uk/course/view.php?id=29617"'},
    {'9', '"/Users/lingzhi/Downloads/Moodle/Statistics Project 202122"', '"https://moodle.gla.ac.uk/course/view.php?id=29406"'}
}

function CheckKeyDownCount()
    CheckKeyDownCountTimer:stop() -- Stops keydown timer so it doesn't repeat

    if keyDownCount == 1 then -- 根据按键次数执行操作
        -- hs.alert("Pressed once")
        openFolder(keyAndActions[3])
    elseif keyDownCount == 2 then
        -- hs.alert("Pressed twice")
        local shell_command = 'open -a "Google Chrome" ' .. keyAndActions[4]
        hs.execute(shell_command)
    elseif keyDownCount == 3 then
        -- hs.alert("Pressed thrice")
    end
    
    keyAndActions = nil --delete this variable
    keyDownCount = 0 -- Reset keypress counter
end


function CheckKey(s_keycode)
    focusKey = s_keycode
    for index, act in pairs(key2Action) do
        local key = act[1]
        local path = act[2]
        local url = act[3]
        if focusKey == key then
            return {true, key, path, url} --等效于break
        end
    end
    return {false}
end


CheckKeyDownCountTimer = hs.timer.new(keyMultipressGapTime, CheckKeyDownCount)

multipressBtnShortcuts = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(e) 
    
    local n_keycode = e:getKeyCode()
    local s_keycode = hs.keycodes.map[e:getKeyCode()]
    -- print(n_keycode)
    keyAndActions = CheckKey(s_keycode) --该变量设置为global给CheckKeyDownCount调用

    
    if keyAndActions[1] then
        e:setType(hs.eventtap.event.types.nullEvent)  -- null所有 3 次击键事件
        
        keyDownCount = keyDownCount + 1

        if CheckKeyDownCountTimer:running() then
            CheckKeyDownCountTimer:stop() 
        end

        if keyDownCount < keyMaxPressCount then -- restart the timer
            CheckKeyDownCountTimer:start() 
        elseif keyDownCount >= keyMaxPressCount then
            CheckKeyDownCount()
        end
        
    end

    return false
end)

-- multipressBtnShortcuts:start()



----------------------------------------------------------------------------------------------------
-- HyperKey
----------------------------------------------------------------------------------------------------
hyperMod1 = hs.hotkey.modal.new({}, "§")
-- function hyperMod1:entered() hs.alert'Entered mode' end
-- function hyperMod1:exited()  hs.alert'Exited mode'  end

hyperMod1_apps = {
    {'q', 'QQ'},
    {'w', 'WeChat'},
    -- {'c', 'Calendar'},
}

for i, app in ipairs(hyperMod1_apps) do
    hyperMod1:bind(hyperKey1, app[1], function() hs.application.launchOrFocus(app[2]) end)
end


-- 两层括号，进到terminal里还需要一个括号
-- hyperMod1_paths = {
--     {'e', '"/Users/lingzhi/Desktop/格拉论文"'},
--     {'r', '""'},
--     {'t', '"/Users/lingzhi/Desktop/格拉论文/写论文/texworkplace"'},

-- }

-- for i, path in ipairs(hyperMod1_paths) do
--     hyperMod1:bind(hyperKey1, path[1], function() 
--         openFolder(path[2])
--     end)
-- end


hyperMod1_urls = {
    {'m', '"https://notion.so"'},
}

for i, url in ipairs(hyperMod1_urls) do
    hyperMod1:bind(hyperKey1, url[1], function() 
        local shell_command = 'open -a "Google Chrome" ' .. url[2]
        hs.execute(shell_command)
    end)
end


hyperKey1Callback = hs.eventtap.new({hs.eventtap.event.types.flagsChanged}, function(e)
    local t_flags = e:getFlags()
    local n_keycode = e:getKeyCode()
    local s_keycode = hs.keycodes.map[e:getKeyCode()] --'alt'
    -- print(hs.inspect(t_flags), s_keycode)

    if n_keycode == 58 and (t_flags.cmd and t_flags.ctrl and t_flags.alt) then   
        -- print('hyperKey1 down')
        hyperMod1:enter()
        multipressBtnShortcuts:start() --进入该mode后会监听所有按键，如果符合条件就转义
    end

    if n_keycode == 58 and (t_flags.cmd and t_flags.ctrl) and (t_flags.alt == nil) then   
        -- print('hyperKey1 up')
        hyperMod1:exit()
        multipressBtnShortcuts:stop()
    end
    --fix bug. 按下hyperKey1加ijkl后karabiner会转译,导致不会触发hyperMod1:exit()
    --这个模式是根据karabiner在按下方向键后,{'cmd', 'ctrl', 'alt'}会依次抬起但是顺序更上面的不一样
    if n_keycode == 59 and (t_flags.cmd and t_flags.alt) and (t_flags.ctrl == nil) then  
        -- hs.alert('按下arrow后松开hyperKey1')
        hyperMod1:exit()
        multipressBtnShortcuts:stop()
    end

end)

hyperKey1Callback:start()


------------------------- 单独绑定的键  -------------------------

-- This removed formatting while pasting clipboard text 
hyperMod1:bind(hyperKey1, "v", function() hs.eventtap.keyStrokes(hs.pasteboard.getContents()) end)

hyperMod1:bind(hyperKey1, "g", function() --用于popclip没弹出，直接打开chrome搜索
    -- hs.eventtap.keyStroke({ "cmd" }, "C", hs.application.frontmostApplication()) --这样在Bob里不行
    local previousPasteboard = hs.pasteboard.getContents()
    hs.eventtap.keyStroke({ "cmd" }, "C", hs.window.focusedWindow():application())
    -- hs.osascript.applescript( --在本桌面打开新窗口
    --     [[tell application "/Applications/Google Chrome.app"
    --         make new window
    --         activate
    --     end tell]])
    hs.execute("open -a 'Google Chrome' chrome://newtab") --跳转到已经打开的窗口，打开新tab
    hs.timer.usleep(50000) --不加参数 n 几乎不需要这行命令
    local chrome = hs.application.get("com.google.Chrome")
    hs.eventtap.keyStroke({ "cmd" }, "V", chrome)
    hs.eventtap.keyStroke({  }, "return", chrome)
    hs.pasteboard.setContents(previousPasteboard)
end)

-- 关于命令行打开chrome https://stackoverflow.com/questions/61670173/on-macos-how-to-open-a-new-chrome-window-instead-of-a-new-tab-from-terminal-i

switchInterfaceMode = function()
    --https://stackoverflow.com/questions/25207077/how-to-detect-if-os-x-is-in-dark-mode
    output = hs.execute('defaults read -g AppleInterfaceStyle')
    if output == 'Dark' then --处于暗模式
        hs.osascript.applescript('tell application "System Events" to tell appearance preferences to set dark mode to false')
    else
        hs.osascript.applescript('tell application "System Events" to tell appearance preferences to set dark mode to true')
    end
end


hyperMod1:bind(hyperKey1, 'n', function()
    --https://apple.stackexchange.com/a/402797
    hs.osascript.applescript(
        [[tell application "Finder"
            activate
            set targetFolder to the target of the front window as alias
            set newFileName to my getAvailableFilename(targetFolder)
            set newFile to make new file at targetFolder with properties {name:newFileName}
            select newFile
        end tell

        delay 0.4

        tell application "System Events"
            tell process "Finder"
                keystroke return
            end tell
        end tell

        on getAvailableFilename(folderAlias)
            set found to false
            set fileCount to 1
            set appendix to ""
            
            repeat while found is false
                tell application "Finder"
                    if exists file ((folderAlias as text) & "untitled file" & appendix) then
                        set fileCount to (fileCount + 1)
                        set appendix to (" " & fileCount as string)
                    else
                        return "untitled file" & appendix
                    end if
                end tell
            end repeat
            
        end getAvailableFilename]])
end)

function transferPathFromClipboard()
    -- 将path写入剪切板传递给hs并恢复之前的剪切板内容
    local finder = hs.application.get('com.apple.finder')
    local previousPasteboard = hs.pasteboard.getContents()
    hs.eventtap.keyStroke({'cmd', 'alt'}, "c", 0, finder)
    hs.timer.usleep(10000) --0.01s 最快了
    local path = hs.pasteboard.getContents()
    hs.pasteboard.setContents(previousPasteboard)
    return path
end
function transferTextFromClipboard()
    -- 将text写入剪切板传递给hs，并恢复之前的剪切板内容
    local app = hs.window.focusedWindow():application()
    local previousPasteboard = hs.pasteboard.getContents()
    hs.eventtap.keyStroke({'cmd'}, "c", 0, app)
    hs.timer.usleep(10000) --0.01s 最快了
    local text = hs.pasteboard.getContents()
    hs.pasteboard.setContents(previousPasteboard)
    return text
end


hyperMod1:bind(hyperKey1, "s", function() --open terminal
    local finder = hs.application.get('com.apple.finder')
    if finder:isFrontmost() ~= true then return end

    local path = transferPathFromClipboard()
    if os.execute("cd '" .. path .. "'") then 
        -- hs.alert("Is a dir")
        local path = '"'..path..'"' --前后加"，防止文件名中有空格
        hs.execute('open -a "Terminal" '.. path)
    else 
        -- hs.alert("Not a dir")
        local path = path:match("(.*[/\\])") --file path → directory 文件名中有/时不管用
        local path = '"'..path..'"' --前后加"，防止文件名中有空格
        hs.execute('open -a "Terminal" '.. path)
    end
end)
-- lua: file path → directory 
--https://stackoverflow.com/questions/9102126/lua-return-directory-path-from-path

-- vscode R语言 初始化编辑器layout。里面的时间设置都是最快了
function vscodeInitLayout(terminalAndPlot)
    local vscode = hs.application.get('com.microsoft.VSCode')
    if vscode == nil then return end
    vscode:activate()
    hs.eventtap.keyStroke({ "cmd" }, "\\", 0, vscode) --向右拆分
    hs.timer.usleep(200000) --最快了
    hs.eventtap.keyStroke(hyperKey1, "tab", 0, vscode) --打开R终端,需要同vscode中的快捷键一致
    hs.timer.usleep(100000) --最快了
    hs.eventtap.keyStroke({ "ctrl" }, "1", 0, vscode) --切到同区域的多余编辑器上
    hs.eventtap.keyStroke({ "cmd" }, "w", 0, vscode) --关闭多余编辑器

    if terminalAndPlot then 
        hs.timer.usleep(200000) --最快了
        vscode:selectMenuItem({"查看", "编辑器布局", "向上拆分"})
        hs.timer.usleep(200000)
        hs.eventtap.keyStroke({ "cmd" }, "3", 0, vscode) --切回终端
        hs.timer.usleep(200000)
        hs.eventtap.keyStrokes('par(ask=FALSE)', vscode)
        hs.timer.usleep(200000)
        hs.eventtap.keyStroke({  }, 'return', 0, vscode)
        hs.timer.usleep(1200000) --最快了
        hs.eventtap.keyStroke({ "cmd" }, "4", 0, vscode) --切回新打开的web panel
        hs.timer.usleep(300000) --最快了
        hs.eventtap.keyStroke(hyperKey1, "up", 0, vscode) --将其移动到上面的组
    end
    
    hs.eventtap.keyStroke({ "cmd" }, "1", 0, vscode) --切回左侧编辑器
end


hyperMod1:bind(hyperKey1, "a", function()
    local frontmostApp = hs.application.frontmostApplication()

    if frontmostApp:bundleID() == 'com.apple.finder' then --如果是finder，open vscode
        local finder = frontmostApp
        if finder:isFrontmost() ~= true then return end
        local path = '"'..transferPathFromClipboard()..'"'
        hs.execute('open -a "Visual Studio Code" '.. path)

    elseif frontmostApp:bundleID() == 'com.microsoft.VSCode' then --如果是terminal，为R设置布局
        local _, _, c = hs.osascript.applescript([[display dialog "请选择工作区模式" buttons {"Cancel", "仅终端", "终端与绘图"} default button 3 with icon note]])
        if c == "{ 'bhit':'utxt'(\"?????\") }" then 
            vscodeInitLayout(true)
        elseif c == "{ 'bhit':'utxt'(\"???\") }" then
            vscodeInitLayout(false)
        else --"User canceled."
            frontmostApp:activate()
        end
    
    elseif frontmostApp:bundleID() == 'com.apple.Terminal' then --如果是terminal，将光标移动到行首
        hs.eventtap.keyStroke({'ctrl'}, "a", 0, frontmostApp)
    end

end)

-- string.match(win:title(), "^(.+)(%.)[rR](.*)$")
-- ^字符串开头，()匹配并返回括号内的内容，.匹配任意字符，+匹配前一字符1次或多次，%.匹配点号，[rR]匹配r与R，*匹配当前字符0次或多次(最长匹配)
-- --按esc/点cancel是false，按回车/点OK是true，按tab循环切换按钮，按空格选择非默认按钮。如果按回车无论如何都是默认按钮。



hyperMod1:bind(hyperKey1, "left", function()
    hs.osascript.applescript([[
        tell application "System Events"
            tell process "控制中心"
                click menu bar item 6 of menu bar 1
                click button "倒回，15秒钟" of window 1
                click menu bar item 6 of menu bar 1
            end tell
        end tell
    ]])
end)
hyperMod1:bind(hyperKey1, "right", function()
    hs.osascript.applescript([[
        tell application "System Events"
            tell process "控制中心"
                click menu bar item 6 of menu bar 1
                click button "快进，15秒钟" of window 1
                click menu bar item 6 of menu bar 1
            end tell
        end tell
    ]])
end)




