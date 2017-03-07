local function run(msg, matches)
  if not is_admin(msg) then
    return
  end
  if matches[1]:match("^%d+$") then
    user_info("user#id" .. matches[1], get_user_info, {receiver = get_receiver(msg)})
  elseif matches[1]:match("^-100%d+$") then
    matches[1] = matches[1]:gsub("-100", "channel#id")
    channel_info(matches[1], get_channel_info, {receiver = get_receiver(msg)})
  elseif matches[1]:match("^-%d+$") then
    matches[1] = matches[1]:gsub("-", "chat#id")
    chat_info(matches[1], get_chat_info, {receiver = get_receiver(msg)})
  elseif matches[1]:match("^@?%a%S*$") then
    if matches[1]:starts("@") then
      if not user_info(matches[1], get_user_info, {receiver = get_receiver(msg)}) then
        if not channel_info(matches[1], get_channel_info, {receiver = get_receiver(msg)}) then
          resolve_username(matches[1]:gsub("@", ""),get_username_info, {receiver = get_receiver(msg), query = matches[1]:gsub("@", "")})
        end
      end
    else
      if not user_info("@" .. matches[1], get_user_info, {receiver = get_receiver(msg)}) then
        if not channel_info("@" .. matches[1], get_channel_info, {receiver = get_receiver(msg)}) then
          resolve_username(matches[1], get_username_info, {receiver = get_receiver(msg), query =  matches[1]})
        end
      end
    end
  else
    if msg.to.type == "channel" then
      channel_info("channel#id" .. msg.to.id, get_channel_info, {receiver = get_receiver(msg)})
    elseif msg.to.type == "chat" then
      chat_info("chat#id" .. msg.to.id, get_chat_info, {receiver = get_receiver(msg)})
    end
  end
end

return{
  patterns = {
    "!info (-?%d+)$",
    "!info (@?%a%S+)$",
    "!info$"
  },
  run = run
}
