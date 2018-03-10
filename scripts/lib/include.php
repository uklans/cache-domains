<?php

// ------------------------------------------------------------ //
// Array of files to include
// ------------------------------------------------------------ //
$includes = array(
					"functions",
					"cli_mode",
					"web_mode",
				);


// ------------------------------------------------------------ //
// Include the php files in the array
// ------------------------------------------------------------ //
foreach ($includes as $key => $value) 
{
	//Always finde the correct path
	$dir_path = __FILE__;
	$dir_path = str_replace("include.php", "", $dir_path);

	require_once $dir_path . $value . ".php";
}


?>