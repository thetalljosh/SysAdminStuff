list_of_ips = []

import ipaddress

# Group the IP addresses into /24 networks
networks = {}
for ip in list_of_ips:
    #adjust the / subnet mask in the network = line below to adjust IP grouping
    network = ipaddress.ip_network(ip + '/16', strict=False)
    if network not in networks:
        networks[network] = []
    networks[network].append(ip)

# Print the networks and the IP addresses in each network
for network, ips in networks.items():
    print(f"{network} contains {len(ips)} IP addresses")    
    #for ip in ips:
    #   print('  ' + ip)
