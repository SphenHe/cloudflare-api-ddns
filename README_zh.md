基于 Cloudflare API 在 Bash 中进行 DDNS 更新，无需一些不必要的依赖。
现在这个脚本已经支持了 IPv6（AAAA 的 DNS 记录）

更详细的用法可以在我博客上看到 https://blog.ascn.site/post/d6e420c9614f.html

# 用法
	curl https://raw.githubusercontent.com/Leao9203/cloudflare-api-v4-ddns/dev/cf-v4-ddns.sh > /usr/local/bin/cf-ddns.sh && chmod +x /usr/local/bin/cf-ddns.sh
	
	cf-ddns.sh
	-a cloudflare-api-token \ # 填写 Cloudflare API Token
	-u user@example.com \     # 填写 Cloudflare 用户邮箱
	-h host.example.com \     # 填写更新的子域名
	-z example.com \          # 填写在 Cloudflare 所托管的域名
	-t A|AAAA                 # 填写更新的记录类型，IPv4（A）或者 IPv6（AAAA）
## 可选操作:
	-k cloudflare-api-key \   # 使用 Cloudflare Global Key，注意不能和 API Token 同时使用。
	-f false|true \           # 强制更新 DNS，忽略本地文件。
