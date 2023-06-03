
int ServerPort;       // Server Port (0 for auto selection)
string Instrument;   // Server instrument ("AUTO" for current symbol)
string ServerIP="192.168.1.153";
#property strict
//+------------------------------------------------------------------+
//| A symbol to port map                                             |
//+------------------------------------------------------------------+
struct PortMap
  {
   string            ServicesString;
   int               Port;
  };
//+------------------------------------------------------------------+
//| Automatically select a port for the specified symbol             |
//+------------------------------------------------------------------+
int AutoSelectPort(const PortMap &portMap[],string services)
  {
  
   for(int i=0; i<ArraySize(portMap)-1; i++)
     {
      if(portMap[i].ServicesString==services)
        {
         return portMap[i].Port;
        }
     }
   Alert("Service is Not supported On This Version!");
   
   return 0;
  }
// edit here to update auto port mapping
PortMap PortMaps[]=
  {
     
     {"FORECAST", 7001},
     {"FXDATA", 7001},
     {"SENTIMENTAL", 7001},
     {"NEWS", 7001},
     {"FUNDAMENTAL", 7001},
     {"AUTOTRADE", 7001},
      
     {"", NULL}
  
  };

