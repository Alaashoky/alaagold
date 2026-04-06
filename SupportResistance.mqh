//+------------------------------------------------------------------+
//|                                         SupportResistance.mqh    |
//|                                      Copyright 2023, Gold Trader  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Gold Trader"
#property strict

ENUM_TIMEFRAMES SR_Timeframe = PERIOD_H1;

double support_levels[10];
double resistance_levels[10];
int    support_count    = 0;
int    resistance_count = 0;

void SetSRTimeframe(ENUM_TIMEFRAMES timeframe) { SR_Timeframe = timeframe; }

void IdentifySupportResistanceLevels()
{
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    int copied = CopyRates(Symbol(), SR_Timeframe, 0, 200, rates);

    if(copied < 100) { Print("Unable to retrieve enough data for support and resistance analysis"); return; }

    support_count = 0;
    resistance_count = 0;

    for(int i = 10; i < 100 && i + 2 < copied && support_count < 10; i++) {
        if(rates[i].low < rates[i-1].low && rates[i].low < rates[i+1].low &&
           rates[i].low < rates[i-2].low && rates[i].low < rates[i+2].low)
        {
            if(IsSupportValid(rates, rates[i].low)) { support_levels[support_count] = rates[i].low; support_count++; }
        }
    }

    for(int i = 10; i < 100 && i + 2 < copied && resistance_count < 10; i++) {
        if(rates[i].high > rates[i-1].high && rates[i].high > rates[i+1].high &&
           rates[i].high > rates[i-2].high && rates[i].high > rates[i+2].high)
        {
            if(IsResistanceValid(rates, rates[i].high)) { resistance_levels[resistance_count] = rates[i].high; resistance_count++; }
        }
    }

    if(support_count > 1) {
        for(int i = 0; i < support_count - 1; i++)
            for(int j = i+1; j < support_count; j++)
                if(support_levels[i] > support_levels[j]) { double t = support_levels[i]; support_levels[i] = support_levels[j]; support_levels[j] = t; }
    }

    if(resistance_count > 1) {
        for(int i = 0; i < resistance_count - 1; i++)
            for(int j = i+1; j < resistance_count; j++)
                if(resistance_levels[i] < resistance_levels[j]) { double t = resistance_levels[i]; resistance_levels[i] = resistance_levels[j]; resistance_levels[j] = t; }
    }

    Print("Number of identified support levels: " + IntegerToString(support_count));
    Print("Number of identified resistance levels: " + IntegerToString(resistance_count));
}

bool IsSupportValid(MqlRates &rates[], double level)
{
    int test_count = 0;
    double tolerance = 0.0005 * level;
    int size = ArraySize(rates);
    for(int i = 0; i < size; i++)
        if(MathAbs(rates[i].low - level) <= tolerance) { test_count++; if(test_count >= 2) return true; }
    return false;
}

bool IsResistanceValid(MqlRates &rates[], double level)
{
    int test_count = 0;
    double tolerance = 0.0005 * level;
    int size = ArraySize(rates);
    for(int i = 0; i < size; i++)
        if(MathAbs(rates[i].high - level) <= tolerance) { test_count++; if(test_count >= 2) return true; }
    return false;
}

int CheckSupportResistanceBuy()
{
    if(support_count == 0) { IdentifySupportResistanceLevels(); if(support_count == 0) return 0; }
    double current_price = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    int confirmations = 0;
    for(int i = 0; i < support_count; i++)
        if(MathAbs(current_price - support_levels[i]) < 0.01*current_price && current_price > support_levels[i])
            { confirmations++; Print("Price is near support level " + DoubleToString(support_levels[i],2)); break; }
    for(int i = 0; i < resistance_count; i++)
        if(current_price > resistance_levels[i] && current_price < resistance_levels[i]*1.01)
            { confirmations++; Print("Price has broken the resistance level " + DoubleToString(resistance_levels[i],2)); break; }
    return confirmations;
}

int CheckSupportResistanceShort()
{
    if(resistance_count == 0) { IdentifySupportResistanceLevels(); if(resistance_count == 0) return 0; }
    double current_price = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    int confirmations = 0;
    for(int i = 0; i < resistance_count; i++)
        if(MathAbs(current_price - resistance_levels[i]) < 0.01*current_price && current_price < resistance_levels[i])
            { confirmations++; Print("Price is near resistance level " + DoubleToString(resistance_levels[i],2)); break; }
    for(int i = 0; i < support_count; i++)
        if(current_price < support_levels[i] && current_price > support_levels[i]*0.99)
            { confirmations++; Print("Price has broken the support level " + DoubleToString(support_levels[i],2)); break; }
    return confirmations;
}
