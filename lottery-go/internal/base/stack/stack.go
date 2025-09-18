package stack

import (
	"fmt"
	"runtime"
	"strings"
)

// GetStackTrace 建议skip>=2，跳过 Callers 和 GetStackTrace 本身，因为0=runtime.Callers, 1=printStack
func GetStackTrace(skip int) string {
	pcs := make([]uintptr, 20)      // 最多20层堆栈
	n := runtime.Callers(skip, pcs) // skip=2: 跳过 Callers 和 GetStackTrace 本身
	pcs = pcs[:n]

	frames := runtime.CallersFrames(pcs)
	var builder strings.Builder

	for {
		frame, more := frames.Next()

		builder.WriteString(fmt.Sprintf("%s\n\t%s:%d\n", frame.Function, frame.File, frame.Line))
		if !more {
			break
		}
	}

	return builder.String()
}
