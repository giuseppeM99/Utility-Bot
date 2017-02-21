local function parsed_url(link)
  local parsed_link = URL.parse(link)
  local parsed_path = URL.parse_path(parsed_link.path)
  if parsed_path[1] == "joinchat" then
    return parsed_path[2], "hash"
  end
  return parsed_path[1], "username"
end

local function join_cb(cb_extra, success, result)
  if success then
    print("logging")
    if result.peer_type == "user" then
      send_large_msg(cb_extra.receiver, "Username @" ..result.username .. " is of an user")
      return ger_user_info({receiver = cb_extra.receiver}, true, result)
    end
    if not channel_join("channel#id" .. result.peer_id, ok_cb, nil) then
      send_large_msg(cb_extra.receiver, "Failed join channel -100"..result.peer_id)
    end
  else
    send_large_msg(cb_extra.receiver, "Username @" .. cb_extra.query .. " does not exist")
  end
end
local function run(msg, matches)
  if is_admin(msg) then
    if matches[1]:starts("https://") or matches[1]:starts("http://") then
      local hash, what = parsed_url(matches[1])
      if what == "hash" then
        res = import_chat_link(hash, ok_cb, nil)
        if res then
          return "Joined"
        else
          return "Can't join " .. hash
        end
      elseif what == "username" then
        resolve_username(hash, join_cb, {receiver = get_receiver(msg), query = hash})
        return
      end
    end
    if matches[1]:match("^t%.me/%w+/?[%S+]?$") or matches[1]:match("^telegram%.me/%w+/?[%S+]?$") then
      local hash, what = parsed_url("https://" .. matches[1])
      print(hash)
      print(what)
      print(matches[1])
      if what == "hash" then
        res = import_chat_link(hash, ok_cb, nil)
        if res then
          return "Joined"
        else
          return "Can't join " .. hash
        end
      elseif what == "username" then
        resolve_username(hash, join_cb, {receiver = get_receiver(msg), query = hash})
        return
      end
    end
  else
    return nil
  end
end

return {
  description = "Invite bot into a group chat",
  usage = "!join [invite link]",
  patterns = {
    "^!join (.*)$"
  },
  run = run
}
