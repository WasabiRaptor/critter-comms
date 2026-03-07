# Critter Comms

fox to fox communication

fox to fox conversation

## Disclaimer
This might not fly under certain server rules about not sending encoded messages or only speaking english!
So make sure to double check before using it.

## About
A drop-in figura script for critter-ifying your messages!

This does require you to go into the figura settings and enable the Chat Messages in dev settings to function!

With this script, your messages can be critter-ified into whatever noises you want, and only you, and other players with the script will be able to understand them! You can also optionally, make yourself unable to understand players who aren't using the script, or only understand certain other kinds of critters, its all increcibly configurable!

### How to use

First, copy `critter_comms.lua` and `critter_comms_config.lua` into your figura avatar's folder.

If you're updating from a previous version of the script, you only need to replace `critter_comms.lua`, if the script doesn't work, you may need to copy any new values in `critter_comms_config.lua` that are missing into your existing config file.

Open `critter_comms_config.lua` in your favorite text editor, preferably one that can provide you with lua syntax highlighting.

Peruse the values in the config file for any you may want to change, such as what sounds words are scrambled into, what words are whitelisted to leave unchanged, etc. Every value in the config should have a comment explaining what it is, and what it does.

Of certain importance is the command prefix, which is used for the chat commands to control the script, the default prefix is `"!cc"` which would result in commands being sent like `"!cc speak true"` which would enable critter speak on the recipient if the sender is on the whitelist. By default the user list mode is a whitelist, you will have to add your own username to this whitelist.

All existing commands are listed in the config, one can also define an alias to inputting a command with specific arguments in the `commandPhrases` config value.


### How it works
This is not encryption, an encryption based system would be far too large and make messages way too long to be reasonable to see in chat.

Instead, this system randomly generates critter words of similar length to the original words out of a configurable list of noises, using the lowercase original word as a seed so the same critter word is generated for the same word every time. Words can also be configured to always be replaced with a specific value as well. Only letters and numbers count as words, symbols are mostly ignored and left as is aside from a few cases where they are part of words, such as in emotes or contractions.

The message is then sent in chat, there is likely no reasonable way to reverse engineer the original words due to how lossy this is, but not to fear! The script sends a figura script ping containing the data of the original message to the script on other clients, which is then stored as an avatar variable other scripts can retrieve.

When recieving a message, the script will check avatar variables on the sender to determine if they are also a critter, if they are, it will temporarily obfuscate the message until it is able to retrieve the original message's data from that player's avatar variables, and then replace the obfuscated message with a 'translated' one, this is only for your client however! Other players who aren't critters will only ever see the critter-ified versions of the message! You can also configure the 'kinds' of critter speak you speak in, and set it so you can only understand certain other kinds of critters that speak in ways you understand.

(Sometimes the retrieval may fail and the message will remain obfuscated, this seems to be incredibly rare and only happens in moments of high lag)

If you're configured in a way that you aren't able to understand most higher speech words that non-critters are using, they become unreadable unless its an important word, like "treat".
