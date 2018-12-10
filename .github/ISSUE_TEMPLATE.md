### Describe the issue you are having
<!-- replace this with your issue description -->

### Describe your setup?
<!-- What is your dns server, are you using steamcache/dns or another resolver -->

### Are you running sniproxy
<!-- Yes/no -->

### DNS Configuration
```
<!-- Paste either your docker run command for the DNS container OR explain how you have setup DNS zone files etc -->
```

### Sniproxy output
Please paste the output from `docker logs <sniproxy container name/id> | sed 's/.*\:443 \[//;s/\].*//' | sort | uniq -c` below
```
<!-- If you are running sniproxy paste the output to the following command
docker logs <sniproxy container name/id> | sed 's/.*\:443 \[//;s/\].*//' | sort | uniq -c
-->
```
