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
           \/_____/   \/_____/   \/_/  \/_/   \/_/  \/_/   \/_____/ v1.1.2

                        fox to fox communication

                        fox to fox conversation

                    Made by Wasabi_Raptor and Zygahedron
                https://github.com/WasabiRaptor/critter-comms
]]

-- print("reloaded")

-- workaround to detectt if chat commands are enabled (thank you grandpa_scout)
if host:isHost() then
  CHAT_ENABLED = false
  host:sendChatCommand("figura run CHAT_ENABLED = true")

  if not CHAT_ENABLED then
    printJson(toJson({
      text = "Enable 'Chat Messages' in figura dev settings for Critter Comms to function.",
      color = "#FF0000",
    }))
  end
  -- Remove the evidence.
  CHAT_ENABLED = nil
end
local cc = {
  config = require("critter_comms_config"),
  commands = {},
  messageNumber = 0,
  prevLevel = 0,
  temp = {
    brain = {
      messages = 0,
      time = 0
    },
    speak = {
      messages = 0,
      time = 0
    },
    all = {
      messages = 0,
      time = 0
    }
  },
  stolenWords = {}
}

avatar:store("isCritter", true)
avatar:store("speakKinds", cc.config.speakKinds or { "critter" })
avatar:store("messageNumber", cc.messageNumber)
if cc.config.persist and config:load("critterPersist") then
  cc.config.speak = config:load("critterSpeak") or false
  cc.config.brain = config:load("critterBrain") or false
  cc.config.debug = config:load("critterDebug") or false
else
  config:save("critterPersist", cc.config.persist)
  config:save("critterSpeak", cc.config.speak)
  config:save("critterBrain", cc.config.brain)
  config:save("critterDebug", cc.config.debug)
end
if cc.config.debug then print("Critter Comms debug messages are enabled.") end

---@param randomRoll boolean
---@return boolean
function cc.checkCritterBrain(randomRoll)
  return cc.config.brain
    or (cc.temp.all.time > 0)
    or (cc.temp.all.messages > 0)
    or (cc.temp.brain.time > 0)
    or (cc.temp.brain.messages > 1)
    or ((randomRoll and math.random(table.unpack(cc.config.speechLevels)) or cc.config.speechLevels[1]) > player:getExperienceLevel())

end

---@param randomRoll boolean
---@return boolean
function cc.checkCritterSpeak(randomRoll)
  return cc.config.brain
      or (cc.temp.all.time > 0)
      or (cc.temp.all.messages > 0)
      or (cc.temp.speak.time > 0)
      or (cc.temp.speak.messages > 1)
      or ((randomRoll and math.random(table.unpack(cc.config.speechLevels)) or cc.config.speechLevels[1]) > player:getExperienceLevel())
end

---@return boolean
function cc.checkWordsGained()
  local level = player:getExperienceLevel()
  return (level > cc.prevLevel) and (cc.config.speechLevels[1] < level) and (cc.config.speechLevels[2] > level)
end
---@return boolean
function cc.checkWordsLost()
  local level = player:getExperienceLevel()
  return (level < cc.prevLevel) and (cc.config.speechLevels[1] < level) and (cc.config.speechLevels[2] > level)
end

---@param str string
---@return integer
function cc.hashString(str)
  local hash = 5381
  for i = 1, #str do
    hash = math.fmod(hash * 33 + str:byte(i), 2147483648)
  end
  return hash
end
function cc.condenseText(textTable)
  if type(textTable) == "table" and textTable[1] then
    local out = ""
    for _, v in ipairs(textTable) do
      out = out .. (cc.condenseText(v) or "")
    end
    return out
  elseif type(textTable) == "table" and textTable.text then
    return textTable.text
  elseif type(textTable) == "string" then
    return textTable
  end
end


---comment
---@param curWord string
---@param newWord string
---@param noiseTable table
---@return string
function cc.addNoise(curWord, newWord, noiseTable)
  local start, middle, ending = table.unpack(noiseTable[math.random(#noiseTable)])
  local noise = start .. middle .. ending
  local noisecount = 1
  while (noise:sub(1, 1) == newWord:sub(-1, -1)) and (noisecount < #noiseTable) do
    start, middle, ending = table.unpack(noiseTable[math.random(#noiseTable)])
    noise = start .. middle .. ending
    noisecount = noisecount + 1
  end

  local from, to = curWord:find("^" .. curWord:sub((#newWord + #noise + 1), #newWord + #noise + 1) .. "+",
    #newWord + #noise + 2) -- check if the same character has been repeated
  if not to then
    if ((#newWord + #noise + cc.config.stretchLastNoise) >= #curWord) then
      to = #curWord
    elseif ((#newWord + #noise + cc.config.randomStretchRange[2]) <= #curWord) then
      to = #newWord + #noise + math.random(table.unpack(cc.config.randomStretchRange))
    end
  end
  local substituting = curWord:sub(#newWord, to)

  local _, uppercaseCount = substituting:gsub("%u", "")
  local _, letterCount = substituting:gsub("%a", "")
  if uppercaseCount > (letterCount * cc.config.allcapsPercentage) then
    start, middle, ending = start:upper(), middle:upper(), ending:upper()
  end
  newWord = newWord .. start
    newWord = newWord .. middle
  if #middle > 0 then
    while #newWord < (to - #ending) do
      newWord = newWord .. middle
    end
  end
  newWord = newWord .. ending

  return newWord
end

function cc.hotBarNotification(notif)
  host:setActionbar(toJson({
    { text = notif[math.random(#notif)], color = cc.config.notificationColor },
  }), true)
end

function cc.correctCapitalization(curWord, newWord)
  if curWord:sub(1, 1):find("^%u") then
    newWord = newWord:sub(1, 1):upper() .. newWord:sub(2, -1)
  end
  return newWord
end

function cc.findNextWord(msg, pos)
  local wordStart, wordEnd
  local _, whitespace = msg:find("^%s+", pos)
  if whitespace then
    pos = whitespace + 1
  end
  for _, v in ipairs(cc.config.findContainers) do
    local foundContainer_1, foundContainer_2 = msg:find(v, pos)
    if foundContainer_1 and foundContainer_2 then
      return cc.findNextWord(msg, foundContainer_2 + 1)
    end
  end
  local lower = msg:lower()
  for _, v in ipairs(cc.config.findWords) do
    local foundWord_1, foundWord_2 = lower:find(v, pos)
    if foundWord_1 and foundWord_2 then
      return foundWord_1, foundWord_2
    end
  end

  local foundLetter_1, foundLetter_2 = lower:find("%a+", pos) -- find letters
  local foundDigit_1, foundDigit_2 = lower:find("%d+", pos)   -- find digits

  if foundLetter_1 and foundDigit_1 then
    if foundLetter_1 < foundDigit_1 then
      wordStart = foundLetter_1
      wordEnd = foundLetter_2
    else
      wordStart = foundDigit_1
      wordEnd = foundDigit_2
    end
  elseif foundLetter_1 then
    wordStart = foundLetter_1
    wordEnd = foundLetter_2
  elseif foundDigit_1 then
    wordStart = foundDigit_1
    wordEnd = foundDigit_2
  end

  return wordStart, wordEnd
end

local _Message = {}
_Message.__index = _Message

function _Message:new(message)
  local newMessage = {
    message = message or {},
  }
  setmetatable(newMessage, _Message)
  return newMessage
end

function _Message:append(word, newWord)
  table.insert(self.message, { word, newWord })
end

function _Message:getString()
  local out = ""
  for _, v in ipairs(self.message) do
    local word, newWord = table.unpack(v)
    out = out .. ((type(newWord) == "string") and newWord or word)
  end
  return out
end

function _Message:critterParse(isCritter, canUnderstand)
  if not player:isLoaded() then return end
  local level = player:getExperienceLevel()
  local out = {}
  if isCritter then
    local wordsTranslated = 0
    for i, v in ipairs(self.message) do
      local word, newWord = table.unpack(v)
      math.randomseed(cc.hashString(word:lower())) -- set the seed to the hash of the word so any randomness with that word is consistent
      if newWord -- critter word or something else critters can understand so use original word
          or (not cc.checkCritterBrain(true)) -- if not a critter word, check if we can understand it
          or cc.config.obfuscateMethod == "none"
          or cc.config.understandWhitelist[word:lower()]
          or cc.config.speakWhitelist[word:lower()]
      then
        table.insert(out, {
          text = ((type(newWord) == "string") and newWord or word),
          obfuscated = false,
          font = "default",
        })
        if type(newWord) == "string" then
          wordsTranslated = wordsTranslated + 1
        end
      else -- not a word we can understand, obfuscate in some way
        local obfuscate = cc.config.obfuscateMethod
        if obfuscate == "random" then
          obfuscate = ({ "galactic_alphabet", "illager_runes", "obfuscated" })
              [math.random(3)]
        elseif obfuscate == "random_font" then
          obfuscate = ({ "galactic_alphabet", "illager_runes" })[math.random(2)]
        end
        if obfuscate == "obfuscated" then
          table.insert(out, {
            text = word,
            obfuscated = true,
            font = ({ "alt", "illageralt" })[math.random(2)],
          })
        elseif obfuscate == "galactic_alphabet" then
          table.insert(out, {
            text = word,
            font = "alt",
            obfuscated = false,
          })
        elseif obfuscate == "illager_runes" then
          table.insert(out, {
            text = word,
            font = "illageralt",
            obfuscated = false,
          })
        end
      end
    end
    if (not canUnderstand) or (wordsTranslated < 1) then return out end
    table.insert(out, {
      text = "\n -> ",
      color = "gray",
      font = "default",
      obfuscated = false,
    })
  end

  for i, v in ipairs(self.message) do
    local word, newWord = table.unpack(v)
    math.randomseed(cc.hashString(word:lower())) -- set the seed to the hash of the word so any randomness with that word is consistent
    if newWord -- critter word or something else critters can understand so use original word
        or (not cc.checkCritterBrain(true)) -- if not a critter word, check if we can understand it
        or cc.config.obfuscateMethod == "none"
        or cc.config.understandWhitelist[word:lower()]
        or cc.config.speakWhitelist[word:lower()]
    then
      table.insert(out, {
        text = word,
        obfuscated = false,
        font = "default",
        color = isCritter and "gray",
      })
    else -- not a word we can understand, obfuscate in some way
      local obfuscate = cc.config.obfuscateMethod
      if obfuscate == "random" then
        obfuscate = ({ "galactic_alphabet", "illager_runes", "obfuscated" })[math.random(3)]
      elseif obfuscate == "random_font" then
        obfuscate = ({ "galactic_alphabet", "illager_runes" })[math.random(2)]
      end
      if obfuscate == "obfuscated" then
        table.insert(out, {
          text = word,
          obfuscated = true,
          font = ({ "alt", "illageralt" })[math.random(2)],
          color = isCritter and "gray",
        })
      elseif obfuscate == "galactic_alphabet" then
        table.insert(out, {
          text = word,
          font = "alt",
          obfuscated = false,
          color = isCritter and "gray",
        })
      elseif obfuscate == "illager_runes" then
        table.insert(out, {
          text = word,
          font = "illageralt",
          obfuscated = false,
          color = isCritter and "gray",
        })
      end
    end
  end
  return out
end

function _Message:ping()
  pings.sent_chat_message(toJson(self.message))
end

cc.backlog = {
  "a",
  "a",
  "a",
  "a",
  "a",
  "a",
  "a",
  "a",
  "a",

}
function pings.sent_chat_message(messageJson)
  local message = _Message:new(parseJson(messageJson))
  cc.messageNumber = cc.messageNumber + 1
  local str = message:getString()
  avatar:store("msg:" .. str, message.message)
  avatar:store("msgNum:" .. str, cc.messageNumber)
  avatar:store("messageNumber", cc.messageNumber)
  table.insert(cc.backlog, str)
  local old = table.remove(cc.backlog, 1)
  if (old ~= str) and (old ~= cc.backlog[#cc.backlog-1]) and (old ~= cc.backlog[#cc.backlog-2]) and (old ~= cc.backlog[#cc.backlog-3]) and (old ~= cc.backlog[#cc.backlog-4]) then
    avatar:store("msg:" .. old)
    avatar:store("msgNum:" .. old)
  end
end

function events.entity_init()
  cc.prevLevel = player:getExperienceLevel()
end

function cc.parseNameplate(input)
  if input then
    return cc.condenseText(parseJson(input))
  end
end
function cc.postInit()
  -- add all words in player's name to the understand whitelist so they can always know when people are talking about them
  -- for _, name in ipairs({
  -- 	player:getName(),
  -- 	parseNameplate(nameplate.CHAT:getText()) or false,
  -- 	parseNameplate(nameplate.ENTITY:getText()) or false,
  -- 	parseNameplate(nameplate.LIST:getText()) or false,
  -- }) do
  -- 	if name then
  -- 		local length = #name
  -- 		local pos = 1
  -- 		while pos <= length do
  -- 			local wordStart, wordEnd = findNextWord(name, pos)
  -- 			if wordStart then
  -- 				pos = wordEnd + 1
  -- 				local curWord = name:sub(wordStart, wordEnd)
  -- 				understandWhitelist[curWord:lower()] = true
  -- 			end
  -- 			if not pos then break end
  -- 		end
  -- 	end
  -- end
end

function events.chat_send_message(message)
  if not player:isLoaded() then return message end

  local wordsReplaced = 0
  local prepend = ""
  local length = #message
  local newMessage = _Message:new()
  local pos = 1
  if message:find("^/") then
    local _, tell = message:find("^/tell ")
    if tell then
      local ws1, ws2 = message:find("%s+", tell + 1)
      prepend = message:sub(1, ws2)
      pos = ws2 + 1
      if message:sub(tell + 1, ws1 - 1) == player:getName() and cc.config.selfWhispers then
        newMessage:append(message:sub(pos, -1), true)
        newMessage:ping()
        return message
      end
    else
      return message
    end
  elseif message == "!debug" then
    cc.config.debug = not cc.config.debug
    config:save("debug", cc.config.debug)
    print(cc.config.debug and "Critter Comms debug messages enabled." or "Critter Comms debug messages disabled.")
    return
  end

  local intentional, f2 = message:find(cc.config.critterSpeakCommand, pos)
  if intentional and f2 then
    pos = f2 + 1
  end

  while pos <= length do
    local wordStart, wordEnd = cc.findNextWord(message, pos)
    if wordStart then
      if pos < wordStart then
        local misc = message:sub(pos, wordStart - 1)
        newMessage:append(misc, true) -- copy whatever was between the previous word and this one
      end
      pos = wordEnd + 1
      local curWord = message:sub(wordStart, wordEnd)
      local curWordLower = curWord:lower()
      math.randomseed(cc.hashString(curWordLower)) -- set the seed to the hash of the word so any randomness with that word is consistent

      if cc.config.shortcutWords[curWord] then
        newMessage:append(cc.config.shortcutWords[curWord], true)
      elseif cc.config.speakWhitelist[curWordLower] then
        newMessage:append(curWord, true)
      elseif not (curWordLower:find(cc.config.speechBlacklist) or cc.config.caseSensitiveSpecialWords[curWord] or cc.config.specialWords[curWordLower]) then -- doesn't have any blacklisted characters and isn't a special word, copy as is and don't do any rolls
        newMessage:append(curWord, true)
      elseif not (intentional or cc.stolenWords[curWordLower] or cc.checkCritterSpeak(true)) then -- intentionally speaking in critter speak, or failed speak checks
        newMessage:append(curWord)
      else
        wordsReplaced = wordsReplaced + 1
        if cc.config.caseSensitiveSpecialWords[curWord] then
          local newWord = cc.config.caseSensitiveSpecialWords[curWord]
          newMessage:append(curWord, newWord)
        elseif cc.config.specialWords[curWordLower] then
          local newWord = cc.config.specialWords[curWordLower]
          local _, uppercaseCount = curWord:gsub("%u", "")
          if uppercaseCount > (#curWord * cc.config.allcapsPercentage) then
            newWord = newWord:upper()
          end
          newMessage:append(curWord, cc.correctCapitalization(curWord, newWord))
        else -- word contained blacklisted characters, did not succeed random rolls to be allowed, and was not a special case word, so we replace it with noises
          local newWord = cc.addNoise(curWord, "", cc.config.startNoises)
          if (#newWord < #curWord) then
            while #newWord < #curWord do
              newWord = cc.addNoise(curWord, newWord, cc.config.extendNoises)
            end
          end
          newMessage:append(curWord,
            cc.correctCapitalization(curWord, newWord))
        end
      end
    else -- no more words found, copy the remaining characters to the new message
      local curWord = message:sub(pos, -1)
      newMessage:append(curWord, true)
      break -- exit the loop
    end
    if not pos then break end
  end
  if cc.config.debug then print("original message: ", message) end
  host:appendChatHistory(message)
  newMessage:ping()
  cc.temp.all.messages = math.max((cc.temp.all.messages -1), 0)
  cc.temp.speak.messages = math.max((cc.temp.speak.messages -1), 0)
  return prepend .. newMessage:getString()
end

local translationParseBlacklist = {
  ["chat.type.emote"] = true,
  [""] = true,

}
local critterMessageQueue = {
}
local userLastMessageNumber = {

}
function cc.processCommand(message, allow)
  local hide = false
  local prefixStart, prefixEnd = message:find(cc.config.commandPrefix)
  local command
  if prefixStart and prefixEnd then
    hide = true
    local commandStart, commandEnd = cc.findNextWord(message, prefixEnd+1)
    command = {
      command = message:sub(commandStart, commandEnd),
      args = {}
    }
    local pos = commandEnd + 1
    local length = #message
    while pos <= length do
      local wordStart, wordEnd = cc.findNextWord(message, pos)
      if wordStart and wordEnd then
        pos = wordEnd + 1
        local word = message:sub(wordStart, wordEnd):toLower()
        if word == "true" then
          table.insert(command.args, true)
        elseif word == "false" then
          table.insert(command.args, false)
        elseif tonumber(word) then
          table.insert(command.args, tonumber(word))
        else
          table.insert(command.args, word)
        end
      else
        break
      end
    end
  else
    for commandPhrase, v in pairs(cc.config.commandPhrases) do
      if message:toLower():find(commandPhrase) then
        command = v
        break
      end
    end
  end
  if command and allow then
    cc.commands[command.command](table.unpack(command.args))
  elseif command then

  end
  return hide
end
function cc.commands.speak(enable)
  local wasEnabled = (cc.checkCritterBrain(false) or cc.checkCritterSpeak(false))
  cc.config.speak = enable
  local isEnabled = (cc.checkCritterBrain(false) or cc.checkCritterSpeak(false))
  if isEnabled and not wasEnabled then
    cc.hotBarNotification(cc.config.notifications.speechLost)
  elseif wasEnabled and not isEnabled then
    cc.hotBarNotification(cc.config.notifications.speechGained)
  elseif cc.checkWordsGained() then
    cc.hotBarNotification(cc.config.notifications.wordsGained)
  elseif cc.checkWordsLost() then
    cc.hotBarNotification(cc.config.notifications.wordsLost)
  end
  config:save("critterSpeak", cc.config.speak)
end
function cc.commands.brain(enable)
  local wasEnabled = (cc.checkCritterBrain(false) or cc.checkCritterSpeak(false))
  cc.config.brain = enable
  local isEnabled = (cc.checkCritterBrain(false) or cc.checkCritterSpeak(false))
  if isEnabled and not wasEnabled then
    cc.hotBarNotification(cc.config.notifications.speechLost)
  elseif wasEnabled and not isEnabled then
    cc.hotBarNotification(cc.config.notifications.speechGained)
  elseif cc.checkWordsGained() then
    cc.hotBarNotification(cc.config.notifications.wordsGained)
  elseif cc.checkWordsLost() then
    cc.hotBarNotification(cc.config.notifications.wordsLost)
  end
  config:save("critterBrain", cc.config.brain)
end
function cc.commands.all(enable)
  cc.commands.speak(enable)
  cc.commands.brain(enable)
end

function cc.commands.addTime(name, time)
  cc.temp[name].time = cc.temp[name].time + (time * 60)
end
function cc.commands.setTime(name, time)
  cc.temp[name].time = (time * 60)
end

function cc.commands.addMessages(name, messages)
  cc.temp[name].messages = cc.temp[name].messages + messages
end
function cc.commands.setMessages(name, messages)
  cc.temp[name].messages = messages
end


function events.chat_receive_message(raw, text)
  if not player:isLoaded() then return end
  if raw:find("^%[lua%]") then return end
  local messageTable = parseJson(text)
  if cc.config.debug then
    print("received message.")
    printTable(messageTable, 3)
  end

  local username = ((messageTable.with or {})[1] or {}).insertion
  local uuid = ((((messageTable.with or {})[1] or {}).hoverEvent or {}).contents or {}).id
  local message = cc.condenseText((messageTable.with or {})[2])
  local valid = not (
    (messageTable.with or {})[3]
    or translationParseBlacklist[(messageTable.translate or "")]
  )
  local outgoing = messageTable.translate == "commands.message.display.outgoing"
  local incoming = messageTable.translate == "commands.message.display.incoming"
  if outgoing then -- because outgoing whispers show the other person's name, but you're the one sending the message
    username = player:getName()
    uuid = player:getUUID()
  end

  local speakerBlock = false
  if messageTable.italic and type(messageTable.text) == "string" then -- check for it potentially being supplementaries speaker blocks
    local findMessage_1, findMessage_2 = messageTable.text:find("%:%s+")
    if findMessage_1 and findMessage_2 then
      speakerBlock = messageTable.text:sub(1, findMessage_2)
      username = "Speaker Block"
      message = messageTable.text:sub(findMessage_2 + 1, -1)
    end
  end

  if type(uuid) == "table" then
    uuid = client.intUUIDToString(table.unpack(uuid))
  end
  if username and (type(message) == "string") and (valid or speakerBlock) then
    local allowCommand = true
    if cc.config.userListMode then -- whitelist, do nothing if not in list
      if not cc.config.userList[username] then allowCommand = false end
    else                                      -- blacklist, do nothing if in the list
      if cc.config.userList[username] then allowCommand = false end
    end

    if not outgoing then
      if cc.processCommand(message, allowCommand) then return false end
    end
    if (incoming and (player:getName() == username)) then return end

    if uuid then
      local variables = world:avatarVars()[uuid] or {}
      local isCritter = variables.isCritter
      if isCritter then
        local critterMessage = variables["msg:" .. message]
        local critterMessageNum = variables["msgNum:" .. message]
        local newMessageNumber = variables.messageNumber or 0
        local lastMessageNumber = userLastMessageNumber[username] or 0
        if newMessageNumber < lastMessageNumber then
          userLastMessageNumber[username] = 0
          lastMessageNumber = 0
        end

        local canUnderstand = true
        for _, v in ipairs(variables.speakKinds or {}) do
          canUnderstand = (cc.config.understandKinds or {})[v] or false
          if canUnderstand then break end
        end

        if critterMessage and (newMessageNumber > lastMessageNumber) then
          userLastMessageNumber[username] = critterMessageNum or (lastMessageNumber + 1)
          messageTable.with[2] = _Message:new(critterMessage):critterParse(true, canUnderstand)
          return toJson(messageTable)
        else
          if cc.config.debug then print("obfuscating critter message, adding message to parsing queue.") end
          messageTable.with[2] = { text = message, obfuscated = true, font = "alt" } -- temporarily obfuscate until we can parse it with the critter message data
          table.insert(critterMessageQueue, {
            username = username or "",
            uuid = uuid or "",
            message = message or "",
            canUnderstand = canUnderstand or false,
            attempts = 0
          })
          return toJson(messageTable)
        end
      end
    end
    if cc.checkCritterBrain(true) then
      cc.temp.all.messages = math.max((cc.temp.all.messages -1), 0)
      cc.temp.brain.messages = math.max((cc.temp.brain.messages -1), 0)

      if cc.config.debug then print("Non critter message found, obfuscating words beyond speech level.") end
      local length = #message
      local newMessage = _Message:new()
      local pos = 1
      while pos <= length do
        local wordStart, wordEnd = cc.findNextWord(message, pos)
        if wordStart then
          if pos < wordStart then
            local misc = message:sub(pos, wordStart - 1)
            newMessage:append(misc, misc) -- copy whatever was between the previous word and this one
          end
          pos = wordEnd + 1
          local curWord = message:sub(wordStart, wordEnd)
          newMessage:append(curWord)
        else -- no more words found, copy the remaining characters to the new message
          local curWord = message:sub(pos, -1)
          newMessage:append(curWord, true)

          break -- exit the loop
        end
        if not pos then break end
      end
      if speakerBlock then
        messageTable.text = speakerBlock
        messageTable.extra = newMessage:critterParse()
      else
        messageTable.with[2] = newMessage:critterParse()
      end
      return toJson(messageTable)
    end
  elseif cc.config.debug then
    print("invalid message to parse: ", username, uuid, valid)
  end
end

local didPostInit = false
local dt = 1/20
function events.tick()
  if not host:isHost() then return end -- everything past this is for host only
  for k, v in pairs(cc.temp) do
    v.time = math.max(0, v.time-dt)
  end

  if not didPostInit then
    didPostInit = true
    cc.postInit()
  end
  local queued = critterMessageQueue[1]
  if queued then
    queued.attempts = queued.attempts + 1
    local variables = world:avatarVars()[queued.uuid] or {}
    local critterMessage = variables["msg:" .. queued.message]
    local critterMessageNum = variables["msgNum:" .. queued.message]

    local newMessageNumber = variables.messageNumber or 0
    local lastMessageNumber = userLastMessageNumber[queued.username] or 0
    if newMessageNumber < lastMessageNumber then
      userLastMessageNumber[queued.username] = 0
      lastMessageNumber = 0
    end
    if cc.config.debug then print("finding queued message: ", queued.message, "\n attempt: ",
        queued.attempts) end

    if critterMessage and (newMessageNumber > lastMessageNumber) then
      for i = 1, 10 do
        local curMessage = host:getChatMessage(i)
        if curMessage then
          local curMessageJson = parseJson(curMessage.json)
          if cc.config.debug then
            print("checking message history: ", i)
            printTable(curMessageJson, 3)
          end
          local curMessageText = cc.condenseText(((curMessageJson or {}).extra or {})[4])
          local curMessageUsername = (((curMessageJson or {}).extra or {})[2] or {}).insertion
          if (curMessageText == queued.message) and (curMessageUsername == queued.username) then
            userLastMessageNumber[queued.username] = critterMessageNum or (lastMessageNumber + 1)

            curMessageJson.extra[4] = _Message:new(critterMessage):critterParse(true,
              queued.canUnderstand)
            host:setChatMessage(i, toJson(curMessageJson))
            table.remove(critterMessageQueue, 1)
            if cc.config.debug then print("found message.") end
            break
          end
        else
          break
        end
      end
    elseif queued.attempts > 20 then
      if cc.config.debug then print("gave up on finding message after too many attempts.") end
      userLastMessageNumber[queued.username] = critterMessageNum or (lastMessageNumber + 1)
      table.remove(critterMessageQueue, 1)
    end
  end
  if cc.checkCritterSpeak(false) or cc.checkCritterBrain(false) then
    -- do nothing
  else
    if cc.checkWordsGained() then
      cc.hotBarNotification(cc.config.notifications.wordsGained)
    elseif cc.checkWordsLost() then
      cc.hotBarNotification(cc.config.notifications.wordsLost)
    end
  end
  cc.prevLevel = player:getExperienceLevel()
end

return cc
