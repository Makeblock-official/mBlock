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