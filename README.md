# KekBot

KekBot is a Discord meme trading bot. It is programmed equally with love *and* hate in Ruby, working off of a JSON databse.

## How it Works

Users begin by registering with `.register`. This opts them in to KekBot's databse, and sets up their Wallet with a starting alotment of "keks" - the currency.

### Keks

You can check your wallet with `.keks`.

**Dank Bank keks** 

These keks are your savings, and are used to purchase "rares" (covered later)

**Stipend**

This is a seperate pool of keks that you are given each day (currently capped at 40) that you can give to other people to put into their Bank. Award your friends with keks for being funny, sharing great content or banter, or just generally being awesome!

You can give stipend keks to other users with `.give @user [amount]`

### Rares

Rares are collectible memes that you can claim or purchase from other users. These aren't your average memes; they are often related to in-jokes in your community - they're special! As of `KekBot V1.X`, all rares are unique and can only be owned by one person at a time.

You can check your rare inventory with `.rares`. You can view a specific rare with `.show [description]`. 

Rares can be traded (rare for rare) with friends with `.trade`, or sold for a price to other user with `.sell`. Each rare has a minimum sale value.

## Under the Hood

KekBot's current schema:

```json
{
  "timestamp": "2016-06-09 13:10:00 -0400",
  "netTraded": 0,
  "collectiblesName": "rare",
  "currencyName": "keks",
  "users": {
    "120571255635181568": {
      "name": "Lune",
      "bank": 10,
      "nickwallet": false,
      "currencyReceived": 0,
      "karma": 0,
      "stipend": 40,
      "collectibles": [
        "69efa478890e114b2f3ee7c2e9875fff2925f9a3"
      ]
    }
  },
  "collectibles": {
    "69efa478890e114b2f3ee7c2e9875fff2925f9a3": {
      "description": "some description",
      "timestamp": "2016-06-09 08:41:52 -0400",
      "author": "Lune",
      "url": "some.url",
      "visible": false,
      "claimed": false,
      "unlock": 0,
      "value": 10
    }
  }
}
```

*"Most of this is pretty self explanatory," - Lune, 2k16*

Some not-so obvious things about this db:

- `netTraded` is a counter for the total number of `currency` traded, across all users, to date. This is used with `"collectibles" : [ .. "unlock": value ..`  and will make more rares become available once `netTraded` reaches this threshhold. KekBot will push out a notification when new rares become available..

- `currencyReceived`; we sperately track how many of `currency` the user has recieved to date. This is for a future feature for `KekBot v2.X`.

- `karma`; the number of times the user has been sent `currency`. For now, this just lets us get some statistics via `currencyReceived / karma`.

- `claimed`; once a rare becomes available, it must be `.claim`ed for its `value`. After which, this field is `true`, and will always be in a players inventory. This lets us run a report on which `collectibles` have yet to be claimed by anyone.

- `collectibles` inside of `user` is a list of indexes / IDs in the `collectibles` array that the `user` owns.


## Credits

Original idea by Derekuchan.

Programmed by Lune (z64)

Content Contributors:
```
Aeroxyl
Paper
Skudfuddle
TODOKEK
```

**Join us on Discord!**

https://discord.gg/011tZbkyatr8nf26S

