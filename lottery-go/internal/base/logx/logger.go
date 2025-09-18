package logx

type ILogger interface {
	WithModule(module string) ILogger

	// Debug 示例：logger.Debug("hello, world", "user", os.Getenv("USER"))
	Debug(message string, args ...interface{})
	Info(message string, args ...interface{})
	Warn(message string, args ...interface{})
	Error(message string, args ...interface{})

	DebugF(format string, args ...interface{})
	InfoF(format string, args ...interface{})
	WarnF(format string, args ...interface{})
	ErrorF(format string, args ...interface{})
}
