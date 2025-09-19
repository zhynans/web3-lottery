package eth

import (
	"encoding/hex"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"strings"
)

// ContractError 自定义错误类型
type ContractError struct {
	Type    string
	Message string
}

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
	if !strings.Contains(errStr, "execution reverted") && !strings.Contains(errStr, "revert") {
		return nil
	}

	// 尝试获取revert数据
	var revertData []byte
	if rpcErr, ok := err.(interface{ ErrorData() []byte }); ok {
		revertData = rpcErr.ErrorData()
	} else {
		// 如果没有ErrorData方法，尝试从错误信息中提取
		// 这里可以根据具体的RPC错误格式进行调整
		return &ContractError{
			Type:    "Unknown",
			Message: errStr,
		}
	}

	if len(revertData) < 4 {
		return &ContractError{
			Type:    "Unknown",
			Message: errStr,
		}
	}

	// 解析错误选择器
	selector := revertData[:4]

	// 定义错误ABI
	errorABI, err := abi.JSON(strings.NewReader(errorAbi))
	if err != nil {
		return &ContractError{
			Type:    "Unknown",
			Message: errStr,
		}
	}

	// 检查错误类型
	for errorName, errorDef := range errorABI.Errors {
		if strings.EqualFold(hex.EncodeToString(selector), hex.EncodeToString(errorDef.ID[:])) {
			return &ContractError{
				Type:    errorName,
				Message: errStr,
			}
		}
	}

	return &ContractError{
		Type:    "Unknown",
		Message: errStr,
	}
}
