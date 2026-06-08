# CentOS7 运维

# 1）查看参数

```bash
# 查看 CPU 参数
lscpu
```

```bash
# 查看 CentOS 版本
cat /etc/centos-release
```

# 2）挂载硬盘

## 查看磁盘

```bash
# 查看所有磁盘
lsblk

# 或查看详细信息
fdisk -l
```

## 分区（可选）

如果磁盘未分区，需要先分区：

```bash
# 进入分区工具（以 /dev/vdb 为例）
fdisk /dev/vdb

# 输入 n 创建新分区
# 输入 p 选择主分区
# 输入 1 选择分区号
# 按回车选择默认起始扇区
# 按回车选择默认结束扇区（使用全部空间）
# 输入 w 保存并退出
```

## 格式化

```bash
# 格式化为 ext4（以 /dev/vdb1 为例）
mkfs.ext4 /dev/vdb1

# 或格式化为 xfs
mkfs.xfs /dev/vdb1
```

## 创建挂载点并挂载

```bash
# 创建挂载目录
mkdir -p /data

# 挂载分区
mount /dev/vdb1 /data

# 验证挂载
df -h
```

## 配置开机自动挂载

```bash
# 获取分区 UUID
blkid /dev/vdb1

# 编辑 fstab
vi /etc/fstab
```

添加以下内容（使用 UUID 更可靠）：

```
UUID=你的分区UUID /data ext4 defaults 0 0
```

或直接使用设备名：

```
/dev/vdb1 /data ext4 defaults 0 0
```

测试配置是否正确：

```bash
mount -a
```

---

# 3）切换到 vault 源

CentOS 7 已经在 2024 年停止维护，官方把 yum 历史版本移到了 vault。

先备份：

```bash
mkdir /etc/yum.repos.d/bak
mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak/
```

然后创建新 repo：

```bash
cat > /etc/yum.repos.d/CentOS-Vault.repo << 'EOF'
[base]
name=CentOS-7 - Base
baseurl=https://vault.centos.org/7.9.2009/os/x86_64/
gpgcheck=0
enabled=1

[updates]
name=CentOS-7 - Updates
baseurl=https://vault.centos.org/7.9.2009/updates/x86_64/
gpgcheck=0
enabled=1

[extras]
name=CentOS-7 - Extras
baseurl=https://vault.centos.org/7.9.2009/extras/x86_64/
gpgcheck=0
enabled=1
EOF
```

然后：

```bash
yum clean all
yum makecache
```

如果成功了，再：

```bash
yum install -y yum-utils
```

# 4）安装并启动 Docker

## 先挂载硬盘后安装 Docker（推荐）

如果服务器有数据盘，建议先挂载硬盘，再将 Docker 数据目录配置到新挂载的磁盘，最后安装 Docker。

### 1. 确保硬盘已挂载

参考「2）挂载硬盘」完成磁盘分区、格式化和挂载。

假设已将磁盘挂载到 `/data` 目录。

### 2. 创建 Docker 数据目录

```bash
mkdir -p /data/docker
```

### 3. 配置 Docker 数据目录

创建 Docker 配置文件：

```bash
mkdir -p /etc/docker
vi /etc/docker/daemon.json
```

添加以下内容：

```json
{
  "data-root": "/data/docker"
}
```

### 4. 安装 Docker

现在可以安装 Docker，数据会自动存储到 `/data/docker`：

---

## 安装 Docker

可以先尝试直接安装。

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

如果失败，再直接换国内 Docker 源。

先删掉 docker 官方 repo：

```bash
rm -f /etc/yum.repos.d/docker-ce.repo
```

然后换阿里云 Docker repo：

```bash
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
```

再：

```bash
yum clean all
yum makecache
```

然后安装：

```bash
yum install -y docker-ce docker-ce-cli containerd.io
```

启动：

```bash
systemctl start docker
systemctl enable docker
```

查看：

```bash
docker --version
```

---

如果阿里云也不行，再直接改 repo 文件：

```bash
vi /etc/yum.repos.d/docker-ce.repo
```

把：

```ini
baseurl=https://download.docker.com/linux/centos/7/$basearch/stable
```

改成：

```ini
baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/7/x86_64/stable
```

然后：

```bash
yum makecache
```

---

## 挂载后 Docker 处理

如果 Docker 已经安装并运行，且需要将 Docker 数据迁移到新挂载的磁盘：

### 1. 停止 Docker

```bash
systemctl stop docker
systemctl stop docker.socket
```

### 2. 迁移 Docker 数据目录

```bash
# 创建新的 Docker 数据目录
mkdir -p /data/docker

# 迁移原有数据（如果 /var/lib/docker 有数据）
rsync -avz /var/lib/docker/ /data/docker/

# 或复制（保留权限）
cp -a /var/lib/docker/. /data/docker/
```

### 3. 配置 Docker 使用新数据目录

编辑 Docker 配置文件：

```bash
vi /etc/docker/daemon.json
```

添加或修改 data-root：

```json
{
  "data-root": "/data/docker"
}
```

### 4. 备份原数据（可选）

```bash
mv /var/lib/docker /var/lib/docker.bak
```

### 5. 启动 Docker

```bash
systemctl start docker
systemctl enable docker

# 验证
docker info | grep "Docker Root Dir"
```

### 6. 验证容器和镜像

```bash
# 查看镜像
docker images

# 查看容器
docker ps -a
```

确认一切正常后，可以删除备份：

```bash
rm -rf /var/lib/docker.bak
```

---

# 5）安装 Git

给云仓库配置公钥：

```bash
ssh-keygen -t ed25519
xclip -sel clip < ~/.ssh/id_ed25519.pub
```

若有子模块，需要先初始化子模块。

```bash
git submodule update --init --recursive
```

# 6）确认网络

1. IP
2. 域名
3. DNS
4. 备案
5. 服务端口
6. 防火墙端口
7. BAS 白名单
8. 证书

```text
/etc
├── nginx
│   ├── conf.d
│   └── ssl
│       ├── cert.pem
│       └── cert.key
```

文件传输可以使用 SCP 或 SFTP。

```bash
scp -r /etc/nginx /data/nginx
```

堡垒机的情况，可以使用 xshell 里的 ”窗口-新建文件传输“

# 7）Docker Compose/Swarm

注意挂载，推荐只读，推荐模板：

```yaml
# =============================================================================
# 公共资源交易管理系统 - Docker Compose 配置（单机模式）
# 说明：本配置假设 JAR 和 dist 已在本地 Windows 编译完成并放在 build 目录
# =============================================================================

name: gdjy

services:
  mysql:
    image: docker.m.daocloud.io/library/mysql:8.0
    container_name: gdjy-mysql
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD:-123456}
      MYSQL_DATABASE: ${MYSQL_DATABASE:-gdjy}
      TZ: Asia/Shanghai
      LANG: C.UTF-8
    volumes:
      - /data/gdjy/mysql:/var/lib/mysql
      - ./backend/db/my.cnf:/etc/mysql/conf.d/my.cnf:ro
      - ./backend/db/init.sql:/docker-entrypoint-initdb.d/01-init.sql:ro
      - /etc/localtime:/etc/localtime:ro
    ports:
      - '${MYSQL_PORT:-3306}:3306'
    healthcheck:
      test:
        [
          'CMD',
          'mysqladmin',
          'ping',
          '-h',
          'localhost',
          '-u',
          'root',
          '-p${MYSQL_ROOT_PASSWORD:-123456}',
        ]
      interval: 10s
      timeout: 10s
      retries: 10
      start_period: 60s
    networks:
      - gdjy-network
    restart: unless-stopped
    command: >
      --default-authentication-plugin=mysql_native_password
      --character-set-server=utf8mb4
      --collation-server=utf8mb4_unicode_ci
      --innodb-buffer-pool-size=4G
      --innodb-log-buffer-size=64M
      --max-connections=500
      --thread-cache-size=100
      --table-open-cache=4000
      --default-time-zone='+08:00'
    mem_limit: 6g
    cpus: 4.0
    ulimits:
      nofile:
        soft: 65536
        hard: 65536

  redis:
    image: docker.m.daocloud.io/library/redis:7-alpine
    container_name: gdjy-redis
    command: >
      --appendonly yes
      --appendfsync everysec
      --maxmemory 512mb
      --maxmemory-policy allkeys-lru
      --tcp-keepalive 60
      --timeout 0
    volumes:
      - /data/gdjy/redis:/data
      - /etc/localtime:/etc/localtime:ro
    ports:
      - '${REDIS_PORT:-6379}:6379'
    healthcheck:
      test: ['CMD', 'redis-cli', 'ping']
      interval: 10s
      timeout: 3s
      retries: 5
    networks:
      - gdjy-network
    restart: unless-stopped
    mem_limit: 2g
    cpus: 1.0
    ulimits:
      nofile:
        soft: 65536
        hard: 65536

  backend:
    build:
      context: .
      dockerfile: backend/Dockerfile
      args:
        JAR_FILE: build/*.jar
    image: gdjy-backend:latest
    container_name: gdjy-backend
    environment:
      SPRING_PROFILES_ACTIVE: ${SPRING_PROFILES_ACTIVE:-prod}
      MYSQL_URL: jdbc:mysql://mysql:3306/${MYSQL_DATABASE:-gdjy}?useUnicode=true&characterEncoding=utf8&useSSL=false&serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true&createDatabaseIfNotExist=true
      MYSQL_USERNAME: root
      MYSQL_PASSWORD: ${MYSQL_ROOT_PASSWORD:-123456}
      REDIS_HOST: redis
      REDIS_PORT: 6379
      SERVER_PORT: 8080
      APP_BACKUP_DIRECTORY: /app/backup
      JAVA_OPTS: >
        -XX:+UseContainerSupport
        -XX:MaxRAMPercentage=80.0
        -XX:InitialRAMPercentage=60.0
        -XX:+UseG1GC
        -XX:MaxGCPauseMillis=200
        -XX:G1HeapRegionSize=16m
        -XX:+ParallelRefProcEnabled
        -XX:+AlwaysPreTouch
        -XX:+DisableExplicitGC
        -Djava.security.egd=file:/dev/./urandom
        -Dfile.encoding=UTF-8
        -Dsun.jnu.encoding=UTF-8
    ports:
      - '${BACKEND_PORT:-8080}:8080'
    depends_on:
      mysql:
        condition: service_healthy
      redis:
        condition: service_healthy
    volumes:
      - /data/gdjy/backend/logs:/app/logs
      - /data/gdjy/backend/uploads:/app/uploads
      - /data/gdjy/backend/caches:/app/caches
      - /data/gdjy/backend/backup:/app/backup
      - /etc/localtime:/etc/localtime:ro
    networks:
      - gdjy-network
    restart: unless-stopped
    user: 'appuser'
    mem_limit: 8g
    cpus: 6.0
    ulimits:
      nofile:
        soft: 65536
        hard: 65536
    healthcheck:
      test:
        [
          'CMD',
          'wget',
          '--quiet',
          '--tries=1',
          '--spider',
          'http://localhost:8080/api/actuator/health',
          '||',
          'exit',
          '1',
        ]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  frontend:
    build:
      context: .
      dockerfile: frontend/Dockerfile
      args:
        DIST_PATH: build/dist
    image: gdjy-frontend:latest
    container_name: gdjy-frontend
    ports:
      - '${FRONTEND_PORT:-80}:80'
      - '${FRONTEND_HTTPS_PORT:-443}:443'
    depends_on:
      - backend
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /etc/nginx/ssl:/etc/nginx/ssl:ro
      - ./frontend/nginx.conf:/etc/nginx/nginx.conf:ro
    networks:
      - gdjy-network
    restart: unless-stopped
    mem_limit: 1g
    cpus: 1.0
    ulimits:
      nofile:
        soft: 65536
        hard: 65536
    healthcheck:
      test:
        [
          'CMD',
          'wget',
          '--quiet',
          '--tries=1',
          '--spider',
          'http://localhost/health',
          '||',
          'exit',
          '1',
        ]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s

networks:
  gdjy-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

---

## 常用运维命令

### Docker 基础命令

```bash
# 查看运行中的容器
docker ps

# 查看所有容器（包括停止的）
docker ps -a

# 查看容器日志
docker logs <容器名或ID>
docker logs -f <容器名或ID>          # 实时跟踪
docker logs --tail 100 <容器名>      # 查看最后100行
docker logs -f --since 10m <容器名>  # 查看最近10分钟日志

# 进入容器内部
docker exec -it <容器名> /bin/bash
docker exec -it <容器名> /bin/sh     # 如果没有bash
docker exec -it -e LANG=C.UTF-8 gdjy-mysql mysql -u root -p123456 gdjy
docker exec gdjy-mysql mysql -uroot -p123456 -e "SHOW DATABASES;"

# 将 SQL 文件复制到容器内
docker cp your_file.sql gdjy-mysql:/tmp/your_file.sql

# 执行 SQL 文件
docker exec gdjy-mysql mysql -uroot -p123456 -e "source /tmp/your_file.sql"

# 通过管道传递 SQL
echo "SHOW DATABASES;" | docker exec -i gdjy-mysql mysql -uroot -p123456

# 在容器内执行命令（不进入交互模式）
docker exec <容器名> ls -la /app

# 启动/停止/重启容器
docker start <容器名>
docker stop <容器名>
docker restart <容器名>

# 删除容器
docker rm <容器名>
docker rm -f <容器名>                # 强制删除运行中的容器

# 查看容器详情
docker inspect <容器名>

# 查看容器资源使用情况
docker stats
docker stats <容器名>

# 复制文件到/从容器
docker cp <本地文件> <容器名>:<容器路径>
docker cp <容器名>:<容器路径> <本地文件>

# 查看容器进程
docker top <容器名>

# 查看镜像列表
docker images

# 删除镜像
docker rmi <镜像名或ID>
docker image prune                    # 清理未使用的镜像

# 清理系统（删除停止的容器、未使用的网络、悬空镜像）
docker system prune
docker system prune -a                # 删除所有未使用的镜像

# 查看磁盘使用情况
docker system df
```

### Docker Compose 命令

```bash
# 启动服务（后台运行）
docker-compose up -d

# 启动特定服务
docker-compose up -d mysql redis

# 停止服务
docker-compose down

# 停止并删除卷（慎用，会删除数据）
docker-compose down -v

# 查看服务状态
docker-compose ps

# 查看服务日志
docker-compose logs
docker-compose logs -f               # 实时跟踪
docker-compose logs -f backend       # 查看特定服务

# 重启服务
docker-compose restart
docker-compose restart backend       # 重启特定服务

# 重新构建并启动
docker-compose up -d --build

# 构建镜像
docker-compose build

# 拉取最新镜像
docker-compose pull

# 查看配置
docker-compose config

# 进入服务容器
docker-compose exec mysql /bin/bash
docker-compose exec backend /bin/sh

# 停止服务（保留容器）
docker-compose stop

# 启动已停止的服务
docker-compose start

# 查看服务依赖关系
docker-compose config --services

# 扩展服务实例数（用于可扩展服务）
docker-compose up -d --scale backend=3
```

### Docker Swarm 命令

```bash
# 初始化 Swarm 集群
docker swarm init
docker swarm init --advertise-addr <IP地址>

# 查看加入令牌
docker swarm join-token manager      # 管理节点令牌
docker swarm join-token worker       # 工作节点令牌

# 工作节点加入集群
docker swarm join --token <TOKEN> <MANAGER-IP>:2377

# 查看节点列表
docker node ls

# 查看节点详情
docker node inspect <节点ID>

# 停用/启用节点
docker node update --availability drain <节点ID>   # 排空节点（不再分配任务）
docker node update --availability active <节点ID>  # 激活节点

# 删除节点
docker node rm <节点ID>

# 提升工作节点为管理节点
docker node promote <节点ID>

# 降级管理节点为工作节点
docker node demote <节点ID>

# 创建服务
docker service create --name myservice --replicas 3 -p 8080:80 nginx

# 查看服务列表
docker service ls

# 查看服务详情
docker service inspect <服务名>
docker service inspect --pretty <服务名>   # 友好格式显示

# 查看服务日志
docker service logs <服务名>
docker service logs -f <服务名>            # 实时跟踪

# 查看服务任务（容器）
docker service ps <服务名>
docker service ps <服务名> --no-trunc      # 显示完整信息

# 扩展/缩减服务
docker service scale <服务名>=5

# 更新服务
docker service update --image nginx:latest <服务名>
docker service update --env-add KEY=value <服务名>
docker service update --publish-add 8443:443 <服务名>

# 滚动更新配置
docker service update --update-parallelism 2 --update-delay 10s <服务名>

# 删除服务
docker service rm <服务名>

# 查看网络列表
docker network ls

# 创建覆盖网络（Swarm 使用）
docker network create --driver overlay <网络名>
docker network create --driver overlay --attachable <网络名>

# 查看 Swarm 集群状态
docker info

# 离开 Swarm 集群
docker swarm leave                    # 工作节点离开
docker swarm leave --force            # 管理节点强制离开

# 锁定 Swarm 集群（安全）
docker swarm update --autolock=true

# 解锁 Swarm 集群
docker swarm unlock

# 查看解锁密钥
docker swarm unlock-key

# 轮换解锁密钥
docker swarm unlock-key --rotate
```

### 故障排查命令

```bash
# 查看容器详细信息和事件
docker inspect <容器名>
docker events

# 查看容器资源限制
docker inspect -f '{{.HostConfig.Memory}}' <容器名>

# 查看容器IP地址
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' <容器名>

# 查看容器退出码
docker inspect -f '{{.State.ExitCode}}' <容器名>

# 查看容器健康检查状态
docker inspect -f '{{.State.Health.Status}}' <容器名>

# 查看 Swarm 服务失败原因
docker service ps <服务名> --no-trunc
docker inspect --format '{{.Status.Err}}' <任务ID>

# 查看节点资源使用情况
docker node inspect <节点ID> --pretty

# 强制重新调度服务
docker service update --force <服务名>

# 清理未使用的卷
docker volume prune

# 查看卷列表
docker volume ls

# 查看卷详情
docker volume inspect <卷名>
```
