#!/usr/bin/env bash

######################################
# Created by Pool4U for YiiMP use... #
######################################

source /etc/functions.sh
source /etc/yiimpserver.conf

echo -e "$CYAN Boosting server performance for YiiMP...$COL_RESET"
# Boost Network Performance by Enabling TCP BBR
sudo apt install -y --install-recommends linux-generic-hwe-16.04
echo 'net.core.default_qdisc=fq' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv4.tcp_congestion_control=bbr' | sudo tee -a /etc/sysctl.conf

# Tune Network Stack
echo 'net.core.wmem_max=12582912' | sudo tee -a /etc/sysctl.conf
echo 'net.core.rmem_max=12582912' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv4.tcp_rmem= 10240 87380 12582912' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv4.tcp_wmem= 10240 87380 12582912' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv4.tcp_window_scaling = 1' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv4.tcp_timestamps = 1' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv4.tcp_sack = 1' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv4.tcp_no_metrics_save = 1' | sudo tee -a /etc/sysctl.conf
echo 'net.core.netdev_max_backlog = 5000' | sudo tee -a /etc/sysctl.conf
echo -e "$GREEN Tuning completed...$COL_RESET"
cd $HOME/yiimpserver/yiimp_single
