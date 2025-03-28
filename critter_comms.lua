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
           \/_____/   \/_____/   \/_/  \/_/   \/_/  \/_/   \/_____/ v1.0

                        fox to fox communication

                        fox to fox conversation

                    Made by Wasabi_Raptor and Zygahedron
                https://github.com/WasabiRaptor/critter-comms
]]

-- print("reloaded")

local critter_comms_config = require("critter_comms_config")

avatar:store("isCritter", true)
local messageNumber = 0
avatar:store("messageNumber", messageNumber)
if critter_comms_config.persist and ((config:load("critterSpeak") or config:load("critterBrain")) ~= nil) then
  critter_comms_config.speak = config:load("critterSpeak")
  critter_comms_config.brain = config:load("critterBrain")
end

---@param str string
---@return integer
local function hashString(str)
  local hash = 5381
  for i = 1, #str do
    hash = math.fmod(hash * 33 + str:byte(i), 2147483648)
  end
  return hash
end
local function condenseText(textTable)
  if type(textTable) == "table" and textTable[1] then
    local out = ""
    for _, v in ipairs(textTable) do
      out = out .. (condenseText(v) or "")
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
local function addNoise(curWord, newWord, noiseTable)
  local start, middle, ending = table.unpack(noiseTable[math.random(#noiseTable)])
  local noise = start .. middle .. ending
  local noisecount = 1
  while (noise:sub(1, 1) == newWord:sub(-1, -1)) and (noisecount < #noiseTable) do
    start, middle, ending = table.unpack(noiseTable[math.random(#noiseTable)])
    noise = start .. middle .. ending
    noisecount = noisecount + 1
  end

  local from, to = curWord:find("^" .. curWord:sub((#newWord + #noise + 1), #newWord + #noise + 1) .. "+",
    #newWord + #noise + 2)                                                                                                      -- check if the same character has been repeated
  if not to then
    if ((#newWord + #noise + critter_comms_config.stretchLastNoise) >= #curWord) then
      to = #curWord
    elseif ((#newWord + #noise + critter_comms_config.randomStretchRange[2]) <= #curWord) then
      to = #newWord + #noise + math.random(table.unpack(critter_comms_config.randomStretchRange))
    end
  end
  local substituting = curWord:sub(#newWord, to)

  local _, uppercaseCount = substituting:gsub("%u", "")
  local _, letterCount = substituting:gsub("%a", "")
  if uppercaseCount > (letterCount * critter_comms_config.allcapsPercentage) then
    start, middle, ending = start:upper(), middle:upper(), ending:upper()
  end
  newWord = newWord .. start
  newWord = newWord .. middle
  while #newWord < (to - #ending) do
    newWord = newWord .. middle
  end
  newWord = newWord .. ending

  return newWord
end

local function hotBarNotification(notif)
  host:setActionbar(toJson({
    { text = notif[math.random(#notif)], color = critter_comms_config.notificationColor },
  }), true)
end

local function correctCapitalization(curWord, newWord)
  if curWord:sub(1, 1):find("^%u") then
    newWord = newWord:sub(1, 1):upper() .. newWord:sub(2, -1)
  end
  return newWord
end

local function findNextWord(msg, pos)
  local wordStart, wordEnd
  local _, whitespace = msg:find("^%s+", pos)
  if whitespace then
    pos = whitespace + 1
  end
  for _, v in ipairs(critter_comms_config.findContainers) do
    local foundContainer_1, foundContainer_2 = msg:find(v, pos)
    if foundContainer_1 and foundContainer_2 then
      return findNextWord(msg, foundContainer_2 + 1)
    end
  end
  local lower = msg:lower()
  for _, v in ipairs(critter_comms_config.findWords) do
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

function _Message:critterParse(isCritter)
  if not player:isLoaded() then return end
  local level = player:getExperienceLevel()
  local out = {}
  if isCritter then
    local wordsUnderstood = 0

    for i, v in ipairs(self.message) do
      local word, newWord = table.unpack(v)
      math.randomseed(hashString(word:lower()))                                                                                                           -- set the seed to the hash of the word so any randomness with that word is consistent
      if newWord                                                                                                                                          -- critter word or something else critters can understand so use original word
          or ((math.random(critter_comms_config.minimumSpeechLevel, critter_comms_config.normalSpeechLevel) <= level) and not critter_comms_config.brain) -- if not a critter word, check if we can understand it
          or critter_comms_config.obfuscateMethod == "none"
          or critter_comms_config.understandWhitelist[word:lower()]
          or critter_comms_config.speakWhitelist[word:lower()]
      then
        table.insert(out, {
          text = ((type(newWord) == "string") and newWord or word),
          obfuscated = false,
          font = "default",
        })
        if type(newWord) ~= "boolean" then
          wordsUnderstood = wordsUnderstood + 1
        end
      else -- not a word we can understand, obfuscate in some way
        local obfuscate = critter_comms_config.obfuscateMethod
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
    if not (wordsUnderstood > 0) then return out end
    table.insert(out, {
      text = "\n -> ",
      color = "gray",
      font = "default",
      obfuscated = false,
    })
  end

  for i, v in ipairs(self.message) do
    local word, newWord = table.unpack(v)
    math.randomseed(hashString(word:lower()))                                                                                                           -- set the seed to the hash of the word so any randomness with that word is consistent
    if newWord                                                                                                                                          -- critter word or something else critters can understand so use original word
        or ((math.random(critter_comms_config.minimumSpeechLevel, critter_comms_config.normalSpeechLevel) <= level) and not critter_comms_config.brain) -- if not a critter word, check if we can understand it
        or critter_comms_config.obfuscateMethod == "none"
        or critter_comms_config.understandWhitelist[word:lower()]
        or critter_comms_config.speakWhitelist[word:lower()]
    then
      table.insert(out, {
        text = word,
        obfuscated = false,
        font = "default",
        color = isCritter and "gray",
      })
    else -- not a word we can understand, obfuscate in some way
      local obfuscate = critter_comms_config.obfuscateMethod
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

local backlog = {
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
  messageNumber = messageNumber + 1
  local str = message:getString()
  avatar:store("msg:" .. str, message.message)
  avatar:store("messageNumber", messageNumber)
  table.insert(backlog, str)
  local old = table.remove(backlog, 1)
  if old ~= str then
    avatar:store("msg:" .. old)
  end
end

local prevLevel = 0
function events.entity_init()
  prevLevel = player:getExperienceLevel()
end

local function parseNameplate(input)
  if input then
    return condenseText(parseJson(input))
  end
end
local function postInit()
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
  local level = player:getExperienceLevel()
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
      if message:sub(tell + 1, ws1 - 1) == player:getName() and critter_comms_config.selfWhispers then
        newMessage:append(message:sub(pos, -1), true)
        newMessage:ping()
        return message
      end
    else
      return message
    end
  end

  local intentional, f2 = message:find(critter_comms_config.critterSpeakCommand, pos)
  if intentional and f2 then
    pos = f2 + 1
  end

  while pos <= length do
    local wordStart, wordEnd = findNextWord(message, pos)
    if wordStart then
      if pos < wordStart then
        local misc = message:sub(pos, wordStart - 1)
        newMessage:append(misc, true) -- copy whatever was between the previous word and this one
      end
      pos = wordEnd + 1
      local curWord = message:sub(wordStart, wordEnd)
      local curWordLower = curWord:lower()
      math.randomseed(hashString(curWordLower)) -- set the seed to the hash of the word so any randomness with that word is consistent

      if critter_comms_config.shortcutWords[curWord] then
        newMessage:append(critter_comms_config.shortcutWords[curWord], true)
      elseif critter_comms_config.speakWhitelist[curWordLower] then
        newMessage:append(curWord, true)
      elseif not (curWordLower:find(critter_comms_config.speechBlacklist) or critter_comms_config.caseSensitiveSpecialWords[curWord] or critter_comms_config.specialWords[curWordLower]) then -- doesn't have any blacklisted characters and isn't a special word, copy as is and don't do any rolls
        newMessage:append(curWord, true)
      elseif (math.random(critter_comms_config.minimumSpeechLevel, critter_comms_config.normalSpeechLevel) <= level) and not (critter_comms_config.speak or intentional) then
        newMessage:append(curWord)
      else
        wordsReplaced = wordsReplaced + 1
        if critter_comms_config.caseSensitiveSpecialWords[curWord] then
          local newWord = critter_comms_config.caseSensitiveSpecialWords[curWord]
          newMessage:append(curWord, newWord)
        elseif critter_comms_config.specialWords[curWordLower] then
          local newWord = critter_comms_config.specialWords[curWordLower]
          local _, uppercaseCount = curWord:gsub("%u", "")
          if uppercaseCount > (#curWord * critter_comms_config.allcapsPercentage) then
            newWord = newWord:upper()
          end
          newMessage:append(curWord, correctCapitalization(curWord, newWord))
        else -- word contained blacklisted characters, did not succeed random rolls to be allowed, and was not a special case word, so we replace it with noises
          local newWord = addNoise(curWord, "", critter_comms_config.startNoises)
          if (#newWord < #curWord) then
            while #newWord < #curWord do
              newWord = addNoise(curWord, newWord, critter_comms_config.extendNoises)
            end
          end
          newMessage:append(curWord,
            correctCapitalization(curWord, newWord))
        end
      end
    else -- no more words found, copy the remaining characters to the new message
      local curWord = message:sub(pos, -1)
      newMessage:append(curWord, true)
      break -- exit the loop
    end
    if not pos then break end
  end
  host:appendChatHistory(message)
  newMessage:ping()
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
local function processCommand(message, phrase, hide, target, enable, allow)
  local level = player:getExperienceLevel()
  if message:find(phrase) then
    if allow then
      if enable then
        if (not (critter_comms_config.speak and critter_comms_config.brain)) and (level > critter_comms_config.minimumSpeechLevel) and not critter_comms_config[target] then
          hotBarNotification(critter_comms_config.notifications.speechLost)
        end
      else
        if (critter_comms_config.speak or critter_comms_config.brain) and (level > critter_comms_config.minimumSpeechLevel) and critter_comms_config[target] then
          local notif = critter_comms_config.notifications.wordsGained
          critter_comms_config[target] = enable -- doing it early here for easier calcs
          if (not (critter_comms_config.speak or critter_comms_config.brain)) and (level > critter_comms_config.normalSpeechLevel) then
            notif = critter_comms_config.speechGained
          end
          hotBarNotification(notif)
        end
      end

      critter_comms_config[target] = enable
    end

    config:save("critterSpeak", critter_comms_config.speak)
    config:save("critterBrain", critter_comms_config.brain)
    return hide
  end
end
function events.chat_receive_message(raw, text)
  if not player:isLoaded() then return end
  if raw:find("^%[lua%]") then return end
  local messageTable = parseJson(text)
  -- printTable(messageTable, 3)

  local username = ((messageTable.with or {})[1] or {}).insertion
  local uuid = ((((messageTable.with or {})[1] or {}).hoverEvent or {}).contents or {}).id
  local message = condenseText((messageTable.with or {})[2])
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
    if critter_comms_config.userListMode then -- whitelist, do nothing if not in list
      if not critter_comms_config.userList[username] then allowCommand = false end
    else                                      -- blacklist, do nothing if in the list
      if critter_comms_config.userList[username] then allowCommand = false end
    end

    if not outgoing then
      for phrase, hide in pairs(critter_comms_config.enableSpeak or {}) do
        if processCommand(message, phrase, hide, "speak", true, allowCommand) then return false end
      end
      for phrase, hide in pairs(critter_comms_config.disableSpeak or {}) do
        if processCommand(message, phrase, hide, "speak", false, allowCommand) then return false end
      end
      for phrase, hide in pairs(critter_comms_config.enableBrain or {}) do
        if processCommand(message, phrase, hide, "brain", true, allowCommand) then return false end
      end
      for phrase, hide in pairs(critter_comms_config.disableBrain or {}) do
        if processCommand(message, phrase, hide, "brain", false, allowCommand) then return false end
      end
      for phrase, hide in pairs(critter_comms_config.enableAll or {}) do
        processCommand(message, phrase, hide, "speak", true, allowCommand)
        if processCommand(message, phrase, hide, "brain", true, allowCommand) then return false end
      end
      for phrase, hide in pairs(critter_comms_config.disableAll or {}) do
        processCommand(message, phrase, hide, "speak", false, allowCommand)
        if processCommand(message, phrase, hide, "brain", false, allowCommand) then return false end
      end
    end
    local level = player:getExperienceLevel()
    if (critter_comms_config.brain or (level < critter_comms_config.normalSpeechLevel)) and not (incoming and (player:getName() == username)) then
      if uuid then
        local variables = world:avatarVars()[uuid] or {}
        local isCritter = variables["isCritter"]
        -- print(isCritter, username, uuid)
        -- printTable(world:avatarVars(), 3)
        if isCritter then
          local critterMessage = variables["msg:" .. message]
          local newMessageNumber = variables["messageNumber"] or 0
          local lastMessageNumber = userLastMessageNumber[username] or 0
          if newMessageNumber < lastMessageNumber then
            userLastMessageNumber[username] = 0
            lastMessageNumber = 0
          end

          if critterMessage and (newMessageNumber > lastMessageNumber) then
            userLastMessageNumber[username] = lastMessageNumber + 1
            messageTable.with[2] = _Message:new(critterMessage):critterParse(true)
            return toJson(messageTable)
          else
            messageTable.with[2] = { text = message, obfuscated = true, font = "alt" } -- temporarily obfuscate until we can parse it with the critter message data
            table.insert(critterMessageQueue, { username, uuid, message, 0 })
            return toJson(messageTable)
          end
        end
      end
      local length = #message
      local newMessage = _Message:new()
      local pos = 1
      while pos <= length do
        local wordStart, wordEnd = findNextWord(message, pos)
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
  end
end

local didPostInit = false
function events.tick()
  if not host:isHost() then return end -- everything past this is for host only

  if not didPostInit then
    didPostInit = true
    postInit()
  end
  if critterMessageQueue[1] then
    local username, uuid, message, attempts = table.unpack(critterMessageQueue[1])
    local variables = world:avatarVars()[uuid] or {}
    local critterMessage = variables["msg:" .. message]
    local newMessageNumber = variables["messageNumber"] or 0
    local lastMessageNumber = userLastMessageNumber[username] or 0
    if newMessageNumber < lastMessageNumber then
      userLastMessageNumber[username] = 0
      lastMessageNumber = 0
    end

    critterMessageQueue[1][4] = attempts + 1

    if critterMessage and (newMessageNumber > lastMessageNumber) then
      for i = 1, 10 do
        local curMessage = host:getChatMessage(i)
        if curMessage then
          local curMessageJson = parseJson(curMessage.json)
          local curMessageText = condenseText(curMessageJson.extra[4])
          local curMessageUsername = curMessageJson.extra[2].insertion
          -- printTable(curMessage, 4)
          -- printTable(parseJson(host:getChatMessage(i).json), 3)
          if (curMessageText == message) and (curMessageUsername == username) then
            userLastMessageNumber[username] = lastMessageNumber + 1

            curMessageJson.extra[4] = _Message:new(critterMessage):critterParse(true)
            host:setChatMessage(i, toJson(curMessageJson))
            table.remove(critterMessageQueue, 1)
            break
          end
        end
      end
    elseif attempts > 20 then
      userLastMessageNumber[username] = lastMessageNumber + 1
      table.remove(critterMessageQueue, 1)
    end
  end
  local level = player:getExperienceLevel()
  if critter_comms_config.speak and critter_comms_config.brain then
  elseif level > prevLevel then
    if (prevLevel < critter_comms_config.normalSpeechLevel) and (level >= critter_comms_config.normalSpeechLevel) then
      hotBarNotification(critter_comms_config.notifications.speechGained)
    elseif level >= critter_comms_config.normalSpeechLevel then
    elseif level >= critter_comms_config.minimumSpeechLevel then
      hotBarNotification(critter_comms_config.notifications.wordsGained)
    end
  elseif level < prevLevel then
    if (prevLevel >= critter_comms_config.minimumSpeechLevel) and (level < critter_comms_config.minimumSpeechLevel) then
      hotBarNotification(critter_comms_config.notifications.speechLost)
    elseif level >= critter_comms_config.normalSpeechLevel then
    elseif level >= critter_comms_config.minimumSpeechLevel then
      hotBarNotification(critter_comms_config.notifications.wordsLost)
    end
  end
  prevLevel = level
end
