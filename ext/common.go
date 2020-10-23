package ext

import (
	"git.kaiostech.com/cloud/common/mq"
	"sync"
	l4g "git.kaiostech.com/cloud/thirdparty/code.google.com/p/log4go"
	"git.kaiostech.com/cloud/common/config"
)

const EXT_TO_BD_STREAM = string("ext_to_bd_stream") //NATS subject

var (
	initialized bool // By default, it should be false. Used to auto-initialize
	mu sync.Mutex	 // To prevent race condition at initialization.
	cm mq.MQCliMan
)

// As we have to be as independent as possible from the caller, we have to 
// perform our own initialization.	
func auto_init(req_id string) error {
	if config.GetFEConfig().Common.Debug {
		l4g.Debug("req #%v: auto_init starts",req_id)
		defer l4g.Debug("req #%v: auto_init ends",req_id)
	}
	// We are going to assume the configuration has been read at this stage
	// and rely on the proper configuration of the caller.
	cm=mq.NewMQSimpleCliMan(config.GetConfig().GetNatsServer())
	cm.Start()
	return nil
}
