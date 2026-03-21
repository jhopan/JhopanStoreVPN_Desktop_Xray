package xray

import (
	"encoding/json"
	"fmt"
	"runtime"
	"strconv"
	"strings"

	"jhovpn/core/vless"
)

func GenerateConfig(vc vless.Config, dns1, dns2 string, allowInsecure bool) ([]byte, error) {
	if dns1 == "" {
		dns1 = "8.8.8.8"
	}
	if dns2 == "" {
		dns2 = "8.8.4.4"
	}

	domain, portStr, err := vless.SplitAddress(vc.Address)
	if err != nil {
		return nil, err
	}
	port, err := strconv.Atoi(portStr)
	if err != nil {
		return nil, fmt.Errorf("invalid port: %s", portStr)
	}

	isCloudflareWorkers := false
	workersDomains := []string{".workers.dev", ".pages.dev"}
	checkStrings := []string{vc.Host, vc.SNI}
	for _, s := range checkStrings {
		if s == "" {
			continue
		}
		sLower := strings.ToLower(s)
		for _, d := range workersDomains {
			if strings.HasSuffix(sLower, d) {
				isCloudflareWorkers = true
				break
			}
		}
	}

	wsHost := vc.Host
	if wsHost == "" {
		wsHost = vc.SNI
	}
	if wsHost == "" {
		wsHost = domain
	}

	serverName := vc.SNI
	if serverName == "" {
		serverName = domain
	}

	var parsedDNS1, parsedDNS2 string
	if isCloudflareWorkers {
		parsedDNS1 = "tcp://" + dns1
		parsedDNS2 = "tcp://" + dns2
	} else {
		parsedDNS1 = dns1
		parsedDNS2 = dns2
	}

	config := map[string]interface{}{
		"log": map[string]interface{}{
			"loglevel": "none",
		},
		"policy": map[string]interface{}{
			"system": map[string]interface{}{
				"statsInboundUplink":    false,
				"statsInboundDownlink":  false,
				"statsOutboundUplink":   false,
				"statsOutboundDownlink": false,
			},
		},
		"dns": map[string]interface{}{
			"servers":       []string{parsedDNS1, parsedDNS2},
			"queryStrategy": "UseIPv4",
		},
		"inbounds": []map[string]interface{}{
			{
				"tag":      "tun-in",
				"port":     10809,
				"protocol": "tun",
				"settings": tunSettings(),
			},
			{
				"tag":      "socks-in",
				"port":     10808,
				"listen":   "127.0.0.1",
				"protocol": "socks",
				"settings": map[string]interface{}{
					"udp": true,
				},
			},
		},
	}

	outbounds := []map[string]interface{}{
		{
			"tag":      "proxy",
			"protocol": "vless",
			"settings": map[string]interface{}{
				"vnext": []map[string]interface{}{
					{
						"address": domain,
						"port":    port,
						"users": []map[string]interface{}{
							{
								"id":         vc.UUID,
								"encryption": "none",
							},
						},
					},
				},
			},
			"streamSettings": map[string]interface{}{
				"network":  "ws",
				"security": "tls",
				"tlsSettings": map[string]interface{}{
					"serverName":    serverName,
					"allowInsecure": allowInsecure,
				},
				"wsSettings": map[string]interface{}{
					"path": vc.Path,
					"headers": map[string]interface{}{
						"Host": wsHost,
					},
				},
			},
		},
		{
			"tag":      "direct",
			"protocol": "freedom",
			"settings": map[string]interface{}{
				"domainStrategy": "UseIPv4",
			},
		},
		{
			"tag":      "dns-out",
			"protocol": "dns",
		},
	}
	config["outbounds"] = outbounds

	routingRules := []map[string]interface{}{}
	// Always handle DNS requests explicitly for better compatibility.
	routingRules = append(routingRules, map[string]interface{}{
		"type":        "field",
		"inboundTag":  []string{"socks-in", "tun-in"},
		"port":        "53",
		"outboundTag": "dns-out",
	})

	if !isCloudflareWorkers {
		routingRules = append(routingRules, map[string]interface{}{
			"type": "field",
			"ip": []string{
				"10.0.0.0/8",
				"172.16.0.0/12",
				"192.168.0.0/16",
				"127.0.0.0/8",
			},
			"outboundTag": "direct",
		})
	}

	config["routing"] = map[string]interface{}{
		"domainStrategy": "AsIs",
		"rules":          routingRules,
	}

	data, err := json.MarshalIndent(config, "", "  ")
	if err != nil {
		return nil, fmt.Errorf("failed to marshal config: %w", err)
	}
	return data, nil
}

func tunSettings() map[string]interface{} {
	settings := map[string]interface{}{
		"mtu":                    1500,
		"stack":                  "system",
		"autoRoute":              true,
		"strictRoute":            false,
		"endpointIndependentNat": true,
		"sniffing":               true,
		"inet4Address":           []string{"172.19.0.1/30"},
		"inet6Address":           []string{"fdfe:dcba:9876::1/126"},
	}

	// Keep adapter naming explicit on Windows for stable interface handling.
	switch runtime.GOOS {
	case "windows":
		settings["name"] = "JhopanVPN"
	case "linux":
		// Explicit interface name simplifies policy/routing debugging on Linux.
		settings["name"] = "jhopan0"
	case "darwin":
		// macOS usually manages utun naming automatically.
	}

	if runtime.GOOS == "linux" {
		settings["strictRoute"] = true
	}

	return settings
}
