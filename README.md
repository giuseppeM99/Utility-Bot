Utility Bot (telegram-bot)
============

A Telegram Bot based on plugins using [tg](https://github.com/Rondoozle/tg). Forked from [Lucentw's s-uzzbot](https://github.com/LucentW/s-uzzbot.git).

[Installation](https://github.com/yagop/telegram-bot/wiki/Installation)
------------
```bash
# Tested on Debian 7, for other OSes check out https://github.com/yagop/telegram-bot/wiki/Installation
sudo apt-get install libreadline-dev libconfig-dev libssl-dev lua5.2 liblua5.2-dev libevent-dev make unzip git redis-server g++ libjansson-dev libpython-dev expat libexpat1-dev
```

```bash
# After installing the dependencies, install the bot
cd $HOME
git clone https://github.com/giuseppeM99/Utility-Bot.git
cd Utility-Bot
./launch.sh install
./launch.sh # Will ask you for a phone number & confirmation code.
```

There are two more scripts to launch the bot: `launchd.sh` will run tg-cli over gdb, `launchf.sh` will take care of restarting the bot in case it crashes, deleting tg-cli's `state` file to prevent reparsing buggy/broken messages.

Usage
------------
For the correct usage of Utility-Bot, you need:
1) A Bot Admin. You can use either a clone of an official supported bot or you can make your own
2) A Main control group (Private), where there have to be the sudoers (userbot, apibot and Creators)

You must edit the file data/config.lua : insert the sudoers ids and the main group id


Enable more [`plugins`](https://github.com/LucentW/s-uzzbot/tree/master/plugins)
-------------
This instance support all the plugins from other forks of s-uzzbot, 


Run it as a daemon
------------
If your Linux/Unix comes with [upstart](http://upstart.ubuntu.com/) you can run the bot by this way
```bash
$ sed -i "s/yourusername/$(whoami)/g" etc/utilitybot.conf
$ sed -i "s_telegrambotpath_$(pwd)_g" etc/utilitybot.conf
$ sudo cp etc/utility-bot.conf /etc/init/
$ sudo start utility-bot # To start it
$ sudo stop utility-bot # To stop it
```

Official supported bot
------------
- [@GroupHelpBot](https://telegram.me/GroupHelpBot)
- [@ControlPanelGroupBot](https://telegram.me/ControlPanelGroupBot)

Credits:
------------
- [@LucentW](https://telegram.me/LucentW) for the original [s-uzzbot](https://github.com/LucentW/s-uzzbot.git)
- [@BruninoIt](https://telegram.me/BruninoIt) for the idea of a complementary userbot
- [@giuseppeM99](https://telegram.me/giuseppeM99) 

