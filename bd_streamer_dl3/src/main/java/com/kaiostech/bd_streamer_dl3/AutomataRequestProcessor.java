package com.kaiostech.bd_streamer_dl3;

import com.kaiostech.model.core.JWT;

import com.kaiostech.bd_streamer_dl3.actions.IAction;

import com.kaiostech.cerrors.CError;

import com.kaiostech.mq.MQRequestProvider;
import com.kaiostech.mq.MQRequest;
import com.kaiostech.mq.MQServer;
import com.kaiostech.mq.MQResponse;

import com.kaiostech.mq.MQRequestType;
import com.kaiostech.mq.MQRequestScope;

import com.kaiostech.mq.codec.IMQCodec;
import com.kaiostech.mq.codec.MQCodecFactory;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
   This class is actually in charge of executing the requests received by the
   BdStreamerDl class.

   BdStreamerDl will start several threads for this classes in order to provide a
   sufficient pool of workers to execute the requests (each individual request
   execution will take time).
*/
public class AutomataRequestProcessor extends Thread {
    private static Logger _logger=LogManager.getLogger(AutomataRequestProcessor.class);

    private MQRequestProvider _rp=null;
    private int _id=0;
    private int _max_req_process_time=0;
    private IMQCodec _codec=null;
    private Automata _automata=null;
    private MQServer _server;
    private Boolean _keep_running;
    private Boolean _stopped;

    public AutomataRequestProcessor(int id, MQRequestProvider rp, MQServer server, int max_req_process_time) {
        _rp=rp;
        _id=id;
        _max_req_process_time=max_req_process_time;
        _server=server;
        _codec=MQCodecFactory.getNewCodec();
        _keep_running=true;
        _stopped=false;
    }

    public void shutdown() {
        _logger.info("Request Processor #"+_id+": received shutdown signal ...");
        _keep_running=false;
    }

    public Boolean is_stopped() {
        return _stopped;
    }

    public void run() {
        MQRequest req;

        _logger.info("Request Processor #"+_id+": initializing ...");
        _automata=new Automata();

        _logger.info("Request Processor #"+_id+": starting ...");

        while (_keep_running) {
            req=_rp.get();

            if (req==null) {
                try {
                    Thread.sleep(10);
                }
                catch (InterruptedException e) {
                }
                continue;
            }

            if (_logger.isDebugEnabled()) {
                _logger.debug("Request Processor #"+_id+": processing request #"+req.ReqId+" ...");
            }
            process(req);
        }

        _logger.info("Request Processor #"+_id+": shutdown ...");

        _stopped=true;
    }

    private void process(MQRequest request) {
        MQRequestScope scope;
        MQRequestType type;
        JWT jwt;
        IAction action;
        CError err;
        byte []data;
        MQResponse rsp=null;
        long ref_time, cur_time;

        scope=request.Scope;
        type=request.Type;

        // For JWT, we CANNOT use the default codec to decode the JWT object because
        // the definition of JWT in Go layers and Java layer is slightly different.
        // In Go, JWT is a Map<String,Object> whereas in Java JWT is a class containing
        // a Map<String,Object>. Thus is leads to some clashes when decoding/encoding
        // in JSON.
        //jwt=_codec.decode(request.JWT.getBytes(),JWT.class);

        if (request.JWT != null) {
            jwt = JWT.fromString(request.JWT);
        }
        else {
            jwt = JWT.fromString(request.ReqInfo.JWT);
        }

        /*
          We don't check the result because some action may not require the JWT while some others may.
        */

        // Retrieving the action for the given Request Scope and Request Type.
        action=_automata.get(scope,type);

        // The request is invalid as no action is linked with these Scope and Type.
        if (action==null) {
            _logger.error("Request Processor #"+_id+": request #"+request.ReqId+": ("+scope+", "+type+") failed! Not linked with any action.");
            err = CError.New(CError.ERROR_INVALID_REQUEST,"Request #"+request.ReqId+": Invalid request ("+scope+", "+type+")");
            data=_codec.encode(err);
            rsp=new MQResponse(request.Id, "", type, scope,  data, true,request.ReqId);
            _server.send(rsp);
            return;
        }

        // We can finally execute the action!
        ref_time=System.currentTimeMillis();
        rsp=action.execute(_id,jwt,request);
        cur_time=System.currentTimeMillis();

        if ((cur_time-ref_time)>_max_req_process_time) {
            // We exceeded the allowed time. No need to answer anymore since
            // the client is no more waiting for the response!
            _logger.warn("Request Processor #"+_id+": request #"+request.ReqId+" ("+scope+", "+type+") takes too long! [METRICS] Processing time "+(cur_time-ref_time)+" ms > "+_max_req_process_time+" ms. Dropped.");

            err = CError.New(CError.ERROR_TIME_OUT,"Request #"+request.ReqId+" ("+scope+", "+type+") timed out. Check log on DL Server for that particular request ID for details.");
            data=_codec.encode(err);
            rsp=new MQResponse(request.Id, "", type, scope,  data, true,request.ReqId);
            _server.send(rsp);

            return;
        }

        if (rsp==null) {
            _logger.warn("Request Processor #"+_id+": request #"+request.ReqId+" ("+scope+", "+type+") leads to null response! [METRICS] Processing time "+(cur_time-ref_time)+" ms.");
            return;
        }

        _logger.info("Request Processor #"+_id+": request #"+request.ReqId+" ("+scope+", "+type+") success! [METRICS] Processing time "+(cur_time-ref_time)+" ms.");
        _server.send(rsp);
    }
}
    
