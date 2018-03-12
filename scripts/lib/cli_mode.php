<?php

/**
* 
*/
class cli_mode
{
	
	function __construct()
	{
		if (isset($_SERVER['argv'][1]) && isset($_SERVER['argv'][2]) && isset($_SERVER['argv'][3])) 
		{
			$dns_service = array('dns_service' => $_SERVER['argv'][1]);
			$output_mode = array('filetype' => $_SERVER['argv'][2]);
			$convert_to_array = explode(',', $_SERVER['argv'][3]);

			for($i=0; $i < count($convert_to_array ); $i++){
			    $key_value = explode('=', $convert_to_array [$i]);
			    $end_array[trim($key_value [0])] = trim($key_value [1]);

			}
			$services = $end_array;

			$this->make_conf($dns_service, $output_mode, $services); //Server ip comes from $services
		}
		else
		{
			$this->run();
		}
	}

	function run()
	{
		$cache_server = $this->cache_server();
		$dns_service = $this->dns_service();
		$output_mode = $this->output_mode($dns_service["filetype"]);
		$services = $this->services($cache_server);
		$this->make_conf($dns_service, $output_mode, $services); //Server ip comes from $services
	}

	function cache_server()
	{
		echo "// ------------------------------------------------------------------------------- //" . PHP_EOL;
		echo "Do you want to use different cache servers" . PHP_EOL;
		echo "Warning: using same cache server can result in a cache collision" . PHP_EOL;
		echo "Default is yes (hit enter)" . PHP_EOL;
		echo "Y/y = yes" . PHP_EOL;
		echo "N/n = no" . PHP_EOL;

		$handle = fopen ("php://stdin","r");
		$cli_input = fgets($handle);
		$cli_input = strtolower($cli_input);
		$cli_input = trim($cli_input);

		if ($cli_input == "y" || $cli_input == "yes") 
		{
			return "service_dependent";
		}
		elseif ($cli_input == "n" || $cli_input == "no")
		{
			echo "// ------------------------------------------------------------------------------- //" . PHP_EOL;
			echo "Type ip of the cache server" . PHP_EOL;

			$cache_server_ip = $this->get_and_validate_ip_from_input(); //Loops until you get it right
			return $cache_server_ip;
		}
		else
		{
			return "service_dependent";
		}
	}

	function dns_service()
	{
		echo "// ------------------------------------------------------------------------------- //" . PHP_EOL;
		echo "Choice dns server" . PHP_EOL;
		echo 'Press "1" for unbound' . PHP_EOL;


		$handle = fopen ("php://stdin","r");
		$cli_input = fgets($handle);
		$cli_input = strtolower($cli_input);
		$dns_service = trim($cli_input);

		echo PHP_EOL;
		
		if ($dns_service == "unbound" || $dns_service == "1") 
		{
			return array(
							"dns_service" => "unbound", 
							"filetype" => "conf"
						);
		}
		else
		{
			echo "Mode not supported, try agrin" . PHP_EOL . PHP_EOL;
			return $this->dns_service();
		}
	}

	function output_mode($filetype)
	{
		echo "// ------------------------------------------------------------------------------- //" . PHP_EOL;
		echo "Choice output press enter for default" . PHP_EOL;
		echo "1 = Default (makes a file called services.".$filetype." in the scripts output folder)" . PHP_EOL;
		echo "2 = text file (makes a file called services.txt in the scripts output folder)" . PHP_EOL;
		echo "3 = terminal (outputs the text in the terminal)" . PHP_EOL;

		$handle = fopen ("php://stdin","r");
		$cli_input = fgets($handle);
		$cli_input = strtolower($cli_input);
		$output_mode = trim($cli_input);

		echo PHP_EOL;

		if ($output_mode == "default" || $output_mode == "1") 
		{
			return array(
							"output_mode" => "default", 
							"filetype" => $filetype
						);
		}
		elseif ($output_mode == "textfile" || $output_mode == "2") 
		{
			return array(
							"output_mode" => "textfile", 
							"filetype" => "txt"
						);
		}
		elseif ($output_mode == "terminal" || $output_mode == "3") 
		{
			return array(
							"output_mode" => "terminal", 
							"filetype" => "echo"
						);
		}
		elseif ($output_mode == "") 
		{
			// Makes default file
			return array(
							"output_mode" => "default", 
							"filetype" => $filetype
						);
		}
		else
		{
			echo "Mode not supported, try agrin" . PHP_EOL;
			return $this->output_mode($filetype);

		}
	}

	function services($cache_server)
	{
		echo "// ------------------------------------------------------------------------------- //" . PHP_EOL;
		echo "Choice a service pack or make your own." . PHP_EOL;
		echo "You can mix as many as you whant seperate with space" . PHP_EOL;
		echo 'You can mix games and updates by wirting "g u" and press enter' . PHP_EOL;
		echo PHP_EOL;
		
		// Packs 
		echo "Packs:" . PHP_EOL;
		echo "A/a = All dns records (note need spi proxy)" . PHP_EOL;
		echo "G/g = Games" . PHP_EOL;
		echo "GS/gs = Games plus games that need spi proxy" . PHP_EOL;
		echo "GSO/gso = Only spi proxy games" . PHP_EOL;
		echo "U/u = Updates" . PHP_EOL;
		echo "O/o = Other" . PHP_EOL;
		echo PHP_EOL;

		// Files - Always finde the correct path
		$dir_path = __FILE__;
		$dir_path = str_replace("cli_mode.php", "", $dir_path);
		$files = glob($dir_path . "../../*.txt");

		echo "Services:" . PHP_EOL;
		foreach ($files as $key => $file) 
		{
			$file = scrape_between($file, "../../", ".txt");
			echo $key+1 . " = " . $file . PHP_EOL;;
		}


		$handle = fopen ("php://stdin","r");
		$cli_input = fgets($handle);
		$cli_input = strtoupper($cli_input);
		$services = explode(" ", $cli_input);

		foreach ($services as $key => $service) 
		{
			$services[$key] = str_replace("%0D%0A", "", urlencode(trim($service, " \t\n\r\0\x0B")));
		}

		echo PHP_EOL;

		if (empty($services)) 
		{
			echo "No services chosen" . PHP_EOL . PHP_EOL;
			return $this->services();
		}
		elseif (in_array("A", $services))
		{
			return $files;
		}
		else 
		{
			// Ensure that nomather the order the json content is in we always find the correct service if the file name and the service name in the json match
			$json = json_decode(file_get_contents($dir_path . "../../cache_domains.json"), true);
			foreach ($json["cache_domains"] as $key => $service) 
			{
				$json["cache_domains"][$service["name"]] = $service;
			}

			// Packs/catagoris
			foreach ($services as $key => $service) 
			{
				foreach ($files as $key1 => $file) 
				{
					$lines = file($file);

					$file = scrape_between($file, "../../", ".txt");

					$category = $json["cache_domains"][$file]["category"];

					if 	(($service == "G" || $service == "GS" || strtolower($service) == "games" || strtolower($service) == "games-spi") && strtolower($category) == strtolower("Games"))
					{
						if ($cache_server == "service_dependent") 
						{
							echo "Type cache server ip for " . $file . PHP_EOL;
							$cache_server_ip = $this->get_and_validate_ip_from_input(); //Loops until you get it right

							$services_out[$file] = $cache_server_ip;
						}
						else
						{
							$services_out[$file] = $cache_server;
						}
					}
					elseif (($service == "GS" || $service == "GSO" || strtolower($service) == "games-spi") && strtolower($category) == strtolower("Games-SPI"))
					{
						if ($cache_server == "service_dependent") 
						{
							echo "Type cache server ip for " . $file . PHP_EOL;
							$cache_server_ip = $this->get_and_validate_ip_from_input(); //Loops until you get it right

							$services_out[$file] = $cache_server_ip;
						}
						else
						{
							$services_out[$file] = $cache_server;
						}
					}
					elseif (($service == "U" || strtolower($service) == "updates") && strtolower($category) == strtolower("Updates")) 
					{
						if ($cache_server == "service_dependent") 
						{
							echo "Type cache server ip for " . $file . PHP_EOL;
							$cache_server_ip = $this->get_and_validate_ip_from_input(); //Loops until you get it right

							$services_out[$file] = $cache_server_ip;
						}
						else
						{
							$services_out[$file] = $cache_server;
						}
					}
					elseif (($service == "O" || strtolower($service) == "other") && strtolower($category) == strtolower("Other")) 
					{
						if ($cache_server == "service_dependent") 
						{
							echo "Type cache server ip for " . $file . PHP_EOL;
							$cache_server_ip = $this->get_and_validate_ip_from_input(); //Loops until you get it right

							$services_out[$file] = $cache_server_ip;
						}
						else
						{
							$services_out[$file] = $cache_server;
						}
					}
					elseif ((is_int(intval($service)) && $service == $key1+1) || $service == strtolower(scrape_between($file, "../../", ".txt"))) 
					{
						//Service is a int and and service match the file number we are lokking at, OR, the service name is the same as the file we are lokking in.
						if ($cache_server == "service_dependent") 
						{
							echo "Type cache server ip for " . $file . PHP_EOL;
							$cache_server_ip = $this->get_and_validate_ip_from_input(); //Loops until you get it right

							$services_out[$file] = $cache_server_ip;
						}
						else
						{
							$services_out[$file] = $cache_server;
						}
					}
				}
			}

			if (empty($services_out)) 
			{
				echo "No supported services chosen" . PHP_EOL . PHP_EOL;
				return $this->services();
			}
			else
			{
				return $services_out;
			}
		}
	}

	function make_conf($dns_service, $output_mode, $services)
	{
		// Always finde the correct path in cli
		$dir_path = __FILE__;
		$dir_path = str_replace("cli_mode.php", "", $dir_path);

		require_once $dir_path . "../plugins/" . $dns_service["dns_service"] . ".php";

		if ($dns_service["dns_service"] == "unbound") 
		{
			$unbound = new unbound("cli");
			$output = $unbound->make("cli", $services);
		}
		elseif ($dns_service["dns_service"] == "other_service_replace_me") 
		{
			# code...
		}
		else
		{
			echo "DNS services not implemnted";
			exit;
		}


		if ($output == "" || $output == NULL) 
		{
			echo "An error occurred making DNS output data" . PHP_EOL;
			echo "No data from DNS making plugin: " . $dns_service["dns_service"];
		}
		else
		{
			if ($output_mode["filetype"] == "echo") 
			{
				echo $output;
			}
			else
			{
				if(!is_dir($dir_path . "../output"))
				{
					echo "Making output folder" . PHP_EOL;
					mkdir($dir_path . "../output");
					echo $dir_path . "../output". PHP_EOL;
				}
				file_put_contents($dir_path . "../output/services." . $output_mode["filetype"], $output);
				echo "File: " . $dir_path . "../output/services." . $output_mode["filetype"] . PHP_EOL;
				echo "Output done";
			}
		}

	}

	function get_and_validate_ip_from_input()
	{
		//Loops until you get it right
		$handle = fopen ("php://stdin","r");
		$cli_input = fgets($handle);
		$cli_input = strtolower($cli_input);
		$cache_server_ip = trim($cli_input);

		// Validate ip
		if (filter_var($cache_server_ip, FILTER_VALIDATE_IP)) 
		{
		    echo $cache_server_ip . " is a valid IP address" . PHP_EOL . PHP_EOL;
		    return $cache_server_ip;
		} 
		else 
		{
		    echo $cache_server_ip . " is not a valid IP address" . PHP_EOL . PHP_EOL;
		    echo "Try agrin" . PHP_EOL;
		    return $this->get_and_validate_ip_from_input(); //Loops until you get it right
		}
	}
}




?>