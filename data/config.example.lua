do local _ = {
  enabled_plugins = {
    "plugins",
    "sudo",
    "join",
    "mute",
    "delmsg",
    "id",
    "moderation",
    "user",
    "leave",
  },
  moderation = {
    data = "data/moderation.json"
  },
  sudo_users = {
    123456789,
    123456789
  },
  LOG_ID = "channel#id00000000",-- use chat#id for groups, channel#id for channels/supergroups and user#id for users
  enable_chats = { --this are the ids of the chats [normal groups] where the bot can join, see plugin chatdel.lua, chatid are botapi's chatid * -1
    0123456789,
    9876543210,
  }
}
return _
end
