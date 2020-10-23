/**
This package will be used as an interface to report events data in device financier. It will send the data to the bd_streamer microservice via NATS.
Bugzilla 107952
Author: Maen Abu Hammour
**/
package ext

import(
	"git.kaiostech.com/cloud/common/mq"
	"git.kaiostech.com/cloud/common/cerrors"
	"git.kaiostech.com/cloud/common/config"
	l4g "git.kaiostech.com/cloud/thirdparty/code.google.com/p/log4go"
	//	"encoding/json"
	"fmt"
)

type T_Event interface {
	Marshal() ([]byte,error) // Object of T_Event will need to implement its own Marshal method.
	GetLayer() string  //from which layer the request has been received FE/LL. This will be used for error reporting.
}

func  Stream(origin_request *mq.MQRequest, event T_Event)(cerr *cerrors.CError){

	
	if config.GetFEConfig().Common.Debug {
		l4g.Debug("req #%s: Stream starts", origin_request.ReqId)
		defer l4g.Debug("req #%s: Stream ends", origin_request.ReqId)
	}

	// Race condition for the 'initialized' variable! Protect to prevent
	// several initializations from happening in parallel.
	mu.Lock()
	if !initialized {
		err:=auto_init(origin_request.ReqId)

		if err!=nil {
			l4g.Error("req #%v: Stream: initialization failed: '%s' ",origin_request.ReqId, err)
			return cerrors.NewErrNo(cerrors.ERROR_INTERNAL_SERVER_ERROR, err.Error(), event.GetLayer(), true,cerrors.ERRNO_EXT_FAILED_TO_INIT)
		}
		initialized=true
	}
	mu.Unlock()

	event_bytes,err := event.Marshal()

	if err!=nil {
		cerr = cerrors.New(cerrors.ERROR_INTERNAL_SERVER_ERROR, fmt.Sprintf("Failed to set request data: '%s'", err.Error()), event.GetLayer(), true)
	}

	request = mq.NewMQRequest("", mq.MQRT_CREATE, mq.MQSCOPE_FIN_BD_STREAM, origin_request.ReqId,nil)
	
	if err = request.SetData(event_bytes); err != nil {

		cerr = cerrors.New(cerrors.ERROR_INVALID_REQUEST, fmt.Sprintf("Failed to set request data: '%s'", err.Error()), event.GetLayer(), true)
		return cerr
	}
	//Send to bd_stream microservice
	cerr = cm.Send(EXT_TO_BD_STREAM, request)
	if cerr!=nil{
		
		return cerr
	}
	return nil
}
