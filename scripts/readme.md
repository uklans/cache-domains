# Scripts

##PHP Script

###CLI mode (Comandline)
Run the index.php file using php folow the guide in the script.
The CLI mode support to choose from categories or a single or more services at onces.

####Running without arguments (running in terminal)
* Decide if you want to use different cache servers (using same cache server can result in a cache collision)
	* Yes, is also default if enter is hit (you enter ip's for the cache based on the service you want to cache later in the script)
	* No, you type a global ip adresse for the cache
* Enter DNS server type
	* 1 = unbound
	* More to come
* Enter output mode and file
	* Enter = default (makes config (file extension) based on dns server)
	* 1 = default (makes config (file extension) based on dns server)
	* 2 = txt (makes a txt file)
	* 3 = echo (prints the output in the terimnal)
* choose from categories or a single or more services at onces
	* Choose more categories or services by separating using space
		* Example "g u"  (gives games and updates)
	* Categories
		* A = All dns records (note need spi proxy)
		* G = Games
		* GO = Games plus games that need spi proxy
		* GOS = Only spi proxy games
		* U = Updates
		* O = Other
	* Single services 
		* Based on the txt files
		* Use there number example 1 for apple or just type apple it is up to you
		* Seperate using space

####Running with arguments
* The script takes 3 inputs 
	* DNS server
		* unbound
		* more to come
	* File extension (just a string example "conf" or "txt")
	* Services
		* Use the names of the txt files (without ".txt") and the cache server ip
			* Example "steam=192.168.1.1,uplay=192.168.1.2"
				* All spaces is trimt so "steam = 192.168.1.1 , uplay = 192.168.1.2" is also okay
* Full example
	* Linux
		* php /path/to/file/cache-domains/scripts/index.php unbound conf "steam=192.168.1.1,uplay=192.168.1.2"
	* Windows
		* "C:\Program Files\PHP\v7.0\PHP.exe" C:\path\to\file\cache-domains\scripts\index.php unbound conf "steam=192.168.1.1,uplay=192.168.1.2"

###Web mode (hosting on webserver)
The web mode do not support what kind of servies you want, all is exported by default.
Functions is to come.