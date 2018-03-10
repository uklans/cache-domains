<?php

/**
* Template class to support new dns services
/ There are 5 places to change data
*/
class template
{
    
    function __construct($mode)
    {
        if ($mode != "cli") 
        {
            header("Content-Type: text/plain");
        }
    }

    function make($mode, $services, $server)
    {
        /// Files - Always finde the correct path in cli
        $dir_path = __FILE__;
        // ----------------------------------------------------------
        // Change below me
        // ----------------------------------------------------------
        $dir_path = str_replace("template.php", "", $dir_path); // Change template.php to the corrent file name of the new file
        // ----------------------------------------------------------
        // Change above me
        // ----------------------------------------------------------
        $files = glob($dir_path . "../../*.txt");

        foreach ($services as $key => $service) 
        {
            $services[$key] = scrape_between($service, "../../", ".txt");
        }
        
        $output = "";

        foreach($files as $file) 
        {
            if (in_array(scrape_between($file, "../../", ".txt"), $services)) 
            {
                // ----------------------------------------------------------
                // Change below me
                // ----------------------------------------------------------
                // Change the # to match comments in youre services (default # starts comment if not changed)
                $output .= "# File: " . scrape_between($file, "../../", ".txt"); 
                // ----------------------------------------------------------
                // Change above me
                // ----------------------------------------------------------
                $output .= PHP_EOL;
                foreach (file($file) as $key => $line) 
                {
                    $line = trim($line, " \t\n\r\0\x0B");
                    if (substr($line, 0,1) == "#") 
                    {
                        // Comment handling
                        // ----------------------------------------------------------
                        // Change below me
                        // ----------------------------------------------------------
                        $output .= $line; // Change this to match comments in youre services (default # starts comment if not changed)
                        // ----------------------------------------------------------
                        // Change above me
                        // ----------------------------------------------------------
                    }
                    elseif (substr($line, 0,1) == "*") 
                    {
                        // Wildcard handling change to match services
                        // Output for wildcard

                        // ----------------------------------------------------------
                        // Change below me
                        // ----------------------------------------------------------
                        $line = ltrim($line, '*'); // Removing the * in the line
                        $line = ltrim($line, '.'); // Removing the . in the line

                        // Append to the output file 
                        // line is the corrent line in the file (domainname)
                        $output .= "# ------ Wildcard replaced with local-zone data ------ #" . PHP_EOL;
                        $output .= 'local-zone: "' . $line . '" redirect' . PHP_EOL;
                        $output .= 'local-data: "' . $line . ' A ' . $server . '"' . PHP_EOL;
                        $output .= "# ---------------------------------------------------- #";
                        // ----------------------------------------------------------
                        // Change above me
                        // ----------------------------------------------------------
                    }
                    else
                    {
                        // Single domain handling
                        // ----------------------------------------------------------
                        // Change below me
                        // ----------------------------------------------------------
                        $output .= 'local-data: "' . $line . ' A ' . $server . '"';
                        // ----------------------------------------------------------
                        // Change above me
                        // ----------------------------------------------------------
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