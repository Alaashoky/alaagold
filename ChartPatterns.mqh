//+------------------------------------------------------------------+
//|                                               ChartPatterns.mqh  |
//|                                      Copyright 2023, Gold Trader  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Gold Trader"
#property strict

#import "AlaaGoldEA.mq5"
   void DebugPrint(string message);
#import

extern ENUM_TIMEFRAMES CHT_Timeframe;
extern int CHT_Lookback;
extern double CHT_Tolerance;

bool IsHeadAndShouldersBullish(MqlRates &rates[])
{
    int size = ArraySize(rates);
    if(size < CHT_Lookback) return false;

    for(int i = 5; i < CHT_Lookback - 5; i++) {
        double left_shoulder  = rates[i+4].low;
        double left_peak      = rates[i+3].high;
        double head           = rates[i+2].low;
        double right_peak     = rates[i+1].high;
        double right_shoulder = rates[i].low;

        bool symmetry = MathAbs(left_shoulder - right_shoulder) < CHT_Tolerance * left_shoulder;
        bool head_low  = head < left_shoulder && head < right_shoulder;
        bool peaks_ok  = MathAbs(left_peak - right_peak) < CHT_Tolerance * left_peak;

        double neckline = (left_peak + right_peak) / 2.0;
        double current  = SymbolInfoDouble(Symbol(), SYMBOL_BID);

        if(symmetry && head_low && peaks_ok && current > neckline) return true;
    }
    return false;
}

bool IsHeadAndShouldersBearish(MqlRates &rates[])
{
    int size = ArraySize(rates);
    if(size < CHT_Lookback) return false;

    for(int i = 5; i < CHT_Lookback - 5; i++) {
        double left_shoulder  = rates[i+4].high;
        double left_trough    = rates[i+3].low;
        double head           = rates[i+2].high;
        double right_trough   = rates[i+1].low;
        double right_shoulder = rates[i].high;

        bool symmetry  = MathAbs(left_shoulder - right_shoulder) < CHT_Tolerance * left_shoulder;
        bool head_high = head > left_shoulder && head > right_shoulder;
        bool troughs_ok = MathAbs(left_trough - right_trough) < CHT_Tolerance * left_trough;

        double neckline = (left_trough + right_trough) / 2.0;
        double current  = SymbolInfoDouble(Symbol(), SYMBOL_ASK);

        if(symmetry && head_high && troughs_ok && current < neckline) return true;
    }
    return false;
}

bool IsDoubleBottom(MqlRates &rates[])
{
    int size = ArraySize(rates);
    if(size < CHT_Lookback) return false;
    for(int i = 5; i < CHT_Lookback - 2; i++) {
        double bottom1   = rates[i+2].low;
        double mid_high  = rates[i+1].high;
        double bottom2   = rates[i].low;
        if(MathAbs(bottom1 - bottom2) < CHT_Tolerance * bottom1 && mid_high > bottom1) {
            double current = SymbolInfoDouble(Symbol(), SYMBOL_BID);
            if(current > mid_high) return true;
        }
    }
    return false;
}

bool IsDoubleTop(MqlRates &rates[])
{
    int size = ArraySize(rates);
    if(size < CHT_Lookback) return false;
    for(int i = 5; i < CHT_Lookback - 2; i++) {
        double top1     = rates[i+2].high;
        double mid_low  = rates[i+1].low;
        double top2     = rates[i].high;
        if(MathAbs(top1 - top2) < CHT_Tolerance * top1 && mid_low < top1) {
            double current = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
            if(current < mid_low) return true;
        }
    }
    return false;
}

int CheckChartPatternsBuy()
{
    int confirmations = 0;
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    int copied = CopyRates(Symbol(), CHT_Timeframe, 0, CHT_Lookback, rates);
    if(copied < CHT_Lookback) { DebugPrint("ChartPatterns: not enough data"); return 0; }
    if(IsHeadAndShouldersBullish(rates)) confirmations++;
    if(IsDoubleBottom(rates)) confirmations++;
    DebugPrint("Chart pattern buy confirmations: " + IntegerToString(confirmations));
    return confirmations;
}

int CheckChartPatternsShort()
{
    int confirmations = 0;
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    int copied = CopyRates(Symbol(), CHT_Timeframe, 0, CHT_Lookback, rates);
    if(copied < CHT_Lookback) { DebugPrint("ChartPatterns: not enough data"); return 0; }
    if(IsHeadAndShouldersBearish(rates)) confirmations++;
    if(IsDoubleTop(rates)) confirmations++;
    DebugPrint("Chart pattern sell confirmations: " + IntegerToString(confirmations));
    return confirmations;
}
