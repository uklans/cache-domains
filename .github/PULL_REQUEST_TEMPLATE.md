### What CDN does this PR relate to
<!-- Please clearly state what existing cdn this pr relates to, or which games if it's a new cdn -->

### Does this require running via sniproxy
<!-- Yes/no/untested -->

### Capture method
<!-- Please give a short description how you ascertained the updates to the domain files, wireshark, dns logs etc -->

### Testing Scenario
<!-- Please give a short description on how you have tested this and where (home, office, small lan, large lan etc) -->

### Testing Configuration
```
<!-- Paste either your docker run command from the DNS container OR explain how you have setup DNS zone files etc to test this issue -->
```

### Sniproxy output
Please paste the output from `docker logs <sniproxy container name/id> | sed 's/.*\:443 \[//;s/\].*//' | sort | uniq -c` below
```
<!-- If you are running sniproxy paste the output to the following command
docker logs <sniproxy container name/id> | sed 's/.*\:443 \[//;s/\].*//' | sort | uniq -c
-->
```

