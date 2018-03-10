<?php

/**
* 
*/
class cli_mode
{
	
	function __construct()
	{
		$this->run();
	}

	function run()
	{
		$server = $this->dns_server();
		$dns_service = $this->dns_service();
		$output_mode = $this->output_mode($dns_service["filetype"]);
		$services = $this->services();
		$this->make_conf($dns_service, $output_mode, $services, $server);
	}

	function dns_server()
	{
		echo "// ------------------------------------------------------------------------------- //" . PHP_EOL;
		echo "Type ip of the dns server" . PHP_EOL;

		$handle = fopen ("php://stdin","r");
		$cli_input = fgets($handle);
		$cli_input = strtolower($cli_input);
		$dns_server = trim($cli_input);

		return $dns_server;
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
			echo "Mode not supported, try agrin" . PHP_EOL;
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

	function services()
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
			//$file = str_replace(".txt", "", $file);
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
			// Packs/catagoris
			foreach ($services as $key => $service) 
			{
				foreach ($files as $key1 => $file) 
				{
					$lines = file($file);

					$category = scrape_between($lines[0], "<", ">");

					if 	(($service == "G" || $service == "GS") && trim(strtolower($category)) == strtolower("Games"))
					{
						$services_out[$key1] = $file;
					}
					elseif (($service == "GS" || $service == "GSO") && strtolower($category) == strtolower("Games-SPI"))
					{
						$services_out[$key1] = $file;
					}
					elseif ($service == "U" && strtolower($category) == strtolower("Updates")) 
					{
						$services_out[$key1] = $file;
					}
					elseif ($service == "O" && strtolower($category) == strtolower("Other")) 
					{
						$services_out[$key1] = $file;
					}
					elseif (is_int(intval($service)) && $service == $key1+1) 
					{
						$services_out[$key1] = $file;
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

	function make_conf($dns_service, $output_mode, $services, $server)
	{
		// Always finde the correct path in cli
		$dir_path = __FILE__;
		$dir_path = str_replace("cli_mode.php", "", $dir_path);

		require_once $dir_path . "../plugins/" . $dns_service["dns_service"] . ".php";

		if ($dns_service["dns_service"] == "unbound") 
		{
			$unbound = new unbound("cli");
			$output = $unbound->make("cli", $services, $server);
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

		if ($output_mode["filetype"] == "echo") 
		{
			echo $output;
		}
		else
		{
			file_put_contents($dir_path . "../output/services." . $output_mode["filetype"], $output);
			echo "Output done";
		}

	}
}




?>