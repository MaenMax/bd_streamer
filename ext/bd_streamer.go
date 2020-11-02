/**
This package will be used as an interface to report events data in device financier. It will send the data to the bd_streamer microservice via NATS.
Bugzilla 107952
Author: Maen Abu Hammour
**/
package ext

import (
	"encoding/json"
	"fmt"

	"git.kaiostech.com/cloud/common/cerrors"
	"git.kaiostech.com/cloud/common/config"
	"git.kaiostech.com/cloud/common/model/financier"
	"git.kaiostech.com/cloud/common/mq"
	l4g "git.kaiostech.com/cloud/thirdparty/code.google.com/p/log4go"
)

type T_Event interface {
	Marshal() ([]byte, error) // Object of T_Event will need to implement its own Marshal method.
}

//The concrete event object. Any future changes on the event content must be updated here.
type T_DFP_Event struct {
	EventName    string
	ResponseCode int
	ResponseBody []byte
	DeviceInfo   *financier.T_Device
}

// The Event concrete type must implement the T_Event Interface's Marshal() method. The implementation of this method needs in consistent with the Event structure.
func (e T_DFP_Event) Marshal() ([]byte, error) {
	event_bytes, err := json.Marshal(e)
	if err != nil {
		return nil, err
	}
	return event_bytes, nil
}

// A global function used to stream events from FE/LL subcomponents of device financier backend (kc_fin_fe_fe, kc_fin_fe_ll, kc_fin_be_fe, kc_fin_be_ll)
func Stream(origin_request *mq.MQRequest, event T_Event, event_id string) (cerr *cerrors.CError) {
	if config.GetFEConfig().Common.Debug {
		l4g.Debug("req #%s: Stream starts", origin_request.ReqId)
		defer l4g.Debug("req #%s: Stream ends", origin_request.ReqId)
	}
	// Race condition for the 'initialized' variable! Protect to prevent
	// several initializations from happening in parallel.
	mu.Lock()
	if !initialized {
		err := auto_init(origin_request.ReqId)
		if err != nil {
			l4g.Error("req #%v: Stream: initialization failed: '%s' ", origin_request.ReqId, err)
			return cerrors.NewErrNo(cerrors.ERROR_INTERNAL_SERVER_ERROR, err.Error(), "", true, cerrors.ERRNO_EXT_FAILED_TO_INIT)
		}
		initialized = true
	}
	mu.Unlock()
	event_bytes, err := event.Marshal()
	if err != nil {
		cerr = cerrors.New(cerrors.ERROR_INTERNAL_SERVER_ERROR, fmt.Sprintf("Failed to set request data: '%s'", err.Error()), "bd_streamer.Stream", true)
	}
	request := mq.NewMQRequest(event_id, mq.MQRT_CREATE, mq.MQSCOPE_FIN_BD_STREAM, origin_request.ReqId, nil)
	if err = request.SetData(event_bytes); err != nil {
		cerr = cerrors.New(cerrors.ERROR_INTERNAL_SERVER_ERROR, fmt.Sprintf("Failed to set request data: '%s'", err.Error()), "bd_streamer.Stream", true)
		return cerr
	}
	//Sending the request to bd_stream microservice
	cerr = cm.MQSend(EXT_TO_BD_STREAM, request)
	if cerr != nil {
		return cerr
	}
	return nil
}
