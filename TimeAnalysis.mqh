//+------------------------------------------------------------------+
//|                                               TimeAnalysis.mqh   |
//|                                      Copyright 2023, Gold Trader  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Gold Trader"
#property strict

#import "AlaaGoldEA.mq5"
   void DebugPrint(string message);
#import

extern bool  TA_UseSessionFilter;
extern int   TA_LondonOpenHour;
extern int   TA_LondonCloseHour;
extern int   TA_NewYorkOpenHour;
extern int   TA_NewYorkCloseHour;
extern int   TA_TokyoOpenHour;
extern int   TA_TokyoCloseHour;

bool IsLondonSession()
{
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    return (dt.hour >= TA_LondonOpenHour && dt.hour < TA_LondonCloseHour);
}

bool IsNewYorkSession()
{
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    return (dt.hour >= TA_NewYorkOpenHour && dt.hour < TA_NewYorkCloseHour);
}

bool IsTokyoSession()
{
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    return (dt.hour >= TA_TokyoOpenHour || dt.hour < TA_TokyoCloseHour);
}

bool IsHighVolatilityPeriod()
{
    return (IsLondonSession() || IsNewYorkSession() || (IsLondonSession() && IsNewYorkSession()));
}

bool IsTradingTimeAllowed()
{
    if(!TA_UseSessionFilter) return true;
    return IsHighVolatilityPeriod();
}

bool IsWeekend()
{
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    return (dt.day_of_week == 0 || dt.day_of_week == 6);
}

bool IsEndOfWeek()
{
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    return (dt.day_of_week == 5 && dt.hour >= 20);
}

int CheckTimeAnalysisBuy()
{
    if(!IsTradingTimeAllowed()) return 0;
    if(IsWeekend() || IsEndOfWeek()) return 0;
    int confirmations = 0;
    if(IsHighVolatilityPeriod()) confirmations++;
    DebugPrint("Time analysis buy confirmations: " + IntegerToString(confirmations));
    return confirmations;
}

int CheckTimeAnalysisShort()
{
    if(!IsTradingTimeAllowed()) return 0;
    if(IsWeekend() || IsEndOfWeek()) return 0;
    int confirmations = 0;
    if(IsHighVolatilityPeriod()) confirmations++;
    DebugPrint("Time analysis sell confirmations: " + IntegerToString(confirmations));
    return confirmations;
}
