Cloudflare API v4 Dynamic DNS Update in Bash, without unnecessary requests
Now the script also supports v6(AAAA DDNS Recoards)

[中文文档](README_zh.md)

More details can be found on my blog (zh_CN Only) https://blog.ascn.site/post/20220121081740/

# Usage
	curl https://raw.githubusercontent.com/Leao9203/cloudflare-api-v4-ddns/dev/cf-v4-ddns.sh > /usr/local/bin/cf-ddns.sh && chmod +x /usr/local/bin/cf-ddns.sh
	
	cf-ddns.sh
	-a cloudflare-api-token \ # specify cf token
	-u user@example.com \     # specify cf email
	-h host.example.com \     # fqdn of the record you want to update
	-z example.com \          # will show you all zones if forgot, but you need this
	-t A|AAAA                 # specify ipv4/ipv6, default: ipv4
## Optional flags:
	-k cloudflare-api-key \   # specify cf global key
	-f false|true \           # force dns update, disregard local stored ip
