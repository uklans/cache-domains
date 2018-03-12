<?php

/**
* Class to make unbound config file
*/
class unbound
{
    
    function __construct($mode)
    {
        if ($mode == "web") 
        {
            header("Content-Type: text/plain");
        }
    }

    function make($mode, $services)
    {
        /// Files - Always finde the correct path in cli
        $dir_path = __FILE__;
        $dir_path = str_replace("unbound.php", "", $dir_path);
        $files = glob($dir_path . "../../*.txt");

        $output = "";

        foreach($files as $file) 
        {
            if (array_key_exists(scrape_between($file, "../../", ".txt"), $services)) 
            {
                $server = $services[scrape_between($file, "../../", ".txt")];
                $output .= "# File: " . scrape_between($file, "../../", ".txt") . PHP_EOL;
                foreach (file($file) as $key => $line) 
                {
                    $line = trim($line, " \t\n\r\0\x0B");
                    if (substr($line, 0,1) == "#") 
                    {
                        // Comment handling
                        $output .= $line;
                    }
                    elseif (substr($line, 0,1) == "*") 
                    {
                        // Wildcard handling
                        $line = ltrim($line, '*');
                        $line = ltrim($line, '.');

                        // Output for wildcard
                        $output .= "# ------ Wildcard replaced with local-zone data ------ #" . PHP_EOL;
                        $output .= 'local-zone: "' . $line . '" redirect' . PHP_EOL;
                        $output .= 'local-data: "' . $line . ' A ' . $server . '"' . PHP_EOL;
                        $output .= "# ---------------------------------------------------- #";
                    }
                    else
                    {
                        $output .= 'local-data: "' . $line . ' A ' . $server . '"';
                    }
                    $output .= PHP_EOL;
                }
                $output .= PHP_EOL;
                $output .= PHP_EOL;
            }
        }
        if ($mode == "cli") 
        {
            return $output;
        }
        else
        {
            echo $output;
        }
    }
}

?>