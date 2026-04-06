//+------------------------------------------------------------------+
//|                                                   AlaaGoldEA.mq5 |
//|                          AlaaGold EA - XAUUSD Gold Trading System |
//|                                      Copyright 2023, Gold Trader  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Gold Trader"
#property version   "1.00"
#property strict
#property description "AlaaGoldEA - Multi-Strategy Gold Trading Expert Advisor"
#property description "Supports 15+ trading strategies with weighted confirmations"

#include <Trade/Trade.mqh>

//--- Strategy module includes
#include "CandlePatterns.mqh"
#include "TrendPatterns.mqh"
#include "SupportResistance.mqh"
#include "PriceAction.mqh"
#include "Indicators.mqh"
#include "MACrossover.mqh"
#include "PivotPoints.mqh"
#include "TimeAnalysis.mqh"
#include "MultiTimeframe.mqh"
#include "VolumeAnalysis.mqh"
#include "Divergence.mqh"
#include "HarmonicPatterns.mqh"
#include "ElliottWaves.mqh"
#include "WolfeWaves.mqh"
#include "ChartPatterns.mqh"
#include "ChartPatternsImpl.mqh"

//=== General Settings ===
input string Symbol_Name          = "XAUUSD";          // Trading symbol
input bool   Debug_Mode           = false;              // Enable debug messages
input bool   UseSessionFilter     = true;               // Filter by trading sessions
input int    Magic_Number         = 123456;             // EA magic number

//=== Timeframes ===
input ENUM_TIMEFRAMES Main_Timeframe    = PERIOD_H1;   // Main analysis timeframe
input ENUM_TIMEFRAMES Higher_Timeframe  = PERIOD_H4;   // Higher timeframe for MTF
input ENUM_TIMEFRAMES Lower_Timeframe   = PERIOD_M15;  // Lower timeframe

//=== Risk Management ===
input double LotSize             = 0.1;                // Fixed lot size
input double StopLoss_Pips       = 100.0;              // SL in pips (fixed)
input double TakeProfit_Pips     = 150.0;              // TP in pips (fixed)
input double MaxRisk_Percent     = 1.0;                // Risk % per trade
input int    MaxOpenTrades       = 1;                  // Max open positions
input double Max_Lot_Size        = 0.3;                // Maximum lot size
input double Max_Position_Volume = 1.0;                // Maximum total volume
input bool   Use_Dynamic_StopLoss = true;              // Use ATR-based SL/TP
input double ATR_StopLoss_Multiplier  = 2.0;           // ATR multiplier for SL
input double ATR_TakeProfit_Multiplier = 4.0;          // ATR multiplier for TP
input double TrailingStop        = 30.0;               // Trailing stop in pips (0=off)

//=== Confirmation System ===
input int    Min_Confirmations   = 4;                  // Min weighted confirmations to trade

//=== Strategy Enable/Disable ===
input bool   Use_CandlePatterns  = true;
input bool   Use_TrendPatterns   = true;
input bool   Use_SupportResistance = true;
input bool   Use_PriceAction     = true;
input bool   Use_Indicators      = true;
input bool   Use_MACrossover     = true;
input bool   Use_PivotPoints     = true;
input bool   Use_TimeAnalysis    = true;
input bool   Use_MultiTimeframe  = true;
input bool   Use_VolumeAnalysis  = true;
input bool   Use_Divergence      = true;
input bool   Use_HarmonicPatterns = true;
input bool   Use_ElliottWaves    = true;
input bool   Use_WolfeWaves      = true;
input bool   Use_ChartPatterns   = true;

//=== Strategy Weights ===
input int    CandlePatterns_Weight  = 1;
input int    TrendPatterns_Weight   = 2;
input int    SupportResistance_Weight = 3;
input int    PriceAction_Weight     = 2;
input int    Indicators_Weight      = 1;
input int    MACrossover_Weight     = 2;
input int    PivotPoints_Weight     = 2;
input int    TimeAnalysis_Weight    = 1;
input int    MultiTimeframe_Weight  = 2;
input int    VolumeAnalysis_Weight  = 2;
input int    Divergence_Weight      = 3;
input int    HarmonicPatterns_Weight = 3;
input int    ElliottWaves_Weight    = 3;
input int    WolfeWaves_Weight      = 3;
input int    ChartPatterns_Weight   = 2;

//=== Indicator Settings ===
input int    RSI_Period         = 14;
input int    MACD_Fast          = 12;
input int    MACD_Slow          = 26;
input int    MACD_Signal        = 9;
input int    BB_Period          = 20;
input double BB_Deviation       = 2.0;
input int    ATR_Period         = 14;

//=== MA Settings ===
input int    MA_Fast_Period     = 20;
input int    MA_Slow_Period     = 50;
input int    MA_Trend_Period    = 200;
input ENUM_MA_METHOD  MA_Method = MODE_EMA;
input ENUM_APPLIED_PRICE MA_Applied_Price = PRICE_CLOSE;

//=== Multi-Timeframe Settings ===
input int    MTF_MA_Period      = 50;

//=== Session Times (GMT) ===
input bool   Trade_London_Session  = true;
input bool   Trade_NewYork_Session = true;
input bool   Trade_Tokyo_Session   = false;
input int    LondonOpenHour     = 8;
input int    LondonCloseHour    = 17;
input int    NewYorkOpenHour    = 13;
input int    NewYorkCloseHour   = 22;
input int    TokyoOpenHour      = 0;
input int    TokyoCloseHour     = 9;

//=== Harmonic Pattern Settings ===
input int    HP_Lookback_Bars   = 100;
input double HP_Tol             = 0.05;

//=== Elliott Wave Settings ===
input int    EW_Lookback_Bars   = 50;

//=== Wolfe Wave Settings ===
input int    WW_Lookback_Bars   = 60;
input double WW_Tol             = 0.02;

//=== Chart Pattern Settings ===
input int    CHT_Lookback_Bars  = 50;
input double CHT_Tol            = 0.005;

//=== Divergence Settings ===
input int    DIV_RSI_Period     = 14;
input int    DIV_MACD_Fast      = 12;
input int    DIV_MACD_Slow      = 26;
input int    DIV_MACD_Signal    = 9;
input int    DIV_Lookback_Bars  = 30;

//=== Volume Analysis Settings ===
input int    VA_MA_Period       = 20;

//+------------------------------------------------------------------+
//| Global non-input variables (referenced as extern in modules)     |
//+------------------------------------------------------------------+

// Module timeframes
ENUM_TIMEFRAMES CP_Timeframe   = PERIOD_H1;
ENUM_TIMEFRAMES TP_Timeframe   = PERIOD_H1;
ENUM_TIMEFRAMES PA_Timeframe   = PERIOD_H1;
ENUM_TIMEFRAMES IND_Timeframe  = PERIOD_H1;
ENUM_TIMEFRAMES MAC_Timeframe  = PERIOD_H1;
ENUM_TIMEFRAMES PP_Timeframe   = PERIOD_D1;
ENUM_TIMEFRAMES VA_Timeframe   = PERIOD_H1;
ENUM_TIMEFRAMES DIV_Timeframe  = PERIOD_H1;
ENUM_TIMEFRAMES HP_Timeframe   = PERIOD_H1;
ENUM_TIMEFRAMES EW_Timeframe   = PERIOD_H1;
ENUM_TIMEFRAMES WW_Timeframe   = PERIOD_H1;
ENUM_TIMEFRAMES CHT_Timeframe  = PERIOD_H1;
ENUM_TIMEFRAMES MTF_HigherTF   = PERIOD_H4;
ENUM_TIMEFRAMES MTF_LowerTF    = PERIOD_M15;

// Time analysis session settings
bool TA_UseSessionFilter  = true;
int  TA_LondonOpenHour    = 8;
int  TA_LondonCloseHour   = 17;
int  TA_NewYorkOpenHour   = 13;
int  TA_NewYorkCloseHour  = 22;
int  TA_TokyoOpenHour     = 0;
int  TA_TokyoCloseHour    = 9;

// Pattern/wave lookback and tolerance settings
int    HP_Lookback   = 100;
double HP_Tolerance  = 0.05;
int    EW_Lookback   = 50;
int    WW_Lookback   = 60;
double WW_Tolerance  = 0.02;
int    CHT_Lookback  = 50;
double CHT_Tolerance = 0.005;
int    DIV_Lookback  = 30;

// Backtest mode flag
bool is_backtest = false;

// Pivot point globals
double daily_pivot = 0, weekly_pivot = 0, monthly_pivot = 0;
double daily_s1 = 0, daily_s2 = 0, daily_s3 = 0;
double daily_r1 = 0, daily_r2 = 0, daily_r3 = 0;
double weekly_s1 = 0, weekly_s2 = 0, weekly_s3 = 0;
double weekly_r1 = 0, weekly_r2 = 0, weekly_r3 = 0;

//+------------------------------------------------------------------+
//| Internal state variables                                          |
//+------------------------------------------------------------------+
datetime g_last_candle_time = 0;
bool     g_debug_mode       = false;
CTrade   g_trade;

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
    g_debug_mode = Debug_Mode;

    // Detect backtest mode
    is_backtest = (MQLInfoInteger(MQL_TESTER) || MQLInfoInteger(MQL_OPTIMIZATION));

    // Propagate timeframes to modules
    CP_Timeframe  = Main_Timeframe;
    TP_Timeframe  = Main_Timeframe;
    PA_Timeframe  = Main_Timeframe;
    IND_Timeframe = Main_Timeframe;
    MAC_Timeframe = Main_Timeframe;
    PP_Timeframe  = PERIOD_D1;
    VA_Timeframe  = Main_Timeframe;
    DIV_Timeframe = Main_Timeframe;
    HP_Timeframe  = Main_Timeframe;
    EW_Timeframe  = Main_Timeframe;
    WW_Timeframe  = Main_Timeframe;
    CHT_Timeframe = Main_Timeframe;
    MTF_HigherTF  = Higher_Timeframe;
    MTF_LowerTF   = Lower_Timeframe;

    // Time analysis session configuration
    TA_UseSessionFilter  = UseSessionFilter;
    TA_LondonOpenHour    = LondonOpenHour;
    TA_LondonCloseHour   = LondonCloseHour;
    TA_NewYorkOpenHour   = NewYorkOpenHour;
    TA_NewYorkCloseHour  = NewYorkCloseHour;
    TA_TokyoOpenHour     = TokyoOpenHour;
    TA_TokyoCloseHour    = TokyoCloseHour;

    // Pattern lookbacks and tolerances
    HP_Lookback   = HP_Lookback_Bars;
    HP_Tolerance  = HP_Tol;
    EW_Lookback   = EW_Lookback_Bars;
    WW_Lookback   = WW_Lookback_Bars;
    WW_Tolerance  = WW_Tol;
    CHT_Lookback  = CHT_Lookback_Bars;
    CHT_Tolerance = CHT_Tol;
    DIV_Lookback  = DIV_Lookback_Bars;

    // Configure trade object
    g_trade.SetExpertMagicNumber(Magic_Number);
    g_trade.SetDeviationInPoints(10);

    // Initial support/resistance and pivot calculation
    SetSRTimeframe(Higher_Timeframe);
    IdentifySupportResistanceLevels();
    CalculatePivotPoints();

    DebugPrint("AlaaGoldEA initialized on " + Symbol());
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    DebugPrint("AlaaGoldEA deinitialized. Reason: " + IntegerToString(reason));
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Only process on new candle (bar)
    datetime candle_time = iTime(Symbol(), Main_Timeframe, 0);
    if(candle_time == g_last_candle_time) return;
    g_last_candle_time = candle_time;

    // Session and day checks
    if(!IsTradingTimeAllowed())
    {
        DebugPrint("Outside trading hours - skipping");
        return;
    }
    if(IsWeekend() || IsEndOfWeek())
    {
        DebugPrint("Weekend or end-of-week - skipping");
        return;
    }

    // Count open positions for this symbol
    int open_trades = 0;
    double open_volume = 0.0;
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(PositionGetSymbol(i) == Symbol())
        {
            open_trades++;
            open_volume += PositionGetDouble(POSITION_VOLUME);
        }
    }

    if(open_trades >= MaxOpenTrades)
    {
        DebugPrint("Max open trades reached: " + IntegerToString(open_trades));
        ManageOpenPositions();
        return;
    }
    if(open_volume >= Max_Position_Volume)
    {
        DebugPrint("Max position volume reached: " + DoubleToString(open_volume, 2));
        ManageOpenPositions();
        return;
    }

    // Refresh pivot points once per day
    CalculatePivotPoints();

    // Gather buy confirmations (weighted)
    int buy_conf = 0;

    if(Use_CandlePatterns)    buy_conf += CheckCandlePatternsBuy()     * CandlePatterns_Weight;
    if(Use_PriceAction)       buy_conf += CheckPriceActionBuy()        * PriceAction_Weight;
    if(Use_SupportResistance) buy_conf += CheckSupportResistanceBuy()  * SupportResistance_Weight;
    if(Use_Indicators)        buy_conf += CheckIndicatorsBuy()         * Indicators_Weight;
    if(Use_MACrossover)       buy_conf += CheckMACrossoverBuy()        * MACrossover_Weight;
    if(Use_PivotPoints)       buy_conf += CheckPivotPointsBuy()        * PivotPoints_Weight;
    if(Use_MultiTimeframe)    buy_conf += CheckMultiTimeframeBuy()     * MultiTimeframe_Weight;
    if(Use_VolumeAnalysis)    buy_conf += CheckVolumeAnalysisBuy()     * VolumeAnalysis_Weight;
    if(Use_Divergence)        buy_conf += CheckDivergenceBuy()         * Divergence_Weight;
    if(Use_HarmonicPatterns)  buy_conf += CheckHarmonicPatternsBuy()   * HarmonicPatterns_Weight;
    if(Use_ElliottWaves)      buy_conf += CheckElliottWavesBuy()       * ElliottWaves_Weight;
    if(Use_WolfeWaves)        buy_conf += CheckWolfeWavesBuy()         * WolfeWaves_Weight;
    if(Use_ChartPatterns)     buy_conf += CheckChartPatternsBuy()      * ChartPatterns_Weight;
    if(Use_TimeAnalysis)      buy_conf += CheckTimeAnalysisBuy()       * TimeAnalysis_Weight;

    // Gather sell confirmations (weighted)
    int sell_conf = 0;

    if(Use_CandlePatterns)    sell_conf += CheckCandlePatternsShort()    * CandlePatterns_Weight;
    if(Use_PriceAction)       sell_conf += CheckPriceActionShort()       * PriceAction_Weight;
    if(Use_SupportResistance) sell_conf += CheckSupportResistanceShort() * SupportResistance_Weight;
    if(Use_Indicators)        sell_conf += CheckIndicatorsShort()        * Indicators_Weight;
    if(Use_MACrossover)       sell_conf += CheckMACrossoverShort()       * MACrossover_Weight;
    if(Use_PivotPoints)       sell_conf += CheckPivotPointsShort()       * PivotPoints_Weight;
    if(Use_MultiTimeframe)    sell_conf += CheckMultiTimeframeShort()    * MultiTimeframe_Weight;
    if(Use_VolumeAnalysis)    sell_conf += CheckVolumeAnalysisShort()    * VolumeAnalysis_Weight;
    if(Use_Divergence)        sell_conf += CheckDivergenceShort()        * Divergence_Weight;
    if(Use_HarmonicPatterns)  sell_conf += CheckHarmonicPatternsShort()  * HarmonicPatterns_Weight;
    if(Use_ElliottWaves)      sell_conf += CheckElliottWavesShort()      * ElliottWaves_Weight;
    if(Use_WolfeWaves)        sell_conf += CheckWolfeWavesShort()        * WolfeWaves_Weight;
    if(Use_ChartPatterns)     sell_conf += CheckChartPatternsShort()     * ChartPatterns_Weight;
    if(Use_TimeAnalysis)      sell_conf += CheckTimeAnalysisShort()      * TimeAnalysis_Weight;

    DebugPrint(StringFormat("[AlaaGoldEA] Buy conf=%d  Sell conf=%d  Min=%d",
               buy_conf, sell_conf, Min_Confirmations));

    // Calculate ATR for position sizing
    double atr_val = GetATR(0);
    if(atr_val <= 0) atr_val = StopLoss_Pips * _Point * 10;

    // Execute trades based on confirmation threshold
    if(buy_conf >= Min_Confirmations && buy_conf > sell_conf)
    {
        OpenBuyTrade(atr_val);
    }
    else if(sell_conf >= Min_Confirmations && sell_conf > buy_conf)
    {
        OpenSellTrade(atr_val);
    }

    // Manage trailing stops
    ManageOpenPositions();
}

//+------------------------------------------------------------------+
//| Open a buy trade                                                  |
//+------------------------------------------------------------------+
void OpenBuyTrade(double atr)
{
    double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    double sl  = 0, tp  = 0;

    if(Use_Dynamic_StopLoss)
    {
        sl = ask - atr * ATR_StopLoss_Multiplier;
        tp = ask + atr * ATR_TakeProfit_Multiplier;
    }
    else
    {
        double pip = _Point * 10;
        sl = ask - StopLoss_Pips  * pip;
        tp = ask + TakeProfit_Pips * pip;
    }

    double lot = CalculateLotSize(MathAbs(ask - sl));

    g_trade.SetExpertMagicNumber(Magic_Number);
    if(!g_trade.Buy(lot, Symbol(), ask, sl, tp, "AlaaGoldEA|B"))
        DebugPrint("Buy order failed: " + IntegerToString(g_trade.ResultRetcode()));
    else
        DebugPrint("Buy order opened at " + DoubleToString(ask, _Digits));
}

//+------------------------------------------------------------------+
//| Open a sell trade                                                 |
//+------------------------------------------------------------------+
void OpenSellTrade(double atr)
{
    double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    double sl  = 0, tp  = 0;

    if(Use_Dynamic_StopLoss)
    {
        sl = bid + atr * ATR_StopLoss_Multiplier;
        tp = bid - atr * ATR_TakeProfit_Multiplier;
    }
    else
    {
        double pip = _Point * 10;
        sl = bid + StopLoss_Pips  * pip;
        tp = bid - TakeProfit_Pips * pip;
    }

    double lot = CalculateLotSize(MathAbs(sl - bid));

    g_trade.SetExpertMagicNumber(Magic_Number);
    if(!g_trade.Sell(lot, Symbol(), bid, sl, tp, "AlaaGoldEA|S"))
        DebugPrint("Sell order failed: " + IntegerToString(g_trade.ResultRetcode()));
    else
        DebugPrint("Sell order opened at " + DoubleToString(bid, _Digits));
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk percentage                        |
//+------------------------------------------------------------------+
double CalculateLotSize(double sl_distance)
{
    if(LotSize > 0) return NormalizeLot(LotSize);

    if(sl_distance <= 0) return NormalizeLot(SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN));

    double balance    = AccountInfoDouble(ACCOUNT_BALANCE);
    double risk_amt   = balance * MaxRisk_Percent / 100.0;
    double tick_val   = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
    double tick_size  = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);

    if(tick_size <= 0 || tick_val <= 0)
        return NormalizeLot(SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN));

    double lot = risk_amt / (sl_distance / tick_size * tick_val);
    lot = MathMin(lot, Max_Lot_Size);
    return NormalizeLot(lot);
}

//+------------------------------------------------------------------+
//| Normalize lot to broker requirements                              |
//+------------------------------------------------------------------+
double NormalizeLot(double lot)
{
    double min_lot  = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
    double max_lot  = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
    double lot_step = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);

    if(lot_step > 0)
        lot = MathFloor(lot / lot_step) * lot_step;

    lot = MathMax(lot, min_lot);
    lot = MathMin(lot, MathMin(max_lot, Max_Lot_Size));
    return lot;
}

//+------------------------------------------------------------------+
//| Manage trailing stop on open positions                            |
//+------------------------------------------------------------------+
void ManageOpenPositions()
{
    if(TrailingStop <= 0) return;
    double trail = TrailingStop * _Point * 10;

    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if(!PositionSelectByTicket(ticket)) continue;
        if(PositionGetString(POSITION_SYMBOL)  != Symbol()) continue;
        if(PositionGetInteger(POSITION_MAGIC) != Magic_Number) continue;

        double cur_sl    = PositionGetDouble(POSITION_SL);
        double cur_tp    = PositionGetDouble(POSITION_TP);
        ENUM_POSITION_TYPE pos_type =
            (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

        if(pos_type == POSITION_TYPE_BUY)
        {
            double bid    = SymbolInfoDouble(Symbol(), SYMBOL_BID);
            double new_sl = bid - trail;
            if(new_sl > cur_sl + _Point)
                g_trade.PositionModify(ticket, new_sl, cur_tp);
        }
        else if(pos_type == POSITION_TYPE_SELL)
        {
            double ask    = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
            double new_sl = ask + trail;
            if(cur_sl == 0 || new_sl < cur_sl - _Point)
                g_trade.PositionModify(ticket, new_sl, cur_tp);
        }
    }
}

//+------------------------------------------------------------------+
//| Exported helper functions (used via #import in .mqh modules)     |
//+------------------------------------------------------------------+

void DebugPrint(string message)
{
    if(g_debug_mode) Print("[AlaaGoldEA] " + message);
}

bool GetDebugMode()
{
    return g_debug_mode;
}

bool CheckArrayAccess(int index, int array_size, string function_name)
{
    if(index < 0 || index >= array_size)
    {
        if(g_debug_mode)
            Print("Array out of bounds in " + function_name +
                  ": index=" + IntegerToString(index) +
                  " size=" + IntegerToString(array_size));
        return false;
    }
    return true;
}

bool CheckArraySize(MqlRates &rates[], int min_size, string function_name)
{
    int sz = ArraySize(rates);
    if(sz < min_size)
    {
        if(g_debug_mode)
            Print(function_name + ": array size " + IntegerToString(sz) +
                  " < required " + IntegerToString(min_size));
        return false;
    }
    return true;
}

void ResetExternalCandleCache()   { /* handled internally by CandlePatterns.mqh  */ }
void ResetExternalPatternCache()  { /* handled internally by ChartPatternsImpl.mqh */ }

void AppendTag(string &tag, string new_tag)
{
    if(StringLen(tag) > 0) tag += "|";
    tag += new_tag;
}
