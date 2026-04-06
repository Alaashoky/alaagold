//+------------------------------------------------------------------+
//|                                                  Indicators.mqh  |
//|                                      Copyright 2023, Gold Trader  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Gold Trader"
#property strict

#import "AlaaGoldEA.mq5"
   void DebugPrint(string message);
#import

extern ENUM_TIMEFRAMES IND_Timeframe;
extern int RSI_Period;
extern int MACD_Fast;
extern int MACD_Slow;
extern int MACD_Signal;
extern int BB_Period;
extern double BB_Deviation;
extern int ATR_Period;

double GetRSI(int shift = 0)
{
    int handle = iRSI(Symbol(), IND_Timeframe, RSI_Period, PRICE_CLOSE);
    if(handle == INVALID_HANDLE) { DebugPrint("RSI handle invalid"); return 50; }
    double buf[];
    ArraySetAsSeries(buf, true);
    if(CopyBuffer(handle, 0, shift, 1, buf) <= 0) { DebugPrint("RSI copy failed"); return 50; }
    IndicatorRelease(handle);
    return buf[0];
}

double GetMACDMain(int shift = 0)
{
    int handle = iMACD(Symbol(), IND_Timeframe, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE);
    if(handle == INVALID_HANDLE) { DebugPrint("MACD handle invalid"); return 0; }
    double buf[];
    ArraySetAsSeries(buf, true);
    if(CopyBuffer(handle, 0, shift, 1, buf) <= 0) { DebugPrint("MACD main copy failed"); return 0; }
    IndicatorRelease(handle);
    return buf[0];
}

double GetMACDSignal(int shift = 0)
{
    int handle = iMACD(Symbol(), IND_Timeframe, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE);
    if(handle == INVALID_HANDLE) { DebugPrint("MACD handle invalid"); return 0; }
    double buf[];
    ArraySetAsSeries(buf, true);
    if(CopyBuffer(handle, 1, shift, 1, buf) <= 0) { DebugPrint("MACD signal copy failed"); return 0; }
    IndicatorRelease(handle);
    return buf[0];
}

double GetBBUpper(int shift = 0)
{
    int handle = iBands(Symbol(), IND_Timeframe, BB_Period, 0, BB_Deviation, PRICE_CLOSE);
    if(handle == INVALID_HANDLE) return 0;
    double buf[];
    ArraySetAsSeries(buf, true);
    if(CopyBuffer(handle, 1, shift, 1, buf) <= 0) return 0;
    IndicatorRelease(handle);
    return buf[0];
}

double GetBBLower(int shift = 0)
{
    int handle = iBands(Symbol(), IND_Timeframe, BB_Period, 0, BB_Deviation, PRICE_CLOSE);
    if(handle == INVALID_HANDLE) return 0;
    double buf[];
    ArraySetAsSeries(buf, true);
    if(CopyBuffer(handle, 2, shift, 1, buf) <= 0) return 0;
    IndicatorRelease(handle);
    return buf[0];
}

double GetBBMiddle(int shift = 0)
{
    int handle = iBands(Symbol(), IND_Timeframe, BB_Period, 0, BB_Deviation, PRICE_CLOSE);
    if(handle == INVALID_HANDLE) return 0;
    double buf[];
    ArraySetAsSeries(buf, true);
    if(CopyBuffer(handle, 0, shift, 1, buf) <= 0) return 0;
    IndicatorRelease(handle);
    return buf[0];
}

double GetATR(int shift = 0)
{
    int handle = iATR(Symbol(), IND_Timeframe, ATR_Period);
    if(handle == INVALID_HANDLE) return 0;
    double buf[];
    ArraySetAsSeries(buf, true);
    if(CopyBuffer(handle, 0, shift, 1, buf) <= 0) return 0;
    IndicatorRelease(handle);
    return buf[0];
}

int CheckIndicatorsBuy()
{
    int confirmations = 0;
    double rsi        = GetRSI();
    double macd_main  = GetMACDMain();
    double macd_sig   = GetMACDSignal();
    double price      = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    double bb_lower   = GetBBLower();

    if(rsi < 40) confirmations++;
    if(macd_main > macd_sig && GetMACDMain(1) <= GetMACDSignal(1)) confirmations++;
    if(price <= bb_lower * 1.001) confirmations++;

    DebugPrint("Indicator buy confirmations: " + IntegerToString(confirmations));
    return confirmations;
}

int CheckIndicatorsShort()
{
    int confirmations = 0;
    double rsi        = GetRSI();
    double macd_main  = GetMACDMain();
    double macd_sig   = GetMACDSignal();
    double price      = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    double bb_upper   = GetBBUpper();

    if(rsi > 60) confirmations++;
    if(macd_main < macd_sig && GetMACDMain(1) >= GetMACDSignal(1)) confirmations++;
    if(price >= bb_upper * 0.999) confirmations++;

    DebugPrint("Indicator sell confirmations: " + IntegerToString(confirmations));
    return confirmations;
}
