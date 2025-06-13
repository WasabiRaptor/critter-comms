--[[

 ______     ______     __     ______   ______   ______     ______
/\  ___\   /\  == \   /\ \   /\__  _\ /\__  _\ /\  ___\   /\  == \
\ \ \____  \ \  __<   \ \ \  \/_/\ \/ \/_/\ \/ \ \  __\   \ \  __<
 \ \_____\  \ \_\ \_\  \ \_\    \ \_\    \ \_\  \ \_____\  \ \_\ \_\
  \/_____/   \/_/ /_/   \/_/     \/_/     \/_/   \/_____/   \/_/ /_/

          ______     ______     __    __     __    __     ______
         /\  ___\   /\  __ \   /\ "-./  \   /\ "-./  \   /\  ___\
         \ \ \____  \ \ \/\ \  \ \ \-./\ \  \ \ \-./\ \  \ \___  \
          \ \_____\  \ \_____\  \ \_\ \ \_\  \ \_\ \ \_\  \/\_____\
           \/_____/   \/_____/   \/_/  \/_/   \/_/  \/_/   \/_____/ v1.1

                        fox to fox communication

                        fox to fox conversation

                    Made by Wasabi_Raptor and Zygahedron
                https://github.com/WasabiRaptor/critter-comms
]]

local critter_comms_config = {}
critter_comms_config.persist = true -- whether to save being enabled or not between reloads
critter_comms_config.speak = false  -- critter speak enabled, this turns your words into critter noises
critter_comms_config.brain = false  -- critter brain enabled, this makes it so you can't understand non critter words that aren't whitelisted

-- / commands will never be critterified unless it is /tell

-- if this is true, don't critterify text when whispering to yourself, so whispering a special command to yourself will get it parsed
critter_comms_config.selfWhispers = true

-- map of string matches to appear in chat that activate or deactivate critter speak mode
-- these can be activated by other people saying them or whispering to you
-- these ones will enable or disable you having to talk in critter speak
critter_comms_config.enableSpeak = {
  -- any match strings defined in the list will be accepted as a command
  ["^%!foxspeak true"] = true, -- true means the message will be hidden on recipt
  -- ["silly fox critter"] = false,   -- false means the message will not be hidden on receipt
  -- this second message doesn't have a ^ at the start, so if the phrase is found anywhere in a message, it will activate
}
critter_comms_config.disableSpeak = {
  ["^%!foxspeak false"] = true,
}

-- map of string matches to appear in chat that activate or deactivate critter brain mode
-- these ones will enable and disable you from understanding non-critter speech
critter_comms_config.enableBrain = {
  ["^%!foxbrain true"] = true,
}
critter_comms_config.disableBrain = {
  ["^%!foxbrain false"] = true,
}

-- map of string matches to appear in chat that activate or deactivate both modes at the same time
critter_comms_config.enableAll = {
  ["^%!foxmode true"] = true,
}
critter_comms_config.disableAll = {
  ["^%!foxmode false"] = true,
}

-- command to intentionally speak in critter speak yourself even if above level
critter_comms_config.critterSpeakCommand = "^%!fox "

-- used to whitelist or blacklist usernames from using the activation and deactivation phrases,
critter_comms_config.userListMode = true -- false for blacklist, true for whitelist
critter_comms_config.userList = {
  ["username"] = true,
  -- ["Speaker Block"] = true, -- supplementaries speaker blocks are supported,
  -- regardless of the name of the block they are treated as having the "Speaker Block" username here for the sake of people not using them to get around blacklists

}

-- what kinds of critter speak you speak in, you speak in all of these at once when you send a message,
-- if the recipient understands any of these, your message will be translated for them
-- I reccommend using simple adjectives or nouns here, things that describe your species
critter_comms_config.speakKinds = {
  "critter", -- I reccommend always speaking "critter" even if you aren't set to always understand it, as it is the default and should be universal
  "fox",     -- you probably should speak the type that your species is

  -- potentially, other more broad 'classes' your species falls under
  "carnivore",
  "omnivore",
  "vulpine"
}
-- kinds of critter speak you understand,
critter_comms_config.understandKinds = {
  critter = true, -- I would generally keep this one if you want to understand anyone using the script, remove if you want more species specificity
  fox = true,     -- you should of course, understand your own species

  -- you should probably understand other species similar or close enough to your own
  cat = true,
  dog = true,
  wolf = true,
  coyote = true,

  -- potentially, other more broad 'classes' your species falls under
  carnivore = true,
  omnivore = true,
  vulpine = true

  -- ther may be other more broad 'classes' examples
  -- pokemon = true,
  -- alien = true,
}

-- hex color for the notifications above the hotbar
critter_comms_config.notificationColor = "#E27C21"

-- when the activation phrase has not been used, the script can still roll to replace words
-- it will roll a number between the minimum speech level and the normal speech level for each word spoken
-- if the player's exp level is less than the roll, the word is critterified,
-- the individual word toLower()'s hash is used as the seed for the roll, so each word is consistent regardless of the message or case
-- set these to -1 if you don't want to deal with this and only use activation phrases for critter speech
critter_comms_config.minimumSpeechLevel = 5
critter_comms_config.normalSpeechLevel = 30

-- understanding messages sent by other players will obey mostly the same rules as when critter speak is applied to you
-- what to do when obfuscating a word other people say that you can't understand as a critter
---@type "none" | "random" | "random_font" | "galactic_alphabet" | "illager_runes" | "obfuscated"
critter_comms_config.obfuscateMethod = "random_font"

critter_comms_config.notifications = {
  wordsLost = {
    -- messages when loosing some words, usually from losing levels
    "You're finding it even harder to form words...",
  },
  speechLost = {
    -- messages for when speech is lost fully via the activation phrase or going below minimumSpeechLevel
    "You sense your grip on higher thought slipping away...",
  },
  wordsGained = {
    -- messages when gaining some words, usually from gaining levels or deactivation phrase while below the normalSpeechLevel
    "You think you might be able to form more words...",
  },
  speechGained = {
    -- messages for when speech is regained fully from being above the normalSpeechLevel, and or deactivation phrase while above the level
    "You might be able to fully form words again...",
  },
}
-- for all intents and purposes here, a word is anything that is entirely composed of letters, composed of numbers, or something we explicitly define as a word down below
-- for example, the message "wow! so cool 64 :3c" would be composed of the words, "wow" "so" "cool" "64" "3" "c" because symbols aren't part of words and numbers and letters
-- are treated seperately (however, I have lied here for the sake of an example, as ":3c" is defined as a special word down below in the findWords table)

-- match string to check if a word is allowed to stay the same, this looks like a whitelist but the way things are handled this is technically a blacklist
-- you can learn about the lua patten matching strings here https://www.lua.org/pil/20.2.html
-- a simple explaination of what this is, this is the patten that matches for words critters aren't allowed to say
-- the brackets make a charset, and inside a charset, the ^ gets the complement of the character which is essentially everything that isn't said character
-- so if we only put characters we want, and then put an ^ in front of them, we're actually making a set of every character that isn't these ones to match against
-- if a word contains any character we don't want, it gets scrambled into critter speak
-- the string being matched against is in lowercase
critter_comms_config.speechBlacklist = "[^y^i^p^r^a^w^g]"


-- noises that are used to start words
-- for very short words this will be the entire word, so make sure it can sound nice on its own
critter_comms_config.startNoises = {
  -- noises can be stretched when we detect repeated characters! there is a start, middle, and end, to each sound, the middle gets repeated for repeated chars!
  { "y",  "i", "p" },
  { "y",  "a", "p" },
  { "r",  "a", "wr" },
  { "ra", "w", "r" },
  { "g",  "r", "r" },
  { "a",  "a", "wr" },
  { "a",  "w", "r" },

}

-- noises that are used to extend words to be around the same length as the source word
-- these get attached to the end of start words as well as themselves, make sure these will probably look nice when repeated
critter_comms_config.extendNoises = {
  -- noises can be stretched when we detect repeated characters! there is a start, middle, and end, to each sound, the middle gets repeated for repeated chars!
  { "y", "i", "p" },
  { "y", "a", "p" },
  { "g", "r", "" },
  { "r", "a", "r" },
  { "r", "r", "" },
  { "a", "w", "" },
  { "",  "a", "w" },
  { "",  "a", "" },
}

-- if a word has this number or less characters left, stretch the current noise to the ending rather than add another noise
critter_comms_config.stretchLastNoise = 2

-- randomly stretch the sounds sometimes if that wouldn't exceed the word length
critter_comms_config.randomStretchRange = { 0, 1 }

-- words are replaced in segments, if the percentage of capital characters in the source segment is above this, then the new segment will be allcaps
critter_comms_config.allcapsPercentage = 0.75

-- list of pattern matches used to define words that use symbols or whitespace within them (cannot have whitespace as the starting characters) this is being matched against the message toLower()
-- the lua match escape character % works in front of any non-alphanumeric character 'just in case' so I reccommend using it before any symbols even if they don't do anything in matches
-- the ^ character here behaves differently than within brackets, instead it makes sure the string matches to the beginning of the string being matched against
-- this must be done or the word searching will end up skipping words if the special word here is later in the message
critter_comms_config.findWords = {
  -- contractions
  "^%'m",
  "^%'ve",
  "^%'ll",
  "^%'s",
  "^%'d",
  "^%'re",
  "^%'t",
  "^%'all",

  -- emotes
  "^%:3",
  "^%:3c",

  "^%>w%<",
  "^%>v%<",
  "^%>n%<",

  "^%;w%;",
  "^%;v%;",
  "^%;n%;",

  "^%^w%^",
  "^%^v%^",
  "^%^n%^",
}

-- case seneitive shortcuts to other words that shouldn't translate, usually for emotes or things that contain symbols
critter_comms_config.shortcutWords = {
  thetadelta = "ΘΔ",
}

-- case sensitive words to replace with a specific value, does not go through the same capitalization process everything else does
critter_comms_config.caseSensitiveSpecialWords = {
  I = "Yi",
  i = "yi",
}
-- special words to replace with specific new words
critter_comms_config.specialWords = {
  me = "yi",
  my = "ya",

}

-- words that are intentionally left unchanged by critter speak
critter_comms_config.speakWhitelist = {
  uwu = true,
  uvu = true,
  unu = true,

  owo = true,
  ovo = true,
  ono = true,

  -- these use symbols and letters so they have to be defined in the findWords list to make sure they're detected as a full word rather than just a single letter between some symbols
  [">w<"] = true,
  [">v<"] = true,
  [">n<"] = true,

  ["^w^"] = true,
  ["^v^"] = true,
  ["^n^"] = true,

  [";w;"] = true,
  [";v;"] = true,
  [";n;"] = true,

  [":3"] = true,
  [":3c"] = true,
}

-- words said by other people that are never obfuscated when critter speak is active
-- understanding will also not obfuscate words that are in the speak whitelist
-- I reccommend adding your name and the names of other players you'll interact with alot to this list
-- either break apart usernames with symbols into component words, or define the full name in findWords
critter_comms_config.understandWhitelist = {
  therian = true,
  therians = true,

  furry = true,
  furries = true,

  good = true,
  love = true,
  cute = true,
  cutie = true,
  adorable = true,
  silly = true,
  fluffy = true,
  soft = true,
  scaly = true,
  hard = true,
  bad = true,

  sit = true,
  stay = true,
  fetch = true,
  show = true,
  go = true,
  come = true,
  stop = true,
  move = true,
  run = true,
  walk = true,
  walkies = true,
  eat = true,
  feed = true,
  give = true,
  drop = true,
  hide = true,
  hunt = true,
  chase = true,
  follow = true,

  ["in"] = true,
  out = true,
  inside = true,
  outside = true,

  i = true,
  my = true,
  mine = true,
  me = true,

  he = true,
  she = true,
  it = true,
  they = true,

  him = true,
  them = true,

  his = true,
  her = true,
  its = true,
  their = true,

  this = true,
  that = true,

  boy = true,
  girl = true,
  thing = true,
  critter = true,
  creature = true,
  monster = true,

  bean = true,
  beans = true,
  paw = true,
  paws = true,
  tail = true,
  tails = true,
  legs = true,
  leg = true,
  head = true,
  body = true,
  belly = true,
  ear = true,
  ears = true,

  pet = true,
  pets = true,
  petpet = true,
  petpetpet = true,
  rub = true,
  rubs = true,

  food = true,
  treat = true,
  treats = true,
  snack = true,
  snacks = true,

  red = true,
  orange = true,
  yellow = true,
  lime = true,
  green = true,
  cyan = true,
  blue = true,
  magenta = true,
  purple = true,
  pink = true,
  white = true,
  gray = true,
  grey = true,
  black = true,
  brown = true,

  cow = true,
  cows = true,

  pig = true,
  pigs = true,

  chicken = true,
  chickens = true,

  sheep = true,
  sheeps = true, -- I know thats not the plural but its here anyway

  cat = true,
  cats = true,
  kitty = true,
  kitties = true,
  kitten = true,

  fox = true,
  foxes = true,
  fops = true,
  fop = true,
  foxy = true,
  vixen = true,
  kit = true,

  dog = true,
  dogs = true,
  doggy = true,
  doggies = true,
  pup = true,
  puppy = true,
  buppy = true,

  wolf = true,
  wolves = true,
  wolfs = true,
  cub = true,
  wolp = true,

  coyote = true,
  yote = true,

  rabbit = true,
  rabbits = true,
  bunny = true,
  bnuy = true,
  bnuuy = true,
  bnnuy = true,

  bird = true,
  birds = true,
  birdie = true,
  birdies = true,

  squirrel = true,

  bear = true,

  otter = true,
  oter = true,

  dragon = true,
  dragons = true,

  lizard = true,
  lizards = true,

}

-- pattern match strings for finding containers that should be skipped over and not processed
critter_comms_config.findContainers = {
  "^%b**", -- RP actions
  -- "^%b()",
  -- "^%b[]",
  -- "^%b{}",
  -- "^%b::",
}

return critter_comms_config
