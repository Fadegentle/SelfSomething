#!/bin/sh

# 获取IP客户端列表的脚本
# 需要在ASUS路由器上运行，需要root权限

# 输出文件
OUTPUT_FILE="/tmp/ip_client_list.txt"
# 临时文件用于排序和合并
TEMP_FILE="/tmp/ip_temp.txt"

# 清空输出文件
> $OUTPUT_FILE
> $TEMP_FILE

# 获取IPv6邻居发现缓存并按MAC地址排序
echo "正在收集IP客户端信息..."
ip -6 neigh show | sort -k5 | while read line; do
    IPV6_ADDR=$(echo $line | awk '{print $1}')
    MAC_ADDR=$(echo $line | awk '{print $5}')
    STATE=$(echo $line | awk '{print $NF}')

    # 将MAC地址、IPv6地址和状态写入临时文件
    echo "6|$MAC_ADDR|$IPV6_ADDR|$STATE" >> $TEMP_FILE
done

# 获取IPv4邻居缓存并按MAC地址排序
# 使用grep过滤只保留IPv4格式的地址
ip neigh show | grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}' | sort -k3 | while read line; do
    IPV4_ADDR=$(echo $line | awk '{print $1}')
    MAC_ADDR=$(echo $line | awk '{print $5}')
    STATE=$(echo $line | awk '{print $NF}')

    # 将MAC地址、IPv4地址和状态写入临时文件
    echo "4|$MAC_ADDR|$IPV4_ADDR|$STATE" >> $TEMP_FILE
done

# 按MAC地址排序临时文件
sort -t'|' -k2 $TEMP_FILE > "${TEMP_FILE}.sorted"
mv "${TEMP_FILE}.sorted" $TEMP_FILE

# 处理临时文件，合并相同MAC地址的条目
current_mac=""
while IFS='|' read -r ipver mac ip state; do
    if [ "$current_mac" != "$mac" ]; then
        # 如果是新的MAC地址，输出设备信息头部
        if [ ! -z "$current_mac" ]; then
            echo "----------------------------------------" >> $OUTPUT_FILE
        fi
        # 尝试从dnsmasq获取主机名
        HOSTNAME=$(grep -i $mac /var/lib/misc/dnsmasq.leases | awk '{print $4}')
        # 如果没有找到主机名，使用"Unknown"
        if [ -z "$HOSTNAME" ]; then
            HOSTNAME="Unknown"
        fi

        echo "设备名称: $HOSTNAME" >> $OUTPUT_FILE
        echo "MAC地址: $mac" >> $OUTPUT_FILE
        current_mac=$mac
    fi

    # 根据IP版本输出不同格式
    if [ "$ipver" = "4" ]; then
        echo "IPv4地址 ($state): $ip" >> $OUTPUT_FILE
    else
        echo "IPv6地址 ($state): $ip" >> $OUTPUT_FILE
    fi
done < $TEMP_FILE

# 添加最后一个分隔线
echo "----------------------------------------" >> $OUTPUT_FILE

# 清理临时文件
rm -f $TEMP_FILE

# 显示结果
echo "IP客户端列表已生成到: $OUTPUT_FILE"
cat $OUTPUT_FILE