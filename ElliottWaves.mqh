//+------------------------------------------------------------------+
//|                                               ElliottWaves.mqh   |
//|                                      Copyright 2023, Gold Trader  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Gold Trader"
#property strict

#import "AlaaGoldEA.mq5"
   void DebugPrint(string message);
#import

extern ENUM_TIMEFRAMES EW_Timeframe;
extern int EW_Lookback;

bool IsImpulsiveWaveBullish(MqlRates &rates[], int start_idx)
{
    int size = ArraySize(rates);
    if(start_idx + 5 >= size) return false;

    double w1_start = rates[start_idx + 4].low;
    double w1_end   = rates[start_idx + 3].high;
    double w2_end   = rates[start_idx + 2].low;
    double w3_end   = rates[start_idx + 1].high;
    double w4_end   = rates[start_idx].low;

    if(w1_end <= w1_start) return false;
    if(w2_end <= w1_start) return false;
    if(w3_end <= w1_end)   return false;
    if(w4_end >= w1_end)   return false;

    return true;
}

bool IsImpulsiveWaveBearish(MqlRates &rates[], int start_idx)
{
    int size = ArraySize(rates);
    if(start_idx + 5 >= size) return false;

    double w1_start = rates[start_idx + 4].high;
    double w1_end   = rates[start_idx + 3].low;
    double w2_end   = rates[start_idx + 2].high;
    double w3_end   = rates[start_idx + 1].low;
    double w4_end   = rates[start_idx].high;

    if(w1_end >= w1_start) return false;
    if(w2_end >= w1_start) return false;
    if(w3_end >= w1_end)   return false;
    if(w4_end <= w1_end)   return false;

    return true;
}

bool IsWave5BuySetup(MqlRates &rates[])
{
    int size = ArraySize(rates);
    if(size < EW_Lookback) { DebugPrint("ElliottWaves: not enough data"); return false; }

    for(int i = 5; i < EW_Lookback - 5; i++)
        if(IsImpulsiveWaveBullish(rates, i)) return true;

    return false;
}

bool IsWave5SellSetup(MqlRates &rates[])
{
    int size = ArraySize(rates);
    if(size < EW_Lookback) { DebugPrint("ElliottWaves: not enough data"); return false; }

    for(int i = 5; i < EW_Lookback - 5; i++)
        if(IsImpulsiveWaveBearish(rates, i)) return true;

    return false;
}

int CheckElliottWavesBuy()
{
    int confirmations = 0;
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    int copied = CopyRates(Symbol(), EW_Timeframe, 0, EW_Lookback, rates);
    if(copied < EW_Lookback) { DebugPrint("ElliottWaves: not enough data copied"); return 0; }
    if(IsWave5BuySetup(rates)) confirmations++;
    DebugPrint("Elliott Waves buy confirmations: " + IntegerToString(confirmations));
    return confirmations;
}

int CheckElliottWavesShort()
{
    int confirmations = 0;
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    int copied = CopyRates(Symbol(), EW_Timeframe, 0, EW_Lookback, rates);
    if(copied < EW_Lookback) { DebugPrint("ElliottWaves: not enough data copied"); return 0; }
    if(IsWave5SellSetup(rates)) confirmations++;
    DebugPrint("Elliott Waves sell confirmations: " + IntegerToString(confirmations));
    return confirmations;
}
