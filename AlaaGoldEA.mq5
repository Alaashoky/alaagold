//+------------------------------------------------------------------+
//|                                                   AlaaGoldEA.mq5 |
//|                                      Copyright 2023, Gold Trader  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Gold Trader"
#property version   "1.00"
#property strict

//--- Includes
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
input bool   Debug_Mode           = false;
input bool   UseSessionFilter     = true;

//=== Timeframes ===
input ENUM_TIMEFRAMES Main_Timeframe    = PERIOD_H1;
input ENUM_TIMEFRAMES Higher_Timeframe  = PERIOD_H4;
input ENUM_TIMEFRAMES Lower_Timeframe   = PERIOD_M15;

//=== Risk Management ===
input double LotSize         = 0.1;
input double StopLoss_Pips   = 50.0;
input double TakeProfit_Pips = 100.0;
input double MaxRisk_Percent = 2.0;
input int    MaxOpenTrades   = 3;
input double TrailingStop    = 30.0;

//=== Confirmation Threshold ===
input int MinConfirmations = 3;

//=== RSI Settings ===
input int    RSI_Period         = 14;

//=== MACD Settings ===
input int    MACD_Fast          = 12;
input int    MACD_Slow          = 26;
input int    MACD_Signal        = 9;

//=== Bollinger Bands ===
input int    BB_Period          = 20;
input double BB_Deviation       = 2.0;

//=== ATR ===
input int    ATR_Period         = 14;

//=== MA Crossover ===
input int    MA_Fast_Period     = 20;
input int    MA_Slow_Period     = 50;
input int    MA_Trend_Period    = 200;
input ENUM_MA_METHOD  MA_Method = MODE_EMA;
input ENUM_APPLIED_PRICE MA_Applied_Price = PRICE_CLOSE;

//=== Multi Timeframe ===
input int    MTF_MA_Period      = 50;

//=== Time Analysis ===
input int    LondonOpenHour     = 8;
input int    LondonCloseHour    = 17;
input int    NewYorkOpenHour    = 13;
input int    NewYorkCloseHour   = 22;
input int    TokyoOpenHour      = 0;
input int    TokyoCloseHour     = 9;

//=== Harmonic Patterns ===
input int    HP_Lookback_Bars   = 100;
input double HP_Tol             = 0.05;

//=== Elliott Waves ===
input int    EW_Lookback_Bars   = 50;

//=== Wolfe Waves ===
input int    WW_Lookback_Bars   = 60;
input double WW_Tol             = 0.02;

//=== Chart Patterns ===
input int    CHT_Lookback_Bars  = 50;
input double CHT_Tol            = 0.005;

//=== Divergence ===
input int    DIV_RSI_Period     = 14;
input int    DIV_MACD_Fast      = 12;
input int    DIV_MACD_Slow      = 26;
input int    DIV_MACD_Signal    = 9;
input int    DIV_Lookback_Bars  = 30;

//=== Pivot Points ===
// (uses Main_Timeframe)

//--- Global state
datetime g_last_candle_time = 0;
bool     g_debug_mode       = false;

//+------------------------------------------------------------------+
//| Expert initialisation                                            |
//+------------------------------------------------------------------+
int OnInit()
{
    g_debug_mode = Debug_Mode;

    // Propagate timeframes to submodules
    CP_Timeframe  = Main_Timeframe;
    TP_Timeframe  = Main_Timeframe;
    PA_Timeframe  = Main_Timeframe;
    IND_Timeframe = Main_Timeframe;
    MAC_Timeframe = Main_Timeframe;
    PP_Timeframe  = Main_Timeframe;
    VA_Timeframe  = Main_Timeframe;
    DIV_Timeframe = Main_Timeframe;
    HP_Timeframe  = Main_Timeframe;
    EW_Timeframe  = Main_Timeframe;
    WW_Timeframe  = Main_Timeframe;
    CHT_Timeframe = Main_Timeframe;
    MTF_HigherTF  = Higher_Timeframe;
    MTF_LowerTF   = Lower_Timeframe;

    // Time analysis
    TA_UseSessionFilter  = UseSessionFilter;
    TA_LondonOpenHour    = LondonOpenHour;
    TA_LondonCloseHour   = LondonCloseHour;
    TA_NewYorkOpenHour   = NewYorkOpenHour;
    TA_NewYorkCloseHour  = NewYorkCloseHour;
    TA_TokyoOpenHour     = TokyoOpenHour;
    TA_TokyoCloseHour    = TokyoCloseHour;

    // Indicators
    RSI_Period    = RSI_Period;
    MACD_Fast     = MACD_Fast;
    MACD_Slow     = MACD_Slow;
    MACD_Signal   = MACD_Signal;
    BB_Period     = BB_Period;
    BB_Deviation  = BB_Deviation;
    ATR_Period    = ATR_Period;

    // MA Crossover
    MA_Fast_Period    = MA_Fast_Period;
    MA_Slow_Period    = MA_Slow_Period;
    MA_Trend_Period   = MA_Trend_Period;
    MA_Method         = MA_Method;
    MA_Applied_Price  = MA_Applied_Price;
    MTF_MA_Period     = MTF_MA_Period;

    // Harmonic / Elliott / Wolfe / Chart patterns
    HP_Lookback  = HP_Lookback_Bars;
    HP_Tolerance = HP_Tol;
    EW_Lookback  = EW_Lookback_Bars;
    WW_Lookback  = WW_Lookback_Bars;
    WW_Tolerance = WW_Tol;
    CHT_Lookback = CHT_Lookback_Bars;
    CHT_Tolerance= CHT_Tol;

    // Divergence
    DIV_RSI_Period   = DIV_RSI_Period;
    DIV_MACD_Fast    = DIV_MACD_Fast;
    DIV_MACD_Slow    = DIV_MACD_Slow;
    DIV_MACD_Signal  = DIV_MACD_Signal;
    DIV_Lookback     = DIV_Lookback_Bars;

    // Support & resistance timeframe
    SetSRTimeframe(Higher_Timeframe);

    // Initial S/R calculation
    IdentifySupportResistanceLevels();
    CalculatePivotPoints();

    DebugPrint("AlaaGoldEA initialized on " + Symbol());
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization                                          |
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
    // Only process on new candle
    datetime candle_time = iTime(Symbol(), Main_Timeframe, 0);
    if(candle_time == g_last_candle_time) return;
    g_last_candle_time = candle_time;

    if(!IsTradingTimeAllowed()) { DebugPrint("Outside trading hours"); return; }
    if(IsWeekend() || IsEndOfWeek()) { DebugPrint("Weekend or end-of-week"); return; }

    // Count open positions
    int open_trades = 0;
    for(int i = PositionsTotal() - 1; i >= 0; i--)
        if(PositionGetSymbol(i) == Symbol()) open_trades++;

    if(open_trades >= MaxOpenTrades) { DebugPrint("Max open trades reached"); return; }

    // Gather buy confirmations
    int buy_conf = 0;
    buy_conf += CheckCandlePatternsBuy();
    buy_conf += CheckPriceActionBuy();
    buy_conf += CheckSupportResistanceBuy();
    buy_conf += CheckIndicatorsBuy();
    buy_conf += CheckMACrossoverBuy();
    buy_conf += CheckPivotPointsBuy();
    buy_conf += CheckMultiTimeframeBuy();
    buy_conf += CheckVolumeAnalysisBuy();
    buy_conf += CheckDivergenceBuy();
    buy_conf += CheckHarmonicPatternsBuy();
    buy_conf += CheckElliottWavesBuy();
    buy_conf += CheckWolfeWavesBuy();
    buy_conf += CheckChartPatternsBuy();
    buy_conf += CheckTimeAnalysisBuy();

    // Gather sell confirmations
    int sell_conf = 0;
    sell_conf += CheckCandlePatternsShort();
    sell_conf += CheckPriceActionShort();
    sell_conf += CheckSupportResistanceShort();
    sell_conf += CheckIndicatorsShort();
    sell_conf += CheckMACrossoverShort();
    sell_conf += CheckPivotPointsShort();
    sell_conf += CheckMultiTimeframeShort();
    sell_conf += CheckVolumeAnalysisShort();
    sell_conf += CheckDivergenceShort();
    sell_conf += CheckHarmonicPatternsShort();
    sell_conf += CheckElliottWavesShort();
    sell_conf += CheckWolfeWavesShort();
    sell_conf += CheckChartPatternsShort();
    sell_conf += CheckTimeAnalysisShort();

    DebugPrint(StringFormat("Buy conf=%d  Sell conf=%d  Min=%d", buy_conf, sell_conf, MinConfirmations));

    double atr = iATR(Symbol(), Main_Timeframe, ATR_Period) > 0
                 ? iATR(Symbol(), Main_Timeframe, ATR_Period) : StopLoss_Pips * Point();

    if(buy_conf >= MinConfirmations && buy_conf > sell_conf)
        OpenBuyTrade(atr);
    else if(sell_conf >= MinConfirmations && sell_conf > buy_conf)
        OpenSellTrade(atr);

    ManageOpenPositions();
}

//+------------------------------------------------------------------+
//| Open a buy trade                                                  |
//+------------------------------------------------------------------+
void OpenBuyTrade(double atr)
{
    double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    double sl  = ask - atr * 1.5;
    double tp  = ask + atr * 3.0;
    double lot = CalculateLotSize(MathAbs(ask - sl));

    MqlTradeRequest req = {};
    MqlTradeResult  res = {};
    req.action   = TRADE_ACTION_DEAL;
    req.symbol   = Symbol();
    req.volume   = lot;
    req.type     = ORDER_TYPE_BUY;
    req.price    = ask;
    req.sl       = sl;
    req.tp       = tp;
    req.deviation= 10;
    req.magic    = 20230101;
    req.comment  = "AlaaGoldEA Buy";

    if(!OrderSend(req, res))
        DebugPrint("Buy order failed: " + IntegerToString(res.retcode));
    else
        DebugPrint("Buy order opened at " + DoubleToString(ask, Digits()));
}

//+------------------------------------------------------------------+
//| Open a sell trade                                                 |
//+------------------------------------------------------------------+
void OpenSellTrade(double atr)
{
    double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    double sl  = bid + atr * 1.5;
    double tp  = bid - atr * 3.0;
    double lot = CalculateLotSize(MathAbs(sl - bid));

    MqlTradeRequest req = {};
    MqlTradeResult  res = {};
    req.action   = TRADE_ACTION_DEAL;
    req.symbol   = Symbol();
    req.volume   = lot;
    req.type     = ORDER_TYPE_SELL;
    req.price    = bid;
    req.sl       = sl;
    req.tp       = tp;
    req.deviation= 10;
    req.magic    = 20230101;
    req.comment  = "AlaaGoldEA Sell";

    if(!OrderSend(req, res))
        DebugPrint("Sell order failed: " + IntegerToString(res.retcode));
    else
        DebugPrint("Sell order opened at " + DoubleToString(bid, Digits()));
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk                                  |
//+------------------------------------------------------------------+
double CalculateLotSize(double sl_distance)
{
    if(sl_distance <= 0) return LotSize;
    double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double risk_amount     = account_balance * MaxRisk_Percent / 100.0;
    double tick_value      = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
    double tick_size       = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
    if(tick_size <= 0 || tick_value <= 0) return LotSize;
    double lot = risk_amount / (sl_distance / tick_size * tick_value);
    double min_lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
    double max_lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
    double step    = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
    lot = MathFloor(lot / step) * step;
    lot = MathMax(lot, min_lot);
    lot = MathMin(lot, max_lot);
    return lot;
}

//+------------------------------------------------------------------+
//| Manage trailing stop on open positions                            |
//+------------------------------------------------------------------+
void ManageOpenPositions()
{
    if(TrailingStop <= 0) return;
    double trail = TrailingStop * Point();

    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if(!PositionSelectByTicket(ticket)) continue;
        if(PositionGetString(POSITION_SYMBOL) != Symbol()) continue;
        if((int)PositionGetInteger(POSITION_MAGIC) != 20230101) continue;

        double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
        double cur_sl     = PositionGetDouble(POSITION_SL);
        ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

        MqlTradeRequest req = {};
        MqlTradeResult  res = {};
        req.action   = TRADE_ACTION_SLTP;
        req.symbol   = Symbol();
        req.position = ticket;

        if(pos_type == POSITION_TYPE_BUY)
        {
            double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
            double new_sl = bid - trail;
            if(new_sl > cur_sl + Point())
            {
                req.sl = new_sl;
                req.tp = PositionGetDouble(POSITION_TP);
                OrderSend(req, res);
            }
        }
        else if(pos_type == POSITION_TYPE_SELL)
        {
            double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
            double new_sl = ask + trail;
            if(new_sl < cur_sl - Point() || cur_sl == 0)
            {
                req.sl = new_sl;
                req.tp = PositionGetDouble(POSITION_TP);
                OrderSend(req, res);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Exported helper functions (used by #import in .mqh files)         |
//+------------------------------------------------------------------+
void DebugPrint(string message)
{
    if(g_debug_mode) Print("[AlaaGoldEA] " + message);
}

bool GetDebugMode() { return g_debug_mode; }

void ResetExternalCandleCache() { /* placeholder for external modules */ }

bool CheckArrayAccess(int index, int array_size, string function_name)
{
    if(index < 0 || index >= array_size)
    {
        DebugPrint("Array out of bounds in " + function_name + ": index=" +
                   IntegerToString(index) + " size=" + IntegerToString(array_size));
        return false;
    }
    return true;
}
