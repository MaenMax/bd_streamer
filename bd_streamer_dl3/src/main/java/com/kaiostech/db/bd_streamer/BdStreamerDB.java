/*
  creatEventRecord function will add an event entry in bd_stream table which has the following schema:

  CREATE TABLE bd_stream (cursor int, ts timestamp, event_id text,schema_version int,data blob, PRIMARY KEY (cursor,ts,event_id)) WITH CLUSTERING ORDER BY (ts ASC,event_id ASC); 
    
  the "data" blob structure is going to be:
     
  “data” blob structure: 
  { 
  "device_info": { 
  "id": "ID", 
  "device_type": 10, 
  "brand": "AlcatelOneTouch", 
  "model": "GoFlip2", 
  "reference": "4044O-2AAQUS0", 
  "os": "KaiOS", 
  "os_version": "2.5", 
  "device_id": "1921687188",
  "icc_mnc"l: "",
  "icc_mcc": "",
  "net_mnc": "",
  "net_mcc": ""
  }, 
  "event_name": "event_name", 
  "response_code": 200, 
  "data": { 
  } 
  } 

  Example on a valid CQLSH INSERT query:
  insert into bd_stream (cursor , ts , event_id , schema_version , data ) VALUES ( 10,1604292468,'6d82782b-406a-4af1-8dfe-8a39870e1629
  ', 1 , TextAsBlob('{}'));

*/
package com.kaiostech.db.bd_streamer;
import java.util.List;
import java.time.LocalDate;
import java.util.Map;
import java.util.TreeMap;
import java.nio.ByteBuffer;
import com.kaiostech.cerrors.CError;
import com.kaiostech.cerrors.CException;
import com.kaiostech.db.nosql.INoSqlDB_C;
import com.kaiostech.db.nosql.NoSqlDBFactory_C;
import com.kaiostech.utils.Base64Cursor;
import com.datastax.driver.mapping.Mapper;
import com.kaiostech.model.financier.Device;
import java.util.UUID;
import java.lang.System;
import java.util.Date;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import com.kaiostech.mq.codec.IMQCodec;
import com.kaiostech.mq.codec.MQCodecFactory;

/**
 * @author Maen
 * Created at - 03/16/2020
 */

public class BdStreamerDB{

    private static final String FINANCIER_DATA_STREAM_TABLE_NAME = "bd_stream";
    private static final int SCHEMA_VERSION = 1;
    private static Logger _logger = LogManager.getLogger(BdStreamerDB.class);
    private INoSqlDB_C _nosqldb;
    private static BdStreamerDB _bsDB;
    //private String FINANCIER_CUREF_COLUMN_NAME = "curef_class_id";
    //private Mapper<BdStream> _mapper;   
    static {
        INoSqlDB_C nosqldb = NoSqlDBFactory_C.getDefault();
	//   Mapper<BdStream> _mapper = nosqldb.getMapperManager().mapper(BdStream.class);
        _bsDB = new BdStreamerDB(nosqldb); //, fcMapper);
    }
    public static BdStreamerDB getInstance() {
        return _bsDB;
    }
    public BdStreamerDB(INoSqlDB_C nosqldb) {
        this._nosqldb = nosqldb;
    }
    public boolean connect() throws CException {
        try {
            this._nosqldb.connect();
        } catch (CException e) {
            _logger.error("BdStreamerDB: Connection error while connecting to database: '" + e.toString()+"'!");
            throw new CException(CError.New(CError.ERROR_INTERNAL_SERVER_ERROR, e.getMessage(), "DL:BdStreamerDB:connect"));
        }
        return true;
    }
    public void close() {
        if (this._nosqldb != null) {
	    this._nosqldb.close();
	}
    }    
    public boolean createEventRecord(String eventId, byte[] data) throws CException {
        if (_logger.isDebugEnabled()) {
            _logger.debug("createEventRecord starts");
        }
        IMQCodec _codec = MQCodecFactory.getDefault();
        boolean ok;
        // List<Row> results=null;
    	Map<String,Object> query=new TreeMap<String,Object>();
        
        //Verifying functions parameters
        if (eventId == null) {
            _logger.error(Thread.currentThread().getId() + ": '" + "Missing or empty event ID"+ "'!");
	    throw new CException(CError.New(CError.ERROR_INVALID_PARAMETER_VALUE, "Missing or empty event ID.", "DL:BdStreamerDB:createEventRecord"));
        }
	//Creating a timestamp
	long ts = System.currentTimeMillis();  //Epoch time in seconds.
	
	//Calculating cursor value based on event ID.
	//Maen: Bug 111740. Changing the range of cursor values (0-63).
	long cursor = Base64Cursor.strToNLong(eventId,1);

	// Preparing the INSERT query
	query.put("cursor", cursor);
	query.put("ts",ts);
	query.put("event_id",eventId);
	query.put("schema_version", SCHEMA_VERSION);
	query.put("data",data);

	String table_name = getCurrentMonthTable();

	// Executing the INSERT query
	ok = _nosqldb.setValue(null,table_name,query);
	if (_logger.isDebugEnabled()) {
	    _logger.debug(Thread.currentThread().getId() + ": Inserting event: " + eventId + " in table: "+ table_name);
	}
	if (ok) {
	    return true;
	}
	return false;
    }
    //Helper function to append the proper suffex to the table name for table rotation feature. Example: bd_stream_2020_11
    public String getCurrentMonthTable() {
	// Initializing the Date object with current EPOCH timestamp
	Date current_date  = new Date(System.currentTimeMillis());
	//Getting the current month in two decimal digits.
	int currentMonth = current_date.getMonth();
	String month_string = String.format("%02d", currentMonth+1);
	//getting the current year (the year represented by this date, minus 1900). Thus, we need to add 1900 to get the desired value.
	int currentYear = current_date.getYear() + 1900;
	//Building rotating table name
	String currentMonthTable =  FINANCIER_DATA_STREAM_TABLE_NAME + "_" + currentYear + "_" + month_string  ;
	return currentMonthTable;
    }
}
