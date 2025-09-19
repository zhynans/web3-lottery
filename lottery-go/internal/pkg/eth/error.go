package eth

import (
	"bytes"
	"encoding/hex"
	"strings"

	"github.com/ethereum/go-ethereum/accounts/abi"
)

// ContractError 自定义错误类型
type ContractError struct {
	Type    string
	Message string
}

// 常量定义
const (
	// 最小选择器长度（4字节）
	minSelectorLength = 4
	// 最小十六进制字符串长度（0x + 8个字符 = 10个字符）
	minHexStringLength = 10
	// 错误类型
	unknownErrorType = "Unknown"
)

// Error 实现error接口
func (e *ContractError) Error() string {
	return e.Message
}

// ParseContractError 解析合约返回的错误信息
func ParseContractError(errorAbi string, err error) *ContractError {
	if err == nil {
		return nil
	}

	errStr := err.Error()
	if !isRevertError(errStr) {
		return nil
	}

	// 解析错误ABI
	errorABI, parseErr := abi.JSON(strings.NewReader(errorAbi))
	if parseErr != nil {
		return newUnknownContractError(errStr)
	}

	// 尝试获取revert数据
	revertData := extractFromWrappedError(err)
	if len(revertData) < minSelectorLength {
		return newUnknownContractError(errStr)
	}

	// 匹配错误类型
	selector := revertData[:4]
	if errorName := matchErrorType(selector, errorABI.Errors); errorName != "" {
		return &ContractError{
			Type:    errorName,
			Message: errStr,
		}
	}

	return newUnknownContractError(errStr)
}

// isRevertError 检查是否为revert错误
func isRevertError(errStr string) bool {
	return strings.Contains(errStr, "execution reverted") ||
		strings.Contains(errStr, "revert")
}

// newUnknownContractError 创建未知错误
func newUnknownContractError(message string) *ContractError {
	return &ContractError{
		Type:    unknownErrorType,
		Message: message,
	}
}

// extractFromWrappedError 从包装错误中提取数据
func extractFromWrappedError(err error) []byte {
	if wrapErr, ok := err.(interface{ Unwrap() error }); ok {
		wrappedErr := wrapErr.Unwrap()
		if rpcErr, ok := wrappedErr.(interface{ ErrorData() interface{} }); ok {
			// 尝试转换为字符串
			if str, ok := rpcErr.ErrorData().(string); ok && str != "" {
				return parseHexString(str)
			}
		}
	}
	return nil
}

// matchErrorType 匹配错误类型
func matchErrorType(selector []byte, errors map[string]abi.Error) string {
	for errorName, errorDef := range errors {
		// 检查选择器是否匹配（前4字节）
		if len(selector) >= minSelectorLength {
			if bytes.Equal(selector, errorDef.ID[:minSelectorLength]) {
				return errorName
			}
		}

		// 检查完整的十六进制字符串匹配
		if strings.EqualFold(hex.EncodeToString(selector), hex.EncodeToString(errorDef.ID[:])) {
			return errorName
		}
	}
	return ""
}

// parseHexString 解析十六进制字符串
func parseHexString(str string) []byte {
	// 尝试解析带0x前缀的字符串
	if strings.HasPrefix(str, "0x") {
		data, err := hex.DecodeString(str[2:])
		if err == nil && len(data) >= minSelectorLength {
			return data
		}
		return nil
	}

	// 尝试解析不带0x前缀的字符串
	data, err := hex.DecodeString(str)
	if err == nil && len(data) >= minSelectorLength {
		return data
	}

	return nil
}
