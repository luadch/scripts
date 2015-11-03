	RSSFeedWatch.lua
		A socket script that watches an RSS feed for changes

        - this script adds a command "rss"
        - usage: [+!#]rss feedhelp for more instructions and a list of available commands

		v0.08: by Jerker
			- Fixed a problem with character entities (&#nnn;)
			- Updated timer to use os.time

		v0.07: by Jerker
			- Added msgToPM option to send messages from commands to PM (true) or main (false)
			  when user hasn't selected channel, otherwise messages are sent to where user selected
			  Error messages are still sent to main
			- Converting non UTF-8 feeds to UTF-8
			- Don't truncate links
			- New labels for feed fields with tab count for formatting output
			- Added RC to Add and Delete feeds and to toggle ForceFeed setting

		v0.06: by Jerker
			- Added support for atom feeds
			- Added support for ssl
		
		v0.05: by Night
			- Fix a problem with using nick prefix script
			- Fix a typo in FeedHelp

		v0.04: by Night
			- Change the ForceFeed option to allow enabling multiple forced feeds
			- Add ForceFeedPM option to send forced feeds in PM
		
		v0.03: by Night
			- Better ways to change FeedText content
			
		v0.02: by Night
			- Add RC
			- Add option to Get all feeds at once ( ex. different release category links ) 
			- Don't list commands user is not allowed to use in FeedHelp

		v0.01: by Night
            - initial version


	Dependencies:
		Luasocket http.
		Luadch comes with these already so all you need to do is:
			-Create socket folder ../lib/luasocket/lua/socket/
			-Copy all files from ../lib/luasocket/lua/ folder into ../lib/luasocket/lua/socket/
		
		Luasec https.
		Luadch comes with these already so all you need to do is:
			-Create ssl folder ../lib/luasec/lua/ssl/
			-Copy all files from ../lib/luasec/lua/ folder into ../lib/luasec/lua/ssl/
		
		slaxml.lua
			-Copy folder slaxml to ../lib/
		
