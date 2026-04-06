//+------------------------------------------------------------------+
//|                                                WolfeWaves.mqh    |
//|                                      Copyright 2023, Gold Trader  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Gold Trader"
#property strict

#import "AlaaGoldEA.mq5"
   void DebugPrint(string message);
#import

extern ENUM_TIMEFRAMES WW_Timeframe;
extern int WW_Lookback;
extern double WW_Tolerance;

bool IsBullishWolfeWave(MqlRates &rates[])
{
    int size = ArraySize(rates);
    if(size < WW_Lookback) { DebugPrint("WolfeWaves: not enough data"); return false; }

    for(int i = 10; i < WW_Lookback - 5; i++) {
        double p1 = rates[i+4].high;
        double p2 = rates[i+3].low;
        double p3 = rates[i+2].high;
        double p4 = rates[i+1].low;
        double p5 = rates[i].high;

        if(p3 < p1 && p4 < p2 && p5 < p3) {
            double slope_1_3 = (p3 - p1) / 2.0;
            double expected_5 = p3 + slope_1_3;
            if(MathAbs(p5 - expected_5) < WW_Tolerance * p5) {
                double current = SymbolInfoDouble(Symbol(), SYMBOL_BID);
                if(current > p4) return true;
            }
        }
    }
    return false;
}

bool IsBearishWolfeWave(MqlRates &rates[])
{
    int size = ArraySize(rates);
    if(size < WW_Lookback) { DebugPrint("WolfeWaves: not enough data"); return false; }

    for(int i = 10; i < WW_Lookback - 5; i++) {
        double p1 = rates[i+4].low;
        double p2 = rates[i+3].high;
        double p3 = rates[i+2].low;
        double p4 = rates[i+1].high;
        double p5 = rates[i].low;

        if(p3 > p1 && p4 > p2 && p5 > p3) {
            double slope_1_3 = (p3 - p1) / 2.0;
            double expected_5 = p3 + slope_1_3;
            if(MathAbs(p5 - expected_5) < WW_Tolerance * p5) {
                double current = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
                if(current < p4) return true;
            }
        }
    }
    return false;
}

int CheckWolfeWavesBuy()
{
    int confirmations = 0;
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    int copied = CopyRates(Symbol(), WW_Timeframe, 0, WW_Lookback, rates);
    if(copied < WW_Lookback) { DebugPrint("WolfeWaves: not enough data copied"); return 0; }
    if(IsBullishWolfeWave(rates)) confirmations++;
    DebugPrint("Wolfe Waves buy confirmations: " + IntegerToString(confirmations));
    return confirmations;
}

int CheckWolfeWavesShort()
{
    int confirmations = 0;
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    int copied = CopyRates(Symbol(), WW_Timeframe, 0, WW_Lookback, rates);
    if(copied < WW_Lookback) { DebugPrint("WolfeWaves: not enough data copied"); return 0; }
    if(IsBearishWolfeWave(rates)) confirmations++;
    DebugPrint("Wolfe Waves sell confirmations: " + IntegerToString(confirmations));
    return confirmations;
}
