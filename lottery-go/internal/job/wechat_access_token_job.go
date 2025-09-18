package job

//
//import (
//	"bootcamp-web/internal/biz/platform"
//	"bootcamp-web/internal/common/logger"
//)
//
//type WechatAccessTokenJob struct {
//	wechatService *platform.WechatService
//}
//
//func NewWechatAccessTokenJob(wechatService *platform.WechatService) *WechatAccessTokenJob {
//	return &WechatAccessTokenJob{wechatService: wechatService}
//}
//
//func (j WechatAccessTokenJob) Run() {
//	token, err := j.wechatService.CheckAccessToken()
//	if err != nil {
//		logger.ErrorF("Check access token err: %v", err)
//	}
//
//	if token == "" {
//		//logger.InfoF("Check access token, it's not expired")
//	} else {
//		logger.InfoF("Check access token. new token: %s", token)
//	}
//}
