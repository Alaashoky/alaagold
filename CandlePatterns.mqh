//+------------------------------------------------------------------+
//|                                                CandlePatterns.mqh |
//|                                       Copyright 2023, Gold Trader |
//|                                                                   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Gold Trader"
#property strict

// Declare external variables needed
extern ENUM_TIMEFRAMES CP_Timeframe;

// Static variables for caching
static datetime s_cp_last_candle_time = 0;
static int s_cp_cached_buy_count = -1;
static int s_cp_cached_sell_count = -1;
static bool s_cp_pattern_cache[10] = {false, false, false, false, false, false, false, false, false, false};

// The DebugPrint function must be defined in the main file
#import "AlaaGoldEA.mq5"
void DebugPrint(string message);
bool GetDebugMode();
void ResetExternalCandleCache();
#import

//+------------------------------------------------------------------+
//| Check candlestick patterns for buying                             |
//+------------------------------------------------------------------+
int CheckCandlePatternsBuy()
{
    // Use caching for performance improvement
    datetime current_time = TimeCurrent();

    // If we are still in the same candle and cached result exists
    if(current_time - s_cp_last_candle_time < PeriodSeconds(CP_Timeframe) && s_cp_cached_buy_count >= 0)
        return s_cp_cached_buy_count;

    int confirmations = 0;

    // Get candlestick data
    MqlRates rates[];
    ArrayResize(rates, 10);
    ArraySetAsSeries(rates, true);
    int copied = CopyRates(Symbol(), CP_Timeframe, 0, 10, rates);

    if(copied < 3) {
        DebugPrint("Error: Not enough data copied. Copied: " + IntegerToString(copied));
        s_cp_last_candle_time = current_time;
        s_cp_cached_buy_count = 0;
        return 0;
    }

    for(int i=0; i<10; i++)
        s_cp_pattern_cache[i] = false;

    if(IsBullishPinBar(rates)) { s_cp_pattern_cache[0] = true; confirmations++; }
    if(IsBullishInsideBar(rates)) { s_cp_pattern_cache[1] = true; confirmations++; }
    if(IsHammer(rates)) { s_cp_pattern_cache[2] = true; confirmations++; }
    if(IsBullishEngulfing(rates)) { s_cp_pattern_cache[3] = true; confirmations++; }
    if(IsMorningStar(rates)) { s_cp_pattern_cache[4] = true; confirmations++; }

    s_cp_last_candle_time = current_time;
    s_cp_cached_buy_count = confirmations;
    return confirmations;
}

//+------------------------------------------------------------------+
//| Check candlestick patterns for selling                            |
//+------------------------------------------------------------------+
int CheckCandlePatternsShort()
{
    datetime current_time = TimeCurrent();

    if(current_time - s_cp_last_candle_time < PeriodSeconds(CP_Timeframe) && s_cp_cached_sell_count >= 0)
        return s_cp_cached_sell_count;

    int confirmations = 0;

    MqlRates rates[];
    ArrayResize(rates, 10);
    ArraySetAsSeries(rates, true);
    int copied = CopyRates(Symbol(), CP_Timeframe, 0, 10, rates);

    if(copied < 3) {
        DebugPrint("Error: Not enough data copied. Copied: " + IntegerToString(copied));
        s_cp_last_candle_time = current_time;
        s_cp_cached_sell_count = 0;
        return 0;
    }

    if(IsBearishPinBar(rates)) { s_cp_pattern_cache[5] = true; confirmations++; }
    if(IsBearishInsideBar(rates)) { s_cp_pattern_cache[6] = true; confirmations++; }
    if(IsShootingStar(rates)) { s_cp_pattern_cache[7] = true; confirmations++; }
    if(IsBearishEngulfing(rates)) { s_cp_pattern_cache[8] = true; confirmations++; }
    if(IsEveningStar(rates)) { s_cp_pattern_cache[9] = true; confirmations++; }

    s_cp_last_candle_time = current_time;
    s_cp_cached_sell_count = confirmations;
    return confirmations;
}

bool IsBullishPinBar(MqlRates &rates[])
{
    if(s_cp_last_candle_time > 0 && s_cp_pattern_cache[0]) return true;
    double body = MathAbs(rates[0].close - rates[0].open);
    double upper_shadow = rates[0].high - MathMax(rates[0].open, rates[0].close);
    double lower_shadow = MathMin(rates[0].open, rates[0].close) - rates[0].low;
    double total_length = rates[0].high - rates[0].low;
    return (lower_shadow > 2*body && lower_shadow > upper_shadow && lower_shadow > 0.6*total_length);
}

bool IsBearishPinBar(MqlRates &rates[])
{
    double body = MathAbs(rates[0].close - rates[0].open);
    double upper_shadow = rates[0].high - MathMax(rates[0].open, rates[0].close);
    double lower_shadow = MathMin(rates[0].open, rates[0].close) - rates[0].low;
    double total_length = rates[0].high - rates[0].low;
    return (upper_shadow > 2*body && upper_shadow > lower_shadow && upper_shadow > 0.6*total_length);
}

bool IsBullishInsideBar(MqlRates &rates[])
{
    return (rates[0].high < rates[1].high && rates[0].low > rates[1].low && rates[0].close > rates[0].open);
}

bool IsBearishInsideBar(MqlRates &rates[])
{
    return (rates[0].high < rates[1].high && rates[0].low > rates[1].low && rates[0].close < rates[0].open);
}

bool IsHammer(MqlRates &rates[])
{
    double body = MathAbs(rates[0].close - rates[0].open);
    double upper_shadow = rates[0].high - MathMax(rates[0].open, rates[0].close);
    double lower_shadow = MathMin(rates[0].open, rates[0].close) - rates[0].low;
    double total_length = rates[0].high - rates[0].low;
    return (lower_shadow > 2*body && lower_shadow > upper_shadow && lower_shadow > 0.6*total_length && rates[0].close > rates[0].open);
}

bool IsShootingStar(MqlRates &rates[])
{
    double body = MathAbs(rates[0].close - rates[0].open);
    double upper_shadow = rates[0].high - MathMax(rates[0].open, rates[0].close);
    double lower_shadow = MathMin(rates[0].open, rates[0].close) - rates[0].low;
    double total_length = rates[0].high - rates[0].low;
    return (upper_shadow > 2*body && upper_shadow > lower_shadow && upper_shadow > 0.6*total_length && rates[0].close < rates[0].open);
}

bool IsBullishEngulfing(MqlRates &rates[])
{
    if(ArraySize(rates) < 2) return false;
    double body1 = MathAbs(rates[1].close - rates[1].open);
    double body2 = MathAbs(rates[0].close - rates[0].open);
    bool bearish_candle = rates[1].close < rates[1].open;
    bool bullish_candle = rates[0].close > rates[0].open;
    bool engulfs_body  = rates[0].close >= rates[1].open && rates[0].open <= rates[1].close;
    bool significant_size = body2 > body1 * 0.8;
    return bearish_candle && bullish_candle && (engulfs_body || significant_size);
}

bool IsBearishEngulfing(MqlRates &rates[])
{
    if(ArraySize(rates) < 2) return false;
    double body1 = MathAbs(rates[1].close - rates[1].open);
    double body2 = MathAbs(rates[0].close - rates[0].open);
    bool bullish_candle = rates[1].close > rates[1].open;
    bool bearish_candle = rates[0].close < rates[0].open;
    bool engulfs_body  = rates[0].close <= rates[1].close && rates[0].open >= rates[1].open;
    bool significant_size = body2 > body1 * 0.8;
    return bullish_candle && bearish_candle && (engulfs_body || significant_size);
}

bool IsMorningStar(MqlRates &rates[])
{
    if(ArraySize(rates) < 3) return false;
    double body1 = MathAbs(rates[2].close - rates[2].open);
    double body2 = MathAbs(rates[1].close - rates[1].open);
    bool bearish_first = rates[2].close < rates[2].open;
    bool small_middle  = body2 < body1 * 0.5;
    bool bullish_last  = rates[0].close > rates[0].open;
    bool good_recovery = rates[0].close > ((rates[2].open + rates[2].close) / 2.0) * 0.9;
    return bearish_first && small_middle && bullish_last && good_recovery;
}

bool IsEveningStar(MqlRates &rates[])
{
    if(ArraySize(rates) < 3) return false;
    double body1 = MathAbs(rates[2].close - rates[2].open);
    double body2 = MathAbs(rates[1].close - rates[1].open);
    bool bullish_first = rates[2].close > rates[2].open;
    bool small_middle  = body2 < body1 * 0.5;
    bool bearish_last  = rates[0].close < rates[0].open;
    bool good_decline  = rates[0].close < ((rates[2].open + rates[2].close) / 2.0) * 1.1;
    return bullish_first && small_middle && bearish_last && good_decline;
}

int FindCandlestickPattern(MqlRates &rates[], int bullish_pattern)
{
    if(ArraySize(rates) < 3) return 0;
    if(bullish_pattern > 0) {
        if(IsBullishEngulfing(rates) || IsHammer(rates) || IsMorningStar(rates)) return 1;
    } else {
        if(IsBearishEngulfing(rates) || IsShootingStar(rates) || IsEveningStar(rates)) return 1;
    }
    return 0;
}

bool IsThreeWhiteSoldiers(MqlRates &rates[])
{
    int size = ArraySize(rates);
    if(size < 3) { DebugPrint("Error in IsThreeWhiteSoldiers: Array size is too small: " + IntegerToString(size)); return false; }
    bool cond1  = rates[2].close > rates[2].open;
    bool cond2  = rates[1].close > rates[1].open;
    bool cond3  = rates[0].close > rates[0].open;
    bool cond4  = rates[1].close > rates[2].close;
    bool cond5  = rates[0].close > rates[1].close;
    bool cond6  = rates[1].open  > rates[2].open;
    bool cond7  = rates[0].open  > rates[1].open;
    bool cond8  = (rates[0].close-rates[0].open) > 0.7*(rates[0].high-rates[0].low);
    bool cond9  = (rates[1].close-rates[1].open) > 0.7*(rates[1].high-rates[1].low);
    bool cond10 = (rates[2].close-rates[2].open) > 0.7*(rates[2].high-rates[2].low);
    return cond1&&cond2&&cond3&&cond4&&cond5&&cond6&&cond7&&cond8&&cond9&&cond10;
}

bool IsThreeBlackCrows(MqlRates &rates[])
{
    int size = ArraySize(rates);
    if(size < 3) { DebugPrint("Error in IsThreeBlackCrows: Array size is too small: " + IntegerToString(size)); return false; }
    bool cond1  = rates[2].close < rates[2].open;
    bool cond2  = rates[1].close < rates[1].open;
    bool cond3  = rates[0].close < rates[0].open;
    bool cond4  = rates[1].close < rates[2].close;
    bool cond5  = rates[0].close < rates[1].close;
    bool cond6  = rates[1].open  < rates[2].open;
    bool cond7  = rates[0].open  < rates[1].open;
    bool cond8  = (rates[0].open-rates[0].close) > 0.7*(rates[0].high-rates[0].low);
    bool cond9  = (rates[1].open-rates[1].close) > 0.7*(rates[1].high-rates[1].low);
    bool cond10 = (rates[2].open-rates[2].close) > 0.7*(rates[2].high-rates[2].low);
    return cond1&&cond2&&cond3&&cond4&&cond5&&cond6&&cond7&&cond8&&cond9&&cond10;
}

void ResetCandlePatternsCache()
{
    s_cp_last_candle_time = 0;
    s_cp_cached_buy_count = -1;
    s_cp_cached_sell_count = -1;
    for(int i=0; i<10; i++) s_cp_pattern_cache[i] = false;
    ResetExternalCandleCache();
}

void CheckExitConditions() {}
