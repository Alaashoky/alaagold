//+------------------------------------------------------------------+
//|                                               MACrossover.mqh   |
//|                                      Copyright 2023, Gold Trader  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Gold Trader"
#property strict

#import "AlaaGoldEA.mq5"
   void DebugPrint(string message);
#import

extern ENUM_TIMEFRAMES MAC_Timeframe;
extern int MA_Fast_Period;
extern int MA_Slow_Period;
extern int MA_Trend_Period;
extern ENUM_MA_METHOD MA_Method;
extern ENUM_APPLIED_PRICE MA_Applied_Price;

double GetMA(int period, int shift = 0, ENUM_MA_METHOD method = MODE_EMA)
{
    int handle = iMA(Symbol(), MAC_Timeframe, period, 0, method, MA_Applied_Price);
    if(handle == INVALID_HANDLE) { DebugPrint("MA handle invalid for period " + IntegerToString(period)); return 0; }
    double buf[];
    ArraySetAsSeries(buf, true);
    if(CopyBuffer(handle, 0, shift, 1, buf) <= 0) { DebugPrint("MA copy failed"); return 0; }
    IndicatorRelease(handle);
    return buf[0];
}

bool IsMACrossoverBullish()
{
    double fast_cur  = GetMA(MA_Fast_Period, 0, MA_Method);
    double fast_prev = GetMA(MA_Fast_Period, 1, MA_Method);
    double slow_cur  = GetMA(MA_Slow_Period, 0, MA_Method);
    double slow_prev = GetMA(MA_Slow_Period, 1, MA_Method);
    return (fast_cur > slow_cur && fast_prev <= slow_prev);
}

bool IsMACrossoverBearish()
{
    double fast_cur  = GetMA(MA_Fast_Period, 0, MA_Method);
    double fast_prev = GetMA(MA_Fast_Period, 1, MA_Method);
    double slow_cur  = GetMA(MA_Slow_Period, 0, MA_Method);
    double slow_prev = GetMA(MA_Slow_Period, 1, MA_Method);
    return (fast_cur < slow_cur && fast_prev >= slow_prev);
}

bool IsPriceBullishMAAlignment()
{
    double fast  = GetMA(MA_Fast_Period,  0, MA_Method);
    double slow  = GetMA(MA_Slow_Period,  0, MA_Method);
    double trend = GetMA(MA_Trend_Period, 0, MA_Method);
    double price = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    return (price > fast && fast > slow && slow > trend);
}

bool IsPriceBearishMAAlignment()
{
    double fast  = GetMA(MA_Fast_Period,  0, MA_Method);
    double slow  = GetMA(MA_Slow_Period,  0, MA_Method);
    double trend = GetMA(MA_Trend_Period, 0, MA_Method);
    double price = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    return (price < fast && fast < slow && slow < trend);
}

int CheckMACrossoverBuy()
{
    int confirmations = 0;
    if(IsMACrossoverBullish()) confirmations++;
    if(IsPriceBullishMAAlignment()) confirmations++;
    DebugPrint("MA crossover buy confirmations: " + IntegerToString(confirmations));
    return confirmations;
}

int CheckMACrossoverShort()
{
    int confirmations = 0;
    if(IsMACrossoverBearish()) confirmations++;
    if(IsPriceBearishMAAlignment()) confirmations++;
    DebugPrint("MA crossover sell confirmations: " + IntegerToString(confirmations));
    return confirmations;
}
