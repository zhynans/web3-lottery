
#### 部署命令
##### 构建镜像
```cgo
$ docker build -f deploy/Dockerfile -t lottery-go:0.0.1 .
```
##### 启动容器
```cgo
$ docker run -d -v /data/lottery-go/logs:/app/logs --name lottery-go lottery-go:0.0.1 --env=test
```