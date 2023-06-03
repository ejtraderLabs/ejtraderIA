//+------------------------------------------------------------------+
//|                                                           ia.mq5 |
//|                                         Copyright 2023, EJtrader |
//|                                         https://bitcoinnano.org/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, EJtrader"
#property link "https://bitcoinnano.org/"
#define VERSION "0.1"
#property version VERSION
#property description "IA Power by https://bitcoinnano.org"

#include <Zmq/Zmq.mqh>
#include <ejtrader/PortMap.mqh>
#include <ejtrader/http.mqh>
#include <ejtrader/Json.mqh>
//+------------------------------------------------------------------+
//| ia Description                                                   |
//+------------------------------------------------------------------+
static string ServerKey = "JY%:%zEd6w]<6Z<%d]Ug&oy*-)XmAHJOFjfQUt8t";
input static string genpub; // Public Key
input static string gensec; // secret Key

// A enumeração
enum OptionsEnum
{
    FORECAST,    // Price predictions
    FXDATA,      // Not avalible
    SENTIMENTAL, // Not avalible
    NEWS,        // Not avalible
    FUNDAMENTAL, // Not avalible
    AUTOTRADE    // Not avalible
};

// Declaração de variável
input OptionsEnum SelectedOption = FORECAST; // Select the Service

string baseSymbol;
string ServerAddress = "";
int deInitReason = -1;

Context context;
Socket socket(context, ZMQ_SUB);
PollItem pi[1];

string Expert = "";

string Experties[1] =
    {
        "EjtraderIA.ex5"};

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{

    if (!TERMINAL_DLLS_ALLOWED)
    {
        Alert("Error: Dll calls must be allowed!");
    }
    // check if there is a update
    CheckVertionUpdate();

    // API Authentication
    socket.setCurvePublicKey(genpub);
    socket.setCurveSecretKey(gensec);
    socket.setCurveServerKey(ServerKey);

    // Chart symbol
    baseSymbol = StringSubstr(Symbol(), 0, 6);

    string SelectedService;
    switch (SelectedOption)
    {
    case FORECAST:
        SelectedService = "FORECAST";
        break;
    case FXDATA:
        SelectedService = "FXDATA";
        break;
    case SENTIMENTAL:
        SelectedService = "SENTIMENTAL";
        break;
    case NEWS:
        SelectedService = "NEWS";
        break;
    case FUNDAMENTAL:
        SelectedService = "FUNDAMENTAL";
        break;
    case AUTOTRADE:
        SelectedService = "AUTOTRADE";
        break;
    }

    int port = AutoSelectPort(PortMaps, SelectedService);
    ServerAddress = StringFormat("tcp://%s:%d", ServerIP, port);

    if (deInitReason != REASON_CHARTCHANGE)
    {
        if (!socket.connect(ServerAddress))
        {
            int error = Zmq::errorNumber();
            return INIT_FAILED;
        }

        if (!socket.subscribe(baseSymbol))
        {
            int error = Zmq::errorNumber();
            return INIT_FAILED;
        }

        //--- create timer
        EventSetMillisecondTimer(1);

        //--- setup ZMQ poll structure
        socket.fillPollItem(pi[0], ZMQ_POLLIN);
    }

    //---
    return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{

    deInitReason = reason;
    if (reason != REASON_CHARTCHANGE)
    {
        Print(__FUNCTION__, " Deinitialization reason: ", getUninitReasonText(reason));
        //--- disconnect from API
        socket.disconnect(ServerAddress);

        // Shutdown ZeroMQ Context
        context.shutdown();
        context.destroy(0);

        //--- Delete all Objects on Chart
        ObjectsDeleteAll(ChartID(), -1, -1);
        //--- destroy timer
        EventKillTimer();
    }
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{

    int ret = Socket::poll(pi, 100);
    if (ret == -1)
    {
        Print(">>> Polling command input failed: ", Zmq::errorMessage(Zmq::errorNumber()));
        return;
    }

    if (pi[0].hasInput())
    {

        ZmqMsg symbol;
        ZmqMsg type;
        ZmqMsg content;

        socket.recv(symbol);
        socket.recv(type);

        string msgType = type.getData();
        Print(msgType);
        if (msgType == "FORECAST")
        {
            socket.recv(content);
            string msg = content.getData();
            drawpred(msg);
        }
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void drawpred(string res)
{
    CJAVal json;
    if (!json.Deserialize(res))
    {
        Print("BAD RESPONSE !!");
        return;
    }

    CJAVal pivot = json["pivots"];
    CJAVal target = json["targets"];

    int bars = pivot.Size();

    for (int i = 0; i < bars; i++)
    {
        ObjectDelete(ChartID(), "pivots" + IntegerToString(i + 1));
        ObjectDelete(ChartID(), "targets" + IntegerToString(i + 1));
    }

    for (int i = 0; i < bars; i++)
    {
        double pivotPrice = StringToDouble(pivot[i].ToStr());
        double targetPrice = StringToDouble(target[i].ToStr());

        string pivotName = "pivot" + IntegerToString(i + 1);
        string targetName = "target" + IntegerToString(i + 1);

        // Get time for each object based on the order in the array
        datetime pivotTime = TimeCurrent() + ChartPeriod(0) * 60 * 5;
        datetime targetTime = TimeCurrent() + ChartPeriod(0) * 60;

        color pivotColor = (i == 0) ? clrRed : clrWhite;
        color targetColor = (i == 0) ? clrGreen : clrWhite;

        int pivotSize = (i == 0) ? 1 : 1;
        int targetSize = (i == 0) ? 1 : 1;

        // Create the OBJ_ARROW_LEFT_PRICE object PIVOTS
        ObjectCreate(0, pivotName, OBJ_ARROW_RIGHT_PRICE, 0, pivotTime, pivotPrice);
        ObjectSetInteger(0, pivotName, OBJPROP_COLOR, pivotColor);
        ObjectSetInteger(0, pivotName, OBJPROP_WIDTH, pivotSize);
        ObjectSetInteger(0, pivotName, OBJPROP_ARROWCODE, 159);

        // Create the OBJ_ARROW_LEFT_PRICE object TARGETS
        ObjectCreate(0, targetName, OBJ_ARROW_RIGHT_PRICE, 0, targetTime, targetPrice);
        ObjectSetInteger(0, targetName, OBJPROP_COLOR, targetColor);
        ObjectSetInteger(0, targetName, OBJPROP_WIDTH, targetSize);
        ObjectSetInteger(0, targetName, OBJPROP_ARROWCODE, 160);
    }
}

//+------------------------------------------------------------------+
//| Check Expert Udate Verstion                                      |
//+------------------------------------------------------------------+
void CheckVertionUpdate()
{

    CJAVal incomingMessage;

    // define a URL da API do GitHub
    string url = "https://api.github.com/repos/ejtraderLabs/ejtraderIA/releases/latest";
    string msg = httpGET(url);
    if (!incomingMessage.Deserialize(msg))
    {
        Print("Erro ao receber dados da API do GitHub.");
    }

    string tagName = incomingMessage["tag_name"].ToStr();

    if (VERSION != tagName)

    {
        int choicee = MessageBox(StringFormat("New version available. Update?: ", tagName),
                                 "",
                                 MB_YESNO | MB_ICONQUESTION); //  Two buttons - "Yes" and "No"
        if (choicee == IDYES)
        {
            for (int l = 0; l < ArraySize(Experties); l++)
            {
                Expert = Experties[l];
                GetExperties();
            }
        }
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void GetExperties()
{
    ResetLastError();
    string path = TerminalInfoString(TERMINAL_PATH) + "\\MQL5\\Experts\\" + Expert;
    string Url = "https://raw.githubusercontent.com/ejtraderLabs/ejtraderIA/main/MQL5/Experts/" + Expert;
    GetandSave(Url, path);
}

//+------------------------------------------------------------------+
//| Return a textual description of the deinitialization reason code |
//+------------------------------------------------------------------+
string getUninitReasonText(int reasonCode)
{
    string text = "";
    //---
    switch (reasonCode)
    {
    case REASON_ACCOUNT:
        text = "Account was changed";
        break;
    case REASON_CHARTCHANGE:
        text = "Symbol or timeframe was changed";
        break;
    case REASON_CHARTCLOSE:
        text = "Chart was closed";
        break;
    case REASON_PARAMETERS:
        text = "Input-parameter was changed";
        break;
    case REASON_RECOMPILE:
        text = "Program " + __FILE__ + " was recompiled";
        break;
    case REASON_REMOVE:
        text = "Program " + __FILE__ + " was removed from chart";
        break;
    case REASON_TEMPLATE:
        text = "New template was applied to chart";
        break;
    default:
        text = "Another reason";
    }
    //---
    return text;
}
//+------------------------------------------------------------------+
