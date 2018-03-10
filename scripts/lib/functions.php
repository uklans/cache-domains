<?php

function is_cli()
{
    if (defined('STDIN'))
    {
        return true;
    }

    if (php_sapi_name() === 'cli')
    {
        return true;
    }

    if (array_key_exists('SHELL', $_ENV)) 
    {
        return true;
    }

    if (empty($_SERVER['REMOTE_ADDR']) and !isset($_SERVER['HTTP_USER_AGENT']) and count($_SERVER['argv']) > 0) 
    {
        return true;
    } 

    if (!array_key_exists('REQUEST_METHOD', $_SERVER))
    {
        return true;
    }

    return false;
}


// --------------------------------------------------------- //
// Funktion til at gemme kun den data man har behov for
// --------------------------------------------------------- //
// Defining the basic scraping function
function scrape_between($data, $start, $end)
{
    $data = stristr($data, $start); // Stripping all data from before $start
    $data = substr($data, strlen($start));  // Stripping $start
    $stop = stripos($data, $end);   // Getting the position of the $end of the data to scrape
    $data = substr($data, 0, $stop);    // Stripping all data from after and including the $end of the data to scrape
    return $data;  // Returning the scraped data from the function
}

// --------------------------------------------------------- //
// Funktion til at gemme kun den data man har behov for
// --------------------------------------------------------- //
// Defining the basic scraping function
function scrape_to($data, $end)
{
    //$data = stristr($data, $start); // Stripping all data from before $start
    //$data = substr($data, strlen($start));  // Stripping $start
    $stop = stripos($data, $end);   // Getting the position of the $end of the data to scrape
    $data = substr($data, 0, $stop);    // Stripping all data from after and including the $end of the data to scrape
    return $data;  // Returning the scraped data from the function
}

// --------------------------------------------------------- //
// Funktion til at gemme kun den data man har behov for
// --------------------------------------------------------- //
// Defining the basic scraping function
function scrape_from($data, $start)
{
    $data = stristr($data, $start); // Stripping all data from before $start
    $data = substr($data, strlen($start));  // Stripping $start
    //$stop = stripos($data, $end);   // Getting the position of the $end of the data to scrape
    //$data = substr($data, 0, $stop);    // Stripping all data from after and including the $end of the data to scrape
    return $data;  // Returning the scraped data from the function
}



?>