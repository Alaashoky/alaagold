//+------------------------------------------------------------------+
//|                                                 Divergence.mqh   |
//|                                      Copyright 2023, Gold Trader  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Gold Trader"
#property strict

#import "AlaaGoldEA.mq5"
   void DebugPrint(string message);
#import

extern ENUM_TIMEFRAMES DIV_Timeframe;
extern int DIV_RSI_Period;
extern int DIV_MACD_Fast;
extern int DIV_MACD_Slow;
extern int DIV_MACD_Signal;
extern int DIV_Lookback;

bool IsBullishRSIDivergence()
{
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    if(CopyRates(Symbol(), DIV_Timeframe, 0, DIV_Lookback, rates) < DIV_Lookback) return false;

    int rsi_handle = iRSI(Symbol(), DIV_Timeframe, DIV_RSI_Period, PRICE_CLOSE);
    if(rsi_handle == INVALID_HANDLE) { DebugPrint("Divergence RSI handle invalid"); return false; }
    double rsi[];
    ArraySetAsSeries(rsi, true);
    if(CopyBuffer(rsi_handle, 0, 0, DIV_Lookback, rsi) < DIV_Lookback) { IndicatorRelease(rsi_handle); return false; }
    IndicatorRelease(rsi_handle);

    int price_low1_idx = 0, price_low2_idx = 0;
    for(int i = 1; i < DIV_Lookback - 1; i++)
        if(rates[i].low < rates[i+1].low && rates[i].low < rates[i-1].low)
            { if(price_low1_idx == 0) price_low1_idx = i; else { price_low2_idx = i; break; } }

    if(price_low1_idx == 0 || price_low2_idx == 0) return false;
    bool price_makes_lower_low = rates[price_low1_idx].low < rates[price_low2_idx].low;
    bool rsi_makes_higher_low  = rsi[price_low1_idx]    > rsi[price_low2_idx];
    return (price_makes_lower_low && rsi_makes_higher_low);
}

bool IsBearishRSIDivergence()
{
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    if(CopyRates(Symbol(), DIV_Timeframe, 0, DIV_Lookback, rates) < DIV_Lookback) return false;

    int rsi_handle = iRSI(Symbol(), DIV_Timeframe, DIV_RSI_Period, PRICE_CLOSE);
    if(rsi_handle == INVALID_HANDLE) { DebugPrint("Divergence RSI handle invalid"); return false; }
    double rsi[];
    ArraySetAsSeries(rsi, true);
    if(CopyBuffer(rsi_handle, 0, 0, DIV_Lookback, rsi) < DIV_Lookback) { IndicatorRelease(rsi_handle); return false; }
    IndicatorRelease(rsi_handle);

    int price_high1_idx = 0, price_high2_idx = 0;
    for(int i = 1; i < DIV_Lookback - 1; i++)
        if(rates[i].high > rates[i+1].high && rates[i].high > rates[i-1].high)
            { if(price_high1_idx == 0) price_high1_idx = i; else { price_high2_idx = i; break; } }

    if(price_high1_idx == 0 || price_high2_idx == 0) return false;
    bool price_makes_higher_high = rates[price_high1_idx].high > rates[price_high2_idx].high;
    bool rsi_makes_lower_high    = rsi[price_high1_idx]        < rsi[price_high2_idx];
    return (price_makes_higher_high && rsi_makes_lower_high);
}

int CheckDivergenceBuy()
{
    int confirmations = 0;
    if(IsBullishRSIDivergence()) confirmations++;
    DebugPrint("Divergence buy confirmations: " + IntegerToString(confirmations));
    return confirmations;
}

int CheckDivergenceShort()
{
    int confirmations = 0;
    if(IsBearishRSIDivergence()) confirmations++;
    DebugPrint("Divergence sell confirmations: " + IntegerToString(confirmations));
    return confirmations;
}
