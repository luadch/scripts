	RSSFeedWatch.lua
		A socket script that watches an RSS feed for changes

        - this script adds a command "rss"
        - usage: [+!#]rss feedhelp for more instructions and a list of available commands
        
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
			