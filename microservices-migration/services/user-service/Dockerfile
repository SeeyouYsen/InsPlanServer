# 使用 Swift 官方镜像作为构建阶段
FROM swift:6.0-jammy AS build

# 设置工作目录
WORKDIR /build

# 复制 Package 文件
COPY Package.swift Package.resolved ./

# 解析依赖
RUN swift package resolve

# 复制源代码
COPY Sources ./Sources

# 编译应用
RUN swift build --configuration release

# 使用更小的运行时镜像
FROM swift:6.0-jammy-slim

# 安装运行时依赖
RUN apt-get update && apt-get install -y \
    libssl3 \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

# 创建应用用户
RUN useradd --user-group --create-home --system --skel /dev/null --home-dir /app swift

# 切换到应用目录
WORKDIR /app

# 从构建阶段复制可执行文件
COPY --from=build --chown=swift:swift /build/.build/release/UserService /app/

# 切换到应用用户
USER swift:swift

# 设置可执行权限
RUN chmod +x /app/UserService

# 暴露端口
EXPOSE 8081

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8081/health || exit 1

# 启动应用
ENTRYPOINT ["./UserService"]
