<?php

/**
* Class to make unbound config file
*/
class unbound_conf
{
    
    function __construct()
    {
        header("Content-Type: text/plain");
    }

    function print()
    {
        //Steamcache server ip
        $server = $_POST["ip"];

        $files = glob("../*.txt");

        foreach($files as $file) 
        {
            echo "# File: " . substr($file, 3);
            echo PHP_EOL;
            foreach (file($file) as $key => $value) 
            {
                $value = trim($value, " \t\n\r\0\x0B");
                if (substr($value, 0,1) == "#") 
                {
                    $content = $value;
                }
                elseif (substr($value, 0,1) == "*") 
                {
                    $value = ltrim($value, '*');
                    $value = ltrim($value, '.');

                    $content = "# ------ Wildcard replaced with local-zone data ------ #" . PHP_EOL;
                    $content = $content . 'local-zone: "' . $value . '" redirect' . PHP_EOL;
                    $content = $content . 'local-data: "' . $value . ' A ' . $server . '"' . PHP_EOL;
                    $content = $content . "# ---------------------------------------------------- #";
                }
                else
                {
                    $content = 'local-data: "' . $value . ' A ' . $server . '"';
                }
                echo $content;
                echo PHP_EOL;
            }
            echo PHP_EOL;
            echo PHP_EOL;
        }
    }
}

?>