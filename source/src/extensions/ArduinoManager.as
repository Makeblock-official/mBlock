package extensions
{
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.net.navigateToURL;
	import flash.utils.getQualifiedClassName;
	
	import mx.utils.StringUtil;
	
	import blocks.Block;
	import blocks.BlockIO;
	
	import translation.Translator;
	
	import uiwidgets.DialogBox;
	
	import util.ApplicationManager;
	import util.JSON;
	import util.LogManager;
	import util.SharedObjectManager;
	
	public class ArduinoManager extends EventDispatcher
	{
		
		private static var _instance:ArduinoManager;
		public var _scratch:MBlock;
		public var jsonObj:Object;
		
		public var hexCode:String;
		public var token:String;
		public var output:String;
		public var ccode:String = "";
		public var hexPath:String;
		public var isUploading:Boolean = false;
		
		private var process:NativeProcess;
		public var hasUnknownCode:Boolean = false;
		private var ccode_setup:String = "";
		private var ccode_setup_fun:String = "";
		private var ccode_setup_def:String = "";
		private var ccode_loop:String = ""
		private var ccode_def:String = ""
		private var ccode_inc:String = ""
		private var ccode_pointer:String="setup"
		private var ccode_func:String = "";
		private var mathOp:Array=["+","-","*","/","%",">","=","<","&","|","!","not","rounded"];
		private var varList:Array = [];
		private var varStringList:Array = [];
		private var varListWrite:Array=[]
		private var paramList:Array=[]
		private var moduleList:Array=[];
		private var funcList:Array = [];
		
		public var unknownBlocks:Array = [];
		
		// maintance of project and arduino path
		private var arduinoPath:String = "";
		private var avrPath:String = "";
		private var arduinoLibPath:String = "";
		private var projectPath:String = "";
		private var _currentDevice:String;
		private var _extSrcPath:String = "";
		private var leoPortMap:Array=[[null,null],["11","A8"],["13","A11"],["10","9"],["1","0"],["MISO","SCK"],["A0","A1"],["A2","A3"],["A4","A5"],["6","7"],["5","4"]]
		private var portEnum:Object = {"Port1":1,"Port2":2,"Port3":3,"Port4":4,"Port5":5,"Port6":6,"Port7":7,"Port8":8,"M1":9,"M2":10}
		private var portPortEnum:Object={"Port1":"PORT_1","Port2":"PORT_2","Port3":"PORT_3","Port4":"PORT_4","Port5":"PORT_5","Port6":"PORT_6","Port7":"PORT_7","Port8":"PORT_8","M1":"M1","M2":"M2"}
		private var slotSlotEnum:Object={"Slot1":"SLOT_1","Slot2":"SLOT_2"}
		private var slotEnum:Object = {"Slot1":0,"Slot2":1}
		private var noteEnum:Object = {"B0":31,"C1":33,"D1":37,"E1":41,"F1":44,"G1":49,"A1":55,"B1":62,
			"C2":65,"D2":73,"E2":82,"F2":87,"G2":98,"A2":110,"B2":123,
			"C3":131,"D3":147,"E3":165,"F3":175,"G3":196,"A3":220,"B3":247,
			"C4":262,"D4":294,"E4":330,"F4":349,"G4":392,"A4":440,"B4":494,
			"C5":523,"D5":587,"E5":659,"F5":698,"G5":784,"A5":880,"B5":988,
			"C6":1047,"D6":1175,"E6":1319,"F6":1397,"G6":1568,"A6":1760,"B6":1976,
			"C7":2093,"D7":2349,"E7":2637,"F7":2794,"G7":3136,"A7":3520,"B7":3951,
			"C8":4186,"D8":4699,"Half":500,"Quater":250,"Eighth":125,"Whole":1000,"Double":2000,"Zero":0};
		private var EVENT_NATIVE_DONE:String = "EVENT_NATIVE_DONE"
		private var EVENT_LIBCOMPILE_DONE:String = "EVENT_LIBCOMPILE_DONE"
		private var EVENT_COMPILE_DONE:String = "EVENT_COMPILE_DONE"
		
		public var mainX:int = 0;
		public var mainY:int = 0;
		
		/*
		
		char buffer[64];
		String lastLine;
		int bufferIndex = 0;
		boolean dataLineAvailable(){
		if(Serial.available()){
		char c = Serial.read();
		if(c=='\n'){
		buffer[bufferIndex] = 0;
		return true;
		}else{
		buffer[bufferIndex]=c;
		bufferIndex++;
		}
		}
		return false;
		}
		String readDataLine(){
		if(bufferIndex>0){
		lastLine = buffer;
		}
		bufferIndex = 0;
		memset(buffer,0,64);
		return lastLine;
		}
		String concatenateWith(String s1,String s2){
		return s1+s2;
		}
		char letterOf(int i,String s){
		return s.charAt(i);
		}
		int stringLength(String s){
		return s.length();
		}		
		*/
		
		private var codeTemplate:String = ( <![CDATA[#include <Arduino.h>
#include <Wire.h>
#include <Servo.h>
#include <SoftwareSerial.h>

//include
double angle_rad = PI/180.0;
double angle_deg = 180.0/PI;
//define
//serialParser
//function
void setup(){
//setup
}

void loop(){
//serialParserCall
//loop
}

]]> ).toString();//delay(50);
		
		private var codeSerialParser:String = ( <![CDATA[
char inputBuf[64];
int inputIndex;
void parseSerialInput(){
if(Serial.available()){
char c = Serial.read();
inputBuf[inputIndex++] = c;
if(c=='\\n'){
int value;
//parseList
memset(inputBuf,0,64);
inputIndex = 0;
}
}
}
]]> ).toString();
		
		private var codeSerialScanf:String = ( <![CDATA[
if(sscanf(inputBuf,"param=%d",&value)){
param = value;
//Serial.printf("param=%d\\n",value);
}
]]> ).toString();
		
		private var serialParserInoFile:String = ( <![CDATA[
char buf[64];
char readLine[64];
bool lineParsed = true;
int bufIndex = 0;

void updateVar(char * varName,double * var)
{
  char tmp[16];
  int value,i;
  while(Serial.available()){
	char c = Serial.read();
	buf[bufIndex++] = c;
	if(c=='\n'){
	  memset(readLine,0,64);
	  memcpy(readLine,buf,bufIndex);
	  memset(buf,0,64);
	  bufIndex = 0;
	  lineParsed = false;
	}
  }
  if(!lineParsed){
	char * tmp;
	char * str;
	str = strtok_r(readLine, "=", &tmp);
	if(str!=NULL && strcmp(str,varName)==0){
	  float v = atof(tmp);
	  *var = v;
	  lineParsed = true;
	}
  }
}
]]> ).toString();
		
		public static function sharedManager():ArduinoManager{
			if(_instance==null){
				_instance = new ArduinoManager;
			}
			return _instance;
		} 
		
		public function ArduinoManager()
		{
			addEventListener(EVENT_NATIVE_DONE, gotoNextNativeCmd)
			addEventListener(EVENT_LIBCOMPILE_DONE,runToolChain,false)
			addEventListener(EVENT_COMPILE_DONE,uploadHex,false);
			arduinoPath = SharedObjectManager.sharedManager().getObject("arduinoPath","");
		}
		
		public function setScratch(scratch:MBlock):void{
			_scratch = scratch;
		}
		
		private function portMapPin(port:String,slot:String):String{
			var pin:String = leoPortMap[portEnum[port]][slotEnum[slot]]
			return pin
		}
		
		private function portMapPort(port:String):String{
			return portPortEnum[port]
		}
		
		private function slotMapSlot(slot:String):String{
			return slotSlotEnum[slot]
		}
		
		private function parseMath(blk:Object):CodeObj{
			var op:Object= blk[0]
			var mp1:CodeBlock=getCodeBlock(blk[1]);
			var mp2:CodeBlock=getCodeBlock(blk[2]);
			if(op=="="){
				op="==";
			}
			if(mp1.type=="string"){
				if(!isNaN(Number(mp1.code))){
					mp1.type = "number";
					mp1.code = Number(mp1.code);
				}
			}
			if(mp2.type=="string"){
				if(!isNaN(Number(mp2.code))){
					mp2.type = "number";
					mp2.code = Number(mp2.code);
				}
			}
			//			var isStringValue:Boolean = false;
			//			if(getQualifiedClassName(mp1) == "Array")
			//				mp1 = getCodeBlock(blk[1])
			//			if(getQualifiedClassName(mp2) == "Array")
			//				mp2 = getCodeBlock(blk[2]);
			//			else
			//			{
			//				if(mp1 is String){
			//					isStringValue = mp1.indexOf("readDataLine")>-1;
			//				}
			//			}
			var code:String = StringUtil.substitute("({0}) {1} ({2})",mp1.type=="obj"?mp1.code.code:mp1.code ,op,mp2.type=="obj"?mp2.code.code:mp2.code);
			if(op=="=="){
				if(mp1.type=="string"&&mp2.type=="string"){
					code = StringUtil.substitute("({0}.equals(\"{1}\"))",mp1.code,mp2.code);
				}else{
					code = StringUtil.substitute("(({0})==({1}))",mp1.type=="obj"?mp1.code.code:mp1.code,mp2.type=="obj"?mp2.code.code:mp2.code);
				}
			}else if(op=="%"){
				code = StringUtil.substitute("fmod({0},{1})",mp1.type=="obj"?mp1.code.code:mp1.code,mp2.type=="obj"?mp2.code.code:mp2.code);
			}else if(op=="not"){
				code = StringUtil.substitute("!({0})",mp1.type=="obj"?mp1.code.code:mp1.code);
			}else if(op=="rounded"){
				code = StringUtil.substitute("round({0})",mp1.type=="obj"?mp1.code.code:mp1.code);
			}
			return new CodeObj(code);
		}
		
		
		private function parseVarRead(blk:Object):CodeObj{
			var varName:Object = blk[1]
			if(varList.indexOf(varName)==-1){
				varList.push(varName);
			}
			var code:CodeObj = new CodeObj(StringUtil.substitute("{0}",varName));
			return code;
		}
		
		private function parseVarSet(blk:Object):String{
			var varName:String = blk[1]
			if(varList.indexOf(varName)==-1)
				varList.push(varName)
			var varValue:* = blk[2] is CodeObj?blk[2].code:blk[2];
			if(getQualifiedClassName(varValue) == "Array"){
				varValue = getCodeBlock(varValue);
				if(varValue.type=="obj"){
					if(varValue.code.code.indexOf("ir.getString()")>-1){
						varStringList.push(varName);
					}
				}else if(varValue.type=="string"){
					if(varStringList.indexOf(varName)==-1){
						varStringList.push(varName);
					}
				}
				return (StringUtil.substitute("{0} = {1};\n",varName,varValue.type=="obj"?varValue.code.code:varValue.code))
			}else{
				return (StringUtil.substitute("{0} = {1};\n",varName,varValue is CodeObj?varValue.code:varValue));
			}
		}
		
		private function parseVarShow(fun:Object):CodeObj{
			var param:Object = fun[1]
			if(paramList.indexOf(param)==-1)
				paramList.push(param)
			var funcode:CodeObj=new CodeObj(StringUtil.substitute("Serial.print(\"{0}=\");Serial.println(\"{1}\");\n",param,param));
			return funcode;
		}
		
		private function parseDelay(fun:Object):String{
			var cBlk:CodeBlock=getCodeBlock(fun[1]);
			var funcode:String=(StringUtil.substitute("delay(1000*{0});\n",cBlk.type=="obj"?cBlk.code.code:cBlk.code));
			return funcode;
		}
		private function parseDoRepeat(blk:Object):String{
			var initCode:CodeBlock = getCodeBlock(blk[1]);
			var repeatCode:String=StringUtil.substitute("for(int i=0;i<{0};i++)\n{\n",initCode.type=="obj"?initCode.code.code:initCode.code);
			if(blk[2]!=null){
				for(var i:int=0;i<blk[2].length;i++){
					var b:Object = blk[2][i]
					var cBlk:CodeBlock=getCodeBlock(b);
					repeatCode+=cBlk.type=="obj"?cBlk.code.code:cBlk.code;
				}
			}
			repeatCode+="}\n";
			return repeatCode;
		}
		private function parseDoWaitUntil(blk:Object):String{
			var initCode:CodeBlock = getCodeBlock(blk[1]);
			var untilCode:String=StringUtil.substitute("while(!({0}));\n",initCode.type=="obj"?initCode.code.code:initCode.code);
			return (untilCode);
		}
		private function parseDoUntil(blk:Object):String{
			var initCode:CodeBlock = getCodeBlock(blk[1]);
			var untilCode:String=StringUtil.substitute("while(!({0}))\n{\n",initCode.type=="obj"?initCode.code.code:initCode.code);
			if(blk[2]!=null){
				for(var i:int=0;i<blk[2].length;i++){
					var b:Object = blk[2][i]
					var cBlk:CodeBlock=getCodeBlock(b);
					untilCode+=cBlk.type=="obj"?cBlk.code.code:cBlk.code;
				}
			}
			untilCode+="}\n";
			return (untilCode);
		}
		private function parseCall(blk:Object):String{
			
			var vars:String = "";
			var funcName:String = blk[1];
			if(funcName.indexOf("%")==0){
				funcName = "func "+funcName;
			}
			var ps:Array = funcName.split(" ");
			var tmp:Array = [ps[0]];
			for(var i:uint=0;i<ps.length;i++){
				if(i>0){
					if(ps[i].indexOf("%")>-1){
						tmp.push(ps[i].substr(1,1));
					}
				}
			}
			ps = tmp;
			var params:Array = blk as Array;
			var cBlk:CodeBlock;
			for(i = 2;i<params.length;i++){
				cBlk = getCodeBlock(params[i]);
				//				trace("p:",params[i],cBlk.type,"end");
				if(i>2){
					vars +=",";
				}
				if(cBlk.type=="obj"){
					vars += cBlk.code.code;//(isNaN(Number(params[i]))?'"'+params[i]+'"':(params[i]==""?(ps[i-1]=="s"?'"s"':"false"):params[i]))+(i<params.length-1?", ":"");
				}else{
					
					vars += cBlk.code;
				}
			}
			var callCode:String = StringUtil.substitute("{0}({1});\n",ps[0],vars);
			return (callCode);
		}
		private function addFunction(blks:Array):void{
			var funcName:String = blks[0][1];
			for each(var o:Object in funcList){ 
				if(o.name==funcName){
					return;
				}
			}
			if(funcName.indexOf("%")==0){
				funcName = "func "+funcName;
			}
			var params:Array = funcName.split(" ");
			var tmp:Array = [params[0]];
			for(var i:uint=0;i<params.length;i++){
				if(i>0){
					if(params[i].indexOf("%")>-1){
						tmp.push(params[i].substr(1,1));
					}
				}
			}
			params = tmp;
			var vars:String = "";
			for(i = 1;i<params.length;i++){
				vars += (params[i]=='n'?("double"):(params[i]=='s'?"String":(params[i]=='b'?"boolean":"")))+" "+blks[0][2][i-1].split(" ").join("_")+(i<params.length-1?", ":"");
			}
			var defFunc:String = "void "+params[0]+"("+vars+");\n";
			if(ccode_def.indexOf(defFunc)==-1){
				ccode_def+=defFunc;
			}
			var funcCode:String = "void "+params[0]+"("+vars+")\n{\n";
			for(i=0;i<blks.length;i++){
				if(i>0){
					
					var b:CodeBlock = getCodeBlock(blks[i],blks[0][2]);
					var code:String = (b.type=="obj"?b.code.code:b.code);
					funcCode+=code+"\n";
				}
			}
			funcCode+="}\n";
			funcList.push({name:funcName,code:funcCode});
		}
		private function parseIfElse(blk:Object):String{
			var codeIfElse:String = ""
			var logiccode:CodeBlock = getCodeBlock(blk[1]);
			codeIfElse+=StringUtil.substitute("if({0}){\n",logiccode.type=="obj"?logiccode.code.code:logiccode.code);
			if(blk[2]!=null){
				for(var i:int=0;i<blk[2].length;i++){
					var b:CodeBlock = getCodeBlock(blk[2][i]);
					var ifcode:String=(b.type=="obj"?b.code.code:b.code)+""
					codeIfElse+=ifcode
				}
			}
			codeIfElse+="}else{\n";
			if(blk[3]!=null){
				for(i=0;i<blk[3].length;i++){
					b = getCodeBlock(blk[3][i]);
					var elsecode:String=(b.type=="obj"?b.code.code:b.code)+"";
					codeIfElse+=elsecode;
				}
			}
			codeIfElse+="}\n"
			return codeIfElse
		}
		
		private function parseIf(blk:Object):String{
			var codeIf:String = ""
			var logiccode:String = getCodeBlock(blk[1]).code;
			codeIf+=StringUtil.substitute("if({0}){\n",logiccode)
			if(blk is Array){
				if(blk.length>2){
					if(blk[2]!=null){
						for(var i:int=0;i<blk[2].length;i++){
							var b:CodeBlock = getCodeBlock(blk[2][i]);
							var ifcode:String=(b.type=="obj"?b.code.code:b.code)+"";
							codeIf+=ifcode;
						}
					}
				}
			}
			codeIf+="}\n"
			return codeIf
		}
		
		private function parseVarWrite(blk:Object):String{
			var varName:String = blk[2]
			if (varList.indexOf(varName)==-1){
				varList.push(varName)
			}
			if (varListWrite.indexOf(varName)==-1){
				varListWrite.push(varName)
			}	
			return ""
		}
		private function parseComputeFunction(blk:Object):String{
			var cBlk:CodeBlock = getCodeBlock(blk[2]);
			if(blk[1]=="10 ^"){
				return StringUtil.substitute("pow(10,{0})",cBlk.code);
			}else if(blk[1]=="e ^"){
				return StringUtil.substitute("exp({0})",cBlk.code);
			}else if(blk[1]=="ceiling"){
				return StringUtil.substitute("ceil({0})",cBlk.code);
			}else if(blk[1]=="log"){
				return StringUtil.substitute("log10({0})",cBlk.code);
			}else if(blk[1]=="ln"){
				return StringUtil.substitute("log({0})",cBlk.code);
			}
			
			return StringUtil.substitute("{0}({1})",getCodeBlock(blk[1]).code,cBlk.code).split("sin(").join("sin(angle_rad*").split("cos(").join("cos(angle_rad*").split("tan(").join("tan(angle_rad*");
		}
		private function buildCode(modtype:String,iotype:String,modport:*,modslot:*,valuestring:*):Object{
			var workcode:String = ""
			var setupcode:String = ""
			var defcode:String = ""    
			var inccode:String = ""
			var loopcode:String = ""
			var portcode:String = modport is CodeObj?modport.code:modport;
			var slotcode:String = modslot is CodeObj?modslot.code:modslot;
			var valuecode:String = valuestring is CodeObj?valuestring.code:valuestring;
			if(modtype=="available"){
				if(iotype=="serial"){
					setupcode = StringUtil.substitute("Serial.begin(115200);\n")
					workcode=StringUtil.substitute("dataLineAvailable()");
				}
			}else if(modtype=="read"){
				if(iotype=="serial"){
					setupcode = StringUtil.substitute("Serial.begin(115200);\n")
					workcode=StringUtil.substitute("readDataLine()");
				}
			}else if(modtype=="write"){
				if(iotype=="serial"){
					setupcode = StringUtil.substitute("Serial.begin(115200);\n");
					if(modslot=="command"){
						workcode = StringUtil.substitute("Serial.print(\"{0}=\");Serial.println({1});\n",portcode,valuecode);
					}else if(modslot=="update"){
						workcode = StringUtil.substitute("updateVar(\"{0}\",&{1});\n",portcode,portcode);
					}else{
						workcode=StringUtil.substitute("Serial.println("+(modport is CodeObj?"{0}":"\"{0}\"")+");\n",portcode);
					}
				}
			}else if(modtype=="clear"){
				
			}else{
				hasUnknownCode = true;
				trace("Unknow Module:"+modtype)
			}
			var codeObj:Object = {setup:setupcode,work:workcode,def:defcode,inc:inccode,loop:loopcode};		
			return codeObj;
		}
		
		private function buildModule(mname:String,mport:*,mslot:*,mtype:String,mindex:int,mvalue:*):Object{
			var modDict:Object = {name:mname,port:mport,slot:mslot,type:mtype,index:mindex,value:mvalue}
			modDict.code = buildCode(mname,mtype,mport,mslot,mvalue)
			return modDict;
		}
		
		private function getModule(mod:Object):Object{
			var mdescript:Array = mod[0].split('/')
			var mtype:String = mdescript[0].split('.')[1]
			var mname:String = mdescript[1]
			var mport:CodeBlock = getCodeBlock(mod[1]);
			var mslot:CodeBlock = new CodeBlock();
			var mvalue:CodeBlock = new CodeBlock();
			if(mod.length<=3){
				if(mtype=="run"){
					mvalue = getCodeBlock(mod[mod.length-1]);
				}
				if(mtype=="get"){
					mslot = getCodeBlock(mod[2]);
				}
				if(mtype=="serial"){
					mvalue = getCodeBlock(mod[mod.length-1])
					mslot.code = mdescript[2]
				}
			}else if(mod.length==4){
				mslot = getCodeBlock(mod[2]);
				mvalue = getCodeBlock(mod[3]);
			}else if(mod.length==6){
				if(getQualifiedClassName(mod[3]) == "Array"){
					mod[3] = getCodeBlock(mod[3]).code;
				}			
				if(getQualifiedClassName(mod[4]) == "Array"){
					mod[4] = getCodeBlock(mod[4]).code;
				}
				if(getQualifiedClassName(mod[5]) == "Array"){
					mod[5] = getCodeBlock(mod[5]).code; 
				}
				mvalue.code = StringUtil.substitute("{0},{1},{2},{3}",mod[2],mod[3],mod[4],mod[5])
			}
			for(var i:int = 0;i<moduleList.length;i++){
				var m:Object = moduleList[i]
				if(m.name==mname && m.port==mport.code){
					if(getQualifiedClassName(mvalue.code) == "Array"){
						mvalue = getCodeBlock(mvalue.code)
					}
					m.code=buildCode(mname,mtype,mport.code,mslot.code,mvalue.code) //update work function
					return m
				}
			}
			if(getQualifiedClassName(mvalue.code) == "Array"){
				mvalue = getCodeBlock(mvalue.code)
			}
			moduleList.push(buildModule(mname,mport,mslot,mtype,moduleList.length,mvalue))
			return moduleList[moduleList.length-1]
		}
		
		private function appendFun(funcode:*):void{
			//			if (c!="\n" && c!="}")
			//funcode+=";\n"
			var allowAdd:Boolean = funcode is CodeObj;
			funcode = funcode is CodeObj?funcode.code:funcode;
			
			if(funcode==null) return;
			if(funcode.length==0) return;
			var c:String =  funcode.charAt(funcode.length-1)
			if(ccode_pointer=="setup"){
				if((ccode_setup.indexOf(funcode)==-1&&ccode_setup_fun.indexOf(funcode)==-1)||funcode.indexOf("delay")>-1||allowAdd){
					if(funcode.indexOf("=")>-1&&funcode.indexOf("while")==-1){
						ccode_setup_def=funcode+ccode_setup_def;
					}else{
						ccode_setup_fun+=funcode;
					}
				}
			}
			else if(ccode_pointer=="loop"){
				ccode_loop+=funcode;
			}
		}
		
		private function getCodeBlock(blk:Object,params:Array=null):CodeBlock{
			var code:CodeObj;
			var codeBlock:CodeBlock = new CodeBlock;
			if(blk==null||blk==""){
				codeBlock.type = "number";
				codeBlock.code = "0";
				return codeBlock;
			}
			if(!(blk is Array)){
				codeBlock.code = ""+blk;
				codeBlock.type = isNaN(Number(blk))?"string":"number";
				return codeBlock;
			}
			if(blk.length==0){
				codeBlock.type = "string";
				codeBlock.code = "";
				return codeBlock;
			}
			if(mathOp.indexOf(blk[0])>=0){
				codeBlock.type = "obj";
				codeBlock.code = parseMath(blk);
				return codeBlock;
			}
			else if(blk[0]=="readVariable"){
				codeBlock.type = "obj";
				codeBlock.code = parseVarRead(blk);
				return codeBlock;
			}
			else if(blk[0]=="setVar:to:"){
				codeBlock.type = "string";
				codeBlock.code = parseVarSet(blk);
				return codeBlock;
			}
			else if(blk[0]=="readVariable:")
				code = parseVarShow(blk)
			else if(blk[0]=="wait:elapsed:from:"){
				codeBlock.type = "string";
				codeBlock.code = parseDelay(blk);
				return codeBlock;
			}
			else if(blk[0]=="doIfElse"){
				codeBlock.type = "string";
				codeBlock.code = parseIfElse(blk);
				return codeBlock;
			}
			else if(blk[0]=="doIf"){
				codeBlock.type = "string";
				codeBlock.code = parseIf(blk);
				return codeBlock;
			}
			else if(blk[0]=="writeVariable:")
			{
				codeBlock.type = "string";
				codeBlock.code = parseVarWrite(blk);
				return codeBlock;
			}
			else if(blk[0]=="doRepeat"){
				codeBlock.type = "string";
				codeBlock.code = parseDoRepeat(blk);
				return codeBlock;
			}else if(blk[0]=="doWaitUntil"){
				codeBlock.type = "string";
				codeBlock.code = parseDoWaitUntil(blk);
				return codeBlock;
			}else if(blk[0]=="doUntil"){
				codeBlock.type = "string";
				codeBlock.code = parseDoUntil(blk);
				return codeBlock;
			}else if(blk[0]=="call"){
				codeBlock.type = "string";
				codeBlock.code = parseCall(blk);
				return codeBlock;
			}else if(blk[0]=="randomFrom:to:"){
				codeBlock.type = "number";
				codeBlock.code = StringUtil.substitute("random({0},{1})",getCodeBlock(blk[1]).code,getCodeBlock(blk[2]).code);
				return codeBlock;
			}else if(blk[0]=="computeFunction:of:"){
				codeBlock.type = "number";
				codeBlock.code = parseComputeFunction(blk);
				return codeBlock;
			}else if(blk[0]=="concatenate:with:"){
				var s1:CodeBlock = getCodeBlock(blk[1]);
				var s2:CodeBlock = getCodeBlock(blk[2]);
				codeBlock.type = "obj";
				codeBlock.code = new CodeObj(StringUtil.substitute("{0}+{1}",(s1.type=="obj")?s1.code.code:"String(\""+s1.code+"\")",(s2.type=="obj")?s2.code.code:"String(\""+s2.code+"\")"));
				return codeBlock;
			}else if(blk[0]=="letter:of:"){
				s2 = getCodeBlock(blk[2]);
				codeBlock.type = "obj";
				codeBlock.code = new CodeObj(StringUtil.substitute("{1}.charAt({0}-1)",getCodeBlock(blk[1]).code,(s2.type=="obj")?"String("+s2.code.code+")":"String(\""+s2.code+"\")"));
				return codeBlock;
			}else if(blk[0]=="stringLength:"){
				s1 = getCodeBlock(blk[1]);
				codeBlock.type = "obj";
				codeBlock.code = new CodeObj(StringUtil.substitute("String({0}).length()",(s1.type != "obj")?"\""+s1.code+"\"":s1.code.code));
				return codeBlock;
			}else if(blk[0]=="changeVar:by:"){
				codeBlock.type = "string";
				codeBlock.code = StringUtil.substitute("{0} += {1};\n",getCodeBlock(blk[1]).code,getCodeBlock(blk[2]).code);
				return codeBlock;
			}
				//			else if(blk[0].indexOf("Makeblock")>=0||blk[0].indexOf("Arduino")>=0||blk[0].indexOf("Communication")>=0){
				//				code = new CodeObj(getModule(blk)["code"]["work"]);
				//			}
			else{
				var objs:Array = MBlock.app.extensionManager.specForCmd(blk[0]);
				if(objs!=null){
					var obj:Object = objs[objs.length-1];
					obj = obj[obj.length-1];
					if(typeof obj == "object"){
						var ext:ScratchExtension = MBlock.app.extensionManager.extensionByName(blk[0].split(".")[0]);
						var codeObj:Object = {code:{setup:substitute(obj.setup,blk as Array,ext),work:substitute(obj.work,blk as Array,ext),def:substitute(obj.def,blk as Array,ext),inc:substitute(obj.inc,blk as Array,ext),loop:substitute(obj.loop,blk as Array,ext)}};	
						if(!availableBlock(codeObj)){
							if(ext!=null){
								if(srcDocuments.indexOf(ext.srcPath)==-1){
									srcDocuments.push(ext.srcPath);
								}
							}
							moduleList.push(codeObj);
						}
						codeBlock.type = "obj";
						codeBlock.code = new CodeObj(codeObj.code.work);
						return codeBlock;
					}
				}
				var b:Block = BlockIO.arrayToStack([blk]);
				if(b.op=="getParam"){
					codeBlock.type = "number";
					codeBlock.code = b.spec.split(" ").join("_");
					return codeBlock;
				}
				if(b.op=="procDef"){
					return codeBlock;
				}
				unknownBlocks.push(b);
				hasUnknownCode = true;
				codeBlock.type = "string";
				codeBlock.code = StringUtil.substitute("//unknow {0}{1}",blk[0],b.type=='r'?"":"\n");
				return codeBlock;
			}
			codeBlock.type = "obj";
			codeBlock.code = code;
			return codeBlock;
		}
		private function substitute(str:String,params:Array,ext:ScratchExtension=null,offset:uint = 1):String{
			for(var i:uint=0;i<params.length-offset;i++){
				
				var o:CodeBlock = getCodeBlock(params[i+offset]);
				var v:*=o.type=="string"?(ext.values[o.code]==undefined?o.code:ext.values[o.code]):null;
				var s:CodeBlock = new CodeBlock();
				if(ext==null||(v==null||v==undefined)){
					s = getCodeBlock(params[i+offset]);
					s.type = (s.type=="obj"&&s.code.type!="code")?"string":"number";
				}else{
					s.type = isNaN(Number(v))?"string":"number";
					s.code = v;
				}
				str = str.split("{"+i+"}").join(( s.type == "string")?('"'+s.code+'"'):(( s.type == "number")?s.code:s.code.code));
			}
			return str;
		}
		private function availableBlock(obj:Object):Boolean{
			for each(var o:Object in moduleList){
				if(o.code.def==obj.code.def&&o.code.setup==obj.code.setup){
					return true;
				}
			}
			return false;
		}
		private function parseLoop(blks:Object):void{
			ccode_pointer="loop";
			if(blks!=null){
				for(var i:int;i<blks.length;i++){
					var b:Object = blks[i]
					var cBlk:CodeBlock = getCodeBlock(b);
					appendFun(cBlk.code);
				}
			}
		}
		private function parseModules(blks:Object):void{
			var isArduinoCode:Boolean = false;
			for(var i:int;i<blks.length;i++){
				var b:Object = blks[i];
				var objs:Array = MBlock.app.extensionManager.specForCmd(blks[0]);
				if(objs!=null){
					var obj:Object = objs[objs.length-1];
					obj = obj[obj.length-1];
					if(typeof obj == "object"&&obj!=null){
						var codeObj:Object = {code:{setup:obj.setup,work:obj.work,def:obj.def,inc:obj.inc,loop:obj.loop}};	
						moduleList.push(codeObj);
					}
				}
			}
		}
		private function parseCodeBlocks(blks:Object):Boolean{
			var isArduinoCode:Boolean = false;
			for(var i:int;i<blks.length;i++){
				var b:Object = blks[i];
				if(b[0].indexOf("runArduino")>-1){
					ccode_pointer="setup";
					isArduinoCode = true;
					
					var objs:Array = MBlock.app.extensionManager.specForCmd(blks[0]);
					var n:String = blks[0];
					var ext:ScratchExtension = MBlock.app.extensionManager.extensionByName(n.split(".")[0]);
					if(ext!=null){
						if(srcDocuments.indexOf(ext.srcPath)==-1){
							srcDocuments.push(ext.srcPath);
						}
					}
					if(objs!=null){
						var obj:Object = objs[objs.length-1];
						obj = obj[obj.length-1];
						if(typeof obj == "object"&&obj!=null){
							var codeObj:Object = {code:{setup:obj.setup,work:obj.work,def:obj.def,inc:obj.inc,loop:obj.loop}};	
							moduleList.push(codeObj);
						}
					}
				}else if(b[0]=="doForever"){
					ccode_pointer="loop";
					parseLoop(b[1]);
				}else{
					var cBlk:CodeBlock = getCodeBlock(b);
					appendFun(cBlk.code);
				}
			}
			return isArduinoCode;
		}
		
		private function buildSerialParser(code:String):String{
			if(varListWrite.length==0){
				code = code.replace("//serialParserCall","").replace("//serialParser","")
				return code;
			}
			var codeParser:String=""
			for(var i:int=0;i<varListWrite.length;i++){
				var p:String = varListWrite[i]
				codeParser+=codeSerialScanf.replace("param", p)
			}			
			codeParser = codeSerialParser.replace("//parseList", codeParser)
			code = code.replace("//serialParserCall","parseSerialInput();").replace("//serialParser",codeParser);
			return code;
		}
		
		private function fixTabs(code:String):String{
			var tmp:String = "";
			var tabindex:int=0
			var newLineList:Array = []
			var lines:Array = code.split('\n')
			for(var i:int=0;i<lines.length;i++){
				var l:String = lines[i]
				if(l.indexOf("}")>=0)
					tabindex-=1
				tmp = ""
				for(var j:int=0;j<tabindex;j++)
					tmp+="    "
				newLineList.push(tmp+l)
				if(l.indexOf("{")>=0)
					tabindex+=1
			}
			code = newLineList.join("\n")
			code = code.replace(new RegExp("\r\n", "gi"),"\n") // replace windows type end line
			return code;
		}
		private function fixVars(code:String):String{
			for each(var s:String in varStringList){
				code = code.split("double " +s).join("String "+s);
			}
			return code;
		}
		private var requiredCpp:Array=[];
		public function jsonToCpp(code:String):String{
			// reset code buffers 
			var retcode:String
			ccode_setup=""
			ccode_setup_fun = "";
			ccode_setup_def = "";
			ccode_loop=""
			ccode_inc=""
			ccode_def=""
			ccode_func="";
			hasUnknownCode = false;
			// reset arrays
			varList=[];
			varStringList=[];
			varListWrite=[]
			paramList=[]
			moduleList=[]
			funcList = [];
			unknownBlocks = [];
			// params for compiler
			requiredCpp=[];
			var objs:Object = util.JSON.parse(code);
			var childs:Array = objs.children.reverse();
			for(var i:int=0;i<childs.length;i++){
				var child:Object = childs[i]
				if("scripts" in child){
					for(var j:uint=0;j<child.scripts.length;j++){
						var scr:Object = child.scripts[j][2];
						if(scr[0][0].indexOf("runArduino")==-1){
							if(scr[0][0]=="procDef"){
								addFunction(scr as Array);
								parseModules(scr);
								buildCodes();
							}
							continue;
						}//选中的Arduino主代码
						
						if(!parseCodeBlocks(scr)){
							continue;
						}
						buildCodes();
						if(_scratch!=null){
							_scratch.dispatchEvent(new RobotEvent(RobotEvent.CCODE_GOT,retcode));
						}
						//break; // only the first entrance is parsed
					}
				}
			}
			ccode_func+=buildFunctions();
			retcode = codeTemplate.replace("//setup",ccode_setup).replace("//loop", ccode_loop).replace("//define", ccode_def).replace("//include", ccode_inc).replace("//function",ccode_func);
			retcode = buildSerialParser(retcode);
			retcode = fixTabs(retcode);
			retcode = fixVars(retcode);
			requiredCpp = getRequiredCpp()
			// now go into compile process
			if(!NativeProcess.isSupported) return "";
			return (retcode);
			//			buildAll(retcode, requiredCpp);
		}
		private function buildCodes():void{
			buildInclude();			
			buildDefine();
			buildSetup();
			ccode_setup+=ccode_setup_def;
			//buildSetup();
			ccode_setup+=ccode_setup_fun;
			ccode_setup_fun = "";
			ccode_loop+=buildLoopMaintance();
		}
		private function buildSetup():String{
			var modInitCode:String = "";
			for(var i:int=0;i<moduleList.length;i++){
				var m:Object = moduleList[i];
				var code:* = m["code"]["setup"];
				code = code is CodeObj?code.code:code;
				if(code!=""){
					if(ccode_setup.indexOf(code)==-1&&ccode_setup_fun.indexOf(code)==-1){
						ccode_setup+=code+"";
					}
				}
			}
			return modInitCode;
		}
		
		private function buildDefine():String{
			var modDefineCode:String = ""
			for(var i:int=0;i<varList.length;i++){
				var v:Object = varList[i]
				var code:* = StringUtil.substitute("double {0};\n" ,v)
				if(ccode_def.indexOf(code)==-1){
					ccode_def+=code;
				}
			}
			for(i=0;i<moduleList.length;i++){
				var m:Object = moduleList[i]
				code = m["code"]["def"];
				code = code is CodeObj?code.code:code;
				if(code!=""){
					var array:Array = code.split("\n");
					for(var j:uint=0;j<array.length-1;j++){
						if(ccode_def.indexOf(array[j])==-1){
							ccode_def+=array[j]+"\n";
						}
					}
				}
			}
			return modDefineCode;
		}
		
		private function buildInclude():String{
			var modIncudeCode:String = ""
			for(var i:int=0;i<moduleList.length;i++){
				var m:Object = moduleList[i]
				var code:* = m["code"]["inc"];
				code = code is CodeObj?code.code:code;
				if(code!=""){
					if(ccode_inc.indexOf(code)==-1)
						ccode_inc+=code+"";
				}
			}
			return modIncudeCode;
		}
		
		private function buildLoopMaintance():String{
			var modMaintanceCode:String = ""
			for(var i:int=0;i<moduleList.length;i++){
				var m:Object = moduleList[i]
				var code:* = m["code"]["loop"];
				code = code is CodeObj?code.code:code;
				if(code!=""){
					if(modMaintanceCode.indexOf(code)==-1){
						modMaintanceCode+=code+"\n";
					}
				}
			}
			return modMaintanceCode
		}
		private function buildFunctions():String{
			var funcCodes:String = ""
			for(var i:int=0;i<funcList.length;i++){
				var m:Object = funcList[i]
				var code:* = m["code"];
				code = code is CodeObj?code.code:code;
				if(code!=""){
					if(funcCodes.indexOf(code)==-1)
						funcCodes+=code+"\n";
				}
			}
			return funcCodes;
		}
		private function getRequiredCpp():Array{
			var modMapCpp:Object={"motor":"MeDCMotor","ultrasonic":"MeUltrasonic","servo":"MeServo","temperature":"MeTemperature","led":"MeRGBLed","gyro":"MeGyro","infrared":"MeInfraredReceiver","sevseg":"Me7SegmentDisplay"}
			var cppList:Array=[];
			return cppList;
			for(var i:int=0;i<moduleList.length;i++){
				var m:Object = moduleList[i]
				if(m["name"] in modMapCpp){
					var meModule:String = modMapCpp[m["name"]]
					if(cppList.indexOf(meModule)==-1)
						cppList.push(meModule)
				}
			}
			//			if(cppList.length>0 || moduleList.length>0)
			//cppList.push("MePort")
			return cppList
		}
		
		public function uploadCode(code:String):void{
			var url:String = "http://192.168.1.251:8080/";
			var request:URLRequest = new URLRequest(url);
			var requestVars:URLVariables = new URLVariables();
			requestVars.code = code;
			requestVars.sessionTime = new Date().getTime();
			request.data = requestVars;
			request.method = URLRequestMethod.POST;
			
			var urlLoader:URLLoader = new URLLoader();
			urlLoader = new URLLoader();
			urlLoader.dataFormat = URLLoaderDataFormat.TEXT;
			urlLoader.addEventListener(Event.COMPLETE, uploadCompleteHandler,false,0,true);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler, false, 0, true);
			
			try{
				urlLoader.load(request);
			}catch(e:Error){
				trace(e);
			}
			
		}
		
		private function saveHexFile(token:String,hexString:String):void{
			var f:File = new File();
			f.addEventListener(Event.COMPLETE, _onRfComplete);
			f.save(hexString,token+".hex");
		}
		
		private function _onRfComplete(e:Event):void{
			hexPath = e.target.nativePath
			_scratch.dispatchEvent(new RobotEvent(RobotEvent.HEX_SAVED,hexPath));
		}
		
		private function uploadCompleteHandler(e:Event):void{
			var response:String = String(e.target.data);
			//trace("response:"+response);
			jsonObj = util.JSON.parse(response);
			hexCode = jsonObj["hex"]
			ccode = jsonObj["code"]
			token = jsonObj["hash"]
			output = jsonObj["output"]
			_scratch.dispatchEvent(new RobotEvent(RobotEvent.CCODE_GOT,ccode));
			_scratch.dispatchEvent(new RobotEvent(RobotEvent.COMPILE_OUTPUT,output));
			if(hexCode)
				saveHexFile(token,hexCode);
		}
		
		private function ioErrorHandler(e:Event):void{
			
		}
		
		
		
		
		/****** *****************************
		 * compiler ralated functions 
		 * **********************************/
		
		
		
		private var tc_projCpp:*;
		private var tc_workdir:*;
		private var tc_cppList:*;
		private var nativeDoneEvent:String;
		private var nativeWorkList:Array=[];
		private var srcDocuments:Array = [];
		private var numOfProcess:uint = 0;
		private var numOfSuccess:uint = 0;
		private var _projectDocumentName:String = "";
		private function prepareProjectDir(ccode:String):void{
			_currentDevice = DeviceManager.sharedManager().currentDevice;
			
			var cppList:Array =  requiredCpp;
			// get building direcotry ready
			var workdir:File = File.applicationStorageDirectory.resolvePath("scratchTemp");
			if(!workdir.exists){
				workdir.createDirectory(); 
			}
			var srcdir:File = ApplicationManager.sharedManager().documents.resolvePath("mBlock/libraries/"+_extSrcPath+"/src");
			//			var srcdir:File = File.applicationDirectory.resolvePath("compiler"); 
			if(!workdir.exists){
				return;
			}
			// copy firmware directory
			//			srcdir = srcdir.resolvePath("firmware");
			workdir = workdir.resolvePath(projectDocumentName); 
			//srcdir.copyTo(workdir,true); 
			for each(var path:String in srcDocuments){
				srcdir = new File(path);
				if(srcdir.exists){
					if(srcdir.isDirectory){
						if(srcdir.getDirectoryListing().length>0){
							copyCompileFiles(srcdir.getDirectoryListing(),workdir);
						}
					}
				}
			}
			var projCpp:File = File.applicationStorageDirectory.resolvePath("scratchTemp/"+projectDocumentName+"/"+projectDocumentName+".ino")
			LogManager.sharedManager().log("projCpp:"+projCpp.nativePath);
			var outStream:FileStream = new FileStream();
			outStream.open(projCpp, FileMode.WRITE);
			outStream.writeUTFBytes(ccode)
			outStream.close()
			if(ccode.indexOf("updateVar")>-1){
				// aux ino file for serial variable parser
				projCpp = File.applicationStorageDirectory.resolvePath("scratchTemp/"+projectDocumentName+"/MeComm.ino")
				outStream = new FileStream();
				outStream.open(projCpp, FileMode.WRITE);
				outStream.writeUTFBytes(serialParserInoFile)
				outStream.close()
			}
			
			projectPath = workdir.nativePath;
			LogManager.sharedManager().log("projectPath:"+projectPath);
		}
		
		
		public function uploadHex(evt:*):void{
			//			if(SerialManager.sharedManager().device=="mbot"){
			//				ArduinoUploader.sharedManager().start(projectPath+"\\build\\"+projectDocumentName+".ino.hex");
			//			}else{
			SerialManager.sharedManager().upgrade(projectPath+"/build/"+projectDocumentName+".ino.hex");
			//			}
		}
		
		private var compileErr:Boolean = false;
		private function copyCompileFiles(files:Array,workdir:File):void{
			var dstFile:File;
			var cppList:Array = requiredCpp;
			for (var i:uint = 0; i < files.length; i++)  
			{ 
				if(files[i].extension=="cpp" || files[i].extension=="c" || files[i].extension=="h"){
					dstFile = workdir.resolvePath(files[i].name);
					var n:String = files[i].name.split("."+files[i].extension).join("");;
					if(cppList.indexOf(n)==-1)cppList.push(n);
					files[i].copyTo(dstFile,true);
				}
			}
		}
		public function get projectDocumentName():String{
			var now:Date = new Date;
			var pName:String = MBlock.app.projectName().split(" ").join("");
			for(var i:uint=0;i<pName.length;i++){
				if(pName.charCodeAt(i)>100){
					pName = pName.split(pName.charAt(i)).join("_");
				}
			}
			_projectDocumentName = "project_"+pName+ (now.getMonth()+"_"+now.getDay());
			if(_projectDocumentName=="project_"){
				_projectDocumentName = "project";
			}
			return _projectDocumentName;
		}
		public function buildAll(ccode:String):String
		{
			if(isUploading){
				return "uploading";
			}
			if(arduinoInstallPath==""){
				var dialog:DialogBox = new DialogBox();
				dialog.addTitle("Message");
				dialog.addText("Arduino IDE not found,\nClick 'Set Path' to find the install path of Arduino,\nor Click 'Download' to install the Arduino IDE.");
				function onCancel():void{
					dialog.cancel();
				}
				
				function onSetPath():void{
					var fileRef:File = new File();
					function onPathSelected(evt:Event):void{
						var f:File = evt.target as File;
						arduinoPath = ApplicationManager.sharedManager().system==ApplicationManager.WINDOWS?f.url:(f.url+"/Arduino.app/Contents/Resources/Java");
						SharedObjectManager.sharedManager().setObject("arduinoPath",arduinoPath);
					}
					fileRef.browseForDirectory(Translator.map("Arduino IDE"));
					fileRef.addEventListener(Event.SELECT,onPathSelected);
					dialog.cancel();
				}
				function onDownload():void{
					flash.net.navigateToURL(new URLRequest("http://learn.makeblock.cc/learning-arduino/"));
					dialog.cancel();
				}
				dialog.addButton("Cancel",onCancel);
				dialog.addButton("Set Path",onSetPath);
				dialog.addButton("Download",onDownload);
				dialog.showOnStage(MBlock.app.stage);
				return "Arduino IDE not found.";
			}
			_currentDevice = DeviceManager.sharedManager().currentDevice;
			var cppList:Array =  requiredCpp;
			// get building direcotry ready
			var workdir:File = File.applicationStorageDirectory.resolvePath("scratchTemp")
			if(!workdir.exists){
				workdir.createDirectory(); 
			} 
			
			var srcdir:File = ApplicationManager.sharedManager().documents.resolvePath("mBlock/libraries/"+_extSrcPath+"/src");
			//			var srcdir:File = File.applicationDirectory.resolvePath("compiler"); 
			if(!workdir.exists){
				return "workdir not exists";
			}
			nativeWorkList = []
			// copy firmware directory
			srcdir = srcdir.resolvePath("firmware");
			workdir = workdir.resolvePath(projectDocumentName);
			//srcdir.copyTo(workdir,true); 
			for each(var path:String in srcDocuments){
				srcdir = new File(path);
				if(srcdir.exists){
					if(srcdir.isDirectory){
						if(srcdir.getDirectoryListing().length>0){
							copyCompileFiles(srcdir.getDirectoryListing(),workdir);
						}
					}
				}
			}
			var projCpp:File = File.applicationStorageDirectory.resolvePath("scratchTemp/"+projectDocumentName+"/"+projectDocumentName+".ino")
			var outStream:FileStream = new FileStream();
			outStream.open(projCpp, FileMode.WRITE);
			outStream.writeUTFBytes(ccode)
			outStream.close()
			if(ccode.indexOf("updateVar")>-1){
				// aux ino file for serial variable parser
				projCpp = File.applicationStorageDirectory.resolvePath("scratchTemp/"+projectDocumentName+"/MeComm.ino")
				outStream = new FileStream();
				outStream.open(projCpp, FileMode.WRITE);
				outStream.writeUTFBytes(serialParserInoFile)
				outStream.close()
				ccode = ccode.replace("void setup(){",serialParserInoFile+"\nvoid setup(){"); // too tricky here?
			}
			
			// get MeModule source list
			var files:Array = workdir.getDirectoryListing()
			projectPath = workdir.nativePath
			// get build dir ready
			workdir = workdir.resolvePath("build")
			workdir.createDirectory()
			// yzj, don't use pre-build object any more, build from arduino libs
			/*
			// prepare build directory
			if(boardType=="leonardo")
			srcdir = srcdir.resolvePath("../gcc_template")
			else
			srcdir = srcdir.resolvePath("../gcc_template_uno")
			workdir = workdir.resolvePath("build")
			//workdir.deleteDirectory(true)
			srcdir.copyTo(workdir,true)
			*/
			// prebuild arduino lib
			buildArduinoLib(workdir);
			// copy files
			var dstFile:File;
			for (var i:uint = 0; i < files.length; i++)  
			{ 
				if(files[i].extension=="cpp" || files[i].extension=="c" || files[i].extension=="h"){
					dstFile = workdir.resolvePath(files[i].name);
					var n:String = files[i].name.split("."+files[i].extension).join("");;
					if(cppList.indexOf(n)==-1)cppList.push(n);
					files[i].copyTo(dstFile,true);
				}
			}
			// copy project.ino to ./build/project.ino.cpp
			// combine aux ino and main ino into 1 cpp file
			dstFile = workdir.resolvePath(projectDocumentName+".ino.cpp")
			outStream = new FileStream();
			outStream.open(dstFile, FileMode.WRITE);
			outStream.writeUTFBytes(ccode);
			outStream.close();
			// start building arduino libs
			nativeDoneEvent = EVENT_LIBCOMPILE_DONE
			numOfProcess = nativeWorkList.length
			numOfSuccess = 0
			compileErr = false;
			isUploading = true;
			dispatchEvent(new Event(EVENT_NATIVE_DONE));
			tc_projCpp = projCpp
			tc_workdir = workdir
			tc_cppList = cppList;
			return ""
		}
		
		
		public function openArduinoIDE(ccode:String):String{
			if(arduinoInstallPath==""){
				var dialog:DialogBox = new DialogBox();
				dialog.addTitle("Message");
				dialog.addText("Arduino IDE not found,\nClick 'Set Path' to find the install path of Arduino,\nor Click 'Download' to install the Arduino IDE.");
				function onCancel():void{
					dialog.cancel();
				}
				function onSetPath():void{
					var fileRef:File = new File();
					function onPathSelected(evt:Event):void{
						var f:File = evt.target as File;
						arduinoPath = f.url;
						SharedObjectManager.sharedManager().setObject("arduinoPath",arduinoPath);
					}
					fileRef.browseForDirectory(Translator.map("Arduino IDE"));
					fileRef.addEventListener(Event.SELECT,onPathSelected);
					dialog.cancel();
				}
				function onDownload():void{
					flash.net.navigateToURL(new URLRequest("http://learn.makeblock.cc/learning-arduino/"));
					dialog.cancel();
				}
				dialog.addButton("Cancel",onCancel);
				dialog.addButton("Set Path",onSetPath);
				dialog.addButton("Download",onDownload);
				dialog.showOnStage(MBlock.app.stage);
				return "Arduino IDE not found.";
			}
			prepareProjectDir(ccode)
			var file:File = new File(); 
			if(ApplicationManager.sharedManager().system==ApplicationManager.WINDOWS){
				file.url = arduinoInstallPath+"/arduino.exe";
			}else{
				file.url = new File(arduinoInstallPath+"/../../MacOS/JavaApplicationStub").url;
				if(!file.exists){
					file.url = new File(arduinoInstallPath+"/../MacOS/Arduino").url; 
				}
			}
			
			var processArgs:Vector.<String> = new Vector.<String>(); 
			//trace(contents[i].name, contents[i].size);
			var nativeProcessStartupInfo:NativeProcessStartupInfo =new NativeProcessStartupInfo();
			nativeProcessStartupInfo.executable = file;
			processArgs.push(projectPath+"/"+projectDocumentName+".ino")
			nativeProcessStartupInfo.arguments = processArgs;
			process = new NativeProcess();
			process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, function(e:ProgressEvent):void{}); 
			process.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, function(e:ProgressEvent):void{});
			process.addEventListener(NativeProcessExitEvent.EXIT, function(e:NativeProcessExitEvent):void{});
			process.start(nativeProcessStartupInfo);
			return ""
		}
		
		private function runToolChain(evt:*):String{
			var cpp:File = tc_projCpp
			var dir:File = tc_workdir
			var cppList:Array = tc_cppList
			archOutputFiles(cpp,dir,cppList)
			compileCpp(projectDocumentName+".ino",dir);
			var elf:Array=[projectDocumentName+".ino.o"]
			for(var i:int=0;i<cppList.length;i++){
				var moduleCpp:String = cppList[i]
				compileCpp(moduleCpp,dir)
				elf.push(moduleCpp+".o")
			}
			compileElf(projectDocumentName+".ino",dir,elf);
			generateHex(projectDocumentName+".ino",dir);
			
			nativeDoneEvent = EVENT_COMPILE_DONE
			numOfProcess = nativeWorkList.length
			numOfSuccess = 0
			compileErr = false
			dispatchEvent(new Event(EVENT_NATIVE_DONE));
			return ""
		}
		
		private var arduinoCppList:Array;
		private var arduinoCList:Array;
		private function buildArduinoLib(buildDir:File):void{
			arduinoCppList = []
			arduinoCList = []
			// enum arduino core
			var file:File = new File();
			file.url = new File(arduinoInstallPath+"/hardware/arduino/avr").url;
			if(file.exists){
				avrPath = "/hardware/arduino/avr" // v1.5
			}else{
				avrPath = "/hardware/arduino" // v1.0
			}
			
			file.url = new File(arduinoInstallPath+avrPath+"/cores/arduino").url;
			listArduinoLib(file)
			// enum arduino libs
			file.url = new File(arduinoInstallPath+avrPath+"/libraries").url;
			if(file.exists){
				arduinoLibPath = avrPath+"/libraries";
			}else{
				arduinoLibPath = "/libraries";
			}
			
			file.url = new File(arduinoInstallPath+arduinoLibPath+"/Wire").url;
			listArduinoLib(file)
			file.url = new File(arduinoInstallPath+"/libraries/Servo").url; // servo still in root library
			listArduinoLib(file)
			file.url = new File(arduinoInstallPath+arduinoLibPath+"/SoftwareSerial").url;
			listArduinoLib(file)
			
			//
			for (var i:uint = 0; i < arduinoCppList.length; i++)  
			{ 
				compileCpp(arduinoCppList[i],buildDir)
			}
			for (i = 0; i < arduinoCList.length; i++)  
			{ 
				compileC(arduinoCList[i],buildDir)
			}
		}
		
		private function listArduinoLib(dir:File):void{
			var files:Array = dir.getDirectoryListing()
			for (var i:uint = 0; i < files.length; i++)  
			{ 
				if(files[i].extension=="cpp")
					arduinoCppList.push(dir.nativePath+"/"+files[i].name)
				if(files[i].extension=="c")
					arduinoCList.push(dir.nativePath+"/"+files[i].name)
				if(files[i].isDirectory){
					listArduinoLib(files[i])
				}
			}
		}
		
		public function get arduinoInstallPath():String{
			if(arduinoPath.length>0){
				var ttf:File = new File(); 
				ttf.url = new File(arduinoPath+(ApplicationManager.sharedManager().system==ApplicationManager.WINDOWS?"/hardware/tools/avr/bin/avr-ar.exe":"/hardware/tools/avr/bin/avr-ar")).url;
				if(ttf.exists){
					return arduinoPath;
				}else{
					SharedObjectManager.sharedManager().setObject("arduinoPath","");
					arduinoPath = "";
					//return "";
				}
			}
			var tf:File = new File(); 
			if(ApplicationManager.sharedManager().system==ApplicationManager.MAC_OS){
				tf.url = new File("/Applications/Arduino.app/Contents/Java/hardware/tools/avr/bin/avr-ar").url;
				if(tf.exists){
					arduinoPath ="/Applications/Arduino.app/Contents/Java";
					SharedObjectManager.sharedManager().setObject("arduinoPath",arduinoPath);
					return arduinoPath;
				}else{
					tf.url = new File("/Applications/Arduino.app/Contents/Resources/Java/hardware/tools/avr/bin/avr-ar").url;
					if(tf.exists){
						arduinoPath ="/Applications/Arduino.app/Contents/Resources/Java";
						SharedObjectManager.sharedManager().setObject("arduinoPath",arduinoPath);
						return arduinoPath;
					}
				}
				return "";
			}
			var file:File = File.applicationDirectory.resolvePath("arduino");
			if(file.exists){
				tf.url = file.url+"/hardware/tools/avr/bin/avr-ar.exe"
				if(tf.exists){
					arduinoPath = "file:///"+file.nativePath.split("%20").join("\ ").split("\\").join("/");
					SharedObjectManager.sharedManager().setObject("arduinoPath",arduinoPath);
					return arduinoPath;
				}
			}
			var files:Array = File.getRootDirectories();
			for each(file in files){
				if(file.isDirectory){
					var tmp:Array = file.getDirectoryListing();
					for each(var f:File in tmp){
						if(f.url.toLocaleLowerCase().indexOf("arduino")>-1){
							tf.url = f.url+"/hardware/tools/avr/bin/avr-ar.exe"
							if(tf.exists){
								arduinoPath =(f.url.split("%20").join("\ "));
								SharedObjectManager.sharedManager().setObject("arduinoPath",arduinoPath);
								return arduinoPath;
							}
						}
					}
					var subFile:File = new File(file.nativePath+"Program Files");
					if(subFile.exists){
						if(subFile.isDirectory){
							tmp = subFile.getDirectoryListing();
							for each(f in tmp){
								if(f.url.toLocaleLowerCase().indexOf("arduino")>-1){
									tf.url = f.url+"/hardware/tools/avr/bin/avr-ar.exe"
									if(tf.exists){
										arduinoPath = (f.url.split("%20").join("\ "));
										SharedObjectManager.sharedManager().setObject("arduinoPath",arduinoPath);
										return arduinoPath;
									}
								}
							}
						}
					}
					subFile = new File(file.nativePath+"Program Files (x86)");
					if(subFile.exists){
						if(subFile.isDirectory){
							tmp = subFile.getDirectoryListing();
							for each(f in tmp){
								if(f.url.toLocaleLowerCase().indexOf("arduino")>-1){
									tf.url = f.url+"/hardware/tools/avr/bin/avr-ar.exe"
									if(tf.exists){
										arduinoPath = (f.url.split("%20").join("\ "));
										SharedObjectManager.sharedManager().setObject("arduinoPath",arduinoPath);
										return arduinoPath;
									}
								}
							}
						}
					}
				}
			}
			return arduinoPath;
		}
		
		private function archOutputFiles(cpp:File,dir:File,cppList:Array):void{
			var file:File = new File(arduinoInstallPath+"/hardware/tools/avr/bin/avr-ar"+(ApplicationManager.sharedManager().system==ApplicationManager.WINDOWS?".exe":"")); 
			
			var cmd:Array = ["rcs","core.a","file.o"]
			var contents:Array = dir.getDirectoryListing();
			for (var i:uint = 0; i < contents.length; i++)  
			{ 
				if(contents[i].name.indexOf(".o")>=0){
					var processArgs:Vector.<String> = new Vector.<String>(); 
					//trace(contents[i].name, contents[i].size);
					var nativeProcessStartupInfo:NativeProcessStartupInfo =new NativeProcessStartupInfo();
					nativeProcessStartupInfo.executable = file;
					nativeProcessStartupInfo.workingDirectory = dir
					processArgs.push(cmd[0])
					processArgs.push(cmd[1])
					processArgs.push(contents[i].name)
					nativeProcessStartupInfo.arguments = processArgs;
					nativeWorkList.push(nativeProcessStartupInfo)
					//process.start(nativeProcessStartupInfo);
				}
			}
		}
		
		private function compileCpp(cpp:String,dir:File):void{
			var nativeProcessStartupInfo:NativeProcessStartupInfo =new NativeProcessStartupInfo();
			var file:File = new File(arduinoInstallPath+"/hardware/tools/avr/bin/avr-g++"+(ApplicationManager.sharedManager().system==ApplicationManager.WINDOWS?".exe":"")); 
			//			file.url = arduinoInstallPath+"/hardware/tools/avr/bin/avr-g++.exe";// todo: read the arduino path from setup profile
			nativeProcessStartupInfo.executable = file
			nativeProcessStartupInfo.workingDirectory = dir
			// todo: leonardo and use global arduino path
			var path:String = arduinoInstallPath;
			path=path.split("file:///").join("");//.split("/").join("\\");
			var cmd:String = "";
			trace("currentDevice:",_currentDevice);
			if(_currentDevice=="uno"){
				cmd = " -c -g -Os -w -fno-exceptions -ffunction-sections -fdata-sections -MMD -mmcu=atmega328p -DF_CPU=16000000L -DARDUINO=156 -DARDUINO_AVR_UNO -DARDUINO_ARCH_AVR -I"+path+avrPath+"/cores/arduino -I"+path+avrPath+"/variants/standard -I"+path+"/libraries/Servo/src -I"+path+"/libraries/Servo -I"+path+arduinoLibPath+"/Wire -I"+path+arduinoLibPath+"/Wire/utility -I"+path+arduinoLibPath+"/SoftwareSerial"
			}else if(_currentDevice=="leonardo"){
				cmd = " -c -g -Os -w -fno-exceptions -ffunction-sections -fdata-sections -MMD -mmcu=atmega32u4 -DF_CPU=16000000L -DARDUINO=156 -DARDUINO_AVR_LEONARDO -DARDUINO_ARCH_AVR -DUSB_VID=0x2a03 -DUSB_PID=0x8036 -DUSB_MANUFACTURER= -DUSB_PRODUCT=\"Arduino Leonardo\" -I"+path+avrPath+"/cores/arduino -I"+path+avrPath+"/variants/leonardo -I"+path+"/libraries/Servo/src -I"+path+"/libraries/Servo -I"+path+arduinoLibPath+"/Wire -I"+path+arduinoLibPath+"/Wire/utility -I"+path+arduinoLibPath+"/SoftwareSerial"
			}else if(_currentDevice=="mega1280"){
				cmd = " -c -g -Os -w -fno-exceptions -ffunction-sections -fdata-sections -mmcu=atmega1280 -DF_CPU=16000000L -MMD -DUSB_VID=null -DUSB_PID=null -DARDUINO=1062 -I"+path+avrPath+"/cores/arduino -I"+path+avrPath+"/variants/mega -I"+path+"/libraries/Servo/src -I"+path+"/libraries/Servo -I"+path+arduinoLibPath+"/Wire -I"+path+arduinoLibPath+"/Wire/utility -I"+path+arduinoLibPath+"/SoftwareSerial"
			}else if(_currentDevice=="mega2560"){
				cmd = " -c -g -Os -w -fno-exceptions -ffunction-sections -fdata-sections -mmcu=atmega2560 -DF_CPU=16000000L -MMD -DUSB_VID=null -DUSB_PID=null -DARDUINO=1062 -I"+path+avrPath+"/cores/arduino -I"+path+avrPath+"/variants/mega -I"+path+"/libraries/Servo/src -I"+path+"/libraries/Servo -I"+path+arduinoLibPath+"/Wire -I"+path+arduinoLibPath+"/Wire/utility -I"+path+arduinoLibPath+"/SoftwareSerial"
			}else if(_currentDevice=="nano328"){
				cmd = " -c -g -Os -w -fno-exceptions -ffunction-sections -fdata-sections -mmcu=atmega328p -DF_CPU=16000000L -MMD -DUSB_VID=null -DUSB_PID=null -DARDUINO=1062 -I"+path+avrPath+"/cores/arduino -I"+path+avrPath+"/variants/eightanaloginputs -I"+path+"/libraries/Servo/src -I"+path+"/libraries/Servo -I"+path+arduinoLibPath+"/Wire -I"+path+arduinoLibPath+"/Wire/utility -I"+path+arduinoLibPath+"/SoftwareSerial"
			}else if(_currentDevice=="nano168"){
				cmd = " -c -g -Os -w -fno-exceptions -ffunction-sections -fdata-sections -mmcu=atmega168 -DF_CPU=16000000L -MMD -DUSB_VID=null -DUSB_PID=null -DARDUINO=1062 -I"+path+avrPath+"/cores/arduino -I"+path+avrPath+"/variants/eightanaloginputs -I"+path+"/libraries/Servo/src -I"+path+"/libraries/Servo -I"+path+arduinoLibPath+"/Wire -I"+path+arduinoLibPath+"/Wire/utility -I"+path+arduinoLibPath+"/SoftwareSerial"
			}
			var arg:Array = cmd.split(" -")
			var processArgs:Vector.<String> = new Vector.<String>(); 
			for(var i:int=0;i<arg.length;i++){
				if(arg[i].length>0)
					processArgs.push("-"+arg[i])
			}
			if(cpp.indexOf(".cpp")!=-1)
				processArgs.push(cpp)
			else
				processArgs.push(cpp+".cpp")
			processArgs.push("-o")	
			var tmp:Array = cpp.split("/")
			cpp = tmp[tmp.length-1]
			processArgs.push(cpp+".o")
			nativeProcessStartupInfo.arguments = processArgs;
			nativeWorkList.push(nativeProcessStartupInfo)
			//process.start(nativeProcessStartupInfo); 
		}
		
		private function compileC(cpp:String, dir:File):void{
			var nativeProcessStartupInfo:NativeProcessStartupInfo =new NativeProcessStartupInfo();
			var file:File = new File(arduinoInstallPath+"/hardware/tools/avr/bin/avr-gcc"+(ApplicationManager.sharedManager().system==ApplicationManager.WINDOWS?".exe":"")); 
			nativeProcessStartupInfo.executable = file
			nativeProcessStartupInfo.workingDirectory = dir;
			var path:String = arduinoInstallPath;
			path=path.split("file:///").join("");//.split("/").join("/");
			//			var cmd:String = " -c -g -Os -w -ffunction-sections -fdata-sections -MMD -mmcu=atmega32u4 -DF_CPU=16000000L -DARDUINO=156 -DARDUINO_AVR_LEONARDO -DARDUINO_ARCH_AVR -DUSB_VID=0x2341 -DUSB_PID=0x8036 -DUSB_MANUFACTURER= -DUSB_PRODUCT=\"Arduino Leonardo\" -I"+path+avrPath+"/cores/arduino -I"+path+avrPath+"/variants/leonardo -I"+path+arduinoLibPath+"/Wire -I"+path+"/libraries/Servo/src -I"+path+"/libraries/Servo -I"+path+arduinoLibPath+"/SoftwareSerial -I"+path+arduinoLibPath+"/Wire/utility"
			//			if(boardType!="leonardo")
			//				cmd = " -c -g -Os -w -ffunction-sections -fdata-sections -MMD -mmcu=atmega328p -DF_CPU=16000000L -DARDUINO=156 -DARDUINO_AVR_UNO -DARDUINO_ARCH_AVR -I"+path+avrPath+"/cores/arduino -I"+path+avrPath+"/variants/standard -I"+path+arduinoLibPath+"/Wire -I"+path+"/libraries/Servo/src -I"+path+"/libraries/Servo -I"+path+arduinoLibPath+"/SoftwareSerial -I"+path+arduinoLibPath+"/Wire/utility"
			var cmd:String = "";
			if(_currentDevice=="uno"){
				cmd = " -c -g -Os -w -ffunction-sections -fdata-sections -MMD -mmcu=atmega328p -DF_CPU=16000000L -DARDUINO=156 -DARDUINO_AVR_UNO -DARDUINO_ARCH_AVR -I"+path+avrPath+"/cores/arduino -I"+path+avrPath+"/variants/standard -I"+path+"/libraries/Servo/src -I"+path+"/libraries/Servo -I"+path+arduinoLibPath+"/Wire -I"+path+arduinoLibPath+"/Wire/utility -I"+path+arduinoLibPath+"/SoftwareSerial"
			}else if(_currentDevice=="leonardo"){
				cmd = " -c -g -Os -w -ffunction-sections -fdata-sections -MMD -mmcu=atmega32u4 -DF_CPU=16000000L -DARDUINO=156 -DARDUINO_AVR_LEONARDO -DARDUINO_ARCH_AVR -DUSB_VID=0x2a03 -DUSB_PID=0x8036 -DUSB_MANUFACTURER= -DUSB_PRODUCT=\"Arduino Leonardo\" -I"+path+avrPath+"/cores/arduino -I"+path+avrPath+"/variants/leonardo -I"+path+"/libraries/Servo/src -I"+path+"/libraries/Servo -I"+path+arduinoLibPath+"/Wire -I"+path+arduinoLibPath+"/Wire/utility -I"+path+arduinoLibPath+"/SoftwareSerial"
			}else if(_currentDevice=="mega1280"){
				cmd = " -c -g -Os -w -ffunction-sections -fdata-sections -mmcu=atmega2560 -DF_CPU=16000000L -MMD -DUSB_VID=null -DUSB_PID=null -DARDUINO=1062 -I"+path+avrPath+"/cores/arduino -I"+path+avrPath+"/variants/mega -I"+path+"/libraries/Servo/src -I"+path+"/libraries/Servo -I"+path+arduinoLibPath+"/Wire -I"+path+arduinoLibPath+"/Wire/utility -I"+path+arduinoLibPath+"/SoftwareSerial"
			}else if(_currentDevice=="mega2560"){
				cmd = " -c -g -Os -w -ffunction-sections -fdata-sections -mmcu=atmega2560 -DF_CPU=16000000L -MMD -DUSB_VID=null -DUSB_PID=null -DARDUINO=1062 -I"+path+avrPath+"/cores/arduino -I"+path+avrPath+"/variants/mega -I"+path+"/libraries/Servo/src -I"+path+"/libraries/Servo -I"+path+arduinoLibPath+"/Wire -I"+path+arduinoLibPath+"/Wire/utility -I"+path+arduinoLibPath+"/SoftwareSerial"
			}else if(_currentDevice=="nano328"){
				cmd = " -c -g -Os -w -ffunction-sections -fdata-sections -mmcu=atmega328p -DF_CPU=16000000L -MMD -DUSB_VID=null -DUSB_PID=null -DARDUINO=1062 -I"+path+avrPath+"/cores/arduino -I"+path+avrPath+"/variants/eightanaloginputs -I"+path+"/libraries/Servo/src -I"+path+"/libraries/Servo -I"+path+arduinoLibPath+"/Wire -I"+path+arduinoLibPath+"/Wire/utility -I"+path+arduinoLibPath+"/SoftwareSerial"
			}else if(_currentDevice=="nano168"){
				cmd = " -c -g -Os -w -ffunction-sections -fdata-sections -mmcu=atmega168 -DF_CPU=16000000L -MMD -DUSB_VID=null -DUSB_PID=null -DARDUINO=1062 -I"+path+avrPath+"/cores/arduino -I"+path+avrPath+"/variants/eightanaloginputs -I"+path+"/libraries/Servo/src -I"+path+"/libraries/Servo -I"+path+arduinoLibPath+"/Wire -I"+path+arduinoLibPath+"/Wire/utility -I"+path+arduinoLibPath+"/SoftwareSerial"
			}
			
			var arg:Array = cmd.split(" -")
			var processArgs:Vector.<String> = new Vector.<String>(); 
			for(var i:int=0;i<arg.length;i++){
				if(arg[i].length>0)
					processArgs.push("-"+arg[i])
			}
			if(cpp.indexOf(".c")!=-1)
				processArgs.push(cpp)
			else
				processArgs.push(cpp+".c")
			processArgs.push("-o")	
			var tmp:Array = cpp.split("/")
			cpp = tmp[tmp.length-1]
			processArgs.push(cpp+".o")
			nativeProcessStartupInfo.arguments = processArgs;
			nativeWorkList.push(nativeProcessStartupInfo)
			
		}
		
		private function compileElf(token:String,dir:File,elf:Array):void
		{
			var cmd:String = ""
			if(_currentDevice=="uno"){
				cmd = " -Os -Wl,--gc-sections -mmcu=atmega328p -o token.elf elflist core.a -L./ -lm "
			}else if(_currentDevice=="leonardo"){
				cmd = " -Os -Wl,--gc-sections -mmcu=atmega32u4 -o token.elf elflist core.a -L./ -lm ";
			}else if(_currentDevice=="mega1280"){
				cmd = " -Os -Wl,--gc-sections,--relax -mmcu=atmega1280 -o token.elf elflist core.a -L./ -lm ";
			}else if(_currentDevice=="mega2560"){
				cmd = " -Os -Wl,--gc-sections,--relax -mmcu=atmega2560 -o token.elf elflist core.a -L./ -lm ";
			}else if(_currentDevice=="nano328"){
				cmd = " -Os -Wl,--gc-sections,--relax -mmcu=atmega328p -o token.elf elflist core.a -L./ -lm ";
			}else if(_currentDevice=="nano168"){
				cmd = " -Os -Wl,--gc-sections,--relax -mmcu=atmega168 -o token.elf elflist core.a -L./ -lm ";
			}
			if(elf.indexOf("MeServo.o")!=-1){
				elf.push("./Servo.cpp.o")
			}
			if(elf.indexOf("MeGyro.o")!=-1){
				elf.push("./Wire.cpp.o")
				elf.push("./twi.c.o")
			}
			if(elf.indexOf("MeInfraredReceiver.o")!=-1){
				elf.push("./SoftwareSerial.cpp.o")
			}
			var elflist:String = elf.join(" ")
			cmd = cmd.replace("token", token).replace("elflist", elflist)
			
			var nativeProcessStartupInfo:NativeProcessStartupInfo =new NativeProcessStartupInfo();
			var file:File = new File(arduinoInstallPath+"/hardware/tools/avr/bin/avr-gcc"+(ApplicationManager.sharedManager().system==ApplicationManager.WINDOWS?".exe":"")); 
			nativeProcessStartupInfo.executable = file
			nativeProcessStartupInfo.workingDirectory = dir
			var arg:Array = cmd.split(" ")
			var processArgs:Vector.<String> = new Vector.<String>(); 
			for(var i:int=0;i<arg.length;i++){
				if(arg[i].length>0)
					processArgs.push(arg[i])
			}
			nativeProcessStartupInfo.arguments = processArgs;
			nativeWorkList.push(nativeProcessStartupInfo)
			//process.start(nativeProcessStartupInfo); 
		}
		
		private function generateHex(cpp:String,dir:File):void{
			var nativeProcessStartupInfo:NativeProcessStartupInfo;
			var file:File = new File(arduinoInstallPath+"/hardware/tools/avr/bin/avr-objcopy"+(ApplicationManager.sharedManager().system==ApplicationManager.WINDOWS?".exe":"")); 
			
			// step 1
			var cmd:String = " -O ihex -j .eeprom --set-section-flags=.eeprom=alloc,load --no-change-warnings --change-section-lma .eeprom=0";
			var processArgs:Vector.<String> = new Vector.<String>(); 
			nativeProcessStartupInfo=new NativeProcessStartupInfo()
			nativeProcessStartupInfo.executable = file
			nativeProcessStartupInfo.workingDirectory = dir
			var arg:Array = cmd.split(" ")
			for(var i:int=0;i<arg.length;i++){
				if(arg[i].length>0)
					processArgs.push(arg[i])
			}
			processArgs.push(cpp+".elf")
			processArgs.push(cpp+".eep")
			nativeProcessStartupInfo.arguments = processArgs;
			nativeWorkList.push(nativeProcessStartupInfo)
			// step 2
			cmd = " -O ihex -R .eeprom"
			var processArgs2:Vector.<String> = new Vector.<String>(); 
			nativeProcessStartupInfo=new NativeProcessStartupInfo()
			nativeProcessStartupInfo.executable = file
			nativeProcessStartupInfo.workingDirectory = dir;
			var arg2:Array = cmd.split(" ")
			for(i=0;i<arg2.length;i++){
				if(arg2[i].length>0)
					processArgs2.push(arg2[i])
			}
			processArgs2.push(cpp+".elf")
			processArgs2.push(cpp+".hex")
			nativeProcessStartupInfo.arguments = processArgs2;
			nativeWorkList.push(nativeProcessStartupInfo)
			
		}
		
		
		private function gotoNextNativeCmd(event:Event):void{
			isUploading = true;
			process = new NativeProcess();
			process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData); 
			process.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
			process.addEventListener(NativeProcessExitEvent.EXIT, onExit);
			if(nativeWorkList.length>0 && compileErr==false){
				var nativeProcessStartupInfo:NativeProcessStartupInfo = nativeWorkList.shift()
				MBlock.app.scriptsPart.appendMessage(nativeProcessStartupInfo.executable.nativePath)
				MBlock.app.scriptsPart.appendMessage(nativeProcessStartupInfo.arguments.toString())
				process.start(nativeProcessStartupInfo); 
			}else if(nativeWorkList.length==0){
				// todo: is there a better way to check success of make??
				if(numOfSuccess==numOfProcess)
					dispatchEvent(new Event(nativeDoneEvent))
			}
		}
		
		
		private function onOutputData(event:ProgressEvent):void 
		{ 
			isUploading = true;
			var output:String = process.standardOutput.readUTFBytes(process.standardOutput.bytesAvailable)
			var date:Date = new Date;
			MBlock.app.scriptsPart.appendMessage(""+(date.month+1)+"-"+date.date+" "+date.hours+":"+date.minutes+": Got: "+output); 
		}
		
		private function onErrorData(event:ProgressEvent):void
		{
			isUploading = true;
			compileErr = true
			var errOut:String = process.standardError.readUTFBytes(process.standardError.bytesAvailable);
			var date:Date = new Date;
			MBlock.app.scriptsPart.appendMessage(""+(date.month+1)+"-"+date.date+" "+date.hours+":"+date.minutes+": ####Error####\n"+errOut)
		}
		
		private function onExit(event:NativeProcessExitEvent):void
		{
			isUploading = false;
			var date:Date = new Date;
			
			MBlock.app.scriptsPart.appendMessage(""+(date.month+1)+"-"+date.date+" "+date.hours+":"+date.minutes+": Process exited with "+event.exitCode);
			numOfSuccess++;
			if(compileErr == false)
				dispatchEvent(new Event(EVENT_NATIVE_DONE));
		}
		
	}
}