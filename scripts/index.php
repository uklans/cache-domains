<?php

if (isset($_POST["conf"]) && $_POST["conf"] == "unbound") 
{
	require "unbound_conf.php";
	$unbound_conf = new unbound_conf();
	$unbound_conf->print();
}
else
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

?>