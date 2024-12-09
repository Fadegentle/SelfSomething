#!/bin/bash

# 配置信息
SMTP_SERVER="smtp.qq.com"
SMTP_PORT="465"
SMTP_USER="1104647683@qq.com"
SMTP_PASS="QQ邮箱生成授权码"
TO_EMAIL="fudongcheng110@qq.com"
FROM_EMAIL="1104647683@qq.com"
SUBJECT="路由器IP变更通知"

# 存储上次IP的文件
LAST_IP_FILE="/tmp/last_ip_status"
TEMP_IP_FILE="/tmp/current_ip_status"
IP_LIST_FILE="/tmp/ip_monitor_list"

# 首先生成IP列表
# 获取IP客户端列表的脚本部分
> $IP_LIST_FILE

# 获取IPv6邻居发现缓存并按MAC地址排序
ip -6 neigh show | sort -k5 | while read line; do
    IPV6_ADDR=$(echo $line | awk '{print $1}')
    MAC_ADDR=$(echo $line | awk '{print $5}')
    STATE=$(echo $line | awk '{print $NF}')
    echo "6|$MAC_ADDR|$IPV6_ADDR|$STATE" >> "${IP_LIST_FILE}.temp"
done

# 获取IPv4邻居缓存并按MAC地址排序
ip neigh show | grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}' | sort -k3 | while read line; do
    IPV4_ADDR=$(echo $line | awk '{print $1}')
    MAC_ADDR=$(echo $line | awk '{print $5}')
    STATE=$(echo $line | awk '{print $NF}')
    echo "4|$MAC_ADDR|$IPV4_ADDR|$STATE" >> "${IP_LIST_FILE}.temp"
done

# 按MAC地址排序并处理
sort -t'|' -k2 "${IP_LIST_FILE}.temp" | awk -F'|' '
BEGIN {
    current_mac = ""
}
{
    if (current_mac != $2) {
        if (current_mac != "") {
            print "----------------------------------------"
        }
        # 尝试获取主机名（在实际环境中需要调整）
        "grep -i " $2 " /var/lib/misc/dnsmasq.leases | awk \047{print $4}\047" | getline hostname
        if (hostname == "") hostname = "Unknown"

        print "设备名称: " hostname
        print "MAC地址: " $2
        current_mac = $2
    }

    if ($1 == "4") {
        print "IPv4地址 (" $4 "): " $3
    } else {
        print "IPv6地址 (" $4 "): " $3
    }
}
END {
    print "----------------------------------------"
}' > $IP_LIST_FILE

rm -f "${IP_LIST_FILE}.temp"

# 获取当前IP信息
CURRENT_IP=$(ip -6 addr show scope global | grep -v deprecated | awk '/inet6/{print $2}' | cut -d'/' -f1 | tail -1)
CURRENT_IPV4=$(ip -4 addr show scope global | awk '/inet/{print $2}' | cut -d'/' -f1 | tail -1)

# 保存当前IP到临时文件
echo "IPv6:${CURRENT_IP}" > "${TEMP_IP_FILE}"
echo "IPv4:${CURRENT_IPV4}" >> "${TEMP_IP_FILE}"

# 检查是否需要发送邮件
if [ ! -f "${LAST_IP_FILE}" ] || ! cmp -s "${LAST_IP_FILE}" "${TEMP_IP_FILE}"; then
    # 读取设备列表
    if [ -f "$IP_LIST_FILE" ]; then
        IP_LIST=$(cat "$IP_LIST_FILE")
    else
        IP_LIST="无设备信息"
    fi

    # 构建邮件正文
    BODY="=== 路由器网络信息 ===
路由器IPv6: ${CURRENT_IP}
路由器IPv4: ${CURRENT_IPV4}

=== 连接设备信息 ===
${IP_LIST}
==================="

    # 使用openssl生成base64编码
    USER_BASE64=$(echo -n "${SMTP_USER}" | openssl enc -base64)
    PASS_BASE64=$(echo -n "${SMTP_PASS}" | openssl enc -base64)

    # 创建邮件内容
    MAIL_CONTENT="From: ${FROM_EMAIL}
To: ${TO_EMAIL}
Subject: ${SUBJECT}
Content-Type: text/plain; charset=utf-8

${BODY}"

    # 使用openssl发送邮件
    (
        printf "EHLO localhost\r\n"
        sleep 1
        printf "AUTH LOGIN\r\n"
        sleep 1
        printf "%s\r\n" "${USER_BASE64}"
        sleep 1
        printf "%s\r\n" "${PASS_BASE64}"
        sleep 1
        printf "MAIL FROM:<%s>\r\n" "${FROM_EMAIL}"
        sleep 1
        printf "RCPT TO:<%s>\r\n" "${TO_EMAIL}"
        sleep 1
        printf "DATA\r\n"
        sleep 1
        printf "%s\r\n" "${MAIL_CONTENT}"
        printf ".\r\n"
        sleep 1
        printf "QUIT\r\n"
    ) | openssl s_client -connect ${SMTP_SERVER}:${SMTP_PORT} -quiet 2>/dev/null

    # 更新上次的IP记录
    cp "${TEMP_IP_FILE}" "${LAST_IP_FILE}"
fi

# 清理临时文件
rm -f "${TEMP_IP_FILE}"