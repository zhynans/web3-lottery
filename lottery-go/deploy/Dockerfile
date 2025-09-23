FROM golang:1.24.7 AS builder

# 为我们的镜像设置必要的环境变量
ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    GOPROXY=https://goproxy.cn,direct \
    GOOS=linux \
    GOARCH=amd64

# 移动到工作目录：/build
WORKDIR /build

# 将代码复制到容器中
COPY . .

# 将我们的代码编译成二进制可执行文件app
RUN go build -o lottery-go cmd/main.go cmd/wire_gen.go

FROM alpine:3.21.4
# 修改镜像源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories 

# 上海时区
ENV TZ=Asia/Shanghai
RUN apk update \
    && apk add tzdata \
    && echo "${TZ}" > /etc/timezone \
    && ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
    && rm /var/cache/apk/*

# 从builder镜像中把/build 拷贝到当前目录
COPY --from=builder /build/lottery-go /app/
COPY --from=builder /build/configs /app/configs/

WORKDIR /app

# 启动容器时运行的命令
ENTRYPOINT ["./lottery-go"]
CMD ["--env=test"]
