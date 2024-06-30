# Cloudflare API 动态 DNS 更新脚本

此脚本会自动将您的 Cloudflare DNS 记录更新为当前 IP，支持 IPv4 (A) 和 IPv6 (AAAA) 记录。

中文 | [English](README.md)

## 使用方法

下载并使脚本可执行：

```sh
curl https://raw.githubusercontent.com/Leao9203/cloudflare-api-v4-ddns/dev/cf-v4-ddns.sh > /usr/local/bin/cf-ddns.sh && chmod +x /usr/local/bin/cf-ddns.sh
```

### 命令

```sh
cf-ddns.sh
	-4|-6 \                    	# 指定 IPv4 或 IPv6
    -a cloudflare-api-token \   # 指定 Cloudflare API 令牌
    -u user@example.com \       # 指定 Cloudflare 邮箱
    -h host.example.com \       # 您想要更新的记录的 FQDN
    -z example.com \            # 您的域名（区域）
```

### 可选标志

```sh
    -f false(默认)|true \       # 强制 DNS 更新，不考虑本地存储的 IP
```

## 许可证

此项目根据 MIT 许可证进行许可 - 详见 [LICENSE](LICENSE) 文件。