--[[
|------------------------------------------------- |--------- ______-----------------_________---|
|   ______   __   ______    _____     _____    __  |  _____  |  ____|  __     __    /  _______/  |
|  |__  __| |  | |__  __|  /     \   |     \  |  | | |__   | | |____  |  |   |  |  /  /______    |
|    |  |   |  |   |  |   /  /_\  \  |  |\  \ |  | |   /  /  |  ____| |  |   |  |  \______   /   |
|    |  |   |  |   |  |  /  _____  \ |  | \  \|  | |  /  /_  | |____  |  |___|  |   _____/  /    |
|    |__|   |__|   |__| /__/     \__\|__|  \_____| | |_____| |______|  \_______/  /________/     |
|--------------------------------------------------|---------------------------------------------|
|  This Project Powered by : Pouya Poorrahman CopyRight 2016 Jove Version 2.0 Anti Spam Cli Bot  |
|------------------------------------------------------------------------------------------------|
]]
local function set_bot_photo(msg, success, result)
  local receiver = get_receiver(msg)
  if success then
    local file = 'data/photos/bot.jpg'
    print('File downloaded to:', result)
    os.rename(result, file)
    print('File moved to:', file)
    set_profile_photo(file, ok_cb, false)
    send_large_msg(receiver, 'Photo changed!', ok_cb, false)
    redis:del("bot:photo")
  else
    print('Error downloading: '..msg.id)
    send_large_msg(receiver, 'Failed, please try again!', ok_cb, false)
  end
end

--Function to add log supergroup
local function logadd(msg)
	local data = load_data(_config.moderation.data)
	local receiver = get_receiver(msg)
	local GBan_log = 'GBan_log'
   	if not data[tostring(GBan_log)] then
		data[tostring(GBan_log)] = {}
		save_data(_config.moderation.data, data)
	end
	data[tostring(GBan_log)][tostring(msg.to.id)] = msg.to.peer_id
	save_data(_config.moderation.data, data)
	local text = 'Log SuperGroup has has been set!'
	reply_msg(msg.id,text,ok_cb,false)
	return
end

--Function to remove log supergroup
local function logrem(msg)
	local data = load_data(_config.moderation.data)
    local receiver = get_receiver(msg)
	local GBan_log = 'GBan_log'
	if not data[tostring(GBan_log)] then
		data[tostring(GBan_log)] = nil
		save_data(_config.moderation.data, data)
	end
	data[tostring(GBan_log)][tostring(msg.to.id)] = nil
	save_data(_config.moderation.data, data)
	local text = 'Log SuperGroup has has been removed!'
	reply_msg(msg.id,text,ok_cb,false)
	return
end


local function parsed_url(link)
  local parsed_link = URL.parse(link)
  local parsed_path = URL.parse_path(parsed_link.path)
  return parsed_path[2]
end

local function get_contact_list_callback (cb_extra, success, result)
  local text = " "
  for k,v in pairs(result) do
    if v.print_name and v.id and v.phone then
      text = text..string.gsub(v.print_name ,  "_" , " ").." ["..v.id.."] = "..v.phone.."\n"
    end
  end
  local file = io.open("contact_list.txt", "w")
  file:write(text)
  file:flush()
  file:close()
  send_document("user#id"..cb_extra.target,"contact_list.txt", ok_cb, false)--.txt format
  local file = io.open("contact_list.json", "w")
  file:write(json:encode_pretty(result))
  file:flush()
  file:close()
  send_document("user#id"..cb_extra.target,"contact_list.json", ok_cb, false)--json format
end

local function get_dialog_list_callback(cb_extra, success, result)
  local text = ""
  for k,v in pairsByKeys(result) do
    if v.peer then
      if v.peer.type == "chat" then
        text = text.."group{"..v.peer.title.."}["..v.peer.id.."]("..v.peer.members_num..")"
      else
        if v.peer.print_name and v.peer.id then
          text = text.."user{"..v.peer.print_name.."}["..v.peer.id.."]"
        end
        if v.peer.username then
          text = text.."("..v.peer.username..")"
        end
        if v.peer.phone then
          text = text.."'"..v.peer.phone.."'"
        end
      end
    end
    if v.message then
      text = text..'\nlast msg >\nmsg id = '..v.message.id
      if v.message.text then
        text = text .. "\n text = "..v.message.text
      end
      if v.message.action then
        text = text.."\n"..serpent.block(v.message.action, {comment=false})
      end
      if v.message.from then
        if v.message.from.print_name then
          text = text.."\n From > \n"..string.gsub(v.message.from.print_name, "_"," ").."["..v.message.from.id.."]"
        end
        if v.message.from.username then
          text = text.."( "..v.message.from.username.." )"
        end
        if v.message.from.phone then
          text = text.."' "..v.message.from.phone.." '"
        end
      end
    end
    text = text.."\n\n"
  end
  local file = io.open("dialog_list.txt", "w")
  file:write(text)
  file:flush()
  file:close()
  send_document("user#id"..cb_extra.target,"dialog_list.txt", ok_cb, false)--.txt format
  local file = io.open("dialog_list.json", "w")
  file:write(json:encode_pretty(result))
  file:flush()
  file:close()
  send_document("user#id"..cb_extra.target,"dialog_list.json", ok_cb, false)--json format
end

-- Returns the key (index) in the config.enabled_plugins table
local function plugin_enabled( name )
  for k,v in pairs(_config.enabled_plugins) do
    if name == v then
      return k
    end
  end
  -- If not found
  return false
end

-- Returns true if file exists in plugins folder
local function plugin_exists( name )
  for k,v in pairs(plugins_names()) do
    if name..'.lua' == v then
      return true
    end
  end
  return false
end

local function reload_plugins( )
	plugins = {}
  return load_plugins()
end

local function run(msg,matches)
    local receiver = get_receiver(msg)
    local group = msg.to.id
	local print_name = user_print_name(msg.from):gsub("?", "")
	local name_log = print_name:gsub("_", " ")
    if not is_admin1(msg) then
    	return 
    end
    if msg.media then
      	if msg.media.type == 'photo' and redis:get("bot:photo") then
      		if redis:get("bot:photo") == 'waiting' then
        		load_photo(msg.id, set_bot_photo, msg)
      		end
      	end
    end
    if matches[1] == "setbotphoto" then
    	redis:set("bot:photo", "waiting")
    	return reply_msg(msg.id, '> Please send me bot photo now', ok_cb, false)
    end
    if matches[1] == "markread" then
    	if matches[2] == "on" then
    		redis:set("bot:markread", "on")
    		return reply_msg(msg.id, "Done \nMark read > #On", ok_cb, false)
    	end
    	if matches[2] == "off" then
    		redis:del("bot:markread")
    		return reply_msg(msg.id, "Done \nMark read > #Off", ok_cb, false)
    	end
    	return
    end
    if matches[1] == "pm" then
    	local text = "Message From "..(msg.from.username or msg.from.last_name).."\n\nMessage : "..matches[3]
    	send_large_msg("user#id"..matches[2],text)
    	return reply_msg(msg.id, "Message has been sent", ok_cb, false)
    end
    
    if matches[1] == "import" then--join by group link
    	local hash = parsed_url(matches[2])
    	import_chat_link(hash,ok_cb,false)
		return reply_msg(msg.id, "Done!", ok_cb, false)
    end
    if matches[1] == "contactlist" then
	    if not is_sudo(msg) then-- Sudo only
    		return reply_msg(msg.id, "You're Not Allowd.", ok_cb, false)
    	end
      get_contact_list(get_contact_list_callback, {target = msg.from.id})
      return reply_msg(msg.id, "I've sent contact list with both json and text format to your private", ok_cb, false)
    end
 if matches[1] == "sendcontact" and is_sudo(msg) then
    phone = matches[2]
    first_name = matches[3]
    last_name = matches[4]
    send_contact(get_receiver(msg), phone, first_name, last_name, ok_cb, false)
end
 if matches[1] == "mycontact" and is_sudo(msg) then
	if not msg.from.phone then
		return reply_msg(msg.id, "I must Have Your Phone Number!", ok_cb, false)
    end
    phone = msg.from.phone
    first_name = (msg.from.first_name or msg.from.phone)
    last_name = (msg.from.last_name or msg.from.id)
    send_contact(get_receiver(msg), phone, first_name, last_name, ok_cb, false)
end

    if matches[1] == "dialoglist" then
      get_dialog_list(get_dialog_list_callback, {target = msg.from.id})
      return reply_msg(msg.id, "I've sent a group dialog list with both json and text format to your private messages", ok_cb, false)
    end
    if matches[1] == "whois" then
      user_info("user#id"..matches[2],user_info_callback,{msg=msg})
    end
	if matches[1] == 'reload' then
		receiver = get_receiver(msg)
		reload_plugins(true)
		return reply_msg(msg.id, "#BOT Reloaded By |"..msg.from.id.."| \n#All Plugins Reloaded! \n#All Changes Succesfully Installed.", ok_cb, false)
	end
	if matches[1] == 'updateid' then
		local data = load_data(_config.moderation.data)
		local long_id = data[tostring(msg.to.id)]['long_id']
		if not long_id then
			data[tostring(msg.to.id)]['long_id'] = msg.to.peer_id 
			save_data(_config.moderation.data, data)
			return reply_msg(msg.id, "*Updated ID.", ok_cb, false)
		end
	end
	if matches[1] == 'addlog' and not matches[2] then
		if is_log_group(msg) then
			return reply_msg(msg.id, "*Already a Log SuperGroup", ok_cb, false)
		end
		print("Log_SuperGroup "..msg.to.title.."("..msg.to.id..") added")
		savelog(msg.to.id, name_log.." ["..msg.from.id.."] added Log_SuperGroup")
		logadd(msg)
	end
	if matches[1] == 'remlog' and not matches[2] then
		if not is_log_group(msg) then
			return reply_msg(msg.id,"> #Not a Log SuperGroup", ok_cb, false)
		end
		print("Log_SuperGroup "..msg.to.title.."("..msg.to.id..") removed")
		savelog(msg.to.id, name_log.." ["..msg.from.id.."] added Log_SuperGroup")
		logrem(msg)
	end
    return
end

local function pre_process(msg)
  if not msg.text and msg.media then
    msg.text = '['..msg.media.type..']'
  end
  return msg
end

return {
  patterns = {
	"^[#!/](pm) (%d+) (.*)$",
	"^[#!/](import) (.*)$",
	"^[#!/](markread) (on)$",
	"^[#!/](markread) (off)$",
	"^[#!/](setbotphoto)$",
	"^[#!/](contactlist)$",
	"^[#!/](dialoglist)$",
	"^[#!/](sendcontact) (.*) (.*) (.*)$",
	"^[#!/](mycontact)$",
	"^[#/!](reload)$",
	"^[#/!](updateid)$",
	"^[#/!](addlog)$",
	"^[#/!](remlog)$",
	"^([Pp]m) (%d+) (.*)$",
	"^([Ii]mport) (.*)$",
	"^([Mm]arkread) (on)$",
	"^([Mm]arkread) (off)$",
	"^([Ss]etbotphoto)$",
	"^([Cc]ontactlist)$",
	"^([Dd]ialoglist)$",
	"^([Ss]endcontact) (.*) (.*) (.*)$",
	"^([Mm]ycontact)$",
	"^([Rr]eload)$",
	"^([Uu]pdateid)$",
	"^([Aa]ddlog)$",
	"^([Rr]emlog)$",
	"%[(photo)%]",
  },
  run = run,
  pre_process = pre_process
}
