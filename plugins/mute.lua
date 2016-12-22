local function mute_reply(extra, success, result)
  local hash = 'mute:'..result.to.peer_id..':'..result.from.peer_id
  redis:set(hash, true)
end

local function delmute_reply(extra, success, result)
  local hash = 'mute:'..result.to.peer_id..':'..result.from.peer_id
  local reply
  if redis:get(hash) then
    redis:del(hash)
  end
end

local function resolved_username(extra, success, result)
  if success then
    local hash = 'mute:'..extra.chat_id..':'..result.peer_id
    if extra.get_cmd == 'user' then
      redis:set(hash, true)
      snoop_msg("Utente " .. result.peer_id " mutato nel gruppo " .. extra.chat_id)
    end
    if extra.get_cmd == 'delete' then
      if redis:get(hash) then
        redis:del(hash)
        snoop_msg("Utente " .. result.peer_id " smutato nel gruppo " .. extra.chat_id)
      end
    end
    if extra.get_cmd == "check" then
      if redis:get(hash) then
        send_large_msg(extra.receiver, "User is muted")
      else send_large_msg(extra.receiver, "User isn't muted") end
    end
  end
end

local function run (msg, matches)
  if matches[1] ~= nil then
    if not is_chan_msg(msg) then
      return nil
    else
      if is_momod(msg) then
        local chat = msg.to.id
        local hash = 'anti-spam:enabled:'..chat
        if matches[1] == 'mute' then
          if msg.reply_id then
            get_message(msg.reply_id, mute_reply, get_receiver(msg))
            return nil
          end
        end
        if matches[1] == 'unmute' then
          if msg.reply_id then
            get_message(msg.reply_id, delmute_reply, get_receiver(msg))
            return nil
          end
        end
        if matches[1] == 'all' then
          local hash = 'mute:'..msg.to.id..':all'
          redis:set(hash, true)
        end
        if matches[1] == 'undo' then
          local hash = 'mute:'..msg.to.id..':all'
          redis:del(hash)
        end
        if matches[2] then
          if matches[2] == 'service' then
            local hash = 'mute:'..msg.to.id':tgservice'
            if matches[1] == 'user' then
              redis:set(hash, true)
            end
            if matches[1] == 'delete' then
              if redis:get(hash) then
                redis:del(hash)
              end
            end
          end
          if string.match(matches[2], '^%d+$') then
            local hash = 'mute:'..msg.to.id..':'..matches[2]
            if matches[1] == 'user' and not is_mod(matches[2], msg.to.id) then
              redis:set(hash, true)
              if not msg.from.username == nil then
                local text = "Utente " .. matches[2] .. "mutato da " .. msg.from.username .." " ..msg.from.id .. " nel gruppo " .. msg.to.print_name " " .. msg.to.id
              else
                local text = "Utente " .. matches[2] .. "mutato da " .. msg.from.print_name .." " ..msg.from.id .. " nel gruppo " .. msg.to.print_name " " .. msg.to.id
              end
              snoop_msg(text)
            end
            if matches[1] == 'delete' then
              if redis:get(hash) then
                redis:del(hash)
                if not msg.from.username == nil then
                  local text = "Utente " .. matches[2] .. "smutato da " .. msg.from.username .." " ..msg.from.id .. " nel gruppo " .. msg.to.print_name " " .. msg.to.id
                else
                  local text = "Utente " .. matches[2] .. "smutato da " .. msg.from.print_name .." " ..msg.from.id .. " nel gruppo " .. msg.to.print_name " " .. msg.to.id
                end
                snoop_msg(text)
              end
            end
            if matches[1] == 'check' then
              if redis:get(hash) then
                return "User is muted"
              else return "User is not muted" end
            end
          else
            local member = string.gsub(matches[2], '@', '')
            return resolve_username(member, resolved_username, {get_cmd=matches[1], receiver=get_receiver(msg), chat_id=msg.to.id, member=member})
          end
        end
      else
        return nil
      end
    end
  end
  return nil
end

local function pre_process(msg)
  -- Ignore service msg
  if msg.service then
    print('Service message')
    return msg
  end

  local hash_muted = 'mute:'..msg.to.id..':'..msg.from.id
  local hash_all_muted = 'mute:'..msg.to.id..':all'
  local hash_tgservice_muted = 'mute:'..msg.to.id..':tgservice'
  local muted = redis:get(hash_muted) or redis:get(hash_all_muted) or redis:get(hash_tgservice_muted)

  if is_momod(msg) then
    return msg
  end

  if muted then
    delete_msg(msg.id, ok_cb, nil)
    return nil
  end

  return msg
end

return {
  description = 'Plugin to mute people on supergroups.',
  usage = {
    moderator = {
      "!mute user username/id : Mute an user on current supergroup",
      "!mute delete username/id : Unmute an user on current supergroup",
      "!mute user service: Delete automatically tg service messages on current supergroup",
      "!mute delete service: Remove autodelete for tg service messages on supergroup",
      "!mute all : Mute all users on current supergroup (except mods)",
      "!mute undo : Stop muting all users on current supergroup",
      "#mute (by reply) : Mute an user on current supergroup",
      "#unmute (by reply) : Unmute an user on current supergroup"
    },
  },
  patterns = {
    '!mute (user) (.*) .*$',
    '!mute (delete) (.*) .*$',
    '!mute (all) .*$',
    '!mute (undo) .*$',
    '#(mute) .*$',
    '#(unmute) .*$',
    "#(mute)$",
    "#(unmute)$",
    "!mute (check) (.*)$"
  },
  run = run,
  pre_process = pre_process
}
