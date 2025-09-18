package main

import "lottery-go/internal/config"

func main() {
	// 加载配置文件
	err := config.LoadAll()
	if err != nil {
		panic(err)
	}

	// 初始化项目
	app, err := initApp()
	if err != nil {
		panic(err)
	}

	app.Run()
}
