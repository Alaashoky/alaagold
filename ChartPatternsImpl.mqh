//+------------------------------------------------------------------+
//|                                           ChartPatternsImpl.mqh  |
//|                                      Copyright 2023, Gold Trader  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Gold Trader"
#property strict

#import "AlaaGoldEA.mq5"
   void DebugPrint(string message);
   bool CheckArrayAccess(int index, int array_size, string function_name);
#import

bool IsTriangleBullish(MqlRates &rates[], int lookback)
{
    int size = ArraySize(rates);
    if(size < lookback) { DebugPrint("IsTriangleBullish: not enough data"); return false; }

    double high_start = rates[lookback-1].high;
    double high_end   = rates[0].high;
    double low_start  = rates[lookback-1].low;
    double low_end    = rates[0].low;

    bool descending_highs = high_end < high_start;
    bool ascending_lows   = low_end  > low_start;

    if(descending_highs && ascending_lows) {
        double current = SymbolInfoDouble(Symbol(), SYMBOL_BID);
        double resistance = high_start + (high_end - high_start) * 0.1;
        return (current > resistance);
    }
    return false;
}

bool IsTriangleBearish(MqlRates &rates[], int lookback)
{
    int size = ArraySize(rates);
    if(size < lookback) { DebugPrint("IsTriangleBearish: not enough data"); return false; }

    double high_start = rates[lookback-1].high;
    double high_end   = rates[0].high;
    double low_start  = rates[lookback-1].low;
    double low_end    = rates[0].low;

    bool ascending_highs   = high_end > high_start;
    bool descending_lows   = low_end  < low_start;

    if(ascending_highs && descending_lows) {
        double current = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
        double support = low_start + (low_end - low_start) * 0.1;
        return (current < support);
    }
    return false;
}

bool IsFlagBullish(MqlRates &rates[], int lookback)
{
    int size = ArraySize(rates);
    if(size < lookback) return false;

    double pole_low  = rates[lookback-1].low;
    double pole_high = rates[lookback/2].high;
    double pole_size = pole_high - pole_low;
    if(pole_size <= 0) return false;

    double flag_high = rates[lookback/2-1].high;
    double flag_low  = rates[1].low;
    double flag_size = flag_high - flag_low;

    bool strong_pole = pole_size > flag_size * 2;
    bool flag_slope  = flag_high < pole_high && flag_low > pole_low;
    double current   = SymbolInfoDouble(Symbol(), SYMBOL_BID);

    return (strong_pole && flag_slope && current > flag_high);
}

bool IsFlagBearish(MqlRates &rates[], int lookback)
{
    int size = ArraySize(rates);
    if(size < lookback) return false;

    double pole_high = rates[lookback-1].high;
    double pole_low  = rates[lookback/2].low;
    double pole_size = pole_high - pole_low;
    if(pole_size <= 0) return false;

    double flag_low  = rates[lookback/2-1].low;
    double flag_high = rates[1].high;
    double flag_size = flag_high - flag_low;

    bool strong_pole = pole_size > flag_size * 2;
    bool flag_slope  = flag_low > pole_low && flag_high < pole_high;
    double current   = SymbolInfoDouble(Symbol(), SYMBOL_ASK);

    return (strong_pole && flag_slope && current < flag_low);
}

int CheckChartPatternsImplBuy(int lookback = 30)
{
    int confirmations = 0;
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    if(CopyRates(Symbol(), PERIOD_H1, 0, lookback, rates) < lookback) return 0;
    if(IsTriangleBullish(rates, lookback)) confirmations++;
    if(IsFlagBullish(rates, lookback))     confirmations++;
    DebugPrint("ChartPatternsImpl buy confirmations: " + IntegerToString(confirmations));
    return confirmations;
}

int CheckChartPatternsImplShort(int lookback = 30)
{
    int confirmations = 0;
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    if(CopyRates(Symbol(), PERIOD_H1, 0, lookback, rates) < lookback) return 0;
    if(IsTriangleBearish(rates, lookback)) confirmations++;
    if(IsFlagBearish(rates, lookback))     confirmations++;
    DebugPrint("ChartPatternsImpl sell confirmations: " + IntegerToString(confirmations));
    return confirmations;
}
