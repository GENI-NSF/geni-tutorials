# This script is to generate ospfd.conf for each VMs running xorp
BEGIN {
	iface_index = 0
	ip_index = 0
	count = 0
	date = ARGV[2]
	prefix = ARGV[3]
	ARGV[2] = ""
	ARGV[3] = ""
	small = 255
}
{

	if ( NR == 1) {
		hostname = $0
		#print hostname
	}
	else {
		if ($1 ~ /eth/ && $1 != "eth0" ) {
			#getline; 
			#print $1;
			iface_list[iface_index] = $1;
			getline;
			split($2, ip, ":")
			#print ip[2]
			ip_list[ip_index] = ip[2];
			count ++;
			iface_index++
			ip_index++
		}

	}
    
	
} END {

    for (i=0; i<count; i++) {
		split(ip_list[i], a, ".")
		if ( a[3] <= small ) {
			small = a[3]
		}
	}
	#print small
	for (i=0; i<count;i++) {
		split(ip_list[i], a, ".")
		if ( a[3] == small) {
			#print ip_list[i]
			router_id = ip_list[i]
			break
		}
	}

	# print header
	printf("/* OSPF configuration file for XORP \n *\n")
    printf(" * Host: %s\n * DATE: %s\n * \n */\n\n", hostname, date)
	
	# print interface information
	printf("interfaces {\n  restore-original-config-on-shutdown: false\n")
	for (i = 0; i < count; i++) {
		#printf("iface: %s ip: %s\n", iface_list[i], ip_list[i]);
		printf("  interface %s { \n", iface_list[i])
		printf("    description: \"%s-%s\"\n", "virtual interface", iface_list[i])
		printf("    disable: false\n    discard: false\n")
		printf("    vif %s {\n", iface_list[i])
		printf("        disable: false\n        address %s {\n", ip_list[i])
		printf("\t\t prefix-length: %s\n \t\t disable: false\n  \t}\n    }  \n  }\n", prefix)		

	}
	printf("}\n\n\n")

	# print fea configuration
	printf("fea {\n    unicast-forwarding4 {\n        disable: false\n    }\n}\n\n\n")

	# print protocol configuration
	printf("protocols {\n")
	printf("    ospf4 {\n")
	printf("        router-id: %s\n        area 0.0.0.0 {\n", router_id)
	printf("	    area-type:\"normal\"\n")
	for (i = 0; i < count; i++) {
		printf("	    interface %s {\n", iface_list[i])
		printf("	        vif %s {\n", iface_list[i])
		printf("	          address %s {\n", ip_list[i])
		printf("	            interface-cost 10\n")
		printf("	            hello-interval 5\n")
		printf("	            router-dead-interval 10\n")
		printf("	            disable: false\n")
		printf("	          }\n")
		printf("	        }\n")
		printf("	    }\n")



	}
	printf("	}\n")
	printf("    }\n")
	printf("}\n")
}
