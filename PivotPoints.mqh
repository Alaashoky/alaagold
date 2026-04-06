//+------------------------------------------------------------------+
//|                                                 PivotPoints.mqh  |
//|                                      Copyright 2023, Gold Trader  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Gold Trader"
#property strict

#import "AlaaGoldEA.mq5"
   void DebugPrint(string message);
#import

extern ENUM_TIMEFRAMES PP_Timeframe;

double pp_pivot = 0, pp_r1 = 0, pp_r2 = 0, pp_r3 = 0;
double pp_s1 = 0, pp_s2 = 0, pp_s3 = 0;

void CalculatePivotPoints()
{
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    int copied = CopyRates(Symbol(), PP_Timeframe, 1, 1, rates);
    if(copied < 1) { DebugPrint("PivotPoints: failed to copy rates"); return; }

    double high  = rates[0].high;
    double low   = rates[0].low;
    double close = rates[0].close;

    pp_pivot = (high + low + close) / 3.0;
    pp_r1    = 2.0 * pp_pivot - low;
    pp_s1    = 2.0 * pp_pivot - high;
    pp_r2    = pp_pivot + (high - low);
    pp_s2    = pp_pivot - (high - low);
    pp_r3    = high + 2.0 * (pp_pivot - low);
    pp_s3    = low  - 2.0 * (high - pp_pivot);

    DebugPrint(StringFormat("Pivot=%.5f R1=%.5f R2=%.5f S1=%.5f S2=%.5f", pp_pivot, pp_r1, pp_r2, pp_s1, pp_s2));
}

int CheckPivotPointsBuy()
{
    if(pp_pivot == 0) CalculatePivotPoints();
    int    confirmations = 0;
    double price         = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    double tolerance     = 0.002 * price;

    if(MathAbs(price - pp_s1) < tolerance && price > pp_s1) confirmations++;
    if(MathAbs(price - pp_s2) < tolerance && price > pp_s2) confirmations++;
    if(price > pp_pivot) confirmations++;

    DebugPrint("Pivot buy confirmations: " + IntegerToString(confirmations));
    return confirmations;
}

int CheckPivotPointsShort()
{
    if(pp_pivot == 0) CalculatePivotPoints();
    int    confirmations = 0;
    double price         = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    double tolerance     = 0.002 * price;

    if(MathAbs(price - pp_r1) < tolerance && price < pp_r1) confirmations++;
    if(MathAbs(price - pp_r2) < tolerance && price < pp_r2) confirmations++;
    if(price < pp_pivot) confirmations++;

    DebugPrint("Pivot sell confirmations: " + IntegerToString(confirmations));
    return confirmations;
}
