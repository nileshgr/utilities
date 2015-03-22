#include <stdio.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <arpa/inet.h>

int main(int argc, char **argv) {
	if(argc < 4) {
		fprintf(stderr, "Execute command as:\n%s <network id> <subnet mask> <ip to be checked>\n", argv[0]);
		return 1;
	}

	struct in_addr netid;
	struct in_addr subnet_mask;
	struct in_addr ip;

	if(!inet_aton(argv[1], &netid)) {
		fprintf(stderr, "Unable to parse network ID\n");
		return 1;
	}

	if(!inet_aton(argv[2], &subnet_mask)) {
		fprintf(stderr, "Unable to parse subnet mask\n");
		return 1;
	}

	if(!inet_aton(argv[3], &ip)) {
		fprintf(stderr, "Unable to parse ip address to be checked\n");
	}

	uint32_t bin_netid, bin_subnet, bin_ip;

	bin_netid = ntohl(netid.s_addr);
	bin_subnet = ntohl(subnet_mask.s_addr);
	bin_ip = ntohl(ip.s_addr);

	if(bin_netid == (bin_ip & bin_subnet)) {
		printf("%s is in range of %s/%s\n", argv[3], argv[1], argv[2]);
		return 0;
	} else {
		printf("%s is not in range of %s/%s\n", argv[3], argv[1], argv[2]);
		return 1;
	}
}
