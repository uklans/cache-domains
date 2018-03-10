<?php

require_once "lib/include.php";

if (is_cli() === true) 
{
	// Running in cli (commandline)
	$cli_mode = new cli_mode();

}
else
{
	// Running in web interface for hosting
	$web_mode = new web_mode();
}

?>