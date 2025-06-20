# Critter Comms

fox to fox communication

fox to fox conversation

## Disclaimer
This might not fly under certain server rules about not sending encoded messages or only speaking english!
So make sure to double check before using it.

## About
A drop-in figura script for critter-ifying your messages!

This does require you to go into the figura settings and enable the Chat Messages in dev settings to function!

With this script, your messages can be critter-ified into whatever noises you want, and only you, and other players with the script will be able to understand them!

This is not encryption, an encryption based system would be far too large and make messages way too long to be reasonable to see in chat.

Instead, this system randomly generates critter words of similar length to the original words out of a configurable list of noises, using the lowercase original word as a seed so the same critter word is generated for the same word every time. Words can also be configured to always be replaced with a specific value as well. Only letters and numbers count as words, symbols are mostly ignored and left as is aside from a few cases where they are part of words, such as in emotes or contractions.

The message is then sent in chat, there is likely no reasonable way to reverse engineer the original words due to how lossy this is, but not to fear! The script sends a figura script ping containing the data of the original message to the script on other clients, which is then stored as an avatar variable other scripts can retrieve.

When recieving a message, the script will check avatar variables on the sender to determine if they are also a critter, if they are, it will temporarily obfuscate the message until it is able to retrieve the original message's data from that player's avatar variables, and then replace the obfuscated message with a 'translated' one, this is only for your client however! Other players who aren't critters will only ever see the critter-ified versions of the message! You can also configure the 'kinds' of critter speak you speak in, and set it so you can only understand certain other kinds of critters that speak in ways you understand.

(Sometimes the retrieval may fail and the message will remain obfuscated, this seems to be incredibly rare and only happens in moments of high lag)

Critters are also kind of dumb! Critters cannot understand most higher speech words that non-critters are using, so they become unreadable* unless its an important word, like "treat". *(unless you can read Illager runes or Standard Galactic Alphabet)
However, as critters gain more experience, they start to understand more words, and might even be able to speak them!

This is configurable if you only want to intentionally use critter speak via command, or just want to understand the critters, by changing the min and max speech level values in the config to -1.

There are configurable chat commands to lock yourself into critter speak, lock yourself into critter brain, or simply send a single message in critter speak.

By default, the script is configured to whitelist commands to a certain username, which should be changed to your own, however this can be swapped to have it be a blacklist of users to disallow commands from, so instead you can have your friends whisper the commands or say activation phrases to put you in critter mode.

The script is split into two parts:

`critter_comms.lua` Contains the actual script making things happen. Kept seperate so if there are future updates you can simply replace that script and leave your config intact.

`critter_comms_config.lua` Contains the configuration values for everything, I reccommend taking a look at this, you will need to change the username whitelist to include your own if you intend to use the activation commands.
