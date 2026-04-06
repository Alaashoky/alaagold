//+------------------------------------------------------------------+
//|                                             MultiTimeframe.mqh   |
//|                                      Copyright 2023, Gold Trader  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Gold Trader"
#property strict

#import "AlaaGoldEA.mq5"
   void DebugPrint(string message);
#import

extern ENUM_TIMEFRAMES MTF_HigherTF;
extern ENUM_TIMEFRAMES MTF_LowerTF;
extern int             MTF_MA_Period;

bool IsHigherTimeframeBullish()
{
    int handle = iMA(Symbol(), MTF_HigherTF, MTF_MA_Period, 0, MODE_EMA, PRICE_CLOSE);
    if(handle == INVALID_HANDLE) { DebugPrint("MTF higher TF MA handle invalid"); return false; }
    double buf[];
    ArraySetAsSeries(buf, true);
    if(CopyBuffer(handle, 0, 0, 1, buf) <= 0) { IndicatorRelease(handle); return false; }
    IndicatorRelease(handle);
    double price = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    return (price > buf[0]);
}

bool IsHigherTimeframeBearish()
{
    int handle = iMA(Symbol(), MTF_HigherTF, MTF_MA_Period, 0, MODE_EMA, PRICE_CLOSE);
    if(handle == INVALID_HANDLE) { DebugPrint("MTF higher TF MA handle invalid"); return false; }
    double buf[];
    ArraySetAsSeries(buf, true);
    if(CopyBuffer(handle, 0, 0, 1, buf) <= 0) { IndicatorRelease(handle); return false; }
    IndicatorRelease(handle);
    double price = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    return (price < buf[0]);
}

bool IsLowerTimeframeBullishMomentum()
{
    int rsi_handle = iRSI(Symbol(), MTF_LowerTF, 14, PRICE_CLOSE);
    if(rsi_handle == INVALID_HANDLE) return false;
    double rsi_buf[];
    ArraySetAsSeries(rsi_buf, true);
    if(CopyBuffer(rsi_handle, 0, 0, 2, rsi_buf) < 2) { IndicatorRelease(rsi_handle); return false; }
    IndicatorRelease(rsi_handle);
    return (rsi_buf[0] > 50 && rsi_buf[0] > rsi_buf[1]);
}

bool IsLowerTimeframeBearishMomentum()
{
    int rsi_handle = iRSI(Symbol(), MTF_LowerTF, 14, PRICE_CLOSE);
    if(rsi_handle == INVALID_HANDLE) return false;
    double rsi_buf[];
    ArraySetAsSeries(rsi_buf, true);
    if(CopyBuffer(rsi_handle, 0, 0, 2, rsi_buf) < 2) { IndicatorRelease(rsi_handle); return false; }
    IndicatorRelease(rsi_handle);
    return (rsi_buf[0] < 50 && rsi_buf[0] < rsi_buf[1]);
}

int CheckMultiTimeframeBuy()
{
    int confirmations = 0;
    if(IsHigherTimeframeBullish()) confirmations++;
    if(IsLowerTimeframeBullishMomentum()) confirmations++;
    DebugPrint("MTF buy confirmations: " + IntegerToString(confirmations));
    return confirmations;
}

int CheckMultiTimeframeShort()
{
    int confirmations = 0;
    if(IsHigherTimeframeBearish()) confirmations++;
    if(IsLowerTimeframeBearishMomentum()) confirmations++;
    DebugPrint("MTF sell confirmations: " + IntegerToString(confirmations));
    return confirmations;
}
