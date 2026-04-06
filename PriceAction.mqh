//+------------------------------------------------------------------+
//|                                                 PriceAction.mqh |
//|                                      Copyright 2023, Gold Trader   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Gold Trader"
#property strict

extern ENUM_TIMEFRAMES PA_Timeframe;

#import "AlaaGoldEA.mq5"
   void DebugPrint(string message);
#import

int CheckPriceActionBuy()
{
    DebugPrint("Starting to check price action patterns for buy");
    int confirmations = 0;
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    int copied = CopyRates(Symbol(), PA_Timeframe, 0, 50, rates);
    if(copied < 20) { DebugPrint("Error retrieving data for CheckPriceActionBuy: " + IntegerToString(GetLastError())); return 0; }
    confirmations += CheckTrendPatternsBuy(rates);
    if(IsThreeWhiteSoldiers(rates)) confirmations++;
    if(IsBreakoutAboveResistance(rates)) confirmations++;
    if(IsBullishPriceFormation(rates)) confirmations++;
    if(IsActiveSupportHolding(rates)) confirmations++;
    DebugPrint("Number of price action confirmations for buy: " + IntegerToString(confirmations));
    return confirmations;
}

int CheckPriceActionShort()
{
    DebugPrint("Starting to check price action patterns for sell");
    int confirmations = 0;
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    int copied = CopyRates(Symbol(), PA_Timeframe, 0, 50, rates);
    if(copied < 20) { DebugPrint("Error retrieving data for CheckPriceActionShort: " + IntegerToString(GetLastError())); return 0; }
    confirmations += CheckTrendPatternsShort(rates);
    if(IsThreeBlackCrows(rates)) confirmations++;
    if(IsBreakoutBelowSupport(rates)) confirmations++;
    if(IsBearishPriceFormation(rates)) confirmations++;
    if(IsActiveResistanceHolding(rates)) confirmations++;
    DebugPrint("Number of price action confirmations for sell: " + IntegerToString(confirmations));
    return confirmations;
}

bool IsBreakoutAboveResistance(MqlRates &rates[])
{
    int size = ArraySize(rates);
    if(size < 20) return false;
    double resistance = 0;
    for(int i = 10; i > 0; i--) { if(i >= size) continue; if(rates[i].high > resistance) resistance = rates[i].high; }
    if(resistance > 0 && rates[0].close > resistance) return true;
    return false;
}

bool IsBreakoutBelowSupport(MqlRates &rates[])
{
    int size = ArraySize(rates);
    if(size < 20) return false;
    double support = DBL_MAX;
    for(int i = 10; i > 0; i--) { if(i >= size) continue; if(rates[i].low < support) support = rates[i].low; }
    if(support < DBL_MAX && rates[0].close < support) return true;
    return false;
}

bool IsBullishPriceFormation(MqlRates &rates[])
{
    int size = ArraySize(rates);
    if(size < 10) return false;
    double prev_low  = rates[9].low;
    double prev_high = rates[9].high;
    int higher_lows  = 0;
    int higher_highs = 0;
    for(int i = 8; i >= 0; i -= 2) {
        if(i >= size) continue;
        if(rates[i].low > prev_low) { higher_lows++; prev_low = rates[i].low; }
        if(i > 0 && i < size) { if(rates[i-1].high > prev_high) { higher_highs++; prev_high = rates[i-1].high; } }
    }
    return (higher_lows >= 3 || higher_highs >= 3);
}

bool IsBearishPriceFormation(MqlRates &rates[])
{
    int size = ArraySize(rates);
    if(size < 10) return false;
    double prev_low  = rates[9].low;
    double prev_high = rates[9].high;
    int lower_lows   = 0;
    int lower_highs  = 0;
    for(int i = 8; i >= 0; i -= 2) {
        if(i >= size) continue;
        if(rates[i].low < prev_low) { lower_lows++; prev_low = rates[i].low; }
        if(i > 0 && i < size) { if(rates[i-1].high < prev_high) { lower_highs++; prev_high = rates[i-1].high; } }
    }
    return (lower_lows >= 3 || lower_highs >= 3);
}

bool IsActiveSupportHolding(MqlRates &rates[])
{
    int size = ArraySize(rates);
    if(size < 20) return false;
    int trough_idx = -1;
    for(int i = 5; i >= 1; i--) {
        if(i+1 >= size || i-1 < 0) continue;
        if(rates[i].low < rates[i+1].low && rates[i].low < rates[i-1].low) { trough_idx = i; break; }
    }
    if(trough_idx == -1) return false;
    return (rates[0].close > rates[trough_idx].low && rates[0].close > rates[0].open);
}

bool IsActiveResistanceHolding(MqlRates &rates[])
{
    int size = ArraySize(rates);
    if(size < 20) return false;
    int peak_idx = -1;
    for(int i = 5; i >= 1; i--) {
        if(i+1 >= size || i-1 < 0) continue;
        if(rates[i].high > rates[i+1].high && rates[i].high > rates[i-1].high) { peak_idx = i; break; }
    }
    if(peak_idx == -1) return false;
    return (rates[0].close < rates[peak_idx].high && rates[0].close < rates[0].open);
}
