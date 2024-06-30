# Cloudflare API Dynamic DNS Update Script

This script automatically updates your Cloudflare DNS record to the current IP, supporting both IPv4 (A) and IPv6 (AAAA) records.

[中文](README_zh.md) | English

## Usage

To download and make the script executable:

```bash
curl https://raw.githubusercontent.com/SphenHe/cloudflare-api-ddns/dev/cf-ddns.sh > /usr/local/bin/cf-ddns.sh && chmod +x /usr/local/bin/cf-ddns.sh
```

### Command

```sh
cf-ddns.sh
    -4|-6 \                    	# specify IPv4 or IPv6
    -a cloudflare-api-token \   # specify Cloudflare API token
    -u user@example.com \       # specify Cloudflare email
    -h host.example.com \       # FQDN of the record you want to update
    -z example.com \            # your domain (zone)
```

### Optional flags

```sh
    -f false(default)|true \             # force DNS update, disregard local stored IP
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
