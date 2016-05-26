require 'rubygems'
require 'discordrb'
require 'json'

bot = Discordrb::Commands::CommandBot.new token: ARGV[0], application_id: 184500834053259265, prefix: '.'

puts "This bot's invite URL is #{bot.invite_url}."

db = Hash.new

bot.message(with_text: "Ping!") do |event|

	event.respond 'Pong! :wink:'

end

bot.command(:game, min_args: 1) do |event, *game|

	event.bot.game = game.join(' ')
	nil

end

#DATABASE
#load db
bot.command(:loaddb) do |event|

	file = File.read('kekdb.json')
	db = JSON.parse(file)

	event << "Loaded database from **" + db['timestamp'] + "** :computer:\n"

end

#restart bot
bot.command(:restart) do |event|

	bot.user(120571255635181568).pm("Restart issued.. :wrench:")
	exit

end

#rev - get latest rev + patchnote
bot.command(:rev) do |event|

	cmd = "git log -n 1"
	value = `#{cmd}`
	event << "```#{value}```"

end

bot.command(:getdb) do |event|

	file = File.open('kekdb.json')
	event.channel.send_file(file)

end

#save db
bot.command(:save) do |event|

	db['timestamp'] = Time.now.to_s

	file = File.open("kekdb.json", "w")
	file.write(JSON.generate(db))

	event << "**You have saved the keks..** :pray:"

end

bot.command(:register) do |event|

	flag = false

	usersdb = db['users']
	usersdb.each do |x|

		if x['id'] == event.user.id.to_i
			event << "You are already registered, young kek."
			return
		end

	end

	db['users'][db['users'].length] = { "id" => event.user.id, "name" => event.user.name, "bank" => 10, "stipend" => 40, "collectables" => [0] }
	event << "**Welcome to the KekNet, " + event.user.name + "!**"

	save(db)
	nil
end

#KEKS
#get keks
bot.command(:keks) do |event, mention|

	if mention.nil?
		mention = event.user.id.to_i
	else
		mention = event.message.mentions.at(0).id.to_i
	end

	usersdb = db['users']
	usersdb.each do |x|		

		if x['id'].to_i == mention
			event << x['name'] + "\'s Dank Bank balance: **" + x['bank'].to_s + " " + db['currencyName'] + "**"
			event << "Stipend balance: **" + x['stipend'].to_s + " " + db['currencyName'] + "**"
		end

	end

	nil

end

#set keks
bot.command(:setkeks) do |event, mention, bank, stipend|

	usersdb = db['users']
	usersdb.each do |x|		

		if x['id'].to_i == event.message.mentions.at(0).id.to_i
			x['bank'] = bank.to_i
			x['stipend'] = stipend.to_i
			event << "Oh, senpai.. updated! :wink:"
		end		
	end

	save(db)
	nil
end

#give keks
bot.command(:give, min_args: 2) do |event, to, value|
		
	fromUser = getUser(db, event.user.id.to_i)
	
	if (fromUser["stipend"] - value.to_i) < 0
		event << "You do not have enough " + db["currencyName"] + " to make this transaction. :disappointed_relieved:"
		return
	end

	if bot.parse_mention(to).id.to_i == 184500867213426688
		event << "Wh-... wha.. " + fromUser["name"] + "-senpai...*!*"
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

	event << "**" + fromUser["name"] + "** awarded **" + toUser["name"] + "** with **" + value.to_s + " " + db["currencyName"] + "** :joy: :ok_hand: :fire:"

	save(db)
	nil
end

#COLLECTABLES
#inspect a collectable
bot.command(:rare, min_args: 1) do |event, *description| 

	description = description.join(' ')
	user = getUser(db, event.user.id.to_i)
	user["collectables"].each do |x|
		if db["collectables"][x]["description"] == description
			event << user["name"] + "'s `" + description + "`: "
			event << db["collectables"][x]["url"]
			return
		end
	end

	db["collectables"].each do |x|
		if x["description"] == description
			if x["claimed"]
				event << "`" + description + "` is a claimed " + db["collectablesName"] + "! :eyes:"
			else
				event << "`" + description + "` is an unclaimed " + db["collectablesName"] + "! :eyes:"
				event << "Use `.claim " + x["description"] + "` to claim this " + db["collectablesName"] + " for: **" + x["value"] + " " + db["currencyName"] + "!**"
				event << x["url"]
			end
			return
		end
	end

	event << "The " + db["collectablesName"] + " `" + description + "` doesn't exist, or isn't in your inventory."

	nil
end

#list collectables
bot.command(:rares) do |event|

	user = getUser(db, event.user.id.to_i)

	event << user["name"] + "'s `"+ user["collectables"].length.to_s + "` " + db["collectablesName"] + "s\n"

	user["collectables"].each do |x|
		event << "`" + db["collectables"][x]["description"] + "`\n"
	end	

	nil
end

#add collectables
bot.command(:addrare, min_args: 4) do |event, url, value, unlock, *description| 

	description = description.join(' ')

	db["collectables"][db["collectables"].length] = { "description" => description, "url" => url, "claimed" => false, "unlock" => unlock, "value" => value }

	event << "Added rare: `" + description + "`"

	save(db)
	nil

end

#bot.command(:update_avatar) do |event|
#
#	#begin
#	#bot.profile.avatar=(File.new("avatar.jpg"))
#	#rescue => e
#	#event << e.inspect
#	#end
#
#	avatar = File.new('avatar.jpg')
#	bot.profile.avatar = avatar
#
#end

def getUser(db, id)	
	usersdb = db['users']
	usersdb.each do |x|
		if x['id'] == id
			return x
		end
	end
	return nil
end

def save(db)

	db['timestamp'] = Time.now.to_s

	file = File.open("kekdb.json", "w")
	file.write(JSON.generate(db))

end

bot.run :async

	file = File.read('kekdb.json')
	db = JSON.parse(file)

	bot.user(120571255635181568).pm("Loaded database from **" + db['timestamp'] + "** :computer:\n")

bot.sync