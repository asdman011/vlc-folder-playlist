--[[
    This extension captures the initially opened media (both its file name and full URI),
    loads all media files from that file's folder into VLC's playlist, and then jumps to the captured media.
    
    Navigation commands (next/previous) work relative to the current item, with wrap-around behavior,
    regardless of VLC's loop settings.
--]]

function descriptor()
    return {
        title = "Folder Playlist Loader & Navigation (Initial Media Captured)",
        version = "1.2",
        author = "Mindconstructor (modified)",
        url = 'http://www.videolan.org',
        shortdesc = "Folder Playlist Loader & Navigation",
        description = "Captures the initially opened media, loads the folder's media into the playlist, and resumes from that file.",
        capabilities = {"input-listener"},
        commands = {
            { id = "next",           title = "Play Next in Folder" },
            { id = "previous",       title = "Play Previous in Folder" },
            { id = "media_next",     title = "Play Next (Media Key)" },
            { id = "media_previous", title = "Play Previous (Media Key)" }
        }
    }
end

local lastplayeditem = ""
local initialFileName = ""  -- Captures the file name of the first-opened media
local initialFileUri = ""   -- Captures the full URI of the first-opened media
local processedInitialItem = false -- Flag to track if we've processed the initial item

-- Utility: extract folder from a full file path.
function extract_folder(path)
    local folder = string.match(path, "^(.*[/\\])")
    if folder then
        folder = string.gsub(folder, "^file:///", "")
        return folder
    end
    return nil
end

-- Utility: extract file name from a full path.
function extract_filename(path)
    return string.match(path, "([^/\\]+)$")
end

-- When the extension is activated, capture the initial file name and URI,
-- load all media files in the folder into the playlist,
-- and then jump to the captured media in the playlist.
function activate()
    vlc.msg.dbg("[Folder Playlist] Activated")
    local item = vlc.input.item()
    if item then
        local uri = item:uri()
        local path = vlc.strings.decode_uri(uri)
        initialFileName = extract_filename(path) or ""
        initialFileUri = uri
        vlc.msg.dbg("Captured initial file name: " .. initialFileName)
        vlc.msg.dbg("Captured initial file URI: " .. initialFileUri)
        
        -- Mark the current item as processed so we don't process it again in input_changed
        item:set_meta("FolderPlaylistLoader", "processed")
        
        local folder_path = extract_folder(path)
        if folder_path then
            local files = vlc.io.readdir(folder_path)
            if files then
                files = filter_media_files(files)
                if #files > 0 then
                    table.sort(files)  -- sort alphabetically
                    vlc.msg.dbg("Loading playlist from folder: " .. folder_path)
                    
                    -- Clear the playlist but keep the current item
                    local current_item_id = vlc.playlist.current()
                    local playlist = vlc.playlist.get("playlist")
                    
                    if playlist and playlist.children then
                        for index, item in pairs(playlist.children) do
                            if item.id and item.id ~= current_item_id then
                                vlc.playlist.delete(item.id)
                            end
                        end
                    end
                    
                    -- Add all files from the folder
                    for _, file in ipairs(files) do
                        local file_uri = "file:///" .. folder_path .. file
                        -- Don't add the current file again
                        if file_uri ~= initialFileUri then
                            vlc.playlist.enqueue({{ path = file_uri }})
                        end
                    end
                    
                    -- Now, sort the playlist alphabetically
                    vlc.playlist.sort("title")
                    
                    -- Find and jump to our initial item
                    jump_to_initial_media()
                else
                    vlc.msg.dbg("No media files found in folder: " .. folder_path)
                end
            else
                vlc.msg.dbg("Could not read folder: " .. folder_path)
            end
        else
            vlc.msg.dbg("Unable to determine folder from current file: " .. path)
        end
    else
        vlc.msg.dbg("No input item found on activation.")
    end
end

function deactivate()
    vlc.msg.dbg("[Folder Playlist] Deactivated")
end

-- Called when input changes (new file plays)
function input_changed()
    local item = vlc.input.item()
    if not item then return end
    
    -- Check if we've already processed this item
    if item:metas()["FolderPlaylistLoader"] then
        return
    end
    
    -- Mark the item as processed
    item:set_meta("FolderPlaylistLoader", "processed")
    
    local uri = item:uri()
    vlc.msg.dbg("Now playing: " .. uri)
    lastplayeditem = uri
end

-- Jump to the media item that matches the initially opened media.
function jump_to_initial_media()
    local p = vlc.playlist.get("normal", true)
    if p then
        local found = false
        -- First try matching by full URI.
        for _, entry in ipairs(p) do
            if entry.path == initialFileUri then
                vlc.msg.dbg("Jumping to initial media by URI: " .. entry.path)
                vlc.playlist.goto_item(entry.id)
                lastplayeditem = entry.path
                found = true
                break
            end
        end
        -- If not found by URI, try matching by file name.
        if not found then
            for _, entry in ipairs(p) do
                local entryName = extract_filename(entry.path)
                if entryName == initialFileName then
                    vlc.msg.dbg("Jumping to initial media by file name: " .. entry.path)
                    vlc.playlist.goto_item(entry.id)
                    lastplayeditem = entry.path
                    found = true
                    break
                end
            end
        end
        if not found then
            vlc.msg.dbg("Initial media not found in playlist; defaulting to first item")
            if #p > 0 then
                vlc.playlist.goto_item(p[1].id)
                lastplayeditem = p[1].path
            end
        end
    end
end

-- Returns the URI of the current item or falls back to lastplayeditem.
function get_current_uri()
    local item = vlc.input.item()
    if item then
        return item:uri()
    else
        return lastplayeditem
    end
end

-- Navigation: jump to next item (with wrap-around).
function next()
    vlc.msg.dbg("next() command received")
    local p = vlc.playlist.get("normal", true)
    if not p or #p == 0 then
        vlc.msg.dbg("Playlist is empty")
        return
    end
    local current_uri = get_current_uri()
    local currentIndex = nil
    for i, entry in ipairs(p) do
        if entry.path == current_uri then
            currentIndex = i
            break
        end
    end
    if not currentIndex then
        vlc.msg.dbg("Current item not found in playlist; defaulting to first item")
        currentIndex = 1
    end
    local nextIndex = currentIndex + 1
    if nextIndex > #p then
        nextIndex = 1  -- wrap around to first item
    end
    local nextItem = p[nextIndex]
    if nextItem then
        vlc.msg.dbg("Jumping to next item: " .. nextItem.path)
        vlc.playlist.goto_item(nextItem.id)
    end
end

-- Navigation: jump to previous item (with wrap-around).
function previous()
    vlc.msg.dbg("previous() command received")
    local p = vlc.playlist.get("normal", true)
    if not p or #p == 0 then
        vlc.msg.dbg("Playlist is empty")
        return
    end
    local current_uri = get_current_uri()
    local currentIndex = nil
    for i, entry in ipairs(p) do
        if entry.path == current_uri then
            currentIndex = i
            break
        end
    end
    if not currentIndex then
        vlc.msg.dbg("Current item not found in playlist; defaulting to first item")
        currentIndex = 1
    end
    local prevIndex = currentIndex - 1
    if prevIndex < 1 then
        prevIndex = #p  -- wrap to last item
    end
    local prevItem = p[prevIndex]
    if prevItem then
        vlc.msg.dbg("Jumping to previous item: " .. prevItem.path)
        vlc.playlist.goto_item(prevItem.id)
    end
end

-- Media key commands.
function media_next()
    next()
end

function media_previous()
    previous()
end

-- Filter the list of files for media file extensions.
function filter_media_files(files)
    local media_files = {}
    local media_extensions = {
        "%.avi$", "%.mkv$", "%.mp4$", "%.wmv$", "%.flv$", 
        "%.mpeg$", "%.mpg$", "%.mov$", "%.rm$", "%.vob$", 
        "%.asf$", "%.divx$", "%.m4v$", "%.ogg$", "%.ogm$", 
        "%.ogv$", "%.qt$", "%.rmvb$", "%.webm$", "%.3gp$",
        "%.3g2$", "%.drc$", "%.f4v$", "%.f4p$", "%.f4a$", 
        "%.f4b$", "%.gifv$", "%.mng$", "%.mts$", "%.m2ts$", 
        "%.ts$", "%.mov$", "%.qt$", "%.mxf$", "%.nsv$", 
        "%.roq$", "%.svi$", "%.viv$",
        "%.mp3$", "%.wav$", "%.flac$", "%.aac$", "%.ogg$", 
        "%.wma$", "%.alac$", "%.ape$", "%.ac3$", "%.opus$", 
        "%.aiff$", "%.aif$", "%.amr$", "%.au$", "%.mka$", 
        "%.dts$", "%.m4a$", "%.m4b$", "%.m4p$", "%.mpc$", 
        "%.mpp$", "%.mp+", "%.oga$", "%.spx$", "%.tta$",
        "%.voc$", "%.ra$", "%.mid$", "%.midi$"
    }
    for _, f in ipairs(files) do
        for _, ext in ipairs(media_extensions) do
            if string.match(f, ext) then
                table.insert(media_files, f)
                break
            end
        end
    end
    return media_files
end