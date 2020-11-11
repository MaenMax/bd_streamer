package com.kaiostech.bd_streamer_dl3.actions.bd_streamer;

import com.kaiostech.cerrors.CError;
import com.kaiostech.cerrors.CException;
import com.kaiostech.bd_streamer_dl3.actions.IAction;
import com.kaiostech.bd_streamer_dl3.actions.IAutomataLine;
import com.kaiostech.model.core.JWT;
import com.kaiostech.mq.*;
import com.kaiostech.mq.codec.IMQCodec;
import com.kaiostech.mq.codec.MQCodecFactory;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import com.kaiostech.db.bd_streamer.BdStreamerDB;
import com.kaiostech.utils.ErrorUtils;

/**
 * @author Maen
 * Created - 10/26/2020
 */

public class BdStreamerActions implements IAutomataLine {
    private IAction[] _actions;
    private static BdStreamerActions _instance = null;
    private BdStreamerActions() {
        int i;
        int max = MQRequestType.MQRT_LAST.getValue();
        _actions = new IAction[max + 1];
        for (i = 0; i < max + 1; i++) {
            _actions[i] = null;
        }
        _actions[MQRequestType.MQRT_CREATE.getValue()] = new CreateEventRecord();
    }
    public static BdStreamerActions getInstance() {
	if (_instance == null) {
	    _instance = new BdStreamerActions();
	}
	return _instance;
    }
    public IAction[] getAutomataLine() {
	return _actions;
    }
	
}

class CreateEventRecord implements IAction{
    private static Logger _logger = LogManager.getLogger(CreateEventRecord.class);
    private static BdStreamerDB _db = BdStreamerDB.getInstance();
    private static IMQCodec _codec = MQCodecFactory.getDefault(); 
    
    public MQResponse execute(int id, JWT jwt, MQRequest request) {
	if (_logger.isDebugEnabled()) {
            _logger.debug("Req #"+request.ReqId+": "+"CreateEventRecord starts");
        }
	CError err;
	boolean ok;
	String eventId = request.ObjectId;
	MQDataResult dr = request.Data();
	if (dr.err != null){
	    _logger.error("Req #" + request.ReqId + ": CreateEventRecord aborted due to error while fetching request body data: '"+dr.err.toString()+"'!");
	    return null;
	}
	try{
	    ok = _db.createEventRecord(eventId, dr.data);
	} catch(CException e){
	    return ErrorUtils.sendErrorResponse(e.getCError(), request.Id, MQRequestType.MQRT_CREATE, MQRequestScope.MQRS_FIN_BD_STREAM, request.ReqId);
	}
	if(!ok){
	    _logger.error("Req #" + request.ReqId  + " Could not save event record in DB");
	    err = CError.New(CError.ERROR_DATABASE_FAILED,"Could not save event record in DB");
	    return new MQResponse(request.Id, "", MQRequestType.MQRT_CREATE, MQRequestScope.MQRS_FIN_BD_STREAM, _codec.encode(err), true,request.ReqId); 
	}
	if (_logger.isDebugEnabled()) {
	    _logger.debug("Req #"+request.ReqId+": "+"CreateEventRecord ends");
	}
	return  null;
    }
}   
