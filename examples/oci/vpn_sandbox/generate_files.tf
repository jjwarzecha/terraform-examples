output "test_command_libreswan" {
  value = <<LIBREINSTALL
#generated with terraform at ${timestamp()}
#installation of libreSWAN
sudo yum -y install libreswan
LIBREINSTALL
}

output "file_sysctl.conf" {
  value = <<SYSCONF
#generated by terraform on ${timestamp()}
#configure sysctl.conf for traffic forwarding
#
# ! please remember to update your interface names if needed !
#
net.ipv4.ip_forward=1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.eth0.send_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.eth0.accept_redirects = 0
SYSCONF
}

output "file_ipsec.conf" {
  value = <<IPSECCONF
#generated with terraform at ${timestamp()}
config setup
    plutoopts="--perpeerlog"
    protostack=auto
    nat_traversal=yes
include /etc/ipsec.d/*.conf
IPSECCONF
}

output "file_ipsec.d_oci_conf" {
  value = <<OCICONF
#configuration of OCI connection
conn oci1
  authby=secret
  auto=start
  pfs=yes
  #remote
  leftid=${data.oci_core_ipsec_config.vcn_vpn_ipsec_data.tunnels.0.ip_address}              #OCI DRG IPSec Public IP
  left=${data.oci_core_ipsec_config.vcn_vpn_ipsec_data.tunnels.0.ip_address}                #OCI DRG IPSec Public IP
  leftsubnets=${var.vcn_vpn_cidr_block}       #OCI VCN CIDR
  #local
  right=${var.cpe_ip_address}                   #on Premises Libreswan network
  rightid=${var.cpe_ip_address}     #AWS Libreswan Public IP address
  rightsubnet=${var.vcn_vpn_on_premises_cidr_block}           #on Premises CIDR
OCICONF
}

output "file_ipsec.secrets" {
  value = <<IPSECRETS
#generated with terraform at ${timestamp()}
#configuration syntax
#OCI_DRG-Public-IP-IPSEC-Tunel1  onPrem LibreSWAN-PublicIP   :   PSK    "DRG Secret Key"

#main tunnel
#created at ${data.oci_core_ipsec_config.vcn_vpn_ipsec_data.tunnels.0.time_created}
${data.oci_core_ipsec_config.vcn_vpn_ipsec_data.tunnels.0.ip_address}   ${var.cpe_ip_address} : PSK  "${data.oci_core_ipsec_config.vcn_vpn_ipsec_data.tunnels.0.shared_secret}"

#redundant tunnel
#created at ${data.oci_core_ipsec_config.vcn_vpn_ipsec_data.tunnels.1.time_created}
#${data.oci_core_ipsec_config.vcn_vpn_ipsec_data.tunnels.1.ip_address}   ${var.cpe_ip_address} : PSK  "${data.oci_core_ipsec_config.vcn_vpn_ipsec_data.tunnels.1.shared_secret}"
IPSECRETS
}

output "test_command_ipsec" {
  value = <<TESTCOMMAND
#generated with terraform at ${timestamp()}
sudo ipsec auto --status |grep "==="
TESTCOMMAND
}

output "network_iptables" {
  value = <<NATIPTABLE
#generated with terraform at ${timestamp()}
# enp0s3 - external interface (eth0)
# 10.20.0.0/16 - local networks
iptables -A FORWARD -o enp0s3 -j ACCEPT
iptables -t nat -A POSTROUTING -s 10.20.0.0/16 -o enp0s3 -m policy --dir out --pol none -j MASQUERADE
NATIPTABLE
}