# Simple Chat Bubbles 2

## Description

Simple Chat Bubbles helps to alert you when other people are talking. This addon provides a visually better and more flexible option compared to the built-in chat bubbles options (which is still in beta). Also it allowing you to see chat bubbles for players that are not on your screen right now.

The bubbles are positioned in the upper half center of screen. There are two rows of 3 bubbles, for a total of 6 bubbles. The number of bubbles shown is configurable, if you would like to save space or not have so much "bubble clutter". However, the less bubbles available, the more likely incoming chat will overwrite existing bubbles.

Bubbles expand in the following order:

* Top Center
* Top Left
* Top Right
* Bottom Left
* Bottom Right
* Bottom Center

## Features

Simple Chat Bubbles has a tidy amount of options to help you personalize the chat bubbles. Please see the screenshots for more details.

Chat bubbles can be enable or disabled for different events individually to unclutter your screen. For instance you may select to show chat bubbles for your guild and party and ignore all other messages. Chat bubbles text colored exactly as it's appearing in your chat window to make it easier to distinguish one from another.

Current events on which you can receive an alert:
* Any guild messages (including officer messages).
* Per zone messages (including language-specific).
* Whispers / tells / says / yells / emotes (including monster).
* Group / party / leader messages.

Other features:
* Bubble text font size and color are configurable or default colors from your chat window can be used. Also bubble background, shadow, opacity and other visuals can be changed too.
* Adaptive bubble duration - minimal and maximal on-screen time of bubbles can be set and the addon will adjust it automatically based on the size of a chat message displayed.
* [NEW] Positions and distance between bubbles can be adjusted to better fit your UI and screen resolution.
* Can display bubbles for your own messages sent or you can disable it.
* Of course chat bubbles can be disabled in combat to prevent distraction.
* Includes a simple spam filter :).

## Integration with Chat Sound Alerts

This addon exposes its API via LibAddonAPI and integrates with [Chat Sound Alerts](http://www.esoui.com/downloads/info1343-ChatSoundAlerts.html) at the configuration level. Right now only one way syncronization is supported - from Chat Sound Alerts to this addon. When any of notificaiton channel options are changed in Chat Sound Alerts the same options will be replicated in Simple Chat Bubbles too allowing you to keep settings of both addons in sync in a snap.

## How do I configure it?

You can find the settings in Addon Settings -> Simple Chat Bubbles. In the Chat Sound Alerts section you will find everything you need precisely configure and fine tune the addon to your individual needs. It is pretty straight forward and the tooltips on mouse overs has even more detailed information.

## What's up next?

* Better integration with Chat Sound Alerts.
* Improve spam filtering.
* Add more chat bubbles popup effects.

## Credits.

* sirinsidiator and Seerah for LibAddonMenu-2.0 - so much time saved!
* Dio for the writing original code for the [addon](http://www.esoui.com/downloads/info136-SimpleChatBubbles.html).
* RibbedStoic for reviving the [addon](http://www.esoui.com/downloads/info720-SimpleChatBubbles-Revived.html).