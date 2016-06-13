# KekBot

KekBot is a Discord meme trading bot. It is programmed equally with love *and* hate in Ruby, working off of a JSON databse.

**Invite KekBot to your server: https://discordapp.com/oauth2/authorize?client_id=185442396119629824&scope=bot&permissions=0**

## Support

Questions, bugs, or feature requests? **Please report them here on GitHub!**

For other inquiries, please join our Discord server and someone will be around to help you.

**Join us on Discord!**

https://discord.gg/011tZbkyatr8nf26S

## How it Works

Users begin by registering with `.register`. This opts them in to KekBot's databse, and sets up their Wallet with a starting alotment of "keks" - the currency.

### Keks

You can check your wallet with `.keks`.

**Dank Bank Keks** - These keks are your savings, and are used to purchase "rares" (covered later)

**Sipend** - This is a seperate pool of 40 keks that you are given each day that you can give to other people to put into their Bank. 

*Award your friends with keks for being funny, sharing great content or banter, or just generally being awesome!*

You can give stipend keks to other users with `.give @user [amount]`

### Rares

Rares are collectible memes that you can claim or purchase from other users. These aren't your average memes; they are often related to in-jokes in your community - they're special! As of `KekBot V1.0`, all rares are unique and can only be owned by one person at a time.

You can check your rare inventory with `.rares`. You can view a specific rare with `.show [description]`. 

Rares can be traded (rare for rare) with friends with `.trade`, or sold for a price to other user with `.sell`.

You can see what rares are available for purchase with `.catalog`. You can then take a closer look at them with `.show [description]`, and then use `.claim [description]` to claim it for your own. 

**Examples:**

Open a trade with `@User` trading `my meme` for `your meme`

`.trade @User my meme / your meme`

Sell `my meme` to `@User` for `20 keks`

`.sell my meme @User 20`


### Contribute!

Submit rares to the database with `.submit [url] [description]`.

Once the rare is approved by our mod team, it will be added to the database and will eventually be available for you and your friends to `.claim`.

## Credits

Original idea by Derekuchan.
Feature Design by Lune & Derekuchan
Programmed by Lune (z64)

**Project Contributors**

Other friends who have contributed in the development of KekBot:

```
Aeroxyl
Baldbeard
Paper
Skudfuddle
TODOKEK
```

:heart:
