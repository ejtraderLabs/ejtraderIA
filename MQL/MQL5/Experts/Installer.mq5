//+------------------------------------------------------------------+
//|                                                           ia.mq5 |
//|                                         Copyright 2023, EJtrader |
//|                                         https://bitcoinnano.org/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, EJtrader"
#property link "https://bitcoinnano.org/"
#define VERSION "1.0"
#property version VERSION
#property description "Installer IA Power by https://bitcoinnano.org"

string Library = "";
string Expert = "";

string url = "https://raw.githubusercontent.com/ejtraderLabs/ejtraderIA/main/MQL/MQL5";

string Libraries[2] =
    {
        "libzmq.dll", "libsodium.dll"};

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
    else
    {
        GetDependencies();
    }

    return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    //--- Delete all Objects on Chart
    ObjectsDeleteAll(ChartID(), -1, -1);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void GetDependencies()
{
    Getvcredist();
    for (int l = 0; l < ArraySize(Libraries); l++)
    {
        Library = Libraries[l];
        GetLibraries();
    }

    for (int l = 0; l < ArraySize(Experties); l++)
    {
        Expert = Experties[l];
        FileDelete(Expert);
        GetExperties();
    }
}

#import "shell32.dll"
int ShellExecuteW(int hwnd, string lpOperation, string lpFile, string lpParameters, string lpDirectory, int nShowCmd);
#import

void ExecutePowerShellCommand(string command)
{
    int result = ShellExecuteW(0, "open", "powershell.exe", command, NULL, 0);
    if (result <= 32)
    {
        Print("Falha ao executar o comando: ", result);
    }
}

void Getvcredist()
{
    string command = "-Command \"(New-Object System.Net.WebClient).DownloadFile('https://download.microsoft.com/download/0/6/4/064F84EA-D1DB-4EAA-9A5C-CC2F0FF6A638/vc_redist.x64.exe', 'vcredist_x64.exe'); Start-Process -Wait 'vcredist_x64.exe'\"";
    ExecutePowerShellCommand(command);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void GetLibraries()
{
    //---
    ResetLastError();
    string filePath = TerminalInfoString(TERMINAL_PATH) + "\\MQL5\\Libraries\\" + Library;
    string LibraryUrl = url + "/Libraries/" + Library;
    string command = "-Command \"(New-Object System.Net.WebClient).DownloadFile('" + LibraryUrl + "', '" + filePath + "')\"";
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void GetExperties()
{
    ResetLastError();
    string filePath = TerminalInfoString(TERMINAL_PATH) + "\\MQL5\\Experts\\" + Expert;
    string ExpertsUrl = url + "/Experts/" + Expert;
    string command = "-Command \"(New-Object System.Net.WebClient).DownloadFile('" + ExpertsUrl + "', '" + filePath + "')\"";
}
