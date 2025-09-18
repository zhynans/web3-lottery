package logx

import (
	"fmt"
)

func Default() ILogger {
	return defaultLogger
}

func WithModule(module string) ILogger {
	return defaultLogger.WithModule(module)
}

func Debug(message string, args ...interface{}) {
	defaultLogger.Debug(message, args...)
}

func Info(message string, args ...interface{}) {
	defaultLogger.Info(message, args...)
}

func Warn(message string, args ...interface{}) {
	defaultLogger.Warn(message, args...)
}

func Error(message string, args ...interface{}) {
	defaultLogger.Error(message, args...)
}

func DebugF(format string, args ...interface{}) {
	defaultLogger.Debug(fmt.Sprintf(format, args...))
}

func InfoF(format string, args ...interface{}) {
	defaultLogger.Info(fmt.Sprintf(format, args...))
}

func WarnF(format string, args ...interface{}) {
	defaultLogger.Warn(fmt.Sprintf(format, args...))
}

func ErrorF(format string, args ...interface{}) {
	defaultLogger.Error(fmt.Sprintf(format, args...))
}
