package logx

import (
	"fmt"
	"gopkg.in/natefinch/lumberjack.v2"
	"io"
	"log/slog"
	"os"
)

type Slog struct {
	slog *slog.Logger
}

func NewLogger(conf *LoggerCfg) ILogger {
	ljWriter := &lumberjack.Logger{
		Filename: conf.FilePath,
		MaxSize:  50, // 单个文件最大10MB
		MaxAge:   7,  // 保存7天
		Compress: false,
	}

	writer := io.MultiWriter(ljWriter, os.Stdout) // 文件 + 控制台输出

	handler := slog.NewTextHandler(writer, &slog.HandlerOptions{Level: getSlogLevel(conf.Level)})
	log := slog.New(handler)
	return &Slog{slog: log}
}

// 设置日志等级
func getSlogLevel(setLevel string) *slog.LevelVar {
	level := new(slog.LevelVar)
	switch setLevel {
	case "info":
		level.Set(slog.LevelInfo)
	case "debug":
		level.Set(slog.LevelDebug)
	case "warning":
		level.Set(slog.LevelWarn)
	case "error":
		level.Set(slog.LevelError)
	}
	return level
}

func (s *Slog) WithModule(module string) ILogger {
	return &Slog{slog: s.slog.With("module", module)}
}

func (s *Slog) Debug(message string, args ...interface{}) {
	s.slog.Debug(message, args...)
}

func (s *Slog) Info(message string, args ...interface{}) {
	s.slog.Info(message, args...)
}

func (s *Slog) Warn(message string, args ...interface{}) {
	s.slog.Warn(message, args...)
}

func (s *Slog) Error(message string, args ...interface{}) {
	s.slog.Error(message, args...)
}

func (s *Slog) DebugF(format string, args ...interface{}) {
	s.slog.Debug(fmt.Sprintf(format, args...))
}

func (s *Slog) InfoF(format string, args ...interface{}) {
	s.slog.Info(fmt.Sprintf(format, args...))
}

func (s *Slog) WarnF(format string, args ...interface{}) {
	s.slog.Warn(fmt.Sprintf(format, args...))
}

func (s *Slog) ErrorF(format string, args ...interface{}) {
	s.slog.Error(fmt.Sprintf(format, args...))
}
