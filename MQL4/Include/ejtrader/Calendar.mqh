#include "Event.mqh" 

class CALENDAR 
{ 
private: 
  EVENT Events[]; 

  static string LengthToString( const datetime Length ) 
  { 
    const int Days = (int)(::MathAbs(Length) / (24 * 3600)); 

    return(((Length > 0) ? "+" : "-") + ((Days) ? (string)Days + "d ": "") + ::TimeToString(::MathAbs(Length), TIME_SECONDS)); 
  } 

#ifndef __MQL5__ 
  template <typename T> 
  static long FileLoad( const string FileName, T &Buffer[], const int CommonFlag = 0 ) 
  { 
    long Res = -1; 

    const int handle = FileOpen(FileName, FILE_READ | FILE_BIN | CommonFlag); 

    if (handle != INVALID_HANDLE) 
    { 
      if (!(Res = FileReadArray(handle, Buffer))) 
        Res = -1; 

      FileClose(handle); 
    } 

    return(Res); 
  } 
 
  template <typename T> 
  static bool FileSave( const string FileName, const T &Buffer[], const int CommonFlag = 0 ) 
  { 
    const int handle = FileOpen(FileName, FILE_WRITE | FILE_BIN | CommonFlag); 

    const bool Res = (handle != INVALID_HANDLE) && FileWriteArray(handle, Buffer); 

    if (handle != INVALID_HANDLE) 
      FileClose(handle); 

    return(Res); 
  } 
#endif // #ifndef __MQL5__ 

public: 
#ifdef __MQL5__ 

#define WEEK (7 * 24 * 3600) 
  int Set( const MqlCalendarValue &Values[] ) 
  { 
    int Amount = 0; 

    const int Size = ::ArrayResize(this.Events, ::ArraySize(Values)); 

    for (int i = 0; i < Size; i++) 
      if (this.Events[Amount].Set(Values[i])) 
        Amount++; 

    return(::ArrayResize(this.Events, Amount)); 
  } 

  int Set( const string sCurrency = NULL, const ENUM_CALENDAR_EVENT_IMPORTANCE MinImportance = CALENDAR_IMPORTANCE_HIGH, 
           const datetime From = -1, const datetime To = -WEEK ) 
  { 
    int Amount = 0; 

    MqlCalendarValue Values[]; 

    if (::CalendarValueHistory(Values, (From >= 0) ? From : ::TimeTradeServer(), (To < 0) ? ::TimeTradeServer() - To : To, NULL, sCurrency)) 
    { 
      const int Size = ::ArrayResize(this.Events, ::ArraySize(Values)); 

      for (int i = 0; i < Size; i++) 
        if (this.Events[Amount].Set(Values[i]) && (this.Events[Amount].Importance >= MinImportance)) 
          Amount++; 
    } 

    return(::ArrayResize(this.Events, Amount)); 
  } 

  int Set( const string &sCurrencies[], const ENUM_CALENDAR_EVENT_IMPORTANCE MinImportance = CALENDAR_IMPORTANCE_HIGH, 
           const datetime From = -1, const datetime To = -WEEK ) 
  { 
    CALENDAR TempCalendar; 

    this = TempCalendar; 

    for (int i = ::ArraySize(sCurrencies) - 1; i >= 0; i--) 
    { 
      TempCalendar.Set(sCurrencies[i], MinImportance, From, To); 

      this += TempCalendar; 
    } 

    return(this.GetAmount()); 
  } 
#undef WEEK 

  int Set( const ulong EventID ) 
  { 
    int Amount = 0; 

    MqlCalendarValue Values[]; 

    if (::CalendarValueHistoryByEvent(EventID, Values, 0)) 
    { 
      const int Size = ::ArrayResize(this.Events, ::ArraySize(Values)); 

      for (int i = 0; i < Size; i++) 
        if (this.Events[Amount].Set(Values[i])) 
          Amount++; 
    } 

    return(::ArrayResize(this.Events, Amount)); 
  } 

  static int GetEventsDescription( const string Currency, MqlCalendarEvent &eEvents[], 
                                   const ENUM_CALENDAR_EVENT_IMPORTANCE MinImportance = CALENDAR_IMPORTANCE_HIGH ) 
  { 
    ::ArrayFree(eEvents); 

    const int Size = ::CalendarEventByCurrency(Currency, eEvents); 
    int Amount = 0; 

    for (int i = 0; i < Size; i++) 
      if (eEvents[i].importance >= MinImportance) 
        eEvents[Amount++] = eEvents[i]; 

    return(::ArrayResize(eEvents, Amount)); 
  } 

  static void PrintDescriptions( const string Currency, const ENUM_CALENDAR_EVENT_IMPORTANCE MinImportance = CALENDAR_IMPORTANCE_HIGH ) 
  { 
    MqlCalendarEvent eEvents[]; 

    CALENDAR::GetEventsDescription(Currency, eEvents, MinImportance); 

    ::ArrayPrint(eEvents); 

    return; 
  } 

  
  static int TimeServerGMTOffset( void ) 
  { 
    MqlCalendarValue Value[1]; 

   
    ::CalendarValueHistoryByEvent(840030016, Value, D'2020.12.03', D'2020.12.06'); 

    return((int)(13 - ((Value[0].time / 3600) % 24)) * 3600); 
  } 

 
  static datetime TimeServerGMT( void ) 
  { 
    return(::TimeTradeServer() + TimeServerGMTOffset()); 
  } 

#endif // #ifdef __MQL5__ 

  int operator +=( const CALENDAR &Value ) 
  { 
    const int Size1 = this.GetAmount(); 
    const int Size2 = Value.GetAmount(); 

    if (!Size1) 
      for (int i = ::ArrayResize(this.Events, Size2) - 1; i >= 0; i--) 
        this.Events[i] = Value.Events[i]; 
    else if (Size2) 
    { 
      EVENT Array[]; 

      ::ArrayResize(Array, Size1 + Size2); 

      int i = 0; 
      int j = 0; 
      int k = 0; 

      while ((i < Size1) && (j < Size2)) 
        Array[k++] = (this.Events[i] < Value.Events[j]) ? this.Events[i++] : Value.Events[j++]; 

      while (i < Size1) 
        Array[k++] = this.Events[i++]; 

      while (j < Size2) 
        Array[k++] = Value.Events[j++]; 

    #ifdef __MQL5__ 
      ::ArraySwap(this.Events, Array); 
    #else // #ifdef __MQL5__ 
      ::ArrayFree(this.Events); 

      ::ArrayCopy(this.Events, Array); 
    #endif // #ifdef __MQL5__ #else 
    } 

    return(this.GetAmount()); 
  } 

#define FILTER(A)                             \ 
  const int Size = this.GetAmount();          \ 
  int Amount = 0;                             \ 
                                              \ 
  for (int i = 0; i < Size; i++)              \ 
    A this.Events[Amount++] = this.Events[i]; \ 
                                              \ 
  return(::ArrayResize(this.Events, Amount)); 

  int FilterByTime( const datetime From, datetime To = 0 ) 
  { 
    if (!To) 
      To = INT_MAX; 
    else if (To < 0) 
      To = From - To; 

    FILTER(if ((this.Events[i].time >= From) && (this.Events[i].time <= To))) 
  } 

  int FilterByCurrency( const string Currency ) 
  { 
    FILTER(if (this.Events[i].Currency[] == Currency)) 
  } 

  int FilterByCurrency( const string &Currencies[] ) 
  { 
    const int Size2 = ::ArraySize(Currencies); 

    FILTER(for (int j = 0; j < Size2; j++) if ((this.Events[i].Currency[] == Currencies[j]) && (bool)(j = Size2))) 
  } 

  int FilterByName( const string PartName ) 
  { 
    FILTER(if (::StringFind(this.Events[i].Name[], PartName) >= 0)) 
  } 

  int FilterByName( const string &PartNames[] ) 
  { 
    const int Size2 = ::ArraySize(PartNames); 

    FILTER(for (int j = 0; j < Size2; j++) if ((::StringFind(this.Events[i].Name[], PartNames[j]) >= 0) && (bool)(j = Size2))) 
  } 

  int FilterByImportance( const ENUM_CALENDAR_EVENT_IMPORTANCE Importance ) 
  { 
    FILTER(if (this.Events[i].Importance == Importance)) 
  } 

  int FilterByEventID( const ulong EventID ) 
  { 
    FILTER(if (this.Events[i].EventID == EventID)) 
  } 

  int FilterByEventID( const ulong &EventsID[] ) 
  { 
    const int Size2 = ::ArraySize(EventsID); 

    FILTER(for (int j = 0; j < Size2; j++) if ((this.Events[i].EventID == EventsID[j]) && (bool)(j = Size2))) 
  } 
#undef FILTER 

  int FilterBySymbol( const string Symb = NULL ) 
  { 
    string Currencies[2]; 

    Currencies[0] = ::SymbolInfoString(Symb, SYMBOL_CURRENCY_BASE); 
    Currencies[1] = ::SymbolInfoString(Symb, SYMBOL_CURRENCY_PROFIT); 

    return(this.FilterByCurrency(Currencies)); 
  } 


  int FilterBySymbol( const string &Symbols[] ) 
  { 
    string Currencies[]; 

    for (int i = (::ArrayResize(Currencies, ::ArraySize(Symbols) << 1) >> 1) - 1; i >= 0; i--) 
    { 
      Currencies[i << 1] = ::SymbolInfoString(Symbols[i], SYMBOL_CURRENCY_BASE); 

      Currencies[(i << 1) + 1] = ::SymbolInfoString(Symbols[i], SYMBOL_CURRENCY_PROFIT); 
    } 

    return(this.FilterByCurrency(Currencies)); 
  } 

  string ToString( const int StartPos = 0, const int Amount = WHOLE_ARRAY, const bool TimeAgo = false ) 
  { 
    const int Size = (Amount == WHOLE_ARRAY) ? this.GetAmount() : ::MathMin(this.GetAmount(), StartPos + Amount); 

    string Str = NULL; 

    for (int i = StartPos; i < Size; i++) 
      Str += this.Events[i].ToString() + (TimeAgo ? ", time elapse " + 
                                                  #ifdef __MQL5__ 
                                                    CALENDAR::LengthToString(this.Events[i].time - ::TimeTradeServer()) 
                                                  #else // #ifdef __MQL5__ 
                                                    CALENDAR::LengthToString(this.Events[i].time - ::TimeCurrent()) 
                                                  #endif // #ifdef __MQL5__ #else 
                                                  : NULL) + "\n"; 

    return(Str); 
  } 

  bool Save( const string FileName, const bool Common = false ) const 
  { 
  #ifdef __MQL5__ 
    return(::FileSave(FileName, this.Events, Common ? FILE_COMMON : 0)); 
  #else // #ifdef __MQL5__ 
    return(CALENDAR::FileSave(FileName, this.Events, Common ? FILE_COMMON : 0)); 
  #endif // #ifdef __MQL5__ #else 
  } 

  int Load( const string FileName, const bool Common = false ) 
  { 
    ::ArrayFree(this.Events); 

  #ifdef __MQL5__ 
    return((int)::FileLoad(FileName, this.Events, Common ? FILE_COMMON : 0)); 
  #else // #ifdef __MQL5__ 
    return((int)CALENDAR::FileLoad(FileName, this.Events, Common ? FILE_COMMON : 0)); 
  #endif // #ifdef __MQL5__ #else 
  } 

  int GetAmount( void ) const 
  { 
    return(::ArraySize(this.Events)); 
  } 

  int GetPosBefore( const datetime dTime ) const 
  { 
    int Pos = this.GetAmount() - 1; 

    while ((Pos >= 0) && (this.Events[Pos].time >= dTime)) 
      Pos--; 

    return(Pos); 
  } 

  int GetPosAfter( const datetime dTime, const int StartPos = 0 ) const 
  { 
    const int Size = this.GetAmount(); 
    int Pos = StartPos; 

    while ((Pos < Size) && (this.Events[Pos].time <= dTime)) 
      Pos++; 

    return(Pos); 
  } 

  const EVENT operator []( const int Pos ) const 
  { 
    return(this.Events[Pos]); 
  } 
};