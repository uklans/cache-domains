<?php

/**
* 
*/
class web_mode
{
	
	function __construct()
	{
		$this->request_handling();
	}

	function request_handling()
	{
		// Files - Always finde the correct path
		$dir_path = __FILE__;
		$dir_path = str_replace("web_mode.php", "", $dir_path);
		$files = glob($dir_path . "../../*.txt");

		// TODO: Update to support what services that shoud output
		if (isset($_POST["conf"]) && $_POST["conf"] == "unbound") 
		{
			require_once $dir_path . "../plugins/unbound.php";
			$unbound = new unbound("web");
			$unbound->make("web", $files, $_POST["ip"]);
		}
		else
		{
			$this->show_gui();
		}
	}

	function show_gui()
	{
		?>

		<form action="/steamcache/scripts/" method="post">
			<input type="text" name="ip" placeholder="ip of cache server"><br>
			<input type="radio" name="conf" value="unbound" checked> unbound<br>
			<input type="radio" name="conf" value="other"> Other<br>
			<input type="radio" name="conf" value="other2"> Other2<br>
			<input type="submit" value="Submit">
		</form>

		<?php
	}
}

?>