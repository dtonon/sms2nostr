# sms2nostr

sms2nostr is a proof of concept of a sms-to-nostr gateway that permits a user to post notes on Nostr using non internet enabled phones or IoT devices, or a feature phone when the network is not available.

Post only. Receiving is technically possible but that would require a curated inbound filter to be manageable via SMS and could be quite expensive when operator debit the SMSs.

## Privacy & Security

The system tries to be more privacy oriented and secure as possibile: the sender's phone number, nsec and pin are never saved to DB or logged (with the exception of debug mode that save the LOGIN operations and output some logs).
When using the "your own key mode" the nsec key is decripted and used on the fly just for posting.  
The only concern is about the POST mode, because the send is not pin protected, so it is possible that someone can spoof the number (if known, of course) and post in your name.
The best approach is create locally a key and LOGIN it with a PIN, this gives full privacy and security.

## Configuration

The configuration is done editing config/settings.yml; the default on is ready to go and just include 2 relays. You have to disable the debug mode (active for security) to go live.

```yml
dryrun_mode: true
# When active the messages are just logged and never posted to Nostr; the LOGIN / WIPE commands are saved to DB

relays: ["wss://relay.damus.io", "wss://relay.snort.social"]
# The list of relays where to post the notes
```

Some optional values are available to tweak the SOS mode.

```yml
antispam_mode: false
# If active the commands-prefix is always neeeded otherwise the message is discarted
# If disabled (default) a plain message is treated as if it were a POST

dm_recipient: npub1zzzzzzzzzzzzzzzzzzzzzzz
# Send a private message to a Nostr account instead of posting the note publicly; useful for testing purpose or management of IoT devices
# SOS messages are always public!

sos_mode: false
# If active SOS commands are accepted

show_number_on_sos: false
# Show the sender number in the SOS alert

sms2nostr_host: https://localhost:3000
# The service host, used to grab the SOS image

sms2nostr_nsec: nsec1xxxxxxxxxxxxxxxxxxxxxxxxxxx
# The service (not your one) nsec, used to post the SOS alert
```

## Setup

The system can receive SMSs using two providers:

### Incoming SMS fowarder
An open source Android app.  
Dowload: https://github.com/bogkonstantin/android_income_sms_gateway_webhook  
Endpoint: https://yourdomain.com/api/v1/incoming_sms_forwarder/fetch

### MessageBird
MessageBird is a pay service that rents virtual numbers; the numbers can receive sms from all over the world.
Subscribe: https://www.messagebird.com
Endpoint: https://yourdomain.com/api/v1/messagebird/fetch

### Textmagic
Textmagic is a pay service that rents virtual numbers; the numbers can receive sms only from the same country.  
Subscribe: https://www.textmagic.com  
Endpoint: https://yourdomain.com/api/v1/textmagic/fetch

---

New providers can easily be added, see `provider_template.rb`.

## Usage

sms2nostr offers 4 modality:

* POST mode: create a new account (random key) posting the first message and use it for subsequent messages;
* BURN mode: create a new key for every new messages;
* LOGIN mode: login with a specific key and associate it with a pin, use the account for subsequent messages; 
* SOS: sent a message with a new random account highlighted by an "SOS image.

You can interact with the gateway using the following sms commands.  
The space around the "#" separator are not mandatory.

### Standard post
```
POST # Hello Nostr! Low tech vibes here
```
Post the message using a new random key and associate it to the sender number; the following posts will use the same key. You can obtain the key only if you have access to the DB (your instance).

If the `antispam_mode` config is disabled you can omit the "POST #" prefix, it is implicit, so you can send only the text:

```
Hello Nostr! Low tech vibes here
```
Fast posting!

### Standard post with a new random key
```
RESET # Hello Nostr! I'm posting from a remote location
```
Post the message forcing a new key and associate it to the sender number; the following posts will use the same key. You can obtain the key only if you have access to the DB (your instance).

### Post via burn account
```
BURN # This is the secret: I prefer Twitter :P
```
Post the message using a throwaway account; every post has a new key and no "account" has been created; the key is not saved anywhere.

### Login with your own key
```
LOGIN # nsec1xxxxxxxxxxxxxxxxxxxxxxxxxxxxx # MYPIN123
```
Set your own key to use in future posts and associate it to a personal pin (password); the key is saved in plain in the db so use it only on your own sms2nostr instance or with throwaway account.

### Post with your own key
```
MYPIN123 # Hello Nostr! I'm posting from a remote location
```
Post the message using a new random key and associate it to the sender number; the following posts will use the same key. You can obtain the key only if you have access to the DB (your instance).

### Logout and wipe the account
```
WIPE # MYPIN123
```
Wipe your key/account and all the related messages from the DB.

### SOS alert
```
SOS # Help i have a broken leg, GPS 46.86196543558215, 10.99588952865901
```
Post the message using a throwaway account and add a SOS image to highlight it; if the "show_number_on_sos" option is enabled add the phone number to help track down the sender; every post has a new key and no "account" has been created; the key is not saved anywhere.
Even if the `dm_recipient` option is enabled the SOS is public fired, to be seen by as many people as possible.

## Future - Todo

- [ ] Allow login and posting without the security pin prefix; on a self-managed instance the service number acts as a password because it is known only to the sender.