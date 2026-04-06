//+------------------------------------------------------------------+
//|                                             VolumeAnalysis.mqh   |
//|                                      Copyright 2023, Gold Trader  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Gold Trader"
#property strict

#import "AlaaGoldEA.mq5"
   void DebugPrint(string message);
#import

extern ENUM_TIMEFRAMES VA_Timeframe;
extern int VA_MA_Period;

double GetAverageVolume(int periods = 20)
{
    long vol[];
    ArraySetAsSeries(vol, true);
    int copied = CopyTickVolume(Symbol(), VA_Timeframe, 1, periods, vol);
    if(copied < periods) { DebugPrint("VolumeAnalysis: not enough volume data"); return 0; }
    double sum = 0;
    for(int i = 0; i < periods; i++) sum += (double)vol[i];
    return sum / periods;
}

double GetCurrentVolume()
{
    long vol[];
    ArraySetAsSeries(vol, true);
    if(CopyTickVolume(Symbol(), VA_Timeframe, 0, 1, vol) < 1) return 0;
    return (double)vol[0];
}

bool IsVolumeIncreasing()
{
    long vol[];
    ArraySetAsSeries(vol, true);
    if(CopyTickVolume(Symbol(), VA_Timeframe, 0, 3, vol) < 3) return false;
    return (vol[0] > vol[1] && vol[1] > vol[2]);
}

bool IsVolumeAboveAverage()
{
    double avg = GetAverageVolume();
    if(avg <= 0) return false;
    return (GetCurrentVolume() > avg * 1.2);
}

bool IsBullishVolumePattern()
{
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    if(CopyRates(Symbol(), VA_Timeframe, 0, 3, rates) < 3) return false;
    long vol[];
    ArraySetAsSeries(vol, true);
    if(CopyTickVolume(Symbol(), VA_Timeframe, 0, 3, vol) < 3) return false;
    bool bullish_candle = rates[0].close > rates[0].open;
    bool high_volume    = (double)vol[0] > GetAverageVolume() * 1.1;
    return (bullish_candle && high_volume);
}

bool IsBearishVolumePattern()
{
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    if(CopyRates(Symbol(), VA_Timeframe, 0, 3, rates) < 3) return false;
    long vol[];
    ArraySetAsSeries(vol, true);
    if(CopyTickVolume(Symbol(), VA_Timeframe, 0, 3, vol) < 3) return false;
    bool bearish_candle = rates[0].close < rates[0].open;
    bool high_volume    = (double)vol[0] > GetAverageVolume() * 1.1;
    return (bearish_candle && high_volume);
}

int CheckVolumeAnalysisBuy()
{
    int confirmations = 0;
    if(IsVolumeAboveAverage()) confirmations++;
    if(IsBullishVolumePattern()) confirmations++;
    if(IsVolumeIncreasing()) confirmations++;
    DebugPrint("Volume buy confirmations: " + IntegerToString(confirmations));
    return confirmations;
}

int CheckVolumeAnalysisShort()
{
    int confirmations = 0;
    if(IsVolumeAboveAverage()) confirmations++;
    if(IsBearishVolumePattern()) confirmations++;
    if(IsVolumeIncreasing()) confirmations++;
    DebugPrint("Volume sell confirmations: " + IntegerToString(confirmations));
    return confirmations;
}
