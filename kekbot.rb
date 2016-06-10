require 'discordrb'
require 'json'
require 'yaml'
require 'digest/sha1'

bot = Discordrb::Commands::CommandBot.new token: ARGV[0], application_id: 185442396119629824, prefix: '.'

puts "This bot's invite URL is #{bot.invite_url}."

#global things
db = Hash.new
devChannel = 184597857414676480
version = "v1.0"

bot.ready do |event|

  file = File.read('kekdb.json')
  db = JSON.parse(file)

  message = ""

  message << "Loaded database from **" + db['timestamp'] + "** :file_folder: \n"

  cmd = "git log --pretty=\"%h\" -n 1"
  rev = `#{cmd}`
  event.bot.game = "#{version} [#{rev.strip}]"

  cmd = "git log -n 1"
  log = `#{cmd}`

  cmd = "git branch | grep \"*\""
  branch = `#{cmd}`

  message << "**Current Revision**\n```branch: #{branch}\n#{log}```\n"
  message << "**Bot ready!** :raised_hand:"

  bot.send_message(devChannel, message)

  bot.send_message(devChannel, "**Active servers** :computer:")
  bot.servers.each do |x|
    bot.send_message(devChannel, "```name: #{x[1].name}\nowner: #{x[1].owner.username}\nmembers: #{x[1].member_count}```")
    sleep 0.5
  end

end

#restart bot
bot.command(:restart, description: "restarts the bot") do |event|
  break unless event.channel.id == devChannel

  bot.send_message(devChannel,"Restart issued.. :wrench:")
  bot.stop
  exit

end

bot.message(with_text: "Ping!") do |event|

  event.respond 'Pong! :wink:'

end

bot.command(:game, description: "sets bot game") do |event, *game|
  break unless event.channel.id == devChannel

  event.bot.game = game.join(' ')
  nil

end

#DATABASE
#load db
bot.command(:loaddb, description: "reloads database") do |event|
  break unless event.channel.id == devChannel

  file = File.read('kekdb.json')
  db = JSON.parse(file)

  event << "Loaded database from **#{db['timestamp']}** :computer:\n"

end

#rev - get latest rev + patchnote
bot.command(:rev, description:"gets bot's HEAD revision") do |event|

  cmd = "git log -n 1"
  log = `#{cmd}`

  cmd = "git branch"
  branch = `#{cmd}`

  event <<"Current branch:\n`#{branch}`"
  event << "```#{log}```"
  event << "**https://github.com/z64/kekbot**"

end

bot.command(:log, min_args: 1, description:"gets n many rev logs") do |event, number|

  cmd = "git log --pretty=format:\"%h - %an, %ar : %s\" -n #{number}"
  log = `#{cmd}`

  cmd = "git branch"
  branch = `#{cmd}`

  event <<"Current branch: `#{branch}`"
  event << "```#{log}```"
  event << "**https://github.com/z64/kekbot**"

end

bot.command(:getdb, description: "uploads the current databse file") do |event|
  break unless event.channel.id == devChannel

  file = File.open('kekdb.json')
  event.channel.send_file(file)

end

#save db
bot.command(:save, description: "force database save") do |event|
  break unless event.channel.id == devChannel

  save(db)

  event << "**You have saved the keks..** :pray:"

end

bot.command(:register, description: "registers new user") do |event|

  #grab user id
  id = event.user.id.to_s

  #check if user is already registered
  if !db['users'][id].nil?
    event << "You are already registered, yung kek."
  end

  #construct user
  db['users'][id] = { "name" => event.user.name, "bank" => 10, "nickwallet" => false, "currencyReceived" => 0, "karma" => 0, "stipend" => 40, "collectibles" => [] }

  #welcome message
  event << "**Welcome to the KekNet, #{event.user.name}!**"
  event << "Use `.help` for a list of commands."
  event << "For more info: **https://github.com/z64/kekbot/blob/master/README.md**"

  save(db)
  nil
end

#KEKS
#get keks
bot.command(:keks, description: "fetches your balance, or @user's balance") do |event, mention|

  #report our own keks if no @mention
  #pick up user if we have a @mention
  if mention.nil?
    mention = event.user.id.to_i
  else
    mention = event.message.mentions.at(0).id.to_i
  end

  #load user from db, report if user is invalid or not registered.
  user = db["users"][mention.to_s]
  if user.nil?
    event << "User does not exist, or hasn't `.register`ed yet. :x:"
    return
  end

  #report keks
  event << "#{bot.user(mention).mention}'s Dank Bank balance: **#{user['bank'].to_s} #{db['currencyName']}**"
  event << "Stipend balance: **#{user['stipend'].to_s} #{db['currencyName']}**"

  nil
end

#set keks
bot.command(:setkeks, min_args: 2, description: "sets @user's kek and stipend balance") do |event, mention, bank, stipend|
  break unless event.channel.id == devChannel

  #get integers
  bank = bank.to_i
  stipend = stipend.to_i

  #update db with requested values
  user = event.bot.parse_mention(mention).id.to_s
  db['users'][user]['bank'] = bank
  db['users'][user]['stipend'] = stipend

  #update nickwallet
  #updateNick(db, event.message.mentions.at(0).on(event.server))

  #notification
  event << "Oh, senpai.. updated! :wink:"

  save(db)
  nil
end

#give keks
bot.command(:give, min_args: 2,  description: "give currency") do |event, to, value|

  #pick up user
  fromUser = db["users"][event.user.id.to_s]

  #return if invalid user
  if fromUser.nil?
    event << "User does not exist, or hasn't `.register`ed yet. :x:"
    return
  end

  #check if they have enough first
  if (fromUser["stipend"] - value.to_i) < 0
    event << "You do not have enough #{db["currencyName"]} to make this transaction. :disappointed_relieved:"
    return
  end

  #flattery won't get you very far with KekBot
  if bot.parse_mention(to).id == event.bot.profile.id
    event << "Wh-... wha.. #{event.user.on(event.server).display_name}-senpai...*!*"
    event << "http://i.imgur.com/nxMsRS5.png"
    return
  end

  #pick up user to receive currency
  toUser = db["users"][event.message.mentions.at(0).id.to_s]

  #check that they exist
  if toUser.nil?
    event << "User does not exist, or hasn't `.register`ed yet. :x:"
    return
  end

  #you can't give keks to yourself
  if fromUser == toUser
    event << "https://media.giphy.com/media/yidUzkciDTniZ7OHte/giphy.gif"
    return
  end

  #transfer keks
  fromUser["stipend"] -= value.to_i
  toUser["bank"] += value.to_i

  #update user stats
  toUser["currencyReceived"] += value.to_i
  toUser["karma"] += 1

  #update server stats
  db["netTraded"] += value.to_i

  #update nickwallet
  #updateNick(db, event.bot.parse_mention(to).on(event.server))

  #notification
  event << "**#{event.user.on(event.server).display_name}** awarded **#{event.message.mentions.at(0).on(event.server).display_name}** with **#{value.to_s} #{db["currencyName"]}** :joy: :ok_hand: :fire:"

  save(db)
  nil
end

bot.command(:setstipend, min_args: 1, description: "sets all users stipend values") do |event, value|
  break unless event.channel.id == devChannel

  #get integer
  value = value.to_i

  #update all users
  db["users"].each do |id, data|
    data["stipend"] = value
  end

  #notification
  event << "All stipends set to `#{value.to_s}`"

end

bot.command(:nickwallet, description: "Toggle: shows your wallet in your nickname.") do |event|

  # user = getUser(db, event.user.id)
  # user["nickwallet"] = !user["nickwallet"]
  #
  # if user["nickwallet"]
  #
  #   event.user.on(event.server).nick = "#{event.user.on(event.server).on(event.server).display_name} (#{user["bank"]} #{db["currencyName"]})"
  #   event << "Nickname applied."
  #
  # else
  #
  #   event.user.on(event.server).nick = ""
  #   event << "Nickname removed."
  #
  # end
  #
  # nil

end

#COLLECTIBLES
#inspect a collectible
bot.command(:show, min_args: 1, description: "displays a rare, or tells you who owns it", usage: ".show [description]") do |event, *description|

  #stitch args together
  description = description.join(' ')

  #get user
  user = db["users"][event.user.id.to_s]

  #look for our collectible, and do checks
  db['collectibles'].each do |id, data|
    if data['description'] == description

      #output the collectible if its ours
      if !user['collectibles'].grep(id).empty?
        event << "#{event.user.mention}\'s `#{description}`: "
        event << data['url']
        return
      end

      #don't show it if it exists, but is claimed by someone else
      if data['claimed']
        event << "`#{description}` is a claimed #{db["collectiblesName"]}! :eyes:"
        return
      end

      #its unclaimed at this point - tell the user how to claim it
      event << '`#{description}` is an unclaimed #{db["collectiblesName"]}! :eyes:'
      event << "Use `.claim #{data["description"]}` to claim this #{db["collectiblesName"]} for: **#{data["value"].to_s} #{db["currencyName"]}!**"
      event << data['url']
    end
  end

  #if we're here, it doesn't exist.
  event << "The #{db["collectiblesName"]} `#{description}` doesn't exist, or isn't in your inventory."

end

#list collectibles
bot.command(:rares, description: "list what rares you own") do |event|

  #get user
  user = db["users"][event.user.id.to_s]

  #init list with intro text
  list = "#{event.user.mention}\'s `#{user["collectibles"].length.to_s}` #{db["collectiblesName"]}s:\n\n"

  #buffer our output in case we go over 2k characters
  user["collectibles"].each do |x|

    #output string
    addtion = "`#{db["collectibles"][x]["description"]}`"

    #if our next addition will go over our 2000 char buffer, spit out the list and clear the buffer
    if (addtion.length + list.length) > 2000
      event.respond(list)
      list = ""
    end

    #add next addition
    list << "#{addtion}  "

  end

  #output list / end of list
  event.respond(list)

  #some extra help text
  event << "\nInspect a #{db["collectiblesName"]} in your inventory with `.show [description]`."

end

#list all collectibles
bot.command(:catalog, description: "lists all unclaimed rares") do |event|

  #intro text
  message = "**Unclaimed #{db["collectiblesName"]}s**\nClaim any #{db["collectiblesName"]} in the list below with `.claim [description]`.\n\n"

  #buffer our output in case we go over 2k characters
  db["collectibles"].each do |id, data|

    #if next addition goes over the 2k buffer, spit it out and clear the buffer
    if (message.length + data["description"].length) > 2000
      event.respond(message)
      message = ''
    end

    #add next collectible to message if its unclaimed
    if !data["claimed"] then message << "`#{data["description"]} (#{data["value"]})`  " end

  end

  #output list / end of list
  event.respond(message)

end

#add collectibles
bot.command(:submit, min_args: 2, description: "adds a rare to the db", usage: ".submit [url] [description]") do |event, url, *description|

  #stitch together description splat
  description = description.join(' ')

  #write new collectible
  db['collectibles'][Digest::SHA1.hexdigest(url)] = { "description" => description, "timestamp"=> Time.now, "author" => event.user.name, "url" => url, "visible" => false, "claimed" => false, "unlock" => 0, "value" => 0 }

  #output success
  event << "**Thank you #{event.user.mention}!**"
  event << "Submitted rare: `#{description}`"

  save(db)
  nil
end

#claim collectible
bot.command(:claim, min_args: 1, description: "claims an unclaimed rare", usage: ".claim [description]") do |event, *description|

  #stitch together description splat
  description = description.join(' ')

  #grab user
  user = db['users'][event.user.id.to_s]

  #select collectible
  db['collectibles'].each do |id, data|
    if data['description'] == description

      #check if its already claimed
      if data['claimed']
        event << "`#{description}` is already claimed.. :eyes:"
        return
      end

      #make sure we can afford it
      if user['bank'] < data['value']
        event << "Not enough **#{db["currencyName"]}** in your **Dank Bank**.. :eyes:"
        return
      end

      #its unclaimed and we can afford it
      #perform transaction
      user['collectibles'] << id
      user['bank'] -= data['value']
      data['claimed'] = true
      #updateNick(db, event.user.on(event.server))
      save(db)

      #output success
      event << "`#{description}` has been added to your `.inventory`! :money_with_wings:"
      return
    end
  end

  #at this point, collectible must not exist
  event << "This rare does not exist.. :eyes:"

  nil
end

bot.command(:sell, min_args: 3, description: "create a sale", usage: ".sell [description] @user [offer]") do |event, *sale|

  amount = sale.pop.to_i
  sale.pop #pop off mention
  description = sale.join(' ')
  buyer = event.message.mentions.at(0)

  #setup
  buyer_db = getUser(db, buyer.id)
  seller_db = getUser(db, event.user.id)

  collectibleIndex = getCollectibleIndex(db, description)
  collectible = db["collectibles"][collectibleIndex]

  #checks
  if collectibleIndex.nil?
    event << "This #{db["collectiblesName"]} does not exist.. :eyes:"
    return
  end

  if amount > buyer_db["bank"]
    event << "#{bot.user(buyer_db["id"]).on(event.server).display_name} can not afford that sale.. :eyes:"
    return
  end

  hasCollectible = !seller_db["collectibles"].grep(collectibleIndex).empty?

  if !hasCollectible
    event << "You don't have this #{db["collectiblesName"]}.. :eyes:"
    return
  end

  #process sale
  event << "#{bot.user(seller_db["id"]).on(event.server).display_name} wants to sell `#{collectible["description"]}` to #{bot.user(buyer_db["id"]).on(event.server).display_name} for #{amount} #{db["currencyName"]}! :incoming_envelope:"
  event << "#{buyer.mention}, type `accept` or `reject`"

  buyer.await(:sale) do |subevent|

    if subevent.message.content == "accept"

      #users balance could have changed since sale created - double check we can afford it
      if amount > buyer_db["bank"]

        subevent.respond("#{bot.user(buyer_db["id"]).on(event.server).display_name} can no longer afford that sale.. :eyes:")

      else

        subevent.respond("#{bot.user(buyer_db['id']).on(event.server).display_name} accepted your offer, #{event.user.mention}!")

        seller_db["collectibles"].delete(collectibleIndex)
        buyer_db["collectibles"] << collectibleIndex

        buyer_db["bank"] -= amount
        seller_db["bank"] += amount
        db["netTraded"] += amount

        updateNick(db, buyer.on(event.server))
        updateNick(db, event.user.on(event.server))
        save(db)

      end

      true

    elsif subevent.message.content == "reject"

      subevent.respond("#{bot.user(buyer_db["id"]).on(event.server).display_name} has rejected your offer, #{event.user.mention} :x:")

      true

    else

      false

    end

  end
  nil
end

bot.command(:trade, description: "trade collectibles with other users", usage: ".trade @user [yourCollectible] / [theirCollectible]") do |event, *trade|

  trade.shift #drop mention
  user_a = getUser(db, event.user.id)
  user_b = getUser(db, event.message.mentions.at(0).id)
  trade = trade.join(' ').split("\s/\s").slice(0..1)

  #check that collectibles exist
  collectible_a = getCollectibleIndex(db, trade[0])
  if collectible_a.nil?
    event << "#{db["collectiblesName"]} `#{trade[0]}` not found."
    return
  end

  collectible_b = getCollectibleIndex(db, trade[1])
  if collectible_b.nil?
    event << "#{db["collectiblesName"]} `#{trade[1]}` not found."
    return
  end

  #check that each user owns the specified collectibles
  if user_a["collectibles"].grep(collectible_a).empty?
    event << "You don't own that #{db["collectiblesName"]}..!"
    return
  end

  if user_b["collectibles"].grep(collectible_b).empty?
    event << "#{user_b} doesn't own that #{db["collectiblesName"]}"
    return
  end

  event << "#{bot.user(user_a["id"]).on(event.server).display_name} wants to trade his `#{db["collectibles"][collectible_a]["description"]}` for your `#{db["collectibles"][collectible_b]["description"]}` #{event.message.mentions.at(0).mention}!"
  event << "Respond with `accept` or `reject` to complete the trade."

  event.message.mentions.at(0).await(:trade) do |subevent|

    if subevent.message.content == "accept"

      #perform the trade
      user_a["collectibles"].delete(collectible_a)
      user_a["collectibles"] << collectible_b

      user_b["collectibles"].delete(collectible_b)
      user_b["collectibles"] << collectible_a

      subevent.respond("Trade complete! :blush: :heart:")

      save(db)
      true

    elsif subevent.message.content == "reject"

      subevent.respond("#{bot.user(user_b["id"]).on(event.server).display_name} has rejected your offer, #{event.user.mention} :x:")

      true

    else

      false

    end
  end
  nil
end

bot.command(:eval, help_available: false) do |event, *code|
  break unless event.user.id == 120571255635181568

  begin
    eval code.join(' ')
  rescue
    "An error occured 😞"
  end
end

#FUNCTIONS
def save(db)

  db['timestamp'] = Time.now.to_s

  file = File.open("kekdb.json", "w")
  file.write(JSON.pretty_generate(db))

  #file = File.open("kekdb.yaml", "w")
  #file.write(db.to_yaml)

end

def getUser(db, id)
  usersdb = db['users']
  usersdb.each_with_index do |x,index|
    if x['id'] == id
      #return [index, x]
      return x
    end
  end
  return nil
end

def getCollectibleIndex(db, description)
  db["collectibles"].each_with_index do |x, index|
    if x["description"] == description
      return index
    end
  end
  return nil
end

def updateNick(db, user)
  user_db = getUser(db, user.id)
  if user_db["nickwallet"]
    user.nick = "#{user_db["name"]} (#{user_db["bank"]} #{db["currencyName"]})"
  end
end

bot.run
