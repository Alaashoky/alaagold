//+------------------------------------------------------------------+
//|                                            HarmonicPatterns.mqh  |
//|                                      Copyright 2023, Gold Trader  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Gold Trader"
#property strict

#import "AlaaGoldEA.mq5"
   void DebugPrint(string message);
#import

extern ENUM_TIMEFRAMES HP_Timeframe;
extern int HP_Lookback;
extern double HP_Tolerance;

bool IsGartleyBullish(MqlRates &rates[])
{
    int size = ArraySize(rates);
    if(size < HP_Lookback) return false;

    int x_idx = -1, a_idx = -1, b_idx = -1, c_idx = -1;
    for(int i = HP_Lookback - 2; i > 3; i--)
        if(rates[i].high > rates[i+1].high && rates[i].high > rates[i-1].high && x_idx == -1) { x_idx = i; break; }
    if(x_idx == -1) return false;

    for(int i = x_idx - 1; i > 1; i--)
        if(rates[i].low < rates[i+1].low && rates[i].low < rates[i-1].low) { a_idx = i; break; }
    if(a_idx == -1) return false;

    double xa = rates[x_idx].high - rates[a_idx].low;
    double xb_retracement = 0.618;

    for(int i = a_idx - 1; i > 1; i--)
        if(rates[i].high > rates[i+1].high && rates[i].high > rates[i-1].high) {
            double ab = rates[i].high - rates[a_idx].low;
            if(MathAbs(ab/xa - xb_retracement) < HP_Tolerance) { b_idx = i; break; }
        }
    if(b_idx == -1) return false;

    for(int i = b_idx - 1; i > 1; i--)
        if(rates[i].low < rates[i+1].low && rates[i].low < rates[i-1].low) { c_idx = i; break; }
    if(c_idx == -1) return false;

    double ad_retracement = 0.786;
    double d_level        = rates[x_idx].high - xa * ad_retracement;
    double current_price  = SymbolInfoDouble(Symbol(), SYMBOL_BID);

    return (MathAbs(current_price - d_level) < HP_Tolerance * rates[x_idx].high);
}

bool IsGartleyBearish(MqlRates &rates[])
{
    int size = ArraySize(rates);
    if(size < HP_Lookback) return false;

    int x_idx = -1, a_idx = -1, b_idx = -1, c_idx = -1;
    for(int i = HP_Lookback - 2; i > 3; i--)
        if(rates[i].low < rates[i+1].low && rates[i].low < rates[i-1].low && x_idx == -1) { x_idx = i; break; }
    if(x_idx == -1) return false;

    for(int i = x_idx - 1; i > 1; i--)
        if(rates[i].high > rates[i+1].high && rates[i].high > rates[i-1].high) { a_idx = i; break; }
    if(a_idx == -1) return false;

    double xa            = rates[a_idx].high - rates[x_idx].low;
    double xb_retracement = 0.618;

    for(int i = a_idx - 1; i > 1; i--)
        if(rates[i].low < rates[i+1].low && rates[i].low < rates[i-1].low) {
            double ab = rates[a_idx].high - rates[i].low;
            if(MathAbs(ab/xa - xb_retracement) < HP_Tolerance) { b_idx = i; break; }
        }
    if(b_idx == -1) return false;

    for(int i = b_idx - 1; i > 1; i--)
        if(rates[i].high > rates[i+1].high && rates[i].high > rates[i-1].high) { c_idx = i; break; }
    if(c_idx == -1) return false;

    double ad_retracement = 0.786;
    double d_level        = rates[x_idx].low + xa * ad_retracement;
    double current_price  = SymbolInfoDouble(Symbol(), SYMBOL_ASK);

    return (MathAbs(current_price - d_level) < HP_Tolerance * rates[a_idx].high);
}

int CheckHarmonicPatternsBuy()
{
    int confirmations = 0;
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    int copied = CopyRates(Symbol(), HP_Timeframe, 0, HP_Lookback, rates);
    if(copied < HP_Lookback) { DebugPrint("HarmonicPatterns: not enough data"); return 0; }
    if(IsGartleyBullish(rates)) confirmations++;
    DebugPrint("Harmonic pattern buy confirmations: " + IntegerToString(confirmations));
    return confirmations;
}

int CheckHarmonicPatternsShort()
{
    int confirmations = 0;
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    int copied = CopyRates(Symbol(), HP_Timeframe, 0, HP_Lookback, rates);
    if(copied < HP_Lookback) { DebugPrint("HarmonicPatterns: not enough data"); return 0; }
    if(IsGartleyBearish(rates)) confirmations++;
    DebugPrint("Harmonic pattern sell confirmations: " + IntegerToString(confirmations));
    return confirmations;
}
