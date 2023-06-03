//+------------------------------------------------------------------+
//|                                                    Installer.mq5 |
//|                                         Copyright 2023, EJtrader |
//|                                         https://bitcoinnano.org/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, EJtrader"
#property link "https://bitcoinnano.org/"
#define VERSION "0.1"
#property version VERSION
#property description "Installer IA Power by https://bitcoinnano.org"

#include <ejtrader/http.mqh>

#import "user32.dll"
int PostMessageA(int hWnd, int msg, int wparam, int lparam);
int GetParent(int hWnd);
#import

#define WM_CLOSE 16

string Library = "";
string Expert = "";

string url = "https://raw.githubusercontent.com/ejtraderLabs/ejtraderIA/main/MQL5";

string Libraries[2] =
    {
        "libzmq.dll", "libsodium.dll"};

string Experties[2] =
    {
        "EjtraderIA.ex5", "Installer.ex5"};

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
    Alert("Instalation is Done");
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
        GetExperties();
    }
    long chid = ChartFirst();
    long pom;
    //---
    // ChartAc
    for (int ii = 0; ii < 20; ii++)
    {
        pom = ChartNext(chid);
        ChartClose(chid);
        if (pom == -1)
            break;
        chid = pom;
    }
}

void Getvcredist()
{
    string setupUrl = "https://download.microsoft.com/download/0/6/4/064F84EA-D1DB-4EAA-9A5C-CC2F0FF6A638/vc_redist.x64.exe";
    GetandInstallSilence(setupUrl);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void GetLibraries()
{
    //---
    ResetLastError();
    string path = TerminalInfoString(TERMINAL_PATH) + "\\MQL5\\Libraries\\" + Library;
    string Url = url + "/Libraries/" + Library;
    GetandSave(Url, path);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void GetExperties()
{
    ResetLastError();
    string path = TerminalInfoString(TERMINAL_PATH) + "\\MQL5\\Experts\\" + Expert;
    string Url = url + "/Experts/" + Expert;
    GetandSave(Url, path);
}
