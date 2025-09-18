package errorx

import (
	"errors"
	"fmt"
	"strings"
)

func New(msg string, args ...interface{}) error {
	// 如果参数不是2的倍数，则不处理参数
	if len(args)%2 != 0 {
		return errors.New(msg)
	}

	return errors.New(GetString(msg, args...))
}

func Wrap(msg string, err error, args ...interface{}) error {
	// 如果参数不是2的倍数，则不处理参数
	if len(args)%2 != 0 {
		return fmt.Errorf("%s. %w", msg, err)
	}

	return fmt.Errorf("%s. %w", GetString(msg, args...), err)
}

func GetString(msg string, args ...interface{}) string {
	var str strings.Builder
	str.WriteString(msg)
	str.WriteString(". ")

	for i := 0; i+1 < len(args); i = i + 2 {
		str.WriteString(fmt.Sprintf("%s=%v", args[i], args[i+1]))

		if i+2 < len(args) {
			str.WriteString(", ")
		} else {
			str.WriteString(".")
		}
	}

	return str.String()
}
