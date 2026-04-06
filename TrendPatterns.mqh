//+------------------------------------------------------------------+
//|                                                TrendPatterns.mqh |
//|                                      Copyright 2023, Gold Trader  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Gold Trader"
#property strict

extern ENUM_TIMEFRAMES TP_Timeframe;

#import "AlaaGoldEA.mq5"
   void DebugPrint(string message);
   bool CheckArrayAccess(int index, int array_size, string function_name);
#import

bool IsBullishTrendBreakout(MqlRates &rates[])
{
    int size = ArraySize(rates);
    if(size < 30) { DebugPrint("Error in IsBullishTrendBreakout: Array size is too small: " + IntegerToString(size)); return false; }

    double trendline_value = 0;
    int    count_touches   = 0;
    double slope           = 0;

    for(int i = 3; i < size - 3; i++) {
        if(!CheckArrayAccess(i,size,"IsBullishTrendBreakout") ||
           !CheckArrayAccess(i+1,size,"IsBullishTrendBreakout") ||
           !CheckArrayAccess(i-1,size,"IsBullishTrendBreakout")) continue;

        if(rates[i].high > rates[i+1].high && rates[i].high > rates[i-1].high) {
            if(count_touches == 0) { trendline_value = rates[i].high; count_touches++; }
            else if(count_touches == 1) { slope = (i > 0) ? (rates[i].high - trendline_value)/(double)i : 0; trendline_value = rates[i].high; count_touches++; }
            else {
                double expected_value = trendline_value - (slope*(i));
                if(MathAbs(rates[i].high - expected_value) < 20*Point()) { trendline_value = rates[i].high; count_touches++; }
            }
        }
    }

    if(count_touches < 3) return false;
    trendline_value = trendline_value - (slope*size);

    if(CheckArrayAccess(0,size,"IsBullishTrendBreakout") && CheckArrayAccess(1,size,"IsBullishTrendBreakout"))
        return (rates[0].close > trendline_value && rates[1].close <= trendline_value);

    return false;
}

bool IsBearishTrendBreakout(MqlRates &rates[])
{
    int size = ArraySize(rates);
    if(size < 30) { DebugPrint("Error in IsBearishTrendBreakout: Array size is too small: " + IntegerToString(size)); return false; }

    double trendline_value = 0;
    int    count_touches   = 0;
    double slope           = 0;

    for(int i = 3; i < size - 3; i++) {
        if(!CheckArrayAccess(i,size,"IsBearishTrendBreakout") ||
           !CheckArrayAccess(i+1,size,"IsBearishTrendBreakout") ||
           !CheckArrayAccess(i-1,size,"IsBearishTrendBreakout")) continue;

        if(rates[i].low < rates[i+1].low && rates[i].low < rates[i-1].low) {
            if(count_touches == 0) { trendline_value = rates[i].low; count_touches++; }
            else if(count_touches == 1) { slope = (i > 0) ? (rates[i].low - trendline_value)/(double)i : 0; trendline_value = rates[i].low; count_touches++; }
            else {
                double expected_value = trendline_value + (slope*(i));
                if(MathAbs(rates[i].low - expected_value) < 20*Point()) { trendline_value = rates[i].low; count_touches++; }
            }
        }
    }

    if(count_touches < 3) return false;
    trendline_value = trendline_value + (slope*size);

    if(CheckArrayAccess(0,size,"IsBearishTrendBreakout") && CheckArrayAccess(1,size,"IsBearishTrendBreakout"))
        return (rates[0].close < trendline_value && rates[1].close >= trendline_value);

    return false;
}

int CheckTrendPatternsBuy(MqlRates &rates[])
{
    int confirmations = 0;
    if(ArraySize(rates) < 100) { ArraySetAsSeries(rates,true); CopyRates(Symbol(),TP_Timeframe,0,100,rates); }
    if(IsBullishTrendBreakout(rates)) confirmations++;
    return confirmations;
}

int CheckTrendPatternsShort(MqlRates &rates[])
{
    int confirmations = 0;
    if(ArraySize(rates) < 100) { ArraySetAsSeries(rates,true); CopyRates(Symbol(),TP_Timeframe,0,100,rates); }
    if(IsBearishTrendBreakout(rates)) confirmations++;
    return confirmations;
}
