# Frequently Asked Questions

## What is this list?

This is a list of hostnames for various CDNs or companies that host game related content that can be cached.

## Who is this list for?

The list is maintained primarily for people running LAN parties / gaming events, whether that's 10 people gaming in a friend's garage or thousands bringing their own machines to an exhibition centre. Anyone running a LAN will likely benefit from caching game downloads and other suitable content, by saving internet bandwidth and preventing multiple people downloading the same content from the internet. However anyone running any network that includes multiple gaming computers (such as an internet or gaming cafe) may also benefit.

## How do I use this list?

There are multiple ways to use this list in a caching solution. See [the readme](https://github.com/uklans/cache-domains#usage) for more information.

## Do you recommend any cache solutions?

Many of the maintainers of this repo also contribute to [the lancachenet project](https://github.com/lancachenet/monolithic) which uses this list as its source of host names.

## Why isn't *some other service* on the list?

There are several reasons why a particular service / CDN / website might not be on this list. Here are some of the more common ones:

 1. It's not technically possible to cache it. Many popular websites, including video streaming sites and even some games CDN's use SSL Encryption (i.e https URLs) to serve their content. Because the client opens a secure connection directly to the host, there is no way for the network operator to see what they are downloading, nor cache it. Whilst there are several approaches to work around this, such as MITM techniques, they usually rely on control over the client device to affect SSL Certificates - control somebody running a BYOC LAN typically does not have over the devices customers bring.
 
   - [These issues](https://github.com/uklans/cache-domains/issues?q=is%3Aissue+is%3Aopen+label%3Ahttps-cantfix) contain game CDNs that we would like to include, but cannot for this reason. 
 
 2. It's out of scope for a LAN. We try to keep this list targeted towards people running LANs. Whilst some none game-related CDNs are included for things like windows updates that use internet bandwidth at LANs, we do not go searching for unrelated sites / hostnames.
 
 3. It's not a good cache target / it would not get a good hit ratio. Game downloads are a great cache target because they are large, remain the same for every user and are likely to be downloaded multiple times at a LAN. Other hostnames that only serve dynamic or media files, or content that is not likely to be downloaded multiple times is not a good cache target and can waste valuable storage space on your cache server. This can lead to potentially more valuable content being evicted from the cache due to low space.
 
 4. We simply don't yet have a tested list of hostnames for it yet. This is the category you can help with - if you have something that doesn't fall into one of the above reasons not to include it, we would love to review your PR. See [the readme](https://github.com/uklans/cache-domains) for instructions on how to add a new CDN.

## SNI Proxy / HTTPS

[lancachenet/sniproxy](https://github.com/lancachenet/sniproxy) is part of the lancache project and allows hostnames that serve BOTH http and https content to be included in this list. Traffic going to that hostname on port 80 (http) will hit lancache and be cached, whilst traffic on port 443 (HTTPS) is passed straight through to the internet by sniproxy.

It does not allow https / SSL content to be inspected or cached. Hostnames that serve all or almost all https traffic are still unlikely to be good candidates for this list, as it just places load on the cache box but does not save any internet bandwidth.

## How can I test an addition to this list?

If you are using the lancachenet project, you can fork this repo, add your test hostnames and then use [these instructions](https://github.com/lancachenet/lancache-dns#custom-forksbranches) to use it with your cache instance rather than the main repo.