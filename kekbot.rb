require 'discordrb'
require 'json'
require 'yaml'

bot = Discordrb::Commands::CommandBot.new token: ARGV[0], application_id: 185442396119629824, prefix: '.'

puts "This bot's invite URL is #{bot.invite_url}."

#global things
db = Hash.new
devChannel = 184597857414676480
version = "ALPHA"

bot.ready do |event|

	file = File.read('kekdb.json')
	db = JSON.parse(file)

	message = ""

	message << "Loaded database from **" + db['timestamp'] + "** :file_folder: \n"

	cmd = "git log --pretty=\"%h\" -n 1"
	rev = `#{cmd}`
	event.bot.game = "#{version} #{rev.strip}"

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

	usersdb = db['users']
	usersdb.each do |x|

		if x['id'] == event.user.id.to_i
			event << "You are already registered, young kek."
			return
		end

	end

	db['users'][db['users'].length] = { "id" => event.user.id, "name" => event.user.name, "bank" => 10, "nickwallet" => false, "currencyReceived" => 0, "karma" => 0, "stipend" => 40, "collectibles" => [0] }

	event << "**Welcome to the KekNet, #{event.user.name}!**"
	event << "Use `.help` for a list of commands."
	event << "For more info: **https://github.com/z64/kekbot/blob/master/README.md**"

	save(db)
	nil
end

#KEKS
#get keks
bot.command(:keks, description: "fetches your balance, or @user's balance") do |event, mention|

	if mention.nil?
		mention = event.user.id.to_i
	else
		mention = event.message.mentions.at(0).id.to_i
	end

	usersdb = db['users']
	usersdb.each do |x|		

		if x['id'].to_i == mention
			event << "#{x['name']}'s Dank Bank balance: **#{x['bank'].to_s} #{db['currencyName']}**"
			event << "Stipend balance: **#{x['stipend'].to_s} #{db['currencyName']}**"
		end

	end

	nil

end

#set keks
bot.command(:setkeks, min_args: 2, description: "sets @user's kek and stipend balance") do |event, mention, bank, stipend|
	break unless event.channel.id == devChannel

	usersdb = db['users']
	usersdb.each do |x|		

		if x['id'].to_i == event.message.mentions.at(0).id.to_i
			x['bank'] = bank.to_i
			x['stipend'] = stipend.to_i
			event << "Oh, senpai.. updated! :wink:"
		end		
	end

	updateNick(db, event.message.mentions.at(0).on(event.server))
	save(db)
	nil
end

#give keks
bot.command(:give, min_args: 2,  description: "give currency") do |event, to, value|
		
	fromUser = getUser(db, event.user.id.to_i)

	if (fromUser["stipend"] - value.to_i) < 0
		event << "You do not have enough #{db["currencyName"]} to make this transaction. :disappointed_relieved:"
		return
	end

	if bot.parse_mention(to).id == 185442417208590338
		event << "Wh-... wha.. #{fromUser["name"]}-senpai...*!*"
		event << "http://i.imgur.com/nxMsRS5.png"
		return
	end

	toUser = getUser(db, event.message.mentions.at(0).id.to_i)
	if toUser.nil?
		event << "User does not exist, or hasn't `!register`ed yet."
		return
	end

	if fromUser["id"] == toUser["id"]
		event << "https://media.giphy.com/media/yidUzkciDTniZ7OHte/giphy.gif"
		return
	end	

	fromUser["stipend"] -= value.to_i
	toUser["bank"] += value.to_i
	toUser["currencyReceived"] += value.to_i
	toUser["karma"] += 1
	db["netTraded"] += value.to_i

	event << "**#{fromUser["name"]}** awarded **#{toUser["name"]}** with **#{value.to_s} #{db["currencyName"]}** :joy: :ok_hand: :fire:"

	save(db)
	updateNick(db, event.bot.parse_mention(to).on(event.server))
	nil
end

bot.command(:setstipend, min_args: 1, description: "sets all users stipend values") do |event, value|
	break unless event.channel.id == devChannel

	value = value.to_i

	db["users"].each do |x|
		x["stipend"] = value
	end

	event << "All stipends set to `#{value.to_s}`"

end

bot.command(:nickwallet, description: "Toggle: shows your wallet in your nickname.") do |event|

	user = getUser(db, event.user.id)
	user["nickwallet"] = !user["nickwallet"]

	if user["nickwallet"]

		event.user.on(event.server).nick = "#{event.user.on(event.server).display_name} (#{user["bank"]} #{db["currencyName"]})"
		event << "Nickname applied."

	else

		event.user.on(event.server).nick = ""
		event << "Nickname removed."

	end

	nil

end

#COLLECTIBLES
#inspect a collectible
bot.command(:rare, min_args: 1, description: "displays a rare, or tells you who owns it") do |event, *description| 

	description = description.join(' ')

	user = getUser(db, event.user.id.to_i)
	user["collectibles"].each do |x|
		if db["collectibles"][x]["description"] == description
			event << "#{user["name"]}\'s `#{description}`: "
			event << db["collectibles"][x]["url"]
			return
		end
	end

	db["collectibles"].each do |x|
		if x["description"] == description
			if x["claimed"]
				event << "`#{description}` is a claimed #{db["collectiblesName"]}! :eyes:"
			else
				event << "`#{description}` is an unclaimed #{db["collectiblesName"]}! :eyes:"
				event << "Use `.claim #{x["description"]}` to claim this #{db["collectiblesName"]} for: **#{x["value"].to_s} #{db["currencyName"]}!**"
				event << x["url"]
			end
			return
		end
	end

	event << "The #{db["collectiblesName"]} `#{description}` doesn't exist, or isn't in your inventory."

	nil
end

#list collectibles
bot.command(:inventory, description: "list what rares you own") do |event|

	user = getUser(db, event.user.id.to_i)

	event << "#{user["name"]}\'s `#{user["collectibles"].length.to_s}` #{db["collectiblesName"]}s:\n"

	user["collectibles"].each do |x|
		event << "`#{db["collectibles"][x]["description"]}`"
	end	

	event << "\nInspect a #{db["collectiblesName"]} in your inventory with `.rare [description]`."
	nil
end

#list all collectibles
bot.command(:catalog, description: "lists all unclaimed rares") do |event|

	message = ""

	db["collectibles"].each do |x|
		if (message.length + x["description"].length) > 2000
			event.respond(message)
			message = ""
		end

		if !x["claimed"] then message << "`#{x["description"]} (#{x["value"]})` " end

	end

	event.respond(message)

	nil
end

#add collectibles
bot.command(:addrare, min_args: 3, description: "adds a rare to the db") do |event, url, value, *description| 
	#temporary - only allow :addrare on our private channel.
	if event.channel.id != 185021357891780608 then break end

	description = description.join(' ')

	db["collectibles"][db["collectibles"].length] = { "description" => description, "url" => url, "claimed" => false, "unlock" => 0, "value" => value.to_i }

	event << "Added rare: `#{description}`"

	save(db)
	nil

end

#claim collectible
bot.command(:claim, min_args: 1, description: "claims an unclaimed rare") do |event, *description|

	description = description.join(' ')
	collectibleIndex = getCollectibleIndex(db, description)
	collectible = db["collectibles"][collectibleIndex]
	user = getUser(db, event.user.id)

	if collectibleIndex.nil?
		event << "This rare does not exist.. :eyes:"
		return
	end

	if collectible["claimed"]
			event << "`#{description}` is already claimed.. :eyes:"
			return
	else

		if user["bank"] < collectible["value"]
			event << "Not enough **#{db["currencyName"]}** in your **Dank Bank**.. :eyes:"
			return
		end

		user["bank"] -= collectible["value"]
		collectible["claimed"] = true
		user["collectibles"][user["collectibles"].length] = collectibleIndex#
		event << "`#{description}` has been added to your `.inventory`! :money_with_wings:"

	end

	updateNick(db, event.user.on(event.server))
	save(db)
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
		event << "#{buyer_db["name"]} can not afford that sale.. :eyes:"
		return
	end

	hasCollectible = !seller_db["collectibles"].grep(collectibleIndex).empty?

	if !hasCollectible
		event << "You don't have this #{db["collectiblesName"]}.. :eyes:"
		return
	end

	#process sale
	event << "#{seller_db["name"]} wants to sell `#{collectible["description"]}` to #{buyer_db["name"]} for #{amount} #{db["currencyName"]}! :incoming_envelope:"
	event << "#{buyer.mention}, type `accept` or `reject`"

	buyer.await(:sale) do |subevent|

		if subevent.message.content == "accept"

			#users balance could have changed since sale created - double check we can afford it
			if amount > buyer_db["bank"]

				subevent.respond("#{buyer_db["name"]} can no longer afford that sale.. :eyes:")

			else

				subevent.respond("#{buyer_db['name']} accepted your offer, #{event.user.mention}!")

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

			subevent.respond("#{buyer_db["name"]} has rejected your offer, #{event.user.mention} :x:")

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

	event << "#{user_a["name"]} wants to trade his `#{db["collectibles"][collectible_a]["description"]}` for your `#{db["collectibles"][collectible_b]["description"]}` #{event.message.mentions.at(0).mention}!"
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

			subevent.respond("#{user_b["name"]} has rejected your offer, #{event.user.mention} :x:")

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