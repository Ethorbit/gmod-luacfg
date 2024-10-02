-- cfg files are so old school
-- We got 'luacfg' now baby :cool:
--
-- This was made to give administrators a way to configure
-- certain parts of server lua without actually needing to touch lua
--
-- I tried to execute .cfg instead, but Source kept skipping 
-- my commands because of how shitty it is. thus, 'luacfg' was born!

luacfg = luacfg or {}
luacfg.Commands = luacfg.Commands or {}

luacfg.IsValidCommand = function(command)
    local isValid = false

    if command and luacfg.Commands[command] and isfunction(luacfg.Commands[command]) then
        isValid = true
    end
    
    return isValid
end

luacfg.AddCommand = function(command, callback)
    luacfg.Commands[command] = callback
end

luacfg.RunCommand = function(command, args)
    if !luacfg.IsValidCommand(command) then
        print("[luacfg] Invalid command:", command)
    return end

    luacfg.Commands[command](args)
end

-- These characters indicate we're wrapping something in quotes
-- If a match is found that ends the 'quote'
luacfg.QuoteSymbols = {
    ["\""] = true,
    ["'"] = true,
    ["`"] = true
}

luacfg.CommentSymbols = {
    ["/"] = true,
    ["\\"] = true,
    ["-"] = true,
    ["!"] = true,
    ["]"] = true,
    ["["] = true,
    ["."] = true
}

-- Now we need to make our own command interpreter
-- I hate my life.
luacfg.ParseCommand = function(line)
    local command = ""
    local args = {}
    local currentArg = ""
    local currentArgQuoteType = ""
    local currentArgIsQuoted = false
    local char
    local lastchar

    for i = 1, #line do
        lastchar = char
        char = line:sub(i, i)

        -- Get the command
        -- The first space indicates the end of the command because commands can't be spaced
        if command == "" then
            if char == " " then
                command = currentArg
                currentArg = ""
            else
                currentArg = currentArg .. char
            end
            continue
        end

        -- Get the args for the command
        if !currentArgIsQuoted and luacfg.CommentSymbols[char] then
            -- We encountered a comment, ignore the rest of the line now.
            break
        end

        -- We encountered a quote symbol and now the argument is a quoted argument
        if not currentArgIsQuoted and luacfg.QuoteSymbols[char] then
            currentArgQuoteType = char
            currentArgIsQuoted = true
        elseif currentArgIsQuoted and char == currentArgQuoteType then
            -- This is the end of the matching quote, thus the end of the argument
            args[#args + 1] = currentArg
            currentArgIsQuoted = false
            currentArgQuoteType = ""
            currentArg = ""
        elseif currentArgIsQuoted then
            -- Argument is being quoted, keep going.
            currentArg = currentArg .. char
        elseif char == " " then
            -- This is a space, so that's the end of the argument there.
            if currentArg ~= "" then
                args[#args + 1] = currentArg
                currentArg = ""
            end
        else
            -- No spaces encountered yet, keep going.
            currentArg = currentArg .. char
        end

        -- We've reached the end of the line.
        if i == #line and currentArg ~= "" then
            args[#args + 1] = currentArg
        end

        continue
    end

    return command, args
end

luacfg.LoadFile = function(cfg_file)
    if !file.Exists(cfg_file, "GAME") then print("[luacfg] File doesn't exist:", cfg_file) return end

    print("[luacfg] Executing " .. cfg_file)

    local file = file.Open(cfg_file, "r", "GAME")
    local line
    local time = 0
    while !file:EndOfFile() do
        local line = file:ReadLine()
        if !line then return end

        -- Make sure to ignore 'comments'
        if luacfg.CommentSymbols[line[1]] then continue end 

        -- And if for some reason a line begins with a quote
        if luacfg.QuoteSymbols[line[1]] then continue end

        -- ReadLine adds these characters which will be problematic moving forward...
        line = string.Replace(line, "\n", "")
        line = string.Replace(line, "\r", "")
        if #line <= 0 then continue end
        
        command, args = luacfg.ParseCommand(line)
        --print(command)
        --PrintTable(args)

        luacfg.RunCommand(command, args)
    end

    file:Close()
    hook.Run("luacfg.LoadedFile", cfg_file, parent_cfg_file)
end

luacfg.LoadFiles = function(dir)
    if !dir then -- Just start at the root directory then. 
        dir = "cfg/luacfg"
    end

    local get_dir_files_thread = coroutine.create(function()
        coroutine.yield(file.Find(dir .. "/*", "GAME"))
    end)

    _,files,directories = coroutine.resume(get_dir_files_thread)
    
    if files then
        luacfg.FileThread = coroutine.create(function()
            for _,file in pairs(files) do
                if (!string.EndsWith(file, ".luacfg")) then continue end
                
                luacfg.IndividualFileThread = coroutine.create(function()
                    luacfg.LoadFile(dir .. "/" .. file)
                    coroutine.yield()
                end)
                
                coroutine.resume(luacfg.IndividualFileThread)
            end
            
            coroutine.yield()
        end)
    end

    if directories then
        luacfg.DirThread = coroutine.create(function() 
            for _,next_dir in pairs(directories) do
                luacfg.LoadFiles(dir .. "/" .. next_dir)
            end

            coroutine.yield()
        end)
    end

    coroutine.resume(luacfg.FileThread)
    coroutine.resume(luacfg.DirThread)
    
    hook.Run("luacfg.LoadedFiles")
end

hook.Add("luacfg.LoadFiles", "luacfg.LoadFilesListener", function(dir)
    luacfg.LoadFiles(dir)
end)

hook.Add("luacfg.LoadFile", "luacfg.LoadFileListener", function(file)
    luacfg.LoadFile(file)
end)

hook.Run("luacfg.Initialized")
timer.Create("luacfg.IHateGarrysMod", 0.1, 10, function()
    hook.Run("luacfg.Initialized")
end)

hook.Add("InitPostEntity", function()
    luacfg.LoadFiles()
end)
